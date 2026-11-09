# 0. Start here — the order to do things in

You don't need to understand all of WRF before starting. Each step below has a single
"done when" check. Do them in order, one per sitting if you like.

| # | Step | Where | Done when |
|---|---|---|---|
| 1 | Clone this repo on Sooner, `mkdir logs` | login node | `ls` shows `scripts/ cases/ docs/` |
| 2 | `bash scripts/build/01_get_source.sh` | login | WRF + WPS folders in `~/wrf/` |
| 3 | Submit the WRF build, then the WPS build (two `sbatch` lines in docs/02) | `sbatch` | `logs/build_wrf_*.out` shows "Saved working module set" and `OK main/wrf.exe`; WPS log shows `OK ungrib.exe` |
| 4 | `bash scripts/data/get_geog.sh` (can run while step 3 compiles) | login | `/scratch/$USER/wrf/WPS_GEOG/` ≈ 29 GB |
| 5 | `bash scripts/data/get_case_data.sh cases/2013-05-20_moore` | login | 3 `fnl_*.grib2` files |
| 6 | `bash scripts/run/submit_case.sh cases/2013-05-20_moore` | `sbatch` | `SUCCESS COMPLETE WRF` in `logs/wrf_*.out` |
| 7 | Make plots, fill the "Tested configuration" table, commit, push | login | figure shows on the GitHub README |
| 8 | Repeat 5–7 for `cases/2023-01-09_california_ar` | | T2/precip figure in `results/` |

**Why Moore first?** It's the cheapest run (12 h, 2 nodes), so you find build or data
problems quickly. The California case is 48 h on 4 nodes.

**When something fails:** copy the last ~30 lines of the log in `logs/` (and, for WRF,
`rsl.error.0000`), then add the fix to `docs/05_troubleshooting.md` once it's solved.

**Not needed:** choosing compiler/MPI/netCDF versions by hand (the build job finds and
tests them), or typing `el9` (only needed if you want to run module commands yourself).
Also not needed: a conda environment for WRF (it's compiled Fortran built against Sooner's
modules). Conda is only for the plotting step (`scripts/plot/environment.yml`).
