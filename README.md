![StoreScreens — XCUITest Screenshot Orchestration](assets/banner.png?v=interfaces)

# StoreScreens capture skill

Agent instructions for [StoreScreens](https://github.com/ciscoriordan/storescreens-cli) version 4: simulator setup, XCUITest orchestration, and raw screenshot collection.

Use your preferred screenshot renderer and App Store Connect command-line tool. We recommend [Koubou](https://github.com/bitomule/Koubou) for screenshot composition and rendering, and [ASC CLI](https://asccli.sh/) for App Store Connect management and uploads. Neither is required for capture. Version 4 removes the former built-in renderer, App Store Connect client, and Wall of Apps functionality.

## Install

Install the CLI with mise, Homebrew, or the curl installer; see the [installation commands](https://github.com/ciscoriordan/storescreens-cli#install). This skill supplies agent instructions, not the CLI binary.

### Agent skill

From your application's project directory, install the skill with Node.js 22.20 or later:

```sh
npx skills add ciscoriordan/storescreens-skill
```

Choose your coding agent when prompted. Add `-g` to install across projects, then start a new agent session. You can also use your agent's skill installer or the packaged `storescreens.skill`. Read [SKILL.md](SKILL.md) for the workflow and command boundaries.

### MCP setup

For MCP, configure a local stdio server that launches `storescreens-mcp`. With the Codex CLI:

```sh
codex mcp add storescreens -- storescreens-mcp
```

A mise-managed installation can use `mise exec -- storescreens-mcp` as the server command. See the CLI's [example MCP configuration](https://github.com/ciscoriordan/storescreens-cli/blob/main/mcp.json.example), the [Codex MCP setup guide](https://learn.chatgpt.com/docs/extend/mcp), and the website's [installation and setup instructions](https://storescreens.app/#install).

### Koubou for screenshot rendering

[Koubou](https://github.com/bitomule/Koubou) is an optional renderer for layouts, frames, captions, and localization:

```sh
brew install bitomule/tap/koubou
kou --version
```

With a mise-managed Python, you can instead run `python3 -m pip install koubou`. Run `kou setup-html` to prepare HTML rendering, or `kou install-skills` to add Koubou's agent skills. See the [Koubou installation guide](https://github.com/bitomule/Koubou#-installation).

### ASC CLI for App Store Connect

[ASC CLI](https://asccli.sh/) is an optional tool for App Store Connect and screenshot uploads:

```sh
brew install asc
asc --version
```

You can also install it with `curl -fsSL https://asccli.sh/install | bash`. Register your App Store Connect API key with `asc auth login`; `asc auth login --help` lists the key ID, issuer ID, and private-key options. Run `asc install-skills` if you want its agent skills.

## Development

Run `bash build-skill.sh` after changing the instructions or references. The build also synchronizes the XCUITest template from the sibling `storescreens-cli` checkout when available, so the generated tests and packaged skill use the same harness.

StoreScreens 4.0.1 supports partial MCP captures and rejects failed tests before publishing images. See the [complete MCP and Koubou example](https://github.com/ciscoriordan/storescreens-cli/tree/main/examples) for a runnable client, failure recovery, and rendering the collected PNGs.

MIT.
