# Retrieves count data for all available countlines over a one-year period. This function iterates through all countlines found in metadata and calls `get_counts()` for each, combining the results into a single data frame.

Retrieves count data for all available countlines over a one-year
period. This function iterates through all countlines found in metadata
and calls
[`get_counts()`](https://robinlovelace.github.io/vivrcity/reference/get_counts.md)
for each, combining the results into a single data frame.

## Usage

``` r
get_all_countline_counts_annual(end_date = Sys.time(), time_bucket = "24h")
```

## Arguments

- end_date:

  The end date for the one-year period (POSIXct object). Defaults to the
  current system time.

- time_bucket:

  Time bucket size (e.g. "1h", "5m"). Defaults to "24h".

## Value

A data frame of counts.
