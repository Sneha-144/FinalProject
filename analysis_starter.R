# Analysis Starter Script for College Scorecard Data
# This script loads the dataset and performs basic data inspection.

# Load necessary libraries
# If you don't have tidyverse installed, run: install.packages("tidyverse")
library(tidyverse)

# Define the file path
# Note: Adjust the path if the script is moved or run from a different directory
file_path <- "College_Scorecard_Raw_Data_10032025/Most-Recent-Cohorts-Institution.csv"

# Check if file exists
if (!file.exists(file_path)) {
  stop("File not found! Please check the path: ", file_path)
}

# Load the dataset
# using read_csv from readr (part of tidyverse) for better performance with large files
# na = c("NULL", "PrivacySuppressed", "NA", "PS") based on data.yaml
print("Loading dataset... this may take a moment.")
df <- read_csv(file_path, na = c("NULL", "PrivacySuppressed", "NA", "PS", ""), show_col_types = FALSE)

# Display basic information
print("Dataset loaded successfully!")
print(paste("Dimensions:", nrow(df), "rows and", ncol(df), "columns"))

# Inspect the first few rows and columns
print("First 5 rows and 5 columns:")
print(df[1:5, 1:5])

# Example Analysis:
# 1. Summary of Admission Rate (ADM_RATE)
# 2. Summary of In-State Tuition (TUITIONFEE_IN)

print("Summary of Admission Rate (ADM_RATE):")
summary(df$ADM_RATE)

print("Summary of In-State Tuition (TUITIONFEE_IN):")
summary(df$TUITIONFEE_IN)

# Example: Top 10 Schools by Cost (In-State Tuition)
print("Top 10 Most Expensive Schools (In-State Tuition):")
top_expensive <- df %>%
  select(INSTNM, STABBR, TUITIONFEE_IN) %>%
  arrange(desc(TUITIONFEE_IN)) %>%
  head(10)
print(top_expensive)

# Example: Average Admission Rate by State
print("Average Admission Rate by State (Top 10):")
state_adm_rate <- df %>%
  group_by(STABBR) %>%
  summarise(Avg_Adm_Rate = mean(ADM_RATE, na.rm = TRUE), Count = n()) %>%
  arrange(desc(Avg_Adm_Rate)) %>%
  head(10)
print(state_adm_rate)

print("Analysis starter script completed.")
