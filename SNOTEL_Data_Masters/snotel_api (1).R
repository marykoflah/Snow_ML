library(httr)
library(tibble)
library(dplyr)
library(purrr)
library(glue)


#base URL
url_base = glue("https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1/data?stationTriplets={station_triplet}&elements={{replace}}%2C%20WTEQ&duration=HOURLY&beginDate={start_dateapi}&endDate={end_dateapi}&periodRef=END&centralTendencyType=NONE&returnFlags=false&returnOriginalValues=false&returnSuspectData=false")

# Empty list to store data for each element
data_list <- list()

# Loop through each element
for (element in elements) {
  # Substitute {replace} with the current element in the URL
  url <- gsub("\\{replace\\}", element, url_base)
  
  # Send GET request to the API
  response <- GET(url)
  
  if (status_code(response) == 200) {
    data <- content(response, "parsed", simplifyVector = TRUE)
    
    if ("data" %in% names(data) && "values" %in% names(data$data[[1]])) {
      values_data <- data$data[[1]]$values[[1]]
      
      # Convert the 'date' column to POSIXct (datetime)
      df <- tibble(
        Date = as.POSIXct(values_data$date, format="%Y-%m-%d %H:%M", tz = "UTC"),
        Value = as.numeric(values_data$value)
      )
      
      # Rename 'Value' to the current element name for clarity
      colnames(df)[2] <- element
      
      # Add the data frame to the list
      data_list[[element]] <- df
    } else {
      cat("No 'values' field found for element:", element, "\n")
    }
  } else {
    cat("Error in API request for element:", element, "\n")
  }
}

# Generate the complete hourly date-time sequence
complete_date_range <- seq(
  from = as.POSIXct(paste(start_dateapi, "00:00"), tz = "UTC"),
  to = as.POSIXct(paste(end_dateapi, "00:00"), tz = "UTC"),
  by = "hour"
)

# Ensure the 'Date' column is of class POSIXct in all data frames
data_list <- lapply(data_list, function(df) {
  # Ensure that the 'Date' column is of class POSIXct
  df$Date <- as.POSIXct(df$Date, tz = "UTC")
  
  # Create a tibble with the complete date range and join it with the current data frame
  tibble(Date = complete_date_range) %>%
    left_join(df, by = "Date") %>%
    arrange(Date)  # Ensure the data is sorted by Date
})

# Combine all data frames into one
final_data <- reduce(data_list, left_join, by = "Date")

