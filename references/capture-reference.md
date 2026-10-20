# Capture reference

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

`storescreens prepare` boots the configured simulators and configures status bars. `--app MyApp.app` additionally installs an existing simulator build. `capture` builds and runs XCUITests, collecting filesystem PNGs by default; `--xcresult` exports attachments instead. Test code must save named screenshots through the generated harness or a compatible existing helper.

`capture --locale el`, `--appearance dark`, and `--only Home,Search` narrow the run while preserving other manifest entries. `--no-parallel` runs one device at a time; `--retries N` retries failed device runs. `derived_data_path` preserves build products. `result_bundle_dir` retains result bundles in a unique directory per invocation, including for failure diagnosis.

`collect --result-bundle TestResults.xcresult --simulator NAME --output screenshots/raw` extracts attachments from an existing test run. Supply its locale and appearance; they cannot be inferred reliably from image pixels.

Version 4 rejects obsolete `render`, `app_store_connect`, `search_preview`, and `upload` blocks. `storescreens migrate-config` saves an exact `.v3-backup` with private file permissions, carries per-slide appearance overrides into capture settings, and writes capture-only YAML. It does not convert layouts into Koubou or delete credentials. Keep backups containing credentials out of Git.
