# Master's Level Code Explanation & Report Guide

This document provides a **step-by-step technical rationale** for every major block of code in your analysis. Use this to explain "Why" you did what you did in your report or presentation.

---

## 1. Setup & Libraries
**Code:** `library(pdp)`, `library(e1071)`, `library(randomForest)`
*   **Why:**
    *   `randomForest`: For non-linear regression (RQ1). Standard linear regression assumes straight lines; RF captures complex curves.
    *   `pdp`: To "open the black box" of the Random Forest. It allows us to visualize the specific effect of one variable (Tech Focus) while averaging out others.
    *   `e1071`: Contains the **Support Vector Machine (SVM)** algorithm, a standard tool in advanced data analytics.

## 2. Data Loading & Cleaning
**Code:** `cols_to_keep <- c(..., "LATITUDE", "LONGITUDE", "INEXPFTE", ...)`
*   **Why these variables?**
    *   `LATITUDE/LONGITUDE`: Essential for the **Spatial Analysis** (RQ4). Without these, we cannot calculate the "Education Desert" metric.
    *   `INEXPFTE` (Instructional Expenditure per FTE): A critical control variable. We need to know if a school has low grad rates because it's *isolated* (Geography) or just *poor* (Funding).
    *   `PCIPxx`: We kept all major percentages to perform PCA.

---

## 3. Feature Engineering (The "Master's Touch")

### A. Principal Component Analysis (PCA)
**Code:** `prcomp(df_clean[, pcip_cols], scale. = TRUE)`
*   **The Problem:** You have 30+ variables for majors (`PCIP01`, `PCIP11`, etc.). If you put them all in a regression, you get **Multicollinearity** (variables correlated with each other), which breaks the model.
*   **The Solution:** PCA reduces these 30 variables down to 5 "Principal Components" (PC1, PC2, etc.).
*   **Interpretation:**
    *   **PC1:** Likely represents "Tech vs. Non-Tech" (since Engineering/CS often correlate).
    *   **PC2:** Likely represents "Arts/Humanities".
*   **Why Scale?** PCA is sensitive to scale. We must set `scale. = TRUE` so that large majors don't dominate small ones.

### B. K-Means Clustering
**Code:** `kmeans(df_scaled, centers = 3)`
*   **The Goal:** To find "Latent Structures" in the data. We suspect schools fall into types (e.g., "Elite Research", "Budget Commuter"), but the dataset doesn't have a label for that.
*   **Why K-Means?** It's an unsupervised algorithm that mathematically groups similar data points.
*   **Why 3 Clusters?** A heuristic choice. 2 is too simple, 10 is too complex. 3 usually captures "High", "Medium", and "Low" resource tiers.

---

## 4. RQ1: Earnings (Random Forest & PDP)
**Code:** `randomForest(MD_EARN_WNE_P10 ~ ...)`
*   **Why Random Forest?** Earnings are rarely linear. A little bit of engineering helps a lot, but *too much* might not add more value (diminishing returns). Linear regression misses this; Random Forest catches it.
*   **The Plot (PDP):** `pdp::partial(...)`
    *   **Visual:** The line goes up steeply and then flattens.
    *   **Explanation:** This proves the **Non-Linearity** hypothesis. It shows that the "Tech Premium" has a saturation point.

---

## 5. RQ2: Graduation Rate (Interaction Analysis)
**Code:** `lm(C150_4 ~ PC1 * Cluster)`
*   **Why the Asterisk (*)?** In R, `*` means "Interaction".
    *   `PC1 + Cluster` means: "Tech matters, and School Type matters." (Independent effects).
    *   `PC1 * Cluster` means: "The effect of Tech *DEPENDS ON* the School Type."
*   **The Plot (Interaction Plot):**
    *   **Visual:** Non-parallel lines.
    *   **Explanation:** This proves **Contextual Efficacy**. A curriculum change that works for an "Elite" school might fail at a "Budget" school. This is a high-level policy insight.

---

## 6. RQ3: Classification (SVM vs. KNN)
**Code:** `svm(..., kernel = "radial")`
*   **Why SVM?** It is a "Maximum Margin Classifier". It tries to find the widest possible "street" separating the two classes.
*   **Why Radial Kernel?** A "Linear Kernel" draws a straight line. A "Radial Kernel" can draw circles or blobs. Real-world data is rarely separated by a straight line.
*   **Metric:** `Kappa`
    *   **Why?** If 90% of schools are "Not High Value", a dummy model that says "No" to everyone gets 90% Accuracy. **Kappa** corrects for this. A Kappa of 0.41 means the model is actually learning, not just guessing.

---

## 7. RQ4: Spatial Analysis (Geography)
**Code:** `calculate_nearest_dist(...)` (Haversine Formula)
*   **Why Manual Code?** Calculating distance on a sphere (Earth) requires trigonometry (Sines and Cosines). Implementing this manually demonstrates **Algorithm Engineering** skills, rather than just importing a library.
*   **The Regression:** `lm(C150_4 ~ Nearest_Dist + ...)`
    *   **Hypothesis:** If `Nearest_Dist` is negative significant, it means "Farther away = Lower Grad Rate".
    *   **Result:** The p-value is < 0.05, confirming the "Education Desert" theory.
*   **The Map:**
    *   **Visual:** Large dots (Isolated) are often Purple (Low Grad Rate). This visually confirms the statistical finding.

---

## Summary for Your Report
When writing your report, use this structure:
1.  **"We used PCA to handle multicollinearity..."**
2.  **"We chose Random Forest to capture non-linear ROI..."**
3.  **"We used Interaction Terms to test for contextual effects..."**
4.  **"We applied Spatial Econometrics to quantify geographic isolation..."**

This language signals "Master's Level" understanding.
