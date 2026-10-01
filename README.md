# claude-switch

Switch between multiple Claude Code accounts with one command, without logging in again.

```console
$ claude-switch list
* work       you@company.com
  personal   you@gmail.com

$ claude-switch personal
switched to 'personal' (you@gmail.com). Start a new 'claude' session to use it.
```

## Why

If you use Claude Code with more than one account (work and personal, or several team seats), switching normally means running `/login`, opening the browser, and signing in again every time. Claude Code's login tokens last a long time, so `claude-switch` saves each account's login once and swaps the saved login back in when you switch.

## Install

Requirements: macOS or Linux, `bash`, `python3` (preinstalled on macOS), and Claude Code.

```bash
curl -fsSL https://raw.githubusercontent.com/Techiebutler/claude-switch/main/install.sh | bash
```

This installs to `~/.local/bin/claude-switch`. If that folder is not on your `PATH`, the installer tells you what to add to `~/.zshrc` or `~/.bashrc`.

Or install manually:

```bash
git clone https://github.com/Techiebutler/claude-switch.git
ln -s "$PWD/claude-switch/claude-switch" ~/.local/bin/claude-switch
```

## Setup (once per account)

1. Log in to your first account in Claude Code as usual, then save it:
   ```bash
   claude-switch add work
   ```
2. Start `claude`, run **`/login`** and sign in with your second account. Exit Claude, then save it:
   ```bash
   claude-switch add personal
   ```
3. Repeat step 2 for any other accounts.

> **Use `/login` to change accounts, not `/logout`.** Logging out can revoke the saved login on Anthropic's side, and you would have to add that account again.

## Usage

| Command | What it does |
| --- | --- |
| `claude-switch <name>` | Switch to a saved account (same as `use <name>`) |
| `claude-switch next` | Switch to the next saved account, handy when you hit a usage limit |
| `claude-switch list` | Show saved accounts (`*` marks the active one) |
| `claude-switch current` | Show the active account |
| `claude-switch add <name>` | Save the account you are logged in with now |
| `claude-switch remove <name>` | Forget a saved account (does not log you out) |
| `claude-switch --version` | Print the version |

**After switching, quit any running `claude` sessions and start a new one.** A running session keeps the old account in memory. Run `/status` inside Claude to confirm which account is active.

## How it works

Claude Code stores your login in two places:

| What | macOS | Linux |
| --- | --- | --- |
| OAuth tokens | Keychain item `Claude Code-credentials` | `~/.claude/.credentials.json` |
| Account identity | `oauthAccount` in `~/.claude.json` | same |

A profile is a saved copy of both. On a switch, `claude-switch`:

1. Saves the current account's latest tokens back to its profile. Claude Code refreshes tokens while you use it, so this keeps saved profiles from going stale.
2. Writes the target profile's tokens and identity into the places Claude Code reads.

Only the `claudeAiOauth` entry is swapped. Other entries in the same credential store, such as MCP server logins, are left as they are, so your MCP connections keep working whichever account is active. Settings, history, and projects in `~/.claude` are shared across accounts.

### Where profiles are stored

| | macOS | Linux |
| --- | --- | --- |
| Tokens | Keychain items named `claude-switch:<name>` | `~/.claude-switch/<name>/credentials.json` (mode `600`) |
| Account info (email, IDs) | `~/.claude-switch/<name>/account.json` | same |

`~/.claude-switch` is created with mode `700`. Set `CLAUDE_SWITCH_HOME` to use a different folder.

## Security notes

- Saved tokens give full access to the account, just like the login Claude Code already keeps on your machine. Don't copy `~/.claude-switch` to other machines or commit it anywhere.
- On macOS, while a token is written to the Keychain it is passed to the `security` command as an argument, so for a moment it is visible to other processes running as your user (for example via `ps`). This is fine on a personal machine. Avoid it on shared multi-user machines.
- The tool runs only locally and makes no network requests.

## Troubleshooting

**An account shows as logged out after switching.** Its saved login expired or was revoked (for example after `/logout`, or a long time unused). Run `/login` with that account, then `claude-switch add <same name>` to refresh it.

**"this account is already saved as ..."** Each account can only be saved once. Use `claude-switch remove <old name>` first if you want to rename it.

**"CLAUDE_CONFIG_DIR is set"** With a custom config directory, Claude Code stores its login under different names, which this tool does not support. Unset it, or use separate `CLAUDE_CONFIG_DIR` folders as your multi-account setup instead (each folder keeps its own login, settings and history).

## Uninstall

```bash
for n in $(claude-switch list | cut -c3- | awk '{print $1}'); do claude-switch remove "$n"; done
rm -rf ~/.claude-switch ~/.local/bin/claude-switch
```

Your current Claude Code login is not affected.

## Development

```bash
tests/test.sh                                  # end-to-end tests in a temporary HOME with fake tokens
shellcheck claude-switch install.sh tests/test.sh
```

The tests use the file backend (`CLAUDE_SWITCH_BACKEND=file`), so they never touch your real Keychain or login.

## Disclaimer

This is an unofficial community tool and is not affiliated with or endorsed by Anthropic. It relies on how Claude Code stores credentials today, which may change in future releases. Using multiple accounts is subject to Anthropic's terms for each account.

## License

[MIT](LICENSE)
