#!/usr/bin/env bash
# =============================================================================
# get_fnl.sh — download NCEP FNL 1-degree GRIB2 analyses (NCAR GDEX d083002,
# formerly RDA ds083.2) every 6 h between two dates. Run on the LOGIN node.
#
#     bash scripts/data/get_fnl.sh 2013-05-20_12 2013-05-21_00 [outdir]
#
# Files: fnl_YYYYMMDD_HH_00.grib2 (~17 MB each), 6-hourly.
# If the download URL pattern changes, check the "Web Download (HTTPS)" tab at
# https://gdex.ucar.edu/datasets/d083002/dataaccess/ and override FNL_BASE_URL.
# =============================================================================
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO/env/sooner_wrf.env.sh"

START="${1:?start YYYY-MM-DD_HH}"; END="${2:?end YYYY-MM-DD_HH}"
OUT="${3:-$MET_DIR/fnl}"
BASE="${FNL_BASE_URL:-https://data.rda.ucar.edu/d083002/grib2}"
mkdir -p "$OUT"

t=$(date -u -d "${START/_/ }:00" +%s)
tend=$(date -u -d "${END/_/ }:00" +%s)
while [ "$t" -le "$tend" ]; do
    Y=$(date -u -d "@$t" +%Y); M=$(date -u -d "@$t" +%m)
    D=$(date -u -d "@$t" +%d); H=$(date -u -d "@$t" +%H)
    f="fnl_${Y}${M}${D}_${H}_00.grib2"
    if [ -s "$OUT/$f" ]; then echo "have $f"
    else
        echo "get  $f"
        wget -q -O "$OUT/$f.part" "$BASE/$Y/$Y.$M/$f" && mv "$OUT/$f.part" "$OUT/$f" \
          || { rm -f "$OUT/$f.part"; echo "FAILED: $BASE/$Y/$Y.$M/$f"; exit 1; }
    fi
    t=$((t + 6*3600))
done
ls -lh "$OUT"
