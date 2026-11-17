#!/usr/bin/env python3
# genpal.py <image> <dark|light|auto> <wallpaper|dark|light>
# One palette for everything: Quickshell, wal (kitty/btop/GTK/lock), KDE, Discord, borders.
import sys, os, re, json, math, colorsys, shutil, subprocess, warnings
warnings.filterwarnings("ignore")
from string import Template

img, kind, mode = sys.argv[1], sys.argv[2], sys.argv[3]
light = kind == "light"
home = os.path.expanduser("~")
cfg_dir = os.path.join(home, ".config", "qstheme")
out_dir = os.path.join(home, ".local", "state", "qstheme")

def rd(name, default=""):
    try:
        v = open(os.path.join(cfg_dir, name)).read().strip()
        return v if v else default
    except Exception:
        return default

def num(name, default):
    try:
        return float(rd(name, str(default)))
    except ValueError:
        return float(default)

# ---------- OKLCH colour maths ----------
def s2l(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def l2s(c):
    c = max(0.0, min(1.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055

def hex2lab(h):
    h = h.lstrip("#")
    r, g, b = [s2l(int(h[i:i + 2], 16) / 255) for i in (0, 2, 4)]
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_, m_, s_ = l ** (1 / 3), m ** (1 / 3), s ** (1 / 3)
    return (0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
            1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
            0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_)

def lch2rgb(L, C, H):
    a = C * math.cos(math.radians(H))
    b = C * math.sin(math.radians(H))
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)

def inrgb(rgb):
    return all(-0.0005 <= v <= 1.0005 for v in rgb)

def lch(L, C, H):
    L = max(0.0, min(1.0, L))
    C = max(0.0, C)
    rgb = lch2rgb(L, C, H)
    if not inrgb(rgb):
        lo, hi = 0.0, C
        for _ in range(24):
            mid = (lo + hi) / 2
            if inrgb(lch2rgb(L, mid, H)):
                lo = mid
            else:
                hi = mid
        rgb = lch2rgb(L, lo, H)
    return "#%02x%02x%02x" % tuple(round(l2s(v) * 255) for v in rgb)

def rlum(hx):
    h = hx.lstrip("#")
    r, g, b = [s2l(int(h[i:i + 2], 16) / 255) for i in (0, 2, 4)]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast(a, b):
    la, lb = rlum(a), rlum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)

def pick(L, C, H, bg, ratio):
    c = lch(L, C, H)
    for _ in range(60):
        if contrast(c, bg) >= ratio:
            break
        L += -0.012 if light else 0.012
        c = lch(L, C, H)
    return c

def fix_hex(c, bg, ratio):
    L, a, b = hex2lab(c)
    return pick(L, math.hypot(a, b), (math.degrees(math.atan2(b, a)) + 360) % 360, bg, ratio)

def shade(c, dl):
    L, a, b = hex2lab(c)
    return lch(L + dl, math.hypot(a, b), (math.degrees(math.atan2(b, a)) + 360) % 360)

# ---------- finding the wallpaper's real colour ----------
def pixels(path):
    try:
        from PIL import Image
        im = Image.open(path).convert("RGB")
        im.thumbnail((64, 64))
        return list(im.getdata())
    except Exception:
        pass
    try:
        out = subprocess.run(["magick", path, "-resize", "64x64!", "-depth", "8", "txt:-"],
                             capture_output=True, text=True, timeout=40).stdout
        px = []
        for line in out.splitlines():
            m = re.search(r"\((\d+),(\d+),(\d+)", line)
            if m:
                px.append(tuple(int(x) for x in m.groups()))
        return px
    except Exception:
        return []

if kind == "auto":
    _px = pixels(img)
    _mean = sum(0.2126 * r + 0.7152 * g + 0.0722 * b for r, g, b in _px) / (255.0 * len(_px)) if _px else 0.0
    kind = "light" if _mean > 0.6 else "dark"
    light = kind == "light"

def source_colour(path):
    bins = [0.0] * 36
    chs = [0.0] * 36
    cnt = [0] * 36
    for r, g, b in pixels(path):
        L, a, bb = hex2lab("#%02x%02x%02x" % (r, g, b))
        C = math.hypot(a, bb)
        if C < 0.04 or L < 0.2 or L > 0.95:
            continue
        H = (math.degrees(math.atan2(bb, a)) + 360) % 360
        i = int(H / 10) % 36
        bins[i] += C * C
        chs[i] += C
        cnt[i] += 1
    if sum(bins) < 0.3:
        return None
    sm = [bins[i - 1] * 0.5 + bins[i] + bins[(i + 1) % 36] * 0.5 for i in range(36)]
    peak = max(range(36), key=lambda i: sm[i])
    x = y = cs = 0.0
    n = 0
    for d in (-2, -1, 0, 1, 2):
        i = (peak + d) % 36
        ang = math.radians(i * 10 + 5)
        x += bins[i] * math.cos(ang)
        y += bins[i] * math.sin(ang)
        cs += chs[i]
        n += cnt[i]
    return (math.degrees(math.atan2(y, x)) + 360) % 360, (cs / n if n else 0.1)

# ---------- palettes ----------
def mono():
    if light:
        return dict(bg="#f4f4f4", fg="#161616", dim="#7a7a7a", accent="#2a2a2a", accent2="#444444",
                    c1="#4a4a4a", c2="#5a5a5a", c3="#6a6a6a", c5="#505050"), "monochrome light"
    return dict(bg="#0b0b0b", fg="#e6e6e6", dim="#7a7a7a", accent="#c4c4c4", accent2="#d0d0d0",
                c1="#8f8f8f", c2="#a0a0a0", c3="#b0b0b0", c5="#9a9a9a"), "monochrome dark"

def oklch_palette():
    variant = rd("variant", "balanced")
    cap = {"soft": 0.10, "balanced": 0.16, "vivid": 0.23}.get(variant, 0.16)
    harmony = rd("harmony", "analogous")
    cscale = num("chroma", 1.0)
    tint = num("bgtint", 1.0)
    shift = num("hueshift", 0)
    ratio = num("contrast", 4.5)
    src = source_colour(img)
    h, cs = src if src else (250.0, 0.10)
    exact = rd("accent", "")
    exact_ok = re.fullmatch(r"#[0-9a-fA-F]{6}", exact) is not None
    if exact_ok:
        eL, ea, eb = hex2lab(exact)
        h = (math.degrees(math.atan2(eb, ea)) + 360) % 360
        c = math.hypot(ea, eb)
    else:
        c = max(0.07, min(cap, cs)) * cscale
    h = (h + shift) % 360
    c = max(0.0, min(0.32, c))
    bg = lch(0.965 if light else 0.17, (0.016 if light else 0.028) * tint, h)
    La = 0.50 if light else 0.74          # accent lightness
    off = {"analogous": (25, 0, -25, -50, 50),
           "colorful": (60, 0, -35, -70, 35),
           "mono": (0, 0, 0, 0, 0)}.get(harmony, (25, 0, -25, -50, 50))
    d = 0.06 if light else -0.06          # lightness steps for the mono harmony
    accent = pick(eL if exact_ok else La, c, h, bg, ratio)
    if harmony == "mono":
        sp = [(La + d, c * 0.9), (La - d, c * 0.5), (La + 2 * d, c * 0.8), (La - 2 * d, c * 0.7), (La + 3 * d, c * 0.6)]
    else:
        sp = [(La, c * 0.9), (La, c * 0.5), (La, c * 0.8), (La, c * 0.7), (La, c * 0.7)]
    P = dict(
        bg=bg,
        fg=pick(0.22 if light else 0.93, 0.02 * tint, h, bg, max(9, ratio)),
        dim=pick(0.52 if light else 0.68, 0.03 * tint, h, bg, 3.2),
        accent=accent,
        accent2=pick(sp[0][0], sp[0][1], h + off[0], bg, ratio),
        c3=pick(sp[1][0], sp[1][1], h + off[1], bg, ratio),
        c2=pick(sp[2][0], sp[2][1], h + off[2], bg, ratio),
        c1=pick(sp[3][0], sp[3][1], h + off[3], bg, ratio),
        c5=pick(sp[4][0], sp[4][1], h + off[4], bg, ratio),
    )
    note = "oklch %s/%s hue %d chroma %.2f%s%s" % (variant, harmony, h, c, " exact accent" if exact_ok else "",
                                                  "" if (src or exact_ok) else " (no colour in wallpaper)")
    return P, note

def material_palette():
    exe = shutil.which("matugen") or os.path.expanduser("~/.cargo/bin/matugen")
    if not exe or not os.path.exists(exe):
        return None, "matugen not found"
    scheme = rd("scheme", "scheme-tonal-spot")
    out = None
    for extra in (["--dry-run"], []):
        try:
            r = subprocess.run([exe, "image", img, "--json", "hex", "--type", scheme] + extra,
                               capture_output=True, text=True, timeout=60)
        except Exception as e:
            return None, "matugen failed: %s" % e
        if r.returncode == 0 and "{" in r.stdout:
            out = r.stdout
            break
    if not out:
        return None, "matugen printed nothing usable"
    try:
        d = json.loads(out[out.index("{"): out.rindex("}") + 1])
    except Exception:
        return None, "could not read matugen's json"
    m = "light" if light else "dark"

    def g(role):
        c = d.get("colors", d)
        for a, b in ((role, m), (m, role)):
            try:
                v = c[a][b]
            except Exception:
                continue
            if isinstance(v, dict):
                v = v.get("color") or v.get("hex") or next(iter(v.values()), None)
            if isinstance(v, str) and v.startswith("#"):
                return v[:7]
        return None

    bg = g("surface") or g("background")
    fg = g("on_surface")
    pri, sec, ter = g("primary"), g("secondary"), g("tertiary")
    if not (bg and fg and pri and sec and ter):
        return None, "matugen json is missing colours"
    ratio = num("contrast", 4.5)
    ol = g("outline") or g("on_surface_variant") or fg
    e1 = g("primary_fixed_dim") or pri
    e2 = g("tertiary_fixed_dim") or ter
    e3 = g("secondary_fixed_dim") or sec
    return dict(bg=bg, fg=fix_hex(fg, bg, 9), dim=fix_hex(ol, bg, 3.2),
                accent=fix_hex(pri, bg, ratio), accent2=fix_hex(ter, bg, ratio), c3=fix_hex(sec, bg, ratio),
                c2=fix_hex(e1, bg, ratio), c1=fix_hex(e2, bg, ratio), c5=fix_hex(e3, bg, ratio)), \
        "material3 %s" % scheme

if mode in ("dark", "light"):
    P, note = mono()
else:
    P = None
    note = ""
    if rd("engine", "oklch") == "material":
        P, why = material_palette()
        if P:
            note = why
        else:
            print("[setwall] material3 unavailable (%s), using oklch" % why)
    if P is None:
        P, note = oklch_palette()

# ---------- write everything ----------
os.makedirs(out_dir, exist_ok=True)

qml = "pragma Singleton\nimport Quickshell\nimport QtQuick\n\nSingleton {\n"
qml += "    readonly property bool light: %s\n" % ("true" if light else "false")
for k in ("bg", "fg", "dim", "accent", "accent2", "c1", "c2", "c3", "c5"):
    qml += '    readonly property color %s: "%s"\n' % (k, P[k])
qml += "    function a(c, o) { return Qt.rgba(c.r, c.g, c.b, o) }\n}\n"
open(os.path.join(out_dir, "Pal.qml"), "w").write(qml)

hy = lambda c, a: "rgba(%s%s)" % (c.lstrip("#"), a)
open(os.path.join(out_dir, "colors-hypr.lua"), "w").write(
    'return {\n    active = "%s",\n    active2 = "%s",\n    inactive = "%s",\n}\n'
    % (hy(P["accent"], "ee"), hy(P["accent2"], "ee"), hy(P["dim"], "66")))

lift = lambda c: shade(c, -0.07 if light else 0.07)
W = {
    "wallpaper": img, "alpha": "100",
    "special": {"background": P["bg"], "foreground": P["fg"], "cursor": P["fg"]},
    "colors": {
        "color0": P["bg"], "color1": P["c1"], "color2": P["c2"], "color3": P["c3"],
        "color4": P["accent"], "color5": P["c5"], "color6": P["accent2"], "color7": P["fg"],
        "color8": P["dim"], "color9": lift(P["c1"]), "color10": lift(P["c2"]), "color11": lift(P["c3"]),
        "color12": lift(P["accent"]), "color13": lift(P["c5"]), "color14": lift(P["accent2"]), "color15": P["fg"],
    },
}
json.dump(W, open(os.path.join(out_dir, "wal-theme.json"), "w"), indent=2)

# KDE / Qt colour schemes (two names so plasma-apply-colorscheme always re-applies)
def rgbs(c):
    c = c.lstrip("#")
    return "%d,%d,%d" % (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16))

def kde_sec(name, bgc, alt, fgn, fga, fgi, link):
    return ("[Colors:%s]\nBackgroundNormal=%s\nBackgroundAlternate=%s\nDecorationFocus=%s\nDecorationHover=%s\n"
            "ForegroundActive=%s\nForegroundInactive=%s\nForegroundLink=%s\nForegroundNegative=218,68,83\n"
            "ForegroundNeutral=246,116,0\nForegroundNormal=%s\nForegroundPositive=39,174,96\nForegroundVisited=%s\n\n"
            % (name, rgbs(bgc), rgbs(alt), rgbs(P["accent"]), rgbs(P["accent2"]),
               rgbs(fga), rgbs(fgi), rgbs(link), rgbs(fgn), rgbs(P["accent2"])))

surf = shade(P["bg"], -0.04 if light else 0.04)
alt = shade(P["bg"], -0.02 if light else 0.02)
secs = ""
for nm, bgc in (("Window", P["bg"]), ("View", surf), ("Button", surf), ("Tooltip", surf),
                ("Header", P["bg"]), ("Complementary", P["bg"])):
    secs += kde_sec(nm, bgc, alt, P["fg"], P["accent"], P["dim"], P["accent"])
secs += kde_sec("Selection", P["accent"], P["accent"], P["bg"], P["bg"], P["bg"], P["bg"])
fx = ("[ColorEffects:Disabled]\nColor=56,56,56\nColorAmount=0\nColorEffect=0\nContrastAmount=0.65\n"
      "ContrastEffect=1\nIntensityAmount=0.1\nIntensityEffect=2\n\n"
      "[ColorEffects:Inactive]\nChangeSelectionColor=true\nColor=112,111,110\nColorAmount=0.025\n"
      "ColorEffect=2\nContrastAmount=0.1\nContrastEffect=2\nEnable=false\nIntensityAmount=0\nIntensityEffect=0\n")
kd = os.path.join(home, ".local", "share", "color-schemes")
os.makedirs(kd, exist_ok=True)
for n in ("A", "B"):
    open(os.path.join(kd, "Wallpaper%s.colors" % n), "w").write(
        "[General]\nColorScheme=Wallpaper%s\nName=Wallpaper %s\nshadeSortColumn=true\n\n%s%s" % (n, n, secs, fx))

# Discord (Vencord / Vesktop) theme file
def rgba(c, a):
    c = c.lstrip("#")
    return "rgba(%d, %d, %d, %s)" % (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), a)

DISCORD = Template("""/**
 * @name Wallpaper
 * @description Discord colours follow your desktop wallpaper (written by setwall)
 * @version 1.0
 * @author setwall
 */
:root, .theme-dark, .theme-light, .theme-darker, .theme-midnight, .visual-refresh {
  --background-primary: $b2 !important;
  --background-secondary: $b1 !important;
  --background-secondary-alt: $b1 !important;
  --background-tertiary: $b0 !important;
  --background-floating: $b3 !important;
  --background-accent: $b4 !important;
  --background-modifier-hover: $hover !important;
  --background-modifier-active: $active !important;
  --background-modifier-selected: $active !important;
  --background-modifier-accent: $border !important;
  --channeltextarea-background: $b3 !important;
  --chat-background: $b2 !important;
  --text-normal: $fg !important;
  --text-muted: $dim !important;
  --text-link: $accent !important;
  --header-primary: $fg !important;
  --header-secondary: $dim !important;
  --interactive-normal: $dim !important;
  --interactive-hover: $fg !important;
  --interactive-active: $fg !important;
  --channels-default: $dim !important;
  --brand-experiment: $accent !important;
  --brand-500: $accent !important;
  --brand-360: $accent !important;
  --scrollbar-thin-thumb: $b4 !important;
  --background-base-lowest: $b0 !important;
  --background-base-lower: $b1 !important;
  --background-base-low: $b2 !important;
  --background-surface-high: $b3 !important;
  --background-surface-higher: $b4 !important;
  --background-surface-highest: $b4 !important;
  --text-default: $fg !important;
  --text-strong: $fg !important;
  --text-subtle: $dim !important;
  --interactive-icon-default: $dim !important;
  --interactive-icon-hover: $fg !important;
  --interactive-icon-active: $fg !important;
  --border-subtle: $border !important;
  --border-normal: $border !important;
  --bg-brand: $accent !important;
  --text-brand: $accent !important;
}
""")
up = -1 if light else 1
css = DISCORD.safe_substitute(
    b0=shade(P["bg"], -0.025 * up), b1=P["bg"], b2=shade(P["bg"], 0.025 * up),
    b3=shade(P["bg"], 0.055 * up), b4=shade(P["bg"], 0.085 * up),
    fg=P["fg"], dim=P["dim"], accent=P["accent"],
    hover=rgba(P["accent"], 0.12), active=rgba(P["accent"], 0.22), border=rgba(P["fg"], 0.12))
nd = 0
for d in (() if rd("apps/discord", "on") == "off" else ("~/.config/vesktop/themes", "~/.config/Vesktop/themes", "~/.config/Vencord/themes",
          "~/.var/app/dev.vencord.Vesktop/config/vesktop/themes",
          "~/.var/app/com.discordapp.Discord/config/Vencord/themes")):
    d = os.path.expanduser(d)
    if os.path.isdir(os.path.dirname(d)):
        os.makedirs(d, exist_ok=True)
        open(os.path.join(d, "wallpaper.theme.css"), "w").write(css)
        nd += 1

open(os.path.join(out_dir, "kind"), "w").write(kind)
print("[setwall] palette: %s | bg %s accent %s | discord files: %d" % (note, P["bg"], P["accent"], nd))
