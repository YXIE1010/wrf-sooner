#!/bin/bash
# =============================================================================
# run_wps.slurm — geogrid -> ungrib -> metgrid for one case.
#     sbatch --export=ALL,CASE=cases/2013-05-20_moore scripts/run/run_wps.slurm
# (normally called by scripts/run/submit_case.sh)
# =============================================================================
#SBATCH --job-name=wps
#SBATCH --partition=sooner_test
#SBATCH --container=el9hw
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=logs/wps_%j.out
#SBATCH --error=logs/wps_%j.out

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source scripts/run/_common.sh "${CASE:?pass CASE=cases/<name> via --export}"
wrf_load_modules >/dev/null
set_grib2_paths

mkdir -p "$WPS_RUN" && cd "$WPS_RUN"
rm -f geo_em.d0*.nc met_em.d0*.nc FILE:* GRIBFILE.* *.log
for x in geogrid ungrib metgrid; do
    ln -sfn "$(readlink -f "$WPS_DIR/$x.exe")" "$x.exe"
done
ln -sfn "$WPS_DIR/geogrid" geogrid          # GEOGRID.TBL lives here
ln -sfn "$WPS_DIR/metgrid" metgrid          # METGRID.TBL lives here
ln -sfn "$WPS_DIR/ungrib/Variable_Tables/$VTABLE" Vtable
fill_template "$CASE_DIR/namelist.wps" namelist.wps

echo "== geogrid =="; ./geogrid.exe > geogrid.out 2>&1; tail -n 2 geogrid.out
grep -q "Successful completion of geogrid" geogrid.out || { cat geogrid.out; exit 1; }

echo "== ungrib ==";  link_grib "$MET_DIR/$MET_SOURCE"
./ungrib.exe > ungrib.out 2>&1; tail -n 2 ungrib.out
grep -q "Successful completion of ungrib" ungrib.out || { tail -n 40 ungrib.out; exit 1; }

echo "== metgrid =="; ./metgrid.exe > metgrid.out 2>&1; tail -n 2 metgrid.out
grep -q "Successful completion of metgrid" metgrid.out || { tail -n 40 metgrid.out; exit 1; }

ls -1 met_em.d0*.nc | wc -l | xargs echo "met_em files:"
rm -f FILE:*        # intermediate files no longer needed
echo "WPS done -> $WPS_RUN"
