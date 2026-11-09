# WRF on OU OSCER Sooner — from scratch to a case study

Reproducible scripts and documentation to **build, configure and run the Weather Research and
Forecasting model (WRF-ARW v4.7.1 + WPS v4.7.0)** on the University of Oklahoma's
[OSCER](https://www.ou.edu/oscer) *Sooner* cluster (Enterprise Linux 9, SLURM), with a
complete convection-permitting case example: the **20 May 2013 Moore, Oklahoma tornadic
supercells**.

<p align="center">
  <img src="results/figures/refl_d02.png" width="720"
       alt="Simulated composite reflectivity, 3 km nest, 19–22 UTC 20 May 2013">
  <br><em>Simulated composite reflectivity on the 3 km nest (★ = Moore, OK).</em>
</p>

## Quick start
```bash
# on sooner.oscer.ou.edu
git clone https://github.com/<you>/wrf-oscer-sooner.git && cd wrf-oscer-sooner && mkdir -p logs

el9                                            # enter the EL9 module environment
bash scripts/build/00_check_modules.sh         # pick/verify compiler, MPI, netCDF modules
bash scripts/build/01_get_source.sh            # clone WRF + WPS
bash scripts/data/get_geog.sh                  # static data (~29 GB, /scratch)
bash scripts/data/get_fnl.sh 2013-05-20_12 2013-05-21_00   # NCEP FNL forcing
exit                                           # leave el9 before submitting

jid=$(sbatch --parsable scripts/build/02_build_wrf.slurm)  # ~30-60 min
sbatch --dependency=afterok:$jid scripts/build/03_build_wps.slurm

bash scripts/run/submit_case.sh cases/2013-05-20_moore      # WPS -> real -> WRF chain
```

## Documentation
1. [Access & environment](docs/01_access_and_environment.md) — EL9 container, storage, partitions
2. [Building WRF & WPS](docs/02_build.md) — toolchain, netCDF merge, configure options
3. [Input data](docs/03_data.md) — geog data, FNL, other forcing options
4. [Running the case](docs/04_run_case.md) — domain, physics, job chain, plotting
5. [Troubleshooting](docs/05_troubleshooting.md)

## Repository layout
```
env/sooner_wrf.env.sh          modules + paths (single source of truth)
scripts/build/                 module check, source download, WRF & WPS build jobs
scripts/data/                  geog + FNL download
scripts/run/                   run_wps / run_real / run_wrf jobs, submit_case.sh chain
scripts/plot/                  domain map + reflectivity plots, conda env
cases/2013-05-20_moore/        case.conf, namelist.wps, namelist.input (templates)
results/                       figures + timing summary committed after the run
```

## Workflow
```
 geog data ─┐
            ├─ geogrid ─┐
 FNL GRIB2 ─┴─ ungrib ──┴─ metgrid ──► real.exe ──► wrf.exe ──► wrfout_d0* ──► plots
 └──────── run_wps.slurm ─────────┘   run_real      run_wrf
```

## Case summary
| | d01 | d02 |
|---|---|---|
| Δx | 15 km | 3 km |
| Grid | 160 × 130 × 51 | 241 × 211 × 51 |
| Convection | Grell–Freitas | explicit |
| Period | 2013-05-20 12 UTC – 05-21 00 UTC | same (two-way) |

Thompson MP · RRTMG · YSU · Noah · FNL 1° IC/BC.

## Tested configuration
*Fill in after your first successful run — this is what makes it reproducible.*

| Item | Value |
|---|---|
| System | OSCER Sooner, EL9 (`el9hw` container) |
| Compiler / MPI | GCC x.y.z / OpenMPI x.y.z |
| netCDF-C / netCDF-Fortran | x.y.z / x.y.z |
| WRF / WPS | v4.7.1 / v4.7.0 |
| wrf.exe resources | 2 nodes × 20 MPI tasks |
| Wall time (12 h forecast) | see [`results/timing_summary.txt`](results/) |

## Data & software credits
* WRF/WPS: Skamarock et al. (2021), *A Description of the Advanced Research WRF Model
  Version 4.3*, NCAR Tech. Note NCAR/TN-556+STR, doi:10.5065/1dfh-6p97.
* NCEP FNL analyses: doi:10.5065/D6M043C6 (NSF NCAR GDEX d083002).
* Computing: OU Supercomputing Center for Education & Research (OSCER).

## License
Scripts and docs in this repository: MIT (see `LICENSE`). WRF and WPS are distributed
separately under their own public-domain notice.
