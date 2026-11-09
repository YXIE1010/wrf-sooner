#!/usr/bin/env python
"""Temperature and precipitation over complex terrain from WRF output.

    python scripts/plot/plot_t2_precip.py $WRF_RUN results/figures/ca_t2_precip.png --domain d02

Four panels:
  (a) terrain height
  (b) total precipitation accumulated over the run (RAINC + RAINNC, last - first file)
  (c) run-mean 2 m temperature (degC), with the 0 degC contour (rough snow line)
  (d) precipitation vs. elevation scatter, coloured by mean T2 — the orographic signal

Terrain contours (500 m) are drawn on (b) and (c). Uses cartopy if installed.
"""
import argparse
import glob
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr

try:
    import cartopy.crs as ccrs
    import cartopy.feature as cfeature
    HAVE_CARTOPY = True
except ImportError:
    HAVE_CARTOPY = False


def main():
    p = argparse.ArgumentParser()
    p.add_argument("run_dir")
    p.add_argument("out_png")
    p.add_argument("--domain", default="d02")
    a = p.parse_args()

    files = sorted(glob.glob(os.path.join(a.run_dir, f"wrfout_{a.domain}_*")))
    if len(files) < 2:
        raise SystemExit(f"need >=2 wrfout_{a.domain}_* files in {a.run_dir}")
    first, last = xr.open_dataset(files[0]), xr.open_dataset(files[-1])
    lat, lon = first["XLAT"][0].values, first["XLONG"][0].values
    hgt = first["HGT"][0].values
    land = first["LANDMASK"][0].values > 0.5
    attrs = first.attrs

    precip = ((last["RAINC"][0] + last["RAINNC"][0]) -
              (first["RAINC"][0] + first["RAINNC"][0])).values      # mm
    # Mean T2 over all output times (open one at a time to keep memory low)
    t2 = np.zeros_like(hgt, dtype="f8")
    for f in files:
        with xr.open_dataset(f) as ds:
            t2 += ds["T2"][0].values
    t2 = t2 / len(files) - 273.15
    t0 = first["Times"][0].values.tobytes().decode()[:13].replace("_", " ")
    t1 = last["Times"][0].values.tobytes().decode()[:13].replace("_", " ")
    hours = len(files) - 1

    if HAVE_CARTOPY:
        proj = ccrs.LambertConformal(central_longitude=attrs["STAND_LON"],
                                     central_latitude=attrs["CEN_LAT"],
                                     standard_parallels=(attrs["TRUELAT1"], attrs["TRUELAT2"]))
        kw = {"transform": ccrs.PlateCarree()}
    else:
        proj, kw = None, {}

    fig = plt.figure(figsize=(12, 10.5))
    axes = [fig.add_subplot(2, 2, i + 1, projection=proj) if proj else fig.add_subplot(2, 2, i + 1)
            for i in range(3)]
    ax_sc = fig.add_subplot(2, 2, 4)

    def decorate(ax, title):
        if HAVE_CARTOPY:
            ax.add_feature(cfeature.STATES, linewidth=0.5, edgecolor="0.2")
            ax.add_feature(cfeature.COASTLINE, linewidth=0.6)
        ax.set_title(title, fontsize=11, loc="left")

    # (a) terrain
    pm = axes[0].pcolormesh(lon, lat, hgt, cmap="terrain", vmin=-300, vmax=4000, shading="auto", **kw)
    fig.colorbar(pm, ax=axes[0], shrink=0.8, label="m")
    decorate(axes[0], "(a) Terrain height")

    tlev = np.arange(500, 4500, 500)
    # (b) precipitation
    plev = [1, 5, 10, 25, 50, 75, 100, 150, 200, 300, 400]
    cs = axes[1].contourf(lon, lat, precip, levels=plev, cmap="YlGnBu", extend="max", **kw)
    axes[1].contour(lon, lat, hgt, levels=tlev, colors="0.35", linewidths=0.4, **kw)
    fig.colorbar(cs, ax=axes[1], shrink=0.8, label="mm", ticks=plev)
    decorate(axes[1], f"(b) {hours} h precipitation")

    # (c) mean T2 with 0 degC line
    cs = axes[2].contourf(lon, lat, t2, levels=np.arange(-16, 18, 2), cmap="RdYlBu_r", extend="both", **kw)
    axes[2].contour(lon, lat, hgt, levels=tlev, colors="0.35", linewidths=0.4, **kw)
    axes[2].contour(lon, lat, t2, levels=[0], colors="k", linewidths=1.4, **kw)
    fig.colorbar(cs, ax=axes[2], shrink=0.8, label="°C")
    decorate(axes[2], "(c) Mean 2 m temperature (black: 0 °C)")

    # (d) precip vs elevation over land
    sel = land & (precip >= 0)
    sc = ax_sc.scatter(hgt[sel], precip[sel], c=t2[sel], s=2, cmap="RdYlBu_r",
                       vmin=-16, vmax=16, rasterized=True)
    # binned median, 250 m bins
    bins = np.arange(0, np.nanmax(hgt[sel]) + 250, 250)
    idx = np.digitize(hgt[sel], bins)
    med = [np.median(precip[sel][idx == i]) if np.any(idx == i) else np.nan for i in range(1, len(bins))]
    ax_sc.plot(bins[:-1] + 125, med, "k-", lw=2, label="median per 250 m")
    ax_sc.set_xlabel("Elevation (m)")
    ax_sc.set_ylabel(f"{hours} h precipitation (mm)")
    ax_sc.legend(loc="upper left", fontsize=9)
    fig.colorbar(sc, ax=ax_sc, label="mean T2 (°C)")
    ax_sc.set_title("(d) Precipitation vs. elevation (land points)", fontsize=11, loc="left")
    ax_sc.grid(alpha=0.3)

    fig.suptitle(f"WRF {attrs['DX']/1000:g} km ({a.domain})  {t0} – {t1} UTC", fontsize=13)
    fig.tight_layout()
    os.makedirs(os.path.dirname(a.out_png) or ".", exist_ok=True)
    fig.savefig(a.out_png, dpi=150)
    print("wrote", a.out_png)
    print(f"domain-max precip {np.nanmax(precip):.0f} mm; "
          f"land-mean precip {np.nanmean(precip[land]):.1f} mm")


if __name__ == "__main__":
    main()
