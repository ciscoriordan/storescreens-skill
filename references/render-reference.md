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
  logo:       { ... }
  caption:    { ... }
  chrome:     { ... }

  slides:
    "Home":   { ... }   # per-slide overrides keyed by screenshot name
    "Detail": { ... }
```

Every sub-block (background, scrim, logo, caption, chrome) may also appear inside a per-slide entry under `slides:` and will override the top-level value for just that slide.

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

Applies to: `background.image`, `background.color`, `logo.path`.

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

## logo

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

`nudge.x_pct` and `nudge.y_pct` are canvas-percentage offsets applied on top of the default center-top placement — the same scale as everything else in the render config, so a nudge stays the same relative position across device sizes.

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
  padding_pct: 5              # horizontal inset for the whole caption block

  vertical_align: center      # top | center (default) | bottom — where the block sits in its band
  nudge:                      # fine-tune offset applied after vertical_align
    x_pct: 0                  # positive = right, negative = left
    y_pct: 0                  # positive = up, negative = down
```

`min_font_size_pct` matters because captions auto-shrink to fit - if the title is long, the renderer steps the point size down until it either fits on one line or hits this floor (then wraps).

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
- `logo.placement: first_only` (first entry in the list).
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

A recipes app, 6.9" + iPad Pro 13", with panoramic background, logo on first slide, markdown captions with per-slide highlights, bezel chrome, bundled Inter font for proper bold/italic:

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

  logo:
    path: ./marketing/logo-wordmark.svg
    placement: first_only
    max_height_pct: 6
    top_padding_pct: 3

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
