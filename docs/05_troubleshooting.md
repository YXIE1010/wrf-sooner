# 5. Troubleshooting

Add every problem you actually hit on Sooner here — this section is what makes the repo
useful to the next person.

## Build
| Symptom | Likely cause / fix |
|---|---|
| `module: command not found` or modules missing | You are not in the EL9 container (`el9`) on the login node, or the job lacks `--container=el9hw`. |
| `configure` can't find netCDF / `netcdf.inc` | netCDF-Fortran not merged into `$NETCDF`; check `ls /scratch/$USER/wrf/build/netcdf-combined/include/netcdf.inc`. |
| Thousands of `Type mismatch` errors | gfortran ≥10 without `-fallow-argument-mismatch`; WRF ≥4.2 adds it automatically — make sure you're on 4.7.x and that `configure.wrf` shows gfortran. |
| `wrf.exe` missing, error mentions `noahmp` / `mmm` / `MYNN` | Source cloned without `--recurse-submodules`: `git submodule update --init --recursive`. |
| `undefined reference to nf_...` | netCDF-C and netCDF-Fortran from different toolchains. |
| Only `ungrib.exe` missing in WPS | JasPer/PNG not found: check `JASPERLIB`, `JASPERINC` in the log, or try the `JasPer/2.x` module (JasPer 3/4 API changes can break older WPS). |
| Compile killed on login node | Never compile on the login node; use the build jobs. |

## WPS
| Symptom | Fix |
|---|---|
| geogrid: `Could not open .../WPS_GEOG/...` | Geog data missing or purged from `/scratch` → re-run `get_geog.sh`. |
| ungrib: `data not found: 2013-05-20_18` | Missing GRIB file for that time; check `ls $MET_DIR/fnl`. |
| metgrid: `missing value encountered in output field ST/SM` | Vtable doesn't match the data; FNL/GFS use `Vtable.GFS`. |

## real.exe / wrf.exe
| Symptom | Fix |
|---|---|
| `input_wrf.F: SIZE MISMATCH: namelist num_metgrid_levels` | Should not happen (auto-filled); check `ncdump -h met_em.d01.* \| grep num_metgrid`. |
| `cfl` messages in `rsl.error.*`, then crash | Reduce `time_step` (e.g. 60), keep `w_damping = 1`, check for steep terrain near boundaries. |
| Job killed, `OOM` | Use `--mem=0` (whole node) — already set — or add nodes. |
| `SUCCESS COMPLETE WRF` missing but no error | Walltime hit: increase `WRF_WALLTIME` in `case.conf` or use more nodes; use restart files for long runs. |

Useful commands:
```bash
grep -i -l error rsl.error.*            # which rank failed
tail -n 30 rsl.error.0000
sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,NodeList
```

## Storage
| Symptom | Fix |
|---|---|
| `Disk quota exceeded` during a build | Builds go to `/scratch`; only the ~0.5 GB install goes to `$HOME`. Check `du -sh ~/* \| sort -h \| tail`; conda package caches (`conda clean --all`) are a common culprit. Or `export WRF_HOME=/ourdisk/...` before building. |
| `wrf.exe: No such file` weeks later | Install lives in `$HOME` and survives; if you moved `WRF_HOME` to `/scratch`, it was purged. Rebuild. |
| WPS build fails: `Build WRF first` | The scratch build tree was purged between the two builds. Re-run `01_get_source.sh` and both builds. |
