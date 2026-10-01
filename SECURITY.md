# Security Policy

ai-switch handles login tokens for AI coding tools, so we take security reports seriously.

## Supported versions

Only the latest release gets security fixes. Please upgrade before reporting:

```bash
curl -fsSL https://raw.githubusercontent.com/Techiebutler/ai-switch/main/install.sh | bash
```

## Reporting a vulnerability

**Do not open a public issue.** Report it privately through GitHub instead:

1. Go to the [Security tab](https://github.com/Techiebutler/ai-switch/security) of this repository.
2. Click **Report a vulnerability** and describe the problem, how to reproduce it, and its impact.

Never include real tokens or credentials in a report. Use fake values.

What to expect:

- an acknowledgement within 3 business days
- an assessment and a plan within 10 business days
- credit in the release notes once a fix ships, unless you'd rather stay anonymous

## Scope

In scope:

- saved tokens leaking to other users, files, logs, the network or the terminal
- profile data stored with weaker permissions than documented
- one account's login being written into another account's profile
- anything that lets a profile name or file content escape `~/.ai-switch` or run commands

Known and documented, so out of scope:

- on macOS, a token is briefly visible to other processes of the **same user** while it is written to the Keychain (see Security notes in the README)
- anyone who already has access to your user account can read the logins, just as they could read the tools' own login files
- vulnerabilities in Claude Code, Codex or Cursor themselves (report those to their vendors)
