# StoreScreens capture skill

Agent instructions for [StoreScreens](https://github.com/ciscoriordan/storescreens-cli) version 4: simulator setup, XCUITest orchestration, and raw screenshot collection.

We recommend [Koubou](https://github.com/bitomule/Koubou) for screenshot composition and rendering, and [ASC CLI](https://asccli.sh/) for App Store Connect management and uploads. StoreScreens is active again with a capture-only scope; version 3's rendering and App Store Connect instructions have been removed.

Install the skill from this repository using your agent's skill installer, or use the packaged `storescreens.skill`. Read [SKILL.md](SKILL.md) for the workflow and command boundaries.

Run `bash build-skill.sh` after changing the instructions or references. The build also synchronizes the XCUITest template from the sibling `storescreens-cli` checkout when available, so the generated tests and packaged skill use the same harness.

MIT.
