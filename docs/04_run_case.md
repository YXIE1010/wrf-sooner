# 4. Running the case: 20 May 2013 Moore, Oklahoma supercells

## Why this case
On the afternoon of 20 May 2013, supercells formed along a dryline in central Oklahoma; one
produced the EF5 Moore tornado (~1956–2035 UTC). It is a classic, well-documented
convection-permitting test for WRF, and it happened right next to OU.

## Configuration
| | d01 | d02 |
|---|---|---|
| Grid spacing | 15 km | 3 km |
| Size (e_we × e_sn) | 160 × 130 | 241 × 211 |
| Coverage | south-central US | Oklahoma + surroundings |
| Time step | 75 s | 15 s |
| Cumulus | Grell–Freitas (3) | none (explicit convection) |
| Output | hourly | every 15 min |

Shared: 51 levels, model top 50 hPa, Thompson microphysics (8), RRTMG LW/SW (4),
YSU PBL (1) + revised MM5 surface layer (1), Noah LSM (2), two-way nesting,
`do_radar_ref = 1` (writes `REFL_10CM`). Run: **2013-05-20 12 UTC → 2013-05-21 00 UTC (12 h)**.

Files: [`cases/2013-05-20_moore/`](../cases/2013-05-20_moore). Namelists are templates —
`@TOKENS@` (dates, geog path, metgrid levels) are filled by the run scripts from `case.conf`.

## Run it
```bash
cd ~/wrf-oscer-sooner           # outside el9
bash scripts/run/submit_case.sh cases/2013-05-20_moore
squeue -u $USER
```
This submits three chained jobs (each starts only if the previous succeeded):

| Job | What | Check |
|---|---|---|
| `run_wps.slurm` | geogrid → ungrib → metgrid | `Successful completion of metgrid` |
| `run_real.slurm` | `real.exe` on 8 MPI tasks | `SUCCESS COMPLETE REAL_EM` |
| `run_wrf.slurm` | `wrf.exe` on 2 × 20 MPI tasks | `SUCCESS COMPLETE WRF` |

Re-run only part of the chain: `--from real` or `--from wrf`.

Monitor a running model:
```bash
tail -f /scratch/$USER/wrf/runs/2013-05-20_moore/wrf/rsl.error.0000
```

## Plot
```bash
conda activate wrfplot   # one-time setup: see "Plotting env and the home quota" below
RUN=/scratch/$USER/wrf/runs/2013-05-20_moore
python scripts/plot/plot_domains.py $RUN/wps results/figures/domains.png
python scripts/plot/plot_reflectivity.py $RUN/wrf results/figures/refl_d02.png --domain d02 \
  --times 2013-05-20_19:00:00 2013-05-20_20:00:00 2013-05-20_21:00:00 2013-05-20_22:00:00
cp $RUN/wrf/timing_summary.txt results/
```
Commit the PNGs and `timing_summary.txt` (small), **not** the `wrfout` files (GBs).

## What to expect / how to interpret
* Discrete supercells initiating along the dryline in central OK during 19–21 UTC.
  Timing and location will not match observations exactly at 1° FNL forcing — that is
  normal and worth one sentence in the README.
* For a stronger comparison, plot observed NEXRAD composite reflectivity (KTLX) for the same
  hours next to the simulation.
* Sensitivity ideas to add as extra case folders: Thompson vs. Morrison (10) vs. NSSL (17)
  microphysics; 0.25° GDAS forcing (needs a post-2015 case); 1 km third nest.

## Plotting env and the home quota
A conda env with cartopy takes about 1–2 GB. If your conda lives in `$HOME`, that counts
against the 20 GB quota. Options, from least to most home space:
* create it outside home: `conda env create -f scripts/plot/environment.yml -p /ourdisk/hpc/<group>/envs/wrfplot`
  (then `conda activate /ourdisk/.../wrfplot`);
* reuse an env you already have: `pip install xarray netCDF4 matplotlib` (cartopy optional;
  without it the scripts plot on a plain lat/lon grid);
* `conda clean --all` first. Package caches are often several GB.
