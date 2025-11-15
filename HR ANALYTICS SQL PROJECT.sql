-- HR Analytics Project Questions 


-- Q.1 Average Tenure by Department
-- Calculate the average tenure (in years) for employees in each department and show the total number of active employees per department.

WITH num_days_worked AS 
(
	SELECT 
		firstname,
		startdate,
		EXTRACT(YEAR FROM startdate) start_year,
		COALESCE(exitdate, CURRENT_DATE) - startdate AS days_worked,
		departmenttype
	FROM employees_data
	WHERE employeestatus = 'Active'
	GROUP BY firstname,startdate,exitdate,departmenttype
),
num_years_worked AS 
(
	SELECT
		firstname,
		departmenttype,
		startdate,
		ROUND(days_worked::numeric/365.25,2) AS yrs_worked
	FROM num_days_worked
	WHERE start_year = 2020
	-- ORDER BY yrs_worked DESC
),
rank_years_worked AS
(
	SELECT
		firstname,
		departmenttype,
		startdate,
		yrs_worked,
		ROW_NUMBER() OVER(PARTITION BY departmenttype ORDER BY yrs_worked DESC) rank_yrs_worked
	FROM num_years_worked
)
SELECT 
	firstname,
	departmenttype,
	startdate,
	yrs_worked,
	rank_yrs_worked
FROM rank_years_worked
WHERE rank_yrs_worked <= 3;


-- Q.2 Department Employee Count by Gender
-- List each department with the number of employees broken down by gender.


SELECT
	departmenttype,
	gendercode,
	COUNT(DISTINCT employeeid) num_employees
FROM employees_data
GROUP BY departmenttype, gendercode
ORDER BY num_employees DESC;


-- Q.3 Training Participation per Employee
-- Identify employees who have attended at least one training and return their total number of trainings completed.


SELECT
	ed.firstname,
	COUNT(DISTINCT td.employeeid) num_training_completed,
	td.trainingdate
FROM employees_data ed
LEFT JOIN trainings_data td
	ON ed.employeeid = td.employeeid
GROUP BY  ed.firstname, td.trainingdate
	HAVING COUNT(DISTINCT td.employeeid) > 1
ORDER BY num_training_completed DESC;


-- Q.4 Average Engagement Score per Department
-- Calculate the average engagement score for each department using the latest survey for each employee.


WITH grp_department AS
(
	SELECT
		ed.departmenttype,
		EXTRACT(YEAR FROM TO_DATE(sd.surveydate, 'dd/MM/yyyy')) exc_year,
		ROUND(AVG(sd.engagementscore)::numeric,2) avg_engagement
	FROM employees_data ed
	INNER JOIN surveys_data sd
		ON ed.employeeid = sd.employeeid
	GROUP BY ed.departmenttype, sd.surveydate
		HAVING EXTRACT(YEAR FROM TO_DATE(sd.surveydate, 'dd/MM/yyyy')) = 2023
),
departmental_rank AS 
(
	SELECT
		departmenttype,
		exc_year,
		avg_engagement,
		ROW_NUMBER() OVER(PARTITION BY departmenttype ORDER BY avg_engagement DESC) rank_department 
	FROM grp_department
)
SELECT
	departmenttype,
	exc_year,
	avg_engagement,
	rank_department 
FROM departmental_rank 
WHERE rank_department <= 3;


-- Q.5 Top 3 Cities with Highest Satisfaction Scores
-- Determine the top three states (or cities) where employees have the highest average satisfaction score.

SELECT
	rd.country,
	ROUND(AVG(sd.satisfactionscore)::numeric,2) max_score
FROM recruitments_data rd
INNER JOIN surveys_data sd
	ON rd.applicantid = sd.employeeid
GROUP BY rd.country
ORDER BY max_score DESC
LIMIT 3;


-- Q.6 Training Effectiveness per Department
-- For each department, calculate the average performance score improvement for employees after attending trainings.

SELECT 
	ed.departmenttype,
	td.trainingtype,
	ROUND(AVG(CASE
		WHEN ed.performancescore = 'Needs Improvement' THEN 1
		WHEN ed.performancescore = 'PIP' THEN 2
		WHEN ed.performancescore = 'Fully Meets' THEN 3
		WHEN ed.performancescore = 'Exceeds' THEN 4
		ELSE 0
	END ),2) avg_performance_score
FROM employees_data ed
LEFT JOIN trainings_data td
	ON ed.employeeid = td.employeeid
GROUP BY ed.departmenttype, td.trainingtype
ORDER BY avg_performance_score DESC;


-- Q.7 Employees Without Training but High Performance
-- Identify employees who have not completed any trainings in the past year but have performance scores above 4.


WITH performance_rating AS 
(
	SELECT 
		ed.employeeid,
		ed.firstname,
		td.trainingoutcome,
		ROUND(SUM(CASE
			WHEN ed.performancescore = 'Needs Improvement' THEN 1
			WHEN ed.performancescore = 'PIP' THEN 2
			WHEN ed.performancescore = 'Fully Meets' THEN 3
			WHEN ed.performancescore = 'Exceeds' THEN 4
			ELSE 0
		END),2)  avg_performance_score
	FROM employees_data ed
	LEFT JOIN trainings_data td
		ON ed.employeeid = td.employeeid
	GROUP BY ed.firstname, ed.employeeid, td.trainingoutcome, td.trainingdate
		HAVING EXTRACT(YEAR FROM td.trainingdate) = 2023
	ORDER BY avg_performance_score DESC
	
	
)
SELECT 
	employeeid,
	firstname,
	trainingoutcome,
	avg_performance_score
FROM performance_rating
WHERE avg_performance_score >= 4
	AND 
	trainingoutcome = 'Incomplete'


-- Q8 Retention Rate by Department
-- Calculate the retention rate per department over the last two years and identify departments with below-average retention.


WITH dept_retation AS 
(
	SELECT 
		departmenttype,
		COUNT(CASE WHEN employeestatus ILIKE '%Active%' OR exitdate IS NULL THEN 1 END) num_active_customers,
		COUNT(*) num_employees
	FROM employees_data
	WHERE startdate <= CURRENT_DATE - INTERVAL '5 YEARS' --- 2023,2022
	GROUP BY departmenttype
)
SELECT
	departmenttype,
	ROUND((num_active_customers/num_employees) * 100,2) avg_pec_retation
FROM dept_retation
ORDER BY avg_pec_retation DESC;


-- Q.9 Performance vs Engagement by Supervisor
-- Rank supervisors by the average performance and engagement scores of their team members.

SELECT 
*
FROM
(
	WITH avg_performance AS
	(
		SELECT 
			ed.supervisor,
			ed.performancescore,
			ROUND(AVG(
			CASE 
				WHEN ed.performancescore ILIKE 'Fully Meets' THEN sd.engagementscore
				WHEN ed.performancescore ILIKE 'Exceeds' THEN sd.engagementscore
				WHEN ed.performancescore ILIKE 'Needs Improvement' THEN sd.engagementscore
				WHEN ed.performancescore ILIKE 'PIP' THEN sd.engagementscore
			END),2) avg_performance_score
		FROM employees_data ed
		LEFT JOIN surveys_data sd
			ON ed.employeeid = sd.employeeid
		GROUP BY ed.supervisor, ed.performancescore
	)
	SELECT 
		supervisor,
		performancescore,
		avg_performance_score,
		DENSE_RANK() OVER(PARTITION BY performancescore ORDER BY avg_performance_score DESC) rank_supervisor 
	FROM avg_performance
	
)
WHERE rank_supervisor <=3;


-- Q.10 Experience vs Performance Analysis
-- Group employees by years of experience (0–3, 4–7, 8–12, 13+) and calculate the average performance and satisfaction scores for each group.


SELECT 
*
FROM
(
	WITH yrs_experience AS
	(
		SELECT 
			ed.firstname,
			ed.lastname,
			rd.yearsofexperience,
			CASE 
				WHEN rd.yearsofexperience BETWEEN 0 AND 3 THEN 'Junior'
				WHEN rd.yearsofexperience BETWEEN 4 AND 7 THEN 'Associate'
				WHEN rd.yearsofexperience BETWEEN 8 AND 12 THEN 'Senior'
				WHEN rd.yearsofexperience >= 13 THEN 'Manager'
			END AS years_experience 
		FROM recruitments_data rd
		INNER JOIN employees_data ed
			ON rd.applicantid = ed.employeeid
		GROUP BY ed.firstname, ed.lastname, rd.yearsofexperience
	), 
	employee_performance AS
	(
		SELECT
		ed.firstname,
		ROUND(AVG(sd.satisfactionscore),2) avg_satisfaction_score,
		ed.performancescore,
		ROUND(AVG(CASE 
			WHEN ed.performancescore ILIKE 'Fully Meets' THEN sd.engagementscore
			WHEN ed.performancescore ILIKE 'Exceeds' THEN sd.engagementscore
			WHEN ed.performancescore ILIKE 'Needs Improvement' THEN sd.engagementscore
			WHEN ed.performancescore ILIKE 'PIP' THEN sd.engagementscore
		END),2) avg_performance
		FROM employees_data ed
		LEFT JOIN surveys_data sd
			ON ed.employeeid = sd.employeeid
		GROUP BY ed.performancescore, ed.firstname
	)
	SELECT
		yrs.firstname,
		yrs.lastname,
		yrs.yearsofexperience,
		yrs.years_experience,
		perf.avg_satisfaction_score,
		perf.performancescore,
		perf.avg_performance,
		ROW_NUMBER() OVER(
			PARTITION BY yrs.years_experience
			ORDER BY perf.avg_performance DESC) rank_performance
	FROM yrs_experience yrs
	INNER JOIN employee_performance perf
		ON yrs.firstname = perf.firstname
)
WHERE rank_performance <= 5;


-- Q.11 Top Performing Employees by Department
-- Determine the top 5 employees in each department based on overall performance rating, considering only those with at least two years of tenure.

SELECT 
*
FROM
(
	WITH employee_performance AS 
	(
		SELECT
			firstname,
			lastname,
			departmenttype,
			performancescore,
			SUM(CASE 
				WHEN performancescore ILIKE 'Fully Meets' THEN currentemployeerating
				WHEN performancescore ILIKE 'Exceeds' THEN currentemployeerating
				WHEN performancescore ILIKE 'Needs Improvement' THEN currentemployeerating
				WHEN performancescore ILIKE 'PIP' THEN currentemployeerating
			END) performance_rating,
			ROUND(EXTRACT(YEAR FROM AGE(COALESCE(exitdate, CURRENT_DATE), startdate))
			+
			(EXTRACT(MONTH FROM AGE(COALESCE(exitdate, CURRENT_DATE), startdate))/ 12.0),2) tenure_years
		FROM employees_data
		GROUP BY departmenttype, firstname, lastname, exitdate, startdate,performancescore
	)
	SELECT 
		firstname,
		lastname,
		departmenttype,
		performancescore,
		performance_rating,
		tenure_years,
		DENSE_RANK() OVER(PARTITION BY performancescore ORDER BY tenure_years DESC) rank_performance_rating
	FROM employee_performance
	WHERE tenure_years >= 2
)
WHERE rank_performance_rating <= 5;

-- Q.12 Gender Pay Gap Analysis
-- Analyze the average pay (or pay zone proxy) between genders within each department and job title, ranking the largest gaps first.

WITH pay_zones_score AS
(
	SELECT 
		title,
		payzone,
		CASE
			WHEN payzone ILIKE 'Zone A' THEN 1
			WHEN payzone ILIKE 'Zone B' THEN 2
			WHEN payzone ILIKE 'Zone C' THEN 3
		END AS pay_zones,
		departmenttype,
		gendercode
	FROM employees_data
	WHERE gendercode IS NOT NULL
)
SELECT
	title,
	departmenttype,
	gendercode,
	ROUND(AVG(pay_zones),2) avg_pay_zones,
	ROW_NUMBER() OVER(PARTITION BY  title, departmenttype ORDER BY AVG(pay_zones) desc) rank_payzone
FROM pay_zones_score
GROUP BY title, departmenttype, gendercode;


-- Q.13 Comprehensive Workforce Health Dashboard
-- Generate a summary table per department including total employees, average age, average tenure, average engagement, average satisfaction, retention rate, and gender ratio.

SELECT
*
FROM
(
	WITH workforce_summary AS
	(
		SELECT
			ed.firstname,
			ed.lastname,
			ed.departmenttype,
			EXTRACT(YEAR FROM AGE(CURRENT_DATE, TO_DATE(ed.dob, 'DD/MM/YYYY'))) age_employee,
			ROUND(AVG(EXTRACT(YEAR FROM AGE(COALESCE(ed.exitdate, CURRENT_DATE), ed.startdate))
				+
				(EXTRACT(MONTH FROM AGE(COALESCE(ed.exitdate, CURRENT_DATE), ed.startdate))/ 12.0)),2) tenure_years,
			ROUND(AVG(sd.engagementscore),2) avg_engagement,
			ROUND(AVG(sd.satisfactionscore),2) avg_satisfaction,
			ed.gendercode
		FROM employees_data ed
		LEFT JOIN trainings_data td
			ON ed.employeeid = td.employeeid
		LEFT JOIN surveys_data sd
			ON ed.employeeid = sd.employeeid
		GROUP BY ed.departmenttype,ed.firstname, ed.lastname, ed.gendercode, ed.dob
	),
	employee_retention_rate AS
	(
	-- Retention rate = still_employeed/total_employees
		SELECT
			firstname,
			ROUND(COUNT(CASE WHEN exitdate IS NULL THEN 1 END)::decimal/COUNT(*)::decimal * 100,2) retention_rate
		FROM employees_data
		GROUP BY firstname, exitdate
			HAVING ROUND(
				COUNT(CASE WHEN exitdate IS NULL THEN 1 END)::decimal/COUNT(*)::decimal * 100
			,2) > 0
	)
	SELECT
		ws.firstname,
		ws.lastname,
		ws.departmenttype,
		ws.age_employee,
		ws.tenure_years,
		ws.avg_engagement,
		ws.avg_satisfaction,
		COALESCE(err.retention_rate,0) pec_retention_rate,
		ROW_NUMBER() OVER(
			PARTITION BY ws.departmenttype 
			ORDER BY ws.tenure_years DESC, 
				ws.avg_engagement DESC, 
				ws.avg_satisfaction DESC) rank_employees_dept
	FROM workforce_summary ws
	LEFT JOIN employee_retention_rate err
		ON ws.firstname = err.firstname
)
WHERE rank_employees_dept <= 5
