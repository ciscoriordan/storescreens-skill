---
name: storescreens
description: "Set up and run storescreens-cli to automate App Store screenshot capture for iOS apps, including rendering captioned/framed App Store-ready screenshots with device bezels, markdown captions, and panoramic backgrounds, uploading screenshots + per-locale metadata (name, subtitle, description, keywords, what's new, promotional text) directly to App Store Connect via the official API, and archiving + uploading the app binary (.ipa) to App Store Connect / TestFlight via xcodebuild + altool with a pinned non-beta Xcode. Also supports targeted screenshots for quick visual checks during development. Use this skill when the user wants to install storescreens-cli, configure screenshot automation for an Xcode project, add UI tests that capture screenshots, write or update ScreenshotTests.swift, run storescreens capture, render framed/captioned App Store screenshots, install device bezels, iterate on caption text and styling, take a quick screenshot of the simulator, configure the App Store Connect API for uploads, upload screenshots to App Store Connect, submit metadata, push to App Store, update what's new / description / keywords for a release, archive the app and upload to TestFlight / App Store Connect, build an .ipa, scaffold upload-build config, or troubleshoot screenshot automation or build upload. Triggers for requests like 'set up App Store screenshots', 'automate screenshots with storescreens', 'add screenshot UI tests', 'capture screenshots for App Store Connect', 'configure storescreens', 'add captions to my App Store screenshots', 'frame my screenshots with device bezels', 'render App Store screenshots', 'take a screenshot of the simulator', 'show me what the app looks like', 'upload screenshots to App Store Connect', 'submit metadata', 'push to App Store', 'update the what's new', 'configure app store connect API', 'set up app store connect credentials', 'scaffold metadata directory', 'storescreens auth init', 'storescreens auth login', 'storescreens metadata init', 'set up the ASC API key', 'archive and upload my app', 'upload a build to TestFlight', 'build and upload the ipa', 'storescreens upload-build', 'upload-build init', 'archive with storescreens', 'submit a binary to App Store Connect', or 'ship a new release build'."
---

# storescreens

storescreens-cli runs XCUITest-based UI tests across simulators, extracts named `XCTAttachment` screenshots from the `.xcresult` bundle, and organizes them by device size. It also renders the raw captures into captioned, framed App Store Connect-ready screenshots (backgrounds, device bezels, markdown captions, per-slide highlights).

Follow the steps below in order. Each step checks state before acting - skip steps that are already complete.

The full workflow is:

1. Install CLI + MCP server (Steps 1-1b)
2. Detect project and generate `storescreens.yml` (Steps 2-3)
3. Set up UI test target + `ScreenshotTests.swift` (Steps 4-6)
4. Verify the build (Step 7)
5. Capture raw screenshots (Step 8)
6. **(optional) Render captioned, framed App Store-ready screenshots (Step 9)**
7. **(optional) Upload screenshots + metadata to App Store Connect (Step 10)**
8. **(optional) Archive + upload the app binary to App Store Connect / TestFlight (Step 10b)**
9. **(optional) Upload to storescreens.app for visual editing (Step 11)**

---

## Step 1: Check / Install storescreens-cli

Run:

```bash
storescreens --help 2>&1
```

Print the full output - it shows the available subcommands and options so the user knows what's available. If the command is not found, install it:

```bash
brew tap ciscoriordan/tap && brew install storescreens
# or
curl -fsSL https://raw.githubusercontent.com/ciscoriordan/storescreens-cli/main/install.sh | sh
```

---

## Step 1b: MCP Server Setup (REQUIRED - do this before anything else)

**The storescreens MCP server is the preferred way to run captures.** It gives you structured tools (`capture`, `get_capture_status`, `list_screenshots`, `get_screenshot`, etc.) instead of parsing CLI output in Bash. **Always set this up.**

**Check if already connected:** Look at your available MCP tools. If you see `capture`, `get_capture_status`, `list_screenshots`, etc. from a `storescreens` MCP server, it's already working - skip to Step 2.

**If MCP is NOT connected, you MUST set it up now:**

1. Check if `.mcp.json` exists in the project root. If it does, read it.

2. **If `.mcp.json` doesn't exist**, create it:

```json
{
  "mcpServers": {
    "storescreens": {
      "command": "storescreens-mcp",
      "args": []
    }
  }
}
```

3. **If `.mcp.json` already exists** but doesn't have a `storescreens` entry, add the `storescreens` server to the existing `mcpServers` object. Do not overwrite other MCP servers.

4. **After creating or updating `.mcp.json`, STOP and tell the user:**

> **Action required: Please exit and relaunch Claude Code from this project directory.**
>
> I just created/updated `.mcp.json` to add the storescreens MCP server. Claude Code only reads project-level `.mcp.json` files on startup - running `/mcp` inside the current session won't pick it up.
>
> After relaunching, run `/storescreens` again and I'll continue from where we left off.

**Do not continue with further steps until MCP is confirmed working.** The MCP server provides `capture`, `get_capture_status`, `check`, `list_screenshots`, `get_screenshot`, `take_screenshot`, `read_config`, `write_config`, and other tools that make the entire workflow dramatically better. Without it, you're stuck parsing raw xcodebuild output in Bash.

---

## Step 2: Detect project

Find the `.xcworkspace` or `.xcodeproj` in the working directory. Identify the scheme name (usually matches the app name). You'll need both for `storescreens.yml` and the `xcodebuild` verify command later.

Also check for XcodeGen: if `project.yml` exists at the repo root, this project is XcodeGen-managed. The `.xcodeproj` is a generated artifact, so any target changes must go in `project.yml` and then `xcodegen generate` regenerates the project. Note this state (keep a note or variable like `usesXcodeGen = true`) and branch accordingly in Steps 4 and 7.

---

## Step 3: Check for existing `storescreens.yml`

**If `storescreens.yml` already exists, skip `storescreens init` and proceed directly to Step 4.** Do not re-run init or ask config questions unless the user explicitly asks to change devices, locales, or appearances.

Only run `storescreens init` when:
- `storescreens.yml` does not exist yet (fresh project), or
- the user explicitly asks to reconfigure or reinitialise

When you do run init:

```bash
storescreens init
```

Print the full output. If `.mcp.json` was created or updated, tell the user: **exit and relaunch Claude Code from this project directory** to pick up the new MCP config. Running `/mcp` inside the current session is not enough - project-level `.mcp.json` files are only read on startup.

After running `storescreens init`, read `storescreens.yml` and review the config with the user. Show the current values and ask:

1. **Devices** - Are these the right simulators? (Show the current list)
2. **Appearances** - Currently set to `[current value]`. Light only, or both light and dark?
3. **Locales** - Currently `[current value or "not set"]`. Do you need screenshots in multiple languages?

Make any requested changes by editing `storescreens.yml` directly, then continue to Step 4.

If `storescreens.yml` does not exist yet (fresh project), ask the user these questions before running `storescreens init`:

1. **iPhone devices** - Present these options and ask the user to choose:

   - **6.9" only (recommended)** - `iPhone 17 Pro Max`. App Store Connect auto-fills the 6.5" slot from 6.9" screenshots, so this single device covers both. This is all most apps need.
   - **6.9" + 6.5"** - Add `iPhone 11 Pro Max` or `iPhone Xs Max` if they want *distinct* screenshots in the 6.5" slot rather than the auto-scaled 6.9" ones. Note: no current simulator produces 6.5" (1242×2688) - only these older simulators do.
   - **More sizes** - App Store Connect also has slots for 6.3", 6.1", 5.5", 4.7", 4", and 3.5". Ask if they want any of these. Corresponding simulators: `iPhone 17 Pro` (6.3"), `iPhone 16` (6.1"), `iPhone 8 Plus` (5.5"), `iPhone SE (3rd generation)` (4.7"). Sizes smaller than 4.7" are very old and rarely needed.
   - **Skip iPhone for now** - valid choice; they can add iPhone later.

   Note: App Store Connect has **no 6.7" slot** - do not suggest `iPhone 16 Plus`.

2. **Appearances** - Light mode only, or also dark mode?

Once you have the iPhone answers, write `storescreens.yml` with the iPhone devices. See `references/config-reference.md` for the full schema. The `test_target` and `test_class` should be `<AppName>UITests` and `ScreenshotTests` - you'll confirm these in Step 4.

**IMPORTANT: Always include `derived_data_path` in the config.** Without it, every capture run recompiles everything from scratch (including all SPM packages), which can add 3-5+ minutes to each run. Set it to `~/.storescreens-cache/<AppName>`:

```yaml
derived_data_path: ~/.storescreens-cache/<AppName>
```

If `storescreens.yml` already exists but is missing `derived_data_path`, add it now.

---

## Step 3b: iPad devices (separate question)

Ask the user separately whether they want iPad screenshots. Don't push it - it's fine to skip and add later.

App Store Connect iPad slots:
- **13"** (required when iPad is supported) → `iPad Pro 13-inch (M5)` - **recommend this as the starting point**
- **11"** → `iPad Pro 11-inch (M5)`
- **12.9"**, **10.5"**, **9.7"** - legacy slots requiring older simulator runtimes; rarely needed

If they want iPad, add the chosen simulators to `devices` in `storescreens.yml`. Also note: if their app has iPad support disabled in Xcode (Supported Destinations), they'll need to re-enable it there first (General tab → Supported Destinations → add iPad).

---

## Step 4: Check for a UI test target

Look for an existing UI test target by searching for `*UITests` directories or `.swift` files containing `XCTestCase` in a test target folder.

**If a UI test target already exists:**

Check whether `ScreenshotTests.swift` exists inside it. If it does, skip to Step 6. If it doesn't, proceed to Step 5 to write the test file.

**If no UI test target exists and the project is XcodeGen-managed (`project.yml` exists):**

Don't ask the user to create the target in Xcode. Editing the generated `.xcodeproj` directly is pointless because `xcodegen generate` wipes those changes. Add the target to `project.yml` yourself.

Append to the `targets:` block:

```yaml
  <AppName>UITests:
    type: bundle.ui-testing
    platform: iOS
    deploymentTarget: "<same as the app target>"
    sources:
      - path: <AppName>UITests
    dependencies:
      - target: <AppName>
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: <app bundle id>.uitests
      GENERATE_INFOPLIST_FILE: YES
```

Also add the test target to the app scheme's `test:` block so `xcodebuild test` can discover it:

```yaml
schemes:
  <AppName>:
    build:
      targets:
        <AppName>: all
    test:
      targets:
        - <AppName>UITests
```

Then run `xcodegen generate` to regenerate the `.xcodeproj`. After that, proceed to Step 5.

**If no UI test target exists and the project is not XcodeGen-managed:**

Tell the user they need to create one manually in Xcode (this cannot be done from code):

> Please add a UI test target in Xcode:
> 1. File → New → Target → UI Testing Bundle
> 2. Name it `<AppName>UITests`
> 3. Set "Target to be Tested" to your app
> 4. Click Finish
>
> Xcode will generate a placeholder `<AppName>UITestsLaunchTests.swift` - delete that file.
> Then come back and I'll write `ScreenshotTests.swift` for you.

Wait for the user to confirm before continuing.

---

## Step 4b: Preflight check (run by the setup wizard)

The `storescreens setup` wizard automatically runs `storescreens check` before generating the test file. If it finds issues:

- **Errors** (e.g. unguarded CloudKit, missing `.toolbarVisibility` iPad guard): the wizard asks `Continue setup anyway? [y/N]`. Default is **No** - fix errors first, then re-run `storescreens setup`.
- **Warnings** (e.g. missing accessibility identifiers, unguarded review prompts): the wizard asks `Continue setup with warnings? [Y/n]`. Default is **Yes** - warnings are informational and don't block setup, but should be addressed before capture.

The `missing-accessibility-identifier` warning fires when a UI test file references an identifier (e.g. `waitForElement(id: "saveButton")` or `app.buttons["saveButton"]`) that has no corresponding `.accessibilityIdentifier("saveButton")` in the app source. Help the user add the missing identifier to their view before continuing.

The `localized-nav-button` warning fires when a test uses `navigationBars.buttons["Back"]` (or any title-cased label) to find a navigation bar button. Localized titles change per locale - "Back" becomes "Atrás" in Spanish, "Zurück" in German, etc. - causing test failures when running multi-locale screenshot capture. Fix: use `app.navigationBars.buttons.element(boundBy: 0)` for the system back button (it is always the first/leftmost button), or add an `.accessibilityIdentifier` to a custom button and query by that instead.

**When reporting findings, handle each warning/error category separately** - present one category, ask if the user wants to fix it now, fix it if yes, then move to the next category. Do not bundle multiple categories into a single question.

---

## Step 5: Check / configure screenshot mode in the app

Before writing the test file, check whether the app already handles a screenshot mode launch argument (search for `--uitesting` or `--uitesting` in the Swift source).

If it does not, explain what needs to be added and help the user add it to the appropriate place (app `init`, `@main` struct, or root view `.task`):

```swift
if ProcessInfo.processInfo.arguments.contains("--uitesting") {
    // Force premium/subscriber access - skip StoreKit verification
    // subscriptionService.isSubscribed = true

    // Disable animations for fast, deterministic captures
    UIView.setAnimationsEnabled(false)

    // Reset persisted UI state if needed
    // UserDefaults.standard.removeObject(forKey: "onboardingDone")
}
```

Also guard any `checkEntitlements()` or StoreKit calls so they don't run in screenshot mode. **Wrap the specific call - do not add a `guard...return` at the top of the function.** An early return silently skips everything below it, including state setup like `isInitialized = true`, which can leave the app in a broken state during tests.

```swift
// Good - wraps just the entitlement call:
if !ProcessInfo.processInfo.arguments.contains("--uitesting") {
    checkEntitlements()
}

// Bad - skips ALL code below this line, including isInitialized = true:
// guard !ProcessInfo.processInfo.arguments.contains("--uitesting") else { return }
```

Confirm with the user which (if any) subscription/entitlement service needs to be bypassed.

---

## Step 6: Write `ScreenshotTests.swift`

Ask the user to describe the screens they want to capture and the navigation flow between them. Use their description to write a tailored test file.

Key requirements for the test file:

- `app.launchArguments = ["--uitesting"]`
- Wait for the app to fully load before the first screenshot: `XCTAssertTrue(element.waitForExistence(timeout: 20))`
- Name screenshots with their meaningful identifier only: `"Home"`, `"Detail"`, `"MealPlan"`. No numeric prefixes. The capture pipeline stamps each output PNG's mtime and creationDate in the order of the `screenshots:` list in `storescreens.yml`, so `ls -t` and Finder's "Date Created" sort match the configured display order without needing `01_` / `02_` prefixes.
- Use accessibility identifiers for all element lookups - ask the user what identifiers exist or help them add them. Avoid fragile text/position-based queries.
- Always `waitForExistence(timeout:)` before tapping any element
- Clean up any state changed during the test (e.g. delete test permits/data added during the flow) at the end

After you decide the screens, write the same list under top-level `screenshots:` in `storescreens.yml`. That list is the single source of truth for display order: it drives capture filtering, HTML preview ordering, render order, and mtime stamping.

Use `assets/ScreenshotTests.swift.template` as a starting point. Place the file inside the `<AppName>UITests/` folder.

For XcodeGen-managed projects (`project.yml` exists): the file goes in `<AppName>UITests/` matching the `sources:` path in `project.yml`. No "Add Files to target" step is needed because XcodeGen picks up every `.swift` file under that directory on the next `xcodegen generate`. Run `xcodegen generate` after writing the file, then continue to Step 7.

For projects without XcodeGen, tell the user:

> Add `ScreenshotTests.swift` to the Xcode target:
> Right-click the `<AppName>UITests` group → Add Files to "[project]" → select `ScreenshotTests.swift` → confirm the target membership checkbox is checked.

---

## Step 7: Verify the build

If the project is XcodeGen-managed, run `xcodegen generate` first so the `.xcodeproj` reflects the new test target and any `ScreenshotTests.swift` additions. Any time you edit `project.yml` or add/remove test files, regenerate before invoking `xcodebuild`.

Pipe xcodebuild output to a log file so you can inspect errors:

```bash
xcodebuild build-for-testing \
  -workspace MyApp.xcworkspace \
  -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | tee build.log
```

If this fails, check `build.log` for the full error output and fix before running capture.

---

## Step 8: Capture

### Targeted screenshot (quick visual check)

When you need to verify a UI change visually, **do NOT run the full screenshot suite.** Use the `take_screenshot` MCP tool instead. It captures the current simulator screen in under a second - no build, no tests.

**When to use `take_screenshot`:**
- You edited a SwiftUI view and want to see the result
- You want to confirm a layout change before committing
- The simulator is already running your app

**When to use full `capture` instead:**
- You need final App Store screenshots
- You need multiple devices or locale variants
- The app is not running and you need it built from source

**Using the MCP tool:**

If the simulator is already running your app:

```
take_screenshot(simulator: "iPhone 17 Pro")
```

The image renders inline immediately. If no simulator name is given, it uses the first booted simulator.

If the simulator is not booted:

```
take_screenshot(simulator: "iPhone 17 Pro", boot: true)
```

**Using the CLI (if MCP is not available):**

```bash
storescreens screenshot --simulator "iPhone 17 Pro" --output screenshot.png
# Boot variant:
storescreens screenshot --simulator "iPhone 17 Pro" --boot --output screenshot.png
```

**If you need to navigate to a specific screen** that requires UI test interaction, the old approach still works: temporarily disable the main test, write a focused `testQuickVisual()` method, run `capture`, then clean up. But for a simple "what does the current screen look like" check, `take_screenshot` is much faster.

### Choosing the right screenshot tool

If Xcode 26.3+ is running and its MCP server is available (you'll have tools like `RenderPreview`, `BuildProject`, etc.), you have three options for visual checks:

| Tool | What it captures | When to use |
|------|-----------------|-------------|
| Xcode `RenderPreview` | A single SwiftUI `#Preview` | Checking an individual view's layout. No simulator needed. |
| storescreens `take_screenshot` | The full running app in a simulator | Checking the app with real data, navigation state, and system chrome. |
| storescreens `capture` | Full App Store screenshots across devices | Final screenshots for App Store Connect. Multiple devices, locales, appearances. |

Use `RenderPreview` when you want to check a single view in isolation (it renders SwiftUI previews, not the running app). Use `take_screenshot` when you need to see the actual app running with real state. Use `capture` for the final App Store screenshot suite.

### Full capture

**Use the MCP `capture` tool.** If the storescreens MCP server is not connected, **STOP - go back to Step 1b and set it up.** Do not proceed with Bash capture unless the user explicitly says they don't want MCP. The MCP tools provide structured progress, inline screenshot previews, and eliminate the need to parse raw xcodebuild output.

Check whether the `storescreens` MCP server is connected (you'll have tools like `capture`, `get_capture_status`, `list_screenshots` available). If it is, call the `capture` tool. Only fall back to Bash if the user explicitly declines MCP setup.

**If using MCP:**

1. Call the `capture` tool - it returns a `taskId` immediately and starts capture in the background.
2. **Poll interval: follow what `get_capture_status` tells you.** Each response ends with either "Wait 30 seconds" (build phase) or "Wait 5 seconds" (test phase). Always use the interval the server specifies - never switch on your own based on which devices have finished or what you see in the output.
   ```bash
   sleep 30   # when server says "Wait 30 seconds"
   sleep 5    # when server says "Wait 5 seconds"
   ```
   Then call `get_capture_status(task_id: "<taskId>")`. Repeat until `status: completed` or `status: failed`. Never call `get_capture_status` back-to-back without the sleep in between.
3. **What to show the user while polling:**
   - After each poll, output any **new** `✓ [Device] [Slot] screenshot_name` lines that weren't in the previous poll response. This is the primary progress signal - output them as-is so the user can see screenshots being captured in real time.
   - Also surface these meaningful transitions when they first appear: `Testing started`, `** TEST SUCCEEDED **`, `** BUILD FAILED **`, locale changes (`● Locale: ...`), and device completion lines (`✓ DeviceName: N screenshots`).
   - Do not repeat lines that were already shown in a previous poll. Track what you've output and only emit new lines.
   - **"last activity Xs ago" does NOT mean the run is stuck.** xcodebuild writes build output to stdout (which the MCP tracks), but once the build phase completes and tests start running, xcodebuild writes results directly to the `.xcresult` bundle on disk - **no stdout output is produced during test execution**. A "last activity 300s ago" status is normal and expected during the test phase. Keep polling - do not report a stall to the user unless the run exceeds 20 minutes total. **If the run HAS exceeded 20 minutes and all device tests have already passed** (you saw `Test case '...' passed` for every device in the status output), the MCP server is stuck in a post-test deadlock. Tell the user: "The capture process is stuck. Please run `pkill -f storescreens-mcp` in a terminal, then exit and relaunch Claude Code so the MCP server restarts, then re-run capture."
   - **Detect the stuck-buffer problem.** If the output is identical across any 2 consecutive polls **and** `last activity` has not advanced, immediately call `list_screenshots` AND check the file timestamps (via `ls -la` on the output directory) to verify the screenshots are from the *current* run - not a previous one. Compare the file modification times against when the current capture started. Only report screenshots as complete if they are newer than the capture start time. If timestamps are stale, the run is still in progress - keep polling.
   - **"0 screenshots" for a completed device is a red flag.** If a poll response shows a device reporting "Tests completed" or "0 screenshots", treat this as a likely failure and immediately inspect the per-device log. Do NOT continue polling silently. Read the log:
     ```bash
     cat <output_dir>/logs/test-<UDID-prefix>.log | grep -E "error:|FAILED|fatalError|Could not resolve"
     ```
     If errors are found, report them to the user immediately.
   - **Device failures in logs during polling:** `get_capture_status` will include a "Device failures detected in logs" section if it finds error patterns in any per-device log file. When this appears, immediately report the failure to the user - do not wait for the run to complete. If some devices have failed and others are still running, tell the user: "Device X failed (see error below). Other devices are still running. Do you want to abort or wait for them to finish?" Then wait for the user's answer before taking action.
4. On completion, report results: how many screenshots per device. Output a clickable preview link using the absolute path: `file://<absolute-path-to-project>/<output_dir>/preview.html`. On failure, read the log.

**If using Bash (MCP unavailable):**

```bash
storescreens capture
```

The CLI streams full xcodebuild output to stdout (auto-detected in non-TTY mode). The command output will be large (compile steps + test output).

**IMPORTANT - after the command finishes, ALWAYS print these two messages as your own text output (NOT inside a bash block):**

1. Tell the user they can expand the output block above to see the full xcodebuild build and test log.
2. Show the tail command for the log files using the absolute path to the project's output dir:

```
To follow logs in real time on future runs, open another terminal:
  tail -f <absolute-path-to-project>/<output_dir>/logs/test-*.log
```

Then report the results: how many screenshots captured, whether tests passed/failed. Output a clickable preview link using the absolute path: `file://<absolute-path-to-project>/<output_dir>/preview.html`.

If tests failed, read the log file to diagnose:

```bash
cat <absolute-path-to-project>/<output_dir>/logs/test-*.log
```

Output lands in `storescreens-output/` with device name as a filename prefix. Light and dark mode get separate directories:

```
storescreens-output/
├── preview.html           ← open: file://<absolute-path-to-project>/<output_dir>/preview.html
├── manifest.json
├── logs/
│   └── test-<device>.log  ← one per device
├── light/
│   ├── iPhone_6.9_Home.png
│   ├── iPhone_6.9_Detail.png
│   ├── iPhone_6.3_Home.png
│   └── ...
└── dark/
    ├── iPhone_6.9_Home.png
    ├── iPhone_6.9_Detail.png
    └── ...
```

Screenshot names are the meaningful identifier only (`Home`, `Detail`, `Search`). The capture pipeline stamps each output PNG's mtime + creationDate in the order of the top-level `screenshots:` list in `storescreens.yml`, so `ls -t storescreens-output/light/` and Finder's "Date Created" sort match the configured App Store display order without numeric prefixes.

---

## Step 9: Render captioned, framed screenshots (optional)

Raw captures from Step 8 are functional but plain - just the app UI with no marketing chrome. The render pipeline turns them into framed, captioned images ready to upload to App Store Connect: background, device bezel, images (logos, badges), laurel award overlays, marketing captions with markdown, per-slide highlights.

**When to offer this:** any time the user wants App Store Connect-ready screenshots with captions or device frames. The render is opt-in (off by default) but most users want it before shipping.

**Rendering runs automatically after `storescreens capture`** when `render.enabled: true` is in `storescreens.yml`. It can also be invoked standalone with `storescreens render`, which skips recapture and is the right loop for iterating on caption text, colors, fonts, etc. Pass `--no-render` to `storescreens capture` to skip rendering on one run.

### 9a. Design the narrative first

Before touching YAML, ask the user:

1. **What's the hero story?** Typically the first 2-3 slides in App Store Connect do 90% of the conversion work. What's the single most important thing to communicate? Often this becomes slide 1's title.
2. **What's the slide order?** Get a numbered list. This list goes verbatim into the top-level `screenshots:` key in `storescreens.yml` - the render pipeline walks it in this exact order (no alphabetical reordering anywhere).
3. **Bezels or no bezels?** `chrome.style: bezel` is the polished App Store look but needs bezel DMGs from Apple Design Resources. `chrome.style: stroke` looks clean, has zero external assets, and is a fine default while iterating.
4. **Light, dark, or both?** Most render fields (`background.image`, `background.color`, `images[].path`, `laurels[].color`) accept `{ light:, dark: }` variants.
5. **Any brand fonts?** Four tiers available: `system` (SF Pro), installed family name, local `.otf`/`.ttf` path, `{ google: "Inter" }` (auto-downloaded), or `{ regular:, bold:, italic:, bold_italic: }` bundle for correct markdown bold/italic.

### 9b. Write the screenshots list

Add the authoritative order at the top level of `storescreens.yml`:

```yaml
screenshots:
  - Home
  - Search
  - Detail
  # ...
```

This list is the single source of truth for display order. It drives capture filtering, render order, HTML preview order, and mtime stamping on the output PNGs (first in list = most recent mtime, so `ls -t` and Finder's "Date Created" both match). A panoramic background's left edge pins to the first entry here. An image with `placement: first_only` (also the default for `above_title`) draws on the first entry here.

### 9c. Install bezels (only if using `chrome.style: bezel`)

Apple licenses the bezel PSDs for use with their products. StoreScreens does not redistribute them - the user downloads once, then the importer extracts what it needs.

1. Open <https://developer.apple.com/design/resources/> in a browser. Scroll to "Product Bezels". Download the DMG for each device family needed (iPhone, iPad, MacBook).
2. Double-click each downloaded DMG to mount it. They appear under `/Volumes/`.
3. Run:

```bash
storescreens bezels import
```

This auto-scans `/Volumes/` for Apple Design Resource DMGs, classifies PSDs by screen pixel dimensions, applies any `model_preference` / `colorway_preference` from `render.chrome`, and writes transparent-screen PNGs + JSON sidecars to `~/Library/Application Support/storescreens/bezels/` (user-global).

Flags:

- `--volume PATH` - use an explicit mount path instead of auto-scanning. Repeatable.
- `--yes` - skip the "about to write N files, ok?" confirmation.
- `--verbose` - log every PSD considered and why it won or lost.

Inspect afterwards:

```bash
storescreens bezels check     # list installed bezels + canonical keys
storescreens bezels path      # print the install directory
```

Per-project override: drop PNG + JSON sidecar files into `./bezels/` next to `storescreens.yml`. Project-local bezels take precedence over user-global ones.

### 9d. Add a `render:` block - build it up incrementally

**Fast path - start from a named template.** If the user wants a sensible default look instead of hand-tuning every field, pick a built-in template. List them:

```bash
storescreens templates
```

Then seed the config:

```yaml
render:
  enabled: true
  template: sahara     # or: ascent, all_the_wiser, ethereal, midnight, pinecrest, blueprint, sunset_blvd
  output_dir: ./storescreens-framed
```

The template fills in `background`, `caption`, and `chrome` defaults (curated palette + typography + a procedural background pattern where appropriate). Anything the user writes explicitly in the same `render:` block still wins over the template — treat the template as "defaults I can override," not a lock-in. The sections below still apply when the user wants to tune individual fields.

Once picked, continue with per-slide captions (Step 9d's "slides:" block below). Most users won't need the background / scrim / chrome sections when using a template.

Don't dump a huge render block on the user and hope it renders well. Add fields one at a time, run `storescreens render` after each, and open `preview.html` to inspect.

Start with the minimum:

```yaml
render:
  enabled: true
  output_dir: ./storescreens-framed
  chrome:
    style: stroke         # quick-iterate; swap to bezel once bezels are imported
```

Add a background (solid color or image, with optional light/dark variants):

```yaml
  background:
    color: "#1a1a2e"
    # or a vertical gradient, top → bottom:
    # color: ["#1a1a2e", "#4a1e5c"]
    # or an image (single wide image = panoramic, sliced across all slides):
    # image: ./marketing/panorama.jpg
    # fit: cover            # cover | contain | tile
    # align: center         # top | center | bottom
    # with appearance variants:
    # image:
    #   light: ./bg-light.png
    #   dark:  ./bg-dark.png
```

**Panoramic background**: if `background.image` is a single image wider than one slide, the renderer slices it across all slides in `screenshots:` order. Left edge of image pins to left edge of the first slide. Slides concatenate side-by-side in the App Store Connect gallery with a continuous image behind them.

Add a scrim to tame a busy background image:

```yaml
  scrim:
    color: "#000000"
    opacity: 0.35
    # or a vertical opacity gradient instead of flat opacity:
    # gradient:
    #   top_opacity: 0.0
    #   bottom_opacity: 0.6
```

Add image overlays (logos, badges - up to 2 per slide, dropped near the caption block):

```yaml
  images:
    - path: ./marketing/logo-wordmark.svg
      position: above_title    # above_title | below_title | above_subtitle | below_subtitle
      align: center            # left | center (default) | right
      max_height_pct: 6        # % of canvas height; default 8
      placement: first_only    # first_only | all | none
```

`position` defaults to `above_title` (matches the legacy logo placement). `placement` defaults to `first_only` for `above_title` and `all` for every other slot. Two entries in the same slot stack horizontally if they share an `align`, or place independently if they don't.

Optionally add laurel "award badge" overlays - left/right laurel SVGs around centered title/subtitle text:

```yaml
  laurels:
    - title: "Editors' Choice"
      subtitle: "App Store"
      color: "#FFD66B"
      position: below_subtitle
      max_height_pct: 11
```

`title` is bold by default and `subtitle` is regular; override with `title_style:` / `subtitle_style:` which accept the same fields as `caption.title`. Up to 2 per slide, same slot rules as `images`.

Backwards compatibility: the legacy `logo:` block (single path + placement) still renders, treated as a single image at `above_title`. New configs should prefer `images:`. Setting `images: []` explicitly suppresses the legacy fallback.

Add captions. Each role (`title`, `subtitle`) is optional. `min_font_size_pct` lets the renderer auto-shrink a long title to fit before it wraps:

```yaml
  caption:
    title:
      font: system                  # or "Helvetica Neue" / path / bundle / google
      weight: bold                  # thin|light|regular|medium|semibold|bold|heavy
      italic: false
      font_size_pct: 5.5
      min_font_size_pct: 3.0
      color: "#ffffff"
      align: center                 # left | center | right
    subtitle:
      font: system
      weight: regular
      font_size_pct: 3.2
      min_font_size_pct: 2.0
      color: "#ffffff"
      align: center
    spacing_pct: 1.0
    min_height_pct: 22              # reserved area at top of canvas for captions
    padding_pct: 5
```

Then fill in per-slide caption text:

```yaml
  slides:
    "Home":
      caption: "Your recipes, organized."        # shorthand: title only
    "Search":
      caption:                                    # array: strict line breaks
        - "Find anything"
        - "in *seconds*."
    "Detail":
      caption:                                    # full object
        title: "Every **detail**, at a glance."
        subtitle: "Powered by AI"
        highlights:
          - { match: "detail", color: "#feb909", weight: heavy, italic: true }
```

**Caption shorthand:**

| Form | Meaning |
|------|---------|
| `caption: "text"` | title only, auto-wraps at canvas width |
| `caption: ["line 1", "line 2"]` | title with strict line breaks - items never wrap inside themselves |
| `caption: { title:, subtitle:, highlights: }` | full object |

**Markdown in captions:** `**bold**`, `*italic*`, `` `code` ``, `[text](url)` all work in title and subtitle strings. For correct bold/italic rendering, use a `bundle`-form font so the real bold and italic faces are used.

**Highlights:** override color / weight / italic on literal substring matches. Case-sensitive. Applies to all occurrences in both title and subtitle. Each highlight sets any combination of `color`, `weight`, `italic`.

**Chrome options:** `style: none | stroke | bezel`. `fit: width (default) | height | contain` controls how the device fills the canvas - `width` lets a tall device bleed past the bottom (classic App Store look). `corner_radius: auto` or a fixed px value. `model_preference` and `colorway_preference` influence which bezel gets picked at `bezels import` time.

### 9e. Iterate

```bash
storescreens render          # re-renders from existing captures, no recapture
open storescreens-framed/preview.html
```

Standalone render is sub-second per slide. Tweak captions, colors, fonts in `storescreens.yml`, re-run, reload the preview. No simulator reboot needed.

To force a fresh capture + render from scratch:

```bash
storescreens capture         # captures, then renders (since render.enabled: true)
```

To capture without rendering (for diagnosing a capture issue):

```bash
storescreens capture --no-render
```

### 9f. Reference

Full schema with every field, every enum value, and a complete real-world example: `references/render-reference.md`.

---

## Full App Store Connect API coverage (v2.12.0+)

Beyond the screenshot + metadata + build-upload workflow, storescreens-cli wraps the full App Store Connect API across seven resource families as both CLI subcommands and MCP tools, sharing the same `~/.storescreens/asc-credentials.yml` credentials. If the user asks for anything App Store related and the operation isn't covered by `submit` / `upload-build` / `status`, check whether one of these families already handles it before reaching for raw `curl` or unaffiliated tooling:

| Family | CLI prefix | MCP tool prefix | What's in it |
|---|---|---|---|
| TestFlight | `storescreens testflight ...` | `testflight_*` | Beta groups, beta testers, invitations, prerelease versions, builds, build-beta-detail, build-beta-notifications, beta-app/build-localizations, beta-app-review, beta-license-agreement, beta-tester-metrics, build-bundles, build-icons |
| In-App Purchases (V2) | `storescreens iap ...` | `iap_*` | One-time IAPs: products, localizations, price points + schedules, submissions, content-hosting, images, review-screenshots, promotional-images, promoted-purchases |
| Subscriptions | `storescreens subscriptions ...` | `subs_*` | Auto-renewing subs: groups, group-localizations, subscriptions, localizations, prices + price-points, offer-codes (one-time + custom + prices), promotional-offers (+ prices), availability, submissions, review-screenshots, images |
| Customer Reviews | `storescreens reviews ...` | `reviews_*` | List with rich filters (territory / rating / answered / edited), get one, post / update / delete the developer's response, list-unanswered helper |
| Reports | `storescreens reports ...` | `reports_*` | Sales reports (TSV), finance reports (CSV), analytics requests + reports + instances + segments, perf-power metrics, diagnostic signatures |
| Users + Developer Portal | `storescreens users ...` / `storescreens devportal ...` | `users_*` / `devportal_*` | Team users, invitations, user-visible-apps; certificates, profiles, devices, bundle-ids + capabilities |
| Marketing surfaces | `storescreens previews`, `storescreens app-clips`, `storescreens cpp`, `storescreens events`, `storescreens experiments`, `storescreens encryption-decl`, `storescreens routing-coverage` | `preview_*`, `app_clip*`, `cpp_*`, `events_*`, `experiments_*`, `encryption_decl_*`, `routing_coverage_*` | App Previews (videos), App Clips (+ experiences + headers), Custom Product Pages, in-app App Events, App Store Version Experiments V2 (A/B), App Encryption Declarations, Routing App Coverage |
| Game Center | `storescreens game-center ...` | `gc_*` | Achievements (+ localizations + images + releases), leaderboards (+ localizations + images + releases), leaderboard sets (+ localizations + images + members + member-localizations + releases), matchmaking (queues + rule-sets + rules + team-configurations + test-match), game-center detail, app versions, groups + localizations |
| Xcode Cloud (CI/CD) | `storescreens xcode-cloud ...` | `xcc_*` | CI products, workflows (CRUD), build runs (start, cancel, retry, list-for-product/workflow), build actions, artifacts (download), issues, test results, macOS + Xcode version catalogs, SCM repositories + git references + pull requests + providers |
| Alternative Distribution (EU DMA) | `storescreens alt-dist ...` | `altdist_*` | EU-marketplace distribution: keys, packages (+ versions + deltas + variants), domains, marketplace search detail, marketplace webhooks; submission-state ops (activate / disable / validate) |
| Apple Pay + Sandbox + misc | `storescreens apple-pay ...`, `storescreens sandbox ...`, `storescreens resource-limits ...`, `storescreens diagnostic-sessions ...` | `applepay_*`, `sandbox_*`, `resource_limits_*`, `app_hashes_*`, `diagnostic_sessions_*` | Apple Pay: pass type IDs + certificates + merchant domains. Sandbox: testers (with clear-history + modify-renewal-rate actions), tester-apps. Plus team resource quotas, app hashes, Xcode Instruments diagnostic sessions |
| Webhooks (general-purpose) | `storescreens webhooks ...` | `webhooks_*` | Subscribe an HTTPS endpoint to live ASC events (build status, review state, app availability, TestFlight, IAP). CRUD on webhooks, list/get/resend on webhookDeliveries, create on webhookPings. Different from the EU-only `marketplaceWebhooks` covered by `altdist`. |
| Build Uploads (API-native) | `storescreens build-uploads ...` | `build_uploads_*` | Alternative to altool for uploading .ipa binaries: buildUploads + buildUploadFiles resources, 3-phase reservation + chunked PUT + commit, plus a high-level `upload-ipa` convenience that handles the whole flow. |
| Accessibility Declarations | `storescreens accessibility ...` | `accessibility_declarations_*` | Per-device-family Accessibility Nutrition Labels (VoiceOver, Voice Control, captions, dark interface, differentiate without color, larger text, reduced motion, sufficient contrast, audio descriptions). CRUD plus `publish` PATCH for DRAFT → PUBLISHED. |
| Background Assets + Release Control | `storescreens background-assets ...`, `storescreens version-release ...` | `bg_assets_*`, `phased_release_*`, `version_promotion_*`, `version_release_request_*`, `end_preorder_*` | 200GB-per-app post-install asset download (chunked upload, version per build channel) + App Store release control (phased releases, promo carousel opt-in, manual release requests, end-pre-order). |
| Game Center Activities + Challenges | `storescreens game-center-v2 ...` | `gc_activities_*`, `gc_challenges_*`, `gc_*_versions_v2_*`, `gc_*_submissions_*` | Activities (in-game events / tournaments) + Challenges (player-vs-player), with images / localizations / versions each. V2 versioning of achievements / leaderboards / leaderboard sets. Sandbox-only test-submission endpoints. Separate `game-center-v2` parent from Wave 2's `game-center`. |
| Modern TestFlight Feedback + Beta Recruitment + Beta App Clip + IAP Offer Codes | `storescreens beta-feedback ...`, `storescreens beta-recruitment ...`, `storescreens beta-app-clip ...`, `storescreens iap-offer-codes ...` | `beta_feedback_*`, `beta_crash_logs_*`, `beta_recruitment_*`, `beta_app_clip_invocations_*`, `iap_offer_codes_*` | Modern TF feedback API (crash + screenshot submissions, downloadable crash logs), automatic-recruitment criteria, App Clip Beta invocation configs, one-time-IAP offer codes (custom + one-time-use). |
| Subscription / Review / ASC late-2025 grab-bag | `storescreens subs-extras ...`, `storescreens review-extras ...`, `storescreens asc-extras ...` | `subext_*`, `revext_*`, `ascext_*` | Subscription intro offers, win-back offers (+ prices), grace periods, group submissions, price-point standalone gets. Customer review summarizations (Apple Intelligence) + review attachments with 3-phase upload. Merchant IDs, nominations, app tags, custom EULAs, Android→iOS user-migration mapping, in-app actors, app price points V3 + equalizations, App Clip advanced experience images, IAP availabilities + content metadata, territory availability update. |

Discovery:
- MCP: call `tools/list` and grep tool names for the prefix above.
- CLI: `storescreens <family> --help` shows every subcommand and flag.
- Full docs with examples and YAML/JSON output: see the "App Store Connect API coverage" section in storescreens-cli's README.

When the user describes an ASC operation, prefer the storescreens MCP tool or CLI subcommand over Bash + curl + JWT minting. The credentials, JWT handling, retries, pagination, and JSON:API quirks are already taken care of.

---

## Step 10: Upload to App Store Connect (optional)

Once the user is happy with the rendered output from Step 9, they can push everything (screenshots + per-locale metadata like description, what's new, keywords, etc.) straight to App Store Connect via Apple's official API.

**When to offer this:** when the user is ready to ship a version and wants to avoid manually re-uploading screenshots and re-typing localized copy for each release. Opt-in; do not run without an explicit go-ahead.

**Review submission:** by default `submit` uploads and stops, leaving you to click "Submit for Review" in App Store Connect yourself. Set `submit_for_review: true` in the `submit:` block to also submit the version for App Review automatically after uploads finish (internally uses Apple's `reviewSubmissions` 3-step flow plus auto-cleanup of any prior stuck submission: cancels rejected `UNRESOLVED_ISSUES`, adopts empty/own-version `READY_FOR_REVIEW` drafts in place); the submission ID and final state (typically `WAITING_FOR_REVIEW`) show up in the report. When `attach_build: true`, `submit` also waits up to 20 minutes for Apple to finish processing the build before creating the review submission, to avoid leaving an empty draft behind on a build-less version. The default stays `false` because review submission is irreversible without reviewer intervention, so confirm with the user before flipping it on.

Full schema and every flag: `references/submit-reference.md`.

### 10a. Generate an App Store Connect API key

Walk the user through this (they do it in a browser, once per team):

1. Open <https://appstoreconnect.apple.com/access/integrations/api>.
2. Click the "+" to generate a new key. Access level: "Admin" or "App Manager".
3. Download the resulting `AuthKey_XXXXXX.p8` file. Apple only lets you download it once - store it somewhere safe, e.g. `~/.appstoreconnect/`.
4. From the same page, record:
   - **Key ID** - 10-character alphanumeric, shown in the row for the key.
   - **Issuer ID** - a UUID displayed above the key list (team-wide, same for every key).

### 10b. Configure credentials

Three options. Pick one based on the user's situation.

**Option A - `auth init` (recommended for most users):**

```bash
storescreens auth init
```

This writes `~/.storescreens/asc-credentials.yml` (perms 0600) with commented placeholders for `key_id`, `issuer_id`, and `key_path`, then opens it in `$EDITOR` (or the default macOS text editor if `$EDITOR` is unset). Replace the three `REPLACE_ME` values with the credentials from Step 10a and save.

Flags:
- `--force` - overwrite an existing credentials file
- `--no-open` - write the file but don't launch an editor

**Option B - interactive `auth login`** (prompt-driven alternative):

```bash
storescreens auth login
```

Prompts for the three values and writes the same file. Use this if the user prefers a Q&A flow over editing a pre-filled file.

**Option C - environment variables** (best for CI, scripts, or anyone who already manages secrets in their shell):

```bash
export ASC_KEY_ID=ABCDE12345
export ASC_ISSUER_ID=69a6de84-03c8-47e3-e053-5b8c7c11a4d1
export ASC_KEY_PATH=~/.appstoreconnect/AuthKey_ABCDE12345.p8
```

Tell the user: to clear credentials later, run `storescreens auth logout`.

**Credential resolution order (narrow wins):** environment variables first. If all three are set, they are used; the file is ignored. Otherwise, `~/.storescreens/asc-credentials.yml` is read. If neither is present, any submit or auth-status command errors with `credentials not configured`.

### 10c. Verify credentials work

```bash
storescreens auth status
```

This mints a JWT locally and calls `GET /v1/users` against the App Store Connect API. If the key works, it reports the active source (`environment` or `file`) and the authenticated team. If it fails, the output tells you whether the problem is the key ID, issuer ID, the .p8 contents, or an API-side rejection.

Do not proceed to `submit` until `auth status` is green.

### 10d. Add an `app_store_connect:` block to `storescreens.yml`

Add at the top level of the YAML:

```yaml
app_store_connect:
  # One of app_id or bundle_id is required. bundle_id is preferred - it's
  # resolved via the API at submit time, so you don't need to hard-code
  # the numeric ID.
  bundle_id: com.example.recipes
  # app_id: "1234567890"

  metadata_dir: ./metadata        # default: ./metadata

  submit:
    create_version: "1.2.0"       # required; created in ASC if missing
    screenshots: true             # default: true
    metadata: true                # default: true
    submit_for_review: false      # default: false. true auto-submits for App Review after uploads.
```

Every field, defaults, and the full `submit:` shape are documented in `references/submit-reference.md`.

### 10e. Set up `metadata/<locale>/*.txt`

StoreScreens uses fastlane's directory convention. One folder per locale, one file per App Store field. Any file left out means "don't touch that field in App Store Connect" - present files replace whatever is currently there.

**Scaffold the directory with `metadata init`:**

```bash
storescreens metadata init --locales en-US ja
```

This creates `metadata/<locale>/` subdirectories (one per locale you pass) and writes `metadata/README.md` with the full field reference table (name, subtitle, description, keywords, promotional_text, release_notes, support_url, marketing_url, privacy_url) including character limits and notes. The user then fills in only the `.txt` files they actually want uploaded.

Flags:
- `--locales en-US es-ES ja` - one or more locales (default: `en-US`). Accepts multiple values.
- `--dir ./metadata` - override the target directory
- `--force` - overwrite an existing `README.md`

Resulting layout:

```
metadata/
  README.md                  # field reference table (written by `metadata init`)
  en-US/
    name.txt                 # app name (max 30 chars)
    subtitle.txt             # tagline (max 30 chars)
    description.txt          # main description (max 4000 chars)
    keywords.txt             # comma-separated (max 100 chars incl. commas)
    promotional_text.txt     # above-the-fold marketing (max 170 chars)
    release_notes.txt        # "What's New in This Version" (max 4000 chars)
    support_url.txt          # must be https://
    marketing_url.txt        # optional marketing site
    privacy_url.txt          # optional privacy policy URL (app-level field)
  es-ES/
    description.txt
    release_notes.txt
    ...
```

Trailing whitespace and newlines are trimmed from each file. Unknown filenames inside a locale directory are skipped with a warning. A locale directory with zero readable fields is silently dropped (not an error). Locale folder names must match the Xcode locale codes you already use elsewhere in `storescreens.yml` (`en-US`, `ja`, `de-DE`, etc.).

`privacy_url.txt` is optional and patches the App Info localization (app level), not the version localization; `submit` routes it to the correct endpoint automatically, no extra config required.

When helping the user create these files, offer to draft the initial copy based on what the app does - keep it generic if they haven't given you specifics. Never invent claims about the app.

### 10f. Dry run to validate

Always dry-run before the first real upload:

```bash
storescreens submit --dry-run
```

This validates:
- credentials (mints a JWT, hits the API)
- app lookup (by `app_id` or `bundle_id`)
- version find-or-create (reports whether it will create or update)
- `metadata/<locale>/` parse with warnings for unknown files
- every rendered PNG: dimensions match an App Store display type, file under Apple's 8 MB per-screenshot cap

No writes happen. Inspect the output with the user before going live.

### 10g. Live upload

```bash
storescreens submit
```

Reports per-locale metadata updates, per-(locale, display type) screenshot uploads, and any errors.

**Destructive behaviour for screenshots:** each App Store Connect screenshot set is wiped and re-populated from the rendered manifest so the local render is always the source of truth. The manifest's order becomes the App Store display order. Metadata uploads are non-destructive PATCHes: only fields with a file in `metadata/<locale>/` are sent.

**Idempotent re-runs:** `submit` diffs before writing. For metadata it reads the current version-localization attributes and sends only fields that actually differ; a locale whose fields all match is skipped without a PATCH. For screenshots it reads each existing entry's `sourceFileChecksum` (MD5) and compares to the local render's MD5 in manifest order — if the set already matches, the wipe+reupload is skipped entirely. The report lists skipped locales with `count: 0` so re-running after a no-op release (e.g. re-submitting after a rejection without content changes) is cheap and observable.

**Remind the user:** with the default `submit_for_review: false`, `submit` stops after the uploads. Open App Store Connect, navigate to the version, and click "Submit for Review" manually. To skip that step, set `submit_for_review: true` and `submit` will drive Apple's `reviewSubmissions` 3-step flow (create submission, add the version as an item, PATCH `submitted: true`) once screenshots and metadata upload cleanly. Before creating a new submission, `submit` runs a pre-flight cleanup: cancels any prior `UNRESOLVED_ISSUES` (rejected) submissions and any `READY_FOR_REVIEW` drafts that hold a different version, and adopts any `READY_FOR_REVIEW` draft that already has (or can take) the target version by finalizing it in place. This is what makes the reject + resubmit cycle painless and what recovers from a prior aborted submit that left an orphan draft. If a prior submission is `IN_REVIEW` or `WAITING_FOR_REVIEW`, `submit` refuses to auto-cancel and surfaces a loud error - the user must cancel via the ASC web UI if they really mean to resubmit. When `attach_build: true`, `submit` waits up to 20 minutes for Apple's build processing to finish before creating any review submission, so a same-session upload-build + submit pair works without a manual wait. The submission ID and final state appear in the report.

### 10h. Useful flags

| Flag | Description |
|------|-------------|
| `--dry-run` | Validate everything, write nothing. Always run first. |
| `--skip-screenshots` | Upload metadata only. Good for release-notes-only fixes. |
| `--skip-metadata` | Upload screenshots only. Good when iterating on visuals. |
| `--version-override 1.2.1` | Override `submit.create_version` for this run (creates the version if needed). |
| `--render-dir PATH` | Override `render.output_dir` as the screenshot source. |
| `--metadata-dir PATH` | Override `app_store_connect.metadata_dir`. |
| `--config PATH` / `-c PATH` | Path to `storescreens.yml` (default `./storescreens.yml`). |

### 10i. Reference

Full schema, character limits, credential resolution order, destructive semantics, troubleshooting, and a complete working example: `references/submit-reference.md`.

### 10j. Check on the submission

After submit, you don't have to open the App Store Connect web UI to know whether Apple has started reviewing or accepted the build. `storescreens status` queries ASC and prints the current version states and any open review submission:

```bash
storescreens status
```

Read-only - no writes. Color-codes states (green = live / approved, yellow = in flight, red = rejected) and prints a one-line hint about the next action ("Apple is reviewing the submission.", "Apple rejected the submission. Resolve issues and resubmit.", etc.). Pass `--json` for machine-readable output; `--platform IOS|MAC_OS|TV_OS|VISION_OS` to switch platforms.

---

## Step 10b: Archive + upload the app binary (optional)

`storescreens submit` uploads screenshots and metadata only; it does **not** build or upload the `.ipa`. For that, `storescreens upload-build` wraps `xcodebuild archive` -> `xcodebuild -exportArchive` -> `xcrun altool --upload-app` into one command, reusing the same ASC API key credentials.

Key behaviour:

- **Non-beta Xcode auto-selection.** Scans `/Applications` for `Xcode*.app`, excludes anything with "beta" in the path or icon, and pins `DEVELOPER_DIR` to the highest-version production Xcode. A beta `xcode-select -p` won't taint the archive. Override with `xcode_path:` in config or `--xcode-path`.
- **Shared credentials.** Uses `~/.storescreens/asc-credentials.yml` (or `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_PATH` env vars) from Step 10a. The .p8 is written to a tmpdir as `AuthKey_<KEY_ID>.p8`, `API_PRIVATE_KEYS_DIR` is pointed at it, and the tmpdir is wiped after altool exits.
- **Generated ExportOptions.plist by default.** Writes a minimal plist with `method: app-store`, `uploadSymbols: true`, `stripSwiftSymbols: true`. Users with a hand-crafted plist pass `export_options_plist:` to override.

**When to offer this:** any time the user asks about building, archiving, uploading to TestFlight, or shipping a binary. Opt-in; do not run without an explicit go-ahead.

Full schema and every flag: `references/upload-build-reference.md`.

### 10b.a. Scaffold config with `upload-build init`

```bash
storescreens upload-build init
```

Appends an `upload_build:` block inside the existing `app_store_connect:` block in `storescreens.yml`, with commented placeholders for every supported field, and opens the file in `$EDITOR`. The block is inserted as a sibling of `submit:`.

Flags:

- `--force` / `-f` - replace an existing `upload_build:` block.
- `--no-open` - write without launching an editor.
- `--config PATH` / `-c PATH` - target a specific yml.

If `storescreens.yml` has no `app_store_connect:` block yet, `init` appends a fresh one with a `bundle_id: REPLACE_ME_…` placeholder plus the upload-build block; the user fills in the bundle ID.

### 10b.b. Minimum viable config

Most users only need this (inside `app_store_connect:`):

```yaml
app_store_connect:
  bundle_id: com.example.app
  upload_build: {}
```

Defaults kick in: scheme from top-level `scheme:`, `configuration: Release`, `export_method: app-store`, auto-detected non-beta Xcode, automatic signing with `-allowProvisioningUpdates`, output at `./build/`. Hand-edit the scaffolded block to turn any of these off.

### 10b.b.1. Automatic version + build resolution

Before archiving, `upload-build` queries App Store Connect for your app's version state and TestFlight build history, then chooses the right `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` to use:

- **Marketing version already shipped** (state `READY_FOR_SALE`, `PROCESSING_FOR_APP_STORE`, `PENDING_*_RELEASE`, etc.): bumps the patch component (`1.1.7` → `1.1.8`) and resets the build number to `1`.
- **Marketing version is fresh but TestFlight builds exist**: keeps the version, bumps build number to `max(existing) + 1`.
- **Fresh version, no builds**: keeps whatever's in the Xcode project (build defaults to `1` if not already set).

The pbxproj is rewritten in place (every occurrence across every config of every target, matching `agvtool new-version -all` / `new-marketing-version`). `submit.create_version` in `storescreens.yml` is also synced so `storescreens submit` picks up the new version automatically. The working tree shows the diff.

Opt out with:

- `--no-auto-bump` (or `upload_build.auto_bump: false`) - error out instead of rewriting. The error message prints the `agvtool` commands to run manually.
- `--marketing-version X.Y.Z` - force a specific version. Still validates the build number against ASC.
- `--build N` - force a specific build number.

The version check is **skipped** when `--skip-upload` is set (local archive doesn't care about TestFlight collisions) or when credentials aren't configured during `--dry-run` (graceful degrade with a warning).

### 10b.c. Verify credentials + Xcode

Same credential check as submit:

```bash
storescreens auth status
```

Dry-run plans the build without touching xcodebuild or altool:

```bash
storescreens upload-build --dry-run
```

The dry-run output shows the resolved scheme, configuration, destination, export method, which Xcode was picked (version + path + BETA flag if forced to a beta), and where the archive and ipa will land. Inspect this before a live run.

### 10b.d. Live upload

```bash
storescreens upload-build
```

Runs archive, export, then altool upload. Streams xcodebuild output via `--verbose`. To keep a local `.ipa` without pushing to ASC (e.g. for manual distribution or inspection):

```bash
storescreens upload-build --skip-upload
```

Also usable as a YAML field: `upload_build: { skip_upload: true }`.

### 10b.e. Common flags

| Flag | Description |
|------|-------------|
| `--dry-run` | Plan without running xcodebuild or altool. Always run before the first live upload. |
| `--scheme NAME` | Override the scheme. Wins over both top-level `scheme:` and `upload_build.scheme:`. |
| `--configuration NAME` | Override build configuration (e.g. `Debug`). |
| `--xcode-path PATH` | Use a specific Xcode. Accepts the `.app` bundle or `Contents/Developer` dir. |
| `--output-dir PATH` | Override where the `.xcarchive` and exported `.ipa` land. |
| `--skip-upload` | Archive + export + stop. Leaves the `.ipa` in `output_dir`. (Also skips the version check.) |
| `--marketing-version X.Y.Z` | Force a specific marketing version. Still validates build number against ASC. |
| `--build N` | Force a specific build number. |
| `--no-auto-bump` | Error out instead of rewriting the pbxproj when a bump is required. |
| `--verbose` | Stream full xcodebuild output to stdout instead of filtered lines. |
| `--config PATH` / `-c PATH` | Path to `storescreens.yml`. |

### 10b.f. Signing notes

Defaults assume **automatic signing** with `-allowProvisioningUpdates` enabled at both archive and export time, so Xcode can fetch or create missing provisioning profiles on the fly. This matches the happy path for most App Store-enrolled developer accounts.

For **manual signing**, set `signing_style: manual` and fill in `provisioning_profiles:` (bundle id -> profile name). The generated `ExportOptions.plist` uses these instead of asking Xcode to figure things out.

If signing misbehaves, inspect the archive:

```bash
open /path/to/output_dir/<scheme>.xcarchive
```

Or hand-craft an `ExportOptions.plist` and point `export_options_plist:` at it; storescreens skips generation and uses yours verbatim.

### 10b.g. Typical release workflow

```bash
# One-time setup (if you haven't already)
storescreens auth init
storescreens upload-build init

# Every release
storescreens upload-build --dry-run   # sanity check
storescreens upload-build             # archive + export + upload to ASC/TestFlight

# Later, once TestFlight has processed the build:
storescreens submit                   # upload screenshots + metadata and attach to the version
```

Apple typically takes 5-20 minutes to process the uploaded binary before it shows up on a version in App Store Connect. If `submit` runs before processing finishes, it will upload metadata and screenshots but the "Build" field on the version will still need to be set manually (or via a later `submit` run).

### 10b.h. Reference

Full schema, all fields with defaults, credential resolution, and troubleshooting: `references/upload-build-reference.md`.

---

## Step 11: Upload to storescreens.app (optional, opt-in)

The CLI can upload screenshots to [storescreens.app](https://storescreens.app) for visual editing (device frames, backgrounds, marketing text). This is **disabled by default**.

To enable the upload prompt, add `upload: true` to `storescreens.yml`:

```yaml
upload: true
```

When enabled, the CLI prompts after each capture:

> Would you like to design App Store Connect screenshots at storescreens.app? (y/n)

To suppress the prompt on a single run (e.g. in CI), pass `--no-upload`:

```bash
storescreens capture --verbose --no-upload
```

---

## MCP Server (storescreens-mcp)

The `storescreens-mcp` binary is a Model Context Protocol server that exposes storescreens functionality as structured tools - eliminating the need for Bash calls and providing per-screenshot progress inline.

### Setup

Add to your `.mcp.json`:

```json
{
  "mcpServers": {
    "storescreens": {
      "command": "storescreens-mcp",
      "args": []
    }
  }
}
```

Or with a full path if not on `$PATH`:

```json
{
  "mcpServers": {
    "storescreens": {
      "command": "/usr/local/bin/storescreens-mcp",
      "args": []
    }
  }
}
```

### Available Tools

| Tool | Description |
|------|-------------|
| `capture` | Start screenshot capture in background; returns `taskId` immediately |
| `get_capture_status` | Poll progress for a running capture; returns live events + status |
| `get_capture_result` | Fetch full manifest once capture is complete |
| `check` | Run preflight scan; returns `[{rule, severity, file, line, message}]` |
| `list_simulators` | List available simulators grouped by App Store slot |
| `list_screenshots` | List screenshots from the last capture (reads `manifest.json`) |
| `get_screenshot` | Load a PNG as base64 (Claude renders it inline) |
| `take_screenshot` | Capture current simulator screen; returns image inline. No build required. |
| `read_config` | Read and parse `storescreens.yml` |
| `write_config` | Write `storescreens.yml` |

### Progressive Disclosure Pattern

`capture` returns a compact summary to avoid token bloat:

```
● Building for testing…
  ✓ iPhone 17 Pro Max [iPhone 6.9"] Home → storescreens-output/light/iPhone_6.9_Home.png
  ✓ iPhone 17 Pro Max [iPhone 6.9"] Detail → storescreens-output/light/iPhone_6.9_Detail.png
  ● Device complete: iPhone 17 Pro Max - 2 screenshots

captureId: a1b2c3d4
```

Call `get_capture_result` with the `captureId` to get the full manifest including all device sizes, paths, and metadata.

---

## Debugging

When something goes wrong, the xcodebuild output is already in the Bash result (use Ctrl+O to see full output). You can also check the log files directly:

1. **`logs/test-*.log`** - per-device xcodebuild output, element lookup failures, assertion errors
2. **`logs/test-debug-*.log`** - test debug prints (from the named pipe)

If a capture run fails or screenshots are missing, always read the relevant log file before changing code - the root cause is almost always visible in the xcodebuild output.

---

## Common Issues

- **"Element not found"** - use `.accessibilityIdentifier` instead of button titles; always `waitForExistence(timeout:)`. Check `logs/test-*.log` for the full element tree dump.
- **"Test not discovered"** - the `.swift` file isn't in the Xcode target; use "Add Files to" and check target membership
- **StoreKit / entitlement checks override screenshot mode flag** - guard every entitlement check, not just the setter
- **iPad preflight errors** - wrap `.toolbarVisibility(.hidden, for: .tabBar)` with a `UIDevice` idiom check, or pass `--skip-check` for iPhone-only projects
- **Build failures** - check `logs/build-for-testing.log` for the full compiler output
- **"0 screenshots via filesystem" but tests passed** - the breadcrumb file `~/.storescreens-cache-dir` was missing or stale. This file tells the test's `takeScreenshot` helper where to write PNGs. Run `storescreens capture` again (v1.2.1+ writes the breadcrumb correctly). If the file is missing, create it manually: `echo "$PWD/.storescreens-cache" > ~/.storescreens-cache-dir`
- **Wrong/deleted test methods ran (stale DerivedData)** - when using persistent `derived_data_path`, the compiled test binary can become stale if test source files are edited. v1.3.0+ auto-detects this and cleans build products before building. If you see unexpected test methods running, manually clean: `rm -rf ~/.storescreens-cache/<MyApp>/Build/Products`. The `storescreens check` command also warns about stale DerivedData.

## Persistent DerivedData (STRONGLY RECOMMENDED)

**Always configure this.** By default storescreens creates a fresh temp DerivedData directory per run and deletes it afterwards, so every run recompiles all SPM packages from scratch - adding 3-5+ minutes of unnecessary build time. With a persistent cache, incremental builds only recompile changed files.

Add `derived_data_path` to `storescreens.yml`:

```yaml
derived_data_path: ~/.storescreens-cache/<MyApp>
```

Or set it via the MCP `write_config` tool:

```
write_config(derived_data_path: "~/.storescreens-cache/MyApp")
```

You can also pass it as a one-off override on the CLI:

```bash
storescreens capture --derived-data-path ~/.storescreens-cache/MyApp
```

Or via the MCP `capture` tool:

```
capture(derived_data_path: "~/.storescreens-cache/MyApp")
```

**Notes:**
- The directory is created automatically on first use.
- Use a project-specific subdirectory (e.g. `~/.storescreens-cache/MyApp`) if you have multiple projects.
- To force a clean build, delete the directory or don't set this option.
- **Staleness detection (v1.3.0+):** Before each capture, storescreens compares test source file modification times with the compiled test runner binary. If source is newer, it automatically cleans the build products and rebuilds. This prevents stale binaries from running wrong/deleted test methods.

---

## Warmup Run (for apps that need a full launch cycle before capturing)

By default, storescreens runs the test suite **once per device**. xcodebuild parallel test execution is disabled (`-parallel-testing-enabled NO`) to prevent unintended duplicate runs from simulator clones.

Some apps need a full launch cycle before screenshots look correct - for example, apps that seed a CloudKit database, perform On-Demand Resources downloads, or run migrations on first launch. For these, enable the warmup run:

```yaml
warmup_run: true
```

When `warmup_run: true`, storescreens runs the test suite **twice** per device. The first run is a warmup (screenshots are discarded), and the second run captures the real screenshots.

Most apps do **not** need this - leave it unset (default: off).

---

## References

- Full capture config schema: `references/config-reference.md`
- Full render config schema (background, scrim, images, laurels, caption, chrome, bezels, panoramic, markdown, highlights, fonts): `references/render-reference.md`
- Full App Store Connect upload schema (`app_store_connect:` block, credentials, metadata files, `submit` flags, destructive semantics, troubleshooting): `references/submit-reference.md`
- Full archive + binary upload schema (`upload_build:` block, non-beta Xcode auto-selection, ExportOptions.plist generation, altool flow, troubleshooting): `references/upload-build-reference.md`
- ScreenshotTests starter template: `../storescreens-cli/Sources/storescreens-cli/Resources/ScreenshotTests.swift.template`
