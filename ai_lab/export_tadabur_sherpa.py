#!/usr/bin/env python3
"""
تصدير نموذج تدبر-Whisper-Small إلى ONNX بالطريقة الرسمية لـ sherpa-onnx.

مبني على السكريبت الرسمي k2-fsa/sherpa-onnx/scripts/whisper/export-onnx.py
مع تعديل تحميل checkpoint المحوَّل محلياً (tadabur-small.pt الناتج من hf_to_whisper_small.py).

الناتج (في --out-dir):
    encoder.onnx / decoder.onnx        (float32)
    encoder.int8.onnx / decoder.int8.onnx
    tokens.txt
    encoder-final.onnx / decoder-final.onnx  (أسماء نهائية مطابقة لتوقعات Flutter)

الاستخدام:
    python export_tadabur_sherpa.py --ckpt C:\Projects\mathani\ai_lab\tadabur_sherpa\tadabur-small.pt --out-dir C:\Projects\mathani\ai_lab\tadabur_sherpa
"""

import argparse
import sys
from pathlib import Path
from typing import Any, Dict, Optional

if sys.platform.startswith("win"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

import onnx
import torch
import torch.nn.functional as F
from onnxruntime.quantization import QuantType, quantize_dynamic
from torch import Tensor, nn

import whisper
from whisper.model import (
    AudioEncoder,
    ModelDimensions,
    MultiHeadAttention,
    ResidualAttentionBlock,
    TextDecoder,
    Whisper,
)


def get_args():
    p = argparse.ArgumentParser()
    p.add_argument("--ckpt", required=True, help="checkpoint المحوَّل (tadabur-small.pt)")
    p.add_argument("--out-dir", required=True, help="مجلد الناتج")
    p.add_argument(
        "--name", default="tadabur-small", help="اسم النموذج لملفات ONNX المؤقتة"
    )
    return p.parse_args()


def add_meta_data(filename: str, meta_data: Dict[str, Any]):
    """Add meta data to an ONNX model. It is changed in-place."""
    model = onnx.load(filename)

    while len(model.metadata_props):
        model.metadata_props.pop()

    for key, value in meta_data.items():
        meta = model.metadata_props.add()
        meta.key = key
        meta.value = str(value)

    onnx.save(model, filename)


@torch.no_grad()
def modified_audio_encoder_forward(self: AudioEncoder, x: torch.Tensor):
    """
    x : torch.Tensor, shape = (batch_size, n_mels, n_ctx)
        the mel spectrogram of the audio
    """
    x = F.gelu(self.conv1(x))
    x = F.gelu(self.conv2(x))
    x = x.permute(0, 2, 1)

    # نسمح بأي T <= 30 (أزلنا قيد 30 ثانية كما في السكريبت الرسمي)
    assert x.shape[2] == self.positional_embedding.shape[1], "incorrect audio shape"
    assert x.shape[1] == self.positional_embedding.shape[0], "incorrect audio shape"
    x = (x + self.positional_embedding[: x.shape[1]]).to(x.dtype)

    for block in self.blocks:

class MultiHeadAttentionCross(nn.Module):
    def __init__(self, inMultiHeadAttention: MultiHeadAttention):
        super().__init__()
        self.multiHeadAttention = inMultiHeadAttention

    def forward(
        self,
        x: Tensor,
        k: Tensor,
        v: Tensor,
        mask: Optional[Tensor] = None,
    ):
        q = self.multiHeadAttention.query(x)
        wv, qk = self.multiHeadAttention.qkv_attention(q, k, v, mask)
        return self.multiHeadAttention.out(wv)


class MultiHeadAttentionSelf(nn.Module):
    def __init__(self, inMultiHeadAttention: MultiHeadAttention):
        super().__init__()
        self.multiHeadAttention = inMultiHeadAttention

    def forward(
        self,
        x: Tensor,  # (b, n_ctx      , n_state)
        k_cache: Tensor,  # (b, n_ctx_cache, n_state)
        v_cache: Tensor,  # (b, n_ctx_cache, n_state)
        mask: Tensor,
    ):
        q = self.multiHeadAttention.query(x)  # (b, n_ctx, n_state)
        k = self.multiHeadAttention.key(x)  # (b, n_ctx, n_state)
        v = self.multiHeadAttention.value(x)  # (b, n_ctx, n_state)

        k_cache[:, -k.shape[1] :, :] = k  # (b, n_ctx_cache + n_ctx, n_state)
        v_cache[:, -v.shape[1] :, :] = v  # (b, n_ctx_cache + n_ctx, n_state)

        wv, qk = self.multiHeadAttention.qkv_attention(q, k_cache, v_cache, mask)
        return self.multiHeadAttention.out(wv), k_cache, v_cache


class ResidualAttentionBlockTensorCache(nn.Module):
    def __init__(self, inResidualAttentionBlock: ResidualAttentionBlock):
        super().__init__()
        self.originalBlock = inResidualAttentionBlock
        self.attn = MultiHeadAttentionSelf(inResidualAttentionBlock.attn)
        self.cross_attn = (
            MultiHeadAttentionCross(inResidualAttentionBlock.cross_attn)
            if inResidualAttentionBlock.cross_attn
            else None
        )

    def forward(
        self,
        x: Tensor,
        self_k_cache: Tensor,
        self_v_cache: Tensor,
        cross_k: Tensor,
        cross_v: Tensor,
        mask: Tensor,
    ):
        self_attn_x, self_k_cache_updated, self_v_cache_updated = self.attn(
            self.originalBlock.attn_ln(x), self_k_cache, self_v_cache, mask=mask
        )
        x = x + self_attn_x

        if self.cross_attn:
            x = x + self.cross_attn(
                self.originalBlock.cross_attn_ln(x), cross_k, cross_v
            )

        x = x + self.originalBlock.mlp(self.originalBlock.mlp_ln(x))
        return x, self_k_cache_updated, self_v_cache_updated


class TextDecoderTensorCache(nn.Module):
    def __init__(self, inTextDecoder: TextDecoder, in_n_ctx: int):
        super().__init__()
        self.textDecoder = inTextDecoder
        self.n_ctx = in_n_ctx

        self.blocks = []
        for orginal_block in self.textDecoder.blocks:
            self.blocks.append(ResidualAttentionBlockTensorCache(orginal_block))

    def forward(
        self,
        tokens: Tensor,
        n_layer_self_k_cache: Tensor,
        n_layer_self_v_cache: Tensor,
        n_layer_cross_k: Tensor,
        n_layer_cross_v: Tensor,
        offset: Tensor,
    ):
        x = (
            self.textDecoder.token_embedding(tokens)
            + self.textDecoder.positional_embedding[
                offset[0] : offset[0] + tokens.shape[-1]
            ]
        )
        x = x.to(n_layer_cross_k[0].dtype)

        i = 0
        for block in self.blocks:
            self_k_cache = n_layer_self_k_cache[i, :, : offset[0] + tokens.shape[-1], :]
            self_v_cache = n_layer_self_v_cache[i, :, : offset[0] + tokens.shape[-1], :]
            x, self_k_cache, self_v_cache = block(
                x,
                self_k_cache=self_k_cache,
                self_v_cache=self_v_cache,
                cross_k=n_layer_cross_k[i],
                cross_v=n_layer_cross_v[i],
                mask=self.textDecoder.mask,
            )
            n_layer_self_k_cache[i, :, : offset[0] + tokens.shape[-1], :] = self_k_cache
            n_layer_self_v_cache[i, :, : offset[0] + tokens.shape[-1], :] = self_v_cache
            i += 1

        x = self.textDecoder.ln(x)

        logits = (
            torch.matmul(
                self.textDecoder.token_embedding.weight.to(x.dtype),
                x.permute(0, 2, 1),
            )
            .permute(0, 2, 1)
            .float()
        )

        return logits, n_layer_self_k_cache, n_layer_self_v_cache


# ref: https://github.com/ggerganov/whisper.cpp/blob/master/models/convert-pt-to-ggml.py#L232
def convert_tokens(name, model):
    whisper_dir = Path(whisper.__file__).parent
    multilingual = model.is_multilingual
    tokenizer = (
        whisper_dir
        / "assets"
        / (multilingual and "multilingual.tiktoken" or "gpt2.tiktoken")
    )
    if not tokenizer.is_file():
        raise ValueError(f"Cannot find {tokenizer}")

    with open(tokenizer, "r", encoding="utf-8") as f:
        tokens = {
            token: int(rank)
            for token, rank in (line.split() for line in f.read().splitlines() if line)
        }

    with open(f"{name}-tokens.txt", "w", encoding="utf-8") as f:
        for t, i in tokens.items():
            f.write(f"{t} {i}\n")


def load_tadabur_checkpoint(ckpt_path: str) -> Whisper:
    """تحميل checkpoint المحوَّل من صيغة HF وبناء نموذج whisper."""
    print(f"تحميل checkpoint: {ckpt_path}")
    checkpoint = torch.load(ckpt_path, map_location="cpu")

    if "dims" not in checkpoint:
        raise ValueError("checkpoint لا يحتوي على dims")

    dims = ModelDimensions(*checkpoint["dims"].tolist())
    print(f"الأبعاد: {dims}")

    state = {k: v for k, v in checkpoint.items() if k != "dims"}
    model = Whisper(dims)
    result = model.load_state_dict(state, strict=True)
    print(
        f"تحميل الأوزان: missing={len(result.missing_keys)} "
        f"unexpected={len(result.unexpected_keys)}"
    )
    return model


@torch.no_grad()
def main():
    args = get_args()
    name = args.name
    ckpt = Path(args.ckpt)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    # السكريبت الرسمي يكتب الملفات في المجلد الحالي
    import os

    os.chdir(out_dir)

    opset_version = 17

    model = load_tadabur_checkpoint(str(ckpt))

    print(
        f"number of model parameters: {name}",
        sum(p.numel() for p in model.parameters()),
    )
    print(
        f"number of encoder parameters: {name}",
        sum(p.numel() for p in model.encoder.parameters()),
    )
    print(
        f"number of decoder parameters: {name}",
        sum(p.numel() for p in model.decoder.parameters()),
    )

    convert_tokens(name=name, model=model)

    # write tokens

    tokenizer = whisper.tokenizer.get_tokenizer(
        model.is_multilingual, num_languages=model.num_languages
    )

    model.eval()
    print(model.dims)
    audio = torch.rand(16000 * 2)
    audio = whisper.pad_or_trim(audio)
    assert audio.shape == (16000 * 30,), audio.shape

    n_mels = model.dims.n_mels

    mel = (
        whisper.log_mel_spectrogram(audio, n_mels=n_mels).to(model.device).unsqueeze(0)
    )
    batch_size = 1
    assert mel.shape == (batch_size, n_mels, 30 * 100), mel.shape

    encoder = AudioEncoderTensorCache(model.encoder, model.decoder)

    n_layer_cross_k, n_layer_cross_v = encoder(mel)
    assert n_layer_cross_k.shape == (
        model.dims.n_text_layer,
        batch_size,
        model.dims.n_audio_ctx,
        model.dims.n_text_state,
    ), (n_layer_cross_k.shape, model.dims)
    assert n_layer_cross_v.shape == (
        model.dims.n_text_layer,
        batch_size,
        model.dims.n_audio_ctx,
        model.dims.n_text_state,
    ), (n_layer_cross_v.shape, model.dims)

    encoder_filename = f"{name}-encoder.onnx"
    torch.onnx.export(
        encoder,
        mel,
        encoder_filename,
        opset_version=opset_version,
        input_names=["mel"],
        output_names=["n_layer_cross_k", "n_layer_cross_v"],
        dynamic_axes={
            "mel": {0: "n_audio", 2: "T"},  # n_audio is also known as batch_size
            "n_layer_cross_k": {1: "n_audio", 2: "T"},
            "n_layer_cross_v": {1: "n_audio", 2: "T"},
        },
    )

    encoder_meta_data = {
        "model_type": f"whisper-{name}",
        "version": "1",
        "maintainer": "mathani",
        "n_mels": model.dims.n_mels,

    n_audio = mel.shape[0]
    tokens = torch.tensor([[tokenizer.sot, tokenizer.sot, tokenizer.sot]] * n_audio).to(
        mel.device
    )  # [n_audio, 3]
    decoder = TextDecoderTensorCache(model.decoder, model.dims.n_text_ctx)
    n_layer_self_k_cache = torch.zeros(
        (
            len(model.decoder.blocks),
            n_audio,
            model.dims.n_text_ctx,
            model.dims.n_text_state,
        ),
        device=mel.device,
    )
    n_layer_self_v_cache = torch.zeros(
        (
            len(model.decoder.blocks),
            n_audio,
            model.dims.n_text_ctx,
            model.dims.n_text_state,
        ),
        device=mel.device,
    )
    offset = torch.zeros(1, dtype=torch.int64).to(mel.device)
    logits, n_layer_self_k_cache, n_layer_self_v_cache = decoder(
        tokens,
        n_layer_self_k_cache,
        n_layer_self_v_cache,
        n_layer_cross_k,
        n_layer_cross_v,
        offset,
    )
    assert logits.shape == (n_audio, tokens.shape[1], model.dims.n_vocab)
    assert n_layer_self_k_cache.shape == (
        model.dims.n_text_layer,
        n_audio,
        model.dims.n_text_ctx,
        model.dims.n_text_state,
    )
    assert n_layer_self_v_cache.shape == (
        model.dims.n_text_layer,
        n_audio,
        model.dims.n_text_ctx,
        model.dims.n_text_state,
    )

    offset = torch.tensor([tokens.shape[1]], dtype=torch.int64).to(mel.device)
    tokens = torch.tensor([[tokenizer.sot]] * n_audio).to(mel.device)  # [n_audio, 1]

    logits, out_n_layer_self_k_cache, out_n_layer_self_v_cache = decoder(
        tokens,
        n_layer_self_k_cache,
        n_layer_self_v_cache,
        n_layer_cross_k,
        n_layer_cross_v,
        offset,
    )

    decoder_filename = f"{name}-decoder.onnx"
    torch.onnx.export(
        decoder,
        (
            tokens,
            n_layer_self_k_cache,
            n_layer_self_v_cache,
            n_layer_cross_k,
            n_layer_cross_v,
            offset,
        ),
        decoder_filename,
        opset_version=opset_version,
        input_names=[
            "tokens",
            "in_n_layer_self_k_cache",
            "in_n_layer_self_v_cache",
            "n_layer_cross_k",
            "n_layer_cross_v",
            "offset",
        ],
        output_names=["logits", "out_n_layer_self_k_cache", "out_n_layer_self_v_cache"],
        dynamic_axes={
            "tokens": {0: "n_audio", 1: "n_tokens"},
            "in_n_layer_self_k_cache": {1: "n_audio"},
            "in_n_layer_self_v_cache": {1: "n_audio"},
            "n_layer_cross_k": {1: "n_audio", 2: "T"},
            "n_layer_cross_v": {1: "n_audio", 2: "T"},
        },
    )

    # Generate int8 quantization models
    # See https://onnxruntime.ai/docs/performance/model-optimizations/quantization.html#data-type-selection

    print("Generate int8 quantization models")

    encoder_filename_int8 = f"{name}-encoder.int8.onnx"
    quantize_dynamic(
        model_input=encoder_filename,
        model_output=encoder_filename_int8,
        op_types_to_quantize=["MatMul"],
        weight_type=QuantType.QInt8,
    )

    decoder_filename_int8 = f"{name}-decoder.int8.onnx"
    quantize_dynamic(
        model_input=decoder_filename,
        model_output=decoder_filename_int8,
        op_types_to_quantize=["MatMul"],
        weight_type=QuantType.QInt8,
    )

    # ------------------------------------------------------------------
    # أسماء نهائية مطابقة لتوقعات تطبيق Flutter (asr_service.dart)
    # ------------------------------------------------------------------
    import shutil

    pairs = [
        (encoder_filename_int8, "encoder.int8.onnx"),
        (decoder_filename_int8, "decoder.int8.onnx"),
        (f"{name}-encoder.onnx", "encoder.onnx"),
        (f"{name}-decoder.onnx", "decoder.onnx"),
        (f"{name}-tokens.txt", "tokens.txt"),
    ]
    for src, dst in pairs:
        if Path(src).exists():
            shutil.move(src, dst)
            size_mb = Path(dst).stat().st_size / 1024 / 1024
            print(f"✅ {dst} ({size_mb:.1f} MB)")
        else:
            print(f"⚠️ مفقود: {src}")

    print()
    print("🎉 اكتمل التصدير بنجاح! الملفات في:", out_dir)


if __name__ == "__main__":
    torch.set_num_threads(1)
    torch.set_num_interop_threads(1)
    # To fix
    # TypeError: scaled_dot_product_attention(): argument 'is_causal' must be bool, not Tensor
    # See also https://github.com/k2-fsa/sherpa-onnx/issues/1764
    try:
        from whisper.model import disable_sdpa

        with disable_sdpa():
            main()
    except ImportError:
        print("⚠️ disable_sdpa غير متوفر في هذه النسخة — تشغيل بدونها")
        main()

        "n_audio_ctx": model.dims.n_audio_ctx,
        "n_audio_state": model.dims.n_audio_state,
        "n_audio_head": model.dims.n_audio_head,
        "n_audio_layer": model.dims.n_audio_layer,
        "n_vocab": model.dims.n_vocab,
        "n_text_ctx": model.dims.n_text_ctx,
        "n_text_state": model.dims.n_text_state,
        "n_text_head": model.dims.n_text_head,
        "n_text_layer": model.dims.n_text_layer,
        "sot_sequence": ",".join(list(map(str, tokenizer.sot_sequence))),
        "all_language_tokens": ",".join(list(map(str, tokenizer.all_language_tokens))),
        "all_language_codes": ",".join(tokenizer.all_language_codes),
        "sot": tokenizer.sot,
        "sot_index": tokenizer.sot_sequence.index(tokenizer.sot),
        "eot": tokenizer.eot,
        "blank_id": tokenizer.encode(" ")[0],
        "is_multilingual": int(model.is_multilingual),
        "no_speech": tokenizer.no_speech,
        "non_speech_tokens": ",".join(list(map(str, tokenizer.non_speech_tokens))),
        "transcribe": tokenizer.transcribe,
        "translate": tokenizer.translate,
        "sot_prev": tokenizer.sot_prev,
        "sot_lm": tokenizer.sot_lm,
        "no_timestamps": tokenizer.no_timestamps,
    }
    print(f"encoder_meta_data: {encoder_meta_data}")
    add_meta_data(filename=encoder_filename, meta_data=encoder_meta_data)

                cross_k=n_layer_cross_k[i],
                cross_v=n_layer_cross_v[i],
                mask=self.textDecoder.mask,
            )
            n_layer_self_k_cache[i, :, : offset[0] + tokens.shape[-1], :] = self_k_cache
            n_layer_self_v_cache[i, :, : offset[0] + tokens.shape[-1], :] = self_v_cache
            i += 1

        x = self.textDecoder.ln(x)

        logits = (
            torch.matmul(
                self.textDecoder.token_embedding.weight.to(x.dtype),
                x.permute(0, 2, 1),
            )
            .permute(0, 2, 1)
            .float()
        )

        return logits, n_layer_self_k_cache, n_layer_self_v_cache

        x = block(x)

    x = self.ln_post(x)
    return x


AudioEncoder.forward = modified_audio_encoder_forward


class AudioEncoderTensorCache(nn.Module):
    def __init__(self, inAudioEncoder: AudioEncoder, inTextDecoder: TextDecoder):
        super().__init__()
        self.audioEncoder = inAudioEncoder
        self.textDecoder = inTextDecoder

    def forward(self, x: Tensor):
        audio_features = self.audioEncoder(x)

        n_layer_cross_k_list = []
        n_layer_cross_v_list = []
        for block in self.textDecoder.blocks:
            n_layer_cross_k_list.append(block.cross_attn.key(audio_features))
            n_layer_cross_v_list.append(block.cross_attn.value(audio_features))

        return torch.stack(n_layer_cross_k_list), torch.stack(n_layer_cross_v_list)

placeholder
