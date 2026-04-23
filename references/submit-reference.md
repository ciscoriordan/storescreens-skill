# storescreens submit - Full Config Reference

`storescreens submit` uploads rendered screenshots and per-locale metadata (name, subtitle, description, keywords, what's new, etc.) to App Store Connect via Apple's official API. It is a wholly separate step from `capture` and `render`: you must have already captured, rendered, and be happy with the output before running `submit`.

The current v1 of `submit` only uploads. It does NOT submit the version for App Review - you still click "Submit for Review" manually in the App Store Connect web UI. See `submit_for_review` below.

## Top-level shape

Add an `app_store_connect:` block to `storescreens.yml`:

```yaml
app_store_connect:
  # One of app_id or bundle_id is required
  bundle_id: com.example.recipes
  # app_id: "1234567890"

  metadata_dir: ./metadata        # default: ./metadata

  submit:
    create_version: "1.2.0"       # required; created in ASC if missing
    screenshots: true             # default: true
    metadata: true                # default: true
    submit_for_review: false      # default: false (and currently always a no-op)
    platform: IOS                 # IOS | MAC_OS | TV_OS | VISION_OS (default IOS)
```

## `app_store_connect:` fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `app_id` | string | - | Numeric App Store Connect app ID (visible in the ASC URL as `/apps/<id>/`). Exactly one of `app_id` or `bundle_id` must be set. |
| `bundle_id` | string | - | Bundle identifier (e.g. `com.example.recipes`). Resolved via `GET /v1/apps?filter[bundleId]=...` at submit time. More convenient; use this unless you have a reason to hard-code the numeric ID. |
| `metadata_dir` | string | `./metadata` | Directory containing `<locale>/*.txt` files. Relative paths resolve against the directory containing `storescreens.yml`. |
| `submit` | object | - | Upload behaviour. See below. |

## `submit:` fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `create_version` | string | - | **Required.** Target App Store version string (e.g. `1.2.0`). If the version doesn't exist in App Store Connect yet, it is created. Can be overridden on the CLI with `--version-override`. |
| `screenshots` | bool | `true` | Upload rendered screenshots. Set to `false` for a metadata-only submit. Also controllable via `--skip-screenshots`. |
| `metadata` | bool | `true` | Upload per-locale metadata. Set to `false` for a screenshots-only submit. Also controllable via `--skip-metadata`. |
| `submit_for_review` | bool | `false` | Reserved for a future release. The current v1 ONLY uploads; it does not submit for App Review. After `submit` completes, go to App Store Connect and click "Submit for Review" yourself. This is intentional: review submission is irreversible without reviewer intervention, so v1 keeps a human in the loop. |
| `platform` | string | `IOS` | ASC platform enum: `IOS`, `MAC_OS`, `TV_OS`, `VISION_OS`. Rarely needs override; derive from your app's actual platform. |

## Metadata directory layout

Fastlane convention. One folder per locale, one file per field. Any file you leave out means "don't touch that field in App Store Connect". Present files replace whatever is currently there. Trailing whitespace and newlines are trimmed.

```
metadata/
  en-US/
    name.txt
    subtitle.txt
    description.txt
    keywords.txt
    promotional_text.txt
    release_notes.txt
    support_url.txt
    marketing_url.txt
  es-ES/
    description.txt
    release_notes.txt
  ja/
    name.txt
    subtitle.txt
    description.txt
    keywords.txt
    release_notes.txt
```

### File -> App Store Connect field mapping

| File | ASC field (API) | Max length | Notes |
|------|-----------------|------------|-------|
| `name.txt` | `name` (app info localization) | 30 | The app's name as shown on the store. |
| `subtitle.txt` | `subtitle` (app info localization) | 30 | Short tagline under the app name. |
| `description.txt` | `description` (version localization) | 4000 | Main App Store description. |
| `keywords.txt` | `keywords` (version localization) | 100 | Comma-separated keywords. The 100-char limit includes separators. |
| `promotional_text.txt` | `promotionalText` (version localization) | 170 | Marketing text shown above the description. Can be updated without a new app submission. |
| `release_notes.txt` | `whatsNew` (version localization) | 4000 | "What's New in This Version" release notes. Required for every version after 1.0. |
| `support_url.txt` | `supportURL` (version localization) | - | Must start with `http://` or `https://`. |
| `marketing_url.txt` | `marketingURL` (version localization) | - | Optional marketing site. |

Unknown filenames inside a locale directory are skipped with a warning. Dotfiles (`.DS_Store` etc.) are ignored.

Locale directories must match the Xcode locale codes used in your storescreens config (`en-US`, `ja`, `de-DE`, `es-ES`, etc.). A locale with zero readable fields is silently dropped; it is not an error.

## Credential resolution order

`storescreens auth status`, `submit --dry-run`, and `submit` all resolve credentials the same way. Environment variables take priority over the saved file, so CI jobs can always override a local `auth login`.

1. **Environment variables** (all three required together):
   - `ASC_KEY_ID` - 10-character alphanumeric key ID
   - `ASC_ISSUER_ID` - UUID from the App Store Connect API keys page
   - `ASC_KEY_PATH` - path to the `AuthKey_XXXXXX.p8` file (tilde is expanded)
2. **File** at `~/.storescreens/asc-credentials.yml` (perms 0600), written by `storescreens auth login`. The YAML shape is:

   ```yaml
   key_id: ABCDE12345
   issuer_id: 69a6de84-03c8-47e3-e053-5b8c7c11a4d1
   key_path: ~/.appstoreconnect/AuthKey_ABCDE12345.p8
   ```

If none of the above is present, commands that need credentials throw `App Store Connect credentials not configured. Set ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH - or run storescreens auth login.`

## Commands

| Command | Purpose |
|---------|---------|
| `storescreens auth login` | Prompt for key ID / issuer ID / .p8 path and write `~/.storescreens/asc-credentials.yml` (0600). |
| `storescreens auth logout` | Delete the stored credentials file. Env vars are untouched. |
| `storescreens auth status` | Report active credential source and mint a JWT + hit `/v1/users` to verify the key works. |
| `storescreens submit --dry-run` | Validate credentials, app lookup, metadata directory, screenshot dimensions and 8MB size cap. No writes. |
| `storescreens submit` | Live upload. Destructive for screenshot sets (see below). |

### `auth login` flags

Any flag left off is prompted interactively:

- `--key-id ABCDE12345`
- `--issuer-id 69a6de84-03c8-47e3-e053-5b8c7c11a4d1`
- `--key-path ~/.appstoreconnect/AuthKey_ABCDE12345.p8`

### `submit` flags

| Flag | Description |
|------|-------------|
| `--config PATH` / `-c PATH` | Path to `storescreens.yml`. Default: `./storescreens.yml`. |
| `--render-dir PATH` | Override `render.output_dir` as the source of framed PNGs. |
| `--metadata-dir PATH` | Override `app_store_connect.metadata_dir`. |
| `--version-override 1.2.1` | Override `app_store_connect.submit.create_version` for this run. |
| `--dry-run` | Validate everything, write nothing. |
| `--skip-screenshots` | Upload metadata only. |
| `--skip-metadata` | Upload screenshots only. |

## Destructive upload semantics

Screenshot uploads are intentionally destructive so that the local rendered PNGs are always the source of truth:

1. For every (locale, display type) pair in the rendered manifest, the existing App Store Connect screenshot set is wiped.
2. Fresh PNGs are uploaded in the manifest's order. The manifest order becomes the App Store display order.
3. Each upload is confirmed by MD5 hash before the next.

Metadata uploads are PATCHes. Only fields you included in `metadata/<locale>/` are sent; everything else in App Store Connect is left untouched. A locale with zero readable files is skipped entirely.

If you do not want a locale's screenshots re-ordered or wiped, either omit that locale from `metadata/` (metadata side) or pass `--skip-screenshots` for that run.

## Dry run

```bash
storescreens submit --dry-run
```

Runs through:

- credential resolution and JWT mint
- app lookup (by `app_id` or `bundle_id`)
- version find-or-create (read-only: reports whether it will create or update)
- per-locale metadata directory parse, including unknown-file warnings
- every rendered PNG: dimension match against App Store display types and the 8MB per-file cap

No writes happen. Use this as your pre-flight before a live submit.

## Troubleshooting

- **`credentials not configured`** - run `storescreens auth login` or export `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`. `auth status` will tell you which source it found.
- **`no App Store Connect app matched: <bundle>`** - the `bundle_id` in config doesn't match any app in your ASC team. Confirm the bundle ID is an exact match, or switch to `app_id`.
- **`no ASC display type for WxH`** - a rendered PNG has dimensions that don't match any App Store Connect slot. Usually means you captured with a non-App-Store simulator (e.g. `iPhone 16 Plus`, which corresponds to the 6.7" slot that doesn't exist in ASC). Re-capture with a supported simulator per `references/config-reference.md`.
- **`8MB limit exceeded`** - Apple caps individual screenshots at 8 MB. Reduce render complexity (smaller background image, lighter scrim) or lower PNG compression.
- **`app_store_connect.submit.create_version is required`** - set `submit.create_version` in the YAML or pass `--version-override`.
- **Locale not appearing in the upload summary** - every `metadata/<locale>/` file was empty or unknown. Only supported filenames (`name.txt`, `subtitle.txt`, `description.txt`, `keywords.txt`, `promotional_text.txt`, `release_notes.txt`, `support_url.txt`, `marketing_url.txt`) count; anything else is skipped with a warning.

## Complete example

Recipes app targeting 6.9" iPhone and iPad 13", two locales, captions rendered and ready, v1.2.0 shipping:

`storescreens.yml`:

```yaml
project: Recipes.xcodeproj
scheme: Recipes

devices:
  - simulator: "iPhone 17 Pro Max"
  - simulator: "iPad Pro 13-inch (M5)"

appearances:
  - light

locales:
  - en-US
  - es-ES

output_dir: storescreens-output
test_target: RecipesUITests
test_class: ScreenshotTests
derived_data_path: ~/.storescreens-cache/Recipes

screenshots:
  - 01_Home
  - 02_Search
  - 03_Detail
  - 04_MealPlan
  - 05_Shopping

render:
  enabled: true
  output_dir: storescreens-framed
  background:
    color: "#1a1a2e"
  chrome:
    style: bezel
  caption:
    title:
      font: system
      weight: bold
      font_size_pct: 5.5
      color: "#ffffff"
    min_height_pct: 22
  slides:
    "01_Home":
      caption: "Every recipe, **organized**."
    "02_Search":
      caption:
        - "Find anything"
        - "in *seconds*."

app_store_connect:
  bundle_id: com.example.recipes
  metadata_dir: ./metadata
  submit:
    create_version: "1.2.0"
    screenshots: true
    metadata: true
    submit_for_review: false
```

Metadata directory next to the YAML:

```
metadata/
  en-US/
    name.txt                  # "Recipes"
    subtitle.txt              # "Your kitchen, organized"
    description.txt           # 4000-char blurb
    keywords.txt              # "recipe,cooking,meal plan,grocery"
    promotional_text.txt      # short marketing copy
    release_notes.txt         # what's new in 1.2.0
    support_url.txt           # https://example.com/support
    marketing_url.txt         # https://example.com
  es-ES/
    name.txt                  # "Recetas"
    subtitle.txt              # "Tu cocina, organizada"
    description.txt
    keywords.txt
    release_notes.txt
    support_url.txt
```

Workflow:

```bash
# One-time setup
storescreens auth login
storescreens auth status

# Validate without uploading
storescreens submit --dry-run

# Live upload
storescreens submit

# Screenshots-only re-submit (e.g. after tweaking render)
storescreens submit --skip-metadata

# Metadata-only update (e.g. release notes fix)
storescreens submit --skip-screenshots --version-override 1.2.1
```

After `submit` reports success, open App Store Connect, inspect the 1.2.0 version, and click "Submit for Review" manually. v1 of `storescreens submit` deliberately stops short of that step.
