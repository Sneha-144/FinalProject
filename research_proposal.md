# Advanced Research Questions & Analysis Proposal
**Project:** College Scorecard Analysis (STAT 515)

You asked for "better" research questions. The current analysis (predicting Earnings or Graduation Rate) is standard. To make this a "Master's Level" or "A+" project, we should move from **Prediction** to **Inference** and **Insight**.

Here are three proposed options that are more analytical and tell a stronger story.

---

## Option 1: The "Hidden Gems" Analysis (Two-Stage Residual Modeling)
**Concept:** Everyone knows that Harvard graduates earn a lot. That's not surprising. The interesting question is: *Which schools produce high earners despite being non-selective and affordable?*

*   **Research Question:** "What institutional characteristics distinguish 'Overperforming' colleges (those with higher-than-expected earnings given their selectivity and cost) from underperformers?"
*   **Methodology (The "Value-Add" Approach):**
    1.  **Stage 1 (Base Model):** Run a simple Regression: `Earnings ~ SAT_AVG + COST`.
    2.  **Stage 2 (Residuals):** Calculate the **Residuals** (Actual Earnings - Predicted Earnings).
        *   Positive Residual = School adds more value than expected (Hidden Gem).
        *   Negative Residual = School underperforms given its price/selectivity.
    3.  **Stage 3 (Classification):** Create a binary variable `Is_Gem` (Top 25% of residuals).
    4.  **Stage 4 (Analysis):** Use **Logistic Regression** or **Decision Trees** to predict `Is_Gem` using variables like `Region`, `Program_Mix` (Engineering/Business %), `Diversity`, and `Size`.
*   **Why it's better:** It controls for the obvious confounders (wealth/smart students) to find the *true* institutional effect.

---

## Option 2: The "ROI" Analysis (Debt-to-Earnings Ratio)
**Concept:** High earnings don't matter if you have massive debt. A more practical metric for students is the Return on Investment (ROI).

*   **Research Question:** "Which factors are the strongest determinants of a favorable Debt-to-Earnings ratio?"
*   **Methodology:**
    1.  **Feature Engineering:** Create a new target variable: `ROI_Ratio = MD_EARN_WNE_P10 / GRAD_DEBT_MDN`.
    2.  **Analysis:** Use **Gradient Boosting (XGBoost)** or **Random Forest** to model this ratio.
    3.  **Inference:** Use Partial Dependence Plots (PDP) to see the marginal effect of `Tuition`, `Location`, and `Major_Composition` on ROI.
*   **Why it's better:** It creates a custom, highly relevant metric that doesn't exist in the raw data, showing data science creativity.

---

## Option 3: The "Specialization vs. Prestige" Debate
**Concept:** Does it matter *what* you teach, or just *who* you admit?

*   **Research Question:** "To what extent does the program composition (e.g., % STEM degrees) explain earnings variance *beyond* the effect of institutional selectivity?"
*   **Methodology (Hierarchical Regression):**
    1.  **Model A (Prestige Only):** `Earnings ~ SAT_AVG + ADM_RATE`. Record $R^2$.
    2.  **Model B (Prestige + Specialization):** `Earnings ~ SAT_AVG + ADM_RATE + %Engineering + %Business + %Health`. Record $R^2$.
    3.  **Test:** Perform an ANOVA or F-test to see if Model B is significantly better.
    4.  **Interaction:** Test for interaction: `SAT_AVG * %Engineering`. (e.g., "Does having a strong engineering program matter more at less selective schools?")
*   **Why it's better:** It directly tests a hypothesis about curriculum versus reputation.

---

## Recommendation
I recommend **Option 1 (Hidden Gems)**. It is sophisticated, uses a multi-stage approach (Regression -> Residuals -> Classification), and produces a very cool list of "Best Value" schools that you can list in your report.
