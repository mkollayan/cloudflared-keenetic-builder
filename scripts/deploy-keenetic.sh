#!/bin/sh

set -eu

MODEM_HOST="${MODEM_HOST:-192.168.1.1}"
MODEM_USER="${MODEM_USER:-admin}"
BINARY="${BINARY:-derlenenler/cloudflared-mips}"
REMOTE_BIN="${REMOTE_BIN:-/opt/home/cloudflared}"
INIT_SCRIPT="${INIT_SCRIPT:-/opt/etc/init.d/S99cloudflared}"

TARGET="${MODEM_USER}@${MODEM_HOST}"
REMOTE_TMP="${REMOTE_BIN}.new"
REMOTE_BAK="${REMOTE_BIN}.bak"

die() {
  echo "deploy-keenetic: $*" >&2
  exit 1
}

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    die "sha256sum or shasum is required locally"
  fi
}

validate_remote_path() {
  case "$1" in
    /*) ;;
    *) die "remote path must be absolute: $1" ;;
  esac

  case "$1" in
    *"'"*) die "remote path contains unsupported characters: $1" ;;
  esac
}

[ -f "$BINARY" ] || die "binary not found: $BINARY"
[ -s "$BINARY" ] || die "binary is empty: $BINARY"
validate_remote_path "$REMOTE_BIN"
validate_remote_path "$INIT_SCRIPT"

LOCAL_SHA="$(hash_file "$BINARY")"

echo "Target: $TARGET"
echo "Binary: $BINARY"
echo "Local SHA256: $LOCAL_SHA"
echo "Uploading to $REMOTE_TMP via ssh exec sh..."

ssh "$TARGET" "exec sh -c \"cat > '$REMOTE_TMP'\"" < "$BINARY"

echo "Installing on router..."
ssh "$TARGET" "exec sh -s" <<REMOTE
set -eu

REMOTE_TMP='$REMOTE_TMP'
REMOTE_BIN='$REMOTE_BIN'
REMOTE_BAK='$REMOTE_BAK'
INIT_SCRIPT='$INIT_SCRIPT'
LOCAL_SHA='$LOCAL_SHA'

[ -s "\$REMOTE_TMP" ] || {
  echo "uploaded file is missing or empty: \$REMOTE_TMP" >&2
  exit 1
}

if command -v sha256sum >/dev/null 2>&1; then
  REMOTE_SHA="\$(sha256sum "\$REMOTE_TMP" | awk '{print \$1}')"
  echo "Remote SHA256: \$REMOTE_SHA"
  if [ "\$REMOTE_SHA" != "\$LOCAL_SHA" ]; then
    echo "checksum mismatch" >&2
    exit 1
  fi
else
  echo "Remote sha256sum not available; skipping remote checksum verification"
fi

chmod +x "\$REMOTE_TMP"

if [ -x "\$INIT_SCRIPT" ]; then
  "\$INIT_SCRIPT" stop || true
fi

if [ -f "\$REMOTE_BIN" ]; then
  cp "\$REMOTE_BIN" "\$REMOTE_BAK"
fi

mv "\$REMOTE_TMP" "\$REMOTE_BIN"
chmod +x "\$REMOTE_BIN"

if [ -x "\$INIT_SCRIPT" ]; then
  "\$INIT_SCRIPT" start
  "\$INIT_SCRIPT" status
else
  echo "init script not found or not executable: \$INIT_SCRIPT" >&2
  exit 1
fi
REMOTE

echo "Deploy completed."
