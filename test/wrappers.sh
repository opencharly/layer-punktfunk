#!/bin/sh
# Exercises the SHIPPED container-venue wrappers against stubs.
#
# These wrappers are the container venue's entire launch path — supervisord cannot use a
# systemd USER unit — so their behaviour needs a gate that fails when they break. A pod bed
# proves them end to end, but it needs an image build; this runs in seconds and covers what
# the scripts themselves promise: the readiness gate, the env-file sourcing, the exports the
# packaged unit sets, and reaching exec.
#
# The binary/init paths are env-overridable in the wrappers precisely so the real scripts
# (not copies) can be driven here.
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
fails=0
ok()   { printf '  PASS  %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fails=$((fails+1)); }

newhome() {
    H="$(mktemp -d)"; mkdir -p "$H/.config/punktfunk"; printf '%s' "$H"
}

# --- 1. web wrapper: fails closed when the host never writes its token -------------
H="$(newhome)"
out="$(HOME="$H" PUNKTFUNK_READY_TIMEOUT=1 PUNKTFUNK_WEB_INIT=/nonexistent \
      PUNKTFUNK_WEB_SERVER_BIN=/bin/true sh "$ROOT/punktfunk-web-wrapper" 2>&1 || true)"
if printf '%s' "$out" | grep -q 'never appeared'; then
    ok "web: fails closed with a named cause when mgmt-token never appears"
else
    bad "web: expected a 'never appeared' diagnostic, got: $out"
fi
rm -rf "$H"

# --- 2. web wrapper: sources the env files and sets the unit's environment ---------
H="$(newhome)"
printf 'PUNKTFUNK_MGMT_TOKEN=%s\n' deadbeef > "$H/.config/punktfunk/mgmt-token"
printf 'PUNKTFUNK_UI_PASSWORD=%s\n' hunter2  > "$H/.config/punktfunk/web-password"
stub="$H/stub-server"
cat > "$stub" <<'STUB'
#!/bin/sh
printf 'TOKEN=%s PASS=%s PORT=%s HOST=%s CERT=%s KEY=%s SECURE=%s\n' \
  "${PUNKTFUNK_MGMT_TOKEN:-}" "${PUNKTFUNK_UI_PASSWORD:-}" "${PORT:-}" "${HOST:-}" \
  "${PUNKTFUNK_UI_TLS_CERT:-}" "${PUNKTFUNK_UI_TLS_KEY:-}" "${PUNKTFUNK_UI_SECURE:-}"
STUB
chmod +x "$stub"
init_marker="$H/init-ran"
initsh="$H/web-init.sh"; printf '#!/bin/sh\ntouch %s\n' "$init_marker" > "$initsh"; chmod +x "$initsh"
out="$(HOME="$H" PUNKTFUNK_WEB_INIT="$initsh" PUNKTFUNK_WEB_SERVER_BIN="$stub" \
      sh "$ROOT/punktfunk-web-wrapper" 2>&1)"
[ -f "$init_marker" ] && ok "web: runs web-init.sh (the readiness gate) before the server" \
                       || bad "web: web-init.sh was not run"
case "$out" in
  *"TOKEN=deadbeef"*)   ok "web: sources mgmt-token (KEY=VALUE env-file form)" ;;
  *) bad "web: mgmt-token not sourced: $out" ;;
esac
case "$out" in
  *"PASS=hunter2"*)     ok "web: sources the optional web-password" ;;
  *) bad "web: web-password not sourced: $out" ;;
esac
case "$out" in
  *"PORT=47992 HOST=0.0.0.0"*) ok "web: sets the unit's PORT/HOST" ;;
  *) bad "web: PORT/HOST wrong: $out" ;;
esac
case "$out" in
  *"SECURE=1"*) ok "web: enables TLS (PUNKTFUNK_UI_SECURE)" ;;
  *) bad "web: PUNKTFUNK_UI_SECURE not set: $out" ;;
esac
case "$out" in
  *"CERT=$H/.config/punktfunk/cert.pem"*) ok "web: points at the legacy cert pair the server falls back from" ;;
  *) bad "web: TLS cert path wrong: $out" ;;
esac
rm -rf "$H"

# --- 3. scripting wrapper: waits for the host, then execs -------------------------
H="$(newhome)"
out="$(HOME="$H" PUNKTFUNK_READY_TIMEOUT=1 PUNKTFUNK_SCRIPTING_BIN=/bin/true \
      sh "$ROOT/punktfunk-scripting-wrapper" 2>&1 || true)"
case "$out" in
  *"never appeared"*) ok "scripting: fails closed when the host never starts" ;;
  *) bad "scripting: expected a 'never appeared' diagnostic, got: $out" ;;
esac
printf 'PUNKTFUNK_MGMT_TOKEN=%s\n' deadbeef > "$H/.config/punktfunk/mgmt-token"
stub2="$H/stub-runner"; printf '#!/bin/sh\necho RUNNER-EXECED\n' > "$stub2"; chmod +x "$stub2"
out="$(HOME="$H" PUNKTFUNK_SCRIPTING_BIN="$stub2" sh "$ROOT/punktfunk-scripting-wrapper" 2>&1)"
case "$out" in
  *RUNNER-EXECED*) ok "scripting: execs the runner once the host's token exists" ;;
  *) bad "scripting: runner not exec'd: $out" ;;
esac
rm -rf "$H"

if [ "$fails" -ne 0 ]; then
    printf '\n%d wrapper check(s) FAILED\n' "$fails"; exit 1
fi
printf '\nall wrapper checks passed\n'
