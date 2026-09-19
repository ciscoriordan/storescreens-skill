# storescreens.yml - Full Config Reference

```yaml
# Project - specify one
project: "MyApp.xcodeproj"
# workspace: "MyApp.xcworkspace"

scheme: "MyApp"

devices:
  - simulator: "iPhone 18 Pro Max"   # App Store 6.9" (iOS 26 runtimes: "iPhone 17 Pro Max")
  - simulator: "iPhone 18 Pro"       # App Store 6.3" (iOS 26 runtimes: "iPhone 17 Pro")
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

Which simulator names you have depends on the installed simulator runtimes, not on the Xcode version. iOS 27 runtimes (Xcode 27 or later) create `iPhone 18 Pro Max` (6.9") and `iPhone 18 Pro` (6.3"). iOS 26 runtimes create `iPhone 17 Pro Max` and `iPhone 17 Pro`, which still work from Xcode 27 when an iOS 26 runtime is installed. The screens are identical, so the pairs are interchangeable. `iPhone Air`, `iPhone 17`, and `iPhone 17e` exist on both runtimes. Run `storescreens list` to see the names you have. `storescreens init` picks the newest 6.9"-class iPhone installed and never the iPhone Duo.

`submit` picks each screenshot's App Store Connect slot (display type) from the PNG's pixel size. App Store Connect iPhone slots and the simulators that fill them:

| App Store Connect slot | Display type | Accepted sizes (px) | Simulator |
|------------------------|--------------|---------------------|-----------|
| 6.9" (primary required) | `APP_IPHONE_67` | 1320x2868, 1290x2796, 1260x2736 | `iPhone 18 Pro Max` (iOS 27 runtimes) or `iPhone 17 Pro Max` (iOS 26 runtimes) |
| 6.5" (auto-filled from 6.9") ¹ | `APP_IPHONE_65` | 1284x2778, 1242x2688 | `iPhone 11 Pro Max`, `iPhone Xs Max` ² |
| 6.3" | `APP_IPHONE_61` | 1206x2622, 1179x2556 | `iPhone 18 Pro` (iOS 27 runtimes) or `iPhone 17 Pro` (iOS 26 runtimes); `iPhone 17` |
| 6.1" | `APP_IPHONE_58` | 1170x2532, 1125x2436, 1080x2340 | `iPhone 17e` |
| 5.5" | `APP_IPHONE_55` | 1242x2208 | `iPhone 8 Plus` |
| 4.7" | `APP_IPHONE_47` | 750x1334 | `iPhone SE (3rd generation)` |

**No 6.7" slot exists in App Store Connect.** `APP_IPHONE_67` is the 6.9" slot; `iPhone 16 Plus` (1290x2796) and `iPhone Air` (1260x2736) screenshots upload there too, so neither adds a size next to a Pro Max. Two devices in one slot means `submit` uploads only one device's screenshots for it (with a notice): the one with the largest screen in the slot, with config order breaking ties between equal screens (iPhone 17 Pro and iPhone 18 Pro). The same device fills that slot in every locale; in a locale where it has more than 10 screenshots (light and dark of one device share a set), the next device is used and the over-limit device is reported as an error, which skips submit-for-review. See `submit-reference.md`.

**¹ 6.5" is auto-filled** - when 6.9" screenshots are provided, App Store Connect automatically uses them for the 6.5" slot. You only need a dedicated 6.5" simulator if you want distinct screenshots there.

**² 6.5" sizes** (1242×2688 for iPhone Xs Max / 11 Pro Max, 1284×2778 for iPhone 12/13 Pro Max / 14 Plus) come only from older simulators.

**File labels vs slots.** storescreens names output files by its own size labels (the App Store Size column of `storescreens list`), which don't always match the slot: iPhone Air (1260x2736) files are labeled `iPhone 6.3"` but upload to 6.9"; 1290x2796 is labeled `iPhone 6.7"` (uploads to 6.9"), 1284x2778 `iPhone 6.7"` (6.5"), 1179x2556 `iPhone 6.1"` (6.3"), 1125x2436 `iPhone 5.8"` and 1080x2340 `iPhone 5.4"` (6.1"). In a UI-test capture, devices with the same label write the same file names and one overwrites the other (capture warns), so never configure iPhone Air together with a 6.3" device, or iPhone 17 Pro together with iPhone 18 Pro.

iPad slots:

| App Store Connect slot | Display type | Accepted sizes (px) | Simulator |
|------------------------|--------------|---------------------|-----------|
| 13" (primary required) | `APP_IPAD_PRO_3GEN_129` | 2064x2752 | `iPad Pro 13-inch (M5)` |
| 11" | `APP_IPAD_PRO_3GEN_11` | 1668x2420, 1668x2388, 1640x2360, 1488x2266 | `iPad Pro 11-inch (M5)`, `iPad Air 11-inch (M4)`, `iPad mini (A17 Pro)` |
| 12.9" (iPad Pro 2nd Gen) | `APP_IPAD_PRO_129` | 2048x2732 | `iPad Air 13-inch (M4)`, `iPad Pro (12.9-inch) (2nd generation)` ¹ |
| 10.5" | `APP_IPAD_105` | 1668x2224 | `iPad Air (3rd generation)` ¹ |
| 9.7" | `APP_IPAD_97` | 1536x2048 | `iPad (6th generation)` ¹ |

**Recommend `iPad Pro 13-inch (M5)` as the starting point** - it covers the required 13" slot. Add others only if needed.

**¹ Older slots** (12.9", 10.5", 9.7") require older simulator runtimes that may not be installed. Most apps only need 13".

Sizes outside every class (e.g. 1620x2160 from `iPad (9th generation)`, 828x1792 from `iPhone 11`) fail `submit --dry-run` with a `no ASC display type` error.

iPhone Duo (foldable):

| Display | Screenshot size (px) | storescreens label | App Store Connect |
|---------|----------------------|--------------------|-------------------|
| Outer (folded) | 1398x2034 | `iPhone Duo outer` | Not accepted yet; `submit` skips with a notice |
| Inner (open) | 2007x2853 | `iPhone Duo inner` | Not accepted yet; `submit` skips with a notice |

The `iPhone Duo` simulator needs Xcode 27.1 beta or later plus the iOS 27.1 simulator runtime (`xcodebuild -downloadPlatform iOS` with the beta selected). storescreens runs against whichever Xcode `xcode-select` or `DEVELOPER_DIR` selects, so capture the Duo from a separate config that lists only it, has its own `output_dir` (and `render.output_dir`, if rendering; a successful capture replaces the previous output in its directory), and drops the `search_preview` block (search previews never use Duo screenshots, so a Duo-only run would overwrite the main previews with empty tiles): `DEVELOPER_DIR=/Applications/Xcode-27.1.0-Beta.app/Contents/Developer storescreens capture --config storescreens-duo.yml --no-search-preview` (the path `xcodes install 27.1 Beta` uses). The pose can't be set from the command line or a UI test (only in Xcode's Device Hub); the simulator boots folded, so captures are outer-display screenshots unless it is opened there. Each screenshot is labeled by the display it came from. The first simulator launch can take several minutes.

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
| `--retries N` | Retry failed test runs per device (default: 1) |
| `--keep-alive` | Keep simulators running after capture |
| `--skip-check` | Skip preflight source code check |
| `--verbose` | Show full xcodebuild output |
| `--no-render` | Skip the render pass even when `render.enabled: true` |

## Render + Bezel Commands

| Command | Description |
|---------|-------------|
| `storescreens render` | Re-render captioned/framed output from existing captures. No simulator, no xcodebuild. |
| `storescreens themes suggest` | Suggest render themes (background, text color, frame colorway) from the captured screenshots' own colors. `--json` for structured output. |
| `storescreens bezels import` | Auto-scan mounted Apple Design Resource DMGs; install bezel PNGs + sidecars |
| `storescreens bezels import --volume PATH` | Import from one specific mount path instead of scanning `/Volumes` |
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

  # Optional - these are app-info / version metadata that lives in
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

  submission_info:                  # PATCH /v1/appStoreVersions + /v1/apps
    uses_idfa: false                # per version
    contains_third_party_content: true   # per app, carries across releases

  release:                          # PATCH /v1/appStoreVersions/{id}
    type: scheduled                 # manual | after_approval | scheduled
    earliest_release_date: "2026-08-10T12:00:00-07:00"   # exact hour, future, quoted
```

Related commands: `storescreens auth login`, `storescreens auth status`, `storescreens auth logout`, `storescreens submit [--dry-run] [--skip-screenshots] [--skip-metadata] [--version-override X.Y.Z]`, `storescreens precheck [--check-urls]`.
