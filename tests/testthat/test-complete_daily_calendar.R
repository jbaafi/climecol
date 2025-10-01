test_that("complete_daily_calendar fills the date sequence and marks gaps", {
  df <- tibble::tibble(
    station = c("A","A","A","B","B"),
    date = as.Date(c("2020-01-01","2020-01-03","2020-01-04","2020-01-02","2020-01-04")),
    tmax_c = c(0, 2, 1, 5, 6)
  )
  out <- complete_daily_calendar(df)
  # A: should include 1->4 (missing 2), B: 2->4 (missing 3)
  expect_true(all(c(as.Date("2020-01-02"), as.Date("2020-01-03")) %in% out$date))
  # Missing rows flagged
  miss <- out |> dplyr::filter(is_missing_row)
  expect_true(any(miss$station == "A" & miss$date == as.Date("2020-01-02")))
  expect_true(any(miss$station == "B" & miss$date == as.Date("2020-01-03")))
})
