# climecol 0.1.7

## New
- Added `simulate_temp_shifts()` — generates daily temperature scenarios (e.g., baseline to +5 °C) using the fitted seasonal curve from [`fit_seasonal_temp()`].
  - Supports built-in or user-specified models.
  - Optionally maps results to actual calendar dates.
  - Returns tidy `long` or `wide` format for direct plotting or model input.

### Improvements
- Updated vignette and README examples demonstrating temperature-scenario simulation.
- Added unit tests for scenario generation and date mapping.

### Version
- Incremented version to **0.1.7** and rebuilt pkgdown site.

# climecol 0.1.6

## New features

* Added **`sample_rainfall_by_month()`**, a new stochastic rainfall sampler that  
  generates daily rainfall time series while preserving monthly seasonality.  
  This function resamples observed daily rainfall from the same calendar month  
  across years, maintaining the empirical wet/dry distribution without assuming  
  any specific statistical model.

  - Works directly with the built-in `weather_nl` dataset or user-supplied data.  
  - Automatically detects rainfall columns (`rain_mm`, `precip_mm`, etc.) and  
    standardizes variable names using `normalize_weather_names()`.  
  - Supports reproducible sampling via `seed` and numeric or `Date` input.  
  - Includes optional parameters for handling missing data (`drop_na`, `na_as_zero`).

* Added a new vignette **“Stochastic Daily Rainfall Sampling”** demonstrating  
  realistic daily rainfall simulation for ecological or population models.

## Improvements

* Updated **README** with an example section on rainfall sampling and plotting.  
* Expanded **testthat** coverage to validate reproducibility, month pooling,  
  and robustness to varying input column names.

---

# climecol 0.1.5 (2025-10-06)
- Added `fit_seasonal_photo()` to fit and visualise periodic photoperiod cycles.
- Supports built-in sinusoidal models (`sin1`, `sin2`) and custom user-defined formulas.
- Includes AIC and R² reporting, plus optional plots for visual diagnostics.

# climecol 0.1.4 (2025-10-02)

## New
- Added `fit_seasonal_temp()` to fit seasonal temperature curves to day-of-year means using sinusoidal models, 
returning AIC and R², with an optional plot overlay.


# climecol 0.1.3 (2025-10-01)

## New
- Added `normalize_weather_names()` to standardize column names (e.g., `Date` → `date`, `Rain_mm` → `rain_mm`, `Station.Name` → `station`) for smoother downstream workflows.  
- Added `zzz.R` with `utils::globalVariables()` declarations to silence notes about NSE variables (`n_days`, `n_missing`, etc.).

## Improvements
- Updated `weather_nl` dataset to include `Station.Name`, `Climate.ID`, and a canonical `station` key.  
- Harmonized internal helpers and vignettes to use lower-case column conventions (`date`, `rain_mm`).  
- `summarise_rainfall_monthly()` and `plot_rainfall()` are now robust to modernized column names.

## Fixes
- Fixed vignette build errors caused by outdated column references (`Date`, `Rain_mm`).  
- Fixed examples and tests so they run consistently with the updated dataset and helpers.  


# climecol 0.1.2

- Added new helpers for gap handling and imputation:
  - `complete_daily_calendar()`: ensures a complete daily date sequence per station, inserting missing rows flagged with `is_missing_row`.
  - `summarise_gaps()`: quantifies coverage, missingness, and longest gaps per station or month.
  - `impute_weather()`: provides simple gap fillers (`"locf"`, `"linear"`, `"spline"`) with safeguards for short gaps.
- Extended vignette with a new **Gaps + Imputation** section illustrating their use.
- Improved documentation with explicit notes and caveats about imputation assumptions.

# climecol 0.1.1

- Added **Data management** utilities:
  - `read_weather_csv()`: source-agnostic CSV importer with a default EC mapping.
  - `default_weather_mapping()`: starter mapping for Environment Canada daily exports.
  - `validate_weather()`: configurable QA checks (temp bounds, rain max, optional snow max),
    optional precipitation-consistency flags (rain vs SWE), and calendar completeness.
- Added unit tests for these functions, pkgdown reference section, and vignette.

# climecol 0.1.0

- Initial setup of pkgdown site.
- Photoperiod helpers added: `daylength_f95()`, `photoperiod_year()`.
- Example data `weather_nl`; plotting helper `plot_rainfall()`.

# climecol 0.0.0.9000

- First development snapshot.
