# Comprehensive Analysis: College Scorecard Project (Master's Level)
# This script performs data cleaning, advanced statistical analysis, and Machine Learning.
# UPGRADED: Includes Random Forest, LASSO Regression, and Model Comparison.

# Install required packages if not already installed
required_packages <- c("tidyverse", "plotly", "broom", "scales", "randomForest", "glmnet", "caret")
new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(new_packages)) install.packages(new_packages)

library(tidyverse)
library(scales)
library(plotly)
library(broom)
library(randomForest)
library(glmnet)
library(caret) # For data splitting and cross-validation

# --- 1. Data Loading & Cleaning ---
print("--- Step 1: Loading and Cleaning Data ---")
file_path <- "College_Scorecard_Raw_Data_10032025/Most-Recent-Cohorts-Institution.csv"
if (!file.exists(file_path)) stop("File not found!")

# Select relevant columns - EXPANDED for Machine Learning
# We include potential predictors: Size, Location, Degree Types (Business, Tech, Health, etc.)
cols_to_keep <- c(
  "INSTNM", "STABBR", "CONTROL", "ADM_RATE", "COSTT4_A",
  "TUITIONFEE_IN", "MD_EARN_WNE_P10", "C150_4", "SAT_AVG",
  "UGDS", # Undergraduate Enrollment (Size)
  "PCIP11", # % Computer Science
  "PCIP14", # % Engineering
  "PCIP26", # % Biology
  "PCIP52", # % Business
  "PCIP51", # % Health
  "REGION", # Region ID
  "LOCALE" # Locale (Urban/Rural)
)

df <- read_csv(file_path,
  na = c("NULL", "PrivacySuppressed", "NA", "PS", ""),
  col_select = all_of(cols_to_keep), show_col_types = FALSE
)

# Convert numeric columns
numeric_cols <- c("MD_EARN_WNE_P10", "SAT_AVG", "UGDS", "PCIP11", "PCIP14", "PCIP26", "PCIP52", "PCIP51")
df[numeric_cols] <- lapply(df[numeric_cols], as.numeric)

# Convert categorical to factor
df$CONTROL <- as.factor(df$CONTROL)
df$REGION <- as.factor(df$REGION)
df$LOCALE <- as.factor(df$LOCALE)

# Filter for analysis (4-year schools, no missing values in Target & Key Predictors)
df_ml <- df %>%
  filter(!is.na(MD_EARN_WNE_P10), !is.na(COSTT4_A), !is.na(ADM_RATE), !is.na(SAT_AVG)) %>%
  na.omit() # For ML, we need complete cases or imputation. We'll use complete cases for simplicity.

print(paste("Data cleaned for ML. Observations remaining:", nrow(df_ml)))


# --- 2. Train/Test Split ---
print("\n--- Step 2: Splitting Data (80% Train, 20% Test) ---")
set.seed(123) # For reproducibility
trainIndex <- createDataPartition(df_ml$MD_EARN_WNE_P10,
  p = .8,
  list = FALSE,
  times = 1
)
df_train <- df_ml[trainIndex, ]
df_test <- df_ml[-trainIndex, ]

print(paste("Training Set:", nrow(df_train), "schools"))
print(paste("Test Set:", nrow(df_test), "schools"))


# --- 3. Machine Learning: Random Forest (Non-Linear) ---
print("\n--- Step 3: Training Random Forest Model ---")
# Formula: Earnings ~ All other predictors
rf_model <- randomForest(
  MD_EARN_WNE_P10 ~ COSTT4_A + ADM_RATE + SAT_AVG + UGDS +
    PCIP11 + PCIP14 + PCIP26 + PCIP52 + PCIP51 + CONTROL + REGION,
  data = df_train,
  ntree = 500,
  importance = TRUE
)

print(rf_model)

# Visualization: Variable Importance
print("Generating Variable Importance Plot...")
imp_df <- as.data.frame(importance(rf_model))
imp_df$Variable <- rownames(imp_df)

p_rf <- ggplot(imp_df, aes(x = reorder(Variable, `%IncMSE`), y = `%IncMSE`)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Random Forest: Variable Importance",
    subtitle = "Which factors most strongly predict Future Earnings?",
    x = "Predictor Variable",
    y = "% Increase in MSE (Importance)"
  ) +
  theme_minimal()

print(ggplotly(p_rf))


# --- 4. Machine Learning: LASSO Regression (Linear + Feature Selection) ---
print("\n--- Step 4: Training LASSO Regression Model ---")

# Prepare Matrix Data (glmnet requires matrix input)
x_train <- model.matrix(MD_EARN_WNE_P10 ~ COSTT4_A + ADM_RATE + SAT_AVG + UGDS +
  PCIP11 + PCIP14 + PCIP26 + PCIP52 + PCIP51 + CONTROL + REGION, data = df_train)[, -1]
y_train <- df_train$MD_EARN_WNE_P10

x_test <- model.matrix(MD_EARN_WNE_P10 ~ COSTT4_A + ADM_RATE + SAT_AVG + UGDS +
  PCIP11 + PCIP14 + PCIP26 + PCIP52 + PCIP51 + CONTROL + REGION, data = df_test)[, -1]
y_test <- df_test$MD_EARN_WNE_P10

# Cross-Validation to find optimal Lambda
cv_lasso <- cv.glmnet(x_train, y_train, alpha = 1)
best_lambda <- cv_lasso$lambda.min
print(paste("Optimal Lambda:", best_lambda))

# Fit Final LASSO Model
lasso_model <- glmnet(x_train, y_train, alpha = 1, lambda = best_lambda)

# Visualization: LASSO Coefficients (Feature Selection)
print("Generating LASSO Coefficient Plot...")
lasso_coefs <- as.matrix(coef(lasso_model))
coef_df <- data.frame(Variable = rownames(lasso_coefs), Coefficient = lasso_coefs[, 1]) %>%
  filter(Variable != "(Intercept)", Coefficient != 0) # Show only selected variables

p_lasso <- ggplot(coef_df, aes(x = reorder(Variable, abs(Coefficient)), y = Coefficient, fill = Coefficient > 0)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(
    title = "LASSO Regression: Selected Features",
    subtitle = "Variables with non-zero coefficients (Feature Selection)",
    x = "Predictor Variable",
    y = "Coefficient Magnitude"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(ggplotly(p_lasso))


# --- 5. Model Comparison & Validation ---
print("\n--- Step 5: Model Comparison (Test Set Performance) ---")

# Predictions
pred_rf <- predict(rf_model, newdata = df_test)
pred_lasso <- predict(lasso_model, s = best_lambda, newx = x_test)

# Calculate RMSE (Root Mean Squared Error)
rmse_rf <- sqrt(mean((df_test$MD_EARN_WNE_P10 - pred_rf)^2))
rmse_lasso <- sqrt(mean((df_test$MD_EARN_WNE_P10 - pred_lasso)^2))

# Calculate R-Squared
r2_rf <- cor(df_test$MD_EARN_WNE_P10, pred_rf)^2
r2_lasso <- cor(df_test$MD_EARN_WNE_P10, pred_lasso)^2

# Comparison Table
comparison <- data.frame(
  Model = c("Random Forest (Non-Linear)", "LASSO Regression (Linear)"),
  RMSE = dollar(c(rmse_rf, rmse_lasso)),
  R_Squared = percent(c(r2_rf, r2_lasso))
)

print(comparison)

print("\n--- Interpretation ---")
if (rmse_rf < rmse_lasso) {
  print("CONCLUSION: Random Forest outperformed LASSO. This suggests non-linear relationships and complex interactions are important for predicting earnings.")
} else {
  print("CONCLUSION: LASSO performed similarly or better. This suggests a simpler linear model with feature selection is sufficient.")
}

print("\n--- Analysis Complete. Check Viewer for plots. ---")
