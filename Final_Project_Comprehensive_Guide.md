# Final Project Comprehensive Guide: College Scorecard Analysis (v2)

This document contains **everything** you need to know about your analysis. It covers the variables, the methods, the code steps, and the plot interpretations in simple, precise terms.

---

# Part 1: Data & Variables (The "Ingredients")

## 1. Outcome Variables (What we predict)
*   **`MD_EARN_WNE_P10` (Median Earnings 10 Years Later)**
    *   **Why Median?** Averages are easily skewed by outliers.
        *   *Example:* Imagine 10 people in a bar earning $50k. The mean is $50k. Bill Gates walks in. The **Mean** jumps to $100 Million, but the **Median** stays at $50k. The Median represents the *typical* student, not the lucky billionaire.
*   **`C150_4` (6-Year Graduation Rate)**
    *   **Why:** The federal standard. It accounts for students taking extra time.
*   **`GRAD_DEBT_MDN` (Median Debt)**
    *   **Why:** High earnings don't matter if debt is huge. Essential for "Value" analysis.

## 2. Institutional Stats (The School Characteristics)
*   **`PCTPELL` (Percent Pell Grant)**
    *   **What it is:** The % of students receiving federal aid for low income.
    *   **Why Control for it?** Wealthier students generally graduate at higher rates because they don't have to work two jobs and have better support networks. If we compare a rich school to a poor school directly, the rich school looks "better" just because its students are rich. By including `PCTPELL`, we "control" for this, allowing us to judge the school's performance fairly, regardless of its students' background.
*   **`ADM_RATE` (Admission Rate):** Proxy for Selectivity.
*   **`SAT_AVG` (Average SAT):** Measures student academic quality.
*   **`COSTT4_A` (Average Annual Cost):** The "Sticker Price".

## 3. Program Mix (The "Secret Sauce")
*   **`PCIPxx` Variables (e.g., `PCIP14` = Engineering %)**
    *   **Why:** We test if *what* you teach matters more than *who* you admit.

---

# Part 2: Methodology (The "Master's Level Recipe")

> **Note:** This analysis strictly follows the methods taught in your `unsupervised.html` and `Logistic-n-knn.html` course modules, plus advanced techniques (Interaction, SVM) from reference projects.

## Method 1: Dimensionality Reduction (PCA)
*   **Source:** `unsupervised.html`
*   **The Problem:** We have 30+ major categories. Using all of them creates noise.
*   **The Solution (PCA):** We use **Principal Component Analysis** to compress these into "Indices" (e.g., PC1 = "Tech Heavy", PC2 = "Arts Heavy"). This captures the *structure* of the data without overfitting.

## Method 2: Unsupervised Learning (Clustering)
*   **Source:** `unsupervised.html`
*   **The Problem:** Schools fall into natural groups (Archetypes) that we haven't labeled.
*   **The Solution (K-Means):** We let the data group itself into clusters (e.g., "Elite", "Commuter", "Budget"). We then use these `Clusters` as predictors in our models.

## Method 3: Interaction Analysis (Advanced Regression)
*   **Goal:** To see if "One size fits all".
*   **The Question:** Does a "Tech Focus" (PC1) help *all* schools, or does it depend on the *School Type* (Cluster)?
*   **The Model:** `Grad Rate ~ PC1 * Cluster`. We visually inspect if the lines cross (Interaction Effect) using an Interaction Plot.

## Method 4: Classification (SVM vs. KNN)
*   **Source:** `Logistic-n-knn.html` & Reference Projects
*   **Goal:** Predict if a school is "High Value".
*   **Models:**
    1.  **K-Nearest Neighbors (KNN):** Classifies based on similarity.
    2.  **Support Vector Machine (SVM):** Uses a complex "Hyperplane" to slice the data.
*   **Metric (Kappa):** We use **Cohen's Kappa** to correct for "lucky guessing".

## Method 5: Spatial Analysis (Geography)
*   **Goal:** To measure "Education Deserts".
*   **The Metric:** We calculate the **Distance to Nearest Competitor** for every school using the Haversine Formula (calculating curvature of the earth).
*   **The Question:** Do schools that are geographically isolated have lower completion rates?

---

# Part 3: Step-by-Step Code Explanation

## Step 1: Feature Engineering (PCA & Clustering)
*   **PCA:** We reduce 30+ majors to 5 Principal Components.
*   **Clustering:** We group schools into 3 distinct types.

## Step 2: ROI Prediction (Earnings)
*   **Model:** Random Forest using the new **PCA Factors** + **Clusters**.
*   **New Plot (PDP):** **Partial Dependence Plot**.
    *   *What it shows:* The exact "curve" of how Tech Focus affects Earnings. Does it keep going up, or does it plateau?

## Step 3: At-Risk Identification (Grad Rate)
*   **Interaction Model:** We test `PC1 * Cluster`.
*   **New Plot (Interaction):** **Interaction Plot**.
    *   *What it shows:* Three lines (one for each Cluster). If they have different slopes, it means "Context Matters".
    *   *Example:* Tech might boost Grad Rate for "Elite" schools but hurt it for "Budget" schools (if resources are low).

## Step 4: Value Classification (The "Best Deal")
*   **Models:** KNN vs. SVM.
*   **New Plot (Decision Boundary):** **SVM Boundary Plot**.
    *   *What it shows:* A map of the "High Value" zone. You can visually see the "shape" of the winning schools in the PC1 vs PC2 landscape.
*   **Kappa Score:** We compare which model is "smarter" (Higher Kappa).

## Step 5: Spatial Analysis (The Bonus)
*   **Map Plot:** A map of the US.
    *   **Color:** Graduation Rate (Yellow = High, Purple = Low).
    *   **Size:** Isolation (Larger dots = More isolated).
*   **Insight:** We check if the "Large Dots" (Isolated schools) tend to be "Purple" (Low Grad Rate).

---

# Summary for Your Report
*   **Key Insight:** We moved beyond simple averages to use **Machine Learning** to disentangle the effects of *Student Wealth* (`PCTPELL`) vs. *School Quality* vs. *Program Mix*.
*   **Conclusion:** This approach allows us to identify "Hidden Gem" schools that offer high ROI despite lower prestige or cost.
