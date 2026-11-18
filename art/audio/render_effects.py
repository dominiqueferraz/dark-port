"""Render Dark Port's original synthesized cues with Python 3."""

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 48000
OUTPUT = Path(__file__).resolve().parents[2] / "assets" / "audio"


def render(name, strikes, peak):
    """Mix damped, pitched resonances with a little filtered contact noise."""
    length = max(start + duration for start, duration, *_ in strikes)
    samples = [0.0] * math.ceil(length * SAMPLE_RATE)
    random_source = random.Random(name)
    for start, duration, high, low, gain, noise_gain in strikes:
        offset = round(start * SAMPLE_RATE)
        count = min(round(duration * SAMPLE_RATE), len(samples) - offset)
        contact = 0.0
        for index in range(count):
            elapsed = index / SAMPLE_RATE
            progress = elapsed / duration
            phase = math.tau * elapsed * (high + (low - high) * progress / 2)
            tone = math.sin(phase) + 0.14 * math.sin(2.03 * phase)
            contact += 0.32 * (random_source.uniform(-1, 1) - contact)
            attack = min(elapsed / 0.003, 1.0)
            release = math.exp(-5 * progress) * min((1 - progress) * 20, 1.0)
            samples[offset + index] += (
                gain * (tone + noise_gain * contact) * attack * release
            )

    scale = 32767 * peak / max(map(abs, samples))
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as audio:
        audio.setparams((1, 2, SAMPLE_RATE, 0, "NONE", "not compressed"))
        audio.writeframes(struct.pack(f"<{len(samples)}h", *(round(x * scale) for x in samples)))


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    # Strikes specify start time, duration, starting and ending pitch, relative
    # gain, and the proportion of contact noise.
    render("place", [(0, .15, 370, 200, 1, 1.2)], .14)
    render("turn", [(0, .07, 650, 500, .8, 1), (.026, .065, 850, 680, .6, .8)], .12)
    render("connect", [(0, .065, 650, 420, .7, 1.2), (.027, .14, 950, 870, .8, .25)], .13)
    render("disconnect", [(0, .060, 1080, 770, .6, .6), (.027, .11, 510, 315, .7, 1)], .12)
    render("adjust", [(0, .075, 740, 690, 1, 1.25)], .10)
    render("reject", [(0, .13, 370, 315, 1, .4)], .11)
    render("alarm", [(.06, .21, 450, 425, 1, .16), (.18, .26, 352, 340, .9, .12)], .17)
    render("solved", [(.07, .28, 294, 294, 1, 0), (.15, .28, 440, 440, .9, 0),
                      (.23, .40, 659, 659, .65, 0)], .17)
