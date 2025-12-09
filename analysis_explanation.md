# Guide to the Master's Level Analysis Code (`master_analysis.R`)

This document explains every step of the `master_analysis.R` script in simple terms.

---

## 0. Setup & Libraries
**What we do:** We load a set of powerful R packages.
*   `tidyverse`: The core toolkit for data manipulation (filtering, selecting columns) and plotting (`ggplot2`).
*   `randomForest`: A machine learning algorithm that builds hundreds of "decision trees" to make accurate predictions. It's great for capturing complex, non-linear patterns.
*   `glmnet`: Used for **LASSO** and **Ridge** regression. These are "smart" linear models that can handle hundreds of variables and automatically select the most important ones.
*   `caret`: A helper package for splitting data (Train/Test) and tuning models.
*   `rpart` & `rpart.plot`: Used to build and visualize single Decision Trees (the flowchart-like diagrams).

---

## 1. Data Loading & Cleaning
**What we do:**
1.  **Load Data:** Read the massive College Scorecard dataset.
2.  **Select Columns:** We don't need all 2000+ columns. We select:
    *   **Outcomes:** Earnings (`MD_EARN_WNE_P10`), Graduation Rate (`C150_4`), Debt (`GRAD_DEBT_MDN`).
    *   **School Stats:** Cost (`COSTT4_A`), Size (`UGDS`), SAT Scores (`SAT_AVG`), Admission Rate (`ADM_RATE`).
    *   **Program Mix (`PCIP` columns):** These represent the percentage of degrees awarded in specific fields (e.g., `PCIP14` = Engineering, `PCIP52` = Business). This allows us to see if *what* a school teaches matters more than *who* it admits.
3.  **Filter:** We remove rows with missing values (`NA`) because Machine Learning models generally cannot handle missing data.

---

## 2. Research Question 1: The "ROI" Prediction
**Question:** *Can we predict 10-year median earnings based on program mix and institutional stats?*

### Step 2.1: Split Data
We randomly split the data into **Training (80%)** and **Testing (20%)**.
*   **Training:** The models "learn" from this data.
*   **Testing:** We hide this data from the model and use it later to check if the model is actually accurate (and not just memorizing the answers).

### Step 2.2: LASSO Regression
*   **What it is:** A Linear Regression that penalizes complex models. It shrinks the coefficients of unimportant variables to zero.
*   **Why use it:** We have ~30 program mix variables. LASSO tells us which ones actually matter for earnings (e.g., Engineering) and which don't (e.g., History), effectively performing "Feature Selection."

### Step 2.3: Random Forest
*   **What it is:** A "Forest" of decision trees. Each tree votes on the prediction.
*   **Why use it:** Real life is not always a straight line. Random Forest captures interactions (e.g., "Engineering degrees boost earnings, BUT ONLY IF the school is also selective").

### Step 2.4: Comparison
We compare the **RMSE (Root Mean Squared Error)**.
*   **RMSE:** The average error in dollars. If RMSE = $5,000, our predictions are typically off by $5k. **Lower is better.**

---

## 3. Research Question 2: The "At-Risk" Identification
**Question:** *What drives 6-year graduation rates?*

### Step 3.1: Linear Regression
*   **Goal:** Interpretation.
*   We look at the **Coefficients**. If the coefficient for `SAT_AVG` is positive, it means higher SAT scores lead to higher graduation rates. If `COST` is negative, higher cost reduces graduation rates (holding other factors constant).

### Step 3.2: Decision Tree
*   **Goal:** Visualization.
*   We use `rpart` to create a flowchart.
*   **Example Rule:** "IF `SAT_AVG` < 1000 AND `COST` > $20k, THEN Grad Rate is likely Low."
*   This is very useful for identifying "At-Risk" schools based on simple rules.

---

## 4. Research Question 3: The "Value" Classification
**Question:** *Can we classify schools as "High Value"?*

### Step 4.1: Define "High Value"
We create a new **Binary Variable** (Yes/No).
*   **Rule:** A school is "High Value" if it is in the **Top 33% for Earnings** AND the **Bottom 50% for Cost**.
*   This creates a custom target for us to predict.

### Step 4.2: Logistic Regression vs. Random Forest
*   **Logistic Regression:** Predicts the *probability* of being High Value. Good for understanding the odds.
*   **Random Forest:** Predicts the *class* (Yes/No) directly using complex patterns.

### Step 4.3: Evaluation (AUC)
We use the **ROC Curve** and **AUC (Area Under the Curve)**.
*   **AUC = 0.5:** The model is guessing randomly.
*   **AUC = 1.0:** Perfect prediction.
*   We want to see which model has a higher AUC. Usually, Random Forest wins because it can find "niche" high-value schools that don't follow standard linear rules.
