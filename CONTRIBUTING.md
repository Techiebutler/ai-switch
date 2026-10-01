# Contributing to ai-switch

Thanks for helping out. Bug reports, fixes, docs and support for new tools are all welcome.

## Ground rules

- Be respectful. This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
- **Never paste real tokens, `auth.json`, Keychain output or `.credentials.json` contents** into issues, PRs, logs or test fixtures. Replace them with fake values. If you accidentally post one, revoke it by logging out of that account and delete the comment.
- Security problems go through the [security policy](SECURITY.md), not public issues.
- Keep the tool small: a single Python file with no third-party dependencies, so `curl | bash` installs keep working.

## Reporting bugs

Open an issue with the bug template. Please include:

- `ai-switch --version`, your OS, and the version of the tool involved (`claude --version`, `codex --version`, Cursor version)
- the exact command you ran and its output (with emails redacted if you prefer)
- what you expected to happen

## Development setup

```bash
git clone https://github.com/Techiebutler/ai-switch.git
cd ai-switch
tests/test.sh
```

Requirements: `python3` (3.8 or newer), `bash`, and `shellcheck` for linting.

The tests run against a temporary `HOME` with fake tokens and the file backend (`AI_SWITCH_BACKEND=file`), so they never touch your real logins or Keychain. To try the tool by hand without risking your real accounts, do the same:

```bash
export HOME="$(mktemp -d)" AI_SWITCH_BACKEND=file
```

## Making a change

1. Fork the repo and create a branch from `main` (`fix/cursor-linux-path`, `feat/windsurf`, ...).
2. Make your change. Match the style of the surrounding code and keep comments short and useful.
3. Add or update tests in `tests/test.sh` for any behavior change.
4. Run the checks:
   ```bash
   tests/test.sh
   shellcheck install.sh tests/test.sh
   python3 -m py_compile ai-switch
   ```
5. Update `README.md` if usage changes, and add a line under **Unreleased** in `CHANGELOG.md`.
6. Open a pull request and fill in the template. CI must pass on macOS and Linux before merging.

### Commit messages

Use a short imperative summary line (under 72 characters), for example `Add Windsurf support` or `Fix Cursor path on Linux`, and explain the why in the body when it isn't obvious.

## Adding support for a new tool

Each tool is one class in `ai-switch` that subclasses `Tool` and implements:

| Method | Returns |
| --- | --- |
| `identity()` | `{"key", "email"}` for the current login, or `None`. `key` must be stable for an account (an account ID, not a token). |
| `export()` | `{"secret", "meta"}` for the current login, or `None`. `secret` goes to the Keychain; `meta` is non-secret data stored in `account.json`. |
| `apply(secret, meta)` | Makes that login current. Change only login data, never settings or other credentials stored next to it. |
| `check()` | Raises `Fail` when the local setup is something the tool can't handle safely. |

Set `process` (a `pgrep -x` pattern) and `must_quit = True` for desktop apps that rewrite their state on exit. Then register the class in `TOOLS`.

Before writing code, find out where the tool really keeps its login and document it in the PR: file paths, database keys, Keychain item names, and whether tokens are encrypted. Include tests that simulate a login with fake data.

## Releases

Maintainers bump `VERSION` in `ai-switch`, move the **Unreleased** changelog entries under the new version, tag `vX.Y.Z` and publish a GitHub release. Versions follow [Semantic Versioning](https://semver.org/).

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
