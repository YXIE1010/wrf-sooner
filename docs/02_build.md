# 2. Building WRF and WPS

Target: **WRF v4.7.1** (ARW, `em_real`, GNU + OpenMPI, `dmpar`) and **WPS v4.7.0** (serial, GRIB2).

## 2.0 Is there already a module?
```bash
el9
module -t avail 2>&1 | grep -iE '^(WRF|WPS)/'
```
If OSCER provides a recent WRF/WPS module you *can* use it, but building your own makes the
build reproducible and documentable (the point of this repo), and lets you modify the code later.

## 2.1 Toolchain: chosen automatically
You don't pick module versions by hand. The first time `02_build_wrf.slurm` runs, it calls
[`scripts/build/00_setup_modules.sh`](../scripts/build/00_setup_modules.sh), which:
1. lists every GNU-built `netCDF-Fortran` module (`gompi-*` / `foss-*`), newest first;
2. loads it, which also loads the matching GCC, OpenMPI, netCDF-C and HDF5;
3. finds `JasPer` and `libpng` for the same GCC version (needed by WPS);
4. **compiles and runs a tiny MPI + netCDF Fortran program** to prove the set works;
5. saves the first set that passes to `env/sooner_modules.sh`, which every later job reuses.

The chosen versions are written as comments in `env/sooner_modules.sh`. Copy them into the
README's "Tested configuration" table. To re-pick (for example after an OSCER software update),
delete that file. You can also run the script yourself on the login node (`el9` first).

## 2.2 Get the source (login node)
```bash
bash scripts/build/01_get_source.sh
```
Clones the release tags with `--recurse-submodules` (Noah-MP, MMM physics, MYNN-EDMF are
submodules — a non-recursive clone fails late in the compile).

## 2.3 Compile (compute nodes)
```bash
mkdir -p logs             # run sbatch OUTSIDE el9 (jobs enter it themselves)
jid=$(sbatch --parsable scripts/build/02_build_wrf.slurm)
sbatch --dependency=afterok:$jid scripts/build/03_build_wps.slurm
```

What the WRF build job does:
1. **Merges netCDF-C and netCDF-Fortran into one prefix** (`~/wrf/netcdf-combined`, symlinks).
   WRF's `configure` expects both under `$NETCDF`; EasyBuild installs them separately.
2. `./configure` with option **34** (GNU dmpar) and nesting **1** (basic).
3. `./compile -j 8 em_real` → `main/{wrf,real,ndown,tc}.exe`.

The WPS job configures option **1** (gfortran serial), points `WRF_DIR` at the build above,
uses `JASPERLIB/JASPERINC` from the JasPer module, and checks `geogrid.exe`, `ungrib.exe`,
`metgrid.exe`.

> Configure menu numbers occasionally change between releases. If the `grep` of
> `configure.wrf` in the log does not show `gfortran`/`mpif90`, run `./configure` by hand once,
> find the right number, and resubmit with `sbatch --export=ALL,WRF_CONFIG_OPT=<n> ...`.

## 2.4 Verify
```bash
ls -l ~/wrf/WRF-4.7.1/main/*.exe
ls -l ~/wrf/WPS-4.7.0/*.exe
grep -c -i ' error' ~/wrf/WRF-4.7.1/compile_em_real.log   # 0 is ideal; context matters
```

## If netCDF-Fortran is not available as a module
Ask support@oscer.ou.edu first. Otherwise build it yourself into `~/wrf/libs` against the
loaded netCDF-C module (`./configure --prefix=$HOME/wrf/libs CC=gcc FC=gfortran`,
`CPPFLAGS=-I$(nc-config --includedir)`, `LDFLAGS=-L$(nc-config --libdir)`), and point
`MOD_NETCDF_F` at nothing / add `$HOME/wrf/libs/bin` to `PATH` so `nf-config` resolves.
