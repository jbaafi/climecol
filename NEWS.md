# climecol 0.1.4

# climecol 0.1.4 (2025-10-02)

## New
- Added `fit_seasonal_temp()` to fit seasonal temperature curves to day-of-year means using sinusoidal models, 
returning AIC and R², with an optional plot overlay.


# climecol 0.1.3

# climecol 0.1.2

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
