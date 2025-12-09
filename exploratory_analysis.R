# Exploratory Analysis: Finding a Research Question
# This script visualizes three potential research topics to help you decide on your final project.

library(tidyverse)
library(scales)

# 1. Load Data (using the same method as before)
file_path <- "College_Scorecard_Raw_Data_10032025/Most-Recent-Cohorts-Institution.csv"
if (!file.exists(file_path)) stop("File not found!")

# Read specific columns to save memory and time
# We need:
# - INSTNM: Institution Name
# - STABBR: State
# - CONTROL: Control (Public/Private)
# - ADM_RATE: Admission Rate
# - COSTT4_A: Average Cost of Attendance (Academic Year)
# - TUITIONFEE_IN: In-state Tuition
# - TUITIONFEE_OUT: Out-of-state Tuition
# - MD_EARN_WNE_P10: Median Earnings 10 years after entry
# - C150_4: Completion Rate (4-year institutions)
# - SAT_AVG: Average SAT Score

cols_to_keep <- c("INSTNM", "STABBR", "CONTROL", "ADM_RATE", "COSTT4_A", 
                  "TUITIONFEE_IN", "TUITIONFEE_OUT", "MD_EARN_WNE_P10", "C150_4", "SAT_AVG")

print("Loading selected columns...")
df <- read_csv(file_path, na = c("NULL", "PrivacySuppressed", "NA", "PS", ""), 
               col_select = all_of(cols_to_keep), show_col_types = FALSE)

# Convert Earnings to numeric (sometimes read as character due to "PrivacySuppressed")
df$MD_EARN_WNE_P10 <- as.numeric(df$MD_EARN_WNE_P10)

# Filter for 4-year degrees mostly (where Completion Rate is not NA) for cleaner plots
df_clean <- df %>% filter(!is.na(C150_4))

# --- OPTION 1: ECONOMIC (Do expensive schools yield higher earnings?) ---
print("Generating Plot 1: Cost vs. Earnings...")
p1 <- ggplot(df_clean, aes(x = COSTT4_A, y = MD_EARN_WNE_P10)) +
  geom_point(alpha = 0.5, color = "darkblue") +
  geom_smooth(method = "lm", color = "red") +
  scale_x_continuous(labels = dollar_format()) +
  scale_y_continuous(labels = dollar_format()) +
  labs(title = "Research Option 1: Does Higher Cost Lead to Higher Earnings?",
       x = "Average Cost of Attendance (Annual)",
       y = "Median Earnings (10 Years Later)") +
  theme_minimal()
print(p1)

# --- OPTION 2: GEOGRAPHIC (Which states are most expensive?) ---
print("Generating Plot 2: Tuition by State...")
# Filter to top 15 states by number of schools to keep plot readable
top_states <- df_clean %>% count(STABBR, sort = TRUE) %>% head(15) %>% pull(STABBR)

p2 <- df_clean %>%
  filter(STABBR %in% top_states) %>%
  ggplot(aes(x = reorder(STABBR, TUITIONFEE_IN, FUN = median), y = TUITIONFEE_IN)) +
  geom_boxplot(fill = "lightblue") +
  scale_y_continuous(labels = dollar_format()) +
  labs(title = "Research Option 2: Tuition Costs by State (Top 15 States)",
       x = "State",
       y = "In-State Tuition") +
  theme_minimal()
print(p2)

# --- OPTION 3: SELECTIVITY (Do selective schools have better graduation rates?) ---
print("Generating Plot 3: Selectivity vs. Graduation...")
p3 <- ggplot(df_clean, aes(x = ADM_RATE, y = C150_4)) +
  geom_point(alpha = 0.5, color = "darkgreen") +
  geom_smooth(method = "lm", color = "orange") +
  scale_x_continuous(labels = percent_format()) +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Research Option 3: Does Selectivity Predict Graduation Rate?",
       subtitle = "Note: Lower Admission Rate = More Selective",
       x = "Admission Rate",
       y = "Completion Rate (Graduation)") +
  theme_minimal()
print(p3)

print("Exploratory analysis complete. Check the 'Plots' tab in RStudio to see the graphs.")
