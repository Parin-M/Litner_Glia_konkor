#!/usr/bin/env python3
import json, os, struct, subprocess, sys
from pathlib import Path

MODEL_DIR = Path("build/noql")
ASSET_DIR = Path("assets/ai")
MODEL_DIR.mkdir(parents=True, exist_ok=True)
ASSET_DIR.mkdir(parents=True, exist_ok=True)

from huggingface_hub import snapshot_download
snapshot_download(repo_id="shekar-ai/Noql", local_dir=str(MODEL_DIR), local_dir_use_symlinks=False)

import torch
import torch.nn as nn
import torch.nn.functional as F
from sentence_transformers import SentenceTransformer

model = SentenceTransformer(str(MODEL_DIR), device="cpu")
transformer = model[0].auto_model

class NoqlWrapper(nn.Module):
    def __init__(self, encoder):
        super().__init__()
        self.encoder = encoder
    def forward(self, input_ids, attention_mask):
        out = self.encoder(input_ids=input_ids, attention_mask=attention_mask)
        hidden = out.last_hidden_state
        mask = attention_mask.unsqueeze(-1).to(hidden.dtype)
        pooled = (hidden * mask).sum(dim=1) / mask.sum(dim=1).clamp_min(1e-6)
        normalized = F.normalize(pooled, p=2, dim=1)
        return normalized[:, :256]

wrapper = NoqlWrapper(transformer).eval()
example_ids = torch.ones((1, 64), dtype=torch.long)
example_mask = torch.ones((1, 64), dtype=torch.long)
onnx_path = ASSET_DIR / "noql.onnx"

torch.onnx.export(
    wrapper,
    (example_ids, example_mask),
    str(onnx_path),
    input_names=["input_ids", "attention_mask"],
    output_names=["embedding"],
    dynamic_axes={
        "input_ids": {0: "batch", 1: "sequence"},
        "attention_mask": {0: "batch", 1: "sequence"},
        "embedding": {0: "batch"},
    },
    opset_version=17,
    do_constant_folding=True,
)

from onnxruntime.quantization import quantize_dynamic, QuantType
quantized = ASSET_DIR / "noql-int8.onnx"
quantize_dynamic(str(onnx_path), str(quantized), weight_type=QuantType.QInt8)
quantized.replace(onnx_path)

for name in ["tokenizer.json"]:
    src = MODEL_DIR / name
    if not src.exists():
        raise FileNotFoundError(src)
    (ASSET_DIR / name).write_bytes(src.read_bytes())

with open("assets/generated_original_deck.json", "r", encoding="utf-8") as f:
    cards = json.load(f)
with open("assets/generated_persian_pack.json", "r", encoding="utf-8") as f:
    cards += json.load(f)

texts = []
for c in cards:
    texts.append(" | ".join(x for x in [c.get("front",""), c.get("back",""), c.get("extra",""), c.get("lesson","")] if x))

embeddings = model.encode(
    texts,
    batch_size=64,
    show_progress_bar=True,
    normalize_embeddings=True,
    truncate_dim=256,
    convert_to_numpy=True,
)

if embeddings.shape[1] != 256:
    raise RuntimeError(f"Unexpected embedding size: {embeddings.shape}")

with open(ASSET_DIR / "card_embeddings.bin", "wb") as f:
    f.write(struct.pack("<II", embeddings.shape[0], embeddings.shape[1]))
    f.write(embeddings.astype("float32").tobytes(order="C"))

print(f"Noql ready: {len(cards)} cards, {onnx_path.stat().st_size / 1024 / 1024:.1f} MB model")
