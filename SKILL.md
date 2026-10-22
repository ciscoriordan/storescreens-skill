---
name: storescreens
description: "Set up simulators, orchestrate XCUITest screenshot flows, and collect authentic raw captures with StoreScreens. Koubou and ASC CLI are recommended downstream tools."
---

# StoreScreens capture workflow

StoreScreens 4 handles simulator preparation, XCUITest orchestration, and screenshot collection. It can be used with other screenshot renderers and App Store Connect command-line tools. We recommend [Koubou](https://github.com/bitomule/Koubou) for composition, framing, captions, localization, and rendering, and [ASC CLI](https://asccli.sh/) for App Store Connect and Apple Ads management, including screenshot uploads. Neither is required for capture. Follow the application's existing tooling decisions; run downstream tools directly for their operations.

1. Inspect the application's existing screenshot tests and capture configuration. Preserve validated navigation, authentic content fixtures, reviewed copy, sizes, locales, and provenance. Do not replace a queued submission to change tooling.
2. Check `storescreens --version`, `storescreens --help`, and the relevant command's help. Prefer mise-managed installations on Macs. Version 3 has a different scope; migrate its configuration before using version 4.
3. Run `storescreens list`, or `storescreens list --include-watch` for Apple Watch. Use installed simulators compatible with the application; do not guess simulator names or install runtimes unnecessarily.
4. Run `storescreens init` and `storescreens setup` only if configuration and tests are missing. Add app-specific navigation and explicit element waits to the generated harness. Review source checks with `storescreens check`.
5. Run `storescreens prepare` and `storescreens capture`. Poll capture status when using MCP. A failure or zero screenshots is not success; inspect the device logs and retained result bundles.
6. Review the raw images and `manifest.json`. Check every required screen, device, locale, and appearance. Use narrowed captures to repair individual sets while preserving others.
7. Pass raw image paths to the application's source-controlled rendering configuration. For the recommended Koubou and ASC CLI workflow, render with `kou generate`, review the outputs, then use ASC CLI for uploads and App Store Connect operations.

Read [references/capture-reference.md](references/capture-reference.md) for configuration, Apple Watch schemes and companions, partial captures, existing `.xcresult` collection, and version 3 migration. Read [references/pipeline-reference.md](references/pipeline-reference.md) for the boundary between the three tools.

The editable [ScreenshotTests.swift template](assets/ScreenshotTests.swift.template) writes filesystem PNGs and XCTAttachments. It uses accessibility identifiers and explicit waits. Fill in the screen-navigation placeholder; do not fabricate raw screenshots or replace them with rendered UI approximations.

StoreScreens has no App Store Connect client, renderer, credential management, or upload commands. Existing credential files can remain where they are and be used by ASC CLI. Do not remove or expose credentials during migration.
