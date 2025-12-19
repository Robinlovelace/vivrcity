# Get Countline Counts

Get Countline Counts

## Usage

``` r
get_countline_counts(
  countline_ids,
  from,
  to,
  classes = NULL,
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

- classes:

  Vector of classes to include.

- time_bucket:

  Time bucket size (e.g. "1h", "5m"). Defaults to "24h".

- wait:

  Seconds to wait between API requests. Defaults to 1.

## Value

Data frame of counts.
