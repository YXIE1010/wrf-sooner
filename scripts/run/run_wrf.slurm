#!/bin/bash
# =============================================================================
# run_wrf.slurm — run wrf.exe with MPI. Node count / walltime are set by
# submit_case.sh from case.conf (WRF_NODES, WRF_TASKS_PER_NODE, WRF_WALLTIME).
# =============================================================================
#SBATCH --job-name=wrf
#SBATCH --partition=ai2es
#SBATCH --container=el9hw
#SBATCH --mem=40G
#SBATCH --output=logs/wrf_%j.out
#SBATCH --error=logs/wrf_%j.out

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source scripts/run/_common.sh "${CASE:?pass CASE=cases/<name> via --export}"
wrf_load_modules >/dev/null

cd "$WRF_RUN"
[ -s wrfbdy_d01 ] || { echo "No wrfbdy_d01 — run run_real.slurm first"; exit 1; }
rm -f rsl.* wrfout_d0*

echo "Start $(date)  tasks=$SLURM_NTASKS nodes=$SLURM_JOB_NUM_NODES"
SECONDS=0
mpirun -np "$SLURM_NTASKS" ./wrf.exe
#srun --mpi=pmix ./wrf.exe
echo "End   $(date)  elapsed=$((SECONDS/60)) min"

tail -n 3 rsl.error.0000
grep -q "SUCCESS COMPLETE WRF" rsl.error.0000 || { echo "wrf.exe FAILED — see docs/05_troubleshooting.md"; exit 1; }
mkdir -p logs_wrf && mv rsl.* logs_wrf/
# Record a timing summary for the README
# line format: "Timing for main: time <date> on domain   1:    0.12345 elapsed seconds"
awk '/Timing for main/{d=$(NF-3); n[d]++; s[d]+=$(NF-2)} END{for(d in n) printf "domain %s %d steps, mean %.3f s/step, total %.1f min\n", d, n[d], s[d]/n[d], s[d]/60}' \
    logs_wrf/rsl.error.0000 | tee timing_summary.txt || true
ls -lh wrfout_d0* | head
