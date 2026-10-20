# Screenshot pipeline

| Responsibility | Tool |
| --- | --- |
| Simulator preparation, XCUITest execution, PNG collection, raw manifest | StoreScreens |
| Layouts, frames, captions, fonts, localization, rendering | Koubou (`kou`) |
| App Store Connect, Apple Ads, uploads, metadata, TestFlight, releases | ASC CLI (`asc`) |

Raw PNG paths are relative to the directory containing StoreScreens' `manifest.json`. Use those images in Koubou's `content` image assets or HTML templates. Keep the application's Koubou configuration and templates in source control. Do not reinterpret already reviewed copy while changing tools.

Run `kou generate koubou.yml`, inspect all required output sets, and use `asc screenshots upload --help` for the current upload flags. Upload only after reviewing the images and intended target version. StoreScreens does not run an automatic upload or modify App Store Connect state.

Use the existing App Store Connect credentials with ASC CLI. Do not copy credentials into configuration examples, logs, manifests, or Git history. Existing files under `~/.storescreens/` may remain in place.
