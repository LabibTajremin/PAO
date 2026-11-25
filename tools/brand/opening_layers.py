"""Splits the PAO tile into a plain tile and one layer per letter for the app opening (P27).

The layers share the tile's 1024 viewBox, so stacked they draw the exact splash logo and each
letter can settle on its own. Run: python3 -I tools/brand/opening_layers.py
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "Frontend/packages/pao_ui/assets/brand"
OUT = SRC / "opening"
HEAD = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">'


def layers(mode: str) -> dict[str, str]:
    svg = (SRC / f"logo-tile-{mode}.svg").read_text()
    tile = re.search(r'<path id="tile"[^>]*/>', svg).group(0)
    group = re.search(r'<g id="wordmark"([^>]*)>', svg).group(1)
    out = {f"tile-{mode}.svg": HEAD + tile + "</svg>\n"}
    for letter in "PAO":
        path = re.search(rf'<path id="{letter}"[^>]*/>', svg).group(0)
        out[f"{letter}-{mode}.svg"] = f"{HEAD}<g{group}>{path}</g></svg>\n"
    return out


def main() -> int:
    OUT.mkdir(exist_ok=True)
    for mode in ("light", "dark"):
        for name, text in layers(mode).items():
            (OUT / name).write_text(text)
    print(f"opening layers: {len(list(OUT.glob('*.svg')))} files in {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
