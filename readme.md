# Technical Support Operations Analysis

## 📌 Overview
This project analyzes **2,330 technical support tickets** to track ticket volumes, identify common issues, evaluate agent performance, and measure Service Level Agreement (SLA) success rates. 

**Tools Used:** Microsoft Excel, PostgreSQL

![Dashboard Preview](/Dashboard_Image/Screenshot%202026-02-19%20185001.png)

---

## 💡 Executive Summary & Recommendations
Based on the data, the support team has a **33.61% overall SLA failure rate** and an average resolution time of **33.2 hours**. 

**Key Insights:**
* **The Priority Triage is Broken:** Medium (35.04%) and Low (33.89%) priority tickets fail their SLAs the most, but High priority tickets are still failing at a 30.29% rate. *Recommendation: Implement a dedicated "Fast Track" queue for High Priority tickets.*
* **Product Setup is a Bottleneck:** "Product Setup" drives the highest volume (630 tickets) and receives the lowest customer survey score (3.4). *Recommendation: Develop better self-service onboarding documentation to deflect these tickets.*
* **Volume vs. Quality:** The agent handling the highest volume of tickets (Sheela Cutten - 302 tickets) has a lower customer satisfaction score (3.65) compared to agents with slightly lower volumes (e.g., Connor Danielovitch - 273 tickets, 4.07 score).
* **Traffic Patterns:** Email is the dominant channel (1,234 tickets). The busiest time of day for support is consistently 15:00 (3:00 PM).

---

## 📊 Excel Analysis & Dashboarding
I started by loading the raw data into Excel, standardizing timestamps, and calculating true resolution durations.

* **Duration Calculation:** Used `=IF(([@[Resolution time]]-[@[Created time]])*24<0," ",([@[Resolution time]]-[@[Created time]])*24)` to find the exact resolution time in hours.
* **SLA Validation:** Calculated the 33.61% failure rate using `=COUNTIF(Data!N:N,"SLA Violated")/Total Tickets`.

I then built an interactive dashboard utilizing slicers (Months, Agent Groups, Product Groups) to visualize:
* **Volume trends** via Line Charts (Peak: January, Low: February).
* **Geographical impact** via Clustered Bar Charts (Top regions: Germany and Italy).
* **Resolution bottlenecks** via Bar Charts (Training Requests take the longest at 38.9 hours).

---

## 💻 PostgreSQL Analysis
I used SQL to verify the primary KPIs and query the database for deeper operational insights.

First, I wrote queries to match the primary KPIs:

**1. Total Tickets**
```sql
SELECT
       COUNT(*)
FROM
       technical_support;
```

**2. Average Survey Result**
```sql
SELECT
       ROUND(AVG(survey_results),2) AS average_survey_result
FROM
       technical_support;
```

**3. Average Resolution Hour**
```sql
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (resolution_time - created_time))/3600), 2) AS avg_resolution_hours
FROM
    technical_support
WHERE
    status IN ('Closed','Resolved');
```

**4. Overall SLA Failure Rate**
```sql
SELECT
       ROUND(
             100.0*SUM(CASE WHEN sla_for_resolution = 'SLA Violated' THEN 1 ELSE 0 END)
             /
             COUNT(ticket_id)
       ,2) || '%' AS overall_SLA_failure_rate
FROM
       technical_support;
```

Next, I used SQL to answer specific operational questions:

**1. Percentage of tickets that violated the SLA for First Response vs. Resolution**
* **Answer:** First response failed 13.35% of the time, and Resolution failed 33.61% of the time.
```sql
SELECT
       ROUND(100.0*SUM(CASE WHEN SLA_for_first_response = 'SLA Violated' THEN 1 ELSE 0 END)/COUNT(ticket_id),2) || '%' AS perc_violated_first_response,
       ROUND(100.0*SUM(CASE WHEN sla_for_resolution = 'SLA Violated' THEN 1 ELSE 0 END)/COUNT(ticket_id),2) || '%' AS perc_violated_resolution
FROM
       technical_support ts;
```

**2. Actual time taken to resolve tickets by Priority**
* **Answer:** Low -> 32:15:27, High -> 33:09:58, Medium -> 34:51:47
```sql
SELECT
       priority,
       AVG(resolution_time - created_time) AS avg_difference
FROM  
       technical_support ts
WHERE
       status IN ('Closed','Resolved')
GROUP BY priority
ORDER BY avg_difference;
```

**3. Expected SLA to resolve against the actual resolution time (to see how much the team missed the deadline by)**
```sql
SELECT
       ticket_id,
       expected_sla_to_resolve,
       resolution_time - expected_sla_to_resolve AS overdue
FROM
       technical_support ts
WHERE
       expected_sla_to_resolve < resolution_time
ORDER BY overdue DESC;
```

**4. Ranking agents based on the number of tickets they have resolved**
* **Answer:** 1. Sheela Cutten (302), 2. Bernard Beckley (298), 3. Nicola Wane (294) ... 7. Heather Urry (155), 8. Michele Whyatt (145)
```sql
SELECT
       RANK() OVER(ORDER BY COUNT(ticket_id) DESC) AS agent_rank,
       agent_name,
       COUNT(ticket_id) AS no_of_tickets
FROM
       technical_support ts
WHERE
       status IN('Closed','Resolved')
GROUP BY agent_name;
```

**5. Agents with the highest average Survey results (handling more than 5 tickets)**
* **Answer:** Highest is Connor Danielovitch (4.07), second is Sheela Cutten (3.65). Lowest is Kristos Westoll (3.23), second lowest is Nicola Wane (3.36).
```sql
SELECT
       agent_name,
       ROUND(AVG(survey_results),2) AS avg_survey_result
FROM
       technical_support ts
GROUP BY agent_name
HAVING
       COUNT(ticket_id) > 5
ORDER BY avg_survey_result DESC;
```

**6. Which Product group has the highest percentage of "High" priority tickets?**
* **Answer:** Others (18.84%), Ready to use Software (18.12%), Custom software development (17.24%), and Training and Consulting Services (17.22%).
```sql
SELECT
       product_group,
       ROUND(
             100.0*SUM(CASE WHEN priority = 'High' THEN 1 ELSE 0 END)
             /
             COUNT(product_group)
       ,2) AS high_priority_tickets
FROM
       technical_support
GROUP BY product_group
ORDER BY high_priority_tickets DESC;
```

**7. Which specific Topic consistently gets low Survey results?**
* **Answer:** Product setup (3.4) and Training Request (3.46).
```sql
SELECT
       INITCAP(topic) AS clean_topic,
       ROUND(AVG(survey_results),2) AS avg_results
FROM
       technical_support
GROUP BY clean_topic
ORDER BY avg_results ASC;
```

**8. How many tickets are created per day?**
* **Answer:** 2023-06-21 had the most (16). 2023-05-22, 2023-10-18, 2023-08-15, and 2023-01-13 tied for second (15).
```sql
SELECT
       created_time::DATE AS days,
       COUNT(*) AS ticket_count
FROM
       technical_support
GROUP BY days
ORDER BY ticket_count DESC;
```

**9. Average tickets per day**
* **Answer:** 6.54
```sql
SELECT 
       ROUND(AVG(ticket_count),2) AS avg_ticket_per_day
FROM (
       SELECT
              created_time::DATE AS days,
              COUNT(*) AS ticket_count
       FROM
              technical_support
       GROUP BY days
);
```

**10. Find the busiest hour of day for support**
* **Answer:** 15:00 is the busiest (135 tickets), followed by 07:00 (115). 14:00 is the slowest (72), followed by 13:00 (79).
```sql
SELECT
       EXTRACT(HOUR FROM created_time) AS hours,
       COUNT(*) AS ticket_count
FROM
       technical_support
GROUP BY hours
ORDER BY ticket_count DESC;
```

**11. 7-day moving average of ticket volume**
```sql
WITH daily_volume AS (
       SELECT
             created_time::DATE AS ticket_date ,
             COUNT(*) AS daily_count
       FROM
             technical_support
       GROUP BY 1
)
SELECT
    ticket_date,
    daily_count,
    ROUND(AVG(daily_count) OVER (
       ORDER BY ticket_date
       ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_7_day
FROM daily_volume
ORDER BY ticket_date;
```

## Key Findings
* **Volume & Traffic:** A total of 2,330 tickets were logged, averaging 6.54 tickets per day. Email is the most popular support channel, responsible for 1,234 tickets.
* **Performance Timings:** The overall SLA failure rate is 33.61%, and the average resolution time is 33.2 hours. Medium priority tickets fail their SLAs most frequently (35.04%).
* **Busiest Times:** The support team gets the most tickets at 15:00 (135 tickets) and 07:00 (115 tickets). January and May were the busiest months of the year.
* **Common Issues:** "Product Setup" is the most common issue (630 tickets) and also receives the lowest average customer survey score (3.4). "Training Requests" take the longest to resolve (38.9 hours).
* **Agent Success:** Sheela Cutten resolved the highest number of tickets (302), while Connor Danielovitch earned the highest customer satisfaction score (4.07 average).