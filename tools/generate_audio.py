#!/usr/bin/env python3
"""Genera todo el audio de P3C3R4 (música, ambiente y efectos) por síntesis.

Uso (desde la carpeta raíz del proyecto):
    python tools/generate_audio.py

Necesita Python 3 con numpy y scipy. Escribe archivos WAV (22 050 Hz, 16 bits,
mono) en `game/assets/audio/`. Todo el sonido es propio: no hay muestras ni
melodías de terceros, así que no hay licencias que anotar. La melodía es original
(ambiente marino lento, estilo «lofi chiptune»); solo comparte el ánimo de los
niveles acuáticos de los juegos de 16 bits.

Si se cambia algo aquí, se vuelve a ejecutar y se reimporta el proyecto en Godot.
"""
import math
import os
import wave

import numpy as np
from scipy import signal

SR = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "audio")
RNG = np.random.default_rng(20261114)


# --------------------------------------------------------------------------
# Utilidades de síntesis
# --------------------------------------------------------------------------
def midi_hz(note):
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def seconds(n):
    return np.arange(int(n * SR)) / SR


def osc(kind, freq, dur, duty=0.5, vibrato=(0.0, 0.0)):
    """Onda de [kind] a [freq] Hz durante [dur] s. vibrato = (Hz, profundidad en semitonos)."""
    t = seconds(dur)
    inst = freq * np.ones_like(t)
    if vibrato[0] > 0.0:
        inst = inst * 2.0 ** ((vibrato[1] * np.sin(2 * math.pi * vibrato[0] * t)) / 12.0)
    phase = np.cumsum(inst) / SR
    frac = phase % 1.0
    if kind == "square":
        return np.where(frac < duty, 1.0, -1.0)
    if kind == "triangle":
        return 4.0 * np.abs(frac - 0.5) - 1.0
    if kind == "saw":
        return 2.0 * frac - 1.0
    if kind == "sine":
        return np.sin(2 * math.pi * phase)
    raise ValueError(kind)


def adsr(n, attack=0.01, decay=0.1, sustain=0.6, release=0.1):
    env = np.ones(n)
    a = max(int(attack * SR), 1)
    d = int(decay * SR)
    r = max(int(release * SR), 1)
    a = min(a, n)
    env[:a] = np.linspace(0.0, 1.0, a)
    if d > 0 and a < n:
        end = min(a + d, n)
        env[a:end] = np.linspace(1.0, sustain, end - a)
        env[end:] = sustain
    elif a < n:
        env[a:] = sustain
    r = min(r, n)
    env[n - r:] *= np.linspace(1.0, 0.0, r)
    return env


def lowpass(x, cutoff, order=2):
    sos = signal.butter(order, cutoff / (SR / 2), btype="low", output="sos")
    return signal.sosfilt(sos, x)


def highpass(x, cutoff, order=2):
    sos = signal.butter(order, cutoff / (SR / 2), btype="high", output="sos")
    return signal.sosfilt(sos, x)


def bandpass(x, low, high, order=2):
    sos = signal.butter(order, [low / (SR / 2), high / (SR / 2)], btype="band", output="sos")
    return signal.sosfilt(sos, x)


def noise(dur):
    return RNG.uniform(-1.0, 1.0, int(dur * SR))


def echo(x, delay_s, feedback, mix, taps=5):
    out = x.copy()
    d = int(delay_s * SR)
    for i in range(1, taps + 1):
        shifted = np.zeros_like(x)
        shifted[i * d:] = x[: len(x) - i * d] if i * d < len(x) else 0
        out += mix * (feedback ** (i - 1)) * shifted
    return out


def reverb(x, tail=1.8, mix=0.25, brightness=2500.0):
    n = int(tail * SR)
    t = np.arange(n) / SR
    ir = RNG.normal(0.0, 1.0, n) * np.exp(-t * (6.9 / tail))
    ir = lowpass(ir, brightness)
    ir /= np.sqrt(np.sum(ir**2)) + 1e-9
    wet = np.zeros(len(x) + n)
    conv = signal.fftconvolve(x, ir)
    wet[: len(conv)] = conv[: len(x) + n]
    dry = np.concatenate([x, np.zeros(n)])
    return (1.0 - mix) * dry + mix * wet


def place(buf, start_s, sound, gain=1.0):
    i = max(int(start_s * SR), 0)
    if i >= len(buf):
        return
    end = min(i + len(sound), len(buf))
    buf[i:end] += gain * sound[: end - i]


def normalize(x, peak=0.7):
    m = np.max(np.abs(x)) + 1e-9
    return x * (peak / m)


def fade_edges(x, ms=4):
    n = int(ms / 1000.0 * SR)
    x = x.copy()
    x[:n] *= np.linspace(0, 1, n)
    x[-n:] *= np.linspace(1, 0, n)
    return x


def write_wav(name, x):
    os.makedirs(OUT_DIR, exist_ok=True)
    data = np.clip(x, -1.0, 1.0)
    pcm = (data * 32767.0).astype("<i2")
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    print("%-22s %6.2f s  %6.1f KB" % (name, len(x) / SR, os.path.getsize(path) / 1024.0))


def note_tone(kind, midi, dur, duty=0.5, attack=0.005, decay=0.1, sustain=0.5, release=0.08,
              vibrato=(0.0, 0.0)):
    n = int(dur * SR)
    return osc(kind, midi_hz(midi), dur, duty, vibrato)[:n] * adsr(n, attack, decay, sustain, release)


# --------------------------------------------------------------------------
# Efectos de sonido
# --------------------------------------------------------------------------
def sfx_click():
    t = note_tone("square", 84, 0.05, 0.25, 0.001, 0.02, 0.2, 0.03)
    return normalize(lowpass(t, 5000), 0.35)


def sfx_buy():
    out = np.zeros(int(0.32 * SR))
    place(out, 0.0, note_tone("square", 79, 0.1, 0.25, 0.002, 0.05, 0.4, 0.05), 0.6)
    place(out, 0.075, note_tone("square", 86, 0.2, 0.25, 0.002, 0.08, 0.35, 0.12), 0.6)
    return normalize(lowpass(out, 6500), 0.5)


def sfx_sell():
    out = np.zeros(int(0.34 * SR))
    place(out, 0.0, note_tone("triangle", 84, 0.1, 0.5, 0.002, 0.05, 0.5, 0.05), 0.8)
    place(out, 0.075, note_tone("triangle", 79, 0.12, 0.5, 0.002, 0.05, 0.5, 0.06), 0.8)
    place(out, 0.15, note_tone("triangle", 72, 0.18, 0.5, 0.002, 0.08, 0.4, 0.1), 0.8)
    return normalize(out, 0.5)


def sfx_pearl():
    out = np.zeros(int(0.7 * SR))
    for i, m in enumerate([88, 91, 95, 100]):
        tone = note_tone("sine", m, 0.35, 0.5, 0.002, 0.15, 0.2, 0.2)
        place(out, i * 0.06, tone, 0.7)
    out = echo(out, 0.12, 0.45, 0.5, 3)
    return normalize(out, 0.45)


def sfx_hatch():
    out = np.zeros(int(0.75 * SR))
    pop = lowpass(noise(0.06), 2500) * adsr(int(0.06 * SR), 0.001, 0.02, 0.2, 0.03)
    place(out, 0.0, pop, 0.9)
    for i, m in enumerate([76, 83, 88]):
        place(out, 0.09 + i * 0.1, note_tone("square", m, 0.3, 0.125, 0.003, 0.1, 0.3, 0.18), 0.5)
    out = echo(out, 0.14, 0.4, 0.4, 3)
    return normalize(lowpass(out, 6000), 0.5)


def sfx_achievement():
    out = np.zeros(int(1.1 * SR))
    for i, (m, d) in enumerate([(72, 0.12), (76, 0.12), (79, 0.12), (84, 0.5)]):
        place(out, i * 0.12, note_tone("square", m, d + 0.1, 0.25, 0.003, 0.08, 0.5, 0.1), 0.5)
        place(out, i * 0.12, note_tone("triangle", m - 12, d + 0.1, 0.5, 0.003, 0.08, 0.6, 0.1), 0.5)
    out = reverb(echo(out, 0.18, 0.4, 0.4, 3), 0.9, 0.25)
    return normalize(lowpass(out, 6500), 0.55)


def sfx_prestige():
    dur = 2.6
    t = seconds(dur)
    sweep_f = 110.0 * 2.0 ** (t * 2.2)
    sweep = np.sin(2 * math.pi * np.cumsum(sweep_f) / SR) * np.exp(-t * 0.5) * 0.4
    sweep *= np.minimum(t / 0.3, 1.0)
    out = sweep
    for i, m in enumerate([62, 69, 74, 78, 81, 86]):
        place(out, 0.35 + i * 0.2, note_tone("triangle", m, 1.4, 0.5, 0.01, 0.3, 0.4, 0.8), 0.4)
        place(out, 0.35 + i * 0.2, note_tone("sine", m + 12, 1.2, 0.5, 0.01, 0.3, 0.3, 0.7), 0.25)
    out = reverb(out, 1.6, 0.35)
    return normalize(fade_edges(out[: int(dur * SR)], 20), 0.55)


def sfx_event():
    out = np.zeros(int(0.9 * SR))
    for i, m in enumerate([81, 88]):
        place(out, i * 0.18, note_tone("sine", m, 0.5, 0.5, 0.002, 0.2, 0.2, 0.3), 0.7)
        place(out, i * 0.18, note_tone("sine", m + 12, 0.3, 0.5, 0.002, 0.1, 0.15, 0.2), 0.2)
    out = echo(out, 0.2, 0.4, 0.45, 3)
    return normalize(out, 0.45)


def sfx_reward():
    out = np.zeros(int(0.7 * SR))
    for i, m in enumerate([79, 83, 86, 91]):
        place(out, i * 0.07, note_tone("square", m, 0.25, 0.25, 0.002, 0.08, 0.35, 0.15), 0.5)
    out = echo(out, 0.1, 0.4, 0.4, 3)
    return normalize(lowpass(out, 6500), 0.5)


def sfx_feed():
    dur = 0.28
    n = noise(dur)
    band = bandpass(n, 800, 3500) * adsr(int(dur * SR), 0.01, 0.1, 0.3, 0.15)
    drop = note_tone("sine", 70, 0.08, 0.5, 0.001, 0.04, 0.2, 0.04) * 0.4
    band[: len(drop)] += drop
    return normalize(band, 0.4)


def sfx_final():
    dur = 4.0
    out = np.zeros(int(dur * SR))
    chords = [[62, 69, 74, 78], [67, 74, 79, 83], [64, 71, 76, 80], [69, 76, 81, 85]]
    for c, chord in enumerate(chords):
        for m in chord:
            place(out, c * 0.9, note_tone("triangle", m, 1.6, 0.5, 0.05, 0.3, 0.5, 1.0), 0.3)
            place(out, c * 0.9, note_tone("sine", m + 12, 1.4, 0.5, 0.05, 0.3, 0.4, 0.9), 0.15)
    out = reverb(out, 2.2, 0.4)
    return normalize(fade_edges(out[: int(dur * SR)], 30), 0.55)


def sfx_error():
    out = np.zeros(int(0.22 * SR))
    place(out, 0.0, note_tone("square", 50, 0.1, 0.5, 0.002, 0.05, 0.5, 0.04), 0.6)
    place(out, 0.09, note_tone("square", 45, 0.12, 0.5, 0.002, 0.05, 0.5, 0.06), 0.6)
    return normalize(lowpass(out, 1800), 0.4)


# --------------------------------------------------------------------------
# Ambiente: agua y burbujas (bucle sin costuras)
# --------------------------------------------------------------------------
def gull_call(length):
    """Un graznido de gaviota: glissando descendente con armónicos y un temblor."""
    k = int(length * SR)
    tt = np.arange(k) / SR
    f0 = RNG.uniform(1500.0, 1900.0)
    glide = f0 * (1.0 - 0.38 * (tt / length) ** 0.8)
    glide = glide * (1.0 + 0.025 * np.sin(2 * math.pi * 38.0 * tt))
    phase = np.cumsum(glide) / SR
    call = (
        np.sin(2 * math.pi * phase)
        + 0.55 * np.sin(2 * math.pi * 2.0 * phase)
        + 0.3 * np.sin(2 * math.pi * 3.0 * phase)
    )
    env = np.minimum(tt / 0.04, 1.0) * np.exp(-tt * (2.2 / length))
    env[-int(0.03 * SR):] *= np.linspace(1.0, 0.0, int(0.03 * SR))
    return bandpass(call * env, 700.0, 5000.0)


def gulls(dur):
    """Tres pequeñas bandadas de gritos (2 a 4) repartidas por el bucle, lejanas."""
    out = np.zeros(int(dur * SR))
    for centre in (0.18, 0.5, 0.82):
        t = centre * dur + RNG.uniform(-1.0, 1.0)
        for _ in range(int(RNG.integers(2, 5))):
            length = RNG.uniform(0.28, 0.5)
            call = gull_call(length) * RNG.uniform(0.7, 1.0)
            place(out, t, call, 1.0)
            t += length + RNG.uniform(0.1, 0.35)
    return reverb(out, 1.4, 0.3, 3000.0)[: len(out)]


def ambient_water(dur=24.0):
    n = int(dur * SR)
    base = lowpass(noise(dur), 700, 2)
    swell = 0.55 + 0.45 * np.sin(2 * math.pi * (2.0 / dur) * seconds(dur) + 0.7)
    swell2 = 0.7 + 0.3 * np.sin(2 * math.pi * (5.0 / dur) * seconds(dur))
    water = base * swell * swell2 * 0.5
    water += highpass(lowpass(noise(dur), 2400), 900) * 0.05 * swell
    bubbles = np.zeros(n)
    for _ in range(int(dur * 1.6)):
        f = RNG.uniform(500, 1700)
        length = RNG.uniform(0.05, 0.12)
        k = int(length * SR)
        tt = np.arange(k) / SR
        chirp = np.sin(2 * math.pi * np.cumsum(f * (1.0 + 4.0 * tt / length)) / SR)
        blip = chirp * np.exp(-tt * (28.0 / length)) * RNG.uniform(0.12, 0.3)
        start = int(RNG.uniform(0, dur - 0.2) * SR)
        bubbles[start:start + k] += blip
    water_part = water + bubbles
    birds = gulls(dur)
    # Las gaviotas suenan al mismo nivel que las olas (misma energía en sus tramos activos).
    active = np.abs(birds) > 0.02 * np.max(np.abs(birds))
    water_level = np.sqrt(np.mean(water_part**2))
    bird_level = np.sqrt(np.mean(birds[active] ** 2)) + 1e-9
    out = water_part + birds * (water_level / bird_level)
    shift = int(SR * 0.37)
    # Fundido cruzado para que el final enlace con el principio.
    fade = int(SR * 1.2)
    head = out[:fade].copy()
    tail = out[-fade:].copy()
    ramp = np.linspace(0.0, 1.0, fade)
    out = out.copy()
    out[:fade] = head * ramp + tail * (1.0 - ramp)
    out = out[:-fade]
    del shift
    return normalize(out, 0.5)


# --------------------------------------------------------------------------
# Música: «Marea lenta» (día) y «Marea honda» (noche). Composición propia.
# --------------------------------------------------------------------------
# Escala de re dórico; los acordes se dan como notas MIDI (bajo, acorde).
CHORDS = {
    "Dm9": (38, [53, 57, 60, 64]),
    "Bbmaj7": (34, [53, 57, 62, 65]),
    "Fmaj7": (41, [57, 60, 64, 67]),
    "Am7": (45, [55, 60, 64, 67]),
    "Gm9": (43, [58, 62, 65, 69]),
    "Cmaj7": (36, [55, 59, 64, 67]),
    "C13": (36, [58, 62, 64, 69]),
    "Em7b5": (40, [55, 58, 62, 67]),
}
PROGRESSION = [
    "Dm9", "Bbmaj7", "Fmaj7", "Am7",
    "Dm9", "Gm9", "Cmaj7", "Fmaj7",
    "Bbmaj7", "Am7", "Gm9", "C13",
    "Dm9", "Em7b5", "Am7", "C13",
]
# Melodía (compás, tiempo, nota MIDI, duración en tiempos). Frases largas y huecos.
MELODY = [
    (0, 0.0, 74, 3.0), (0, 3.0, 72, 1.0),
    (1, 0.0, 70, 2.0), (1, 2.0, 72, 2.0),
    (2, 0.0, 69, 3.0), (2, 3.0, 67, 1.0),
    (3, 0.0, 69, 4.0),
    (4, 0.0, 74, 2.0), (4, 2.0, 77, 2.0),
    (5, 0.0, 76, 3.0), (5, 3.0, 74, 1.0),
    (6, 0.0, 72, 2.0), (6, 2.0, 71, 2.0),
    (7, 0.0, 69, 4.0),
    (8, 0.0, 77, 2.0), (8, 2.0, 74, 2.0),
    (9, 0.0, 72, 3.0), (9, 3.0, 69, 1.0),
    (10, 0.0, 70, 2.0), (10, 2.0, 74, 2.0),
    (11, 0.0, 76, 3.0), (11, 3.0, 79, 1.0),
    (12, 0.0, 81, 3.0), (12, 3.0, 79, 1.0),
    (13, 0.0, 77, 2.0), (13, 2.0, 76, 2.0),
    (14, 0.0, 72, 2.0), (14, 2.0, 74, 2.0),
    (15, 0.0, 74, 4.0),
]


def ep_tone(midi, dur, vel=1.0):
    """Piano eléctrico tipo Rhodes: FM suave con «diente» que se apaga y un poco de coro."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for cents, gain in ((-4.0, 0.5), (4.0, 0.5)):
        f = midi_hz(midi) * 2.0 ** (cents / 1200.0)
        ph = 2 * math.pi * f * t
        index = (0.9 + 1.6 * vel) * np.exp(-t * 7.0) + 0.25
        out += gain * np.sin(ph + index * np.sin(ph))
    out += 0.12 * vel * np.sin(2 * math.pi * midi_hz(midi) * 4.0 * t) * np.exp(-t * 22.0)
    env = np.exp(-t * (1.4 if dur > 1.0 else 2.2))
    env *= np.minimum(t / 0.004, 1.0)
    release = min(int(0.25 * SR), n)
    env[n - release:] *= np.linspace(1.0, 0.0, release)
    return out * env * vel


def vibes_tone(midi, dur, vel=1.0):
    """Vibráfono: sinusoide con armónico campana que decae y trémolo lento."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = midi_hz(midi)
    out = np.sin(2 * math.pi * f * t) + 0.35 * np.sin(2 * math.pi * f * 4.0 * t) * np.exp(-t * 6.0)
    out *= 1.0 + 0.12 * np.sin(2 * math.pi * 4.6 * t)
    env = np.exp(-t * 1.3) * np.minimum(t / 0.006, 1.0)
    release = min(int(0.3 * SR), n)
    env[n - release:] *= np.linspace(1.0, 0.0, release)
    return out * env * vel


def warm_bass(midi, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = midi_hz(midi)
    out = np.sin(2 * math.pi * f * t) + 0.25 * np.sin(2 * math.pi * f * 2.0 * t)
    env = np.minimum(t / 0.015, 1.0) * np.exp(-t * 1.1)
    release = min(int(0.2 * SR), n)
    env[n - release:] *= np.linspace(1.0, 0.0, release)
    return lowpass(out * env, 520.0)


def pad_tone(midi, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for cents in (-9.0, 0.0, 8.0):
        f = midi_hz(midi) * 2.0 ** (cents / 1200.0)
        out += 2.0 * ((f * t) % 1.0) - 1.0
    env = np.minimum(t / 1.1, 1.0)
    release = min(int(1.2 * SR), n)
    env[n - release:] *= np.linspace(env[n - release], 0.0, release)
    return lowpass(out * env / 3.0, 1000.0)


def lofi_kick():
    n = int(0.28 * SR)
    t = np.arange(n) / SR
    body = np.sin(2 * math.pi * np.cumsum(95.0 * np.exp(-t * 20.0) + 46.0) / SR)
    return lowpass(body * np.exp(-t * 11.0), 300.0)


def lofi_snare():
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    hiss = lowpass(bandpass(noise(0.22), 900, 4200), 3600.0) * np.exp(-t * 17.0)
    knock = np.sin(2 * math.pi * 185.0 * t) * np.exp(-t * 28.0) * 0.5
    return hiss + knock


def lofi_hat(open_hat=False):
    d = 0.16 if open_hat else 0.05
    n = int(d * SR)
    t = np.arange(n) / SR
    return lowpass(highpass(noise(d), 5500), 9000.0) * np.exp(-t * (16.0 if open_hat else 60.0))


def render_music(bpm, transpose, night):
    """Lofi suave: Rhodes, bajo cálido, colchón de pads y batería polvorienta con swing."""
    beat = 60.0 / bpm
    bars = len(PROGRESSION)
    loop_s = bars * 4 * beat
    tail_s = 3.5
    total = np.zeros(int((loop_s + tail_s) * SR))
    swing = (0.0 if night else 0.14) * beat
    layers = {k: np.zeros_like(total) for k in ("bass", "keys", "pad", "lead", "drums")}
    rng = np.random.default_rng(7 if night else 3)
    for bar, name in enumerate(PROGRESSION):
        root, chord = CHORDS[name]
        t0 = bar * 4 * beat
        # Colchón de pads: acorde completo de compás entero.
        for m in chord:
            place(layers["pad"], t0, pad_tone(m - 12 + transpose, 4.2 * beat), 0.17 if night else 0.11)
        # Bajo: raíz en 1 y una nota de paso corta (solo de día).
        place(layers["bass"], t0, warm_bass(root + 12 + transpose, 2.6 * beat), 0.9)
        if not night:
            place(layers["bass"], t0 + (2.5 * beat + swing), warm_bass(root + 19 + transpose, 1.2 * beat), 0.6)
        # Acordes de piano eléctrico, rasgueados, con síncopa (de noche, un solo golpe lento).
        hits = ((0.0, 1.0), (2.5, 0.7)) if not night else ((0.0, 0.8),)
        for pos, vel in hits:
            when = t0 + pos * beat + (swing if pos % 1.0 else 0.0)
            for i, m in enumerate(chord):
                jitter = rng.uniform(0.0, 0.012)
                v = vel * (0.78 + 0.07 * i) * rng.uniform(0.9, 1.0)
                place(layers["keys"], when + i * 0.022 + jitter,
                      ep_tone(m + transpose, 2.4 * beat if pos == 0.0 else 1.5 * beat, v), 0.2)
        # Batería (solo de día): kick flojo, caja polvorienta en 2 y 4, hats con swing.
        if not night:
            for pos, vel in ((0.0, 1.0), (2.5, 0.7)):
                when = t0 + pos * beat + (swing if pos % 1.0 else 0.0)
                place(layers["drums"], when + rng.uniform(-0.006, 0.006), lofi_kick(), 0.5 * vel)
            for pos in (1.0, 3.0):
                place(layers["drums"], t0 + pos * beat + rng.uniform(0.0, 0.016), lofi_snare(), 0.20)
            for i in range(8):
                when = t0 + i * 0.5 * beat + (swing if i % 2 == 1 else 0.0)
                vel = (0.10 if i % 2 == 0 else 0.06) * rng.uniform(0.7, 1.15)
                place(layers["drums"], when + rng.uniform(-0.005, 0.005), lofi_hat(i == 7), vel)
    # Melodía: vibráfono de día, vibráfono muy suave una octava más grave de noche.
    for bar, b, m, d in MELODY:
        t0 = bar * 4 * beat + b * beat + (swing * 0.4 if (b % 1.0) else 0.0)
        shift = -12 if night else 0
        tone = vibes_tone(m + shift + transpose, min(d * beat * 1.1, 4.0 * beat), 0.75 if night else 1.0)
        place(layers["lead"], t0 + rng.uniform(0.0, 0.01), tone, 0.26 if night else 0.3)
    keys = echo(layers["keys"], beat * 0.75, 0.4, 0.35, 3)
    lead = echo(layers["lead"], beat * 1.5, 0.45, 0.5, 3)
    mix = (
        layers["bass"] * 1.05
        + lowpass(keys, 3400.0 if not night else 2200.0)
        + lowpass(lead, 4200.0 if not night else 2600.0)
        + layers["pad"]
        + layers["drums"]
    )
    mix = reverb(mix, 2.6 if night else 2.0, 0.3 if night else 0.22, 2200.0)
    mix = lowpass(mix, 5200 if not night else 3600)
    mix = np.tanh(mix * 1.2)
    # Ruido de cinta y crepitar de vinilo.
    hiss = lowpass(noise((len(mix) + 4) / SR), 3000.0) * 0.0035
    mix = mix + hiss[: len(mix)]
    crackle = np.zeros_like(mix)
    for _ in range(int(loop_s * (6 if not night else 3))):
        i = int(RNG.uniform(0, len(mix) - 30))
        crackle[i:i + 3] += RNG.uniform(0.01, 0.04) * RNG.choice([-1, 1])
    mix += highpass(crackle, 1500)
    # Cierre sin costuras: la cola de reverberación se suma al principio.
    loop_n = int(loop_s * SR)
    out = mix[:loop_n].copy()
    out[: len(mix) - loop_n] += mix[loop_n:]
    # Vaivén de cinta (ciclos enteros por bucle para no romper la unión).
    cycles = max(int(round(loop_s * 0.22)), 1)
    t = np.arange(loop_n) / loop_n
    delay = 16.0 * np.sin(2 * math.pi * cycles * t)
    wrapped = np.concatenate([out, out, out])
    idx3 = np.arange(loop_n) + loop_n + delay
    out = np.interp(idx3, np.arange(len(wrapped)), wrapped)
    return normalize(out - np.mean(out), 0.55 if not night else 0.5)


def main():
    import sys
    if "--ambient" in sys.argv:
        write_wav("ambient_water.wav", ambient_water())
        return
    if "--music" in sys.argv:
        write_wav("music_day.wav", render_music(bpm=76, transpose=0, night=False))
        write_wav("music_night.wav", render_music(bpm=60, transpose=-5, night=True))
        return
    write_wav("sfx_click.wav", fade_edges(sfx_click()))
    write_wav("sfx_buy.wav", fade_edges(sfx_buy()))
    write_wav("sfx_sell.wav", fade_edges(sfx_sell()))
    write_wav("sfx_pearl.wav", fade_edges(sfx_pearl()))
    write_wav("sfx_hatch.wav", fade_edges(sfx_hatch()))
    write_wav("sfx_achievement.wav", fade_edges(sfx_achievement()))
    write_wav("sfx_prestige.wav", sfx_prestige())
    write_wav("sfx_event.wav", fade_edges(sfx_event()))
    write_wav("sfx_reward.wav", fade_edges(sfx_reward()))
    write_wav("sfx_feed.wav", fade_edges(sfx_feed()))
    write_wav("sfx_final.wav", sfx_final())
    write_wav("sfx_error.wav", fade_edges(sfx_error()))
    write_wav("ambient_water.wav", ambient_water())
    write_wav("music_day.wav", render_music(bpm=76, transpose=0, night=False))
    write_wav("music_night.wav", render_music(bpm=60, transpose=-5, night=True))


if __name__ == "__main__":
    main()
