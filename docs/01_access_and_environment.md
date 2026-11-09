# 1. Access and environment on OSCER Sooner

## Log in
```bash
ssh <ou_username>@sooner.oscer.ou.edu
```

## The EL9 container (important on Sooner)
Sooner's software modules live inside an Enterprise Linux 9 container.

| Where | What to do |
|---|---|
| Login node, interactive work (`module avail`, checking modules, plotting) | type `el9` first, `exit` when done |
| Submitting jobs (`sbatch`) | **outside** the container; each job enters it via `#SBATCH --container=el9hw` |

All `.slurm` scripts in this repo already include `--container=el9hw`.

## Storage layout used by this repo

| Path | Purpose | Notes |
|---|---|---|
| `~/wrf-oscer-sooner` | this repo (scripts, namelists, docs) | |
| `~/wrf/WRF-4.7.1`, `~/wrf/WPS-4.7.0` | **slim install**: executables + lookup tables only (~0.5 GB) | `$HOME` has a 20 GB quota, backed up nightly |
| `/scratch/$USER/wrf/build` | WRF/WPS source + compiler output (~3 GB) | only needed while compiling; fine if purged later |
| `/scratch/$USER/wrf/WPS_GEOG` | static geographic data (~29 GB) | **not backed up; files untouched for 2 weeks are deleted** |
| `/scratch/$USER/wrf/met` | downloaded GRIB input | re-downloadable |
| `/scratch/$USER/wrf/runs/<case>` | WPS + WRF run directories, `wrfout_*` | copy results you want to keep! |

**Home quota.** Only the slim install (~0.5 GB) goes in `$HOME`. If home is nearly full, set
`export WRF_HOME=/ourdisk/hpc/<group>/wrf` (or another persistent location) before building
and the repo uses no home space at all. Avoid putting the install in `/scratch`: purged
executables mean a rebuild. Check your usage with `du -sh ~` and `du -sh ~/* | sort -h | tail`.

All paths are set in [`env/sooner_wrf.env.sh`](../env/sooner_wrf.env.sh) and can be overridden
with environment variables (e.g. `export GEOG_DIR=/ourdisk/hpc/<group>/WPS_GEOG`).

## Partitions used
| Job | Partition | Resources |
|---|---|---|
| builds, WPS, real.exe | `sooner_test` | 1 node, 1–8 cores, 48 h limit |
| wrf.exe | `sooner_test` (or `sooner_test_32gb_20core`) | 2 nodes × 20 tasks by default |

Check current partitions with `sinfo -s` and the OSCER partitions page.

## Clone the repo on Sooner
```bash
cd ~
git clone https://github.com/<you>/wrf-oscer-sooner.git
cd wrf-oscer-sooner
mkdir -p logs
```
Always run scripts **from the repo root** — job logs go to `./logs/`.
