--Creating calander starting from first hire date and ending today

IF EXISTS (SELECT * FROM information_schema.tables WHERE Table_Name = 'Calendar' AND Table_Type = 'BASE TABLE')
BEGIN
DROP TABLE [Calendar]
END


CREATE TABLE [Calendar]
(
    [CalendarDate] DATE
)

DECLARE @StartDate DATE
DECLARE @EndDate DATE
SET @StartDate = ( SELECT CAST  (CONCAT( DATEPART(YYYY,CAST(MIN(Start_date) AS DATE)),'/',DATEPART(MM,CAST(MIN(Start_date) AS DATE)),'/','1') AS date)
				 FROM HRDataset_v9)
SET @EndDate = GETDATE()
WHILE @StartDate <= @EndDate
      BEGIN
             INSERT INTO [Calendar]
             (
                   CalendarDate
             )
             SELECT
                   @StartDate

             SET @StartDate = DATEADD(MM, 1, @StartDate)
      END



--Query  the active employees, hired employees and terminated employees by the calander we have created

SELECT  RIGHT(T.Date,4) AS Year,
 AVG(T.Active_Employees) AS Average_of_active_employees,
 SUM(T.Number_of_hired_employees) AS Number_of_hired_employees,
 SUM(T.Number_of_terminated_employees)AS Number_of_terminated_employees,
 CAST (SUM(T.Number_of_terminated_employees) AS decimal )/AVG(T.Active_Employees)*100  AS 'Turnover_rate_in_%'
FROM(

SELECT FORMAT(temp4.MONTH1, 'MM/yyyy', 'en-us') AS Date,
	   (CASE WHEN temp4.Active_employees IS NULL THEN 0 ELSE temp4.Active_employees END) AS Active_Employees , 
	  
	   (CASE WHEN temp3.Number_of_hired_employees IS NULL THEN 0 ELSE temp3.Number_of_hired_employees END) AS Number_of_hired_employees ,
	   (CASE WHEN temp3.Number_of_terminated_employees IS NULL THEN 0 ELSE temp3.Number_of_terminated_employees END) AS Number_of_terminated_employees,
	   (CASE WHEN temp3.Number_of_hired_employees IS NULL THEN 0 ELSE temp3.Number_of_hired_employees END) - (CASE WHEN temp3.Number_of_terminated_employees IS NULL THEN 0 ELSE temp3.Number_of_terminated_employees END) AS Total_HC_Change
FROM
(
			SELECT temp1.month2 AS month_term,
				   temp2.month2 AS month_start, 
				   Number_of_terminated_employees,
				   Number_of_hired_employees
			FROM
			(
				SELECT CAST( CONCAT(MONTH(Termination_date),'/','01/',YEAR(Termination_date))AS DATE) AS MONTH2, 
					   COUNT (*) AS Number_of_terminated_employees
				FROM HRDataset_v9
				WHERE [Employment Status] NOT IN ('Active','Future start', 'Leave of Absence','Voluntarily Terminated',' no-show"')-- Notice that there are 2 employees that has termination date but still active, this is why there is a difference for comparison to excel file
				GROUP BY CAST( CONCAT(MONTH(Termination_date),'/','01/',YEAR(Termination_date))AS DATE)
			)AS temp1

			FULL JOIN

			(
				SELECT CAST( CONCAT(MONTH(Start_date),'/','01/',YEAR(Start_date))AS DATE) AS MONTH2, 
					   COUNT (*) AS Number_of_hired_employees
				FROM HRDataset_v9
				WHERE [Employment Status] NOT IN ('Future start', 'Leave of Absence')
				GROUP BY CAST( CONCAT(MONTH(Start_date),'/','01/',YEAR(Start_date))AS DATE)
			)AS temp2
			
			ON temp1.month2=temp2.month2 
) AS temp3

RIGHT JOIN

(
			SELECT 	Calendar.CALENDARDATE AS month1,
					COUNT(*) AS Active_employees 
			FROM HRDataset_v9 AS h

			FULL JOIN Calendar

			ON  Calendar.CALENDARDATE  >=  H.Start_date
			AND (Calendar.CALENDARDATE  <=  h.Termination_date or h.Termination_date ='')
			WHERE Calendar.CALENDARDATE IS NOT NULL -- we can see that if we will not put this WHERE CLAUSE, we have 5 nulls. this is becuse there are 5 employees who joind and left on the same nonth.
			GROUP BY Calendar.CALENDARDATE
) AS temp4

ON temp4.MONTH1=temp3.month_start OR temp4.MONTH1=temp3.month_term
) AS T
GROUP BY RIGHT(T.Date,4)