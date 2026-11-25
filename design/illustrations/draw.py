"""Draws the seed illustrations for every artwork slot (06-update §5, P24).

Run: python3 design/illustrations/draw.py (the scenes are in scenes.py)
It writes design/illustrations/<slot>.svg and copies them to the backend seed folder and the
pao_ui bundle. Flat line-and-fill in the navy family: outlines in Primary (ivory on the navy
hero backgrounds), fills in Soft, Ground and white, at most two small Action accents, no text,
no gradients. Motifs are Bangladeshi: Dhaka rooftops with water tanks, Sangsad Bhaban,
rickshaws, tea stalls, tiffin carriers, jute bazar bags, banana trees, kantha stitching.
"""
import pathlib
import re
import shutil

P, S, G, W, A, INK = "#16336F", "#B1BFE2", "#F0EEDF", "#FFFFFF", "#FE492A", "#0E1F45"
ROOT = pathlib.Path(__file__).resolve().parents[2]
ICONS = ROOT / "design" / "icons"


def icon(key, x, y, size, color):
    """A library icon (24 grid) placed at x, y and scaled to size."""
    body = re.sub(r"^<svg[^>]*>|</svg>\s*$", "", (ICONS / f"{key}.svg").read_text())
    k = size / 24
    return (f'<g transform="translate({x:.1f} {y:.1f}) scale({k:.3f})" fill="none" stroke="{color}" '
            f'stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">{body}</g>')


def bubble(cx, cy, r, key, line, fill):
    """A round speech bubble with a service icon, like the demo's floating services."""
    return (f'<path d="M{cx - r * .35:.1f} {cy + r * .9:.1f}l{-r * .25:.1f} {r * .45:.1f}l{r * .55:.1f} {-r * .3:.1f}z" '
            f'fill="{fill}" stroke="{line}" stroke-width="{r * .08:.1f}" stroke-linejoin="round"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{line}" stroke-width="{r * .08:.1f}"/>'
            + icon(key, cx - r * .55, cy - r * .55, r * 1.1, P))


def cloud(x, y, w, line):
    h = w * .32
    return (f'<path d="M{x} {y + h}h{w}a{h * .55:.1f} {h * .55:.1f} 0 0 0-{h * .5:.1f}-{h * .7:.1f}'
            f'a{h * .8:.1f} {h * .8:.1f} 0 0 0-{w * .45:.1f}-{h * .2:.1f}a{h * .6:.1f} {h * .6:.1f} 0 0 0-{w * .35:.1f} {h * .5:.1f}'
            f'a{h * .45:.1f} {h * .45:.1f} 0 0 0-{w * .2 - h * .5:.1f} {h * .4:.1f}z" fill="none" stroke="{line}" '
            f'stroke-width="{w * .025:.1f}" stroke-linejoin="round" stroke-linecap="round"/>')


def sangsad(x, base, w, line, fill):
    """Sangsad Bhaban, the parliament: a block with the round and triangular cut-outs."""
    h = w * .55
    parts = [f'<rect x="{x}" y="{base - h}" width="{w}" height="{h}" fill="{fill}" stroke="{line}" stroke-width="{w * .02:.1f}"/>',
             f'<rect x="{x + w * .3}" y="{base - h * 1.35}" width="{w * .4}" height="{h * .35}" fill="{fill}" stroke="{line}" stroke-width="{w * .02:.1f}"/>']
    for i in range(3):
        cx = x + w * (.2 + i * .3)
        parts.append(f'<circle cx="{cx:.1f}" cy="{base - h * .62:.1f}" r="{w * .07:.1f}" fill="none" stroke="{line}" stroke-width="{w * .018:.1f}"/>')
        parts.append(f'<path d="M{cx - w * .07:.1f} {base - h * .15:.1f}l{w * .07:.1f} {-h * .25:.1f}l{w * .07:.1f} {h * .25:.1f}z" fill="none" stroke="{line}" stroke-width="{w * .018:.1f}" stroke-linejoin="round"/>')
    return "".join(parts)


def building(x, base, w, h, line, fill, rows=3, tank=False):
    """A Dhaka block with windows; a rooftop water tank on some."""
    sw = max(w * .03, 2)
    parts = [f'<rect x="{x}" y="{base - h}" width="{w}" height="{h}" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}"/>']
    for r in range(rows):
        for c in range(2):
            parts.append(f'<rect x="{x + w * (.2 + c * .4):.1f}" y="{base - h + h * (.12 + r * .28):.1f}" width="{w * .2:.1f}" height="{h * .14:.1f}" fill="none" stroke="{line}" stroke-width="{sw * .7:.1f}"/>')
    if tank:
        parts.append(f'<rect x="{x + w * .55:.1f}" y="{base - h - w * .3:.1f}" width="{w * .3:.1f}" height="{w * .22:.1f}" rx="{w * .05:.1f}" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}"/>'
                     f'<path d="M{x + w * .6:.1f} {base - h - w * .08:.1f}v{w * .08:.1f}M{x + w * .8:.1f} {base - h - w * .08:.1f}v{w * .08:.1f}" stroke="{line}" stroke-width="{sw:.1f}"/>')
    return "".join(parts)


def banana(x, base, h, line, fill):
    """A banana tree: trunk and drooping leaves."""
    sw = h * .025
    leaves = "".join(
        f'<path d="M{x} {base - h * .75}q{dx * h * .3:.1f} {-h * .3:.1f} {dx * h * .5:.1f} {h * .05:.1f}q{-dx * h * .25:.1f} {h * .02:.1f} {-dx * h * .5:.1f} {-h * .05:.1f}z" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>'
        for dx in (-1, 1, -.7, .7))
    return (f'<path d="M{x - h * .04:.1f} {base}l{h * .02:.1f} {-h * .78:.1f}h{h * .04:.1f}l{h * .02:.1f} {h * .78:.1f}z" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}"/>'
            + leaves)


def plant(x, base, h, line, fill):
    """A potted plant, as on Dhaka balconies and rooftops."""
    sw = h * .04
    return (f'<path d="M{x - h * .25:.1f} {base - h * .35}h{h * .5:.1f}l{-h * .06:.1f} {h * .35:.1f}h{-h * .38:.1f}z" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>'
            + "".join(f'<path d="M{x} {base - h * .35:.1f}q{d * h * .35:.1f} {-h * .3:.1f} {d * h * .1:.1f} {-h * .65:.1f}q{-d * h * .1:.1f} {h * .35:.1f} {-d * h * .1:.1f} {h * .65:.1f}z" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>' for d in (-1, 1, .3)))


def cat(x, base, s, line, fill, accent=None):
    """A sleeping cat, curled."""
    sw = s * .05
    return (f'<path d="M{x} {base}c0-{s * .5:.1f} {s * .35:.1f}-{s * .75:.1f} {s * .85:.1f}-{s * .75:.1f}c{s * .45:.1f} 0 {s * .75:.1f} {s * .3:.1f} {s * .75:.1f} {s * .75:.1f}z" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>'
            f'<circle cx="{x + s * 1.45:.1f}" cy="{base - s * .32:.1f}" r="{s * .3:.1f}" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}"/>'
            f'<path d="M{x + s * 1.3:.1f} {base - s * .55:.1f}l{s * .05:.1f}-{s * .2:.1f}l{s * .12:.1f} {s * .12:.1f}M{x + s * 1.5:.1f} {base - s * .6:.1f}l{s * .1:.1f}-{s * .18:.1f}l{s * .08:.1f} {s * .2:.1f}" fill="none" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>'
            f'<path d="M{x + s * 1.35:.1f} {base - s * .32:.1f}h{s * .1:.1f}M{x + s * 1.52:.1f} {base - s * .32:.1f}h{s * .1:.1f}" stroke="{line}" stroke-width="{sw * .8:.1f}" stroke-linecap="round"/>'
            f'<path d="M{x} {base}q{-s * .35:.1f} {-s * .05:.1f} {-s * .2:.1f} {-s * .4:.1f}" fill="none" stroke="{line}" stroke-width="{sw:.1f}" stroke-linecap="round"/>'
            + (f'<circle cx="{x + s * .55:.1f}" cy="{base - s * .45:.1f}" r="{s * .12:.1f}" fill="{accent}"/>' if accent else ""))


def person(x, base, h, line, skin, cloth, hair, phone=False, long_hair=False, cap=False, toolbag=False):
    """A simple standing figure: round head, kurta or shirt, arms; no facial detail beyond eyes."""
    sw = h * .018
    head_r = h * .1
    hy = base - h + head_r
    parts = []
    if long_hair:
        parts.append(f'<path d="M{x - head_r * 1.1:.1f} {hy:.1f}q0 {h * .35:.1f} {head_r * .4:.1f} {h * .42:.1f}h{head_r * 1.4:.1f}q{head_r * .4:.1f} -{h * .07:.1f} {head_r * .4:.1f} -{h * .42:.1f}z" fill="{hair}" stroke="{line}" stroke-width="{sw:.1f}"/>')
    body_top = hy + head_r * 1.3
    parts.append(f'<path d="M{x - h * .16:.1f} {base}l{h * .03:.1f}-{base - body_top - h * .05:.1f}q{h * .13:.1f}-{h * .06:.1f} {h * .26:.1f} 0l{h * .03:.1f} {base - body_top - h * .05:.1f}z" fill="{cloth}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>')
    parts.append(f'<rect x="{x - h * .03:.1f}" y="{hy + head_r * .7:.1f}" width="{h * .06:.1f}" height="{h * .08:.1f}" fill="{skin}" stroke="{line}" stroke-width="{sw:.1f}"/>')
    parts.append(f'<circle cx="{x}" cy="{hy:.1f}" r="{head_r:.1f}" fill="{skin}" stroke="{line}" stroke-width="{sw:.1f}"/>')
    parts.append(f'<path d="M{x - head_r:.1f} {hy - head_r * .1:.1f}a{head_r:.1f} {head_r:.1f} 0 0 1 {head_r * 2:.1f} 0q-{head_r:.1f}-{head_r * .5:.1f} -{head_r * 2:.1f} 0z" fill="{hair}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>')
    if cap:
        parts.append(f'<path d="M{x - head_r * 1.05:.1f} {hy - head_r * .2:.1f}a{head_r * 1.05:.1f} {head_r * .9:.1f} 0 0 1 {head_r * 2.1:.1f} 0h{head_r * .5:.1f}z" fill="{cloth}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>')
    for d in (-.35, .35):
        parts.append(f'<circle cx="{x + head_r * d:.1f}" cy="{hy + head_r * .15:.1f}" r="{head_r * .09:.1f}" fill="{line}"/>')
    parts.append(f'<path d="M{x - head_r * .3:.1f} {hy + head_r * .45:.1f}q{head_r * .3:.1f} {head_r * .25:.1f} {head_r * .6:.1f} 0" fill="none" stroke="{line}" stroke-width="{sw * .8:.1f}" stroke-linecap="round"/>')
    sy = body_top + h * .04
    if phone:
        parts.append(f'<path d="M{x + h * .1:.1f} {sy:.1f}l{h * .1:.1f} {h * .18:.1f}l{h * .08:.1f}-{h * .1:.1f}" fill="none" stroke="{line}" stroke-width="{h * .05:.1f}" stroke-linecap="round" stroke-linejoin="round"/>'
                     f'<path d="M{x + h * .1:.1f} {sy:.1f}l{h * .1:.1f} {h * .18:.1f}l{h * .08:.1f}-{h * .1:.1f}" fill="none" stroke="{cloth}" stroke-width="{h * .032:.1f}" stroke-linecap="round" stroke-linejoin="round"/>'
                     f'<rect x="{x + h * .22:.1f}" y="{sy - h * .02:.1f}" width="{h * .08:.1f}" height="{h * .13:.1f}" rx="{h * .015:.1f}" fill="{line}" transform="rotate(12 {x + h * .26:.1f} {sy + h * .05:.1f})"/>')
    else:
        parts.append(f'<path d="M{x + h * .12:.1f} {sy:.1f}l{h * .08:.1f} {h * .25:.1f}" stroke="{line}" stroke-width="{h * .05:.1f}" stroke-linecap="round"/>'
                     f'<path d="M{x + h * .12:.1f} {sy:.1f}l{h * .08:.1f} {h * .25:.1f}" stroke="{cloth}" stroke-width="{h * .032:.1f}" stroke-linecap="round"/>')
    parts.append(f'<path d="M{x - h * .12:.1f} {sy:.1f}l{-h * .08:.1f} {h * .25:.1f}" stroke="{line}" stroke-width="{h * .05:.1f}" stroke-linecap="round"/>'
                 f'<path d="M{x - h * .12:.1f} {sy:.1f}l{-h * .08:.1f} {h * .25:.1f}" stroke="{cloth}" stroke-width="{h * .032:.1f}" stroke-linecap="round"/>')
    if toolbag:
        parts.append(f'<rect x="{x - h * .32:.1f}" y="{base - h * .3:.1f}" width="{h * .18:.1f}" height="{h * .12:.1f}" rx="{h * .02:.1f}" fill="{S}" stroke="{line}" stroke-width="{sw:.1f}"/>'
                     f'<path d="M{x - h * .28:.1f} {base - h * .3:.1f}q{h * .05:.1f}-{h * .07:.1f} {h * .1:.1f} 0" fill="none" stroke="{line}" stroke-width="{sw:.1f}"/>')
    return "".join(parts)


def rickshaw(x, base, w, line, fill, accent):
    """A cycle rickshaw from the side: hood, seat, big wheels; one painted accent."""
    sw = w * .015
    r = w * .17
    return (f'<circle cx="{x + w * .25:.1f}" cy="{base - r:.1f}" r="{r:.1f}" fill="none" stroke="{line}" stroke-width="{sw * 1.5:.1f}"/>'
            f'<circle cx="{x + w * .85:.1f}" cy="{base - r * .6:.1f}" r="{r * .6:.1f}" fill="none" stroke="{line}" stroke-width="{sw * 1.5:.1f}"/>'
            f'<path d="M{x + w * .25:.1f} {base - r:.1f}l{w * .6:.1f} {r * .4:.1f}M{x + w * .25:.1f} {base - r:.1f}v{-r * .9:.1f}h{w * .25:.1f}" fill="none" stroke="{line}" stroke-width="{sw * 1.3:.1f}" stroke-linecap="round"/>'
            f'<path d="M{x + w * .05:.1f} {base - r * 1.9:.1f}q{w * .05:.1f}-{r * 1.6:.1f} {w * .45:.1f}-{r * 1.5:.1f}v{r * 1.5:.1f}z" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>'
            f'<path d="M{x + w * .15:.1f} {base - r * 2.6:.1f}h{w * .25:.1f}" stroke="{accent}" stroke-width="{sw * 2:.1f}" stroke-linecap="round"/>'
            f'<path d="M{x + w * .7:.1f} {base - r * 1.3:.1f}l{w * .1:.1f}-{r * .8:.1f}h{w * .08:.1f}" fill="none" stroke="{line}" stroke-width="{sw * 1.3:.1f}" stroke-linecap="round"/>')


def jute_bag(x, base, s, line, fill, stitch=True):
    """A bazar jute bag with handles and kantha stitching."""
    sw = s * .04
    parts = [f'<path d="M{x} {base - s * .9:.1f}h{s:.1f}l{-s * .08:.1f} {s * .9:.1f}h{-s * .84:.1f}z" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>',
             f'<path d="M{x + s * .25:.1f} {base - s * .9:.1f}v{-s * .1:.1f}a{s * .25:.1f} {s * .25:.1f} 0 0 1 {s * .5:.1f} 0v{s * .1:.1f}" fill="none" stroke="{line}" stroke-width="{sw:.1f}"/>']
    if stitch:
        parts.append(f'<path d="M{x + s * .12:.1f} {base - s * .55:.1f}h{s * .76:.1f}M{x + s * .14:.1f} {base - s * .3:.1f}h{s * .72:.1f}" stroke="{line}" stroke-width="{sw * .7:.1f}" stroke-dasharray="{s * .05:.1f} {s * .05:.1f}"/>')
    return "".join(parts)


def tiffin(x, base, s, line, fill):
    """A three-tier tiffin carrier with its handle."""
    sw = s * .05
    tiers = "".join(f'<rect x="{x}" y="{base - s * (.3 + i * .3):.1f}" width="{s * .7:.1f}" height="{s * .28:.1f}" rx="{s * .06:.1f}" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}"/>' for i in range(3))
    return tiers + (f'<path d="M{x + s * .1:.1f} {base - s * .9:.1f}v{-s * .12:.1f}h{s * .5:.1f}v{s * .12:.1f}M{x + s * .35:.1f} {base - s * 1.02:.1f}v{-s * .08:.1f}" fill="none" stroke="{line}" stroke-width="{sw:.1f}" stroke-linecap="round"/>')


def tea(x, base, s, line, fill):
    """A clay tea cup on a saucer with steam."""
    sw = s * .05
    return (f'<path d="M{x} {base - s * .6:.1f}h{s * .6:.1f}l{-s * .08:.1f} {s * .5:.1f}h{-s * .44:.1f}z" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>'
            f'<path d="M{x - s * .12:.1f} {base - s * .08:.1f}h{s * .84:.1f}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linecap="round"/>'
            + "".join(f'<path d="M{x + s * d:.1f} {base - s * .7:.1f}q{-s * .08:.1f}-{s * .12:.1f} 0-{s * .24:.1f}q{s * .08:.1f}-{s * .12:.1f} 0-{s * .24:.1f}" fill="none" stroke="{line}" stroke-width="{sw * .8:.1f}" stroke-linecap="round"/>' for d in (.2, .4)))


def boat(x, base, s, line, fill):
    """A paper boat on a wave: the offline state."""
    sw = s * .04
    return (f'<path d="M{x} {base - s * .3:.1f}h{s:.1f}l{-s * .15:.1f} {s * .3:.1f}h{-s * .7:.1f}z" fill="{fill}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>'
            f'<path d="M{x + s * .2:.1f} {base - s * .3:.1f}l{s * .3:.1f}-{s * .5:.1f}l{s * .3:.1f} {s * .5:.1f}" fill="{W}" stroke="{line}" stroke-width="{sw:.1f}" stroke-linejoin="round"/>'
            f'<path d="M{x - s * .3:.1f} {base + s * .08:.1f}q{s * .2:.1f}-{s * .12:.1f} {s * .4:.1f} 0t{s * .4:.1f} 0t{s * .4:.1f} 0t{s * .4:.1f} 0" fill="none" stroke="{line}" stroke-width="{sw:.1f}" stroke-linecap="round"/>')


def garland(cx, cy, r, line, fill, accent):
    """A marigold garland ring: the success states."""
    beads = []
    for i in range(18):
        import math
        a = math.pi * 2 * i / 18
        beads.append(f'<circle cx="{cx + r * math.cos(a):.1f}" cy="{cy + r * math.sin(a):.1f}" r="{r * .16:.1f}" fill="{accent if i in (0, 9) else fill}" stroke="{line}" stroke-width="{r * .03:.1f}"/>')
    return "".join(beads) + f'<path d="M{cx - r * .35:.1f} {cy}l{r * .25:.1f} {r * .28:.1f}l{r * .5:.1f}-{r * .55:.1f}" fill="none" stroke="{line}" stroke-width="{r * .12:.1f}" stroke-linecap="round" stroke-linejoin="round"/>'


def kantha(x, y, w, line):
    """A kantha-stitch border line."""
    return f'<path d="M{x} {y}h{w}" stroke="{line}" stroke-width="{w * .004:.1f}" stroke-dasharray="{w * .012:.1f} {w * .012:.1f}"/>'


def svg(w, h, body, background=None):
    bg = f'<rect width="{w}" height="{h}" fill="{background}"/>' if background else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{bg}{body}</svg>\n'


def ground(w, h, y, fill, line):
    """The soft ground; only its top edge is outlined so the scene fades out at the sides."""
    top = f"M0 {y}q{w * .25} -{h * .03} {w * .5} 0t{w * .5} 0"
    return (f'<path d="{top}V{h}H0z" fill="{fill}"/>'
            f'<path d="{top}" fill="none" stroke="{line}" stroke-width="{w * .004:.1f}"/>')

if __name__ == "__main__":
    import sys
    sys.path.insert(0, str(pathlib.Path(__file__).parent))
    from scenes import all_scenes
    here = pathlib.Path(__file__).parent
    targets = [ROOT / "Backend" / "database" / "seed" / "artwork", ROOT / "Frontend" / "packages" / "pao_ui" / "assets" / "artwork"]
    for slot, text in all_scenes():
        (here / f"{slot}.svg").write_text(text)
        for target in targets:
            shutil.copy(here / f"{slot}.svg", target / f"{slot}.svg")
    print("wrote", len(list(here.glob("*.svg"))), "illustrations")
