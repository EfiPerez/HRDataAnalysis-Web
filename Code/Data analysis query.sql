SELECT *
FROM basic_info



/* 1- 
Check the pay difference between mails and femails with possition group

SELECT sex, position, AVG(cast([pay rate] as decimal)) AS AVG_salary, count(*) AS Number_of_employees 
FROM basic_info
WHERE Pay_range_status IS NOT NULL
GROUP BY Sex, Position



----------------------------------------------------------------------------------------------------------------------
*/
/* 2- 
Check if there is a correlation between age and pay

SELECT age, AVG(cast([pay rate] as decimal)) AS AVG_salary, count(*) AS Number_of_employees 
FROM basic_info
WHERE Pay_range_status IS NOT NULL
GROUP BY age
----------------------------------------------------------------------------------------------------------------------
*/
/* 3- 
Check the pay difference among martial status
SELECT MaritalDesc, AVG(cast([pay rate] as decimal)) AS AVG_salary, count(*) AS Number_of_employees 
FROM basic_info
WHERE Pay_range_status IS NOT NULL
GROUP BY MaritalDesc
----------------------------------------------------------------------------------------------------------------------
*/


/* 4- 
Check the pay difference between mails and femails without possition group

SELECT sex, AVG(cast([pay rate] as decimal))
FROM basic_info
WHERE Pay_range_status IS NOT NULL
GROUP BY Sex

The reason for the difference between mails and femails salary is that most of the high salary positions are held by mails.
----------------------------------------------------------------------------------------------------------------------

*/
/* 5- 
check the histogram of payment acccording to pay range policy

SELECT Pay_range_status, COUNT(*) as number_of_employees
FROM basic_info
WHERE Pay_range_status IS NOT NULL
GROUP BY Pay_range_status

25 out of 229 (10%) are out of the pay range
----------------------------------------------------------------------------------------------------------------------
*/
/* 6-
this query is to check if there is aproblem with the company not enforcing her pay range

SELECT Pay_range_status, [Employment Status], [Reason For Term],COUNT(*) AS Number_of_employees
FROM basic_info
WHERE Pay_range_status IS NOT NULL AND [Employment Status] NOT IN ('Active','Future start', 'Leave of Absence')
GROUP BY Pay_range_status, [Employment Status], [Reason For Term]

the reason "more money" for termnation doesnt apear aspecially in pay range status 1. so we cen say that the dis enforcement of the policy doesnt effect the employees under the company policy
----------------------------------------------------------------------------------------------------------------------
*/
/* 7-
This query is to check what are the main reasons for termination.
SELECT  *,
CAST( CAST (Number_of_employees AS NUMERIC (5,2))/(SELECT SUM(Number_of_employees) 
  												   FROM (SELECT  COUNT(*) AS Number_of_employees
														 FROM basic_info
														 WHERE Pay_range_status IS NOT NULL AND [Employment Status] NOT IN ('Active','Future start', 'Leave of Absence')
														 GROUP BY  [Reason For Term]
														 ) AS TEMP1
	) AS DECIMAL (10,10)
													)AS Prec_from_total 

FROM (
		SELECT  [Reason For Term], COUNT(*) AS Number_of_employees
		FROM basic_info
		WHERE Pay_range_status IS NOT NULL AND [Employment Status] NOT IN ('Active','Future start', 'Leave of Absence')
		GROUP BY  [Reason For Term]
 	 ) AS TEMP

ORDER BY Prec_from_total DESC

We can see that the first 3 reasons for leaving the company (almost 50%) are dissatisfaction from position, salary or other.
This means that we have a problem that needs to be fixed.

----------------------------------------------------------------------------------------------------------------------
*/
/* 8-
This query is to check wheather the lower pay range effects the reason for leaving the company

SELECT Pay_range_status,
[Reason For Term],
SUM	(Number_of_terminations_by_reasons)  OVER (PARTITION BY pay_range_status) AS Number_of_terminations_by_pay_range_status,
Number_of_terminations_by_reasons,
CAST (CAST( Number_of_terminations_by_reasons AS DECIMAL (5,2)) / SUM(Number_of_terminations_by_reasons)  OVER (PARTITION BY pay_range_status) AS DECIMAL (2,2)) AS percentage1
FROM
(
	SELECT Pay_range_status,
		   [Reason For Term], 
		   COUNT([Employment Status]) AS Number_of_terminations_by_reasons
	FROM basic_info
	WHERE Pay_range_status IS NOT NULL AND [Employment Status] NOT IN ('Active','Future start', 'Leave of Absence')
	GROUP BY Pay_range_status,[Reason For Term]

)AS temp_table

ORDER BY Pay_range_status

From the report we can see that in the lower pay range there isnt a significant effect of the money eventhough they are below pay range.
The intresting thing is that in the above pay range, the reason for money is more significant

----------------------------------------------------------------------------------------------------------------------
*/
/* 9-
This query provides histogram of the actual pay rate with a bin of 5

SELECT Pay_rate,
COUNT(Pay_rate)AS number_of_employees
FROM
(
	SELECT ROUND(CAST([Pay Rate] AS money)*2,-1)/2 AS Pay_rate  
	FROM HRDataset_v9
	WHERE [Employment Status]='active'
)
	AS TEMP_TABLE
GROUP BY Pay_rate 
ORDER BY Pay_rate
----------------------------------------------------------------------------------------------------------------------
*/
/* 10-
This query analyze the actual pay rate histogram and explains the reason fot the form of the histogram

SELECT Pay_rate,
	   position,
	   COUNT(Pay_rate)AS number_of_employees
FROM
(
	SELECT ROUND(CAST([Pay Rate] AS money)*2,-1)/2 AS Pay_rate  ,
		   position
	FROM HRDataset_v9
	WHERE [Employment Status]='active'
)
	AS TEMP_TABLE
GROUP BY Pay_rate ,position
ORDER BY Pay_rate ,position

We can see that the histogram bumps up in the 55 bin due to the area sales manager. there are alot of them in the company
----------------------------------------------------------------------------------------------------------------------
*/
/* 11-
SELECT H.[Employee Name],
		H.[Employee Number],
		H.sex,
		H.MaritalDesc,
		Start_date,
		H.[pay rate],
		H.Position,
		H.[Performance Score],
		CASE 
			WHEN H.[Performance Score]= 'Exceptional'		THEN 1
			WHEN H.[Performance Score]= 'Exceeds'			THEN 2
			WHEN H.[Performance Score]= 'Fully Meets'		THEN 3
			WHEN H.[Performance Score]= '90-day meets'		THEN 4
			WHEN H.[Performance Score]= 'Needs Improvement' THEN 5
		END  AS score, 
		ROW_NUMBER() OVER (PARTITION BY H.position ORDER BY H.[pay rate] DESC) AS rank_number,
		Pay_range_status
		
FROM HRDataset_v9 AS h
JOIN 
basic_info AS b
ON H.[Employee Number]=B.[Employee Number]
WHERE H.[Employment Status]='active' AND H.[Performance Score]!='N/A- too early to review' AND H.[Performance Score]!= 'PIP'AND Pay_range_status IS NOT NULL
----------------------------------------------------------------------------------------------------------------------
*/
/* 12-
This query analyze the performance score histogram and check if the histogram has normal distribution as it should have.

SELECT [Performance Score], 
		CASE 
			WHEN [Performance Score]= 'Exceptional'	  	  THEN 1
			WHEN [Performance Score]= 'Exceeds'			  THEN 2
			WHEN [Performance Score]= 'Fully Meets'		  THEN 3
			WHEN [Performance Score]= '90-day meets'	  THEN 4
			WHEN [Performance Score]= 'Needs Improvement' THEN 5
		END  AS score,
		COUNT(*) AS number_of_employees
FROM HRDataset_v9
WHERE [Employment Status]='active' AND [Performance Score] IN ('Exceptional', 'Exceeds','Fully Meets','90-day meets','Needs Improvement')
GROUP BY [Performance Score]
ORDER BY score
----------------------------------------------------------------------------------------------------------------------
*/
/* 13-
This query is to check whis recruiting sourse is the best to use. it is checked by the years of service and the amount of recruiting trough that source

SELECT  [Employee Source],
		COUNT ([Employee Source]) AS Numner_of_employees, 
		AVG(b.Years_of_service) AS Avarage_years_of_service
FROM HRDataset_v9 AS h
JOIN 
basic_info AS b
ON h.[Employee Number]=b.[Employee Number]
GROUP BY [Employee Source]
ORDER BY AVG(b.Years_of_service) DESC
----------------------------------------------------------------------------------------------------------------------
*/
/* 14-
This query is to check the score distribution of each manager 

SELECT  [Manager Name], 
		[Performance Score], 
		CASE 
			WHEN [Performance Score]= 'Exceptional'	  	  THEN 1
			WHEN [Performance Score]= 'Exceeds'			  THEN 2
			WHEN [Performance Score]= 'Fully Meets'		  THEN 3
			WHEN [Performance Score]= '90-day meets'	  THEN 4
			WHEN [Performance Score]= 'Needs Improvement' THEN 5
		END  AS performance_score,
		COUNT([Performance Score]) AS  Number_of_employees
FROM HRDataset_v9
WHERE [Performance Score]  IN ('Exceptional', 'Exceeds','Fully Meets','90-day meets','Needs Improvement')
GROUP BY [Manager Name], [Performance Score]
ORDER BY [Manager Name],
		CASE 
			WHEN [Performance Score]= 'Exceptional'	  	  THEN 1
			WHEN [Performance Score]= 'Exceeds'			  THEN 2
			WHEN [Performance Score]= 'Fully Meets'		  THEN 3
			WHEN [Performance Score]= '90-day meets'	  THEN 4
			WHEN [Performance Score]= 'Needs Improvement' THEN 5
		END  
----------------------------------------------------------------------------------------------------------------------
*/
/* 15-
This query is to check the score distribution of each department
SELECT  Department, 
		[Performance Score], 
		CASE 
			WHEN [Performance Score]= 'Exceptional'	  	  THEN 1
			WHEN [Performance Score]= 'Exceeds'			  THEN 2
			WHEN [Performance Score]= 'Fully Meets'		  THEN 3
			WHEN [Performance Score]= '90-day meets'	  THEN 4
			WHEN [Performance Score]= 'Needs Improvement' THEN 5
		END  AS performance_score,
		COUNT([Performance Score]) AS  Number_of_employees
FROM HRDataset_v9
WHERE [Performance Score]  IN ('Exceptional', 'Exceeds','Fully Meets','90-day meets','Needs Improvement')
GROUP BY Department, [Performance Score]
ORDER BY Department,
		CASE 
			WHEN [Performance Score]= 'Exceptional'	  	  THEN 1
			WHEN [Performance Score]= 'Exceeds'			  THEN 2
			WHEN [Performance Score]= 'Fully Meets'		  THEN 3
			WHEN [Performance Score]= '90-day meets'	  THEN 4
			WHEN [Performance Score]= 'Needs Improvement' THEN 5
		END  
----------------------------------------------------------------------------------------------------------------------
*/
/* 16-
This query is to check the score distribution by sex

SELECT Sex, 
		[Performance Score], 
		CASE 
			WHEN [Performance Score]= 'Exceptional'	  	  THEN 1
			WHEN [Performance Score]= 'Exceeds'			  THEN 2
			WHEN [Performance Score]= 'Fully Meets'		  THEN 3
			WHEN [Performance Score]= '90-day meets'	  THEN 4
			WHEN [Performance Score]= 'Needs Improvement' THEN 5
		END  AS performance_score,
		COUNT([Performance Score]) AS  Number_of_employees
FROM HRDataset_v9
WHERE [Performance Score]  IN ('Exceptional', 'Exceeds','Fully Meets','90-day meets','Needs Improvement')
GROUP BY Sex, [Performance Score]
ORDER BY Sex,
		CASE 
			WHEN [Performance Score]= 'Exceptional'	  	  THEN 1
			WHEN [Performance Score]= 'Exceeds'			  THEN 2
			WHEN [Performance Score]= 'Fully Meets'		  THEN 3
			WHEN [Performance Score]= '90-day meets'	  THEN 4
			WHEN [Performance Score]= 'Needs Improvement' THEN 5
		END  
----------------------------------------------------------------------------------------------------------------------
*/
/* 17-
This query is to check the effectivenes of the recruiting sources that the company uses
SELECT  H.[Employee Name],
		H.[Employee Number],
		[Days Employed]/365 AS Years_of_sevice,
		CASE 
			WHEN [Performance Score]= 'Exceptional'	  	  THEN 1
			WHEN [Performance Score]= 'Exceeds'			  THEN 2
			WHEN [Performance Score]= 'Fully Meets'		  THEN 3
			WHEN [Performance Score]= '90-day meets'	  THEN 4
			WHEN [Performance Score]= 'Needs Improvement' THEN 5
		END  AS performance_score,
		r.[Employment Source],
		r.Total as total_cost
FROM HRDataset_v9 AS h
FULL JOIN recruiting_costs AS r
ON h.[Employee Source]=r.[Employment Source] 
----------------------------------------------------------------------------------------------------------------------
*/
