test_that("validate_weather flags gaps and negatives", {
  df <- tibble::tibble(
    date = as.Date(c("2020-01-01","2020-01-03")),  # gap at 2020-01-02
    station = "X",
    tmax_c = c(0, 1),
    tmin_c = c(-1, -2),
    rain_mm = c(0, -1),
    precip_mm = c(0, 0),
    snow_cm = c(0, 0)
  )
  out <- validate_weather(df)
  expect_gte(out$summary$n_missing_dates, 1)
  expect_true(any(out$flags$flag == "negative_rain"))
})

test_that("validate_weather respects configurable temperature bounds", {
  df <- tibble::tibble(
    date = as.Date("2020-02-01") + 0:2,
    station = "Y",
    tmax_c = c(55, 10, 5),     # 55 exceeds upper bound if < 55 allowed
    tmin_c = c( 0, -70, 1),    # -70 below lower bound if > -70 allowed
    rain_mm = c(0, 0, 0),
    precip_mm = c(0, 0, 0),
    snow_cm = c(0, 0, 0)
  )

  out_default <- validate_weather(df)  # default [-60,60]
  expect_true(any(out_default$flags$flag == "temp_out_of_range"))

  out_tight <- validate_weather(df, temp_bounds = c(-50, 50))
  expect_gte(sum(out_tight$flags$flag == "temp_out_of_range"),
             sum(out_default$flags$flag == "temp_out_of_range"))
})

test_that("validate_weather flags rain above rain_max and snow above snow_max", {
  df <- tibble::tibble(
    date = as.Date("2020-03-01") + 0:2,
    station = "Z",
    tmax_c = c(1, 1, 1),
    tmin_c = c(0, 0, 0),
    rain_mm = c(50, 250, 10),   # middle exceeds default rain_max=200
    precip_mm = c(60, 260, 10),
    snow_cm = c(10, 200, 5)     # 200 exceeds snow_max=60 in strict call
  )

  out_default <- validate_weather(df)  # rain_max = 200, snow_max = Inf
  expect_true(any(out_default$flags$flag == "rain_gt_max"))
  expect_false(any(out_default$flags$flag == "snow_gt_max"))

  out_strict <- validate_weather(df, rain_max = 100, snow_max = 60)
  expect_gte(sum(out_strict$flags$flag == "rain_gt_max"),
             sum(out_default$flags$flag == "rain_gt_max"))
  expect_true(any(out_strict$flags$flag == "snow_gt_max"))
})

test_that("validate_weather checks precip consistency with swe_ratio and can be disabled", {
  df <- tibble::tibble(
    date = as.Date("2020-04-01") + 0:2,
    station = "W",
    tmax_c = c(2, 2, 2),
    tmin_c = c(0, 0, 0),
    rain_mm = c(20, 5, NA_real_),
    snow_cm = c(3, 8, 10),
    precip_mm = c(15, 60, 50)  # Row1: 15 < rain(20) -> inconsistent
    # Row2: 60 >= rain(5) but compare with snow*swe
    # Row3: rain NA, still compare precip vs snow*swe
  )

  # Default swe_ratio = 10:
  out_default <- validate_weather(df)
  expect_true(any(out_default$flags$flag == "precip_inconsistent"))  # at least row1

  # Stronger SWE (15 mm per cm): row2 becomes inconsistent if 60 < 8*15 = 120
  out_swe15 <- validate_weather(df, swe_ratio = 15)
  expect_gte(sum(out_swe15$flags$flag == "precip_inconsistent"),
             sum(out_default$flags$flag == "precip_inconsistent"))

  # Disable consistency check entirely
  out_off <- validate_weather(df, check_precip_consistency = FALSE)
  expect_false(any(out_off$flags$flag == "precip_inconsistent"))
})
