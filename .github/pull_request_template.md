## What and why

<!-- What does this change, and what problem does it solve? Link the issue: "Fixes #123" -->

## How it was tested

<!-- Commands you ran, and on which OS. Manual testing should use a temporary HOME with fake tokens. -->

## Checklist

- [ ] `tests/test.sh` passes, with new tests for any behavior change
- [ ] `shellcheck install.sh tests/test.sh` and `python3 -m py_compile ai-switch` pass
- [ ] README and CHANGELOG (**Unreleased**) updated if behavior or usage changed
- [ ] No real tokens, credential files or personal emails anywhere in the diff, tests or PR text
