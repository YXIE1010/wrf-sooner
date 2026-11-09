# 0. Start here — the order to do things in

You don't need to understand all of WRF before starting. Each step below has a single
"done when" check. Do them in order, one per sitting if you like.

| # | Step | Where | Done when |
|---|---|---|---|
| 1 | Clone this repo on Sooner, `mkdir logs` | login node | `ls` shows `scripts/ cases/ docs/` |
| 2 | `el9` → `bash scripts/build/00_check_modules.sh`; edit `MOD_*` in `env/sooner_wrf.env.sh` until it passes | login, in `el9` | prints **OK — the module set loads** |
| 3 | `bash scripts/build/01_get_source.sh` | login | WRF + WPS folders in `~/wrf/` |
| 4 | `exit` el9 → submit the WRF build, then the WPS build (see docs/02) | `sbatch` | `main/wrf.exe`, `real.exe`; `geogrid/ungrib/metgrid.exe` exist |
| 5 | `bash scripts/data/get_geog.sh` (can run while step 4 compiles) | login | `/scratch/$USER/wrf/WPS_GEOG/` ≈ 29 GB |
| 6 | `bash scripts/data/get_case_data.sh cases/2013-05-20_moore` | login | 3 `fnl_*.grib2` files |
| 7 | `bash scripts/run/submit_case.sh cases/2013-05-20_moore` | `sbatch` | `SUCCESS COMPLETE WRF` in `logs/wrf_*.out` |
| 8 | Make plots, fill the "Tested configuration" table, commit, push | login | figure shows on the GitHub README |
| 9 | Repeat 6–8 for `cases/2023-01-09_california_ar` | | T2/precip figure in `results/` |

**Why Moore first?** It's the cheapest run (12 h, 2 nodes), so you find build or data
problems quickly. The California case is 48 h on 4 nodes.

**When something fails:** copy the last ~30 lines of the log in `logs/` (and, for WRF,
`rsl.error.0000`), then add the fix to `docs/05_troubleshooting.md` once it's solved.

**Not needed:** a conda environment for WRF (it's compiled Fortran built against Sooner's
modules). Conda is only for the plotting step (`scripts/plot/environment.yml`).
