#!/usr/bin/env bash
# =============================================================================
# submit_case.sh — submit WPS -> real -> WRF as a chained set of SLURM jobs.
# Run from the repo root on the login node, OUTSIDE the el9 container
# (type `exit` if you are in it; jobs enter the container via --container):
#
#     bash scripts/run/submit_case.sh cases/2013-05-20_moore
#     bash scripts/run/submit_case.sh cases/2013-05-20_moore --from real   # skip WPS
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/../.."
CASE="${1:?usage: submit_case.sh cases/<name> [--from wps|real|wrf]}"
FROM="${3:-wps}"; [ "${2:-}" = "--from" ] || FROM=wps
source "$CASE/case.conf"
mkdir -p logs

dep=()
submit() {  # submit <script> [extra sbatch args]
    local s="$1"; shift
    local id
    id=$(sbatch --parsable --export=ALL,CASE="$CASE" "${dep[@]}" "$@" "$s")
    echo "submitted $(basename "$s") -> job $id" >&2
    dep=(--dependency=afterok:"$id")
}

case "$FROM" in
  wps)  submit scripts/run/run_wps.slurm ;&
  real) submit scripts/run/run_real.slurm ;&
  wrf)  submit scripts/run/run_wrf.slurm \
            --nodes="$WRF_NODES" --ntasks-per-node="$WRF_TASKS_PER_NODE" \
            --time="$WRF_WALLTIME" --job-name="wrf_${CASE_NAME}" ;;
  *) echo "unknown --from $FROM"; exit 1 ;;
esac
echo "Monitor with:  squeue -u \$USER     logs in ./logs/"
