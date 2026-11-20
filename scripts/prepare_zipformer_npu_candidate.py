"""Export a fixed-batch ONNX candidate for accelerator compilation.

This tool infers tensor shapes without running the model. Optional Softplus
stabilization preserves the activation formula while avoiding FP16 overflow.
"""

import argparse
import hashlib
import json
from pathlib import Path

import onnx
from onnx import TensorProto, helper, numpy_helper
from onnxruntime.tools.symbolic_shape_infer import SymbolicShapeInference


def tensor_signature(value):
    tensor = value.type.tensor_type
    dimensions = [
        dim.dim_value if dim.HasField("dim_value") else dim.dim_param
        for dim in tensor.shape.dim
    ]
    return tensor.elem_type, dimensions


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def stabilize_softplus(model):
    """Lower log(1 + exp(x)) to max(x, 0) + log(1 + exp(-abs(x)))."""
    graph = model.graph
    producers = {name: node for node in graph.node for name in node.output}
    initializers = {value.name: value for value in graph.initializer}

    def is_one(name):
        tensor = initializers.get(name)
        if tensor is None:
            node = producers.get(name)
            if node is None or node.op_type != "Constant" or len(node.attribute) != 1:
                return False
            tensor = helper.get_attribute_value(node.attribute[0])
        if not isinstance(tensor, TensorProto):
            return False
        value = numpy_helper.to_array(tensor)
        return value.size == 1 and value.item() == 1

    zero = "__mathani_exp_stability_zero"
    graph.initializer.append(helper.make_tensor(zero, TensorProto.FLOAT, [], [0]))
    rewritten = []
    count = 0
    for node in graph.node:
        add = producers.get(node.input[0]) if node.op_type == "Log" else None
        match = None
        if add is not None and add.op_type == "Add":
            for i, name in enumerate(add.input):
                exp = producers.get(name)
                one = add.input[1 - i]
                if exp is not None and exp.op_type == "Exp" and is_one(one):
                    match = (exp.input[0], one)
                    break
        if match is None:
            rewritten.append(node)
            continue

        value, one = match
        prefix = node.output[0] + "__stable_softplus"

        def emit(op, inputs, suffix, output=None):
            name = prefix + suffix
            rewritten.append(helper.make_node(op, inputs, [output or name], name=name))
            return name

        absolute = emit("Abs", [value], "_abs")
        negative = emit("Neg", [absolute], "_neg")
        exponent = emit("Exp", [negative], "_exp")
        one_plus_exp = emit("Add", [one, exponent], "_one_plus_exp")
        log = emit("Log", [one_plus_exp], "_log")
        positive = emit("Max", [value, zero], "_positive")
        emit("Add", [positive, log], "_result", node.output[0])
        count += 1

    if count != 84:
        raise ValueError(f"Expected 84 Zipformer V3 Softplus patterns, found {count}")
    del graph.node[:]
    graph.node.extend(rewritten)
    return count


def prepare(source, output, *, fp16_safe=False):
    if output.exists():
        raise FileExistsError(f"Refusing to replace {output}")
    original = onnx.load(source, load_external_data=False)
    if any(
        onnx.external_data_helper.uses_external_data(t)
        for t in original.graph.initializer
    ):
        raise ValueError("Expected a self-contained ONNX model")

    candidate = onnx.ModelProto()
    candidate.CopyFrom(original)
    for value in (*candidate.graph.input, *candidate.graph.output):
        for dim in value.type.tensor_type.shape.dim:
            if dim.dim_param == "N":
                dim.dim_value = 1
    candidate = SymbolicShapeInference.infer_shapes(candidate, auto_merge=False)

    if (
        candidate.graph.node != original.graph.node
        or candidate.graph.initializer != original.graph.initializer
    ):
        raise ValueError("Shape inference changed graph operations or weights")

    inputs = {v.name: tensor_signature(v) for v in candidate.graph.input}
    outputs = {v.name: tensor_signature(v) for v in candidate.graph.output}
    if len(inputs) != 99 or len(outputs) != 99:
        raise ValueError("Expected the Zipformer V3 99-input, 99-output contract")
    if inputs.get("x") != (onnx.TensorProto.FLOAT, [1, 61, 80]):
        raise ValueError("Unexpected frame input signature")
    if outputs.get("log_probs") != (onnx.TensorProto.FLOAT, [1, 12, 251]):
        raise ValueError("Unexpected CTC output signature")
    for name, (_, shape) in (*inputs.items(), *outputs.items()):
        if not shape or any(not isinstance(dim, int) or dim <= 0 for dim in shape):
            raise ValueError(f"Unresolved tensor shape for {name}: {shape}")
    for name, signature in inputs.items():
        if name != "x" and outputs.get(f"new_{name}") != signature:
            raise ValueError(f"Streaming state input/output mismatch: {name}")

    stabilized = stabilize_softplus(candidate) if fp16_safe else 0
    onnx.checker.check_model(candidate, full_check=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("xb") as target:
        target.write(candidate.SerializeToString())

    return {
        "source_sha256": digest(source),
        "candidate_sha256": digest(output),
        "input_count": len(inputs),
        "output_count": len(outputs),
        "streaming_state_pairs": len(inputs) - 1,
        "operation_count": len(candidate.graph.node),
        "stabilized_softplus_patterns": stabilized,
        "audio_features": inputs["x"][1],
        "ctc_logits": outputs["log_probs"][1],
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--fp16-safe", action="store_true")
    args = parser.parse_args()
    print(json.dumps(prepare(args.source, args.output, fp16_safe=args.fp16_safe), indent=2))
