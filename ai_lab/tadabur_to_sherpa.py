#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
تحويل نموذج تدبر (FaisaI/tadabur-Whisper-Small) من صيغة HuggingFace إلى
الصيغة الرسمية لـ sherpa-onnx: encoder.int8.onnx + decoder.int8.onnx + tokens.txt

الخوارزمية (مبنية على السكريبت الرسمي k2-fsa/sherpa-onnx/scripts/whisper/export-onnx.py):

  1) convert  : model.safetensors (HF, بادئة "model.") → checkpoint بصيغة openai-whisper
                {"dims": {...}, "model_state_dict": {...}} مع نسخ مباشر (بدون transposes
                لأن كلا الطرفين nn.Linear بنفس ترتيب out×in) وتحقق strict بـ load_state_dict.
  2) export   : واجهة KV-cache الرسمية لـ sherpa-onnx:
                encoder → (n_layer_cross_k, n_layer_cross_v) مكدسة عبر طبقات decoder
                decoder(tokens, self_k_cache, self_v_cache, cross_k, cross_v, offset)
                          → (logits, out_self_k_cache, out_self_v_cache)
                logits = matmul(token_embedding.weight, x.T)
  3) tokens   : tokens.txt بتنسيق base64 (نسخ multilingual.tiktoken حرفياً — نفس
                صيغة النماذج الرسمية على huggingface csukuangfj/sherpa-onnx-whisper-*).
  4) metadata : مفاتيح sherpa الرسمية من whisper.tokenizer (sot_sequence، اللغات...).
  5) quantize : quantize_dynamic MatMul-only QInt8 (كما في السكريبت الرسمي).
  6) test     : مقارنة نص التلاوة: HF transformers generate (الحقيقة المرجعية)
                مقابل sherpa_onnx OfflineRecognizer.from_whisper(language="ar").

الاستخدام:
  python tadabur_to_sherpa.py --stage convert
  python tadabur_to_sherpa.py --stage export
  python tadabur_to_sherpa.py --stage test
  python tadabur_to_sherpa.py --stage all
"""

import argparse
import os
import shutil
import sys
import wave
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
    MultiHeadAttention,
    ResidualAttentionBlock,

# ---------------------------------------------------------------------------
# Stage 1: تحويل أوزان HF → صيغة openai-whisper (نسخ مباشر بدون transposes)
# ---------------------------------------------------------------------------

ENCODER_BLOCK_MAP = {
    "self_attn.q_proj.weight": "attn.query.weight",
    "self_attn.k_proj.weight": "attn.key.weight",   # openai: key بلا bias
    "self_attn.v_proj.weight": "attn.value.weight",
    "self_attn.out_proj.weight": "attn.out.weight",
    "self_attn.out_proj.bias": "attn.out.bias",
    "fc1.weight": "mlp.0.weight",
    "fc1.bias": "mlp.0.bias",
    "fc2.weight": "mlp.2.weight",
    "fc2.bias": "mlp.2.bias",
    "self_attn_layer_norm.weight": "attn_ln.weight",
    "self_attn_layer_norm.bias": "attn_ln.bias",
    "final_layer_norm.weight": "mlp_ln.weight",
    "final_layer_norm.bias": "mlp_ln.bias",
}

DECODER_BLOCK_MAP = dict(ENCODER_BLOCK_MAP)
DECODER_BLOCK_MAP.update(
    {
        "self_attn.q_proj.bias": "attn.query.bias",
        "self_attn.v_proj.bias": "attn.value.bias",
        "encoder_attn.q_proj.weight": "cross_attn.query.weight",
        "encoder_attn.q_proj.bias": "cross_attn.query.bias",
        "encoder_attn.k_proj.weight": "cross_attn.key.weight",
        "encoder_attn.v_proj.weight": "cross_attn.value.weight",
        "encoder_attn.v_proj.bias": "cross_attn.value.bias",
        "encoder_attn.out_proj.weight": "cross_attn.out.weight",
        "encoder_attn.out_proj.bias": "cross_attn.out.bias",
        "encoder_attn_layer_norm.weight": "cross_attn_ln.weight",
        "encoder_attn_layer_norm.bias": "cross_attn_ln.bias",
    }
)


def convert_stage(hf_dir: Path, out_dir: Path, ckpt_path: Path) -> None:
    from safetensors.torch import load_file

    print("=" * 60)
    print("[stage 1] تحويل أوزان HuggingFace → صيغة openai-whisper")
    print("=" * 60)

    print(f"تحميل {hf_dir / 'model.safetensors'} ...")
    hf = load_file(str(hf_dir / "model.safetensors"))
    print(f"عدد مفاتيح HF: {len(hf)}")

    # أعداد الطبقات من المفاتيح الفعلية
    n_audio_layer = len({k.split(".")[3] for k in hf if k.startswith("model.encoder.layers.")})
    n_text_layer = len({k.split(".")[3] for k in hf if k.startswith("model.decoder.layers.")})
    n_mels = hf["model.encoder.conv1.weight"].shape[1]
    n_audio_state = hf["model.encoder.conv1.bias"].shape[0]
    n_text_state = hf["model.decoder.embed_tokens.weight"].shape[1]
    n_vocab = hf["model.decoder.embed_tokens.weight"].shape[0]
    n_audio_ctx = hf["model.encoder.embed_positions.weight"].shape[0]
    n_text_ctx = hf["model.decoder.embed_positions.weight"].shape[0]
    dims = {
        "n_mels": n_mels,
        "n_vocab": n_vocab,
        "n_audio_ctx": n_audio_ctx,
        "n_audio_state": n_audio_state,
        "n_audio_head": n_audio_state // 64,
        "n_audio_layer": n_audio_layer,
    def mv(src: str, dst: str) -> None:
        assert src in hf, f"مفتاح مفقود في HF: {src}"
        assert dst not in state, f"مفتاح مكرر: {dst}"
        state[dst] = hf[src].float()

    # ---- encoder (خارج الطبقات) ----
    mv("model.encoder.conv1.weight", "encoder.conv1.weight")
    mv("model.encoder.conv1.bias", "encoder.conv1.bias")
    mv("model.encoder.conv2.weight", "encoder.conv2.weight")
    mv("model.encoder.conv2.bias", "encoder.conv2.bias")
    mv("model.encoder.layer_norm.weight", "encoder.ln_post.weight")
    mv("model.encoder.layer_norm.bias", "encoder.ln_post.bias")
    pos = hf["model.encoder.embed_positions.weight"]
    assert pos.shape[0] >= n_audio_ctx, f"مواقع encoder قصيرة: {pos.shape}"
    state["encoder.positional_embedding"] = pos[:n_audio_ctx].float()

    # ---- encoder blocks ----
    for i in range(n_audio_layer):
        for src, dst in ENCODER_BLOCK_MAP.items():
            mv(f"model.encoder.layers.{i}.{src}", f"encoder.blocks.{i}.{dst}")

    # ---- decoder (خارج الطبقات) ----
    mv("model.decoder.embed_tokens.weight", "decoder.token_embedding.weight")
    dpos = hf["model.decoder.embed_positions.weight"]
    assert dpos.shape[0] >= n_text_ctx, f"مواقع decoder قصيرة: {dpos.shape}"
    state["decoder.positional_embedding"] = dpos[:n_text_ctx].float()
    mv("model.decoder.layer_norm.weight", "decoder.ln.weight")
    mv("model.decoder.layer_norm.bias", "decoder.ln.bias")

    # ---- decoder blocks ----
    for i in range(n_text_layer):
        for src, dst in DECODER_BLOCK_MAP.items():
            mv(f"model.decoder.layers.{i}.{src}", f"decoder.blocks.{i}.{dst}")

    print(f"عدد الأوزان المحوّلة: {len(state)}")

    # ---- تحقق صارم: بناء نموذج whisper وتحميل الأوزان بـ strict=True ----
    wd = whisper.model.ModelDimensions(**dims)
    ref = Whisper(wd)
    ref_keys = set(ref.state_dict().keys())
    our_keys = set(state.keys())
    missing = ref_keys - our_keys
    unexpected = our_keys - ref_keys
    assert not unexpected, f"مفاتيح زائدة: {sorted(unexpected)[:6]}"
    assert not missing, f"مفاتيح ناقصة: {sorted(missing)[:6]}"
    # أطوال متطابقة
    for k in list(ref_keys)[:0]:
        pass
    ref_sd = ref.state_dict()
    for k in state:
        assert tuple(ref_sd[k].shape) == tuple(state[k].shape), (
            f"shape mismatch {k}: whisper={tuple(ref_sd[k].shape)} hf={tuple(state[k].shape)}"
        )
    ref.load_state_dict(state, strict=True)
    print("✅ تحميل strict ناجح — جميع الأوزان متطابقة الأسماء والأبعاد")

    ckpt_path.parent.mkdir(parents=True, exist_ok=True)
    torch.save({"dims": dims, "model_state_dict": state}, ckpt_path)
    size_mb = ckpt_path.stat().st_size / 1024 / 1024
    print(f"✅ checkpoint: {ckpt_path} ({size_mb:.1f} MB)")

        "n_text_ctx": n_text_ctx,
        "n_text_state": n_text_state,
        "n_text_head": n_text_state // 64,
        "n_text_layer": n_text_layer,
    }
    print(f"الأبعاد: {dims}")

    state: Dict[str, torch.Tensor] = {}

    def mv(src: str, dst: str) -> None:
        assert src in hf, f"مفتاح مفقود في HF: {src}"
        assert dst not in state, f"مفتاح مكرر: {dst}"
        state[dst] = hf[src].float()

    TextDecoder,
    Whisper,
)

DEFAULT_HF_DIR = r"C:\Projects\mathani\tadabur"
DEFAULT_OUT_DIR = r"C:\Projects\mathani\ai_lab\tadabur_sherpa_v2"
DEFAULT_WAV = r"C:\Projects\mathani\ai_lab\release_files\test_ayah.wav"

placeholder
