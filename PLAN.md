# env-setup v3.0.0 — Working Plan

Resume doc for the v3.0.0 overhaul. Full design rationale lives in
`~/.claude/plans/we-re-working-on-an-refactored-petal.md`; issue tracking is in
beads (`bd ready`, `bd show <id>`).

**Branch:** `v3` · **Nothing is committed** — the user commits and pushes.

---

## Ground rules for this work

- **Do not execute Ansible playbooks on the host.** Both `.00-init/.init` markers
  are ABSENT, so any invocation of `scripts/env-setup` that reaches MAIN will run
  the init playbook against the real machine. Safe flags only: `-h`, `-A`, `-c`,
  `-e`. For `config()` testing, point `ENVSETUP_INSTALL_DIR` at a scratch dir.
- **Never touch the `vpn` Tart VM.** It is important and unrelated. All harness
  VMs are `es-*`-prefixed; discovery must match by exact name.
- Don't commit or push. Report changed files + validation at handoff.
- `cd` inside a compound Bash command trips a permission prompt — use `env -C`.

---

## Status

| PR | Scope | Issue | State |
|----|-------|-------|-------|
| 1 | Foundation fixes (`_common`, 7 bugs) | `env-setup-8k5` | **done** |
| 2 | Lint configs in CI | `env-setup-8gz` | ready |
| 3 | 24.04 + `HOMEBREW_NO_*` + matrix | `env-setup-jpu` | **done** |
| 4 | Testability refactor + bats | `env-setup-6tw` | ready |
| 5 | `vm` subcommands + `_vm`/`_remote` | `env-setup-4dd` | ready |
| 6 | `infra/` move | `env-setup-1z6` | blocked by 5 |
| 7 | Docker config de-dup | `env-setup-sly` | blocked by 6 |
| 8 | Warm base artifact | `env-setup-ba1` | ready (unblocked by 3) |
| 9 | Tart E2E harness | `env-setup-8m1` | blocked by 4, 5 |
| 10 | Exportable config | `env-setup-3xm` | blocked by 5 |
| 11 | Docs, ratchets, tag | `env-setup-8oh` | blocked by 7, 8, 9, 10 |

### Uncommitted changes so far

```
scripts/_common       scripts/env-setup     scripts/add-playbook
scripts/init          scripts/aliases       docker/Dockerfile
.github/workflows/deploy-image.yml          .claude/settings.json
PLAN.md
```

---

## Done — PR 1 (`env-setup-8k5`)

`_common` hardened: `ENVSETUP_DIR` now derives from `${BASH_SOURCE[0]}` (was `$0`,
which resolved to `<repo>/vm` for nested callers); `readonly LOG_FILE` dropped so
the file can be sourced twice; `set -euo pipefail` moved out of the library —
verified safe because all 22 consumers already declare it. Added `TART_SSH_*` and
`ENVSETUP_REMOTE_DIR` for PR 5.

Seven bugs fixed, each verified by execution:

- `-c <unknown>` used to `rm` the gitignored `config.yml` before validating → now
  exits 1 with the file intact.
- `ls -l | cut -d'>'` config detection → `readlink`, with `-L` tested before `-f`.
- `-e` targeted `$ENVSETUP_DIR` while `config()` used `$INSTALL_DIR` → unified;
  also errors cleanly when `$EDITOR` is unset.
- `PWD=$(pwd)` clobbered bash's magic var, breaking `env-setup all` → `PREV_DIR`.
- `python3` user-base path ran unconditionally on Linux, fatal under `set -e`.
- `add-playbook` referenced undefined `$SUGGEST_ANSIBLE` (**100% broken on
  Linux**); missing-name returned 0 instead of 1.
- `update()` reassigned `ENVSETUP_DIR`, `rm tmp/localhost` was unguarded, and an
  empty dotfiles path would `cd ""`.

**shellcheck: 13 findings → 0** across all 23 shell files.

> Gotcha: a prose comment starting with `# shellcheck` is parsed as a malformed
> directive (SC1072/SC1073). A file-level `disable=` must precede the first
> command, not merely sit near the top.

## Done — PR 3 (`env-setup-jpu`)

**Root cause proven empirically**, not inferred:

| | glibc | libstdc++ | Homebrew floor |
|---|---|---|---|
| `ubuntu:20.04` | **2.31** | **6.0.28** | ✗ both breached |
| `ubuntu:24.04` | 2.39 | 6.0.33 | ✓ cleared exactly |

Floors are `LINUX_GLIBC_CI_VERSION = "2.39"` and
`LINUX_LIBSTDCXX_CI_VERSION = "6.0.33"` in `Homebrew/os.rb:61,64`, consumed by
`needs_libc_formula?` / `needs_compiler_formula?`
(`extend/os/linux/development_tools.rb:59,80`). Below either floor, Homebrew
source-builds glibc **and** gcc into every dependency chain. That is why `.none`
(empty package list) passed in ~5 min while `.mini` (15 formulae) died exactly
like `.most` (32) — the failure never scaled with package count.

`docker/Dockerfile`: `VER` 20.04 → 24.04; four `HOMEBREW_NO_*` vars (no
`HOMEBREW_NO_AUTO_UPDATE` meant a full homebrew-core fetch per serial install);
`TZ=US` → `Etc/UTC` (invalid zone); dropped a redundant `add-apt-repository`.
**`deps` stage smoke-built green on 24.04** — ansible resolved to
`14.5.0-1ppa~noble`, `python3-apt` fine, clearing the plan's risk #5.

`.github/workflows/deploy-image.yml` rewritten:

- `gh workflow run` fan-out → a real `strategy.matrix` driven by a `setup` job.
  The fan-out started four *separate* workflow runs, so the tag's own check went
  green in ~11s while the children failed unnoticed for 10 months.
- Per-job `timeout-minutes` 15/25/30/45 (previously unset → 6h cap).
- `release` now `needs: [image]` — a tag can no longer publish a Homebrew formula
  for an image that failed to build, which is how v2.0.0 shipped.
- Tag glob `v[0-9].[0-9].[0-9]` → `v[0-9]+.[0-9]+.[0-9]+` (couldn't match v2.10.0).
- Registry cache replaces `type=gha` (branch-scoped, 7-day evicted, 10GB budget —
  which is why `gh api .../actions/caches` showed zero buildx caches).
- Added `pull_request` (builds `none`+`mini` only) and a weekly `schedule`.
- Dropped `setup-qemu-action` — linux/amd64 on an amd64 runner.

Matrix planning simulated across all 8 trigger paths; all emit valid JSON and the
bogus-config path fails fast.

**Not yet validated:** no CI run has executed. First action on resume should be
`gh workflow run deploy-image.yml -f config=docker/.mini.config.yml -f version=0.0.0-test`
and confirm it completes in ≤8 min. That is the empirical proof the 6h burn is fixed.

---

## Next up

### PR 2 — lint in CI (`env-setup-8gz`), independent, small

shellcheck already passes clean. Land `.shellcheckrc` with `external-sources=true`,
`source-path=SCRIPTDIR`, `enable=check-unassigned-uppercase` (SC2154 — the class
that caught `$SUGGEST_ANSIBLE`), and `disable=SC2250,SC2312,SC2292` (261+37+14
style findings; ratchet later).

**Critical:** the 19 inline `# shellcheck source=/dev/null` annotations *defeat*
`external-sources` and produce 56 false SC2154s. Replace with
`# shellcheck source=scripts/_common`.

Discovery is shebang-based (`git grep -lIz -E '^#!(/usr/bin/env bash|/bin/bash)'`)
since scripts have no `.sh` extension; `scripts/aliases` already carries a
`# shellcheck shell=bash` directive (added in PR 1).

yamllint: land warn-only first. Expect failures on widespread trailing whitespace,
`truthy` (`become: yes`), `octal-values` (`mode: 0440`), and missing
`document-start`. `key-duplicates` catches a **real bug**: `default.config.yml`
defines `envsetup_os_macos_settings` and `..._sudo_settings` at lines 268-269 then
redefines both at 276/278 — the first pair is silently discarded.

ansible-lint at `profile: min`. **Blocker:** `vars_files: ../../../default.config.yml`
is playbook-dir-relative and `run_playbook()` `cd`s there first, so running from
the repo root fails `load-failure` on all 18 playbooks. Drive per-directory,
naming `.00-init` explicitly (ansible-lint skips hidden paths).

Neither `yamllint` nor `ansible-lint` is installed locally (`ansible-lint` is at
`~/.local/bin`). `bats`, `shellcheck`, `tart` 2.30.0, `sshpass` are present.

### PR 4 — testability + bats (`env-setup-6tw`)

Extract `parse_flags()`/`main()` from `scripts/env-setup` and add
`if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi` so the file sources
inertly. Build the PATH-stub harness recording argv. Highest-value regression
tests are the seven PR-1 bugs — write them RED against `git stash`ed originals if
possible, then confirm GREEN.

### PR 5 — vm subcommands (`env-setup-4dd`)

`getopts` already halts at the first non-flag word; only two changes needed: stop
shifting *inside* the loop (the current per-case `shift "$((OPTIND-1))"` corrupts
`OPTIND`) and declare `s:`/`t:` as taking arguments.

Name-targeted discovery is the core fix — current code picks the first running VM:
```bash
vm_running() { tart list --source local --format json \
  | jq -er --arg n "$1" 'map(select(.Name==$n and .State=="running"))|length>0' >/dev/null; }
```
Keep `-A` emitting byte-identical alias *names* (users have `eval "$(env-setup -A)"`
in their shells); deprecation notice to **stderr** so `eval` stays clean. `-A`
currently still points at `vm/scripts/*` — repoint to `scripts/vm/*` in this PR.

### PR 8 — warm base (`env-setup-ba1`), unblocked by PR 3

Split `Dockerfile.base` (24.04 + brew + ansible + galaxy reqs + the
`mini ∩ default ∩ most` formula intersection) → ghcr, keyed on `hashFiles` with a
`docker manifest inspect` probe. One intersection generator, one unit test, two
consumers (`Dockerfile.base` + `env-setup vm warm`).

### PR 9 — Tart E2E (`env-setup-8m1`), local-only

tart 2.30.0 has **no `snapshot` subcommand** (verified). Restore primitive is
`tart clone <stopped-local-base>` (APFS CoW, ~1-2s); teardown is stop+delete of
the ephemeral. `tart suspend` is *not* a restore point. `tart ip --wait <s>`
replaces polling. `tart exec` needs a guest agent the `-vanilla` images lack —
switch `TART_MACOS_NAME` to `macos-tahoe-base` or stay ssh-only. Note the local
machine has `macos-sequoia-base` pulled, not `tahoe`.

Highest-value assertion, free because the CLI already passes the callback through:
```bash
assert_idempotent() {  # 2nd run must report changed=0
  vm_ssh "$1" "ENVSETUP_INTERACT=0 ANSIBLE_SUDO=-n env-setup $2" >/dev/null
  out=$(vm_ssh "$1" "ENVSETUP_INTERACT=0 ANSIBLE_SUDO=-n ANSIBLE_STDOUT_CALLBACK=json env-setup $2")
  [[ "$(jq '[.stats[].changed]|add' <<<"$out")" == "0" ]]
}
```

### PR 10 — export (`env-setup-3xm`)

Ansible playbook, not bash. Name it **`.09-export`** with the leading dot — load-bearing,
because `find "$PLAYBOOKS/"*` skips dot-dirs, keeping it out of the menu and out of
`env-setup all`. `brew bundle dump --file=- --no-restart` covers taps/brews/casks/mas/vscode
in one call and is installed-on-request-aware.

Two corrections to the `origin/export` markers: `cargo_packages` needs
`cargo install --list`, not `ls ~/.cargo/bin` (binary names ≠ crate names —
`bore` vs `bore-cli`); and `duti` **cannot enumerate** handlers, only answer
`duti -x <ext>`. Confirmed `origin/export:.none.config.yml` is byte-identical to
main's, so the template rebase is clean.

---

## Deferred

- **Brewfile / `brew bundle`** replacing the per-package `loop:` in
  `ansible/{linux,macos}/02-cli` — its own plan, per the user. The warm base does
  *not* fix this for delta formulae.
- Self-hosted macOS runner for Tart E2E (local-only for now).
- `origin/cloudshell` (1 commit, `docker/Dockerfile.cloudshell`) — untouched.
