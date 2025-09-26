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
