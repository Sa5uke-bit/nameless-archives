#!/usr/bin/env python3
"""Build a Bailian voice manifest and attach voice paths to chapter dialogue JSON."""

from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CHAPTER_01_DIALOGUE_FILES = (
    PROJECT_ROOT / "data/dialogue/chapter_01_prologue.json",
    PROJECT_ROOT / "data/dialogue/chapter_01_room_307.json",
    PROJECT_ROOT / "data/dialogue/chapter_01_laundry.json",
    PROJECT_ROOT / "data/dialogue/chapter_01_finale.json",
)
MODEL = "qwen3-tts-instruct-flash"

CAST_CHAPTER_01: dict[str, dict[str, str]] = {
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

CAST_CHAPTER_02: dict[str, dict[str, str]] = {
    "侦探": CAST_CHAPTER_01["侦探"],
    "旁白": CAST_CHAPTER_01["旁白"],
    "方芸": {
        "slug": "fang_yun",
        "voice": "Serena",
        "base": "三十六岁女性，声音温和但有清楚边界，长期疲惫而谨慎。现实主义表演，不柔弱，不故作神秘。",
    },
    "杨佩": {
        "slug": "yang_pei",
        "voice": "Vivian",
        "base": "三十三岁女性，曾是舞台替补演员，嗓音清亮而控制严密。保留舞台训练形成的清楚咬字，收住俏皮感和少女感。",
    },
    "徐峥": {
        "slug": "xu_zheng",
        "voice": "Ethan",
        "base": "二十八岁男性音响师，中音偏轻，聪明直接，有一点紧张。说话具体，不阳光活泼，不使用播音腔。",
    },
    "梁绍康": {
        "slug": "liang_shaokang",
        "voice": "Eldric Sage",
        "base": "五十七岁男性管理者，低中音，清楚缓慢，习惯支配谈话。声音不高，不慈祥，不说书，不做脸谱化反派表演。",
    },
}

CAST_CHAPTER_03: dict[str, dict[str, str]] = {
    "侦探": CAST_CHAPTER_01["侦探"],
    "旁白": CAST_CHAPTER_01["旁白"],
    "陈默": {
        "slug": "chen_mo",
        "voice": "Vincent",
        "base": "四十五岁男性，前夜班门卫，嗓音粗粝疲惫但不凶狠。说话朴实、克制，有被长期误解后的谨慎，不使用武侠或苦情腔。",
    },
    "罗遥": {
        "slug": "luo_yao",
        "voice": "Serena",
        "base": "三十六岁女性，前售票员和档案志愿者，音色温和清楚，观察力强，带压住的内疚。现实主义表演，不柔弱，不故作神秘。",
    },
    "邓守义": {
        "slug": "deng_shouyi",
        "voice": "Arthur",
        "base": "六十一岁男性，退休山路司机，声音年长、厚实、疲惫。承认错误时不煽情，日常口语，不使用说书腔或慈祥长者腔。",
    },
    "黄维国": {
        "slug": "huang_weiguo",
        "voice": "Eldric Sage",
        "base": "六十四岁男性，前客运站站长，低中音平稳清楚，习惯用行政措辞控制谈话。防御而非咆哮，不做脸谱化反派，不冷笑。",
    },
}

CHAPTER_CONFIGS = {
    "1": {
        "dialogue_files": CHAPTER_01_DIALOGUE_FILES,
        "manifest_path": PROJECT_ROOT / "data/voice/chapter_01_full.jsonl",
        "voice_root": "res://assets/audio/dialogue/chapter_01",
        "cast": CAST_CHAPTER_01,
    },
    "2": {
        "dialogue_files": tuple(sorted((PROJECT_ROOT / "data/dialogue").glob("chapter_02_*.json"))),
        "manifest_path": PROJECT_ROOT / "data/voice/chapter_02_full.jsonl",
        "voice_root": "res://assets/audio/dialogue/chapter_02",
        "cast": CAST_CHAPTER_02,
    },
    "3": {
        "dialogue_files": tuple(sorted((PROJECT_ROOT / "data/dialogue").glob("chapter_03_*.json"))),
        "manifest_path": PROJECT_ROOT / "data/voice/chapter_03_full.jsonl",
        "voice_root": "res://assets/audio/dialogue/chapter_03",
        "cast": CAST_CHAPTER_03,
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
    "d31_success",
    "d32_success",
    "d33_success",
    "timeline_success",
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
    if "P-17" in text:
        parts.append("P-17读作“P十七”。")
    if "A 带" in text or "B 带" in text:
        parts.append("A带和B带分别按英文字母A、B加中文“带”来读。")
    return "".join(parts)


def _build(
    dialogue_files: tuple[Path, ...],
    voice_root: str,
    cast_map: dict[str, dict[str, str]],
) -> tuple[dict[Path, dict[str, Any]], list[dict[str, Any]]]:
    updated_files: dict[Path, dict[str, Any]] = {}
    jobs: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    seen_outputs: set[str] = set()

    for dialogue_path in dialogue_files:
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
                if speaker not in cast_map:
                    line.pop("voice", None)
                    line.pop("voice_bus", None)
                    continue

                cast = cast_map[speaker]
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

                line["voice"] = f"{voice_root}/{output}"
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


def _check(
    updated_files: dict[Path, dict[str, Any]],
    jobs: list[dict[str, Any]],
    manifest_path: Path,
) -> int:
    mismatches: list[str] = []
    for path, expected in updated_files.items():
        if path.read_text(encoding="utf-8") != _dumps(expected):
            mismatches.append(str(path.relative_to(PROJECT_ROOT)))
    expected_manifest = _manifest_text(jobs)
    if not manifest_path.is_file() or manifest_path.read_text(encoding="utf-8") != expected_manifest:
        mismatches.append(str(manifest_path.relative_to(PROJECT_ROOT)))
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
    parser.add_argument("--chapter", choices=sorted(CHAPTER_CONFIGS), default="1")
    args = parser.parse_args()
    config = CHAPTER_CONFIGS[args.chapter]
    dialogue_files = config["dialogue_files"]
    manifest_path = config["manifest_path"]
    voice_root = config["voice_root"]
    cast_map = config["cast"]
    updated_files, jobs = _build(dialogue_files, voice_root, cast_map)
    if args.check:
        return _check(updated_files, jobs, manifest_path)

    for path, updated in updated_files.items():
        path.write_text(_dumps(updated), encoding="utf-8")
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(_manifest_text(jobs), encoding="utf-8")
    speakers = sorted({job["speaker"] for job in jobs})
    print(
        json.dumps(
            {
                "jobs": len(jobs),
                "characters": sum(len(job["text"]) for job in jobs),
                "speakers": speakers,
                "manifest": str(manifest_path.relative_to(PROJECT_ROOT)),
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
