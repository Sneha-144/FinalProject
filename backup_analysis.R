# Backup Analysis Plan: Specific Master's Level Research Questions
# This script implements the exact research questions and methods requested in the backup plan.

# Install required packages
required_packages <- c("tidyverse", "plotly", "broom", "scales", "randomForest", "glmnet", "caret", "pROC")
new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(new_packages)) install.packages(new_packages)

library(tidyverse)
library(scales)
library(plotly)
library(broom)
library(randomForest)
library(glmnet)
library(caret)
library(pROC)

# --- 1. Data Loading & Cleaning ---
print("--- Step 1: Loading and Cleaning Data ---")
file_path <- "College_Scorecard_Raw_Data_10032025/Most-Recent-Cohorts-Institution.csv"
if (!file.exists(file_path)) stop("File not found!")

# Select relevant columns based on the specific questions
cols_to_keep <- c(
    "INSTNM", "STABBR", "CONTROL", "ADM_RATE", "SAT_AVG", "UGDS",
    "MD_EARN_WNE_P10", "C150_4",
    "NPT4_PUB", "NPT4_PRIV", # Net Price (Public & Private)
    "PCTPELL", # Percent Pell Grant
    "AVGFACSAL", # Average Faculty Salary
    "GRAD_DEBT_MDN", # Median Student Debt
    "LOCALE" # Locale
)

df <- read_csv(file_path,
    na = c("NULL", "PrivacySuppressed", "NA", "PS", ""),
    col_select = all_of(cols_to_keep), show_col_types = FALSE
)

# Data Preprocessing
# 1. Combine NPT4_PUB and NPT4_PRIV into a single 'NET_PRICE' column
df <- df %>% mutate(NET_PRICE = coalesce(NPT4_PUB, NPT4_PRIV))

# 2. Convert numeric columns
numeric_cols <- c("MD_EARN_WNE_P10", "SAT_AVG", "UGDS", "PCTPELL", "AVGFACSAL", "GRAD_DEBT_MDN", "NET_PRICE", "ADM_RATE", "C150_4")
df[numeric_cols] <- lapply(df[numeric_cols], as.numeric)

# 3. Convert categorical
df$CONTROL <- as.factor(df$CONTROL)
df$LOCALE <- as.factor(df$LOCALE)

# 4. Filter for Complete Cases (Essential for ML)
df_clean <- df %>%
    filter(
        !is.na(MD_EARN_WNE_P10), !is.na(NET_PRICE), !is.na(SAT_AVG),
        !is.na(UGDS), !is.na(PCTPELL), !is.na(AVGFACSAL),
        !is.na(GRAD_DEBT_MDN), !is.na(C150_4)
    )

print(paste("Data cleaned. Observations remaining:", nrow(df_clean)))


# ==============================================================================
# RESEARCH QUESTION 1: Prediction & Feature Selection (LASSO vs OLS)
# "To what extent can we predict median earnings using LASSO vs OLS?"
# ==============================================================================
print("\n--- Q1: LASSO vs OLS (Predicting Earnings) ---")

# 1. Split Data
set.seed(123)
trainIndex <- createDataPartition(df_clean$MD_EARN_WNE_P10, p = .8, list = FALSE)
df_train <- df_clean[trainIndex, ]
df_test <- df_clean[-trainIndex, ]

# 2. LASSO Regression
# Prepare Matrix
x_train <- model.matrix(MD_EARN_WNE_P10 ~ NET_PRICE + SAT_AVG + UGDS + PCTPELL + AVGFACSAL, data = df_train)[, -1]
y_train <- df_train$MD_EARN_WNE_P10
x_test <- model.matrix(MD_EARN_WNE_P10 ~ NET_PRICE + SAT_AVG + UGDS + PCTPELL + AVGFACSAL, data = df_test)[, -1]

cv_lasso <- cv.glmnet(x_train, y_train, alpha = 1)
lasso_model <- glmnet(x_train, y_train, alpha = 1, lambda = cv_lasso$lambda.min)

# 3. OLS Regression (Standard Linear Model)
ols_model <- lm(MD_EARN_WNE_P10 ~ NET_PRICE + SAT_AVG + UGDS + PCTPELL + AVGFACSAL, data = df_train)

# 4. Compare RMSE
pred_lasso <- predict(lasso_model, newx = x_test)
pred_ols <- predict(ols_model, newdata = df_test)

rmse_lasso <- sqrt(mean((df_test$MD_EARN_WNE_P10 - pred_lasso)^2))
rmse_ols <- sqrt(mean((df_test$MD_EARN_WNE_P10 - pred_ols)^2))

print(paste("LASSO RMSE:", dollar(rmse_lasso)))
print(paste("OLS RMSE:  ", dollar(rmse_ols)))

# Visualization: LASSO Coefficients
lasso_coefs <- as.matrix(coef(lasso_model))
coef_df <- data.frame(Variable = rownames(lasso_coefs), Coefficient = lasso_coefs[, 1]) %>% filter(Variable != "(Intercept)")
p1 <- ggplot(coef_df, aes(x = reorder(Variable, abs(Coefficient)), y = Coefficient, fill = Coefficient > 0)) +
    geom_bar(stat = "identity") +
    coord_flip() +
    labs(title = "Q1: LASSO Feature Selection", x = "Variable") +
    theme_minimal()
print(ggplotly(p1))


# ==============================================================================
# RESEARCH QUESTION 2: Classification & Non-Linear Modeling (RF vs Logistic)
# "Which method better predicts High Graduation Rate (>70%)?"
# ==============================================================================
print("\n--- Q2: Random Forest vs Logistic (Predicting High Grad Rate) ---")

# 1. Create Target Variable
df_clean <- df_clean %>% mutate(High_Grad_Rate = as.factor(ifelse(C150_4 > 0.70, "Yes", "No")))
df_train <- df_clean[trainIndex, ] # Re-use split but with new column
df_test <- df_clean[-trainIndex, ]

# 2. Random Forest
rf_model <- randomForest(High_Grad_Rate ~ SAT_AVG + ADM_RATE + NET_PRICE + LOCALE + CONTROL + UGDS,
    data = df_train, ntree = 500, importance = TRUE
)

# 3. Logistic Regression
log_model <- glm(High_Grad_Rate ~ SAT_AVG + ADM_RATE + NET_PRICE + LOCALE + CONTROL + UGDS,
    data = df_train, family = binomial
)

# 4. Compare AUC & Confusion Matrices
# RF Predictions
prob_rf <- predict(rf_model, newdata = df_test, type = "prob")[, 2]
roc_rf <- roc(df_test$High_Grad_Rate, prob_rf)

# Logistic Predictions
prob_log <- predict(log_model, newdata = df_test, type = "response")
roc_log <- roc(df_test$High_Grad_Rate, prob_log)

print(paste("Random Forest AUC:", round(auc(roc_rf), 3)))
print(paste("Logistic Reg AUC: ", round(auc(roc_log), 3)))

# Visualization: RF Variable Importance
imp_df <- as.data.frame(importance(rf_model))
imp_df$Variable <- rownames(imp_df)
p2 <- ggplot(imp_df, aes(x = reorder(Variable, MeanDecreaseGini), y = MeanDecreaseGini)) +
    geom_bar(stat = "identity", fill = "darkgreen") +
    coord_flip() +
    labs(title = "Q2: Random Forest Variable Importance", x = "Variable") +
    theme_minimal()
print(ggplotly(p2))


# ==============================================================================
# RESEARCH QUESTION 3: Multivariate Inference
# "Difference in Student Debt between Public vs Private, controlling for Size & Selectivity?"
# ==============================================================================
print("\n--- Q3: Multivariate Inference (Student Debt) ---")

# Model: Debt ~ Control + SAT + UGDS
model_q3 <- lm(GRAD_DEBT_MDN ~ CONTROL + SAT_AVG + UGDS, data = df_clean)
print(summary(model_q3))

# Visualization: Effect of Control on Debt (Partial Residuals or Boxplot)
# Simple Boxplot for visualization
p3 <- ggplot(df_clean, aes(x = CONTROL, y = GRAD_DEBT_MDN, fill = CONTROL)) +
    geom_boxplot() +
    scale_y_continuous(labels = dollar_format()) +
    labs(title = "Q3: Student Debt by Institution Type", y = "Median Student Debt") +
    theme_minimal()
print(ggplotly(p3))

print("Backup Analysis Complete.")

