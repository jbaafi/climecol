test_that("export_weather writes file with header metadata", {
  data(weather_nl)
  tmp <- tempfile(fileext = ".csv")

  export_weather(weather_nl[1:5, ], tmp,
                 meta = list(station = "St. John's", scenario = "test"))
  expect_true(file.exists(tmp))

  lines <- readLines(tmp, n = 5)
  expect_true(any(grepl("climecol", lines)))
  expect_true(any(grepl("station", lines)))
  unlink(tmp)
})

test_that("export_weather refuses to overwrite unless allowed", {
  data(weather_nl)
  tmp <- tempfile(fileext = ".csv")
  export_weather(weather_nl[1:5, ], tmp)
  expect_error(export_weather(weather_nl[1:5, ], tmp, overwrite = FALSE))
  unlink(tmp)
})
