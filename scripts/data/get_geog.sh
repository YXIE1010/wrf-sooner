#!/usr/bin/env bash
# =============================================================================
# get_geog.sh — download the WPS static geographic data (mandatory fields).
# Run on the LOGIN node. ~2.6 GB download, ~29 GB unpacked.
#
#     bash scripts/data/get_geog.sh            # high-res (recommended for 3 km)
#     GEOG_RES=low bash scripts/data/get_geog.sh   # low-res, ~0.3 GB / ~2.5 GB
#
# NOTE: $GEOG_DIR defaults to /scratch, which OSCER purges after 2 weeks of
# inactivity. Either re-run this script when needed, ask OSCER whether a
# shared WPS_GEOG copy already exists on Sooner, or point GEOG_DIR at
# persistent project storage (e.g. /ourdisk) before running.
# =============================================================================
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO/env/sooner_wrf.env.sh"

RES="${GEOG_RES:-high}"
BASE="https://www2.mmm.ucar.edu/wrf/src/wps_files"
TARBALL="geog_${RES}_res_mandatory.tar.gz"

mkdir -p "$(dirname "$GEOG_DIR")"
cd "$(dirname "$GEOG_DIR")"

if [ -d "$GEOG_DIR/modis_landuse_20class_30s_with_lakes" ] || \
   [ -d "$GEOG_DIR/topo_gmted2010_30s" ]; then
    echo "Geog data already present in $GEOG_DIR"; exit 0
fi

wget -c "$BASE/$TARBALL"
tar -xzf "$TARBALL"
# high-res tarball unpacks to WPS_GEOG/, low-res to WPS_GEOG_LOW_RES/
for d in WPS_GEOG WPS_GEOG_LOW_RES; do
    if [ -d "$d" ] && [ "$(pwd)/$d" != "$GEOG_DIR" ]; then
        mv "$d" "$GEOG_DIR"
    fi
done
rm -f "$TARBALL"
du -sh "$GEOG_DIR"
echo "Set geog_data_path = '$GEOG_DIR' (done automatically by run_wps.slurm)."
