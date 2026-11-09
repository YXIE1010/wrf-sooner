#!/usr/bin/env bash
# =============================================================================
# 00_check_modules.sh — find the compiler/MPI/netCDF/JasPer modules available
# on Sooner and test that the ones in env/sooner_wrf.env.sh actually load.
#
# Run on the LOGIN node, inside the EL9 container:
#     el9
#     bash scripts/build/00_check_modules.sh
# =============================================================================
set -u
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO/env/sooner_wrf.env.sh"

echo "== Is there already a WRF/WPS module? (you can skip building if so) =="
module -t avail 2>&1 | grep -iE '^(WRF|WPS)/' || echo "   none found"
echo
for pat in '^GCC/' '^OpenMPI/' '^netCDF/' '^netCDF-Fortran/' '^JasPer/' '^libpng/' '^zlib/' '^foss/'; do
    echo "== ${pat//[\^\/]/} =="
    module -t avail 2>&1 | grep -E "$pat" | sort -V | tail -n 6
done

echo
echo "== Trying to load the modules configured in env/sooner_wrf.env.sh =="
if wrf_load_modules; then
    echo
    command -v gfortran mpif90 mpicc nc-config nf-config
    echo "gfortran : $(gfortran -dumpfullversion)"
    echo "netCDF-C : $(nc-config --version)   prefix $(nc-config --prefix)"
    echo "netCDF-F : $(nf-config --version)   prefix $(nf-config --prefix)"
    echo "JasPer   : ${EBROOTJASPER:-<EBROOTJASPER unset>}"
    echo
    echo "OK — the module set loads. Continue with 01_build_wrf.slurm."
else
    echo
    echo "Edit the MOD_* lines in env/sooner_wrf.env.sh using the lists above."
    echo "Pick versions that share ONE toolchain (e.g. all '...-gompi-2023a' /"
    echo "'...-GCCcore-12.3.0'). If netCDF-Fortran is missing, email"
    echo "support@oscer.ou.edu or see docs/02_build.md (build-your-own section)."
    exit 1
fi
