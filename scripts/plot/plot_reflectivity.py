#!/usr/bin/env python
"""Composite (column-max) simulated radar reflectivity from wrfout files.

    python scripts/plot/plot_reflectivity.py $WRF_RUN results/figures/refl_d02.png \
        --domain d02 --times 2013-05-20_19:00:00 2013-05-20_20:00:00 \
                             2013-05-20_21:00:00 2013-05-20_22:00:00

Requires do_radar_ref = 1 in namelist.input (writes REFL_10CM).
An optional --mark LAT LON draws a star (default: Moore, OK).
"""
import argparse
import glob
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
from matplotlib.colors import BoundaryNorm, ListedColormap

try:
    import cartopy.crs as ccrs
    import cartopy.feature as cfeature
    HAVE_CARTOPY = True
except ImportError:
    HAVE_CARTOPY = False

# NWS-style reflectivity colors, 5 dBZ bins from 5 to 75
NWS = ["#04e9e7", "#019ff4", "#0300f4", "#02fd02", "#01c501", "#008e00", "#fdf802",
       "#e5bc00", "#fd9500", "#fd0000", "#d40000", "#bc0000", "#f800fd", "#9854c6"]
LEVELS = np.arange(5, 80, 5)


def load(run_dir, domain, when):
    path = os.path.join(run_dir, f"wrfout_{domain}_{when}")
    if not os.path.exists(path):
        cands = sorted(glob.glob(os.path.join(run_dir, f"wrfout_{domain}_*")))
        raise SystemExit(f"{path} not found. Available: {[os.path.basename(c) for c in cands][:6]} ...")
    ds = xr.open_dataset(path)
    refl = ds["REFL_10CM"][0].max(dim="bottom_top")
    return ds["XLAT"][0], ds["XLONG"][0], refl, ds.attrs


def main():
    p = argparse.ArgumentParser()
    p.add_argument("run_dir"); p.add_argument("out_png")
    p.add_argument("--domain", default="d02")
    p.add_argument("--times", nargs="+", required=True)
    p.add_argument("--mark", nargs=2, type=float, default=[35.34, -97.49])
    a = p.parse_args()

    n = len(a.times)
    ncol = 2 if n > 1 else 1
    nrow = int(np.ceil(n / ncol))
    _, _, _, attrs = load(a.run_dir, a.domain, a.times[0])
    if HAVE_CARTOPY:
        proj = ccrs.LambertConformal(central_longitude=attrs["STAND_LON"],
                                     central_latitude=attrs["CEN_LAT"],
                                     standard_parallels=(attrs["TRUELAT1"], attrs["TRUELAT2"]))
        sub = {"projection": proj}
        kw = {"transform": ccrs.PlateCarree()}
    else:
        sub, kw = {}, {}
    fig, axes = plt.subplots(nrow, ncol, figsize=(5.2 * ncol, 4.6 * nrow),
                             subplot_kw=sub, squeeze=False)
    cmap = ListedColormap(NWS)
    norm = BoundaryNorm(LEVELS, cmap.N)

    for ax, t in zip(axes.flat, a.times):
        lat, lon, refl, _ = load(a.run_dir, a.domain, t)
        pm = ax.pcolormesh(lon, lat, np.ma.masked_less(refl, 5), cmap=cmap, norm=norm,
                           shading="auto", **kw)
        if HAVE_CARTOPY:
            ax.add_feature(cfeature.STATES, linewidth=0.5, edgecolor="0.25")
        ax.plot(a.mark[1], a.mark[0], marker="*", color="k", ms=10, **kw)
        ax.set_title(f"{a.domain}  {t.replace('_', ' ')[:16]} UTC", fontsize=10)
    for ax in list(axes.flat)[n:]:
        ax.set_visible(False)
    fig.colorbar(pm, ax=axes, orientation="horizontal", fraction=0.04, pad=0.04,
                 label="Composite simulated reflectivity (dBZ)")
    fig.suptitle(f"WRF {attrs.get('DX', 0)/1000:g} km — column-max REFL_10CM", y=0.99)
    os.makedirs(os.path.dirname(a.out_png) or ".", exist_ok=True)
    fig.savefig(a.out_png, dpi=150, bbox_inches="tight")
    print("wrote", a.out_png)


if __name__ == "__main__":
    main()
