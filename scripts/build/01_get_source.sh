#!/usr/bin/env bash
# =============================================================================
# 01_get_source.sh — clone WRF and WPS release tags into the scratch build
# area ($WRF_BUILD_ROOT). Nothing is written to $HOME.
# Run on the LOGIN node (compute nodes may not have outbound internet).
#
#     bash scripts/build/01_get_source.sh
# =============================================================================
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO/env/sooner_wrf.env.sh"
mkdir -p "$WRF_BUILD_ROOT"

if [ ! -d "$WRF_SRC" ]; then
    # --recurse-submodules is REQUIRED: Noah-MP, MMM physics and MYNN-EDMF are
    # git submodules since v4.4; a plain clone compiles but is missing physics.
    git clone --branch "v${WRF_VERSION}" --depth 1 \
        --recurse-submodules --shallow-submodules \
        https://github.com/wrf-model/WRF.git "$WRF_SRC"
else
    echo "WRF source already at $WRF_SRC"
fi

if [ ! -d "$WPS_SRC" ]; then
    git clone --branch "v${WPS_VERSION}" --depth 1 \
        https://github.com/wrf-model/WPS.git "$WPS_SRC"
else
    echo "WPS source already at $WPS_SRC"
fi

echo
echo "WRF: $(cd "$WRF_SRC" && git describe --tags)   -> $WRF_SRC"
echo "WPS: $(cd "$WPS_SRC" && git describe --tags)   -> $WPS_SRC"
du -sh "$WRF_SRC" "$WPS_SRC"
