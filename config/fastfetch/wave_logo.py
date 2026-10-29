"""Génère le logo fastfetch : 3 vagues (~) épaisses en demi-blocs Unicode."""
import math
import sys

W = int(sys.argv[2]) if len(sys.argv) > 2 else 30     # largeur en caractères
PH = int(sys.argv[3]) if len(sys.argv) > 3 else 12    # hauteur en « pixels » (2 par ligne)
AMP = PH * 0.26           # amplitude de la vague
THICK = PH * 0.20         # demi-épaisseur du trait
CAP = W * 0.07            # marge pour les bouts arrondis


def wave_y(x):
    # une période de sinus sur la largeur utile : bosse à gauche, creux à droite
    t = (x - CAP) / (W - 2 * CAP)
    return PH / 2 - AMP * math.sin(2 * math.pi * t)


def inside(x, y):
    # distance au segment de courbe, bouts arrondis (approx. par échantillonnage)
    best = 1e9
    steps = 200
    for i in range(steps + 1):
        cx = CAP + (W - 2 * CAP) * i / steps
        cy = wave_y(cx)
        # les caractères sont ~2x plus hauts que larges : 1 colonne ≈ 1 pixel vertical
        d = math.hypot(x - cx, y - cy)
        best = min(best, d)
    return best <= THICK


rows = []
for r in range(PH // 2):
    line = ""
    for c in range(W):
        top = inside(c + 0.5, 2 * r + 0.5)
        bot = inside(c + 0.5, 2 * r + 1.5)
        line += "█" if top and bot else "▀" if top else "▄" if bot else " "
    rows.append(line.rstrip())

# retire les lignes vides en haut/bas
while rows and not rows[0].strip():
    rows.pop(0)
while rows and not rows[-1].strip():
    rows.pop()

out = []
for n, color in enumerate(("$1", "$2", "$3")):
    if n:
        out.append("")
    out += [color + "  " + r for r in rows]

with open(sys.argv[1], "w") as f:
    f.write("\n".join(out) + "\n")
