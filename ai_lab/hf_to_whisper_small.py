#!/usr/bin/env python3
"""
تحويل أوزان نموذج تدبر (صيغة HuggingFace Transformers) إلى checkpoint بصيغة
openai-whisper (tadabur-small.pt) بحيث يمكن تصديره بواسطة سكريبت sherpa-onnx الرسمي.

الاستخدام:
    python hf_to_whisper_small.py --hf-dir C:\Projects\mathani\tadabur --out C:\Projects\mathani\ai_lab\tadabur_sherpa\tadabur-small.pt
"""

import argparse
import sys
from pathlib import Path

if sys.platform.startswith("win"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

import torch
from safetensors.torch import load_file


def get_args():
    p = argparse.ArgumentParser()
    p.add_argument("--hf-dir", required=True, help="مجلد نموذج تدبر بصيغة HF")
    p.add_argument("--out", required=True, help="مسار حفظ checkpoint بصيغة whisper")
    return p.parse_args()


def main():
    args = get_args()
    hf_dir = Path(args.hf_dir)

    print(f"تحميل الأوزان من {hf_dir} ...")
    state = load_file(str(hf_dir / "model.safetensors"))
    print(f"عدد الأوزان الأصلية: {len(state)}")

    new_state = {}
    new_state["dims"] = torch.tensor(
        [
            80,     # n_mels
            1500,   # n_audio_ctx
            768,    # n_audio_state
            12,     # n_audio_head
            12,     # n_audio_layer
            51865,  # n_vocab
            448,    # n_text_ctx
            768,    # n_text_state
            12,     # n_text_head
            12,     # n_text_layer
        ]
    ).long()

    def map_tensor(name):
        t = state[name]
        # cast conv weights to float32 (HF may store them differently)
        return t.float() if t.dtype != torch.float32 else t

    # ---------- Encoder ----------
    for i in range(12):
        # self attention
        new_state[f"encoder.blocks.{i}.attn.query.weight"] = map_tensor(
            f"encoder.layers.{i}.self_attn.q_proj.weight"
        )
        new_state[f"encoder.blocks.{i}.attn.key.weight"] = map_tensor(
            f"encoder.layers.{i}.self_attn.k_proj.weight"
        )
        new_state[f"encoder.blocks.{i}.attn.value.weight"] = map_tensor(
            f"encoder.layers.{i}.self_attn.v_proj.weight"
        )
        new_state[f"encoder.blocks.{i}.attn.out.weight"] = map_tensor(
            f"encoder.layers.{i}.self_attn.out_proj.weight"
        ).T
        # mlp
        new_state[f"encoder.blocks.{i}.mlp.0.weight"] = map_tensor(
            f"encoder.layers.{i}.fc1.weight"
        )
        new_state[f"encoder.blocks.{i}.mlp.0.bias"] = map_tensor(
            f"encoder.layers.{i}.fc1.bias"
        )
        new_state[f"encoder.blocks.{i}.mlp.2.weight"] = map_tensor(
            f"encoder.layers.{i}.fc2.weight"
        )
        new_state[f"encoder.blocks.{i}.mlp.2.bias"] = map_tensor(
            f"encoder.layers.{i}.fc2.bias"
        )
        # layer norms
        new_state[f"encoder.blocks.{i}.attn_ln.weight"] = map_tensor(
            f"encoder.layers.{i}.self_attn_layer_norm.weight"
        )
        new_state[f"encoder.blocks.{i}.attn_ln.bias"] = map_tensor(
            f"encoder.layers.{i}.self_attn_layer_norm.bias"
        )
        new_state[f"encoder.blocks.{i}.mlp_ln.weight"] = map_tensor(
            f"encoder.layers.{i}.final_layer_norm.weight"
        )
        new_state[f"encoder.blocks.{i}.mlp_ln.bias"] = map_tensor(
            f"encoder.layers.{i}.final_layer_norm.bias"

    # conv1/conv2 + positional embedding + ln_post
    new_state["encoder.conv1.weight"] = map_tensor("encoder.conv1.weight")
    new_state["encoder.conv1.bias"] = map_tensor("encoder.conv1.bias")
    new_state["encoder.conv2.weight"] = map_tensor("encoder.conv2.weight")
    new_state["encoder.conv2.bias"] = map_tensor("encoder.conv2.bias")
    new_state["encoder.positional_embedding"] = map_tensor(
        "encoder.embed_positions.weight"
    )
    new_state["encoder.ln_post.weight"] = map_tensor("encoder.layer_norm.weight")
    new_state["encoder.ln_post.bias"] = map_tensor("encoder.layer_norm.bias")

    # ---------- Decoder ----------
    new_state["decoder.token_embedding.weight"] = map_tensor(
        "decoder.embed_tokens.weight"
    )

    for i in range(12):
        # self attention
        new_state[f"decoder.blocks.{i}.attn.query.weight"] = map_tensor(
            f"decoder.layers.{i}.self_attn.q_proj.weight"
        )
        new_state[f"decoder.blocks.{i}.attn.query.bias"] = map_tensor(
            f"decoder.layers.{i}.self_attn.q_proj.bias"
        )
        new_state[f"decoder.blocks.{i}.attn.key.weight"] = map_tensor(
            f"decoder.layers.{i}.self_attn.k_proj.weight"
        )
        new_state[f"decoder.blocks.{i}.attn.value.weight"] = map_tensor(
            f"decoder.layers.{i}.self_attn.v_proj.weight"
        )
        new_state[f"decoder.blocks.{i}.attn.out.weight"] = map_tensor(
            f"decoder.layers.{i}.self_attn.out_proj.weight"
        ).T
        new_state[f"decoder.blocks.{i}.attn.out.bias"] = map_tensor(
            f"decoder.layers.{i}.self_attn.out_proj.bias"
        )
        # cross attention
        new_state[f"decoder.blocks.{i}.cross_attn.query.weight"] = map_tensor(
            f"decoder.layers.{i}.encoder_attn.q_proj.weight"
        )
        new_state[f"decoder.blocks.{i}.cross_attn.query.bias"] = map_tensor(
            f"decoder.layers.{i}.encoder_attn.q_proj.bias"
        )
        new_state[f"decoder.blocks.{i}.cross_attn.key.weight"] = map_tensor(
            f"decoder.layers.{i}.encoder_attn.k_proj.weight"
        )
        new_state[f"decoder.blocks.{i}.cross_attn.value.weight"] = map_tensor(
            f"decoder.layers.{i}.encoder_attn.v_proj.weight"
        )
        # mlp
        new_state[f"decoder.blocks.{i}.mlp.0.weight"] = map_tensor(
            f"decoder.layers.{i}.fc1.weight"
        )
        new_state[f"decoder.blocks.{i}.mlp.0.bias"] = map_tensor(
            f"decoder.layers.{i}.fc1.bias"
        )
        new_state[f"decoder.blocks.{i}.mlp.2.weight"] = map_tensor(
            f"decoder.layers.{i}.fc2.weight"
        )
        new_state[f"decoder.blocks.{i}.mlp.2.bias"] = map_tensor(
            f"decoder.layers.{i}.fc2.bias"
        )
        # layer norms
        new_state[f"decoder.blocks.{i}.attn_ln.weight"] = map_tensor(
            f"decoder.layers.{i}.self_attn_layer_norm.weight"
        )
        new_state[f"decoder.blocks.{i}.attn_ln.bias"] = map_tensor(
            f"decoder.layers.{i}.self_attn_layer_norm.bias"
        )
        new_state[f"decoder.blocks.{i}.cross_attn_ln.weight"] = map_tensor(
            f"decoder.layers.{i}.encoder_attn_layer_norm.weight"
        )
        new_state[f"decoder.blocks.{i}.cross_attn_ln.bias"] = map_tensor(
            f"decoder.layers.{i}.encoder_attn_layer_norm.bias"
        )
        new_state[f"decoder.blocks.{i}.mlp_ln.weight"] = map_tensor(
            f"decoder.layers.{i}.final_layer_norm.weight"
        )
        new_state[f"decoder.blocks.{i}.mlp_ln.bias"] = map_tensor(
            f"decoder.layers.{i}.final_layer_norm.bias"
        )

    # final layer norm
    new_state["decoder.ln.weight"] = map_tensor("decoder.layer_norm.weight")
    new_state["decoder.ln.bias"] = map_tensor("decoder.layer_norm.bias")

    print(f"عدد الأوزان المحوّلة: {len(new_state)}")

    # التحقق من عدم فقدان أي وزن مهم
    n_enc = sum(1 for k in new_state if k.startswith("encoder."))
    n_dec = sum(1 for k in new_state if k.startswith("decoder."))
    print(f"أوزان encoder: {n_enc} (متوقع {12 * 18 + 6})")
    print(f"أوزان decoder: {n_dec} (متوقع {12 * 24 + 2})")

    # حفظ checkpoint
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    torch.save(new_state, out_path)
    size_mb = out_path.stat().st_size / 1024 / 1024
    print(f"✅ تم الحفظ: {out_path} ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()

        new_state[f"decoder.blocks.{i}.cross_attn.out.weight"] = map_tensor(
            f"decoder.layers.{i}.encoder_attn.out_proj.weight"
        ).T
        new_state[f"decoder.blocks.{i}.cross_attn.out.bias"] = map_tensor(
            f"decoder.layers.{i}.encoder_attn.out_proj.bias"
        )

    new_state["decoder.positional_embedding"] = map_tensor(
        "decoder.embed_positions.weight"
    )

        )

            12,     # n_text_head
            12,     # n_text_layer
        ]
    ).long()

placeholder
