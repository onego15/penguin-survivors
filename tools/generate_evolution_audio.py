"""Generate the original short evolution cue (standard library only)."""
import math
from pathlib import Path
import struct
import wave


def main():
    rate = 22050
    destination = Path(__file__).resolve().parents[1] / "assets/audio/evolve.wav"
    with wave.open(str(destination), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(rate)
        samples = []
        for i in range(int(rate * 0.75)):
            time = i / rate
            value = 0.0
            for start, frequency in [(0, 523.25), (.12, 659.25), (.24, 783.99), (.36, 1046.5)]:
                if time >= start:
                    age = time - start
                    envelope = .15 * min(1, age / .015) * math.exp(-age * 6)
                    value += envelope * (math.sin(2 * math.pi * frequency * age) + .25 * math.sin(4 * math.pi * frequency * age))
            samples.append(struct.pack("<h", int(max(-1, min(1, value)) * 30000)))
        output.writeframes(b"".join(samples))


if __name__ == "__main__":
    main()
