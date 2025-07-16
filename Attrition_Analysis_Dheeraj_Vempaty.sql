/*
Check for duplicate records.
Perform high-level EDA on data quality.
Note: Age and Year of Birth (YoB) columns are not consistent.
The Age column appears reliable as it aligns with YOE values. 
*/
-- Table backup before changes
CREATE TABLE general_data_backup_may_24 AS
SELECT * FROM general_data;

-- Cleaning data: remove duplicates and non-integer EmployeeID values
SELECT * FROM general_data WHERE EmployeeID LIKE '%EOF%' OR EmployeeID LIKE '%T%'; -- 53 rows
DELETE FROM general_data WHERE EmployeeID LIKE '%EOF%' OR EmployeeID LIKE '%T%';

-- Remove duplicate EmployeeID rows, keeping the first occurrence
DELETE FROM general_data
WHERE ROWID NOT IN (
    SELECT MIN(ROWID) FROM general_data GROUP BY EmployeeID
);

-- Check for inconsistencies between Year of Birth (YoB) and Age columns
SELECT MIN(age), MAX(age) FROM general_data WHERE age <> 0;
SELECT yob, 2025 - yob AS Calculated_Age, COUNT(1) FROM general_data GROUP BY yob ORDER BY Calculated_Age;
SELECT * FROM general_data WHERE yob = 1955;
SELECT age, TotalWorkingYears, yob FROM general_data WHERE age = 19;

-- Update YoB to align with Age (assuming Age is more reliable)
UPDATE general_data
SET YoB = 2025 - Age;

-- Validate YoB updates
SELECT age, TotalWorkingYears, yob FROM general_data WHERE age = 33;
SELECT MIN(age), MAX(age) FROM general_data;

-- Attrition counts by status (Yes/No)
SELECT Attrition, COUNT(1) FROM general_data GROUP BY Attrition;

-- Overall attrition percentage
SELECT COUNT(1) AS total_HC,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(1) AS Attrition_percent
FROM general_data;
-- Average attrition rate is ~16%

-- Attrition analysis by Ethnicity
select Ethnicity, count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data
group by Ethnicity;

-- Attrition analysis by Gender
select Gender, count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data
group by Gender;

-- Attrition analysis by Business Travel Frequency
select TravelFrequency, count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data
group by TravelFrequency
order by 3 desc;

-- Attrition analysis by Distance from Home Address
select DistanceFromHomeAddress, count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data
group by DistanceFromHomeAddress
order by 3 desc;

-- Attrition analysis by grouped Distance from Home Address
SELECT 
    CASE 
        WHEN DistanceFromHomeAddress < 5 THEN '<5 km'
        WHEN DistanceFromHomeAddress BETWEEN 5 AND 10 THEN '5-10 km'
        WHEN DistanceFromHomeAddress BETWEEN 11 AND 20 THEN '11-20 km'
        ELSE '>20 km'
    END AS DistanceGroup,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Attrition_Percent
FROM general_data
GROUP BY DistanceGroup
ORDER BY Attrition_Percent DESC;

-- Attrition analysis by Generation
select Generation, count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data
group by Generation
order by 3 desc;
-- Generation Y (Millennials) show high chances to leave compared to Generation X.
-- Generation Z has the highest rate (50%), 
-- it's based on a very small sample (24 employees), so it's statistically less reliable.

-- Attrition analysis by Marital Status
select CivilStatus, count(1) total_HC,sum(case when attrition='Yes' then 1 else 0 end) Attrition_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data
group by CivilStatus
order by 4 desc;
-- Attrition is double in case of Single compared to Married employees.
-- Relative Increase= (25.53−16.2)*100/16.2 = 57%

-- Attrition analysis by years of experience
select TotalWorkingYears,YearsWithCurrManager,YearsAtCompany, count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data
group by TotalWorkingYears,YearsWithCurrManager,YearsAtCompany
order by 5 desc;

-- Employees with experience less than 2 years & reached 40 years exp are more.
select * from general_data where TotalWorkingYears='NA';
select * from general_data where age=60;
select * from general_data where TotalWorkingYears=40;

-- Newer employees or those who recently changed managers are at higher risk of attrition.
-- Employees with longer tenure at the company and stable management relationships show much lower attrition.
SELECT
    CASE 
        WHEN TotalWorkingYears < 5 THEN '<5 Years'
        WHEN TotalWorkingYears BETWEEN 5 AND 10 THEN '5-10 Years'
        WHEN TotalWorkingYears BETWEEN 11 AND 20 THEN '11-20 Years'
        ELSE '20+ Years' 
    END AS WorkingYearsGroup,
    CASE 
        WHEN YearsWithCurrManager < 2 THEN '<2 Years'
        WHEN YearsWithCurrManager BETWEEN 2 AND 5 THEN '2-5 Years'
        ELSE '>5 Years'
    END AS ManagerYearsGroup,
    CASE 
        WHEN YearsAtCompany < 3 THEN '<3 Years'
        WHEN YearsAtCompany BETWEEN 3 AND 6 THEN '3-6 Years'
        WHEN YearsAtCompany BETWEEN 7 AND 15 THEN '7-15 Years'
        ELSE '15+ Years'
    END AS CompanyYearsGroup,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Attrition_Percent
FROM general_data
GROUP BY WorkingYearsGroup, ManagerYearsGroup, CompanyYearsGroup
ORDER BY Attrition_Percent DESC;

-- Combinations of all years to find patterns
SELECT
    CASE 
        WHEN TotalWorkingYears < 5 THEN '<5 Years'
        WHEN TotalWorkingYears BETWEEN 5 AND 10 THEN '5-10 Years'
        WHEN TotalWorkingYears BETWEEN 11 AND 20 THEN '11-20 Years'
        ELSE '20+ Years' 
    END AS WorkingYearsGroup,
    CASE 
        WHEN TrainingTimesLastYear = 0 THEN '0 Trainings'
        WHEN TrainingTimesLastYear BETWEEN 1 AND 2 THEN '1-2 Trainings'
        WHEN TrainingTimesLastYear BETWEEN 3 AND 5 THEN '3-5 Trainings'
        ELSE '6+ Trainings'
    END AS TrainingGroup,
    CASE 
        WHEN YearsAtCompany < 3 THEN '<3 Years'
        WHEN YearsAtCompany BETWEEN 3 AND 6 THEN '3-6 Years'
        WHEN YearsAtCompany BETWEEN 7 AND 15 THEN '7-15 Years'
        ELSE '15+ Years'
    END AS CompanyYearsGroup,
    CASE 
        WHEN YearsSinceLastPromotion = 0 THEN '0 Years'
        WHEN YearsSinceLastPromotion BETWEEN 1 AND 3 THEN '1-3 Years'
        WHEN YearsSinceLastPromotion BETWEEN 4 AND 7 THEN '4-7 Years'
        ELSE '8+ Years'
    END AS LastPromotionGroup,
    CASE 
        WHEN YearsWithCurrManager < 2 THEN '<2 Years'
        WHEN YearsWithCurrManager BETWEEN 2 AND 5 THEN '2-5 Years'
        ELSE '>5 Years'
    END AS ManagerYearsGroup,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Attrition_Percent
FROM general_data
GROUP BY WorkingYearsGroup, TrainingGroup, CompanyYearsGroup, LastPromotionGroup, ManagerYearsGroup
HAVING COUNT(*) > 10
ORDER BY Attrition_Percent DESC;

--Human Resources department shows particularly high attrition in technician/sales roles.
--R&D roles, especially like Research Director, show significant attrition.

select Organization, JobPosition,count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data
group by Organization,JobPosition
order by 4 desc;

-- Survey Data JOIN
select EnvironmentSatisfaction,JobSatisfaction,WorkLifeBalance,count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent from general_data gnr
left JOIN employee_survey_data emp 
on emp.EmployeeID=gnr.EmployeeID
left join manager_survey_data mgr
on gnr.EmployeeID=mgr.EmployeeID
where EnvironmentSatisfaction <>'NA'
and JobSatisfaction <>'NA' and WorkLifeBalance <> 'NA'
group by 1,2,3
order by 5 desc;
-- Ignoring 'NA' rows to analyze better trend analysis.
-- Low EnvironmentSatisfaction rating for  7 out of the top 10 highest attrition segments.
-- Low WorkLifeBalance is in  6 out of the top 10 highest attrition combinations.
-- Even when other factors (like JobSatisfaction) are high, poor work-life balance consistently correlates with high attrition.
-- Attrition tends to spike when multiple low ratings appear together.
/* For example, combinations like:
EnvironmentSatisfaction = 1, JobSatisfaction = 2, WorkLifeBalance = 1 → 66.67% attrition
All three factors rated as 1 → 60.00% attrition
*/

-- Looks like Employee & Manager Survey play important role with Attrition.
-- Analyzing further on survey data -
select EnvironmentSatisfaction,JobSatisfaction,WorkLifeBalance,JobInvolvement,PerformanceRating,count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent from general_data gnr
left JOIN employee_survey_data emp 
on emp.EmployeeID=gnr.EmployeeID
left join manager_survey_data mgr
on gnr.EmployeeID=mgr.EmployeeID
where EnvironmentSatisfaction <>'NA'
and JobSatisfaction <>'NA' and WorkLifeBalance <> 'NA'
group by 1,2,3,4,5
order by 7 desc
--WorkLifeBalance = 1 shows the highest attrition rate at 31.4% — strongest signal.
-- EnvironmentSatisfaction = 1 and JobSatisfaction = 1 showing significantly higher attrition 
--than higher ratings.

-- WorkLifeBalance = 1 — Highest Attrition Rate
 SELECT 
    WorkLifeBalance,
    COUNT(*) AS Total_Employees,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS Attrition_Percent
FROM general_data g
LEFT JOIN employee_survey_data e ON g.EmployeeID = e.EmployeeID
WHERE WorkLifeBalance IS NOT NULL
GROUP BY WorkLifeBalance
ORDER BY Attrition_Percent DESC;

-- EnvironmentSatisfaction = 1 and JobSatisfaction = 1 — Elevated Attrition
SELECT 
    EnvironmentSatisfaction,
    JobSatisfaction,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Attrition_Percent
FROM general_data g
LEFT JOIN employee_survey_data e 
    ON g.EmployeeID = e.EmployeeID
WHERE EnvironmentSatisfaction <>'NA'
  AND JobSatisfaction <>'NA'
GROUP BY EnvironmentSatisfaction, JobSatisfaction
ORDER BY Attrition_Percent DESC;


WITH survey_data AS (
    SELECT 
        gnr.Attrition,
        CAST(emp.EnvironmentSatisfaction AS INTEGER) AS EnvironmentSatisfaction,
        CAST(emp.JobSatisfaction AS INTEGER) AS JobSatisfaction,
        CAST(emp.WorkLifeBalance AS INTEGER) AS WorkLifeBalance,
        CAST(mgr.JobInvolvement AS INTEGER) AS JobInvolvement,
        CAST(mgr.PerformanceRating AS INTEGER) AS PerformanceRating
    FROM general_data gnr
    LEFT JOIN employee_survey_data emp ON emp.EmployeeID = gnr.EmployeeID
    LEFT JOIN manager_survey_data mgr ON gnr.EmployeeID = mgr.EmployeeID
    WHERE gnr.Attrition IS NOT NULL
), 
agg AS (
    SELECT 'EnvironmentSatisfaction' AS Parameter, EnvironmentSatisfaction AS Level,
           COUNT(*) AS Total, 
           round(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),0) AS AttritionRate
    FROM survey_data
    WHERE EnvironmentSatisfaction IS NOT NULL
    GROUP BY EnvironmentSatisfaction
    UNION ALL
    SELECT 'JobSatisfaction', JobSatisfaction,
           COUNT(*), 
         round(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),0) AS AttritionRate
    FROM survey_data
    WHERE JobSatisfaction IS NOT NULL
    GROUP BY JobSatisfaction
    UNION ALL
    SELECT 'WorkLifeBalance', WorkLifeBalance,
           COUNT(*), 
           round(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),0) AS AttritionRate
    FROM survey_data
    WHERE WorkLifeBalance IS NOT NULL
    GROUP BY WorkLifeBalance
    UNION ALL
    SELECT 'JobInvolvement', JobInvolvement,
           COUNT(*), 
            round(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),0) AS AttritionRate
    FROM survey_data
    WHERE JobInvolvement IS NOT NULL
    GROUP BY JobInvolvement
    UNION ALL
    SELECT 'PerformanceRating', PerformanceRating,
           COUNT(*), 
            round(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),0) AS AttritionRate
    FROM survey_data
    WHERE PerformanceRating IS NOT NULL
    GROUP BY PerformanceRating
)
SELECT * FROM (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY Parameter ORDER BY AttritionRate DESC) AS rn
    FROM agg
) sub
WHERE rn <= 2
ORDER BY  AttritionRate DESC;


-- Impact by Salary components
SELECT
    CASE 
        WHEN StockOptionLevel = 0 THEN 'Level 0'
        WHEN StockOptionLevel = 1 THEN 'Level 1'
        WHEN StockOptionLevel = 2 THEN 'Level 2'
        ELSE 'Level 3+'
    END AS StockOptionGroup,
    CASE 
        WHEN MonthlySalary < 3000 THEN '<3k'
        WHEN MonthlySalary BETWEEN 3000 AND 5000 THEN '3k-5k'
        WHEN MonthlySalary BETWEEN 5001 AND 10000 THEN '5k-10k'
        ELSE '10k+'
    END AS SalaryGroup,
    CASE 
        WHEN PercentSalaryIncrease < 10 THEN '<10%'
        WHEN PercentSalaryIncrease BETWEEN 10 AND 15 THEN '10-15%'
        ELSE '>15%'
    END AS HikeGroup,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Attrition_Percent
FROM general_data
GROUP BY StockOptionGroup, SalaryGroup, HikeGroup
HAVING COUNT(*) > 10
ORDER BY Attrition_Percent DESC;

select * from survey_levels_mapping;
select distinct WorkLifeBalance from employee_survey_data; -- NA
select JobInvolvement,PerformanceRating from manager_survey_data
GROUP by 1,2

/* 
SELECT 
    mgr.PerformanceRating,JobInvolvement,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate_percent
FROM general_data gnr
INNER join manager_survey_data mgr
on gnr.EmployeeID=mgr.EmployeeID
GROUP BY 1,2
ORDER BY 1;

*/
