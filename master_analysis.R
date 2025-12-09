# Master's Level Final Project Analysis
# Author: [Your Name]
# Date: 2025-11-29
# Purpose: Advanced analysis of College Scorecard data using Machine Learning and Statistical Inference.

# --- 0. Setup & Libraries ---
required_packages <- c("tidyverse", "plotly", "broom", "scales", "randomForest", "glmnet", "caret", "rpart", "rpart.plot", "pdp", "e1071")
new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(new_packages)) install.packages(new_packages, repos = "http://cran.us.r-project.org")

library(tidyverse)
library(scales)
library(plotly)
library(broom)
library(randomForest)
library(glmnet)
library(caret)
library(rpart)
library(rpart.plot)
library(pdp)
library(e1071)

# --- 1. Data Loading & Cleaning ---
print("--- Step 1: Loading and Cleaning Data ---")
file_path <- "College_Scorecard_Raw_Data_10032025/Most-Recent-Cohorts-Institution.csv"

if (!file.exists(file_path)) {
    stop("Error: Data file not found. Please ensure 'Most-Recent-Cohorts-Institution.csv' is in the 'College_Scorecard_Raw_Data_10032025' folder.")
}

# Select relevant columns
# We include Program Mix (PCIP), Institutional Stats, and Outcomes
cols_to_keep <- c(
    "INSTNM", "STABBR", "CONTROL", "REGION", "LOCALE", "LATITUDE", "LONGITUDE",
    "ADM_RATE", "SAT_AVG", "UGDS", "COSTT4_A", "TUITIONFEE_IN", "TUITIONFEE_OUT",
    "MD_EARN_WNE_P10", "C150_4", "GRAD_DEBT_MDN", "PCTPELL", "INEXPFTE",
    "PCIP01", "PCIP03", "PCIP04", "PCIP05", "PCIP09", "PCIP10", "PCIP11", # Agriculture, Resources, Arch, Area, Comm, CommTech, CS
    "PCIP12", "PCIP13", "PCIP14", "PCIP15", "PCIP16", "PCIP19", "PCIP22", # Culinary, Edu, Eng, EngTech, Lang, Family, Legal
    "PCIP23", "PCIP24", "PCIP25", "PCIP26", "PCIP27", "PCIP29", "PCIP30", # English, LibArts, Library, Bio, Math, Mil, Multi
    "PCIP31", "PCIP38", "PCIP39", "PCIP40", "PCIP41", "PCIP42", "PCIP43", # Parks, Phil, Theol, PhysSci, SciTech, Psych, Security
    "PCIP44", "PCIP45", "PCIP46", "PCIP47", "PCIP48", "PCIP49", "PCIP50", # PubAdmin, SocSci, Construct, Mech, Precis, Transp, VisArt
    "PCIP51", "PCIP52", "PCIP54" # Health, Business, History
)

df <- read_csv(file_path,
    na = c("NULL", "PrivacySuppressed", "NA", "PS", ""),
    col_select = all_of(cols_to_keep), show_col_types = FALSE
)

# Convert numeric columns
numeric_cols <- setdiff(names(df), c("INSTNM", "STABBR", "CONTROL", "REGION", "LOCALE"))
df[numeric_cols] <- lapply(df[numeric_cols], as.numeric)

# Convert categorical to factor
df$CONTROL <- as.factor(df$CONTROL)
df$REGION <- as.factor(df$REGION)
df$LOCALE <- as.factor(df$LOCALE)

# Filter for analysis (4-year schools mostly, remove rows with missing Target variables)
df_clean <- df %>%
    filter(!is.na(MD_EARN_WNE_P10), !is.na(C150_4), !is.na(COSTT4_A)) %>%
    na.omit() # For ML, complete cases are safest.

print(paste("Data cleaned. Observations remaining:", nrow(df_clean)))

# --- 1.5 Feature Engineering (Master's Level) ---
print("--- Step 1.5: Feature Engineering (PCA & Clustering) ---")

# A. PCA on Program Mix (Reducing 30+ majors to 3-5 factors)
pcip_cols <- grep("PCIP", names(df_clean), value = TRUE)
# Check for zero variance columns before PCA
zero_var_cols <- pcip_cols[sapply(df_clean[, pcip_cols], var) == 0]
if (length(zero_var_cols) > 0) {
    pcip_cols <- setdiff(pcip_cols, zero_var_cols)
}
pca_res <- prcomp(df_clean[, pcip_cols], scale. = TRUE)

# Scree Plot (Variance Explained)
var_explained <- pca_res$sdev^2 / sum(pca_res$sdev^2)
print(head(var_explained)) # Check how much variance top PCs explain

# Add Top 5 PCs to dataframe
df_clean <- cbind(df_clean, pca_res$x[, 1:5])
print("Added PC1-PC5 to dataframe.")

# B. K-Means Clustering (Finding School Archetypes)
# Cluster based on Cost, Size, Admission Rate, SAT
cluster_vars <- c("COSTT4_A", "UGDS", "ADM_RATE", "SAT_AVG")
df_scaled <- scale(df_clean[, cluster_vars])
set.seed(123)
kmeans_res <- kmeans(df_scaled, centers = 3) # 3 Clusters (e.g., Elite, Public, Private)

df_clean$Cluster <- as.factor(kmeans_res$cluster)
print("Added 'Cluster' to dataframe.")
print(table(df_clean$Cluster))


# ==============================================================================
# RESEARCH QUESTION 1: The "ROI" Prediction (Regression)
# "Can we predict 10-year median earnings based on program mix and institutional stats?"
# ==============================================================================
print("\n--- Q1: ROI Prediction (Earnings) - Ridge/Lasso vs Random Forest ---")
# Note: Keeping RF for Regression as it's a standard advanced method, but replacing it for Classification to match course modules.

# 1. Split Data
set.seed(123)
trainIndex <- createDataPartition(df_clean$MD_EARN_WNE_P10, p = .8, list = FALSE)
df_train <- df_clean[trainIndex, ]
df_test <- df_clean[-trainIndex, ]

# 2. LASSO Regression (Feature Selection)
# We use PCA Factors + Cluster + Inst Stats (Removing raw PCIP to avoid multicollinearity)
predictors <- c("PC1", "PC2", "PC3", "PC4", "PC5", "Cluster", "ADM_RATE", "SAT_AVG", "UGDS", "COSTT4_A", "CONTROL", "REGION")

# Create Matrix
x_train <- model.matrix(as.formula(paste("MD_EARN_WNE_P10 ~", paste(predictors, collapse = "+"))), data = df_train)[, -1]
y_train <- df_train$MD_EARN_WNE_P10
x_test <- model.matrix(as.formula(paste("MD_EARN_WNE_P10 ~", paste(predictors, collapse = "+"))), data = df_test)[, -1]
y_test <- df_test$MD_EARN_WNE_P10

# CV for Lambda
cv_lasso <- cv.glmnet(x_train, y_train, alpha = 1)
lasso_model <- glmnet(x_train, y_train, alpha = 1, lambda = cv_lasso$lambda.min)

# 3. Random Forest (Non-Linear)
rf_formula <- as.formula(paste("MD_EARN_WNE_P10 ~", paste(predictors, collapse = "+")))
rf_model <- randomForest(rf_formula, data = df_train, ntree = 100, importance = TRUE)

# 4. Compare Performance
pred_lasso <- predict(lasso_model, newx = x_test)
pred_rf <- predict(rf_model, newdata = df_test)

rmse_lasso <- sqrt(mean((y_test - pred_lasso)^2))
rmse_rf <- sqrt(mean((y_test - pred_rf)^2))

print(paste("LASSO RMSE:", dollar(rmse_lasso)))
print(paste("RF RMSE:   ", dollar(rmse_rf)))

# Visualization: Top 10 Important Features (RF)
imp_df <- as.data.frame(importance(rf_model))
imp_df$Variable <- rownames(imp_df)
p1 <- ggplot(head(imp_df[order(-imp_df$`%IncMSE`), ], 15), aes(x = reorder(Variable, `%IncMSE`), y = `%IncMSE`)) +
    geom_bar(stat = "identity", fill = "steelblue") +
    coord_flip() +
    labs(title = "Q1: Top Predictors of Earnings (Random Forest)", x = "Variable", y = "% Increase in MSE") +
    theme_minimal()
print(ggplotly(p1))

# Visualization 2: Partial Dependence Plot (PDP) for PC1
# Shows the marginal effect of "Tech Factor" on Earnings
print("Generating Partial Dependence Plot...")
pdp_pc1 <- pdp::partial(rf_model, pred.var = "PC1", train = df_train)
p2 <- ggplot(pdp_pc1, aes(x = PC1, y = yhat)) +
    geom_line(color = "darkgreen", size = 1.2) +
    labs(
        title = "Q1: Partial Dependence of Earnings on Tech Factor (PC1)",
        x = "PC1 (Tech/Science Focus)",
        y = "Predicted Earnings (yhat)"
    ) +
    theme_minimal()
print(ggplotly(p2))


# ==============================================================================
# RESEARCH QUESTION 2: The "At-Risk" Identification (Regression)
# "What drives 6-year graduation rates (C150_4)?"
# ==============================================================================
print("\n--- Q2: At-Risk Identification (Grad Rate) - Linear Reg vs Decision Tree ---")

# 1. Interaction Model (Master's Level)
# Does the effect of "Tech Focus" (PC1) depend on "School Type" (Cluster)?
lm_interaction <- lm(C150_4 ~ PC1 * Cluster + SAT_AVG + ADM_RATE + COSTT4_A + UGDS + CONTROL + PCTPELL, data = df_clean)
print(summary(lm_interaction))

# 2. Interaction Plot
# Visualizing how the slope of PC1 changes for each Cluster
p3 <- ggplot(df_clean, aes(x = PC1, y = C150_4, color = Cluster)) +
    geom_point(alpha = 0.3) +
    geom_smooth(method = "lm", se = FALSE) +
    labs(
        title = "Q2: Interaction Effect (Curriculum x School Type)",
        subtitle = "Does Tech Focus help some schools more than others?",
        x = "PC1 (Tech/Science Focus)",
        y = "Graduation Rate"
    ) +
    theme_minimal()
print(ggplotly(p3))

# 3. Decision Tree (Visualization of Rules)
tree_model <- rpart(C150_4 ~ SAT_AVG + ADM_RATE + COSTT4_A + UGDS + CONTROL + PCTPELL + Cluster + PC1, data = df_clean, method = "anova")

# Plot Tree
rpart.plot(tree_model, main = "Q2: Decision Tree for Graduation Rate", type = 3, extra = 101, fallen.leaves = TRUE)


# ==============================================================================
# RESEARCH QUESTION 3: The "Value" Classification (Classification)
# "Can we classify schools as 'High Value' (High Earnings + Low Cost)?"
# ==============================================================================
print("\n--- Q3: Classification (KNN) ---")

# Define High Value
earn_thresh <- quantile(df_clean$MD_EARN_WNE_P10, 0.66)
cost_thresh <- quantile(df_clean$COSTT4_A, 0.50)
df_clean <- df_clean %>% mutate(High_Value = as.factor(ifelse(MD_EARN_WNE_P10 > earn_thresh & COSTT4_A < cost_thresh, "Yes", "No")))

print("Class Distribution:")
print(table(df_clean$High_Value))

# Train KNN Model (using Cross-Validation)
set.seed(123)
ctrl <- trainControl(method = "cv", number = 10)
knn_model <- train(High_Value ~ SAT_AVG + ADM_RATE + UGDS + REGION + PC1 + Cluster,
    data = df_clean,
    method = "knn",
    trControl = ctrl,
    preProcess = c("center", "scale"),
    tuneLength = 10
)

print(knn_model)

# Visualization: Decision Boundary
# We plot PC1 vs PC2 and color by Predicted Value
df_clean$Pred_KNN <- predict(knn_model, newdata = df_clean)

p4 <- ggplot(df_clean, aes(x = PC1, y = PC2, color = Pred_KNN)) +
    geom_point(alpha = 0.6) +
    labs(title = "Q3: KNN Decision Boundary (Tech vs Arts Factors)", x = "PC1 (Tech Factor)", y = "PC2 (Arts Factor)") +
    theme_minimal()
print(ggplotly(p4))

# ==============================================================================
# RESEARCH QUESTION 4: Spatial Analysis (The "Bonus" Question)
# "Does geographic isolation ('Education Deserts') impact completion rates?"
# ==============================================================================
print("\n--- Q4: Spatial Analysis (Education Deserts) ---")

# 1. Spatial Feature Engineering: Calculate Distance to Nearest Competitor
# We use the Haversine Formula to calculate distance between two points on a sphere
# This is a manual implementation to demonstrate coding skills without extra libraries

deg2rad <- function(deg) {
    return(deg * pi / 180)
}

calculate_nearest_dist <- function(lat, lon, all_lats, all_lons) {
    # Earth radius in km
    R <- 6371

    # Convert to radians
    lat1 <- deg2rad(lat)
    lon1 <- deg2rad(lon)
    lats2 <- deg2rad(all_lats)
    lons2 <- deg2rad(all_lons)

    # Haversine formula
    dlat <- lats2 - lat1
    dlon <- lons2 - lon1

    a <- sin(dlat / 2)^2 + cos(lat1) * cos(lats2) * sin(dlon / 2)^2
    c <- 2 * atan2(sqrt(a), sqrt(1 - a))
    d <- R * c

    # Distance to itself is 0, so we ignore it by setting it to infinity
    d[d == 0] <- Inf

    return(min(d, na.rm = TRUE))
}

print("Calculating distances (this may take a moment)...")
# We'll calculate this for a subset or the whole dataset.
# For speed in this demo, let's do it for the cleaned dataset.
# Vectorizing would be faster, but a loop is clearer for demonstration of the logic.
distances <- numeric(nrow(df_clean))
lats <- df_clean$LATITUDE
lons <- df_clean$LONGITUDE

for (i in 1:nrow(df_clean)) {
    distances[i] <- calculate_nearest_dist(lats[i], lons[i], lats, lons)
}

df_clean$Nearest_Dist <- distances
print("Distance calculation complete.")
print(summary(df_clean$Nearest_Dist))

# 2. Regression Model
# Does Distance impact Grad Rate, controlling for Resources (INEXPFTE)?
lm_spatial <- lm(C150_4 ~ Nearest_Dist + INEXPFTE + CONTROL + REGION, data = df_clean)
print(summary(lm_spatial))

# 3. Geographic Visualization
# Plotting schools on a map, colored by Grad Rate
# Highlighting "Isolated" schools (Distance > 50km)
p5 <- ggplot(df_clean, aes(x = LONGITUDE, y = LATITUDE, color = C150_4, size = Nearest_Dist)) +
    geom_point(alpha = 0.7) +
    scale_color_viridis_c(option = "plasma", name = "Grad Rate") +
    borders("state", colour = "gray80", fill = NA) +
    labs(
        title = "Q4: Geography of Completion Rates",
        subtitle = "Size = Isolation (Distance to Nearest School)",
        x = "Longitude", y = "Latitude"
    ) +
    theme_minimal() +
    coord_fixed(1.3) # Fix aspect ratio for map

print(ggplotly(p5))

print("Analysis Complete.")
