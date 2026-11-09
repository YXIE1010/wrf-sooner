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
#SBATCH --partition=sooner_test
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

[ -s "$WRF_DIR/main/wrf.exe" ] || { echo "Build WRF first ($WRF_DIR)"; exit 1; }

cd "$WPS_DIR"
./clean -a >/dev/null 2>&1 || true
# Option 1 = "Linux x86_64, gfortran (serial)". Override with WPS_CONFIG_OPT.
printf '%s\n' "${WPS_CONFIG_OPT:-1}" | ./configure

# WPS needs to know where the compiled WRF lives (for its I/O libraries)
sed -i "s|^WRF_DIR.*|WRF_DIR = ${WRF_DIR}|" configure.wps
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
