#!/usr/bin/env python
"""Plot the WRF domain configuration (terrain of d01 + outline of nests).

    python scripts/plot/plot_domains.py $WPS_RUN results/figures/domains.png

Reads geo_em.d0*.nc written by geogrid. Uses cartopy for coastlines/states if
it is installed, otherwise falls back to a plain lat/lon plot.
"""
import glob
import os
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import xarray as xr

try:
    import cartopy.crs as ccrs
    import cartopy.feature as cfeature
    HAVE_CARTOPY = True
except ImportError:
    HAVE_CARTOPY = False


def outline(ds):
    lat, lon = ds["XLAT_M"][0].values, ds["XLONG_M"][0].values
    xs = list(lon[0, :]) + list(lon[:, -1]) + list(lon[-1, ::-1]) + list(lon[::-1, 0])
    ys = list(lat[0, :]) + list(lat[:, -1]) + list(lat[-1, ::-1]) + list(lat[::-1, 0])
    return xs, ys


def main(wps_dir, out_png):
    files = sorted(glob.glob(os.path.join(wps_dir, "geo_em.d0*.nc")))
    if not files:
        sys.exit(f"no geo_em files in {wps_dir}")
    d01 = xr.open_dataset(files[0])
    lat, lon = d01["XLAT_M"][0], d01["XLONG_M"][0]
    hgt = d01["HGT_M"][0]

    if HAVE_CARTOPY:
        proj = ccrs.LambertConformal(central_longitude=d01.attrs["STAND_LON"],
                                     central_latitude=d01.attrs["MOAD_CEN_LAT"],
                                     standard_parallels=(d01.attrs["TRUELAT1"], d01.attrs["TRUELAT2"]))
        fig, ax = plt.subplots(figsize=(8, 6.5), subplot_kw={"projection": proj})
        kw = {"transform": ccrs.PlateCarree()}
        ax.add_feature(cfeature.STATES, linewidth=0.4, edgecolor="0.3")
        ax.add_feature(cfeature.COASTLINE, linewidth=0.6)
    else:
        fig, ax = plt.subplots(figsize=(8, 6.5))
        kw = {}

    pm = ax.pcolormesh(lon, lat, hgt, cmap="terrain", vmin=-200, vmax=3000, shading="auto", **kw)
    fig.colorbar(pm, ax=ax, shrink=0.75, label="Terrain height (m)")
    for f in files[1:]:
        ds = xr.open_dataset(f)
        xs, ys = outline(ds)
        dx = ds.attrs["DX"] / 1000
        ax.plot(xs, ys, color="k", lw=1.5, **kw)
        ax.text(xs[0], ys[0], f" {os.path.basename(f)[7:10]} ({dx:g} km)",
                va="bottom", fontsize=9, **kw)
    ax.set_title(f"WRF domains — d01 {d01.attrs['DX']/1000:g} km")
    fig.tight_layout()
    os.makedirs(os.path.dirname(out_png) or ".", exist_ok=True)
    fig.savefig(out_png, dpi=150)
    print("wrote", out_png)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
