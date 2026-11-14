#!/bin/bash
# =============================================================================
# run_real.slurm — build wrfinput_d0*/wrfbdy_d01 from the met_em files.
#     sbatch --export=ALL,CASE=cases/2013-05-20_moore scripts/run/run_real.slurm
# num_metgrid_levels / num_metgrid_soil_levels are read from the met_em files,
# so the same namelist works for FNL, GFS, ERA5, ... without hand-editing.
# =============================================================================
#SBATCH --job-name=real
#SBATCH --partition=ai2es
#SBATCH --container=el9hw
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=16G
#SBATCH --time=00:30:00
#SBATCH --output=logs/real_%j.out
#SBATCH --error=logs/real_%j.out

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source scripts/run/_common.sh "${CASE:?pass CASE=cases/<name> via --export}"
wrf_load_modules >/dev/null

mkdir -p "$WRF_RUN" && cd "$WRF_RUN"
# Link the WRF run/ directory contents (lookup tables, executables)
for f in "$WRF_DIR"/run/*; do
    b=$(basename "$f")
    [ "$b" = namelist.input ] && continue
    ln -sfn "$(readlink -f "$f")" "$b"
done
rm -f met_em.d0*.nc wrfinput_d0* wrfbdy_d01 rsl.*
ln -sf "$WPS_RUN"/met_em.d0*.nc .

first=$(ls met_em.d01.* | head -n 1)
NLEV=$(ncdump -h "$first" | awk '/num_metgrid_levels =/{print $3}')
NSOIL=$(ncdump -h "$first" | awk '/NUM_METGRID_SOIL_LEVELS =/{print $3}' | tr -d ';')
echo "num_metgrid_levels=$NLEV  num_metgrid_soil_levels=$NSOIL"
fill_template "$CASE_DIR/namelist.input" namelist.input \
    -e "s|@NUM_METGRID_LEVELS@|$NLEV|" -e "s|@NUM_METGRID_SOIL_LEVELS@|$NSOIL|"

mpirun -np "$SLURM_NTASKS" ./real.exe
tail -n 3 rsl.error.0000
grep -q "SUCCESS COMPLETE REAL_EM" rsl.error.0000 || { echo "real.exe FAILED"; exit 1; }
mkdir -p logs_real && mv rsl.* logs_real/
ls -lh wrfinput_d0* wrfbdy_d01
