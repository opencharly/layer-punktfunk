# punktfunk

The [punktfunk](https://git.unom.io/unom/punktfunk) streaming **host** for
OpenCharly images — the `punktfunk/1` QUIC host daemon, its browser console, and
its plugin runner, installed from unom's signed pacman repository on Arch/CachyOS.

The candy lands three packages (`punktfunk-host`, `punktfunk-web`,
`punktfunk-scripting`), the `[punktfunk]` repo stanza with its locally-signed
release key, and a `host.env` policy file pinning the wlroots compositor backend,
the virtual video source, and the software encoder so the host runs on a headless
seat with no GPU.

## What it provides

| Property | Value |
|---|---|
| Layer / candy | `punktfunk` |
| Packages | `punktfunk-host`, `punktfunk-web`, `punktfunk-scripting` |
| Repo | `[punktfunk]` in `/etc/pacman.conf`, `SigLevel = Required DatabaseOptional` |
| Key | fetched + `pacman-key --lsign-key`'d; fingerprint `E0CA04465C99C936E0B0C6510A317015A34DDD69` |
| Ports | `udp:9777` (native QUIC), `https+insecure:47990` (management API), `https+insecure:47992` (web console) |
| Config | `~/.config/punktfunk/host.env` |
| Distros | Arch **and** CachyOS (one `distro.arch:` section) |

## Two service forms

punktfunk is a systemd **user** service upstream, so the candy ships two forms:

- **systemd venue** (VM/host deploy): the packaged `punktfunk-host`,
  `punktfunk-web`, and `punktfunk-scripting` units are enabled with
  `scope: user`; the candy enables lingering so they run without a login.
- **container venue**: supervisord cannot use a systemd user unit, so the host
  runs through the candy's own `punktfunk-host-wrapper`, which waits for the
  Wayland socket and then sway's IPC socket before exec'ing the host.

## The capture path

A compositor alone does not get frames out. A session resolves to
`capture: Portal`, so the host asks **xdg-desktop-portal**'s ScreenCast interface
to create the virtual output and receives frames over **PipeWire**. A venue
therefore also needs `layer-xdg-portal` and `pod-pipewire` — this candy does not
pull them in; compose them in the image.

## How to use it

Compose the layer by pinning this repo in a box's `candy:` list, then probe the
running host with the `punktfunk:` check verb:

```bash
charly check run check-punktfunk-pod
```

## Layout

- `charly.yml` — the `punktfunk:` candy entity (the `distro.arch:` package + repo
  sections, the two `service:` forms, the wrapper installs, the `host.env` write,
  and the `check:` probes) and the embedded `punktfunk-host-skill:` skill entity.
- `punktfunk-host-wrapper`, `punktfunk-web-wrapper`, `punktfunk-scripting-wrapper`
  — the container-venue launcher wrappers.
- `test/wrappers.sh` — wrapper test.
- `.github/workflows/tag-on-merge.yml` — CalVer tag + `CHANGELOG/` on merge.
- `README.md` — this user overview.

## Related

- Owning skill: `/charly-punktfunk:punktfunk-host`
- Probe verb: `/charly-check:punktfunk`
- Client sibling: [`layer-punktfunk-client`](https://github.com/opencharly/layer-punktfunk-client)
- Beds (in `distro-cachyos`): `check-punktfunk-pod`, `check-punktfunk-vm`
- [`opencharly/charly`](https://github.com/opencharly/charly) — the charly CLI and image builder
- [`opencharly/opencharly`](https://github.com/opencharly/opencharly) — the umbrella
