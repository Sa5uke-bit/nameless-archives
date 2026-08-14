#!/usr/bin/env python3
"""Build the chapter-one Bailian manifest and attach voice paths to dialogue JSON."""

from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DIALOGUE_FILES = (
    PROJECT_ROOT / "data/dialogue/chapter_01_prologue.json",
    PROJECT_ROOT / "data/dialogue/chapter_01_room_307.json",
    PROJECT_ROOT / "data/dialogue/chapter_01_laundry.json",
    PROJECT_ROOT / "data/dialogue/chapter_01_finale.json",
)
MANIFEST_PATH = PROJECT_ROOT / "data/voice/chapter_01_full.jsonl"
VOICE_ROOT = "res://assets/audio/dialogue/chapter_01"
MODEL = "qwen3-tts-instruct-flash"

CAST: dict[str, dict[str, str]] = {
    "侦探": {
        "slug": "detective",
        "voice": "Moon",
        "base": "三十多岁的职业侦探，低中音，沉稳清晰，带分析感。现实主义表演，不故作深沉，不使用播音腔。",
    },
    "旁白": {
        "slug": "narrator",
        "voice": "Neil",
        "base": "成熟男性叙述者，清楚客观，有轻微纪录片质感但不过分正式。保持克制，不使用恐怖预告腔。",
    },
    "乔雯": {
        "slug": "qiao_wen",
        "voice": "Maia",
        "base": "四十岁左右女性，知性温和，声音里有长期疲惫和谨慎。保护欲强但不柔弱，不故作神秘。",
    },
    "顾宁": {
        "slug": "gu_ning",
        "voice": "Elias",
        "base": "三十多岁女性，低沉冷静，措辞利落，习惯掌控局面。情绪内收，避免讲课腔和夸张哭腔。",
    },
    "赵成": {
        "slug": "zhao_cheng",
        "voice": "Vincent",
        "base": "五十岁左右维修工，嗓音粗粝疲惫，防备而负罪。口语真实克制，不使用武侠豪迈或恐怖故事腔。",
    },
    "顾海川": {
        "slug": "gu_haichuan",
        "voice": "Arthur",
        "base": "六十岁左右男性经营者，声音不高却习惯支配别人，缓慢冷静。避免乡野说书腔和脸谱化反派表演。",
    },
    "？？？": {
        "slug": "mystery",
        "voice": "Elias",
        "base": "使用顾宁同一声音身份，低声、急促、像一句被旧金属传声管截断的话。来源遥远但仍是现实人声，不表现成鬼魂。",
    },
}

PRESSURE_MARKERS = (
    "wrong",
    "success",
    "reveal",
    "confess",
    "finale",
    "truth_",
    "accusation",
    "after_d01",
)
QUIET_MARKERS = (
    "repeat",
    "room_307_locked",
    "room_entry",
    "window_first",
)


def _dumps(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def _mood_direction(conversation_id: str, speaker: str) -> str:
    if speaker == "？？？":
        return "句子很短，保留自然停顿，音量偏低。"
    if any(marker in conversation_id for marker in PRESSURE_MARKERS):
        return "当前处于对质、承认或推理推进段落，增加紧张与确定感，但不要喊叫或煽情。"
    if any(marker in conversation_id for marker in QUIET_MARKERS):
        return "当前是复查、回忆或含混段落，音量稍低、语速略慢，保留自然余韵。"
    return "按日常基线自然陈述，停顿清楚，不额外渲染悬疑。"


def _instructions(cast: dict[str, str], conversation_id: str, speaker: str, text: str) -> str:
    parts = [cast["base"], _mood_direction(conversation_id, speaker)]
    if "307" in text:
        parts.append("数字307读作“三零七”。")
    return "".join(parts)


def _build() -> tuple[dict[Path, dict[str, Any]], list[dict[str, Any]]]:
    updated_files: dict[Path, dict[str, Any]] = {}
    jobs: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    seen_outputs: set[str] = set()

    for dialogue_path in DIALOGUE_FILES:
        data = json.loads(dialogue_path.read_text(encoding="utf-8"))
        updated = copy.deepcopy(data)
        conversations = updated.get("conversations")
        if not isinstance(conversations, dict):
            raise ValueError(f"Missing conversations object: {dialogue_path}")

        for conversation_id, lines in conversations.items():
            if not isinstance(lines, list):
                raise ValueError(f"Conversation is not an array: {dialogue_path}:{conversation_id}")
            for line_index, line in enumerate(lines):
                if not isinstance(line, dict):
                    raise ValueError(
                        f"Dialogue line is not an object: {dialogue_path}:{conversation_id}:{line_index}"
                    )
                speaker = str(line.get("speaker", "")).strip()
                text = str(line.get("text", "")).strip()
                if not text:
                    raise ValueError(
                        f"Dialogue line has no text: {dialogue_path}:{conversation_id}:{line_index}"
                    )
                if speaker not in CAST:
                    line.pop("voice", None)
                    line.pop("voice_bus", None)
                    continue

                cast = CAST[speaker]
                job_id = f"{dialogue_path.stem}.{conversation_id}.{line_index:03d}"
                output = (
                    f"{cast['slug']}/{dialogue_path.stem}_{conversation_id}_{line_index:02d}.wav"
                )
                if job_id in seen_ids:
                    raise ValueError(f"Duplicate voice job id: {job_id}")
                if output in seen_outputs:
                    raise ValueError(f"Duplicate voice output: {output}")
                seen_ids.add(job_id)
                seen_outputs.add(output)

                line["voice"] = f"{VOICE_ROOT}/{output}"
                line["voice_bus"] = "VoiceDuct" if speaker == "？？？" else "Voice"
                jobs.append(
                    {
                        "id": job_id,
                        "speaker": speaker,
                        "text": text,
                        "out": output,
                        "model": MODEL,
                        "voice": cast["voice"],
                        "language_type": "Chinese",
                        "instructions": _instructions(cast, conversation_id, speaker, text),
                        "optimize_instructions": True,
                    }
                )
        updated_files[dialogue_path] = updated
    return updated_files, jobs


def _manifest_text(jobs: list[dict[str, Any]]) -> str:
    return "".join(json.dumps(job, ensure_ascii=False, separators=(",", ":")) + "\n" for job in jobs)


def _check(updated_files: dict[Path, dict[str, Any]], jobs: list[dict[str, Any]]) -> int:
    mismatches: list[str] = []
    for path, expected in updated_files.items():
        if path.read_text(encoding="utf-8") != _dumps(expected):
            mismatches.append(str(path.relative_to(PROJECT_ROOT)))
    expected_manifest = _manifest_text(jobs)
    if not MANIFEST_PATH.is_file() or MANIFEST_PATH.read_text(encoding="utf-8") != expected_manifest:
        mismatches.append(str(MANIFEST_PATH.relative_to(PROJECT_ROOT)))
    if mismatches:
        print("Voice data needs rebuilding:")
        for mismatch in mismatches:
            print(f"- {mismatch}")
        return 1
    print(f"Voice data is current: {len(jobs)} lines, {sum(len(job['text']) for job in jobs)} characters")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify generated data without writing")
    args = parser.parse_args()
    updated_files, jobs = _build()
    if args.check:
        return _check(updated_files, jobs)

    for path, updated in updated_files.items():
        path.write_text(_dumps(updated), encoding="utf-8")
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(_manifest_text(jobs), encoding="utf-8")
    speakers = sorted({job["speaker"] for job in jobs})
    print(
        json.dumps(
            {
                "jobs": len(jobs),
                "characters": sum(len(job["text"]) for job in jobs),
                "speakers": speakers,
                "manifest": str(MANIFEST_PATH.relative_to(PROJECT_ROOT)),
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
