#!/bin/bash
# =============================================================================
# 02_build_wrf.slurm — configure + compile WRF (em_real, GNU, dmpar) on a
# compute node. Takes ~30-60 min.
#
#     sbatch scripts/build/02_build_wrf.slurm
#
# Success = main/wrf.exe, real.exe, ndown.exe, tc.exe all exist.
# =============================================================================
#SBATCH --job-name=build_wrf
#SBATCH --partition=sooner_test
#SBATCH --container=el9hw
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=logs/build_wrf_%j.out
#SBATCH --error=logs/build_wrf_%j.out

set -euo pipefail
source "${SLURM_SUBMIT_DIR}/env/sooner_wrf.env.sh"
wrf_load_modules

# --- 1. WRF wants netCDF-C and netCDF-Fortran under ONE prefix. EasyBuild
#        installs them separately, so build a symlink "merged" prefix.
rm -rf "$NETCDF_COMBINED"; mkdir -p "$NETCDF_COMBINED"/{bin,include,lib}
for p in "$(nc-config --prefix)" "$(nf-config --prefix)"; do
    for d in bin include lib lib64; do
        [ -d "$p/$d" ] || continue
        tgt=$([ "$d" = lib64 ] && echo lib || echo "$d")
        ln -sf "$p/$d"/* "$NETCDF_COMBINED/$tgt/" 2>/dev/null || true
    done
done
echo "Merged netCDF prefix: $NETCDF_COMBINED"
ls "$NETCDF_COMBINED/lib" | grep -E 'libnetcdff?\.' || { echo "netCDF libs missing"; exit 1; }

# --- 2. Configure. Option 34 = "GNU (gfortran/gcc)  dmpar", nesting 1 = basic.
#        Menu numbers can shift between versions; override with WRF_CONFIG_OPT.
cd "$WRF_DIR"
./clean -a >/dev/null 2>&1 || true
printf '%s\n%s\n' "${WRF_CONFIG_OPT:-34}" "1" | ./configure
grep -E '^(SFC|DM_FC|FCOPTIM)' configure.wrf

# --- 3. Compile (parallel make). Log kept in the WRF tree for debugging.
./compile -j "${SLURM_NTASKS}" em_real > compile_em_real.log 2>&1 || true

echo "---- tail of compile log ----"
tail -n 25 compile_em_real.log
for exe in wrf real ndown tc; do
    if [ -s "main/${exe}.exe" ]; then echo "OK   main/${exe}.exe"
    else echo "MISSING main/${exe}.exe"; MISSING=1; fi
done
if [ "${MISSING:-0}" = 1 ]; then
    echo "Build FAILED. Search for the FIRST error:"
    echo "   grep -n -m5 -i ' error' $WRF_DIR/compile_em_real.log"
    exit 1
fi
echo "WRF build complete."
