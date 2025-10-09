test_that("simulate_temp_shifts builds scenarios from best model", {
  data(weather_nl)
  fit <- fit_seasonal_temp(weather_nl, funcs = c("sin1","sin2"))
  sims <- simulate_temp_shifts(fit, deltas = 0:2, as_long = FALSE)

  expect_true(all(c("day_of_year","baseline","Temp+0C","Temp+1C","Temp+2C") %in% names(sims)))
  # shifts are additive
  i <- 100
  expect_equal(sims$`Temp+1C`[i] - sims$baseline[i], 1, tolerance = 1e-8)
  expect_equal(sims$`Temp+2C`[i] - sims$baseline[i], 2, tolerance = 1e-8)
})

test_that("simulate_temp_shifts maps to supplied dates", {
  data(weather_nl)
  fit <- fit_seasonal_temp(weather_nl, funcs = "sin1")
  days <- seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
  sims <- simulate_temp_shifts(fit, deltas = c(0,5), dates = days, as_long = TRUE)

  expect_true(all(c("date","key","temp_c") %in% names(sims)))
  expect_true(all(levels(sims$key) == c("baseline","Temp+0C","Temp+5C")))
  # additivity at a specific day
  d <- as.Date("2024-07-01")
  base <- sims$temp_c[sims$date == d & sims$key == "baseline"]
  plus5 <- sims$temp_c[sims$date == d & sims$key == "Temp+5C"]
  expect_equal(plus5 - base, 5, tolerance = 1e-8)
})
