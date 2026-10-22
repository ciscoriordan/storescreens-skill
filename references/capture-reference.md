# Capture reference

MCP `capture` accepts `locales`, `appearances`, `only`, `no_parallel`, and `retries`. Use these fields for partial reruns without replacing the application's saved configuration. A failed test fails the capture even when it wrote PNGs, and leaves the previous successful output intact.

Run from the application project directory. `storescreens init` discovers the project and available simulators; `storescreens setup` generates tests. Existing validated test flows remain authoritative.

```yaml
project: MyApp.xcodeproj
scheme: MyApp
output_dir: screenshots/raw
result_bundle_dir: screenshots/results
devices:
  - simulator: iPhone 18 Pro Max
locales: [en-US, el]
appearances: [light, dark]
screenshots: [Home, Search]
test_target: MyAppUITests
test_class: ScreenshotTests
```

Use `workspace` instead of `project` when appropriate. `devices[].tests` can restrict individual devices to selected test methods. `screenshot_appearances: {Home: dark}` pins a named screen; other screens use the configured appearances. Keep reviewed locale and size coverage when changing configuration.

For Apple Watch, use StoreScreens 4.1 or later and `storescreens list --include-watch` (MCP: `list_simulators` with `include_watch: true`). Initialize with `storescreens init --scheme MyWatchApp` and `storescreens setup --scheme MyWatchApp`; the scheme needs a watchOS UI Testing Bundle targeting the Watch app. Use `platform: watchOS` on Watch devices, or let StoreScreens infer it from the simulator. Watch captures use dark appearance; omitted appearances become `[dark]`, and light-only selections are rejected. iOS status-bar and appearance overrides are skipped.

For a Watch app that requires an iPhone, add `companion: iPhone 18 Pro` under the Watch device, using an installed iPhone simulator's name. Set `companion_scheme` to the phone app's separate iOS scheme to build, install, and launch it first. Without that field, prepare the companion app separately. Keep the iPhone target out of the Watch scheme's test build action. StoreScreens pairs and boots both devices without replacing an existing pairing with a different phone. Paired Watch devices run sequentially. Use separate schemes/configurations for phone and Watch captures. The generated harness, raw PNG collection, Watch size labels, locales, CLI, and MCP work with both watch-only and companion apps.

Set `code_signing_allowed: true` for apps whose Keychain or app-group access requires signed simulator entitlements. The default unsigned build can otherwise change the app's access state, including showing a purchase screen instead of the expected content. Use the project's signing configuration; capture does not need App Store Connect credentials.

`storescreens prepare` boots the configured simulators and configures status bars. `--app MyApp.app` additionally installs an existing simulator build. `capture` builds and runs XCUITests, collecting filesystem PNGs by default; `--xcresult` exports attachments instead. Test code must save named screenshots through the generated harness or a compatible existing helper.

`capture --locale el`, `--appearance dark`, and `--only Home,Search` narrow the run while preserving other manifest entries. `--no-parallel` runs one device at a time; `--retries N` retries failed device runs. `derived_data_path` preserves build products. `result_bundle_dir` retains result bundles in a unique directory per invocation, including for failure diagnosis.

`collect --result-bundle TestResults.xcresult --simulator NAME --output screenshots/raw` extracts attachments from an existing test run. Supply its locale and appearance; they cannot be inferred reliably from image pixels.

Version 4 rejects obsolete `render`, `app_store_connect`, `search_preview`, and `upload` blocks. `storescreens migrate-config` saves an exact `.v3-backup` with private file permissions, carries per-slide appearance overrides into capture settings, and writes capture-only YAML. It does not convert layouts into Koubou or delete credentials. Keep backups containing credentials out of Git.
