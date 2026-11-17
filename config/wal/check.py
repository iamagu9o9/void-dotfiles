import json, os, sys, colorsys

kind = sys.argv[1] if len(sys.argv) > 1 else "dark"
p = os.path.expanduser("~/.cache/wal/colors.json")
try:
    d = json.load(open(p))
except Exception:
    sys.exit(1)

def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) / 255 for i in (0, 2, 4))

def lum(c):
    f = lambda v: v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = [f(v) for v in c]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast(a, b):
    la, lb = lum(a), lum(b)
    if la < lb:
        la, lb = lb, la
    return (la + 0.05) / (lb + 0.05)

bg = rgb(d["special"]["background"])
fg = rgb(d["special"]["foreground"])

if kind == "light":
    if lum(bg) < 0.55:
        sys.exit(1)
else:
    if lum(bg) > 0.15:
        sys.exit(1)

if contrast(fg, bg) < 4.5:
    sys.exit(1)

good = 0
for i in range(1, 7):
    c = rgb(d["colors"]["color%d" % i])
    h, s, v = colorsys.rgb_to_hsv(*c)
    if s >= 0.30 and contrast(c, bg) >= 3.0:
        good += 1
sys.exit(0 if good >= 3 else 1)
