test_that("photoperiod_year returns plausible values", {
  d <- photoperiod_year(2024, lat = 47.56)
  expect_true(nrow(d) %in% c(365, 366))
  # Summer solstice at ~47.6°N is ~15.9–16.0 h with Forsythe (refraction -0.833°)
  expect_gt(max(d$daylength_hours), 15.8)
  expect_lt(min(d$daylength_hours), 9.5)
})

test_that("location lookup works (case/spacing agnostic)", {
  d1 <- photoperiod_year(2024, location = "St John's")
  d2 <- photoperiod_year(2024, location = "st_johns")
  expect_identical(d1$lat[1], d2$lat[1])
})


test_that("Saint John NB vs St. John's NL are distinct", {
  nl <- photoperiod_year(2024, location = "St John's")
  nb <- photoperiod_year(2024, location = "Saint John")
  # Higher latitude (NL) should have a larger max summer daylength
  expect_gt(max(nl$daylength_hours), max(nb$daylength_hours))
})
