import wave, math, random, struct, os

def generate_roar(filename):
    sample_rate = 44100
    duration = 1.5
    num_samples = int(sample_rate * duration)
    f = wave.open(filename, "w")
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(sample_rate)

    for i in range(num_samples):
        t = float(i) / sample_rate
        # Roar envelope: quick attack, slow decay
        env = math.exp(-3 * t) * (1 - math.exp(-20 * t))
        # Low frequency noise with some sine waves
        noise = random.uniform(-1, 1) * 0.5
        freq1 = 80 * math.exp(-1.5 * t)
        freq2 = 120 * math.exp(-1.0 * t)
        wave_val = math.sin(2 * math.pi * freq1 * t) + 0.5 * math.sin(2 * math.pi * freq2 * t) + noise
        
        val = int(env * wave_val * 12000)
        # clip
        if val > 32767: val = 32767
        elif val < -32768: val = -32768
        f.writeframesraw(struct.pack('<h', val))
    f.close()

os.makedirs('android/app/src/main/res/raw', exist_ok=True)
generate_roar('android/app/src/main/res/raw/roar.wav')
print("Generated roar.wav")
