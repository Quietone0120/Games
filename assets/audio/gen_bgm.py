"""
Simple looping background music generator (WAV format).
Works on all platforms including Flutter Web.
"""
import struct, math, wave, os

OUT = os.path.dirname(os.path.abspath(__file__))
SR = 44100  # sample rate

def note_freq(note):
    """Note name -> frequency. e.g. 'C4', 'G4', 'A3'"""
    notes = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
    name, octave = note[:-1], int(note[-1])
    n = notes.index(name)
    return 440.0 * (2 ** ((n - 9 + (octave - 4) * 12) / 12.0))

def sine(freq, duration, sr=SR, vol=0.4, attack=0.01, release=0.08):
    n = int(sr * duration)
    atk = int(sr * attack)
    rel = int(sr * release)
    samples = []
    for i in range(n):
        t = i / sr
        s = math.sin(2 * math.pi * freq * t)
        # Envelope
        if i < atk:
            env = i / atk
        elif i > n - rel:
            env = (n - i) / rel
        else:
            env = 1.0
        samples.append(s * env * vol)
    return samples

def mix(tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    # Normalize
    mx = max(abs(v) for v in out) or 1
    return [v / mx * 0.85 for v in out]

def save_wav(filename, samples, sr=SR):
    path = os.path.join(OUT, filename)
    data = b''.join(struct.pack('<h', max(-32768, min(32767, int(s * 32767)))) for s in samples)
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sr)
        f.writeframes(data)
    size_kb = os.path.getsize(path) // 1024
    print(f"Created: {filename}  ({size_kb} KB)")

# ── Flappy Bird BGM: Bright cheerful C-major melody ──────────────────────────
def make_flappy_bgm():
    beat = 0.22
    # Melody (right hand)
    melody_notes = [
        ('E5',2),('G5',1),('A5',1),('G5',2),('E5',2),
        ('C5',2),('E5',1),('G5',1),('E5',4),
        ('D5',2),('F5',1),('A5',1),('F5',2),('D5',2),
        ('B4',2),('D5',1),('F5',1),('D5',4),
    ]
    # Bass (left hand)
    bass_notes = [
        ('C3',4),('G3',4), ('C3',4),('G3',4),
        ('D3',4),('A3',4), ('G3',4),('D3',4),
    ]
    mel = []
    for note, beats in melody_notes:
        mel += sine(note_freq(note), beat * beats, vol=0.35)
    bas = []
    for note, beats in bass_notes:
        bas += sine(note_freq(note), beat * beats, vol=0.20)

    length = max(len(mel), len(bas))
    mel += [0.0] * (length - len(mel))
    bas += [0.0] * (length - len(bas))
    combined = mix([mel, bas])
    # Duplicate to make it longer before looping
    combined = combined * 2
    save_wav('bgm_flappy.wav', combined)

# ── Tetris BGM: Korobeiniki-inspired (simplified) ────────────────────────────
def make_tetris_bgm():
    beat = 0.18
    melody = [
        ('A4',2),('E4',1),('F4',1),('G4',2),('F4',1),('E4',1),
        ('D4',2),('D4',1),('F4',1),('A4',2),('G4',1),('F4',1),
        ('E4',3),('F4',1),('G4',2),('A4',2),
        ('F4',2),('D4',2),('D4',4),
        ('G4',2),('B4',1),('D5',1),('C5',2),('B4',1),('A4',1),
        ('A4',3),('F4',1),('A4',2),('G4',1),('F4',1),
        ('E4',3),('F4',1),('G4',2),('A4',2),
        ('F4',2),('D4',2),('D4',4),
    ]
    bass = [
        ('A2',4),('E3',4), ('A2',4),('E3',4),
        ('A2',4),('E3',4), ('A2',4),('E3',4),
        ('G2',4),('D3',4), ('A2',4),('E3',4),
        ('A2',4),('E3',4), ('A2',4),('E3',4),
    ]
    mel = []
    for note, beats in melody:
        mel += sine(note_freq(note), beat * beats, vol=0.40)
    bas = []
    for note, beats in bass:
        bas += sine(note_freq(note), beat * beats, vol=0.22)

    length = max(len(mel), len(bas))
    mel += [0.0] * (length - len(mel))
    bas += [0.0] * (length - len(bas))
    combined = mix([mel, bas])
    save_wav('bgm_tetris.wav', combined)

# ── Tank BGM: March-style minor melody ───────────────────────────────────────
def make_tank_bgm():
    beat = 0.20
    melody = [
        ('A3',2),('A3',1),('A3',1),('A3',2),('G3',1),('A3',1),
        ('B3',2),('B3',1),('B3',1),('B3',2),('A3',1),('B3',1),
        ('C4',2),('C4',1),('B3',1),('A3',2),('G3',1),('A3',1),
        ('A3',4),('A3',4),
        ('E4',2),('E4',1),('E4',1),('E4',2),('D4',1),('E4',1),
        ('F4',2),('E4',1),('D4',1),('C4',2),('B3',1),('C4',1),
        ('D4',2),('D4',1),('C4',1),('B3',2),('A3',1),('B3',1),
        ('A3',4),('A3',4),
    ]
    bass = [
        ('A2',4),('E2',4), ('A2',4),('E2',4),
        ('A2',4),('E2',4), ('A2',4),('E2',4),
        ('E2',4),('A2',4), ('D2',4),('A2',4),
        ('A2',4),('E2',4), ('A2',4),('E2',4),
    ]
    mel = []
    for note, beats in melody:
        mel += sine(note_freq(note), beat * beats, vol=0.38)
    bas = []
    for note, beats in bass:
        bas += sine(note_freq(note), beat * beats, vol=0.20)

    length = max(len(mel), len(bas))
    mel += [0.0] * (length - len(mel))
    bas += [0.0] * (length - len(bas))
    combined = mix([mel, bas])
    save_wav('bgm_tank.wav', combined)

make_flappy_bgm()
make_tetris_bgm()
make_tank_bgm()
print("All BGM generated!")
