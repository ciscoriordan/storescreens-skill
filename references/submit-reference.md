# storescreens submit - Full Config Reference

`storescreens submit` uploads rendered screenshots and per-locale metadata (name, subtitle, description, keywords, what's new, etc.) to App Store Connect via Apple's official API. It is a wholly separate step from `capture` and `render`: you must have already captured, rendered, and be happy with the output before running `submit`.

By default `submit` stops after the uploads and leaves review submission to you. Set `submit_for_review: true` in the `submit:` block (or pass `--submit-for-review` on a single run without touching the yml) to also submit the version for App Review once screenshots and metadata are done. Internally this uses Apple's newer `reviewSubmissions` 3-step flow (create submission, add the version as an item, submit), transparent to the user; the submission ID is surfaced in the report. See `submit_for_review` below.

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
    submit_for_review: false      # default: false. Set true to auto-submit for App Review.
    platform: IOS                 # IOS | MAC_OS | TV_OS | VISION_OS (default IOS)
```

## `app_store_connect:` fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `app_id` | string | - | Numeric App Store Connect app ID (visible in the ASC URL as `/apps/<id>/`). Exactly one of `app_id` or `bundle_id` must be set. |
| `bundle_id` | string | - | Bundle identifier (e.g. `com.example.recipes`). Resolved via `GET /v1/apps?filter[bundleId]=...` at submit time. More convenient; use this unless you have a reason to hard-code the numeric ID. |
| `metadata_dir` | string | `./metadata` | Directory containing `<locale>/*.txt` files. Relative paths resolve against the directory containing `storescreens.yml`. |
| `submit` | object | - | Upload behaviour. See below. |
| `pricing` | object | - | App-level pricing. Optional; unset leaves the existing schedule untouched. Today only free pricing is implemented. See "`pricing:` fields" below. |
| `availability` | object | - | Territory availability. Optional; unset leaves current availability untouched. See "`availability:` fields" below. |
| `categories` | object | - | Primary + secondary App Store categories (and optional subcategories). Optional; unset leaves existing categories untouched. See "`categories:` fields" below. |
| `age_rating` | object | - | Age-rating questionnaire answers. Optional; unset leaves the existing declaration untouched. See "`age_rating:` fields" below. |
| `review_info` | object | - | App Review Information panel (notes, contact, demo account). Optional; YAML alternative to per-locale `review_*.txt` files - either flow ends up at the same `appStoreReviewDetails` resource. See "`review_info:` fields" below. |

## `submit:` fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `create_version` | string | - | **Required.** Target App Store version string (e.g. `1.2.0`). If the version doesn't exist in App Store Connect yet, it is created. Can be overridden on the CLI with `--version-override`. |
| `screenshots` | bool | `true` | Upload rendered screenshots. Set to `false` for a metadata-only submit. Also controllable via `--skip-screenshots`. |
| `metadata` | bool | `true` | Upload per-locale metadata. Set to `false` for a screenshots-only submit. Also controllable via `--skip-metadata`. |
| `submit_for_review` | bool | `false` | When `true`, `submit` drives Apple's `reviewSubmissions` 3-step flow (create submission, attach the version as an item, PATCH `submitted: true`) after screenshots and metadata have been uploaded successfully. The submission ID and final state (typically `WAITING_FOR_REVIEW`) are included in the report output. Submission runs only after the uploads succeed, so the version is complete when Apple picks it up. Before creating a new submission, `submit` runs a cleanup-or-adopt pre-flight: any prior `UNRESOLVED_ISSUES` (rejected) submission is cancelled via PATCH `canceled: true`; any stale `READY_FOR_REVIEW` draft is either adopted (when items already reference the target version, or items are empty so the version can be attached) or cancelled (when items reference a different version). Adopted drafts are finalized in place rather than recreated, which is the only programmatic recovery from a prior aborted submit that left an empty orphan. If a prior submission is in `IN_REVIEW` or `WAITING_FOR_REVIEW`, `submit` refuses to auto-cancel and surfaces a loud error so you can decide whether to cancel manually via the ASC web UI. When `attach_build` is also `true`, `submit` polls `/v1/builds` for up to 20 minutes waiting for a VALID build before creating the review submission, so a same-session upload-build + submit pair works without a manual wait. Default is `false` because review submission is irreversible without reviewer intervention, so opt in explicitly when you are ready to ship. |
| `platform` | string | `IOS` | ASC platform enum: `IOS`, `MAC_OS`, `TV_OS`, `VISION_OS`. Rarely needs override; derive from your app's actual platform. |

## `pricing:` fields

Sets the app's price schedule. Today only the free case is implemented - use the ASC web UI for paid pricing until a `price_tier` field lands. Runs idempotently: if the app already has a schedule, submit leaves it untouched rather than replacing it. This is intentional - blindly re-POSTing would overwrite anything a teammate set by hand.

```yaml
app_store_connect:
  pricing:
    free: true
    base_territory: USA
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `free` | bool | - | Required when the `pricing:` block is present. `true` creates a free schedule in the base territory; Apple auto-computes free prices everywhere else. `false` is rejected (paid pricing not yet wired up). |
| `base_territory` | string | `USA` | ISO 3166-1 alpha-3 territory code used to anchor the schedule. Any territory works; USA matches the ASC web UI default. |

## `availability:` fields

Sets which territories the app is available in. Required before a new app can be submitted for review; existing apps keep their current availability unless you change this block. Runs idempotently: matches the current list before POSTing.

```yaml
app_store_connect:
  availability:
    territories: all                    # or: ["USA", "CAN", "GBR"]
    available_in_new_territories: true
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `territories` | `"all"` or list of ISO 3166-1 alpha-3 codes | - | `all` resolves to every territory Apple supports at submit time (expanded via `GET /v1/territories`). A list limits availability to the specified territories only. Unset skips the availability step entirely. |
| `available_in_new_territories` | bool | `true` | When Apple adds a new territory to the App Store, auto-enroll the app. Matches ASC's own default. |

## App Info & version metadata

The next three blocks (`categories:`, `age_rating:`, `review_info:`) cover the rest of what the App Store Connect web UI calls "App Information" plus the "App Review Information" panel. Each is optional and idempotent: `submit` reads the current values from ASC, diffs against the YAML, and only PATCHes when something differs.

`categories:` and `age_rating:` live on the editable AppInfo (the same record that hosts name/subtitle/privacy URLs), so they require an editable AppInfo state - typically `PREPARE_FOR_SUBMISSION`. When the only AppInfo is `READY_FOR_SALE`, the orchestrator skips with `skipped: no editable appInfo` (same skip-reason path as name/subtitle).

`review_info:` lives on the version's `appStoreReviewDetails` resource and works on any editable version.

## `categories:` fields

```yaml
app_store_connect:
  categories:
    primary: EDUCATION
    secondary: REFERENCE
    # optional sub-slots:
    # primary_subcategory_one: ...
    # primary_subcategory_two: ...
    # secondary_subcategory_one: ...
    # secondary_subcategory_two: ...
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `primary` | string | - | Primary App Store category ID (uppercase, e.g. `EDUCATION`, `PHOTO_AND_VIDEO`). Required when assigning categories for the first time; optional on re-runs. |
| `secondary` | string | - | Secondary category ID. Pass the literal string `"none"` to explicitly clear the slot. Optional. |
| `primary_subcategory_one` / `primary_subcategory_two` | string | - | Optional first/second subcategory under the primary category. Mostly used by `GAMES` (e.g. `GAMES_ACTION`, `GAMES_ADVENTURE`). |
| `secondary_subcategory_one` / `secondary_subcategory_two` | string | - | Same shape as the primary subcategory slots, but under `secondary`. |

`storescreens submit --dry-run` validates every supplied id against `GET /v1/appCategories` so a typo fails before the live PATCH. Unknown categories produce errors like `categories.primary = "EDUKATION" is not a known ASC category id (try one of: BOOKS, BUSINESS, DEVELOPER_TOOLS, EDUCATION, ENTERTAINMENT, …)`.

API endpoint: `PATCH /v1/appInfos/{id}` with all six relationships in a single body. Apple's separate relationship-only endpoints (e.g. `PATCH /v1/appInfos/{id}/relationships/primaryCategory`) return 403 `FORBIDDEN_ERROR` "does not allow UPDATE" - the parent PATCH is the only programmatic path that works.

## `age_rating:` fields

The age-rating questionnaire that determines the 4+/9+/12+/17+ badge on the App Store. Each editable AppInfo has exactly one auto-created `ageRatingDeclaration` child; `submit` PATCHes that record with whatever subset of fields you specify in YAML.

```yaml
app_store_connect:
  age_rating:
    # Frequencies: NONE | INFREQUENT_OR_MILD | FREQUENT_OR_INTENSE
    cartoon_or_fantasy_violence: NONE
    realistic_violence: NONE
    prolonged_graphic_sadistic_realistic_violence: NONE
    profanity_or_crude_humor: NONE
    mature_or_suggestive_themes: NONE
    horror_or_fear_themes: NONE
    medical_or_treatment_information: NONE
    alcohol_tobacco_or_drug_use_or_references: NONE
    simulated_gambling: NONE
    sexual_content_or_nudity: NONE
    graphic_sexual_content_and_nudity: NONE
    contests: NONE
    # Booleans
    unrestricted_web_access: false
    gambling: false
    # Other
    kids_age_band: NONE       # NONE | FIVE_AND_UNDER | SIX_TO_EIGHT | NINE_TO_ELEVEN
    # age_rating_override: NONE_OF_THE_ABOVE  # rarely used
```

| Field type | Allowed values | Notes |
|------------|----------------|-------|
| Frequency fields | `NONE`, `INFREQUENT_OR_MILD`, `FREQUENT_OR_INTENSE` | Each defaults to `NONE` server-side; specify only what your app actually contains. |
| `unrestricted_web_access` | `true` / `false` | Set to `true` when the app embeds a general-purpose browser. |
| `gambling` | `true` / `false` | Real-money gambling. (Simulated/play-money gambling uses `simulated_gambling` instead.) |
| `kids_age_band` | `NONE` / `FIVE_AND_UNDER` / `SIX_TO_EIGHT` / `NINE_TO_ELEVEN` | Required for apps in the Kids category; defaults to `NONE` for everything else. |
| `age_rating_override` | string | Rarely needed. Apple's docs list the valid override values; leave unset for normal apps. |

API endpoint: `PATCH /v1/ageRatingDeclarations/{id}`, where `{id}` is fetched once via `GET /v1/appInfos/{appInfoID}/ageRatingDeclaration`. ASC computes the final rating (4+, 9+, 12+, 17+) from the answers automatically; you don't set the rating directly.

If every YAML field already matches the ASC declaration, `submit` skips the PATCH entirely and reports `age rating: unchanged`. ASC rejects PATCHes with no changed attributes, so the pre-diff isn't optional.

## `review_info:` fields

The "App Review Information" panel the reviewer sees while triaging your build: a free-form notes field plus contact info plus an optional demo login. This is an alternative to the per-locale `review_*.txt` files - either flow ends up at the same `appStoreReviewDetails` resource. When both YAML and files are present, YAML wins on a per-field basis.

```yaml
app_store_connect:
  review_info:
    first_name: Jane
    last_name: Doe
    phone_number: "+1 555 123 4567"
    email_address: jane@example.com
    demo_account_required: false  # default: auto-derived from demo_account_*
    demo_account_name: tester@example.com
    demo_account_password: hunter2
    notes: |
      Plain-text notes for Apple's reviewers. Multi-line YAML strings
      work fine here; trailing whitespace is trimmed at PATCH time.
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `first_name` | string | - | Reviewer-facing contact first name. |
| `last_name` | string | - | Reviewer-facing contact last name. |
| `phone_number` | string | - | Phone number Apple uses if they need to reach the developer during review. |
| `email_address` | string | - | Email address for the same purpose. |
| `demo_account_required` | bool | auto | Whether Apple needs a demo login. Defaults to `true` when `demo_account_name` or `demo_account_password` is set; `false` otherwise. Set explicitly to override. |
| `demo_account_name` | string | - | Demo account username/email. Optional. |
| `demo_account_password` | string | - | Demo account password. Required when `demo_account_name` is set. |
| `notes` | string | - | Free-form notes. Multi-line via YAML pipe literal (`notes: \|`). Up to 4000 characters. |

API endpoint: `appStoreReviewDetails` (POST when one doesn't exist on the version yet, PATCH when it does). Diffed before write; unchanged values produce a `review detail: unchanged` log line and no API call.

## Metadata directory layout

Fastlane convention. One folder per locale, one file per field. Any file you leave out means "don't touch that field in App Store Connect". Present files replace whatever is currently there. Trailing whitespace and newlines are trimmed.

Scaffold the directory with `storescreens metadata init` (see the Commands section below). This creates per-locale subdirectories and writes a `metadata/README.md` with the full field reference table inline, so the user has the reference right next to the files they are editing.

```
metadata/
  README.md                  # field reference table, written by `metadata init`
  en-US/
    name.txt
    subtitle.txt
    description.txt
    keywords.txt
    promotional_text.txt
    release_notes.txt
    support_url.txt
    marketing_url.txt
    privacy_url.txt
    review_notes.txt
    review_contact_first_name.txt
    review_contact_last_name.txt
    review_contact_phone.txt
    review_contact_email.txt
    review_demo_account_name.txt
    review_demo_account_password.txt
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

`privacy_url.txt` is optional. Unlike the other fields it patches the App Info localization (app-level) rather than the version localization, which is where App Store Connect keeps privacy URLs. The submit command routes it to the correct endpoint automatically, so no extra config is needed; just drop the file in the locale directory.

`review_notes.txt` and the `review_contact_*.txt` / `review_demo_account_*.txt` files feed the version-level `appStoreReviewDetails` resource (the "App Review Information" panel in App Store Connect). They are version-scoped not locale-scoped on Apple's side, so put them under one locale only - typically your primary. If the same `review_*.txt` file shows up in multiple locale folders, the alphabetically-first one wins and `submit` warns about the rest.

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
| `privacy_url.txt` | `privacyPolicyUrl` (app info localization) | - | Optional privacy policy URL. Patched on the App Info localization (app level), not the version localization. Must start with `http://` or `https://`. |
| `review_notes.txt` | `notes` (appStoreReviewDetail) | 4000 | Free-form notes for Apple's reviewers. Version-scoped, not per-locale - put in one locale only. |
| `review_contact_first_name.txt` | `contactFirstName` (appStoreReviewDetail) | - | Reviewer contact info. |
| `review_contact_last_name.txt` | `contactLastName` (appStoreReviewDetail) | - | Reviewer contact info. |
| `review_contact_phone.txt` | `contactPhone` (appStoreReviewDetail) | - | Reviewer contact info. |
| `review_contact_email.txt` | `contactEmail` (appStoreReviewDetail) | - | Reviewer contact info. |
| `review_demo_account_name.txt` | `demoAccountName` (appStoreReviewDetail) | - | Optional demo login (when the app needs an account to be reviewed). |
| `review_demo_account_password.txt` | `demoAccountPassword` (appStoreReviewDetail) | - | Optional demo login password. |

Unknown filenames inside a locale directory are skipped with a warning. Dotfiles (`.DS_Store` etc.) are ignored.

Locale directories must match the Xcode locale codes used in your storescreens config (`en-US`, `ja`, `de-DE`, `es-ES`, etc.). A locale with zero readable fields is silently dropped; it is not an error.

## Credential resolution order

`storescreens auth status`, `submit --dry-run`, and `submit` all resolve credentials the same way. Environment variables take priority over the saved file, so CI jobs can always override a local `auth login`.

1. **Environment variables** (all three required together):
   - `ASC_KEY_ID` - 10-character alphanumeric key ID
   - `ASC_ISSUER_ID` - UUID from the App Store Connect API keys page
   - `ASC_KEY_PATH` - path to the `AuthKey_XXXXXX.p8` file (tilde is expanded)
2. **File** at `~/.storescreens/asc-credentials.yml` (perms 0600), written by `storescreens auth init` (recommended) or `storescreens auth login`. The YAML shape is:

   ```yaml
   key_id: ABCDE12345
   issuer_id: 69a6de84-03c8-47e3-e053-5b8c7c11a4d1
   key_path: ~/.appstoreconnect/AuthKey_ABCDE12345.p8
   ```

If none of the above is present, commands that need credentials throw `App Store Connect credentials not configured. Set ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH - or run storescreens auth login.`

## Commands

| Command | Purpose |
|---------|---------|
| `storescreens auth init` | Write `~/.storescreens/asc-credentials.yml` (0600) with commented `REPLACE_ME` placeholders for `key_id`, `issuer_id`, `key_path`, then open it in `$EDITOR` (or `open -t` if unset). Recommended onboarding path for most users. |
| `storescreens auth login` | Prompt for key ID / issuer ID / .p8 path and write `~/.storescreens/asc-credentials.yml` (0600). Alternative to `auth init` for users who prefer a Q&A flow. |
| `storescreens auth logout` | Delete the stored credentials file. Env vars are untouched. |
| `storescreens auth status` | Report active credential source and mint a JWT + hit `/v1/users` to verify the key works. |
| `storescreens metadata init` | Scaffold `metadata/<locale>/` directories and write `metadata/README.md` containing the full field reference table. |
| `storescreens submit --dry-run` | Validate credentials, app lookup, metadata directory, screenshot dimensions and 8MB size cap. No writes. |
| `storescreens submit` | Live upload. Destructive for screenshot sets (see below). |

### `auth init` flags

- `--force` / `-f` - overwrite an existing credentials file. Without this, `auth init` warns and opens the existing file instead of clobbering it.
- `--no-open` - write the file but don't launch an editor. Useful in scripted setups.

### `auth login` flags

Any flag left off is prompted interactively:

- `--key-id ABCDE12345`
- `--issuer-id 69a6de84-03c8-47e3-e053-5b8c7c11a4d1`
- `--key-path ~/.appstoreconnect/AuthKey_ABCDE12345.p8`

### `metadata init` flags

- `--locales en-US es-ES ja` / `-l ...` - one or more locale codes. Multiple values accepted in a single flag. Default: `en-US`.
- `--dir PATH` / `-d PATH` - target directory. Default: `./metadata`.
- `--force` / `-f` - overwrite an existing `README.md` inside the target directory.

The command is non-destructive by default: it creates missing locale subdirectories and writes `README.md` only if absent. Existing locale folders and `.txt` files are left alone. The `README.md` inside the metadata directory is the authoritative field reference for the user - it lists every supported filename, the corresponding App Store Connect field, character limits, and an empty-file caveat (an empty file DOES overwrite the ASC field with an empty string; delete the file instead).

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
| `--submit-for-review` / `--no-submit-for-review` | Override `app_store_connect.submit.submit_for_review` for this run. Use the positive form to trigger review submission without editing the yml; the negative form suppresses it even when the yml sets `true`. When neither flag is passed, the yml value is used. Combine with `--skip-screenshots --skip-metadata` to fire only the review submission against an already-uploaded version. |

## Destructive upload semantics

Screenshot uploads are intentionally destructive so that the local rendered PNGs are always the source of truth:

1. For every (locale, display type) pair in the rendered manifest, the existing App Store Connect screenshot set is wiped.
2. Fresh PNGs are uploaded in the manifest's order. The manifest order becomes the App Store display order.
3. Each upload is confirmed by MD5 hash before the next.

Metadata uploads are PATCHes. Only fields you included in `metadata/<locale>/` are sent; everything else in App Store Connect is left untouched. A locale with zero readable files is skipped entirely.

If you do not want a locale's screenshots re-ordered or wiped, either omit that locale from `metadata/` (metadata side) or pass `--skip-screenshots` for that run.

## Idempotent re-runs

Both sides of `submit` diff against App Store Connect before writing, so re-running an unchanged submission is cheap and mostly silent.

**Metadata.** Before PATCHing each version localization, `submit` fetches the current attributes from `GET /appStoreVersionLocalizations/{id}`. It sends only fields whose file content differs from the live value; fields that already match are dropped from the PATCH body. If no field differs, the PATCH is skipped entirely and the locale does not appear in `report.metadataUpdates`. Privacy URL (on the AppInfo localization) follows the same pattern.

**Screenshots.** Before wiping each set, `submit` calls `GET /appScreenshotSets/{id}/appScreenshots` and reads `sourceFileChecksum` (MD5 of the file bytes) and order. It then MD5s the local render PNGs in manifest order. If the lists match position-for-position, no DELETE or upload calls fire. The entry still appears in `report.screenshotUploads` with `count: 0` so the skip is visible.

Any mismatch - different file content, different count, different order - falls back to the full wipe+reupload. This is correct because ASC's upload model can't reorder existing screenshots in place; a reorder is semantically a wipe.

Practical effect: re-submitting after a rejection with only release-notes changes PATCHes only the `whatsNew` field and skips all 32 (or however many) screenshot uploads. Re-submitting with no changes at all is a handful of GETs and returns in seconds.

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

- **`credentials not configured`** - run `storescreens auth init` (recommended) or `storescreens auth login`, or export `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`. `auth status` will tell you which source it found.
- **`no App Store Connect app matched: <bundle>`** - the `bundle_id` in config doesn't match any app in your ASC team. Confirm the bundle ID is an exact match, or switch to `app_id`.
- **`no ASC display type for WxH`** - a rendered PNG has dimensions that don't match any App Store Connect slot. Usually means you captured with a non-App-Store simulator (e.g. `iPhone 16 Plus`, which corresponds to the 6.7" slot that doesn't exist in ASC). Re-capture with a supported simulator per `references/config-reference.md`.
- **`8MB limit exceeded`** - Apple caps individual screenshots at 8 MB. Reduce render complexity (smaller background image, lighter scrim) or lower PNG compression.
- **`app_store_connect.submit.create_version is required`** - set `submit.create_version` in the YAML or pass `--version-override`.
- **Locale not appearing in the upload summary** - every `metadata/<locale>/` file was empty or unknown. Only supported filenames (`name.txt`, `subtitle.txt`, `description.txt`, `keywords.txt`, `promotional_text.txt`, `release_notes.txt`, `support_url.txt`, `marketing_url.txt`, `privacy_url.txt`) count; anything else is skipped with a warning.
- **`release_notes.txt` is ignored on first submission** - App Store Connect rejects "What's New" text on a brand-new app's first version because release notes are semantically "what changed since the last release." `submit` detects this case by listing the app's versions and skips the `whatsNew` attribute in the PATCH, emitting a `skipping whatsNew (...)` progress line. The file is still read, just not sent this time; subsequent version submissions (after the app is live) will pick it up automatically.
- **`categories: skipped: no editable appInfo`** - same root cause as the name/subtitle skip path: the only AppInfo on the app is in `READY_FOR_SALE` (the live store record). Categories live on the editable AppInfo, so they need a `PREPARE_FOR_SUBMISSION`-state AppInfo to PATCH onto. Bump `submit.create_version` to a fresh string so `submit` creates a new editable version (which auto-creates a fresh editable AppInfo) and re-run.
- **`categories.<field> = "..." is not a known ASC category id`** - the supplied id doesn't match any value returned by `GET /v1/appCategories`. The dry-run prints the first five known ids as a hint. Common mistakes: lowercase (use `EDUCATION`, not `Education`), spaces (use `_`, e.g. `PHOTO_AND_VIDEO`), or guessing at the human label instead of the API id (it's `BOOKS`, not `BOOK`).
- **Age-rating PATCH 422 with no detail** - usually means the YAML's frequency value is one Apple doesn't recognize. Valid values are `NONE`, `INFREQUENT_OR_MILD`, `FREQUENT_OR_INTENSE`. The Codable parser catches typos like `SOMETIMES` at YAML-load time, but if Apple changes the enum names server-side a previously-good YAML may start rejecting; check `developer.apple.com/documentation/appstoreconnectapi/age_rating_declaration` for the current list.

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
  - Home
  - Search
  - Detail
  - MealPlan
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
    "Home":
      caption: "Every recipe, **organized**."
    "Search":
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
    privacy_url.txt           # https://example.com/privacy
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
storescreens auth init         # or `storescreens auth login` for a prompt flow
storescreens auth status
storescreens metadata init --locales en-US es-ES

# Validate without uploading
storescreens submit --dry-run

# Live upload
storescreens submit

# Screenshots-only re-submit (e.g. after tweaking render)
storescreens submit --skip-metadata

# Metadata-only update (e.g. release notes fix)
storescreens submit --skip-screenshots --version-override 1.2.1
```

After `submit` reports success with `submit_for_review: false`, open App Store Connect, inspect the 1.2.0 version, and click "Submit for Review" manually. To skip that step and have `submit` drive Apple's `reviewSubmissions` 3-step flow automatically once uploads finish, flip `submit_for_review: true` in the YAML; the returned submission ID appears in the report.
