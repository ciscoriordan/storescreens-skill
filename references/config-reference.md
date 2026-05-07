# storescreens.yml - Full Config Reference

```yaml
# Project - specify one
project: "MyApp.xcodeproj"
# workspace: "MyApp.xcworkspace"

scheme: "MyApp"

devices:
  - simulator: "iPhone 17 Pro Max"   # App Store 6.9"
  - simulator: "iPhone 17 Pro"       # App Store 6.3"
  - simulator: "iPad Pro 13-inch (M5)"
  # macOS: tests run natively, no simulator needed
  # - simulator: "Mac 2560x1600"
  #   platform: macOS
  # Per-device test selection overrides the top-level test_class filter on
  # this one device. Entries are expanded with test_target/test_class defaults:
  #   - "testFoo"          -> test_target/test_class/testFoo
  #   - "Other/testFoo"    -> test_target/Other/testFoo
  #   - "Tgt/Cls/testFoo"  -> passed through verbatim
  # Use when a test only renders meaningfully on one form factor.
  #   - simulator: "iPad Pro 13-inch (M5)"
  #     tests:
  #       - testLandscapePolytonic

# Appearances - light, dark (default: light only)
# - One entry: every slide captures in that appearance, output is flat.
# - Two entries: legacy multiplier - every slide captures in BOTH and
#   the output uses light/ + dark/ subfolders.
# - Per-slide override (see render.slides[name].appearance) wins for
#   that slide and switches the output to a flat layout (no subfolders).
appearances:
  - light
  # - dark

# Locales - runs full capture once per locale (optional)
# locales:
#   - en-US
#   - ja
#   - de-DE

# Custom flags for the HTML preview gallery (optional).
# Keys are Xcode locale codes. Values are either:
#   - A filename (without .svg) from ciscoriordan/svg-flags/circle/languages/
#   - A full https:// URL, used as-is
# Merged with built-in defaults; your values win on collisions.
# locale_flags:
#   en-IN: in-en
#   hi: in-hi
#   custom: https://example.com/my-flag.svg

output_dir: "./storescreens-output"

# Run history: 1 = overwrite (default), 0 = keep all, N = keep last N
# keep_runs: 1

# XCTest mode - which test class to run
test_target: MyAppUITests
test_class: ScreenshotTests

# Filter by screenshot name (optional - capture only these)
# The order here is authoritative for BOTH capture and render. No
# alphabetical reordering happens anywhere in the pipeline. A panoramic
# render background's left edge pins to the first entry; logo placement
# (first_only) uses the first entry here.
# screenshots:
#   - "Home"
#   - "Detail"

# Preflight iPad-safety scan before capture (default: true)
# preflight: true

# Upload to storescreens.app after capture (default: false)
# upload: true

# Render captioned, framed App Store-ready screenshots after capture.
# Auto-runs after `storescreens capture` when render.enabled: true.
# Also runnable standalone via `storescreens render` (no recapture).
# Full schema: references/render-reference.md
# render:
#   enabled: true
#   output_dir: ./storescreens-framed
#   background: { color: "#1a1a2e" }
#   chrome: { style: stroke }
#   caption:
#     title: { font: system, weight: bold, font_size_pct: 5.5, color: "#ffffff" }
#     min_height_pct: 22
#   slides:
#     "Home": { caption: "Your recipes, organized." }
#     # appearance: dark on a slide captures + renders only this slide in
#     # dark, even if the top-level appearances: list is just [light].
#     # Activates flat output layout (no light/ + dark/ subfolders).
#     "DarkOnlySlide": { appearance: dark }

# Upload rendered screenshots + per-locale metadata to App Store Connect
# via `storescreens submit`. Credentials come from env vars (ASC_KEY_ID,
# ASC_ISSUER_ID, ASC_KEY_PATH) or ~/.storescreens/asc-credentials.yml
# (written by `storescreens auth login`). Full schema:
# references/submit-reference.md
# app_store_connect:
#   bundle_id: com.example.app    # or app_id: "1234567890"
#   metadata_dir: ./metadata
#   submit:
#     create_version: "1.2.0"
#     screenshots: true
#     metadata: true
#     submit_for_review: false    # default false; true auto-submits for review (auto-cancels stuck prior submissions)
```

## Device Names & App Store Connect Size Mapping

Use `storescreens list` to see available simulators and their App Store size mappings.

App Store Connect iPhone slots and the simulators that fill them:

| App Store Connect slot | storescreens size | Simulator |
|------------------------|-------------------|-----------|
| 6.9" (primary required) | **6.9"** | `iPhone 17 Pro Max` |
| 6.5" (auto-filled from 6.9") ¹ | **6.5"** | `iPhone 11 Pro Max`, `iPhone Xs Max` ² |
| 6.3" | **6.3"** | `iPhone 17 Pro`, `iPhone 17`, `iPhone Air` |
| 6.1" | **6.1"** | `iPhone 16`, `iPhone 15` |
| 5.5" | **5.5"** | `iPhone 8 Plus` |
| 4.7" | **4.7"** | `iPhone SE (3rd generation)` |

**No 6.7" slot exists in App Store Connect.** Do not use `iPhone 16 Plus`.

**¹ 6.5" is auto-filled** - when 6.9" screenshots are provided, App Store Connect automatically uses them for the 6.5" slot. You only need a dedicated 6.5" simulator if you want distinct screenshots there.

**² 6.5" (1242×2688)** is the iPhone XS Max / 11 Pro Max resolution. No current simulator produces it - only these older simulators do.

iPad slots:

| App Store Connect slot | storescreens size | Simulator |
|------------------------|-------------------|-----------|
| 13" (primary required) | **iPad Pro 13"** | `iPad Pro 13-inch (M5)` |
| 11" | **iPad Pro 11"** | `iPad Pro 11-inch (M5)` |
| 12.9" (iPad Pro 2nd Gen) | **iPad Pro 12.9"** | `iPad Pro 12.9-inch (2nd generation)` ¹ |
| 10.5" | **iPad 10.5"** | `iPad Air (3rd generation)` ¹ |
| 9.7" | **iPad 9.7"** | `iPad (6th generation)` ¹ |

**Recommend `iPad Pro 13-inch (M5)` as the starting point** - it covers the required 13" slot. Add others only if needed.

**¹ Older slots** (12.9", 10.5", 9.7") require older simulator runtimes that may not be installed. Most apps only need 13".

Mac App Store slots:

| Mac App Store slot | storescreens size | Notes |
|--------------------|-------------------|-------|
| 2880x1800 | **Mac 2880x1800** | 15" Retina (MacBook Pro 15") |
| 2560x1600 | **Mac 2560x1600** | 13" Retina (MacBook Pro 13", Air M1+) |
| 1440x900 | **Mac 1440x900** | Non-Retina |
| 1280x800 | **Mac 1280x800** | Minimum required |

macOS devices don't use simulators. Add `platform: macOS` to the device config. XCUITests run natively on the Mac.

Sources:
- [Apple: Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Apple Changed App Store Connect Screenshot Sizes (Sep 2024)](https://www.iwantanelephant.com/blog/2024/09/12/important-update-apple-changed-app-store-connect-screenshot-requirements/)

Common iPad simulators:
- `iPad Pro 13-inch (M5)` → iPad Pro 13"
- `iPad Pro 11-inch (M5)` → iPad Pro 11"

## `storescreens capture` Flags

| Flag | Description |
|------|-------------|
| `--mode xctest\|simple` | Capture mode (default: `xctest`) |
| `--config PATH` | Config file path (default: `storescreens.yml`) |
| `--output DIR` | Override output directory |
| `--locale LOCALE` | Override locales (repeatable) |
| `--retries N` | Retry failed test runs per device |
| `--keep-alive` | Keep simulators running after capture |
| `--skip-check` | Skip preflight source code check |
| `--verbose` | Show full xcodebuild output |
| `--no-render` | Skip the render pass even when `render.enabled: true` |

## Render + Bezel Commands

| Command | Description |
|---------|-------------|
| `storescreens render` | Re-render captioned/framed output from existing captures. No simulator, no xcodebuild. |
| `storescreens bezels import` | Auto-scan mounted Apple Design Resource DMGs; install bezel PNGs + sidecars |
| `storescreens bezels import --volume PATH` | Import from a specific mount path (repeatable) |
| `storescreens bezels import --yes` | Skip confirmation prompt |
| `storescreens bezels check` | List installed bezels |
| `storescreens bezels path` | Print the bezel install directory (`~/Library/Application Support/storescreens/bezels/`) |

See `references/render-reference.md` for the full `render:` schema.

## App Store Connect Upload

The top-level `app_store_connect:` block configures `storescreens submit`, which uploads rendered screenshots and per-locale metadata (description, keywords, what's new, etc.) to App Store Connect via Apple's official API. See `references/submit-reference.md` for the full schema, credential resolution order, metadata file layout, destructive upload semantics, troubleshooting, and a complete example.

```yaml
app_store_connect:
  bundle_id: com.example.app      # or app_id: "1234567890"
  metadata_dir: ./metadata        # default: ./metadata
  submit:
    create_version: "1.2.0"       # required
    screenshots: true
    metadata: true
    submit_for_review: false      # default false; true auto-submits for App Review

  # Optional - all three are app-info / version metadata that lives in
  # App Store Connect outside of the per-locale .txt files. submit reads
  # current values, diffs against the YAML, and only PATCHes when
  # something differs. Full schema in submit-reference.md.

  categories:                       # PATCH /v1/appInfos/{id} relationships
    primary: EDUCATION
    secondary: REFERENCE

  age_rating:                       # PATCH /v1/ageRatingDeclarations/{id}
    cartoon_or_fantasy_violence: NONE
    realistic_violence: NONE
    profanity_or_crude_humor: NONE
    gambling: false
    unrestricted_web_access: false
    kids_age_band: NONE

  review_info:                      # POST/PATCH /v1/appStoreReviewDetails
    first_name: Jane
    last_name: Doe
    phone_number: "+1 555 123 4567"
    email_address: jane@example.com
    notes: |
      Plain-text notes for Apple's reviewers.
```

Related commands: `storescreens auth login`, `storescreens auth status`, `storescreens auth logout`, `storescreens submit [--dry-run] [--skip-screenshots] [--skip-metadata] [--version-override X.Y.Z]`.
