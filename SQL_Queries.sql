SELECT * FROM technical_support ts;

-- KPIs
-- Total Tickets
SELECT 
	COUNT(*) 
FROM 
	technical_support;

-- Average survey Result
SELECT
	ROUND(AVG(survey_results),2) AS average_survey_result
FROM
	technical_support;
	
-- Average resolution time (Hours) - CORRECT METHOD
SELECT 
    ROUND(AVG(EXTRACT(EPOCH FROM (resolution_time - created_time))/3600), 2) as avg_resolution_hours
FROM 
    technical_support
WHERE
    status IN ('Closed','Resolved');
   

-- Overall SLA failure rate
SELECT
	ROUND(
		100.0*SUM(CASE WHEN sla_for_resolution = 'SLA Violated' THEN 1 ELSE 0 END)
		/
		COUNT(ticket_id) 
	,2) || '%' AS overall_SLA_failure_rate
FROM 
	technical_support;



-- 1.Percentage of tickets that violated the SLA for First Response vs. Resolution.
SELECT
	ROUND(100.0*SUM(CASE WHEN SLA_for_first_response = 'SLA Violated' THEN 1 ELSE 0 END)/COUNT(ticket_id),2) || '%' AS perc_violated_first_response,
	ROUND(100.0*SUM(CASE WHEN sla_for_resolution = 'SLA Violated' THEN 1 ELSE 0 END)/COUNT(ticket_id),2) || '%' AS perc_violated_resolution
FROM
	technical_support ts;
	
-- 2.Actual time taken to resolve tickets by Priority.
SELECT
	priority,
	AVG(resolution_time- created_time) AS avg_difference
FROM	
technical_support ts
WHERE
	status IN ('Closed','Resolved')
GROUP BY priority
ORDER BY avg_difference;



-- 3.Expected SLA to resolve against the actual resolution time to see how much the team missed the deadline by.
SELECT 
	ticket_id,
	expected_sla_to_resolve,
	resolution_time - expected_sla_to_resolve AS overdue
FROM
	technical_support ts
WHERE
	expected_sla_to_resolve <  resolution_time
ORDER BY overdue DESC;


-- 4.Ranking agents based on the number of tickets they have resolved.
SELECT
	RANK() OVER(ORDER BY COUNT(ticket_id) DESC) AS agent_rank,
	agent_name,
	COUNT(ticket_id) AS no_of_tickets
FROM
	technical_support ts
WHERE
	status IN('Closed','Resolved')
GROUP BY agent_name;

-- 5.Agents with the highest average Survey results, but filtering out agents who have handled less than 5 tickets.
SELECT
	agent_name,
	ROUND(AVG(survey_results),2) AS avg_survey_result
FROM
	technical_support ts 
GROUP BY agent_name
HAVING
	COUNT(ticket_id)>5
ORDER BY avg_survey_result DESC;
	

-- 6.Which Source (Email, Chat, Phone) drives the most traffic?
SELECT
	"source",
	COUNT(*) AS traffic_count
FROM 
	technical_support
GROUP BY "source" 
ORDER BY traffic_count DESC;

-- 7.Which Product group has the highest percentage of "High" priority tickets?
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


-- 8.Which specific Topic consistently gets low Survey results?
SELECT
	INITCAP(topic) AS clean_topic,
	ROUND(AVG(survey_results),2) AS avg_results
FROM
	technical_support
GROUP BY clean_topic
ORDER BY avg_results ASC;


-- 9.How many tickets are created per day?
SELECT
	created_time::DATE AS days,
	COUNT(*) AS ticket_count
FROM
	technical_support
GROUP BY days
ORDER BY ticket_count DESC;

-- 10.AVG ticket per day
SELECT ROUND(AVG(ticket_count),2) AS avg_ticket_per_day
FROM(
SELECT
	created_time ::DATE AS days,
	COUNT(*) AS ticket_count
FROM
	technical_support
GROUP BY days
);

-- 11.Find the busiest Hour of day for support.
SELECT
	EXTRACT(HOUR FROM created_time) AS hours,
	COUNT(*) AS ticket_count
FROM
	technical_support
GROUP BY hours
ORDER BY ticket_count DESC;

-- 12.7-day moving average of ticket volume.

WITH daily_volume AS 
(
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
    -- Average of current row + the previous 6 rows
    ROUND(AVG(daily_count) OVER (
        ORDER BY ticket_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_7_day
FROM daily_Volume
ORDER BY ticket_date;
