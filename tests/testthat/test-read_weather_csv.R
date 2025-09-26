test_that("read_weather_csv standardizes EC-like columns", {
  path <- testthat::test_path("testdata", "mini_ec.csv")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(
    'Date.Time,Station.Name,Climate.ID,Longitude..x.,Latitude..y.,Max.Temp...C.,Min.Temp...C.,Total.Rain..mm.,Total.Snow..cm.,Total.Precip..mm.,Snow.on.Grnd..cm.,Dir.of.Max.Gust..10s.deg.,Spd.of.Max.Gust..km.h.
2013-01-01,YYT,123,-52.75,47.62,-2.0,-6.5,0.0,0.0,0.0,0,18,35', path)

  wx <- read_weather_csv(path)
  expect_true(all(c(
    "date","station","climate_id","lon","lat",
    "tmax_c","tmin_c","tavg_c","rain_mm","snow_cm","precip_mm",
    "snow_on_ground_cm","wind_spd_kmh","wind_dir_deg"
  ) %in% names(wx)))
  expect_s3_class(wx$date, "Date")
  expect_equal(nrow(wx), 1)
  expect_equal(wx$station[1], "YYT")
  expect_equal(wx$tmax_c[1], -2)
  expect_equal(wx$tmin_c[1], -6.5)
})

test_that("read_weather_csv works with a custom mapping", {
  path <- testthat::test_path("testdata", "mini_custom.csv")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(
    'my_date,my_station,tmax,tmin,rr
2013-02-01,S1,2.3,-1.1,5.0
2013-02-02,S1,1.0,-2.0,0.0', path)

  my_map <- c(
    "my_date"    = "date",
    "my_station" = "station",
    "tmax"       = "tmax_c",
    "tmin"       = "tmin_c",
    "rr"         = "rain_mm"
  )
  wx <- read_weather_csv(path, mapping = my_map)
  expect_equal(nrow(wx), 2)
  expect_true(all(c("date","station","tmax_c","tmin_c","rain_mm") %in% names(wx)))
  expect_equal(wx$rain_mm[1], 5.0)
  expect_s3_class(wx$date, "Date")
})
