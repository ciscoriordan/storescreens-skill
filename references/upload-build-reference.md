# storescreens upload-build - Full Config Reference

`storescreens upload-build` wraps `xcodebuild archive` -> `xcodebuild -exportArchive` -> `xcrun altool --upload-app` into one step, pinning `DEVELOPER_DIR` to a production (non-beta) Xcode so a beta `xcode-select -p` can't taint the archive.

It shares ASC API key credentials with `submit`: if `auth status` works for submit, it works here.

## Top-level shape

Add an `app_store_connect.upload_build:` block to `storescreens.yml` (sibling of `submit:`):

```yaml
app_store_connect:
  bundle_id: com.example.app
  submit: { ... }
  upload_build: {}   # all defaults — most users need nothing more
```

Or with every field set:

```yaml
app_store_connect:
  bundle_id: com.example.app
  upload_build:
    scheme: MyApp                         # default: top-level scheme:
    configuration: Release                # default: Release
    export_method: app-store              # default: app-store
    team_id: ABCDE12345                   # optional; auto-resolved for automatic signing
    signing_style: automatic              # default: automatic
    provisioning_profiles:                # manual signing only
      com.example.app: "My App Distribution Profile"
    include_symbols: true                 # default: true (dSYMs uploaded)
    strip_swift_symbols: true             # default: true
    xcode_path: /Applications/Xcode.app   # default: auto-pick highest non-beta
    export_options_plist: ./ExportOptions.plist  # default: generated from this block
    allow_provisioning_updates: true      # default: true
    destination: generic/platform=iOS     # default: generic/platform=iOS
    output_dir: ./build                   # default: ./build
    skip_upload: false                    # default: false
```

## `upload_build:` fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `scheme` | string | top-level `scheme:` | Scheme to archive. Falls back to the storescreens `scheme:` if omitted. |
| `configuration` | string | `Release` | xcodebuild configuration name. |
| `export_method` | string | `app-store` | One of `app-store`, `ad-hoc`, `enterprise`, `development`. Written to the generated `ExportOptions.plist`. |
| `team_id` | string | - | Apple Developer team ID (10 chars). Usually only required for manual signing; automatic signing resolves the team from the archive. |
| `signing_style` | string | `automatic` | `automatic` or `manual`. If `provisioning_profiles` is set, this flips to `manual` automatically. |
| `provisioning_profiles` | map (bundle_id -> name) | - | Manual signing only. Maps each bundle identifier in your app (incl. extensions) to the provisioning profile name that should be used. |
| `include_symbols` | bool | `true` | Whether to include dSYMs in the export. Turns into `uploadSymbols` in the generated plist. |
| `strip_swift_symbols` | bool | `true` | Whether to strip Swift symbols from the binary. |
| `xcode_path` | string | auto-detected | Override the `DEVELOPER_DIR` Xcode. Accepts `/Applications/Xcode.app` or `/Applications/Xcode.app/Contents/Developer`. If omitted, storescreens scans `/Applications/Xcode*.app`, excludes any path with "beta" in the name or Info.plist icon, and picks the highest-version remaining install. |
| `export_options_plist` | string | - | Path to a hand-crafted `ExportOptions.plist`. When set, storescreens skips generating one and passes your plist to `-exportArchive` verbatim. Relative paths resolve against the directory containing `storescreens.yml`. |
| `allow_provisioning_updates` | bool | `true` | Passes `-allowProvisioningUpdates` at archive and export time, letting Xcode contact the Apple dev portal to create or download missing profiles and certs during the run. Turn this off in air-gapped / fully manual setups. |
| `destination` | string | `generic/platform=iOS` | xcodebuild `-destination` flag for the archive. For tvOS/visionOS/macOS apps, change accordingly. |
| `output_dir` | string | `./build` | Where the `.xcarchive` and exported `.ipa` are written. Relative paths resolve against the yml directory. |
| `skip_upload` | bool | `false` | Archive + export + stop. Useful for producing an `.ipa` for manual distribution, inspection, or a different upload pipeline. Skipping upload also skips the pre-archive version check. |
| `auto_bump` | bool | `true` | When the resolver decides the current `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` won't work (already shipped, or build number collides with TestFlight): rewrite the pbxproj in place (and sync `submit.create_version` in the yml). Set to `false` to error out instead and print the `agvtool` commands to run manually. |
| `marketing_version` | string | - | Force a specific marketing version. Bypasses the "is it shipped?" check but still validates build number against existing TestFlight builds. |
| `build_number` | string | - | Force a specific build number. Bypasses the collision check. |

## Automatic version + build resolution

Before archiving, `upload-build` looks at three sources to pick the right `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`:

1. **Xcode project state**: read from the project's `project.pbxproj` (first `MARKETING_VERSION = X;` / `CURRENT_PROJECT_VERSION = N;` occurrence).
2. **App Store Connect version state**: `GET /v1/apps/{id}/appStoreVersions?filter[platform]=IOS` to see whether the current marketing version has been shipped (any of `READY_FOR_SALE`, `PROCESSING_FOR_APP_STORE`, `PENDING_APPLE_RELEASE`, `PENDING_DEVELOPER_RELEASE`, `REPLACED_WITH_NEW_VERSION`, `REMOVED_FROM_SALE`).
3. **TestFlight build history**: `GET /v1/builds?filter[app]=...&filter[preReleaseVersion.version]=X.Y.Z&sort=-version&limit=200` to find the highest existing build number for the current "train".

Resolution rules:

| Current state | Action |
|---------------|--------|
| Marketing version already shipped | Bump patch (`1.1.7` -> `1.1.8`), reset build to `1` (or `max(existing-on-new-train) + 1` if any builds already sit on the bumped train). |
| Marketing version editable, TestFlight has builds, Xcode build <= max | Keep marketing version, bump build to `max(existing) + 1`. |
| Marketing version editable, TestFlight has builds, Xcode build > max | Use Xcode's build number (already ahead). |
| Fresh marketing version, no builds | Keep marketing version, keep build (defaults to `1` if non-integer). |

Outcomes:

- When `auto_bump: true` (default): the pbxproj is rewritten in place and `submit.create_version` in the yml is synced. Every occurrence of the two settings across every config of every target is updated (matching `agvtool new-version -all` / `new-marketing-version` semantics). Stale build products under `derived_data_path` are preserved; the next archive picks up the new values.
- When `auto_bump: false`: errors out with the `agvtool` commands required to make the change manually.

Override rules:

- `marketing_version:` (or `--marketing-version`) fixes the version string. Build validation still runs against the chosen version's builds.
- `build_number:` (or `--build`) fixes the build number. Collision check is bypassed.
- Both overrides combined skip the ASC round-trip entirely (no API calls).

Degrade paths:

- **Credentials missing during `--dry-run`**: warn and print whatever's currently in the Xcode project. No ASC calls.
- **Credentials missing during a live run**: error (upload requires creds anyway).
- **No `project:` in yml (workspace-only)**: skip the check. `upload-build` can't find a pbxproj to read or rewrite in this setup. Users on workspace-only setups should set `marketing_version:` / `build_number:` explicitly, or pass them on the CLI.
- **`--skip-upload`**: skip the check entirely. A local archive for manual distribution doesn't care about TestFlight collisions.

## Non-beta Xcode auto-selection

The algorithm scans `/Applications/Xcode*.app` and reads `Contents/Info.plist` from each. An install is flagged as beta when:

- the `.app` path (case-insensitive) contains `"beta"`, OR
- `CFBundleIconName` / `CFBundleIconFile` in the Info.plist contains `"beta"` (case-insensitive).

All non-beta installs are ranked by `CFBundleShortVersionString` (dotted-integer compare), and the highest wins. If only beta installs are found, storescreens errors out with a list of what it saw.

Set `xcode_path:` (or pass `--xcode-path`) to opt out of auto-selection. A user-pinned path is trusted even if it points at a beta, because the user explicitly asked for it.

## ExportOptions.plist generation

When `export_options_plist:` is not set, storescreens writes a minimal plist to a temp file and passes it to `-exportArchive`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store</string>
  <key>uploadSymbols</key><true/>
  <key>stripSwiftSymbols</key><true/>
  <key>destination</key><string>export</string>
  <!-- teamID, provisioningProfiles, signingStyle all conditional -->
</dict>
</plist>
```

Keys written:

- `method` - from `export_method`
- `teamID` - from `team_id` (only when set)
- `uploadSymbols` - from `include_symbols`
- `stripSwiftSymbols` - from `strip_swift_symbols`
- `provisioningProfiles` - from `provisioning_profiles` (only when set)
- `signingStyle` - from `signing_style`, or forced to `manual` when `provisioningProfiles` is populated
- `destination` - always `export`

The temp plist is removed after the run.

## Credentials

Same resolution order as `submit` (see `submit-reference.md`):

1. Environment variables `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH` (all three must be set together).
2. `~/.storescreens/asc-credentials.yml`.

altool has its own constraint: the `.p8` file must be named `AuthKey_<KEY_ID>.p8` and live under `./private_keys`, `~/private_keys`, `~/.private_keys`, `~/.appstoreconnect/private_keys`, or the dir pointed to by `$API_PRIVATE_KEYS_DIR`. storescreens writes the PEM into a fresh `NSTemporaryDirectory()` subdir as `AuthKey_<KEY_ID>.p8`, points `API_PRIVATE_KEYS_DIR` at it, and removes the dir in a `defer` block - matching fastlane's `AltoolTransporterExecutor`.

## Commands

| Command | Purpose |
|---------|---------|
| `storescreens upload-build init` | Append an `upload_build:` block with commented placeholders to `storescreens.yml` and open it in `$EDITOR`. |
| `storescreens upload-build --dry-run` | Plan the run. Prints resolved scheme, configuration, destination, Xcode, archive path, export path, upload target. Does not touch xcodebuild or altool. |
| `storescreens upload-build` | Live: archive + export + upload. |
| `storescreens upload-build --skip-upload` | Archive + export + stop. The `.ipa` is left in `output_dir`. Equivalent to `skip_upload: true` in yml. |

### `upload-build init` flags

- `--force` / `-f` - replace an existing `upload_build:` block rather than warning about it.
- `--no-open` - write without launching an editor.
- `--config PATH` / `-c PATH` - target a specific yml (default: `./storescreens.yml`).

Behaviour:

1. If `storescreens.yml` is missing, errors with a pointer to `storescreens init`.
2. If an `upload_build:` block already exists at any indent level inside the file and `--force` isn't passed: warns and opens the file as-is.
3. If `app_store_connect:` exists at top level: inserts the boilerplate inside that block as a sibling of `submit:`, preserving all other content and comments.
4. If `app_store_connect:` does not exist: appends a fresh block with `bundle_id: REPLACE_ME_…` plus the boilerplate `upload_build:` inside it.

### `upload-build` (run) flags

| Flag | Description |
|------|-------------|
| `--config PATH` / `-c PATH` | Path to `storescreens.yml`. Default: `./storescreens.yml`. |
| `--scheme NAME` | Override the scheme. Wins over both top-level `scheme:` and `upload_build.scheme:`. |
| `--configuration NAME` | Override configuration (default: Release). |
| `--xcode-path PATH` | Override `DEVELOPER_DIR`. Accepts the `.app` bundle or the `Contents/Developer` dir. |
| `--output-dir PATH` | Override `output_dir`. |
| `--skip-upload` | Archive + export + stop. |
| `--dry-run` | Plan without running xcodebuild or altool. |
| `--verbose` | Stream full xcodebuild output instead of filtered progress lines. |

## Typical release workflow

```bash
# One-time setup
storescreens auth init           # ASC API key
storescreens upload-build init   # scaffold upload_build: block
# edit storescreens.yml and save

# Every release
storescreens upload-build --dry-run
storescreens upload-build        # binary -> TestFlight/ASC
# wait 5-20 min for Apple to process the build
storescreens submit              # screenshots + metadata onto the version
```

If `submit` runs before Apple has finished processing the binary, the metadata and screenshot uploads still succeed but the "Build" field on the version stays unset (you can either re-run `submit` once processing completes, or set it manually in App Store Connect).

## Troubleshooting

- **`Could not locate a production Xcode: only beta Xcode(s) found`** - install a non-beta Xcode from `xcodereleases.com` or the Mac App Store, or set `xcode_path:` / `--xcode-path` to the path of the Xcode you want to use. A beta install is accepted only when explicitly pinned.
- **`xcodebuild archive failed: No signing certificate`** - you don't have a valid Developer ID / Distribution certificate locally. Open Xcode, go to Settings -> Accounts, select the team, and click "Manage Certificates". Or use manual signing with pre-installed profiles and set `signing_style: manual` + `provisioning_profiles:`.
- **`xcodebuild archive failed: No profiles for ... were found`** - the app (or one of its extensions) has no provisioning profile. With `allow_provisioning_updates: true` (default), Xcode should create one automatically; if it doesn't, you may need to open the project in Xcode once and enable automatic signing, or create the profile in the dev portal and download it.
- **`xcodebuild -exportArchive failed: Could not resolve entitlements`** - an entitlement your code requires isn't enabled on the App ID in App Store Connect (e.g. CloudKit, Associated Domains, Push). Enable it on the App ID, then re-run.
- **`altool upload failed: Authentication failed`** - run `storescreens auth status` to confirm the API key is valid. If the key was recently revoked or the issuer ID changed, regenerate and re-run `storescreens auth init`.
- **`no .ipa produced in <exportPath>`** - exportArchive succeeded but didn't write an `.ipa`. This usually happens when the archive is for a framework or app extension target rather than the app itself. Confirm the `scheme:` points at the app target.
- **`altool: Unable to determine app platform`** - the `destination:` in your config doesn't match the app. For a visionOS app, set `destination: generic/platform=visionOS`.

## Security + hygiene notes

- The `.p8` file on disk never moves. storescreens reads it into memory, writes a copy to a tmpdir for altool, and removes the tmpdir after altool exits. The original file at `key_path:` is not touched.
- Permissions: the tmpdir is `0700`, the inner `AuthKey_<KEY_ID>.p8` is `0600`.
- The archive and exported ipa are kept in `output_dir` after the run (not cleaned up). Delete or gitignore as needed. The temp `ExportOptions.plist` (when generated) is removed on exit.
- Don't commit the `.p8` file, the archive, or the ipa to git. `storescreens init` already adds `build/` and `storescreens-output/` to a project `.gitignore` when it creates one; if you customized `output_dir`, add that path yourself.
