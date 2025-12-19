# Get Countline Counts

Simple wrapper to get countline counts with class breakdown by default.
This is the recommended function for most use cases. It automatically
fetches metadata to add `name` and `sensor_name` columns, enabling
easier aggregation by sensor.

## Usage

``` r
get_counts(
  countline_ids,
  from,
  to,
  by_class = TRUE,
  split_direction = TRUE,
  aggregate = FALSE,
  time_bucket = "24h",
  wait = 1
)
```

## Arguments

- countline_ids:

  Vector of countline IDs.

- from:

  Start timestamp.

- to:

  End timestamp.

- by_class:

  If TRUE (default), returns counts broken down by transport class
  (pedestrian, cyclist, etc.) in long format. If FALSE, returns total
  counts only.

- split_direction:

  If TRUE (default), preserves direction information. If FALSE, sums
  counts across directions.

- aggregate:

  If TRUE, aggregates the results by sensor (summing directions and
  combining countlines belonging to the same sensor). Defaults to FALSE.

- time_bucket:

  Time bucket size (e.g. "1h", "5m"). Defaults to "24h".

- wait:

  Seconds to wait between API requests. Defaults to 1.

## Value

A data frame with columns `id`, `sensor_name`, `name`, `from`, `to`,
`class`, `direction`, `count`. If `by_class` is FALSE, `class` will be
"all". If `split_direction` is FALSE, `direction` column is omitted
(counts are summed). If `aggregate` is TRUE, `id` column will contain
the sensor name, and the `direction` and `name` columns are removed.
