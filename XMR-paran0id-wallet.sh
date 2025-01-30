#!/bin/bash
set +o history 2>/dev/null || true
XMR_WALLET="/path/to/monero-wallet-cli"
 #$(find /*/*/* -type f -executable -name "monero-wallet-cli" 2>/dev/null)
if [ ! -f "$XMR_WALLET" ]; then
    echo "Error: monero-wallet-cli not found at $XMR_WALLET" >&2
    exit 1
fi
if [ ! -x "$XMR_WALLET" ]; then
    echo "Error: monero-wallet-cli is not executable" >&2
    exit 1
fi
TMPDIR=$(mktemp -d)
chmod 700 "$TMPDIR"
cd "$TMPDIR" || exit 1
clear


ENTROPY=$(zenity --entry \
    --title="Wallet Generator" \
    --text="Enter additional entropy (random characters):" \
    --hide-text) || exit 1

echo "$ENTROPY" > "$TMPDIR/ENTROPY"
stty sane
$XMR_WALLET --password password --generate-new-wallet $TMPDIR/paranoid-monero-wallet --extra-entropy $TMPDIR/ENTROPY --mnemonic-language English --command seed --command exit

ENTROPY=$(head -c 32 /dev/urandom | tr -dc 'A-Za-z0-9')
ENTROPY=""
unset ENTROPY

cd / || exit 1
find "$TMPDIR" -type f -exec shred -uzn 3 {} \;
rm -rf "$TMPDIR"

if command -v srm >/dev/null 2>&1; then
    srm -v "$TMPDIR"
elif command -v shred >/dev/null 2>&1; then
    shred -uzv "$TMPDIR"
else
    echo "Warning: Secure deletion tools not found, using regular delete"
    rm -rf "$TMPDIR"
fi
set -o history 2>/dev/null || true
