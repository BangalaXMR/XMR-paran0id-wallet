#!/bin/bash

{
    # Outer loop for the entire process
    while true; do
        {
            echo "Debug: Starting script..." >&2
            # Disable history
            unset HISTFILE
            HISTSIZE=0
            HISTFILESIZE=0
            export HISTFILE=/dev/null
            set +o history 2>/dev/null || true

            echo "Debug: Creating temp directory..." >&2
            # Create secure temporary directory
            TMPDIR=$(mktemp -d)
            chmod 700 "$TMPDIR"

            echo "Debug: Starting entropy collection..." >&2
            # Inner loop for entropy validation
            while true; do
                ENTROPY=$(zenity --entry \
                    --title="Wallet Generator" \
                    --text="Enter additional entropy (minimum 100 random numbers, you can use a dice or a coin):" \
                    --hide-text) || { 
                        echo "Debug: Zenity failed or cancelled" >&2
                        rm -rf "$TMPDIR"
                        exit 1
                    }
                echo "Debug: Got entropy, checking length..." >&2
                # Check entropy length
                if [ ${#ENTROPY} -lt 100 ]; then
                    zenity --error \
                        --title="Error" \
                        --text="Entropy must be at least 100 characters long.\nCurrent length: ${#ENTROPY}" \
                        --width=300
                    continue
                fi
                echo "Debug: Checking entropy quality..." >&2
                # Check entropy quality
                if ! echo "$ENTROPY" | grep -q '[0-9]'; then
                    zenity --error \
                        --title="Error" \
                        --text="Entropy must contain a mix of numbers" \
                        --width=300
                    continue
                fi
                echo "$ENTROPY" > "$TMPDIR/ENTROPY"
                break
            done

            echo "Debug: Starting wallet generation..." >&2
            # Generate wallet with validated entropy
            XMR_WALLET="/path/to/monero-wallet-cli" # or $(find /*/*/* -type f -executable -name "monero-wallet-cli" 2>/dev/null)
            clear
            $XMR_WALLET --generate-new-wallet "paranoid-monero-wallet" --password password --mnemonic-language English --extra-entropy "$TMPDIR/ENTROPY"
            echo "Debug: Starting cleanup..." >&2
            # Secure cleanup
            {
                ENTROPY=$(head -c 32 /dev/urandom | tr -dc 'A-Za-z0-9')
                ENTROPY=""
                unset ENTROPY
                # First change directory to avoid "directory busy" errors
                cd / || exit 1
                # Delete all files in the temporary directory
                rm -rf "$TMPDIR"
            } || exit 1

            echo "Debug: Cleanup complete, restoring history..." >&2
            set -o history 2>/dev/null || true
            break
        } || break
    done
} || {
    # Final cleanup in case of any errors
    echo "Debug: Error occurred, running final cleanup..." >&2
    stty sane
    set -o history 2>/dev/null || true
    exit 1
}
