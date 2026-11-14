#!/bin/bash
# =============================================================================
# 03_build_wps.slurm — configure + compile WPS (serial, GRIB2) against the WRF
# build from 02_build_wrf.slurm. Takes ~5 min.
#
#     sbatch --dependency=afterok:<wrf_build_jobid> scripts/build/03_build_wps.slurm
#
# Serial WPS is plenty for regional domains; geogrid/metgrid run in minutes.
# =============================================================================
#SBATCH --job-name=build_wps
#SBATCH --partition=ai2es
#SBATCH --container=el9hw
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=8G
#SBATCH --time=00:45:00
#SBATCH --output=logs/build_wps_%j.out
#SBATCH --error=logs/build_wps_%j.out

set -euo pipefail
source "${SLURM_SUBMIT_DIR}/env/sooner_wrf.env.sh"
wrf_load_modules
set_grib2_paths

# WPS compiles against the WRF *build tree* (its I/O libraries), not the slim install
[ -s "$WRF_SRC/main/wrf.exe" ] || { echo "Build WRF first ($WRF_SRC)"; exit 1; }

cd "$WPS_SRC"
./clean -a >/dev/null 2>&1 || true

# --- added to fix the build issue --- #
# JasPer >= 3 (Sooner: 4.2.8): jpc_decode/jpc_encode are no longer exported, and
# JasPer must be initialised before ANY jas_* call. Restore the original files,
# then: init JasPer once before the first jas_stream_memopen, and use the public
# jas_image_decode/encode API. Safe to run repeatedly.
G2DIR=ungrib/src/ngl/g2
git checkout -- "$G2DIR/dec_jpeg2000.c" "$G2DIR/enc_jpeg2000.c"
perl -0pi -e '
  s{(#include\s*[<"]jasper/jasper\.h[>"][^\n]*\n)}{$1/* WPS on Sooner: JasPer >= 3 needs a one-time init */\nstatic void wps_jas_init_once(void) { static int done = 0; if (!done) { jas_init(); done = 1; } }\n};
  s{^([ \t]*)(\w+\s*=\s*jas_stream_memopen\s*\()}{$1wps_jas_init_once();\n$1$2}m;
  s{\bjpc_decode\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)}{jas_image_decode($1, jas_image_strtofmt("jpc"), $2)}g;
' "$G2DIR/dec_jpeg2000.c"
perl -0pi -e 's{\bjpc_encode\s*\(\s*(&?\w+)\s*,\s*(\w+)\s*,\s*(\w+)\s*\)}{jas_image_encode($1, $2, jas_image_strtofmt("jpc"), $3)}g' "$G2DIR/enc_jpeg2000.c"
if grep -n -E '\bjpc_(de|en)code\s*\(' "$G2DIR"/*.c || [ "$(grep -c 'wps_jas_init_once' "$G2DIR/dec_jpeg2000.c")" != 2 ]; then
    echo "ERROR: JasPer patch did not apply cleanly to $G2DIR" >&2; exit 1
fi
echo "JasPer API patch applied to $G2DIR"

# Option 1 = "Linux x86_64, gfortran (serial)". Override with WPS_CONFIG_OPT.
printf '%s\n' "${WPS_CONFIG_OPT:-1}" | WRF_DIR="$WRF_SRC" ./configure

sed -i "s|^WRF_DIR.*|WRF_DIR = ${WRF_SRC}|" configure.wps
grep -E '^(WRF_DIR|COMPRESSION_LIBS|COMPRESSION_INC|FC )' configure.wps

./compile > compile_wps.log 2>&1 || true
tail -n 15 compile_wps.log
for exe in geogrid ungrib metgrid; do
    # the top-level *.exe are symlinks into the subdirectories
    if [ -s "${exe}.exe" ]; then echo "OK   ${exe}.exe"
    else echo "MISSING ${exe}.exe"; MISSING=1; fi
done
if [ "${MISSING:-0}" = 1 ]; then
    echo "WPS build FAILED — most often ungrib (JasPer/PNG). See docs/05_troubleshooting.md"
    exit 1
fi
echo "WPS build complete."

# Slim install: executables + the tables run_wps.slurm links to
rm -rf "$WPS_DIR"; mkdir -p "$WPS_DIR"/{geogrid,metgrid,ungrib}
cp -L geogrid.exe ungrib.exe metgrid.exe "$WPS_DIR/"
cp -L geogrid/GEOGRID.TBL* "$WPS_DIR/geogrid/"
cp -L metgrid/METGRID.TBL* "$WPS_DIR/metgrid/"
cp -rL ungrib/Variable_Tables "$WPS_DIR/ungrib/"
cp compile_wps.log configure.wps "$WPS_DIR/"
echo "Installed to $WPS_DIR: $(du -sh "$WPS_DIR" | cut -f1)"
echo "Home usage of the WRF install: $(du -sh "$WRF_HOME" | cut -f1)"
echo "The build trees in $WRF_BUILD_ROOT are no longer needed (safe if scratch purges them)."
