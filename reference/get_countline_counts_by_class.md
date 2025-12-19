# Get Countline Counts by Class/Mode

Returns counts broken down by transport class (pedestrian, cyclist,
etc.)

## Usage

``` r
get_countline_counts_by_class(
  countline_ids,
  from,
  to,
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

- time_bucket:

  Time bucket size (e.g. "1h", "5m"). Defaults to "24h".

- wait:

  Seconds to wait between API requests. Defaults to 1.

## Value

Data frame with counts by class in long format.
