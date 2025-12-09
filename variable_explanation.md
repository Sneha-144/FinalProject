# Data Dictionary & Rationale: Why These Variables?

This document explains exactly which columns were selected for the `master_analysis.R` script, why they were chosen, and what alternatives existed.

---

## 1. Outcome Variables (What we are predicting)

### `MD_EARN_WNE_P10` (Median Earnings 10 Years After Entry)
*   **What it is:** The median salary of students 10 years after they started college.
*   **Why selected:** This is the "Gold Standard" for measuring economic ROI. 10 years allows enough time for graduates to establish their careers.
*   **Alternatives:**
    *   `MD_EARN_WNE_P6` (6 Years): Too soon. Many graduates are still in entry-level jobs or grad school.
    *   `MN_EARN_WNE_P10` (Mean Earnings): Averages are skewed by outliers (e.g., one billionaire). Medians are more robust.

### `C150_4` (6-Year Graduation Rate)
*   **What it is:** The percentage of students who complete a 4-year degree within 6 years (150% of normal time).
*   **Why selected:** This is the federal standard for measuring completion. It accounts for students who change majors or take a semester off.
*   **Alternatives:**
    *   `C100_4` (4-Year Rate): Too strict. Many students take 4.5 or 5 years.
    *   `RET_FT4` (Retention Rate): Only measures if they came back for year 2, not if they finished.

### `GRAD_DEBT_MDN` (Median Debt)
*   **What it is:** The median federal student loan debt of graduates.
*   **Why selected:** Essential for the "Value" analysis. High earnings don't matter if debt is astronomical.

---

## 2. Institutional Characteristics (The "Who")

### `ADM_RATE` (Admission Rate)
*   **What it is:** The percentage of applicants accepted.
*   **Why selected:** A proxy for **Selectivity** and **Prestige**. Lower rate = more selective.
*   **Alternatives:**
    *   `SAT_AVG`: Also good, but some schools are "Test Optional." We used both to be safe.

### `SAT_AVG` (Average SAT Score)
*   **What it is:** The average SAT score of admitted students.
*   **Why selected:** Measures the academic "input" quality of the student body.
*   **Alternatives:**
    *   `ACT_AVG`: We could use this, but SAT is more universally reported in this dataset.

### `UGDS` (Undergraduate Enrollment)
*   **What it is:** The number of degree-seeking undergraduates.
*   **Why selected:** Measures **Size**. Large state schools behave differently than small liberal arts colleges.

### `COSTT4_A` (Average Annual Cost)
*   **What it is:** The average annual total cost of attendance (Tuition + Room + Board + Books).
*   **Why selected:** The most accurate measure of the "Price Tag."
*   **Alternatives:**
    *   `TUITIONFEE_IN` (Tuition Only): Ignores cost of living, which is huge in cities like NYC.
    *   `NPT4` (Net Price): This is cost *after* scholarships. It's good, but `COSTT4_A` is better for the "Sticker Price" vs. Value comparison.

### `CONTROL` (Ownership)
*   **What it is:** Public vs. Private Non-Profit vs. Private For-Profit.
*   **Why selected:** Fundamental structural difference. Public schools are subsidized; For-profits are businesses.

### `PCTPELL` (Percent Pell Grant)
*   **What it is:** The percentage of undergraduates receiving federal Pell Grants (for low-income students).
*   **Why selected:** The standard proxy for **Socioeconomic Status (SES)**. Wealthier students often have more resources and higher graduation rates, so we must control for this to see if the *school* is performing well, or if they just have wealthy students.

---

## 3. Program Mix (The "What")
*   **Variable Names:** `PCIP01` through `PCIP54`.
*   **What they are:** The percentage of degrees awarded in a specific field.
    *   `PCIP11` = Computer Science
    *   `PCIP14` = Engineering
    *   `PCIP52` = Business
    *   `PCIP51` = Health
    *   `PCIP24` = Liberal Arts
*   **Why selected:** This is the **Master's Level** addition. Most basic analyses ignore this. We included ~30 of these to test the hypothesis: *"Does it matter if you go to a fancy school, or does it just matter if you study Engineering?"*
*   **Alternatives:**
    *   Binary "Has Engineering Program" (Yes/No): Too simple. We want to know the *focus* of the school (e.g., Georgia Tech is 60% Eng, UVA is 10% Eng).

---

## 4. Step-by-Step Explanation of the Code

### Step 1: Loading & Cleaning
*   **Action:** We load the CSV and select *only* the columns listed above.
*   **Why:** The raw file has 2,000+ columns. Loading all of them crashes R or makes it slow. We pick the "Signal" and ignore the "Noise."
*   **Cleaning:** We drop rows with `NA` (missing values). If a school doesn't report its Earnings, we can't use it to train our model.

### Step 2: ROI Prediction (LASSO + Random Forest)
*   **Action:** We feed all the `PCIP` (Major) variables + `SAT_AVG` + `COST` into the models.
*   **Why:**
    *   **LASSO:** It's a "Truth Serum." It will look at all 30 majors and tell us: "Only Engineering, CS, and Nursing actually increase earnings. History and Art don't."
    *   **Random Forest:** It finds "Interaction Effects." Example: Maybe Art degrees *do* pay well, but *only* if you go to Yale. Random Forest can find that hidden rule.

### Step 3: At-Risk Identification
*   **Action:** We predict `C150_4` (Grad Rate).
*   **Why:** We want to help policy-makers.
*   **Decision Tree:** We use this because it draws a picture. It might show: "If SAT < 900 and Cost > 20k, Grad Rate is < 40%." This is an actionable "Red Flag" rule.

### Step 4: Value Classification
*   **Action:** We create a "High Value" label (High Earnings + Low Cost).
*   **Why:** Parents don't care about "Regression Coefficients." They care about "Is this school a good deal?"
*   **Logistic Regression:** Tells us the *Probability* (e.g., "There is an 80% chance UVA is High Value").
