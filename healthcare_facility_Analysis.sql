Create database healthcareDB;

#Checking if the table imported
SELECT * from patient_record LIMIT 10;

SELECT * from doctor_record LIMIT 10;

select * from financial_record LIMIT 10;

#Fixing Data Types 
/*rounding the decimal to 2*/
SELECT ROUND(Billing_amount, 2) AS Billing_amount
FROM financial_record;

/*changing string to date format*/
SET SQL_SAFE_UPDATES = 0;

UPDATE patient_record
SET DATE_OF_ADMISSION = STR_TO_DATE(DATE_OF_ADMISSION, '%m/%d/%Y'),
    Discharge_Date = STR_TO_DATE(Discharge_Date, '%m/%d/%Y');
    
ALTER TABLE patient_record
MODIFY COLUMN DATE_OF_ADMISSION DATE,
MODIFY COLUMN Discharge_Date DATE;

/*Analysisng the insights*/
-- Which gender visits more often
select Gender, count(*)
from patient_record            
group by gender;
 
 -- Which blood type is most common among patients?
 select Blood_type,count(*)AS Total
 from patient_record
 group by Blood_Type
 order by total  DESC;
 
 -- What are the most common medical conditions?
SELECT Medical_Condition, COUNT(*) AS total
FROM patient_record
GROUP BY Medical_Condition
ORDER BY total DESC;

 -- Monthly/Yearly admission trends (based on Date of Admission).
SELECT EXTRACT(YEAR FROM Date_of_Admission) AS Year, COUNT(*) AS total_admissions
FROM patient_record
GROUP BY Year
ORDER BY Year; 

select extract(Month from date_of_admission) AS Month,  COUNT(*) AS total_admissions
from patient_record
group by month
order by total_admissions;
 
 -- Age group analysis (Children, Adults, Seniors).
 select
 CASE 
   WHEN Age between 0 and 18 then 'children'
   WHEN Age between 18 and 50 then 'ADULTS'
   else 'Seniors'
END  AS Age_group ,count(*) AS Total
from patient_record
group by Age_group
ORDER BY Age_group;

-- Which gender contributes highest hospital income?
select Gender,SUM(Billing_amount)
from financial_Record F
join patient_record R
on F.patient_id = R.patient_id
group by Gender;

-- Which blood type group contributes highest billing?
select Blood_Type,SUM(Billing_amount)AS Invoice
from financial_Record F
join patient_record R
on F.patient_id = R.patient_id
group by Blood_Type
order by Invoice Desc;

-- Which hospital has the highest revenue and lowest revenue?
SELECT Hospital, total_revenue
FROM (
    SELECT 
        Hospital,
        SUM(Billing_amount) AS total_revenue,
        RANK() OVER (ORDER BY SUM(Billing_amount) DESC) AS rev_rank_desc,
        RANK() OVER (ORDER BY SUM(Billing_amount) ASC) AS rev_rank_asc
    FROM financial_record
    GROUP BY Hospital
) AS Invoice
WHERE rev_rank_desc = 1 OR rev_rank_asc = 1;


    
-- Which admission type (Emergency/Elective) brings highest billing?
Select Admission_Type, sum(billing_amount) AS Invoice
from Financial_record
group by Admission_Type
Limit 5;

-- Which insurance providers pay less vs more
Select Insurance_provider , total_Revenue
from(
      select Insurance_provider, 
      SUM(Billing_amount) AS total_Revenue,
      row_number() over (order by SUM(Billing_Amount) DESC) AS PAY_more,
	  row_number() over (order by SUM(Billing_Amount) Asc )AS PAY_less
      from financial_Record
      group by Insurance_provider
) AS INVOICE
where pay_less = 1 or PAY_MORE =1 ;

-- Revenue trend by month/year
Select EXTRACT(YEAR FROM Discharge_date) AS Year, SUM(Billing_amount) AS Revenue_trend
from Financial_record F
join patient_record P
on F.patient_id = p.patient_id 
group by year
order by year;


SELECT Year, Month, total_revenue
FROM (
    SELECT 
        EXTRACT(YEAR FROM Discharge_date) AS Year,
        EXTRACT(MONTH FROM Discharge_date) AS Month,
        SUM(Billing_amount) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM Discharge_date) 
                     ORDER BY SUM(Billing_amount) DESC) AS month_rank
    FROM Financial_record F
    JOIN patient_record P
        ON F.patient_id = P.patient_id
    GROUP BY Year, Month
) AS MonthlyRevenue
WHERE month_rank = 1;


--  highest number of patients per doctor
SELECT Doctor_Name, COUNT(*) AS total_patients
FROM doctor_record
GROUP BY Doctor_Name
ORDER BY total_patients DESC
LIMIT 1;

-- doctor generates the highest billing
SELECT Doctor_Name, total_billing
FROM (
    SELECT
        D.Doctor_Name, 
        SUM(F.Billing_amount) AS total_billing,
        RANK() OVER (ORDER BY SUM(F.Billing_amount) DESC) AS revenue_rank
    FROM doctor_record D
    JOIN financial_record F
        ON D.Doc_ID = F.Doc_ID
    GROUP BY D.Doctor_Name
) AS ranked_billing
WHERE revenue_rank = 1;


-- Which doctor’s patients had best/worst test results?
SELECT 
    Doctor_name,
    SUM(CASE WHEN `Test_ Results` = 'Normal' THEN 1 ELSE 0 END) AS Normal_cases,
    SUM(CASE WHEN `Test_ Results` IN ('Abnormal', 'Inconclusive') THEN 1 ELSE 0 END) AS Worst_cases
FROM doctor_record
GROUP BY Doctor_name
ORDER BY Normal_cases DESC, Worst_cases ASC;

-- Most prescribed medications overall.
SELECT Medication, COUNT(*) AS prescription_count
FROM doctor_record
GROUP BY Medication
ORDER BY prescription_count DESC
LIMIT 5;

-- Length of Stay = Discharge Date – Date of Admission
-- Average length of stay per hospital.
-- Length of stay by admission typ
select Hospital,  AVG(DATEDIFF(P.Discharge_date, P.Date_of_admission)) AS avg_length
from patient_Record P
join doctor_record D
ON P.Patient_ID = D.Patient_ID
group by hospital;

Select admission_type ,AVG(DATEDIFF(P.Discharge_date, P.Date_of_admission)) AS avg_length_stay
from financial_record F
join patient_record P
ON F.Patient_ID =  P.Patient_ID
group by Admission_Type;


-- Occupancy rate (patients per hospital, per month).
SELECT 
    F.Hospital,
    EXTRACT(YEAR FROM P.Date_of_admission) AS Year,  
    COUNT(F.Patient_ID) AS Total_Patients
FROM financial_record F
JOIN patient_record P
    ON F.Patient_ID = P.Patient_ID
GROUP BY 
    F.Hospital,
    EXTRACT(YEAR FROM P.Date_of_admission)
ORDER BY 
    Total_patients desc;
    
    -- occupancy rate without month and year
    
SELECT 
    F.Hospital,
    COUNT(distinct P.Patient_ID) AS Total_Patients
FROM financial_record F
JOIN patient_record P
    ON F.Patient_ID = P.Patient_ID
GROUP BY 
    F.Hospital
ORDER BY 
    Total_patients desc;
    
    -- Insurance vs non-insurance revenue share
    
-- Correlation between length of stay & billing amount.
Select DATEDIFF(P.Discharge_date , P.Date_of_admission) AS length_of_Stay, F.Billing_amount
from financial_record F
join patient_record P
ON F.Patient_ID = P.Patient_ID
order by length_of_stay DESC;

SELECT 
    DATEDIFF(P.Discharge_date, P.Date_of_admission) AS length_of_stay, 
    F.Billing_amount
FROM financial_record F
JOIN patient_record P
    ON F.Patient_ID = P.Patient_ID
ORDER BY length_of_stay DESC;

-- Top 10 revenue-generating patients
select p.Patient_ID, p.name, SUM(F.Billing_amount) AS high_paid
from patient_record p
join financial_record F
on p.patient_id = f.patient_id
group by p.name
order by high_paid Desc
limit 10;

-- Doctor-hospital combinations (which doctor brings most revenue to which hospital)
Select Hospital, Doctor_name, highest_billing
from( 
select
   D.Doctor_Name, 
   D.Hospital,
   Sum(F.Billing_amount) AS highest_billing,
    rank()over(partition by D.Hospital order by sum(Billing_amount) DESC) AS REVENUE_RANK
from doctor_record D
join financial_record F
on D.Doc_ID = F.Doc_ID
group by D.Hospital,D.Doctor_Name
)as topinvoice
order by highest_billing Desc
Limit 10;

-- Insurance efficiency → Compare insurance payout vs billed amount
Select Insurance_provider, SUM(Billing_amount) AS Total_paid,COUNT(DISTINCT Patient_ID) AS covered_patients,
	ROUND(SUM(Billing_amount) * 100.0 / SUM(SUM(Billing_amount)) OVER (),2) AS pct_of_total
from Financial_record
group by Insurance_provider
ORDER BY total_paid DESC;


-- Readmissions → Check if same patient admitted multiple times.
SELECT 
    P.Name,
    COUNT(P.Patient_ID) AS admission_count,
    MIN(P.Date_of_admission) AS first_admission,
    MAX(P.Date_of_admission) AS last_admission
FROM patient_record P
GROUP BY P.Name
HAVING COUNT(P.Patient_ID) > 7
ORDER BY admission_count DESC;










 


 


 






