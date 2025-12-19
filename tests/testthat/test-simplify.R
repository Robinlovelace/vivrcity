test_that("calculate_average_counts works correctly", {
  # Create dummy data
  df <- tibble::tibble(
    sensor_name = c("A", "A", "B", "B"),
    class = c("car", "car", "car", "car"),
    count = c(10, 20, 5, 15),
    from = as.POSIXct(c("2023-01-01 00:00", "2023-01-02 00:00", "2023-01-01 00:00", "2023-01-02 00:00")),
    to = as.POSIXct(c("2023-01-01 01:00", "2023-01-02 01:00", "2023-01-01 01:00", "2023-01-02 01:00"))
  )
  
  res <- calculate_average_counts(df, by_sensor = TRUE)
  
  expect_true("sensor_name" %in% names(res))
  expect_true("car" %in% names(res))
  expect_equal(nrow(res), 2)
  
  # Sensor A average: (10+20)/2 = 15
  expect_equal(res$car[res$sensor_name == "A"], 15)
  # Sensor B average: (5+15)/2 = 10
  expect_equal(res$car[res$sensor_name == "B"], 10)
})

test_that("calculate_average_counts handles multiple classes", {
  df <- tibble::tibble(
    sensor_name = c("A", "A"),
    class = c("car", "pedestrian"),
    count = c(10, 5)
  )
  
  res <- calculate_average_counts(df, by_sensor = TRUE)
  
  expect_true("car" %in% names(res))
  expect_true("pedestrian" %in% names(res))
  expect_equal(res$car[res$sensor_name == "A"], 10)
  expect_equal(res$pedestrian[res$sensor_name == "A"], 5)
})
