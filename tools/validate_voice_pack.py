#!/usr/bin/env python3
"""Validate generated voice files against chapter dialogue data and metadata."""

from __future__ import annotations

import argparse
import json
import wave
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DIALOGUE_DIR = PROJECT_ROOT / "data/dialogue"
CHAPTER_CONFIGS = {
    "1": {
        "manifest_path": PROJECT_ROOT / "data/voice/chapter_01_full.jsonl",
        "audio_root": PROJECT_ROOT / "assets/audio/dialogue/chapter_01",
        "dialogue_glob": "chapter_01_*.json",
        "resource_prefix": "res://assets/audio/dialogue/chapter_01/",
    },
    "2": {
        "manifest_path": PROJECT_ROOT / "data/voice/chapter_02_full.jsonl",
        "audio_root": PROJECT_ROOT / "assets/audio/dialogue/chapter_02",
        "dialogue_glob": "chapter_02_*.json",
        "resource_prefix": "res://assets/audio/dialogue/chapter_02/",
    },
    "3": {
        "manifest_path": PROJECT_ROOT / "data/voice/chapter_03_full.jsonl",
        "audio_root": PROJECT_ROOT / "assets/audio/dialogue/chapter_03",
        "dialogue_glob": "chapter_03_*.json",
        "resource_prefix": "res://assets/audio/dialogue/chapter_03/",
    },
    "4": {
        "manifest_path": PROJECT_ROOT / "data/voice/chapter_04_full.jsonl",
        "audio_root": PROJECT_ROOT / "assets/audio/dialogue/chapter_04",
        "dialogue_glob": "chapter_04_*.json",
        "resource_prefix": "res://assets/audio/dialogue/chapter_04/",
    },
}


def _load_manifest(manifest_path: Path) -> list[dict[str, Any]]:
    jobs: list[dict[str, Any]] = []
    for line_number, line in enumerate(
        manifest_path.read_text(encoding="utf-8-sig").splitlines(), start=1
    ):
        if not line.strip():
            continue
        value = json.loads(line)
        if not isinstance(value, dict):
            raise ValueError(f"Manifest line {line_number} is not an object")
        jobs.append(value)
    return jobs


def _dialogue_voice_paths(dialogue_glob: str, resource_prefix: str) -> set[str]:
    paths: set[str] = set()
    for dialogue_path in sorted(DIALOGUE_DIR.glob(dialogue_glob)):
        data = json.loads(dialogue_path.read_text(encoding="utf-8"))
        for lines in data["conversations"].values():
            for line in lines:
                voice = str(line.get("voice", ""))
                if voice:
                    if not voice.startswith(resource_prefix):
                        raise ValueError(f"Unexpected voice resource path: {voice}")
                    paths.add(voice.removeprefix(resource_prefix))
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chapter", choices=sorted(CHAPTER_CONFIGS), default="1")
    args = parser.parse_args()
    config = CHAPTER_CONFIGS[args.chapter]
    manifest_path: Path = config["manifest_path"]
    audio_root: Path = config["audio_root"]
    dialogue_glob: str = config["dialogue_glob"]
    resource_prefix: str = config["resource_prefix"]
    jobs = _load_manifest(manifest_path)
    errors: list[str] = []
    expected_outputs: set[str] = set()
    request_ids: set[str] = set()
    voices: set[str] = set()
    speakers: set[str] = set()
    durations: list[float] = []
    total_bytes = 0

    for job in jobs:
        output = str(job.get("out", ""))
        job_id = str(job.get("id", ""))
        if output in expected_outputs:
            errors.append(f"duplicate output: {output}")
            continue
        expected_outputs.add(output)
        voices.add(str(job.get("voice", "")))
        speakers.add(str(job.get("speaker", "")))

        audio_path = audio_root / output
        meta_path = audio_path.with_name(audio_path.name + ".meta.json")
        if not audio_path.is_file():
            errors.append(f"missing audio: {output}")
            continue
        if not meta_path.is_file():
            errors.append(f"missing metadata: {output}")
            continue
        total_bytes += audio_path.stat().st_size

        try:
            with wave.open(str(audio_path), "rb") as audio:
                if audio.getnchannels() != 1:
                    errors.append(f"not mono: {output}")
                if audio.getsampwidth() != 2:
                    errors.append(f"not 16-bit PCM: {output}")
                if audio.getframerate() != 24000:
                    errors.append(f"unexpected sample rate: {output}")
                if audio.getcomptype() != "NONE":
                    errors.append(f"compressed WAV: {output}")
                duration = audio.getnframes() / audio.getframerate()
                if duration < 0.2:
                    errors.append(f"audio too short: {output}")
                durations.append(duration)
        except (wave.Error, OSError) as error:
            errors.append(f"invalid WAV {output}: {error}")
            continue

        metadata = json.loads(meta_path.read_text(encoding="utf-8"))
        meta_job = metadata.get("job", {})
        for field in ("id", "speaker", "text", "model", "voice"):
            if meta_job.get(field) != job.get(field):
                errors.append(f"metadata mismatch for {job_id}: {field}")
        fingerprint = str(metadata.get("fingerprint", ""))
        if len(fingerprint) != 64:
            errors.append(f"invalid fingerprint: {job_id}")
        request_id = str(metadata.get("request_id", ""))
        if not request_id:
            errors.append(f"missing request id: {job_id}")
        elif request_id in request_ids:
            errors.append(f"duplicate request id: {request_id}")
        request_ids.add(request_id)

    actual_wavs = {
        path.relative_to(audio_root).as_posix() for path in audio_root.rglob("*.wav")
    }
    if actual_wavs != expected_outputs:
        for extra in sorted(actual_wavs - expected_outputs):
            errors.append(f"unlisted audio: {extra}")
        for missing in sorted(expected_outputs - actual_wavs):
            errors.append(f"manifest output absent: {missing}")

    dialogue_paths = _dialogue_voice_paths(dialogue_glob, resource_prefix)
    if dialogue_paths != expected_outputs:
        for extra in sorted(dialogue_paths - expected_outputs):
            errors.append(f"dialogue references unlisted audio: {extra}")
        for missing in sorted(expected_outputs - dialogue_paths):
            errors.append(f"audio is not referenced by dialogue: {missing}")

    if errors:
        print("VOICE PACK VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        json.dumps(
            {
                "status": "valid",
                "lines": len(jobs),
                "characters": sum(len(str(job["text"])) for job in jobs),
                "speakers": len(speakers),
                "system_voices": len(voices),
                "duration_seconds": round(sum(durations), 2),
                "audio_bytes": total_bytes,
                "request_ids": len(request_ids),
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
