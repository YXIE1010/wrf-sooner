# 3. Input data

Download on the **login node** (compute nodes may not have outbound internet).

## 3.1 Static geographic data (once)
```bash
bash scripts/data/get_geog.sh                 # high-res mandatory set, ~29 GB unpacked
# GEOG_RES=low bash scripts/data/get_geog.sh  # ~2.5 GB, fine for >=10 km grids
```
Goes to `$GEOG_DIR` (`/scratch/$USER/wrf/WPS_GEOG` by default). Because `/scratch` is purged
after two weeks without access, either ask OSCER whether a shared `WPS_GEOG` exists on Sooner,
keep a copy on project storage, or simply re-run the script (it skips work if data is present).

## 3.2 Meteorological initial/boundary conditions
The case example uses **NCEP FNL 1° analyses** (NSF NCAR GDEX dataset d083002, formerly RDA
ds083.2), 6-hourly GRIB2, ~17 MB/file:
```bash
bash scripts/data/get_case_data.sh cases/2013-05-20_moore
bash scripts/data/get_case_data.sh cases/2023-01-09_california_ar
```
This reads `START`/`END` from each `case.conf` and saves the files in `$MET_DIR/fnl/<case>/`
(one folder per case, so ungrib only sees that case's files). If the HTTPS path changes, find the current pattern under
"Web Download (HTTPS)" on the dataset's data-access page and set `FNL_BASE_URL`.

**Citation:** National Centers for Environmental Prediction/National Weather Service/NOAA/U.S.
Department of Commerce (2000): NCEP FNL Operational Model Global Tropospheric Analyses,
continuing from July 1999. NSF NCAR GDEX, https://doi.org/10.5065/D6M043C6.

### Other forcing options (for new cases)
| Data | Resolution | Vtable | Notes |
|---|---|---|---|
| FNL d083002 | 1°, 6 h | `Vtable.GFS` | 1999–present; used here |
| GDAS/FNL d083003 | 0.25°, 6 h | `Vtable.GFS` | from Jul 2015; better for convection-permitting |
| GFS 0.25° (NOMADS / AWS) | 0.25°, 3 h | `Vtable.GFS` | recent / forecasts |
| ERA5 (CDS or GDEX d633000) | 0.25°, 1 h | `Vtable.ECMWF` (or ERA5 Vtables) | needs pressure + surface files |

`run_real.slurm` reads `num_metgrid_levels` and `num_metgrid_soil_levels` from the met_em files,
so switching data sources only needs `MET_SOURCE`, `VTABLE` and `INTERVAL_SECONDS` in `case.conf`.
