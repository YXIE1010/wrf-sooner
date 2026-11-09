# 6. Case 2: California atmospheric river, 9–11 January 2023

## Why this case
A strong atmospheric river reached central California on 9–10 January 2023 during that
winter's series of storms. Moist southwesterly flow forced up the Coast Ranges and the Sierra
Nevada produced:
* **precipitation that rises sharply with elevation** (orographic enhancement on the windward
  western slopes, rain shadow in the Owens Valley / Nevada)
* **temperature that falls with elevation**, with a 0 °C line that roughly marks rain vs. snow
  in the Sierra

That makes it a clear demonstration of terrain-controlled temperature and precipitation.

## Configuration
| | d01 | d02 |
|---|---|---|
| Δx | 12 km | 4 km |
| Size | 150 × 140 | 211 × 241 |
| Coverage | eastern Pacific + western US (lets the AR enter from the ocean) | central CA: Bay Area, Central Valley, Sierra Nevada, western NV |
| Time step | 60 s | 20 s |
| Cumulus | Grell–Freitas | none |
| Output | hourly | hourly |

Physics: Thompson MP (8), RRTMG (4), YSU (1), **Noah-MP land surface (4)** for a better
snowpack than Noah, `slope_rad = 1` + `topo_shading = 1` (terrain effects on radiation),
`diff_6th_opt = 2` (damps noise over steep terrain). Run: 2023-01-09 00 UTC → 01-11 00 UTC (48 h).
Forcing: FNL 1°. Because the case is after July 2015, the 0.25° GDAS/FNL (d083003) is a
recommended upgrade; see docs/03.

## Run
```bash
bash scripts/data/get_case_data.sh cases/2023-01-09_california_ar   # login node
bash scripts/run/submit_case.sh  cases/2023-01-09_california_ar     # outside el9
```
Expect about 3× the cost of the Moore case. `case.conf` requests 4 nodes × 20 tasks for 8 h;
adjust after you've measured the Moore run's `timing_summary.txt`.

## Plot temperature + precipitation
```bash
conda activate wrfplot
RUN=/scratch/$USER/wrf/runs/2023-01-09_california_ar
python scripts/plot/plot_domains.py  $RUN/wps results/figures/ca_domains.png
python scripts/plot/plot_t2_precip.py $RUN/wrf results/figures/ca_t2_precip.png --domain d02
```
Four panels: (a) terrain, (b) 48 h precipitation with terrain contours, (c) mean 2 m
temperature with the 0 °C line, (d) precipitation vs. elevation scatter coloured by T2.

## Things to check in the result
* Precipitation maxima on the **windward (west) Sierra slopes** and Santa Cruz / Big Sur
  coastal ranges, with a sharp drop east of the crest. The scatter in panel (d) should show
  precipitation rising with elevation up to the crest.
* The 0 °C T2 contour following the mid-to-upper Sierra elevations.
* For validation, compare with PRISM daily precipitation, or with Stage IV / CNRFC gauges.

## Colorado alternative
To show the Rockies instead, copy this folder, recentre the domains
(`ref_lat ≈ 39.5`, `ref_lon/stand_lon ≈ -105.5`), and pick an event such as the 11–13 Sept
2013 Front Range floods or a spring upslope snowstorm. The plotting script works unchanged.
