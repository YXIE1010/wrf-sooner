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
# !! Module names below follow OSCER's EasyBuild naming
# !! (<name>/<version>-<toolchain>). Versions change when OSCER updates the
# !! software stack: run scripts/build/00_check_modules.sh first and edit the
# !! MOD_* lines to match what `module avail` shows on Sooner today.
# =============================================================================

# ---- Versions to build -------------------------------------------------------
export WRF_VERSION="${WRF_VERSION:-4.7.1}"
export WPS_VERSION="${WPS_VERSION:-4.7.0}"   # check github.com/wrf-model/WPS/releases

# ---- Modules (one consistent GCC + OpenMPI toolchain) ------------------------
# All of these must come from the SAME toolchain (e.g. foss-2023a = GCC 12.3 +
# OpenMPI 4.1.5). Mixing toolchains is the #1 cause of link errors.
MOD_COMPILER="${MOD_COMPILER:-GCC/12.3.0}"
MOD_MPI="${MOD_MPI:-OpenMPI/4.1.5-GCC-12.3.0}"
MOD_NETCDF_C="${MOD_NETCDF_C:-netCDF/4.9.2-gompi-2023a}"
MOD_NETCDF_F="${MOD_NETCDF_F:-netCDF-Fortran/4.6.1-gompi-2023a}"
MOD_JASPER="${MOD_JASPER:-JasPer/4.0.0-GCCcore-12.3.0}"
MOD_PNG="${MOD_PNG:-libpng/1.6.39-GCCcore-12.3.0}"
MOD_ZLIB="${MOD_ZLIB:-zlib/1.2.13-GCCcore-12.3.0}"
# Optional, only needed on the login node for the plotting step:
MOD_PYTHON="${MOD_PYTHON:-}"

wrf_load_modules() {
    module purge
    module load "$MOD_COMPILER" "$MOD_MPI" "$MOD_NETCDF_C" "$MOD_NETCDF_F" \
                "$MOD_ZLIB" "$MOD_PNG" "$MOD_JASPER" || {
        echo "ERROR: a module failed to load. Run scripts/build/00_check_modules.sh" >&2
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
