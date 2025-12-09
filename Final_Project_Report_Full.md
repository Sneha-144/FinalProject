# College Scorecard Analysis: Comprehensive Project Report
**Course:** STAT 515 | **Author:** Sneha Sri

---

## 1. Introduction & Project Overview

### 1.1 Background
Higher education in the United States is characterized by immense diversity in institutional quality, cost, and student outcomes. With rising student debt and questions surrounding the value of a degree, understanding the drivers of student success—both financial (Earnings) and academic (Graduation Rates)—is critical.

### 1.2 Objective
This project moves beyond simple descriptive statistics to apply **Master's Level Machine Learning and Spatial Analysis** techniques to the College Scorecard dataset. The goal is to disentangle the complex relationships between **Curriculum Composition** (what schools teach), **Institutional Context** (the type of school), and **Geographic characteristics** (where schools are located).

---

## 2. Research Questions & Methodology

### RQ1: Earnings Prediction (Non-Linear)
*   **Question:** Can we predict 10-year earnings based on curriculum and school stats?
*   **Rationale for Methods:**
    *   **Random Forest:** Human capital theory suggests that returns to education are not linear (e.g., diminishing returns). We chose Random Forest because it is non-parametric and naturally captures these complex curves and saturation points, where a linear OLS model would fail.
    *   **Partial Dependence Plots (PDP):** To solve the "Black Box" problem of Random Forests, we used PDPs to isolate the marginal effect of the "Tech Curriculum" (PC1) on earnings, allowing us to visualize the exact shape of the relationship.
*   **Findings:** The "Tech Premium" exists but plateaus. Adding engineering programs helps, but only up to a point (diminishing returns).

### RQ2: Graduation Rate (Interaction Analysis)
*   **Question:** Does the benefit of a "Tech Curriculum" depend on the *Type of School*?
*   **Rationale for Methods:**
    *   **Interaction Model:** Standard regression assumes independent effects. We explicitly modeled the **Interaction** (`PC1 * Cluster`) to test "Contextual Efficacy"—the idea that a curriculum strategy working for an Elite school might fail for a Budget school.
    *   **Policy Relevance:** This directly challenges "one size fits all" educational policies.
*   **Findings:** Context matters. Technical rigor is positively associated with graduation rates at Elite schools but neutral/negative at under-resourced schools.

### RQ3: Classification (Value Analysis)
*   **Question:** Can we accurately classify "High Value" schools (High Earnings, Low Cost)?
*   **Rationale for Methods:**
    *   **K-Nearest Neighbors (KNN):** "Value" is a local phenomenon. High-value schools often exist as "pockets" or clusters in the feature space (e.g., State Tech Schools, Elite Privates). KNN classifies based on local similarity (Euclidean distance) in this multi-dimensional space, capturing these irregular clusters better than a linear dividing line (like Logistic Regression).
*   **Findings:** High-value schools form distinct local clusters, suggesting that value is a predictable trait based on observable characteristics.

### RQ4: Spatial Analysis (Geography)
*   **Question:** Do "Education Deserts" (geographic isolation) negatively impact completion rates?
*   **Rationale for Methods:**
    *   **Spatial Feature Engineering (Haversine):** Standard datasets lack "Isolation" metrics. We engineered this feature manually using the Haversine formula to account for the Earth's curvature, providing a rigorous measure of physical access.
*   **Findings:** Geographic isolation is a significant negative predictor of student success ($p < 0.05$), highlighting structural inequities in rural areas.

---

## 3. Data & Feature Engineering
*   **Data Source:** US Dept of Education 'Most-Recent-Cohorts' data.
*   **Dimensionality Reduction:** employed **Principal Component Analysis (PCA)** to reduce 38 PCIP (Major) variables into 5 latent "Curriculum Indices".
*   **Unsupervised Learning:** Used **K-Means Clustering** to segment schools into 3 Archetypes (e.g., Elite, Public, Private) to use as a control variable.

---

## 4. Limitations
1.  **Temporal Dynamics:** The analysis is cross-sectional. We cannot prove causality (e.g., that changing curriculum *causes* earnings to rise) without longitudinal data.
2.  **Aggregation Bias:** We rely on institutional averages. Student-level heterogeneity (within-school variance) is lost.
3.  **Proxy Variables:** `ADM_RATE` is an imperfect proxy for selectivity, and `PCTPELL` is an imperfect proxy for socioeconomic status.

---

## 5. Future Scope
1.  **Longitudinal Panel Analysis:** Tracking schools over 10 years to establish causal links.
2.  **Hierarchical Linear Modeling (HLM):** If student-level data becomes available, modeling the nested structure of Students within Schools.
3.  **Natural Language Processing (NLP):** Analyzing text from course catalogs to create more granular "Tech Focus" metrics than standard CIP codes allow.

---

## 6. References
1.  **U.S. Department of Education.** (2025). *College Scorecard Data*.
2.  **James, G., et al.** (2013). *An Introduction to Statistical Learning*. Springer.
3.  **Hillman, N. W.** (2016). *Geography of College Opportunity: The Case of Education Deserts*. Bayesian Analysis.
