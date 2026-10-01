# ai-switch

[![CI](https://github.com/Techiebutler/ai-switch/actions/workflows/ci.yml/badge.svg)](https://github.com/Techiebutler/ai-switch/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Switch between multiple accounts in your AI coding tools with one command, without signing in again.

Supports **Claude Code**, **Codex CLI** and **Cursor**.

```console
$ ai-switch list
Claude Code:
* work             you@company.com
  personal         you@gmail.com

Codex CLI:
* work             you@company.com (team)
  personal         you@gmail.com (plus)

$ ai-switch personal
claude: switched to 'personal' (you@gmail.com). Start a new 'claude' session to use it.
codex: switched to 'personal' (you@gmail.com (plus)). Start a new 'codex' session to use it.
```

## Why

If you have more than one account (work and personal, or several seats), switching normally means logging out, opening the browser and signing in again, every time you hit a usage limit. Login tokens last a long time, so `ai-switch` saves each account's login once and puts the saved login back when you switch.

## Install

Requirements: macOS or Linux, and `python3` (preinstalled on macOS).

```bash
curl -fsSL https://raw.githubusercontent.com/Techiebutler/ai-switch/main/install.sh | bash
```

This installs `ai-switch` to `~/.local/bin`, plus a `claude-switch` shortcut. If that folder is not on your `PATH`, the installer tells you what to add to `~/.zshrc` or `~/.bashrc`.

Or install manually:

```bash
git clone https://github.com/Techiebutler/ai-switch.git
ln -s "$PWD/ai-switch/ai-switch" ~/.local/bin/ai-switch
```

## Setup (once per account)

1. Log in to your first account in the tool as usual, then save it:
   ```bash
   ai-switch claude add work
   ```
2. Log in to your second account using the tool's own login, then save it:
   ```bash
   ai-switch claude add personal
   ```
3. Repeat for other accounts and other tools.

How to log in to another account without losing the saved one:

| Tool | Log in to another account with |
| --- | --- |
| Claude Code | `/login` inside `claude` (**not** `/logout`) |
| Codex CLI | `codex login` |
| Cursor | Sign in from Cursor's settings. If you have to sign out first, save the current account before doing so. |

> Logging out can revoke the saved login on the provider's side, and you would have to add that account again. Prefer logging in over the top of the current account where the tool allows it.

Use the same profile name (like `work`) across tools and you can switch all of them at once with `ai-switch work`.

## Usage

| Command | What it does |
| --- | --- |
| `ai-switch <tool> <name>` | Switch that tool to a saved account |
| `ai-switch <tool> next` | Switch to the tool's next saved account, handy when you hit a usage limit |
| `ai-switch <tool> list` | Show the tool's saved accounts (`*` marks the active one) |
| `ai-switch <tool> current` | Show the tool's active account |
| `ai-switch <tool> add <name>` | Save the account you are logged in with now |
| `ai-switch <tool> remove <name>` | Forget a saved account (does not log you out) |
| `ai-switch <name>` | Switch every tool that has a profile called `<name>` |
| `ai-switch list` | Show saved accounts for all tools |
| `ai-switch current` | Show the active account of every tool |

`<tool>` is `claude`, `codex` or `cursor`. `claude-switch ...` is a shortcut for `ai-switch claude ...`.

**After switching:**
- **Claude Code, Codex:** quit running sessions and start a new one. A running session keeps the old account in memory.
- **Cursor:** quit Cursor before switching (`ai-switch` refuses while it is open, because Cursor rewrites its login when it closes), then open it again.

## Supported tools

| Tool | Where it keeps the login | What gets swapped | Status |
| --- | --- | --- | --- |
| Claude Code | macOS Keychain `Claude Code-credentials` (Linux: `~/.claude/.credentials.json`) and `oauthAccount` in `~/.claude.json` | Only the `claudeAiOauth` entry and `oauthAccount`. MCP server logins in the same store are left alone. | Tested |
| Codex CLI | `~/.codex/auth.json` (or `$CODEX_HOME`) | The whole file. ChatGPT logins and API-key logins both work. | Tested |
| Cursor | `cursorAuth/*` rows in Cursor's `state.vscdb` settings database | Only the `cursorAuth/*` rows | Experimental: tested against the real storage format, not yet in daily use |

Not supported yet:
- **Windsurf / Devin**: its login storage has not been mapped yet. Contributions welcome.
- **Codex with `cli_auth_credentials_store = "keyring"`**, and **Claude Code with `CLAUDE_CONFIG_DIR`**: these keep the login elsewhere, so `ai-switch` refuses to run rather than swap the wrong thing.

## How it works

A profile is a saved copy of a tool's login. On a switch, `ai-switch`:

1. Saves the current account's latest tokens back to its profile. Tools refresh their tokens while you use them, so this keeps saved profiles from going stale.
2. Writes the target profile's login into the place the tool reads it.

Settings, history and projects are shared across accounts; only the login changes.

### Where profiles are stored

| | macOS | Linux |
| --- | --- | --- |
| Tokens | Keychain items named `ai-switch:<tool>:<name>` | `~/.ai-switch/<tool>/<name>/secret.json` (mode `600`) |
| Account info (email, IDs) | `~/.ai-switch/<tool>/<name>/account.json` | same |

`~/.ai-switch` is created with mode `700`. Set `AI_SWITCH_HOME` to use a different folder.

### Upgrading from claude-switch 1.x

Run any `ai-switch` or `claude-switch` command and your saved Claude profiles move from `~/.claude-switch` into `~/.ai-switch/claude` automatically. Old commands like `claude-switch work` keep working.

## Security notes

- Saved tokens give full access to the account, just like the logins the tools already keep on your machine. Don't copy `~/.ai-switch` to other machines or commit it anywhere.
- On macOS, while a token is written to the Keychain it is passed to the `security` command as an argument, so for a moment it is visible to other processes running as your user (for example via `ps`). This is fine on a personal machine. Avoid it on shared multi-user machines.
- The tool runs only locally and makes no network requests.

## Troubleshooting

**An account shows as logged out after switching.** Its saved login expired or was revoked (for example after logging out, or a long time unused). Log in to that account again, then run `ai-switch <tool> add <same name>` to refresh it.

**"this account is already saved as ..."** Each account can be saved once per tool. Run `ai-switch <tool> remove <old name>` first if you want to rename it.

**"quit Cursor first"** Cursor overwrites its login when it closes, so quit it completely (Cmd+Q on macOS), switch, then open it again.

## Uninstall

```bash
for t in claude codex cursor; do
  for n in $(ai-switch "$t" list 2>/dev/null | cut -c3- | awk '{print $1}'); do ai-switch "$t" remove "$n"; done
done
rm -rf ~/.ai-switch ~/.local/bin/ai-switch ~/.local/bin/claude-switch
```

Your current logins are not affected.

## Development

```bash
tests/test.sh                     # end-to-end tests in a temporary HOME with fake tokens
shellcheck install.sh tests/test.sh
```

The tests use the file backend (`AI_SWITCH_BACKEND=file`), so they never touch your real Keychain or logins. Adding a tool means one class in `ai-switch` with `identity`, `export` and `apply` methods.

## Contributing

Contributions are welcome, especially support for more tools (Windsurf / Devin is the most wanted). Read [CONTRIBUTING.md](CONTRIBUTING.md) to get started, and please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Found a security problem? See [SECURITY.md](SECURITY.md) and report it privately. Changes are listed in the [CHANGELOG](CHANGELOG.md).

## Disclaimer

This is an unofficial community tool, not affiliated with or endorsed by Anthropic, OpenAI or Anysphere. It relies on how each tool stores credentials today, which may change in future releases. Using multiple accounts is subject to each provider's terms for each account.

## License

[MIT](LICENSE)
