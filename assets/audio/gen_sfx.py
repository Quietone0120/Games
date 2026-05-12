import struct, math, wave, os, random

OUT = os.path.dirname(os.path.abspath(__file__))

def make_wav(filename, freq=440, duration=0.15, volume=0.6,
             sample_rate=44100, fade=True, wave_type='sine', freq2=None):
    n = int(sample_rate * duration)
    data = []
    for i in range(n):
        t = i / sample_rate
        if wave_type == 'sine':
            s = math.sin(2 * math.pi * freq * t)
        elif wave_type == 'square':
            s = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
        elif wave_type == 'sweep':
            f = freq + ((freq2 or freq) - freq) * (t / duration)
            s = math.sin(2 * math.pi * f * t)
        elif wave_type == 'noise':
            s = random.uniform(-1, 1) * math.exp(-4 * t / duration)
        else:
            s = math.sin(2 * math.pi * freq * t)
        env = (1.0 - (i / n) ** 0.5) if fade else 1.0
        val = max(-32768, min(32767, int(s * env * volume * 32767)))
        data.append(struct.pack('<h', val))
    path = os.path.join(OUT, filename)
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        f.writeframes(b''.join(data))
    print(f"Created: {filename}")

# Flappy Bird SFX
make_wav("sfx_wing.wav",     freq=400, freq2=620,  duration=0.12, wave_type='sweep', volume=0.55)
make_wav("sfx_point.wav",    freq=880, freq2=1100, duration=0.20, wave_type='sweep', volume=0.65)
make_wav("sfx_hit.wav",      freq=160, freq2=60,   duration=0.40, wave_type='sweep', volume=0.80)
# Tetris SFX
make_wav("sfx_move.wav",     freq=300,             duration=0.07, wave_type='square', volume=0.30)
make_wav("sfx_rotate.wav",   freq=500, freq2=700,  duration=0.10, wave_type='sweep',  volume=0.40)
make_wav("sfx_clear.wav",    freq=660, freq2=880,  duration=0.32, wave_type='sine',   volume=0.70)
make_wav("sfx_gameover.wav", freq=220, freq2=80,   duration=0.65, wave_type='sweep',  volume=0.80)
# Tank SFX
make_wav("sfx_shoot.wav",    freq=220, freq2=110,  duration=0.18, wave_type='noise',  volume=0.75)
make_wav("sfx_explode.wav",  freq=90,  freq2=40,   duration=0.55, wave_type='noise',  volume=0.90)
# UI
make_wav("sfx_click.wav",    freq=600,             duration=0.08, wave_type='sine',   volume=0.50)
print("All SFX generated successfully!")
