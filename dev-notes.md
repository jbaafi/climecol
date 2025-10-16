# Developer Notes – climecol

This file tracks small improvements, refactors, and deferred features  
for internal development of the **climecol** R package.

*(Internal file — not built into pkgdown site or CRAN releases.)*

---

## 🧭 Overview

These notes help keep track of incremental polish, postponed enhancements,  
and future extension ideas for `climecol`.  
Items marked with `✅` are complete; unchecked items remain open or in progress.

---



## Future Enhancement: 

- [ ] Evaluate numerical precision of `daylength_f95()` at high latitudes; optionally benchmark against `suncalc` or 
NOAA solar ephemeris for sub-minute accuracy.

Unified Photoperiod Wrapper:

**Context:**  
The core function `daylength_f95()` currently provides accurate day-length estimation following Forsythe et al. (1995).  
While fully functional, its name and interface are somewhat technical compared to other high-level functions in *climecol*.

**Planned improvement:**  
- Add a user-facing wrapper function `photoperiod()` that calls `daylength_f95()` internally.  
- Include an argument `method = "forsythe95"` for future extensibility (e.g., `"spencer"`, `"richardson"`).  
- Keep output identical to the current numeric vector (hours of daylight).  
- This wrapper would make the package API more consistent with functions such as `fit_seasonal_temp()` and `fit_seasonal_photo()`.

**Status:**  
Deferred — not required for Chapter 3 submission; to be implemented in a later release.

## 🧹 Core Functions

### 🔧 `read_weather_csv()`
- [ ] Patch handling of files with empty first column (`...1`) created by `readr::read_csv()`.  
  *Plan:* Detect and drop unnamed columns automatically.
- [ ] Add a clearer message when column names are auto-standardized by `normalize_weather_names()`.
- [ ] Add argument `verbose = TRUE` to print summary of imported columns and missing values.

### 🧩 `validate_weather()`
- [x] Improve documentation by including example summary table.
- [ ] Optionally add visual diagnostics (e.g., plot missing dates or temperature anomalies).

### 🧮 `summarise_gaps()`
- [x] Fixed warning about missing `is_missing_row` column.
- [ ] Consider adding argument `min_gap_length` to filter only large data gaps.

---

## 🌦 Seasonal Fits

### 🌡 `fit_seasonal_temp()` / `fit_seasonal_photo()`
- [ ] Consider harmonizing both under a generic `fit_seasonal()` function.
- [ ] Add diagnostics panel (AIC, R², residual plots).
- [ ] Include option to return fitted function as callable closure for model integration.

---

## 🌧 Stochastic Rainfall Sampling
- [x] Added `sample_daily_rainfall()` preserving monthly seasonality.
- [ ] Add seed reproducibility (`set.seed` option in function arguments).
- [ ] Extend to rainfall scenarios (`dry`, `wet`, `erratic`) with random intensity multipliers.

---

## 💾 Data Export

### 📦 `export_weather()`
- [x] Implemented with metadata header block.
- [ ] Add helper `read_export_header()` for retrieving metadata from saved CSVs.
- [ ] Add `compress = TRUE` option (save as `.csv.gz`).

---

## 📘 Documentation & pkgdown

- [ ] **Pkgdown layout polish:**  
  - Align logo beside package name on homepage (currently left-aligned).  
  - Reduce top spacing under `# climecol` in README.
- [ ] Add short article: “Design Philosophy & Reproducibility Principles.”
- [ ] Review vignette headers to ensure consistent title capitalization.

---

## 🧰 Testing

- [ ] Add edge-case tests for missing or malformed CSV inputs.  
- [ ] Increase test coverage for rainfall and photoperiod fits.  
- [x] Use separate test files for custom model inputs (`test-fit_seasonal_temp-custom.R`).

---

## 🚀 Future Extensions

- [ ] Extend `fit_seasonal_photo()` to fetch photoperiod data automatically using latitude/longitude.  
- [ ] Add temperature shift generator (`simulate_temp_shift()`) and integrate into modeling workflows.  
- [ ] Support `degree_days()` computation (optional, for completeness).  
- [ ] Add lightweight `export_weather()` → `import_weather()` round-trip example vignette.

---

## 💡 Release Prep Checklist

Before tagging a new release version (e.g., `v0.1.9`):

1. **Update metadata**
   - [ ] Bump version number in `DESCRIPTION`
   - [ ] Update `NEWS.md` with a clear summary of changes
   - [ ] Ensure `dev-notes.md` is up to date

2. **Rebuild & check**
   - [ ] Run `devtools::check()`
   - [ ] Run `pkgdown::build_site()` to rebuild documentation
   - [ ] Verify that all vignettes build successfully

3. **Commit and push**
   - [ ] Commit all changes  
     ```bash
     git add .  
     git commit -m "Prepare release vX.Y.Z"
     ```
   - [ ] Push to GitHub  
     ```bash
     git push origin master
     ```

4. **Tag the release**
   ```bash
   git tag -a vX.Y.Z -m "climecol vX.Y.Z — brief description"
   git push origin vX.Y.Z
  ```
  
5.	Verify
	- Check pkgdown site updates correctly on GitHub Pages
	- Optionally draft a GitHub release with highlights

_Last updated: `r format(Sys.Date())` by Joseph Baafi._
