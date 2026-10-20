#!/usr/bin/env python3
"""Validate the offline card/question datasets before packaging the app."""
from __future__ import annotations

import base64
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise SystemExit(f"Invalid JSON in {path.relative_to(ROOT)}: {exc}") from exc


def require_text(value: Any, field: str, entry_id: str) -> None:
    if not isinstance(value, str) or not value.strip():
        raise SystemExit(f"Entry {entry_id!r} has an empty/invalid {field!r}")


def validate_cards(cards: Any, label: str) -> list[dict[str, Any]]:
    if not isinstance(cards, list) or not cards:
        raise SystemExit(f"{label} must be a non-empty JSON array")
    seen: set[str] = set()
    for item in cards:
        if not isinstance(item, dict):
            raise SystemExit(f"{label} contains a non-object entry")
        entry_id = item.get("id")
        require_text(entry_id, "id", str(entry_id))
        if entry_id in seen:
            raise SystemExit(f"Duplicate ID {entry_id!r} in {label}")
        seen.add(entry_id)
        for field in ("front", "back", "category", "lesson", "type"):
            require_text(item.get(field), field, entry_id)
        if "extra" in item and not isinstance(item["extra"], str):
            raise SystemExit(f"Entry {entry_id!r} has a non-text 'extra' field")
    return cards


def main() -> None:
    deck = validate_cards(load_json(ROOT / "assets/generated_original_deck.json"), "original deck")
    pack = load_json(ROOT / "assets/generated_persian_pack.json")
    if not isinstance(pack, dict):
        raise SystemExit("generated_persian_pack.json must contain a JSON object")
    vocab = validate_cards(pack.get("vocabCards"), "Persian vocabulary pack")

    all_card_ids = [item["id"] for item in deck + vocab]
    if len(all_card_ids) != len(set(all_card_ids)):
        raise SystemExit("Card IDs must also be unique across the original deck and Persian pack")

    questions = pack.get("questions")
    if not isinstance(questions, list) or not questions:
        raise SystemExit("Persian pack must contain a non-empty 'questions' array")
    question_ids: set[str] = set()
    for item in questions:
        if not isinstance(item, dict):
            raise SystemExit("The questions array contains a non-object entry")
        qid = item.get("id")
        require_text(qid, "id", str(qid))
        if qid in question_ids:
            raise SystemExit(f"Duplicate question ID {qid!r}")
        question_ids.add(qid)
        for field in ("lesson", "sentence"):
            require_text(item.get(field), field, qid)
        options = item.get("options")
        index = item.get("correctIndex")
        if not isinstance(options, list) or len(options) < 2 or any(not isinstance(x, str) or not x.strip() for x in options):
            raise SystemExit(f"Question {qid!r} must have at least two non-empty text options")
        if type(index) is not int or index < 0 or index >= len(options):
            raise SystemExit(f"Question {qid!r} has an invalid correctIndex")

    collisions = set(all_card_ids).intersection(question_ids)
    if collisions:
        raise SystemExit(f"Card/question IDs must not collide: {sorted(collisions)[:5]}")

    encoded_icon = (ROOT / "assets/glia_app_icon.png.b64").read_bytes()
    try:
        icon = base64.b64decode(encoded_icon, validate=False)
    except Exception as exc:
        raise SystemExit(f"Could not decode launcher icon: {exc}") from exc
    if not icon.startswith(b"\x89PNG\r\n\x1a\n"):
        raise SystemExit("Launcher icon payload is not a valid PNG")

    print(
        "Offline data validation passed: "
        f"{len(deck)} primary cards, {len(questions)} spelling questions, "
        f"{len(vocab)} Persian pack cards; launcher PNG is valid."
    )


if __name__ == "__main__":
    main()
