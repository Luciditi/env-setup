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
| 2 | Lint configs in CI | `env-setup-8gz` | **done** |
| 3 | 24.04 + `HOMEBREW_NO_*` + matrix | `env-setup-jpu` | **done** |
| 4 | Testability refactor + bats | `env-setup-6tw` | **done** |
| 5 | `vm` subcommands + `_vm`/`_remote` | `env-setup-4dd` | **done** |
| 6 | `infra/` move | `env-setup-1z6` | **done** |
| 7 | Docker config de-dup | `env-setup-sly` | **done** |
| 8 | Warm base artifact | `env-setup-ba1` | ready (unblocked by 3) |
| 9 | Tart E2E harness | `env-setup-8m1` | blocked by 4, 5 |
| 10 | Exportable config | `env-setup-3xm` | ready |
| 11 | Docs, ratchets, tag | `env-setup-8oh` | blocked by 7, 8, 9, 10 |

### Uncommitted changes so far

```
.shellcheckrc             .yamllint.yml             .ansible-lint
.pre-commit-config.yaml   .github/workflows/lint.yml
default.config.yml        scripts/aliases           scripts/add-playbook
scripts/env-setup         scripts/linux/install-ansible
scripts/macos/install-ansible                       terraform/scripts/* (9)
vm/scripts/* (7)          tests/* (3)               PLAN.md
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

**Validated:** GitHub Actions workflow run `39089855401` ran against `v3` (`mini`
config, `version=0.0.0-test`) and completed with `success` in 13m17s (initial cold
build, with `buildcache-mini` pushed to GHCR for fast subsequent runs). The 6h burn
is empirically confirmed fixed.

## Done — PR 2 (`env-setup-8gz`)

- Landed `.shellcheckrc` with `external-sources=true`, `source-path=SCRIPTDIR:.`,
  `enable=check-unassigned-uppercase`, and `disable=SC2250,SC2312,SC2292`.
- Replaced all 19 inline `# shellcheck source=/dev/null` directives across `scripts/`,
  `terraform/scripts/`, and `vm/scripts/` with `# shellcheck source=scripts/_common`.
- Added `# shellcheck disable=SC2154` to `scripts/aliases` for exported shell variables.
  **ShellCheck now runs 100% clean across all 24 shell scripts.**
- Fixed `default.config.yml` duplicate empty key definitions at lines 268-269.
- Added `.yamllint.yml` with `key-duplicates: error` and warn-only legacy styling rules.
- Added `.ansible-lint` (`profile: min`).
- Added `.pre-commit-config.yaml` supporting both `prek` and `pre-commit` for local git hooks.
- Added `.github/workflows/lint.yml` to enforce ShellCheck, yamllint, and ansible-lint in CI.

## Done — PR 4 (`env-setup-6tw`)

- Extracted `parse_flags()` and `main()` from `scripts/env-setup`.
- Added inert sourcing guard: `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi`.
- Fixed getopts loop shifting: stopped shifting inside loop for `-C`, `-i`, `-s`, `-t`, `-v`,
  and declared `s:`/`t:` with arguments so `$OPTARG` is populated cleanly without corrupting `OPTIND`.
- Fixed `ANSIBLE_TAG_FLAGS` clobbering bug: multiple tags (`-s` and `-t`) now append properly.
- Fixed `PATH` precedence: appended `/usr/local/bin` rather than prepending, preserving test stubs.
- Guarded `config()` interactive `select` loops with `[[ "$ENVSETUP_INTERACT" == "1" ]]`.
- Created `tests/test_helper.bash` with PATH-stub harness recording invocations for `ansible`,
  `ansible-playbook`, and `ansible-galaxy` in isolated scratch directories.
- Built Bats test suites (`tests/cli.bats` and `tests/regression_pr1.bats`) with 18 tests passing 100% green.
- Added Bats test hook to `.pre-commit-config.yaml` and `.github/workflows/lint.yml`.

## Done — PR 5 (`env-setup-4dd`)

- Created `scripts/_vm` with name-targeted Tart VM operations (`vm_exists`, `vm_running`,
  `vm_ip`, `vm_start`, `vm_stop`, `vm_create`, `vm_delete`, `vm_find_running`).
  Guaranteed safe discovery: never touches or targets the host's `vpn` VM.
- Created `scripts/_remote` with SSH/SCP helper routines (`remote_exec`, `remote_copy`)
  using `TART_SSH_*` credentials from `_common`.
- Implemented modular subcommands in `scripts/vm/*` (`create`, `start`, `stop`, `status`,
  `ssh`, `scp`, `env-setup`, `init`).
- Converted all 7 legacy scripts in `vm/scripts/*` into backward-compatible forwarding shims
  that emit a stderr deprecation warning and forward execution to `scripts/vm/*`.
- Wired `scripts/env-setup vm <subcommand>` dispatch directly before Ansible checks.
- Updated `-A` aliases in `scripts/env-setup` to point to `$INSTALL_DIR/scripts/vm/*` with
  a deprecation notice on stderr so `eval "$(env-setup -A)"` remains clean.
- Fixed duplicate empty macos settings keys in `docker/default.config.yml`.
- Added 20 new Bats tests in `tests/vm.bats` and updated `tests/cli.bats` (now 38 Bats
  tests passing 100% green).
- ShellCheck, yamllint, ansible-lint, and Bats tests all passing 100% clean locally.

## Done — PR 6 (`env-setup-1z6`)

- Moved `docker/` -> `infra/docker/`.
- Moved `terraform/` -> `infra/terraform/`.
- Moved `router/` -> `infra/router/`.
- Removed obsolete `vm/` directory and shims.
- Updated `infra/terraform/scripts/*` (9 scripts) to source `scripts/_common` from `../../../scripts/_common`.
- Updated `.github/workflows/deploy-image.yml`, `.github/workflows/tf.yml`, `.github/workflows/lint.yml`, and `.pre-commit-config.yaml`.
- Updated documentation links in `README.md`, `DEV-README.md`, `CONTRIBUTING.md`, and `infra/docker/README.md`.
- Removed legacy `vm/scripts/ssh` shim test in `tests/vm.bats`.
- Verified with Bats (37/37 passing), ShellCheck (0 findings), and pre-commit (all passing).

## Done — PR 7 (`env-setup-sly`)

- Consolidated configuration changes into the canonical root manifests:
  - Repointed `git_repo_projects` in `default.config.yml`, `.mini.config.yml`, and `.most.config.yml` to `git@github.com:Luciditi/env-setup.git`.
  - Commented out `#- duti` in `default.config.yml` and `.most.config.yml` (Cocoa UTI tool managed on macOS via `08-prefs/duti.yml`, avoiding Linuxbrew issues).
  - Added `sijanc147/formulas` tap to `.most.config.yml` for `macprefs`.
- Deleted redundant duplicate config manifests:
  - `infra/docker/default.config.yml`
  - `infra/docker/.mini.config.yml`
  - `infra/docker/.most.config.yml`
  - `infra/docker/.none.config.yml`
- Updated `.github/workflows/deploy-image.yml` dispatch options, defaults, matrix paths, and case statement to point directly to root config manifests.
- Updated `.github/workflows/tf.yml` fallback default to `default.config.yml`.
- Updated `infra/docker/README.md` and `CONTRIBUTING.md` documentation references.
- Verified with Bats (37/37 passing), ShellCheck (0 findings), yamllint (clean), and full `pre-commit run --all-files` (all 4 hooks green).

---

## Next up

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
