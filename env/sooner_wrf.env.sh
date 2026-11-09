#!/usr/bin/env bash
# =============================================================================
# sooner_wrf.env.sh — single source of truth for the WRF environment on
# OU OSCER "Sooner" (Enterprise Linux 9).
#
#   source env/sooner_wrf.env.sh
#
# Sourced by every build/run script in this repo, both on the login node
# (inside the `el9` container) and inside SLURM jobs (--container=el9hw).
#
# Module versions are NOT hard-coded: scripts/build/00_setup_modules.sh picks
# and tests them and writes env/sooner_modules.sh (sourced below).
# =============================================================================

# ---- Versions to build -------------------------------------------------------
export WRF_VERSION="${WRF_VERSION:-4.7.1}"
export WPS_VERSION="${WPS_VERSION:-4.7.0}"   # check github.com/wrf-model/WPS/releases

# ---- Modules ---------------------------------------------------------------
# Chosen and tested automatically by scripts/build/00_setup_modules.sh, which
# writes env/sooner_modules.sh (the WRF build job runs it if the file is missing).
_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$_ENV_DIR/sooner_modules.sh" ] && source "$_ENV_DIR/sooner_modules.sh"

wrf_load_modules() {
    if [ -z "${MOD_NETCDF_F:-}" ]; then
        echo "ERROR: no module set yet — run scripts/build/00_setup_modules.sh" >&2
        return 1
    fi
    module purge
    # netCDF-Fortran pulls in GCC, OpenMPI, netCDF-C, HDF5 as dependencies
    module load "$MOD_NETCDF_F" "$MOD_JASPER" "$MOD_PNG" || {
        echo "ERROR: a module failed to load. Delete env/sooner_modules.sh and re-run" \
             "scripts/build/00_setup_modules.sh" >&2
        return 1
    }
    module list 2>&1
}

# ---- Directory layout ------------------------------------------------------
# Code + executables: $HOME (20 GB quota, backed up nightly).
# Large data + run directories: /scratch (NOT backed up, 2-week auto-delete).
export WRF_HOME="${WRF_HOME:-$HOME/wrf}"                 # source trees + builds
export WRF_DIR="$WRF_HOME/WRF-${WRF_VERSION}"
export WPS_DIR="$WRF_HOME/WPS-${WPS_VERSION}"
export NETCDF_COMBINED="$WRF_HOME/netcdf-combined"      # merged C+Fortran prefix

export WRF_SCRATCH="${WRF_SCRATCH:-/scratch/$USER/wrf}"
export GEOG_DIR="${GEOG_DIR:-$WRF_SCRATCH/WPS_GEOG}"     # ~29 GB high-res static data
export MET_DIR="${MET_DIR:-$WRF_SCRATCH/met}"            # downloaded GRIB files
export RUNS_DIR="${RUNS_DIR:-$WRF_SCRATCH/runs}"         # one subdir per case

# ---- Build-time variables WRF/WPS look for --------------------------------
export NETCDF="$NETCDF_COMBINED"
export HDF5="${EBROOTHDF5:-}"
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export WRF_EM_CORE=1
export WRF_NMM_CORE=0

# JasPer / PNG for WPS GRIB2 support (EasyBuild sets EBROOT<NAME> variables)
set_grib2_paths() {
    export JASPERINC="${EBROOTJASPER}/include"
    if [ -d "${EBROOTJASPER}/lib64" ]; then
        export JASPERLIB="${EBROOTJASPER}/lib64"
    else
        export JASPERLIB="${EBROOTJASPER}/lib"
    fi
    export LD_LIBRARY_PATH="$JASPERLIB:${EBROOTLIBPNG}/lib:${LD_LIBRARY_PATH:-}"
}

# Repo root (so jobs can find namelists regardless of submit dir)
export WRF_REPO="${WRF_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
