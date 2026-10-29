"""Generates every GreyStore PDF logo/icon file from one design.

Run from the repo root:  python3 packaging/branding/generate.py
Needs Pillow and the Liberation Sans Bold font (fonts-liberation on Debian/Ubuntu).

The frontend keeps the upstream file names (StirlingPDFLogo*.svg, favicon.ico, ...)
because components reference them by name; only their contents are GreyStore's.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FRONTEND = ROOT / "frontend"
BRAND_DIR = FRONTEND / "src/editor/core/assets/brand"
MODERN_LOGO = BRAND_DIR / "modern-logo"
PUBLIC = FRONTEND / "public"
BACKEND_STATIC = ROOT / "app/core/src/main/resources/static"

GREEN = "#1C4E38"  # GreyStoreChile brand dark green
LIME = "#B3D335"  # GreyStoreChile brand lime
PAPER = "#FFFFFF"
FOLD = "#D7E3DC"
FONT_STACK = "Montserrat, 'Segoe UI', Arial, sans-serif"

# Document outline and label band on a 24x24 grid, shared by every vector mark.
DOC_PATH = "M6 2.5H14.5L19 7V21.5H6Z"
FOLD_PATH = "M14.5 2.5V7H19Z"
BAND = dict(x=3.5, y=11.5, width=17, height=5.5, rx=1.3)


def mark_svg_body(doc_fill: str, band_fill: str, fold_fill: str) -> str:
    return (
        f'<path d="{DOC_PATH}" fill="{doc_fill}"/>'
        f'<path d="{FOLD_PATH}" fill="{fold_fill}"/>'
        f'<rect x="{BAND["x"]}" y="{BAND["y"]}" width="{BAND["width"]}" '
        f'height="{BAND["height"]}" rx="{BAND["rx"]}" fill="{band_fill}"/>'
    )


def write(path: Path, content: str | bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(content, bytes):
        path.write_bytes(content)
    else:
        path.write_text(content, encoding="utf-8")
    print("wrote", path.relative_to(ROOT))


def ui_mark_svg() -> str:
    """The <Icon name="stirling-mark"> glyph. BrandMark.css fills the two classes."""
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">\n'
        f'  <path class="sui-brandmark__b" d="{DOC_PATH}" />\n'
        f'  <rect class="sui-brandmark__a" x="{BAND["x"]}" y="{BAND["y"]}" '
        f'width="{BAND["width"]}" height="{BAND["height"]}" rx="{BAND["rx"]}" />\n'
        "</svg>\n"
    )


def standalone_mark_svg() -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">'
        + mark_svg_body(GREEN, LIME, FOLD)
        + "</svg>\n"
    )


def lockup_svg(text_fill: str) -> str:
    """Mark followed by the "GreyStore PDF" wordmark, 200x40."""
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 40" width="200" height="40">'
        '<g transform="translate(0 2) scale(1.5)">'
        + mark_svg_body(GREEN, LIME, FOLD)
        + "</g>"
        f'<text x="42" y="27" font-family="{FONT_STACK}" font-size="20" font-weight="700" '
        f'fill="{text_fill}">GreyStore <tspan fill="{LIME if text_fill != GREEN else GREEN}">PDF</tspan></text>'
        "</svg>\n"
    )


def wordmark_svg(text_fill: str, accent_fill: str) -> str:
    """Text-only wordmark shown next to the mark in the navbar; 116x21 (see Logo.tsx)."""
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 116 21" width="116" height="21" fill="none">'
        f'<text x="0" y="16" font-family="{FONT_STACK}" font-size="15" font-weight="700" '
        f'fill="{text_fill}">GreyStore <tspan fill="{accent_fill}">PDF</tspan></text>'
        "</svg>\n"
    )


def app_icon(size: int) -> Image.Image:
    """Raster app icon: rounded green tile, white page, lime band reading PDF."""
    scale = size / 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    def s(*values: float) -> list[float]:
        return [v * scale for v in values]

    draw.rounded_rectangle(s(16, 16, 496, 496), radius=96 * scale, fill=GREEN)
    x0, y0, x1, y1, fold = 136, 84, 376, 428, 70
    draw.polygon(
        [tuple(s(x0, y0)), tuple(s(x1 - fold, y0)), tuple(s(x1, y0 + fold)), tuple(s(x1, y1)), tuple(s(x0, y1))],
        fill=PAPER,
    )
    draw.polygon([tuple(s(x1 - fold, y0)), tuple(s(x1 - fold, y0 + fold)), tuple(s(x1, y0 + fold))], fill=FOLD)
    draw.rounded_rectangle(s(96, 262, 416, 362), radius=22 * scale, fill=LIME)
    font = ImageFont.truetype(find_font(), max(8, int(84 * scale)))
    left, top, right, bottom = draw.textbbox((0, 0), "PDF", font=font)
    draw.text(
        ((size - (right - left)) / 2 - left, 312 * scale - (bottom - top) / 2 - top),
        "PDF",
        font=font,
        fill=GREEN,
    )
    return img


def find_font() -> str:
    for candidate in Path("/usr/share/fonts").rglob("LiberationSans-Bold.ttf"):
        return str(candidate)
    raise SystemExit("LiberationSans-Bold.ttf not found: install fonts-liberation")


def save_png(path: Path, size: int, canvas: tuple[int, int] | None = None) -> None:
    icon = app_icon(size)
    if canvas:
        tile = Image.new("RGBA", canvas, (0, 0, 0, 0))
        tile.paste(icon, ((canvas[0] - size) // 2, (canvas[1] - size) // 2), icon)
        icon = tile
    path.parent.mkdir(parents=True, exist_ok=True)
    icon.save(path)
    print("wrote", path.relative_to(ROOT))


def save_ico(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    app_icon(512).save(path, sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print("wrote", path.relative_to(ROOT))


def main() -> None:
    write(FRONTEND / "src/editor/core/icons/svg/stirling/stirling-mark.svg", ui_mark_svg())

    write(BRAND_DIR / "branding-logo/wordmark-light.svg", wordmark_svg(GREEN, GREEN))
    write(BRAND_DIR / "branding-logo/wordmark-dark.svg", wordmark_svg(PAPER, LIME))

    for name in ("StirlingPDFLogoNoTextDark.svg", "StirlingPDFLogoNoTextLight.svg", "StirlingProcessorLogoNoText.svg"):
        write(MODERN_LOGO / name, standalone_mark_svg())
    for name in ("StirlingPDFLogoBlackText.svg", "StirlingLogoBlackText.svg", "StirlingProcessorLogoBlackText.svg"):
        write(MODERN_LOGO / name, lockup_svg(GREEN))
    write(MODERN_LOGO / "StirlingPDFLogoGreyText.svg", lockup_svg("#5B6B63"))
    for name in ("StirlingPDFLogoWhiteText.svg", "StirlingLogoWhiteText.svg", "StirlingProcessorLogoWhiteText.svg"):
        write(MODERN_LOGO / name, lockup_svg(PAPER))
    write(MODERN_LOGO / "LoginLightModeHeader.svg", lockup_svg(GREEN))
    write(MODERN_LOGO / "LoginDarkModeHeader.svg", lockup_svg(PAPER))
    write(MODERN_LOGO / "logo-tooltip.svg", standalone_mark_svg())

    save_ico(MODERN_LOGO / "favicon.ico")
    save_png(MODERN_LOGO / "logo192.png", 192)
    save_png(MODERN_LOGO / "logo512.png", 512)

    save_png(PUBLIC / "favicon.png", 64)
    save_png(PUBLIC / "android-chrome-192x192.png", 192)
    save_png(PUBLIC / "android-chrome-512x512.png", 512)
    for name, canvas, size in (
        ("mstile-70x70.png", (70, 70), 56),
        ("mstile-144x144.png", (144, 144), 112),
        ("mstile-150x150.png", (150, 150), 112),
        ("mstile-310x150.png", (310, 150), 112),
        ("mstile-310x310.png", (310, 310), 224),
    ):
        save_png(PUBLIC / name, size, canvas)
    write(
        PUBLIC / "safari-pinned-tab.svg",
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        + mark_svg_body("#000", "#000", "#000")
        + "</svg>\n",
    )

    save_ico(BACKEND_STATIC / "favicon.ico")
    save_png(BACKEND_STATIC / "favicon-16x16.png", 16)
    save_png(BACKEND_STATIC / "favicon-32x32.png", 32)
    save_png(BACKEND_STATIC / "apple-touch-icon.png", 180)
    write(BACKEND_STATIC / "favicon.svg", standalone_mark_svg())
    save_ico(ROOT / "packaging/windows/GreyStorePDF.ico")


if __name__ == "__main__":
    main()
