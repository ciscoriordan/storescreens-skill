# storescreens render - Full Config Reference

The `render:` block in `storescreens.yml` drives a compositing pipeline that turns raw simulator captures into framed, captioned images ready to upload to App Store Connect. Rendering runs automatically after `storescreens capture` when `render.enabled: true`, and can be re-run on its own with `storescreens render` (no recapture).

## Top-level shape

```yaml
render:
  enabled: true
  output_dir: ./storescreens-framed   # optional; default ./storescreens-framed
  template: sahara                    # optional; see "Templates" below

  background: { ... }
  scrim:      { ... }
  images:     [ ... ]                 # 0-2 entries, replaces legacy `logo:`
  laurels:    [ ... ]                 # 0-2 entries, award-badge overlays
  logo:       { ... }                 # deprecated; see `images:` below
  caption:    { ... }
  chrome:     { ... }

  slides:
    "Home":   { ... }   # per-slide overrides keyed by screenshot name
    "Detail": { ... }
```

Every sub-block (background, scrim, images, laurels, logo, caption, chrome) may also appear inside a per-slide entry under `slides:` and will override the top-level value for just that slide. `images:` and `laurels:` are arrays, so a slide-level value replaces the top-level array wholesale (no element-by-element merge).

Slide resolution order (narrow wins): `slides."Home".caption.title.color` overrides `caption.title.color`. When a `template:` is set, its values act as the outermost defaults — user-supplied fields in the top-level `render:` still win.

## Templates

`template:` is an optional preset name that seeds `background`, `caption`, and `chrome` with a curated color + typography + background-pattern bundle. Any explicit field in the same `render:` block overrides the template's value for that field (field-level merge, not block-level replace).

Built-in templates (list live with `storescreens templates` or `storescreens templates --json`):

| id | look | best for |
|---|---|---|
| `ascent` | Cream paper with topographic contours | Outdoor, fitness, health |
| `all_the_wiser` | Warm cream with scattered playful shapes | Education, kids, language |
| `ethereal` | Warm taupe gradient, soft serif | Wellness, meditation, lifestyle |
| `sahara` | Sand-to-terracotta gradient with dune layers | Travel, adventure |
| `midnight` | Deep charcoal with champagne accent text | Premium, entertainment, nightlife |
| `pinecrest` | Forest moss gradient with cream type | Games, health, lifestyle |
| `blueprint` | Pale drafting paper with a grid | Developer tools, productivity |
| `sunset_blvd` | Four-stop sunset gradient with display type | Entertainment, lifestyle, social |
| `jazz_and_wine` | Deep bordeaux with elegant cream serif | Food, drink, hospitality, creative |

Lookup is case-insensitive and ignores dashes/underscores (`sunset_blvd`, `sunsetblvd`, `Sunset Blvd` all resolve to the same template). Unknown names log a warning and the render runs without template defaults.

CLI override:

```bash
storescreens render --template sahara    # overrides any `template:` in the YAML
```

Patterns can also be used directly without a template by setting `background.pattern`:

```yaml
background:
  color: "#F4EFE7"
  pattern:
    pattern: topographic     # topographic | blueprint_grid | dune_layers | soft_waves | gamified_shapes
    color: "#1A1F2E"         # accent / line color, default "#000000"
    opacity: 0.15            # 0..1, default 0.25
```

Patterns draw on top of the solid/gradient color fill and under any user-supplied image. In multi-slide panoramas the pattern spans the full combo width and each slide renders its horizontal slice — adjacent slides line up seamlessly in the App Store Connect gallery.

## Appearance variants

Any field whose value varies per light/dark can take the shape:

```yaml
image:
  light: ./bg-light.png
  dark:  ./bg-dark.png
```

or a single scalar that's used for both:

```yaml
image: ./bg.png
```

Applies to: `background.image`, `background.color`, `images[].path`, `laurels[].color`, `logo.path`.

## background

```yaml
background:
  image: ./bg.png            # single path, or { light:, dark: } variant
  color: "#1a1a2e"           # single hex, or array for vertical gradient
  # color: ["#1a1a2e", "#4a1e5c"]        # top → bottom
  # color: { light: "#fff", dark: "#000" }
  align: center              # top | center | bottom  (how image is pinned)
  fit:   cover               # cover | contain | tile
```

### Panoramic background (single wide image spanning all slides)

When `background.image` is a single image wider than a single slide, it is sliced across **all slides in the `screenshots:` list order** so the rendered screenshots concatenate side-by-side in the App Store Connect gallery.

- The left edge of the source image always pins to the left edge of the **first** slide in the list.
- Each subsequent slide gets the next horizontal slice.
- Leftover image to the right is discarded (slides always win over background).
- If the source is narrower than one slide, it tiles (or is centered, depending on `fit`).

Use this to get a continuous marketing band across your whole App Store hero row.

## scrim

A semi-transparent layer over the background, under the screenshot and caption. Used to darken a busy photo background so captions read.

```yaml
scrim:
  color: "#000000"
  opacity: 0.35            # 0.0 - 1.0; applied as a flat layer

  # OR a vertical gradient (top → bottom) on the scrim color:
  gradient:
    top_opacity: 0.0
    bottom_opacity: 0.6
```

If `gradient` is set, it overrides `opacity`.

## images

Up to two image overlays per slide, dropped into one of three caption-relative slots. Replaces the legacy `logo:` block for new configs.

```yaml
images:
  - path: ./assets/logo.svg          # or { light:, dark: } variant
    position: above_title            # above_title | below_title | above_subtitle | below_subtitle
    align: center                    # left | center (default) | right
    max_height_pct: 8                # % of canvas height; default 8
    placement: first_only            # first_only | all | none
    nudge:                           # optional fine-tune offset
      x_pct: 0                       # positive = right, negative = left
      y_pct: 0                       # positive = up, negative = down
```

### Fields

| Field | Default | Notes |
|---|---|---|
| `path` | required | File path (relative to config dir, absolute, or `~/`). PNG or SVG. Accepts `{ light:, dark: }` variant. |
| `position` | `above_title` | Slot for the overlay. `below_title` and `above_subtitle` are aliases for the same physical slot (the band between title and subtitle). When the slide has no subtitle, `above_subtitle` and `below_subtitle` collapse to "directly under the title". |
| `align` | `center` | Horizontal alignment within the slot. |
| `max_height_pct` | `8` | Image height as a percentage of canvas height. Width follows the source aspect. |
| `placement` | `first_only` for `above_title`, `all` otherwise | Per-slide visibility. `first_only` draws on slide 1 only; `all` on every slide; `none` disables. |
| `nudge.x_pct` / `nudge.y_pct` | `0` | Canvas-percentage offset applied after slot placement. Positive x = right; positive y = up. |

### Above_title slot is anchored to the caption block

When a caption is present, the `above_title` slot extends from the canvas top down to just above the caption block (separated by `caption.spacing_pct`). The image is centered in this slot, which gives roughly equal "canvas top -> image" and "image -> caption" gaps automatically. When `caption.nudge` or `caption.vertical_align` shifts the caption, the slot follows so image + caption read as a single visual unit.

When there is no caption text, the slot collapses to the legacy canvas-top band sized to the image, so middle-slot-only configs keep their old layout.

This is a behaviour change in 2.8.0. Pre-2.8 configs that used `images[].nudge.y_pct` to manually pull the logo down toward the caption can drop the nudge; the default already balances the gaps. To restore the old "logo glued to canvas top" look, set a positive `nudge.y_pct` to push the image back up.

### Stacking and distribution

Up to 2 entries may share a slot. The renderer caps at 2 (extras are dropped with a warning).

- 1 item: respects its `align` (or center by default), centered vertically in the slot, then any `nudge` is applied.
- 2 items: auto-distribute with equal whitespace. The gaps from canvas-left to item₁, between item₁ and item₂, and from item₂ to canvas-right are all equal: `gap = (canvas_width - sum_of_item_widths) / 3`. With identically-sized items their centers land symmetrically; with different-sized items the larger one's center sits closer to its outer edge (still equal-gap layout). Items never overlap as long as they fit on the canvas. The `align` field controls each item's own internal text alignment (e.g. laurel title alignment) but does not affect anchoring in the slot. Use `nudge.x_pct` to fine-tune.
- 2 items wider than the canvas: items are clamped to abut at the midline (still no overlap of each other) and a warning is emitted. Lower `max_height_pct` to fit.

Stacking order follows config order (images before laurels when they share a slot).

## laurels

Laurel "award badge" overlays - left and right laurel SVGs flanking centered title/subtitle text, tinted to a single color. The laurel SVGs ship with the renderer; you supply the text, the color, and the slot.

```yaml
laurels:
  - title: "Editors' Choice"
    subtitle: "App Store"
    color: "#FFD66B"                 # single hex, or { light:, dark: } variant
    position: below_subtitle         # default; same slots as images
    align: center                    # left | center (default) | right
    max_height_pct: 10               # % of canvas height; default 10
    placement: all                   # default; first_only | all | none
    nudge:
      x_pct: 0
      y_pct: 0
    inset_pct: 4                     # default; positive = laurels closer, may overlap text
    title_style:                     # optional; same fields as caption.title
      font: system
      weight: bold
      italic: false
      font_size_pct: null            # auto-derived from max_height_pct when null
      color: "#FFD66B"
    subtitle_style:                  # optional; same fields as caption.subtitle
      weight: regular
      italic: true
```

### Fields

| Field | Default | Notes |
|---|---|---|
| `title` | optional | Top text between the laurels. Bold by default. Accepts a string or array of strings (strict line breaks); markdown supported. |
| `subtitle` | optional | Bottom text between the laurels. Regular by default. Same shapes as `title`. |
| `title_style` | inherits from `color` and bold default | Same fields as `caption.title` (font, weight, italic, font_size_pct, color, align). When `font_size_pct` is omitted, both title and subtitle share a single auto-derived size of about 27 percent of the laurel block height, so the two lines read as balanced typography rather than headline + footnote. The bold default still gives the title visual hierarchy. |
| `subtitle_style` | inherits from `color` and regular default | Same fields as `caption.subtitle`. When `font_size_pct` is omitted, the subtitle defaults to the same auto-derived size as `title_style`. Setting `font_size_pct` on either side breaks the link and uses the explicit value. |
| `color` | `#FFFFFF` | Laurel tint, applied as an alpha-mask fill. Single hex or `{ light:, dark: }`. Also supplies the default text color when `title_style.color` / `subtitle_style.color` are unset. |
| `position` | `below_subtitle` | Same slot values as `images`. |
| `align` | `center` | Horizontal alignment of the whole laurel block within its slot. |
| `max_height_pct` | `10` | Block height (laurel + text) as a percentage of canvas height. |
| `placement` | `all` | Per-slide visibility. Laurels usually want to repeat; default differs from images. |
| `nudge.x_pct` / `nudge.y_pct` | `0` | Same semantics as `images[].nudge`. Shifts the entire laurel + text block. |
| `inset_pct` | `4` | Percent of laurel block height. Positive shifts the left laurel right and the right laurel left, tightening the badge. Negative pushes them outward. The text region stays put, so the laurel branches can encroach on text edges; usually safe given the laurel's open bow shape. |

Up to 2 laurels per slide. Slot distribution follows the same rules as `images`: a single laurel respects its `align`, two laurels in the same slot auto-distribute with equal whitespace.

## tables

A 2D grid of text cells with optional borders. Same overlay slot semantics as `images` and `laurels` — up to two per slide, auto-distributed with equal whitespace when paired.

```yaml
tables:
  - rows:
      - ["5,064",     "Verbs"]
      - ["2x more",   "than competitors"]
    text_color: "#FFFFFF"
    border_color: "#FFD66B"
    cell_style:
      font: system
      weight: bold
      align: center
    column_aligns: [left, right]     # optional; per-column horizontal align
    border:
      enabled: true                  # default
      width_pct: 0.15                # default; % of canvas height
      sides: [outer, inner]          # default; or [outer], [inner], or per-side: [top, bottom, left, right]
    cell_padding_pct: 1              # default; % of canvas height
    position: below_subtitle
    align: center
    max_height_pct: 14
    placement: all
    nudge: { x_pct: 0, y_pct: 0 }
```

Use `columns:` instead of `rows:` to supply column-major content; the renderer transposes internally. Rows of unequal length are padded with empty cells at the end so the grid is always rectangular.

Cell content can include `\n` for in-cell line breaks; the row containing the multi-line cell auto-grows to fit. With auto font sizing, this comes out of the table's overall `max_height_pct` budget — a row with 2-line cells is twice the height of a 1-line row, so other rows shrink proportionally.

### Fields

| Field | Default | Notes |
|---|---|---|
| `rows` | required if `columns` is unset | Row-major content. Each row is an array of cell strings. Markdown is supported per cell. |
| `columns` | optional | Column-major alternative to `rows`. Used only when `rows` is nil. |
| `text_color` | `#FFFFFF` | Cell text color. Hex string or `{ light:, dark: }`. |
| `border_color` | `#FFFFFF` | Border color. Independent from `text_color`. |
| `cell_style` | bold + `text_color` + center align | Same fields as `caption.title`. When `font_size_pct` is omitted, the renderer auto-derives one size that fits inside `max_height_pct` divided across the total number of text lines (so a row containing a 2-line cell takes twice the height of a 1-line row). |
| `column_aligns` | inherits from `cell_style.align` | Per-column horizontal alignment override. e.g. `[left, right]` for a 2-column table left-aligns column 0 and right-aligns column 1. Cells without an entry inherit `cell_style.align` (default center). |
| `column_valigns` | inherits from `cell_style.vertical_align` | Per-column vertical alignment override. `top` / `center` (default) / `bottom`. Useful when one row auto-grows for a multi-line cell and you want its single-line neighbors to top-align with that cell's first line: `column_valigns: [top, top]`. |
| `cell_style.vertical_align` | `center` | Default vertical alignment for cells; `column_valigns[c]` overrides per-column. |
| `border.enabled` | `true` | Set `false` to draw text-only with no lines. |
| `border.width_pct` | `0.15` | Percent of canvas height. |
| `border.sides` | `[outer, inner]` | List of which lines to draw. `outer` expands to the four outer edges; `inner` to grid lines between cells. Per-side names (`top`, `bottom`, `left`, `right`) override slices of `outer`. |
| `cell_padding_pct` | `1` | Interior padding around each cell, percent of canvas height. |
| `position` | `below_subtitle` | Same slot values as `images` / `laurels`. |
| `align` | `center` | Horizontal alignment of the whole table within its slot. |
| `max_height_pct` | `14` | Block height of the table, percent of canvas height. Width is content-driven (sum of column widths + borders). |
| `placement` | `all` | Per-slide visibility. Same semantics as `images` / `laurels`. |
| `nudge.x_pct` / `nudge.y_pct` | `0` | Same semantics as elsewhere. |

Up to 2 tables per slide. Slot distribution follows the same rules as `images` and `laurels`.

## logo

> Deprecated: use `images:` for new configs. The `logo:` block is kept for backwards compatibility and is treated as a single image at `above_title` when `images:` is absent. Setting `images: []` (an explicitly empty array) suppresses the legacy fallback.

A wordmark / logo drawn above the screenshot area.

```yaml
logo:
  path: ./assets/logo.svg          # or { light:, dark: } variant
  placement: first_only            # first_only | all | none
  max_height_pct: 6                # % of canvas height
  top_padding_pct: 3               # % of canvas height
  nudge:                           # optional fine-tune offset
    x_pct: 0                       # positive = right, negative = left
    y_pct: 0                       # positive = up, negative = down
```

- `first_only` (default-ish): logo only on the first slide in `screenshots:` order.
- `all`: logo on every slide.
- `none`: no logo (use to disable at slide level).

SVG and PNG both work. Variant-aware so dark-mode can use a different file.

`nudge.x_pct` and `nudge.y_pct` are canvas-percentage offsets applied on top of the default center-top placement, the same scale as everything else in the render config, so a nudge stays the same relative position across device sizes.

## caption

Captions are composed of two optional roles: `title` and `subtitle`. Each role has the same style knobs.

```yaml
caption:
  title:
    font: system              # see "Fonts" below
    weight: bold              # thin|light|regular|medium|semibold|bold|heavy
    italic: false
    font_size_pct: 5.5        # % of canvas width
    min_font_size_pct: 3.0    # auto-shrinks to fit this minimum before wrapping
    color: "#ffffff"
    align: center             # left | center | right

  subtitle:
    font: system
    weight: regular
    font_size_pct: 3.2
    min_font_size_pct: 2.0
    color: "#ffffff"
    align: center

  spacing_pct: 1.0            # vertical gap between title and subtitle (% of canvas height)
  min_height_pct: 22          # reserves at least this much vertical space above the screenshot
  padding_pct: 5              # horizontal (left+right) inset for the whole caption block

  vertical_align: center      # top | center (default) | bottom — where the block sits in its band
  nudge:                      # fine-tune offset applied after vertical_align
    x_pct: 0                  # positive = right, negative = left
    y_pct: 0                  # positive = up, negative = down
```

`vertical_align` defaults to `center` whether the field is present or absent: same value, same render. If a centered caption looks shifted toward the device anyway, that's the `chrome.padding_pct` inset (default 4%) sitting between the band's bottom and the visible bezel; centering is computed against the visible bezel top, but the inset still adds a small offset to the *apparent* gap below the caption. Lower `chrome.padding_pct` to tighten.

`padding_pct` is a horizontal inset only (left + right). There is no vertical analogue; use `min_height_pct` to enlarge the band, `vertical_align` to choose where the block sits inside it, and `nudge.y_pct` for fine-tuned offset.

`min_font_size_pct` matters because captions auto-shrink to fit. The renderer steps the point size down between `font_size_pct` and `min_font_size_pct` until the lines fit `min_height_pct`. If you set `font_size_pct == min_font_size_pct` to lock a uniform size across slides, three things happen at the floor:

- Wrapped lines fit vertically inside `min_height_pct`: rendered normally, no warning.
- Wrapped lines exceed `min_height_pct`: the caption band grows to the natural height and the device chrome shifts down to make room. A warning surfaces telling you to raise `min_height_pct` or shorten the text if you want a uniform device anchor across slides. (When `chrome.device_height_pct` is set the band is canonical and stays clamped: the warning fires but the layout is preserved.)
- A single strict-array line (or a word) is wider than `blockWidth = canvas - 2 * padding_pct`: the line renders with horizontal overflow, centered in the canvas, with a warning. Pre-2.8 this collapsed the whole caption to a single ellipsized line.

`align`, `vertical_align`, and `nudge` are independent:

- `title.align` / `subtitle.align` — each role's horizontal alignment (left / center / right). Per-role so title and subtitle can align differently.
- `vertical_align` — where the caption block sits inside its reserved band (`min_height_pct`). Block-level; title and subtitle move together.
- `nudge.x_pct` / `nudge.y_pct` — fine-grained offset applied on top of the computed position. Also block-level. Useful for matching a specific mockup or nudging away from a notch/island.

## Fonts

`font:` takes four shapes. The renderer disambiguates a bare string by looking at prefixes/suffixes.

```yaml
# 1. System font (SF Pro)
font: system

# 2. Installed font family (any font installed on the Mac running `storescreens render`)
font: "Helvetica Neue"

# 3. Local file path (relative, absolute, or ~-expanded)
font: "./assets/Inter-Bold.otf"

# 4. Bundle - required for correct markdown bold / italic across four faces:
font:
  regular:     "./assets/Inter-Regular.otf"
  bold:        "./assets/Inter-Bold.otf"
  italic:      "./assets/Inter-Italic.otf"
  bold_italic: "./assets/Inter-BoldItalic.otf"

# 5. Google Fonts (auto-downloaded, cached in ~/Library/Caches/storescreens/fonts/)
font:
  google:  "Inter"
  version: "3.19"   # optional version pin
```

Disambiguation rules for bare strings:
1. `"system"` literal.
2. Starts with `./`, `../`, `/`, or `~` -> treated as a file path.
3. Ends with `.otf`, `.ttf`, `.otc`, `.ttc` -> treated as a file path.
4. Anything else -> treated as an installed family name.

Use the `bundle` form when you want `**bold**` or `*italic*` markdown inside captions to render with the right face rather than letting Core Text synthesize them.

## Markdown in captions

Basic inline markdown works in both `title:` and `subtitle:` strings (and inside array items):

```yaml
title: "Your **recipes**, in *seconds*."
```

Supported:

| Syntax | Effect |
|--------|--------|
| `**bold**` | bold weight |
| `*italic*` | italic face |
| `` `code` `` | monospace (code) |
| `[text](url)` | link (underline + color; url not clickable in an image) |

For correct bold/italic rendering, prefer a `bundle`-form font with all four faces.

### Gotchas

`**bold**` and `*italic*` step the text up to the next-heavier face. The base style needs headroom or the markup is silently a no-op:

- `weight: bold` already at the font's heaviest face: `**X**` strips the markers and renders identically. There's no heavier weight to step up to.
- `italic: true` set as the base: `*X*` likewise has nowhere to go.
- The system font has bold / heavy / black faces. Most Google Fonts ship with a known set of weights; if you use a non-bundle Google Fonts entry, only the regular and bold variants are auto-fetched, so `weight: bold` makes `**X**` a no-op. Switch to a `bundle`-form font with explicit `bold_url` + `regular_url` (and `heavy_url` if you want even more headroom) to get the markdown to do something.

Quick rule: pick the lightest base weight that still reads, and let `**markdown**` carry the emphasis.

## Highlights (per-slide)

Literal substring overrides for a caption. Applied after markdown parsing. Case-sensitive. Applies to **all occurrences** in both title and subtitle.

```yaml
slides:
  "Detail":
    caption:
      title: "Every detail, at a glance."
      highlights:
        - { match: "detail", color: "#feb909", weight: heavy, italic: true }
        - { match: "glance", color: "#ffa500" }
```

Each highlight can set any combination of `color`, `weight`, `italic`. Fields left out leave the role's default intact.

Use this when a single word needs to pop in a brand color without reworking the whole role style.

## Slide caption shorthand

The `caption:` field under a slide supports three input shapes:

```yaml
# 1. bare string - title only, auto-wraps at canvas width
"Home":
  caption: "Your recipes, organized."

# 2. array of strings - title with STRICT line breaks (items never wrap inside themselves)
"Search":
  caption:
    - "Resident or non-resident."
    - "Standard or enhanced."

# 3. full object - title + subtitle + highlights + per-slide style overrides
"Detail":
  caption:
    title:
      - "Every **detail**,"
      - "at a glance."
    subtitle: "Powered by AI"
    highlights:
      - { match: detail, color: "#feb909", weight: heavy }
    title_style:          # optional: override just this slide's title style
      color: "#feb909"
```

Array form is the cleanest way to enforce a specific line break without counting characters.

## chrome

Device chrome around the screenshot.

```yaml
chrome:
  style: bezel                  # none | stroke | bezel
  fit: width                    # width (default) | height | contain
  stroke_color: "#ffffff"       # for style: stroke only
  stroke_width: 3               # px, for style: stroke
  corner_radius: auto           # 'auto' (device-derived) or a fixed number in px
  shadow: true
  padding_pct: 4                # inset from canvas edges (% of canvas width)

  # bezel-only: preferences applied at `bezels import` time, not render time
  model_preference: ["Pro Max", "Pro", "Air"]
  colorway_preference: ["Space Black", "Silver"]
```

### Chrome styles

- **none** - screenshot drawn at the padded rect, no device frame.
- **stroke** - rounded-rect clip with a device-derived corner radius, optional colored border, optional drop shadow. No asset download needed. Good default if you don't want to mess with bezels.
- **bezel** - screenshot composited inside a real Apple device bezel (PSD sourced from Apple Design Resources). Requires bezel install (see below).

### Chrome fit

Controls how the device + screenshot scale inside the padded canvas area.

- **width** (default): content fills the available width; a tall portrait device may extend past the bottom of the canvas (classic App Store marketing crop).
- **height**: content fits fully vertically; the device ends up narrower on canvas.
- **contain**: fits both dimensions inside the padded rect. No bleed.

### corner_radius

- `auto` -> uses the device's actual screen corner radius (looked up by screenshot pixel dimensions).
- A number -> fixed px radius regardless of device.

## Bezel install (required for `chrome.style: bezel`)

Bezel art is sourced from Apple Design Resources. Apple licenses the art for use with Apple products; StoreScreens does not redistribute it.

### One-time install

1. Download the relevant DMGs from <https://developer.apple.com/design/resources/> under "Product Bezels" (iPhone, iPad, MacBook).
2. Double-click each DMG to mount it under `/Volumes/`.
3. Run:

```bash
storescreens bezels import
```

This scans all mounted Apple Design Resource DMGs, parses each PSD, reads the Screen layer's pixel dimensions, applies `model_preference` + `colorway_preference` (falling back to `Space Black` -> `Silver`/`Natural Titanium` defaults), and exports transparent-screen PNGs plus JSON sidecars into:

```
~/Library/Application Support/storescreens/bezels/
```

Flags:

| Flag | Description |
|------|-------------|
| `--volume PATH` | Use a specific mount path instead of auto-scanning `/Volumes/`. Repeatable. |
| `--yes` | Skip the confirmation prompt before writing assets. |
| `--verbose` | Show every PSD considered and why it was or wasn't picked. |

### Inspect

```bash
storescreens bezels check     # list installed bezels and their canonical keys
storescreens bezels path      # print the install directory
```

### Override per project

Drop bezel PNGs + JSON sidecars into `./bezels/` next to `storescreens.yml`. Project-local bezels take precedence over the user-global set.

## Manifest ordering

The top-level `screenshots:` list is the authoritative order for both capture and render. The render pipeline walks `screenshots:` in the order you wrote it - no alphabetical reordering happens anywhere in the pipeline. This matters for:

- Panoramic backgrounds (first slide pins to left edge of image).
- `images[].placement: first_only` (first entry in the list); also the legacy `logo.placement: first_only`.
- The rendered output filename ordering.

If you omit `screenshots:`, the renderer falls back to the names emitted by the test file.

## Auto-run after capture

When `render.enabled: true`, rendering runs automatically after a successful `storescreens capture`. To skip the render pass on a single run:

```bash
storescreens capture --no-render
```

## Standalone render

To iterate on captions, fonts, or colors without recapturing:

```bash
storescreens render
```

Reads from the latest capture's output (`output_dir/`) and writes the rendered frames to `render.output_dir` (default `./storescreens-framed/`). No simulator boots, no xcodebuild - typically sub-second per slide.

## Output layout

```
storescreens-framed/
├── preview.html
├── light/
│   ├── iPhone_6.9_Home.png
│   ├── iPhone_6.9_Detail.png
│   └── ...
└── dark/
    └── ...
```

Filenames mirror the capture output. You upload these directly to App Store Connect.

## Commands cheat sheet

| Command | Purpose |
|---------|---------|
| `storescreens capture` | Capture + auto-render (if `render.enabled`) |
| `storescreens capture --no-render` | Capture only, skip render pass |
| `storescreens render` | Re-render from existing captures (no recapture) |
| `storescreens bezels import` | Import bezels from mounted DMGs |
| `storescreens bezels import --volume /Volumes/iPhoneBezels` | Import from a specific volume |
| `storescreens bezels import --yes` | Skip confirmation prompt |
| `storescreens bezels check` | List installed bezels |
| `storescreens bezels path` | Print bezel install directory |

## Complete example

A recipes app, 6.9" + iPad Pro 13", with panoramic background, wordmark image on first slide, markdown captions with per-slide highlights, bezel chrome, bundled Inter font for proper bold/italic:

```yaml
project: Recipes.xcodeproj
scheme: Recipes

devices:
  - simulator: "iPhone 17 Pro Max"
  - simulator: "iPad Pro 13-inch (M5)"

appearances:
  - light

output_dir: storescreens-output
test_target: RecipesUITests
test_class: ScreenshotTests
derived_data_path: ~/.storescreens-cache/Recipes

screenshots:
  - Home
  - Search
  - Detail
  - MealPlan
  - 05_Shopping

render:
  enabled: true
  output_dir: storescreens-framed

  background:
    image: ./marketing/panorama.jpg    # sliced across all 5 slides
    fit: cover
    align: center

  scrim:
    color: "#000000"
    gradient:
      top_opacity: 0.0
      bottom_opacity: 0.45

  images:
    - path: ./marketing/logo-wordmark.svg
      position: above_title
      align: center
      max_height_pct: 6
      placement: first_only

  caption:
    title:
      font:
        regular:     ./marketing/Inter-Regular.otf
        bold:        ./marketing/Inter-Bold.otf
        italic:      ./marketing/Inter-Italic.otf
        bold_italic: ./marketing/Inter-BoldItalic.otf
      weight: bold
      font_size_pct: 4.4
      min_font_size_pct: 2.5
      color: "#ffffff"
      align: center
    subtitle:
      font: system
      weight: regular
      font_size_pct: 3.0
      min_font_size_pct: 2.0
      color: "#e0e0e0"
      align: center
    spacing_pct: 1.0
    min_height_pct: 22
    padding_pct: 5

  chrome:
    style: bezel
    fit: width
    shadow: true
    padding_pct: 4
    model_preference: ["Pro Max", "Pro"]
    colorway_preference: ["Space Black", "Natural Titanium"]

  slides:
    "Home":
      caption:
        title: "Every recipe, **organized**."
        subtitle: "Save, tag, and find in seconds."
    "Search":
      caption:
        - "Find anything"
        - "in *seconds*."
    "Detail":
      caption:
        title: "Every **detail**, at a glance."
        subtitle: "Ingredients, steps, timers."
        highlights:
          - { match: "detail", color: "#feb909", weight: heavy }
    "MealPlan":
      caption:
        title: "Plan your week in **one tap**."
    "05_Shopping":
      caption:
        title: "Your shopping list, **auto-built**."
        subtitle: "Grouped by aisle."
```

Iteration loop:

```bash
# First time only
storescreens bezels import

# Initial capture (auto-renders when render.enabled: true)
storescreens capture

# Tweak captions / colors / fonts in storescreens.yml, then:
storescreens render

# Open the framed set
open storescreens-framed/preview.html
```
