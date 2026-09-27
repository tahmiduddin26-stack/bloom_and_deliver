"""Generate the game's small, dependency-free cartoon sound palette.

Run this script again after changing a melody or envelope. All output is
deterministic 22.05 kHz mono PCM, supported by Android's built-in decoder.
"""

from math import exp, pi, sin, tanh
from pathlib import Path
import wave


RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def note(buffer, start, duration, frequency, volume=0.3, *, soft=False):
    first = int(start * RATE)
    count = int(duration * RATE)
    for i in range(count):
        at = first + i
        if at >= len(buffer):
            break
        t = i / RATE
        if soft:
            envelope = min(1.0, t * 7) * min(1.0, (duration - t) * 7)
            tone = sin(2 * pi * frequency * t) + 0.18 * sin(4 * pi * frequency * t)
        else:
            envelope = min(1.0, t * 120) * exp(-5.3 * t / duration)
            tone = (
                sin(2 * pi * frequency * t)
                + 0.35 * sin(4 * pi * frequency * t)
                + 0.13 * sin(6 * pi * frequency * t)
            )
        buffer[at] += volume * envelope * tone


def make(name, seconds, notes, *, ambient=False):
    samples = [0.0] * int(seconds * RATE)
    for start, duration, pitch, volume in notes:
        note(samples, start, duration, pitch, volume, soft=ambient)
    if not ambient:
        # A short room reflection softens the computer-generated attack.
        delay = int(0.083 * RATE)
        for i in range(delay, len(samples)):
            samples[i] += samples[i - delay] * 0.14
    peak = max(1.0, max(abs(s) for s in samples) / 0.86)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(b"".join(int(tanh(s / peak) * 32767).to_bytes(2, "little", signed=True) for s in samples))


make("flower_drop", 0.32, [(0, 0.25, 784.0, 0.35)])
make("submit", 0.55, [(0, 0.38, 392.0, 0.25), (0.10, 0.38, 523.25, 0.28)])
make("great_order", 0.98, [
    (0, 0.45, 523.25, 0.25), (0.16, 0.45, 659.25, 0.25),
    (0.32, 0.55, 783.99, 0.24), (0.48, 0.45, 1046.5, 0.27),
])
make("poor_order", 0.65, [(0, 0.36, 440.0, 0.18), (0.19, 0.38, 349.23, 0.16)])
make("coin", 0.48, [(0, 0.29, 1318.5, 0.25), (0.10, 0.30, 1568.0, 0.20)])
make("notification", 0.62, [(0, 0.38, 783.99, 0.22), (0.17, 0.40, 1046.5, 0.20)])

# The pad is intentionally very quiet; each four-second phrase begins and ends
# at zero so the ambient player can loop it without a click.
chords = [
    (0.0, (261.63, 329.63, 392.00)),
    (4.0, (220.00, 261.63, 349.23)),
    (8.0, (196.00, 246.94, 392.00)),
]
ambient_notes = []
for start, chord in chords:
    for pitch in chord:
        ambient_notes.append((start, 4.0, pitch, 0.018))
    ambient_notes.append((start + 0.45, 0.95, chord[1] * 2, 0.008))
    ambient_notes.append((start + 2.0, 0.95, chord[2] * 2, 0.007))
make("ambient_shop", 12.0, ambient_notes, ambient=True)
