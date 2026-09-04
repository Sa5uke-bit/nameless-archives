#!/usr/bin/env python3
"""Build the deterministic Chapter 2 tape-comparison WAVs.

The central seven-second fragment is rendered once and copied byte-for-byte into
both tapes. Surrounding applause, paper movement, room tone, and artificial rain
are procedurally generated so the puzzle's conclusion is audible rather than
being carried only by its transcript.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import wave
from array import array
from pathlib import Path


SAMPLE_RATE = 24_000
MAX_SAMPLE = 32_767
DEFAULT_SOURCE_ROOT = Path("assets/audio/tape/chapter_02/source")
DEFAULT_OUTPUT_ROOT = Path("assets/audio/tape/chapter_02")


def _read_mono_pcm16(path: Path) -> list[float]:
    with wave.open(str(path), "rb") as wav_file:
        if wav_file.getnchannels() != 1:
            raise ValueError(f"{path} must be mono")
        if wav_file.getsampwidth() != 2:
            raise ValueError(f"{path} must be 16-bit PCM")
        if wav_file.getframerate() != SAMPLE_RATE:
            raise ValueError(f"{path} must be {SAMPLE_RATE} Hz")
        samples = array("h")
        samples.frombytes(wav_file.readframes(wav_file.getnframes()))
    return [sample / MAX_SAMPLE for sample in samples]


def _blank(seconds: float) -> list[float]:
    return [0.0] * round(seconds * SAMPLE_RATE)


def _mix(target: list[float], source: list[float], start_seconds: float, gain: float = 1.0) -> None:
    start = round(start_seconds * SAMPLE_RATE)
    for index, sample in enumerate(source):
        position = start + index
        if position >= len(target):
            break
        target[position] += sample * gain


def _noise(seconds: float, rng: random.Random, amplitude: float) -> list[float]:
    return [(rng.random() * 2.0 - 1.0) * amplitude for _ in range(round(seconds * SAMPLE_RATE))]


def _tone(seconds: float, frequency: float, amplitude: float) -> list[float]:
    length = round(seconds * SAMPLE_RATE)
    result: list[float] = []
    for index in range(length):
        time = index / SAMPLE_RATE
        attack = min(1.0, time / 0.008)
        decay = math.exp(-4.2 * time)
        harmonic = math.sin(math.tau * frequency * time) + 0.34 * math.sin(
            math.tau * frequency * 2.73 * time
        )
        result.append(harmonic * amplitude * attack * decay)
    return result


def _cough(rng: random.Random) -> list[float]:
    duration = 0.58
    result = _blank(duration)
    for index in range(len(result)):
        time = index / SAMPLE_RATE
        first = math.exp(-((time - 0.12) / 0.065) ** 2)
        second = 0.72 * math.exp(-((time - 0.34) / 0.085) ** 2)
        rasp = (rng.random() * 2.0 - 1.0) * (first + second)
        body = math.sin(math.tau * 128.0 * time) * (0.34 * first + 0.22 * second)
        result[index] = (rasp * 0.23 + body) * 0.75
    return result


def _applause(seconds: float, rng: random.Random) -> list[float]:
    result = _noise(seconds, rng, 0.018)
    for _ in range(round(seconds * 8.5)):
        center = rng.randrange(len(result))
        width = rng.randrange(90, 310)
        strength = rng.uniform(0.05, 0.16)
        for offset in range(-width, width):
            index = center + offset
            if 0 <= index < len(result):
                envelope = 1.0 - abs(offset) / width
                result[index] += (rng.random() * 2.0 - 1.0) * strength * envelope
    return result


def _paper_rustle(seconds: float, rng: random.Random) -> list[float]:
    result = _blank(seconds)
    previous = 0.0
    for index in range(len(result)):
        time = index / SAMPLE_RATE
        burst = math.exp(-((time - 0.55) / 0.23) ** 2) + 0.7 * math.exp(
            -((time - 1.25) / 0.18) ** 2
        )
        noise = rng.random() * 2.0 - 1.0
        high = noise - previous * 0.75
        previous = noise
        result[index] = high * burst * 0.11
    return result


def _rain(seconds: float, rng: random.Random) -> list[float]:
    result = _blank(seconds)
    smoothed = 0.0
    for index in range(len(result)):
        noise = rng.random() * 2.0 - 1.0
        smoothed = smoothed * 0.82 + noise * 0.18
        result[index] = (noise * 0.035 + smoothed * 0.14)
    for _ in range(round(seconds * 2.3)):
        position = rng.randrange(len(result))
        for offset in range(min(260, len(result) - position)):
            result[position + offset] += math.sin(offset * 0.21) * 0.05 * math.exp(-offset / 75)
    return result


def _make_shared_fragment(farewell: list[float]) -> list[float]:
    fragment = _noise(7.4, random.Random(20110918), 0.006)
    _mix(fragment, farewell, 0.15, 0.78)
    _mix(fragment, _cough(random.Random(42017)), 1.85, 0.82)
    _mix(fragment, _tone(1.0, 987.0, 0.25), 4.25)
    _mix(fragment, _tone(1.0, 987.0, 0.25), 6.15)
    return fragment


def _soft_limit(samples: list[float]) -> list[float]:
    return [math.tanh(sample * 1.18) * 0.86 for sample in samples]


def _write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    output = array("h", (round(max(-1.0, min(1.0, sample)) * MAX_SAMPLE) for sample in samples))
    with wave.open(str(path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(output.tobytes())


def _write_metadata(path: Path, tape_id: str, copied_fragment_start: float) -> None:
    metadata = {
        "asset": tape_id,
        "sample_rate": SAMPLE_RATE,
        "channels": 1,
        "sample_width_bits": 16,
        "duration_seconds": 18.0,
        "source_voice": "source/farewell.wav",
        "source_stagehand": "source/rain_machine.wav" if tape_id == "tape_b_rehearsal" else None,
        "copied_fragment_start_seconds": copied_fragment_start,
        "copied_fragment_duration_seconds": 7.4,
        "generation": "deterministic procedural mix; shared fragment copied byte-for-byte before final mix",
        "license": "original project asset; spoken sources are AI-synthesized from original text",
    }
    path.with_suffix(path.suffix + ".meta.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def build(source_root: Path, output_root: Path) -> None:
    farewell = _read_mono_pcm16(source_root / "farewell.wav")
    rain_machine = _read_mono_pcm16(source_root / "rain_machine.wav")
    fragment = _make_shared_fragment(farewell)

    tape_a = _noise(18.0, random.Random(8501), 0.004)
    _mix(tape_a, _applause(8.0, random.Random(8502)), 0.0, 0.82)
    _mix(tape_a, fragment, 8.3)
    _mix(tape_a, _applause(2.3, random.Random(8503)), 15.7, 0.58)

    tape_b = _noise(18.0, random.Random(9201), 0.005)
    _mix(tape_b, _paper_rustle(2.0, random.Random(9202)), 0.1)
    _mix(tape_b, fragment, 2.6)
    _mix(tape_b, rain_machine, 10.2, 0.62)
    _mix(tape_b, _rain(5.2, random.Random(9203)), 12.8, 0.82)

    tape_a_path = output_root / "tape_a_farewell.wav"
    tape_b_path = output_root / "tape_b_rehearsal.wav"
    _write_wav(tape_a_path, _soft_limit(tape_a))
    _write_wav(tape_b_path, _soft_limit(tape_b))
    _write_metadata(tape_a_path, "tape_a_farewell", 8.3)
    _write_metadata(tape_b_path, "tape_b_rehearsal", 2.6)
    print(f"Built {tape_a_path} and {tape_b_path} ({len(tape_a) / SAMPLE_RATE:.1f}s each)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, default=DEFAULT_SOURCE_ROOT)
    parser.add_argument("--output-root", type=Path, default=DEFAULT_OUTPUT_ROOT)
    args = parser.parse_args()
    build(args.source_root, args.output_root)


if __name__ == "__main__":
    main()
