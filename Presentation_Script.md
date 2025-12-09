# College Scorecard Analysis: Presentation Script

## **Introduction**

**Visual:** Title Slide (Project Title, Name, Course)

**Script:**
"Good [morning/afternoon], everyone. Today, I’ll be presenting my analysis of the College Scorecard dataset.
Higher education in the US is a massive investment, but the return on that investment varies wildly. My goal was to move beyond simple averages and use advanced statistical methods to understand *what actually drives student success*—specifically looking at Earnings, Graduation Rates, and Value."

---

## **Data & Feature Engineering**

**Visual:** Slide with bullet points: "Data: Most Recent Cohorts", "Challenge: 30+ Major variables", "Solution: PCA & Clustering".

**Script:**
"I started with the `Most-Recent-Cohorts` dataset. Immediatley, I faced a challenge: there were over 30 variables just describing the percentage of degrees awarded in different majors (like Engineering, English, History, etc.).
If I threw all of these into a regression, I’d get multicollinearity chaos.
So, I used **Principal Component Analysis (PCA)** to reduce these 30+ variables down to 5 key 'Curriculum Indices'. For example, PC1 captures the 'Tech vs. Non-Tech' dimension.
I also used **K-Means Clustering** to group schools into distinct archetypes—like 'Elite Research' or 'Budget Commuter'—so we could compare apples to apples."

---

## **RQ1: Can we predict Earnings? (Non-Linearity)**

**Visual:** Partial Dependence Plot (The curve that goes up and flattens).

**Script:**
"My first question was: *Does a Tech-focused curriculum guarantee higher earnings?*
I used a **Random Forest** model because I suspected the relationship wasn't a straight line.
This **Partial Dependence Plot** confirms that suspicion.
You can see a sharp initial rise—shifting to a tech focus yields a high ROI initially. But then, the curve flattens out.
This indicates **diminishing returns**. Once a school becomes 'technical enough', adding *more* engineering programs doesn't significantly boost earnings further. A simple linear regression would have missed this saturation point entirely."

---

## **RQ2: The "Context" of Success (Interaction Analysis)**

**Visual:** Interaction Plot (Diverging lines with different colors for clusters).

**Script:**
"Next, I asked: *Does a Tech curriculum work for EVERY school type?*
To answer this, I used an **Interaction Model** between our Tech Factor (PC1) and the School Clusters.
This plot is the 'Smoking Gun'. The lines are **not parallel**.
For Elite schools, the slope is positive—tech rigor attracts high performers.
But for other clusters, the slope is flatter. This suggests **Contextual Efficacy**: a curriculum change that works for an elite university might not have the same effect in a different institutional context. 'One size fits all' does not apply here."

---

## **RQ3: Classifying "High Value" Schools**

**Visual:** KNN Decision Boundary Plot (Scatter plot with colored regions).

**Script:**
"Third, I wanted to identify 'High Value' schools—those with High Earnings but Low Costs.
I treated this as a classification problem and used **K-Nearest Neighbors (KNN)**.
Why KNN? Because value isn't a linear spectrum.
As you can see in this decision boundary plot, high-value schools tend to form local clusters or 'pockets' in the data. They group together based on shared characteristics. KNN allowed me to capture these non-linear groups effectively, achieving a robust classification accuracy."

---

## **RQ4: The "Education Desert" Effect (Spatial Analysis)**

**Visual:** Geographic Map (Points sized by distance, colored by grad rate).

**Script:**
"Finally, I looked at Geography. I wanted to know if **Isolation** hurts graduation rates.
I engineered a feature called 'Distance to Nearest Competitor' using the **Haversine Formula** to calculate actual spatial distance on a sphere.
The results were statistically significant.
This map visualizes the finding: The large dark dots represent isolated schools in 'Education Deserts', and they consistently show lower graduation rates.
This proves that geographic isolation is a tangible barrier to student success, likely due to a lack of local resources and academic infrastructure."

---

## **Conclusion**

**Visual:** Summary Slide (Key Findings).

**Script:**
"In conclusion, this project demonstrated that:
1.  **Non-Linearity Matters:** The 'Tech Premium' has a limit (Random Forest).
2.  **Context is Key:** Curriculum effects depend on the school type (Interaction).
3.  **Value Clusters:** High-value schools are identifiable by local traits (KNN).
4.  **Geography is Destiny:** Isolation negatively impacts completion (Spatial Analysis).

Thank you. I'm happy to take any questions."
