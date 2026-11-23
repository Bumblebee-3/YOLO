"""Build the YOLO Clock family from Inter-Black.otf and Inter-BlackItalic.otf."""
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

source = Path(sys.argv[1])
output = Path(__file__).resolve().parents[1] / "configs/.local/share/fonts/yolo-clock"
output.mkdir(parents=True, exist_ok=True)
for suffix, style in [("", "Regular"), ("Italic", "Italic")]:
    font = TTFont(source / f"Inter-Black{suffix}.otf")
    family = "YOLO Clock"
    full = f"{family} {style}"
    ps = f"YOLOClock-{style}"
    names = {1: family, 2: style, 3: ps + "-" + font["name"].getDebugName(5),
             4: full, 6: ps, 16: family, 17: style}
    for record in font["name"].names:
        if record.nameID in names:
            record.string = names[record.nameID].encode(record.getEncoding())
    cff = font["CFF "].cff
    cff.fontNames[0] = ps
    top = cff.topDictIndex[0]
    top.FamilyName, top.FullName, top.Weight = family, full, "Regular"
    # Black is the normal drawing in this family. Only the style metadata changes.
    font["OS/2"].usWeightClass = 400
    font["OS/2"].fsSelection = (font["OS/2"].fsSelection & ~0x61) | (1 if suffix else 64)
    font["head"].macStyle = (font["head"].macStyle & ~3) | (2 if suffix else 0)
    font.save(output / f"{ps}.otf")
