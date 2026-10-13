#!/usr/bin/env bash
# Build the existing G18 configuration on the host Ubuntu system.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

python3 scripts/g18-wifi-guard.py --baseline HEAD
if ! python3 - <<'PY'
import pathlib
import sys
import sysconfig
header = pathlib.Path(sysconfig.get_path("include")) / "Python.h"
if not header.is_file():
    print(f"Missing Python development header: {header}", file=sys.stderr)
    print("Install it on Ubuntu: sudo apt install python3-dev", file=sys.stderr)
    sys.exit(1)
PY
then
    exit 1
fi
if [[ ! -s .config ]]; then
    echo 'Missing .config. Prepare feeds, load config/g18-pro.config and run make defconfig first.' >&2
    exit 1
fi
if ! grep -qx 'CONFIG_TARGET_rockchip_armv8_DEVICE_bdy_g18-pro=y' .config; then
    echo 'The current .config does not select BDY G18-PRO; check the device before building.' >&2
    exit 1
fi
if ! grep -qx 'CONFIG_PACKAGE_kmod-mt7615e=y' .config ||
   ! grep -qx 'CONFIG_PACKAGE_kmod-mt7615-firmware=y' .config; then
    echo 'The current .config must include kmod-mt7615e and kmod-mt7615-firmware.' >&2
    exit 1
fi
if grep -Eq '^CONFIG_PACKAGE_kmod-mt_wifi=(y|m)$' .config; then
    echo 'Conflicting mt_wifi driver selected; check the configuration before building.' >&2
    exit 1
fi

mkdir -p logs
log="logs/g18-build-$(date +%Y%m%d-%H%M%S)-$$.log"
echo "Build log: $PWD/$log"
export FORCE_UNSAFE_CONFIGURE=1
make_args=()
bootstrap_root=$(sed -n 's/^CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT="\(.*\)"$/\1/p' .config)
if [[ -n "$bootstrap_root" && ! -x "$bootstrap_root/bin/go" ]]; then
    if [[ $(uname -s) == Linux && $(uname -m) == x86_64 ]]; then
        # The feed supports building its own bootstrap on linux_amd64.
        # Override only the host build setting, leaving the preset untouched.
        make_args+=(CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT=)
    else
        echo "Missing Go bootstrap: $bootstrap_root/bin/go. Configure a working bootstrap for this host." >&2
        exit 1
    fi
fi
{
    if (( ${#make_args[@]} )); then
        echo "Go bootstrap $bootstrap_root is unavailable; using the feed's built-in bootstrap on Linux x86_64."
    fi
    echo 'Downloading build sources...'
    make download -j1 V=s "${make_args[@]}"
    echo 'Building G18-Pro...'
    make -j1 V=s "${make_args[@]}"
    echo "Build completed. Output directory: $PWD/bin/targets/rockchip/armv8/"
} 2>&1 | tee "$log"
