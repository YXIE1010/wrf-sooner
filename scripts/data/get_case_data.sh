#!/usr/bin/env bash
# =============================================================================
# get_case_data.sh — download the FNL forcing a case needs, using its case.conf
# (START, END, MET_SOURCE). Run on the LOGIN node.
#
#     bash scripts/data/get_case_data.sh cases/2023-01-09_california_ar
# =============================================================================
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CASE="${1:?usage: get_case_data.sh cases/<name>}"
source "$REPO/env/sooner_wrf.env.sh"
source "$CASE/case.conf"
bash "$REPO/scripts/data/get_fnl.sh" "$START" "$END" "$MET_DIR/$MET_SOURCE"
