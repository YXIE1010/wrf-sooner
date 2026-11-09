#!/usr/bin/env bash
# =============================================================================
# 01_get_source.sh — clone WRF and WPS release tags into $WRF_HOME.
# Run on the LOGIN node (compute nodes may not have outbound internet).
#
#     bash scripts/build/01_get_source.sh
# =============================================================================
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO/env/sooner_wrf.env.sh"
mkdir -p "$WRF_HOME"

if [ ! -d "$WRF_DIR" ]; then
    # --recurse-submodules is REQUIRED: Noah-MP, MMM physics and MYNN-EDMF are
    # git submodules since v4.4; a plain clone compiles but is missing physics.
    git clone --branch "v${WRF_VERSION}" --depth 1 --recurse-submodules \
        https://github.com/wrf-model/WRF.git "$WRF_DIR"
else
    echo "WRF source already at $WRF_DIR"
fi

if [ ! -d "$WPS_DIR" ]; then
    git clone --branch "v${WPS_VERSION}" --depth 1 \
        https://github.com/wrf-model/WPS.git "$WPS_DIR"
else
    echo "WPS source already at $WPS_DIR"
fi

echo
echo "WRF: $(cd "$WRF_DIR" && git describe --tags)   -> $WRF_DIR"
echo "WPS: $(cd "$WPS_DIR" && git describe --tags)   -> $WPS_DIR"
du -sh "$WRF_DIR" "$WPS_DIR"
