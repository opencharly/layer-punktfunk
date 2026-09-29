# AGENTS.md — layer-punktfunk

Standalone candy repo for the `punktfunk` layer — the punktfunk streaming host
(the `punktfunk/1` QUIC host daemon, its browser console, and its plugin runner),
installed from unom's signed pacman repo on Arch/CachyOS. The candy lives in
`charly.yml` at the repo root, including the embedded `skill:` entity projected
into the marketplace corpus as `/charly-punktfunk:punktfunk-host`.

Canonical files:

- `charly.yml` — the `punktfunk:` candy entity (the `distro.arch:` package + repo
  sections, the two `service:` forms, the wrapper installs, the `host.env` write,
  and the `check:` probes) and the `punktfunk-host-skill:` skill entity.
- `punktfunk-host-wrapper`, `punktfunk-web-wrapper`, `punktfunk-scripting-wrapper`
  — the container-venue launcher wrappers.
- `test/wrappers.sh` — wrapper test.
- `.github/workflows/tag-on-merge.yml` — CalVer tag + `CHANGELOG/` on merge.
- `README.md` — user overview only; never agent guidance.

## Load these skills first (R0)

- `/charly-punktfunk:punktfunk-host` — the owning skill. The two service forms,
  the wrapper readiness idiom, the `host.env` pins, and the token-file shape.
  Load before editing or troubleshooting the candy.
- `/charly-check:punktfunk` — the `punktfunk:` check verb that probes and manages
  a running host.
- `/charly-image:layer` — the candy authoring reference (`charly.yml` schema,
  `plan:` step verbs incl. `check:`, the `distro:` cascade, `service:` forms).

## Build / validate / test

- The merge gate is the **org-wide** `charly/pr-validator` (required check
  `validate / validate`, defined in `opencharly/.github`); this repo has **no
  per-repo candy gate** and ships only `.github/workflows/tag-on-merge.yml`.
- `charly box validate` at the repo root checks the manifest parses and
  validates.
- `test/wrappers.sh` exercises the launcher wrappers.
- The candy's `plan:` `check:` steps split into build-context (binary, packages,
  key trust, repo stanza, `host.env`) and runtime probes (wrapper present,
  user-unit enabled on a systemd venue, web console live, management API live).
  The runtime probes are driven by the `check-punktfunk-pod` /
  `check-punktfunk-vm` beds in `distro-cachyos`.
- Two venue-scoped probes report an explicit `N/A` on the venue they do not
  apply to (the container wrapper on a systemd venue; the packaged user unit in a
  container) rather than passing mute.

## Modify this repo

- Edit the `punktfunk:` candy entity AND the `punktfunk-host-skill:` skill entity
  in `charly.yml` together. The skill is the projected usage source, so a version,
  port, or service change not mirrored in the skill leaves the corpus stale.
- Keep the repo stanza and key byte-identical to the client candy's; do not
  "fix" the pacman `$repo`/`$arch` variables into literals — the pac install
  template emits them inside a single-quoted `printf` for pacman to expand.
- The wrapper readiness wait (Wayland socket, then sway's IPC socket) is
  load-bearing: punktfunk creates its virtual output via `swaymsg create_output`.
- Never `setcap` `punktfunk-host` — capabilities belong on
  `punktfunk-encode-worker`.

## Landing

- PR-only. Every change lands through a pull request; the org-required
  `charly/pr-validator` validates the diff and body and arms native auto-merge
  on PASS. Direct pushes to `main` are blocked.
- History lives in `CHANGELOG/` (written by `tag-on-merge` at merge time); the
  PR body IS the changelog.
- The authoritative rulebook is the umbrella `AGENTS.md` in
  `opencharly/opencharly` and `charly/AGENTS.md` in the charly repo. Do not
  restate its rules here.
