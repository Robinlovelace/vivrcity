library(vivarcity)
library(dplyr)

# Check API key availability
if (Sys.getenv("VIVACITY_API_KEY") == "") {
  stop("VIVACITY_API_KEY not found in environment")
}

cat("Fetching Hardware Metadata...\n")
tryCatch({
  hw <- get_hardware_metadata()
  print(tibble::as_tibble(hw))
}, error = function(e) {
  cat("Error fetching hardware metadata:", e$message, "\n")
})

cat("\nFetching Countline Metadata...\n")
tryCatch({
  cl <- get_countline_metadata()
  print(tibble::as_tibble(cl))
}, error = function(e) {
  cat("Error fetching countline metadata:", e$message, "\n")
})

