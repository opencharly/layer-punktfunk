# layer-punktfunk

The `layer-punktfunk` candy of the [opencharly/charly](https://github.com/opencharly/charly)
candy library, as a standalone repo (kind-prefixed naming). The candy manifest lives at
the repo root; the charly resolver fetches this repo at the pinned tag.

Installs the [punktfunk](https://git.unom.io/unom/punktfunk) streaming host — the
`punktfunk/1` QUIC host daemon, its browser console and its plugin runner — from unom's
signed pacman repository on Arch and CachyOS.

Probing and managing a running host is the `punktfunk:` check verb, served out-of-process
by [`plugin-punktfunk`](https://github.com/opencharly/plugin-punktfunk).
