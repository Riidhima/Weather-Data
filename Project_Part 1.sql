-- Project Members: Dhara Patel and Ridhima Shinde
use Weather

-- Altering the coloumns to not null so that they can be added as primary keys

ALTER TABLE AQS_Sites
ALTER COLUMN State_Code VARCHAR(50) NOT NULL
ALTER TABLE AQS_Sites
ALTER COLUMN County_Code VARCHAR(50) NOT NULL
ALTER TABLE AQS_Sites
ALTER COLUMN Site_Number VARCHAR(50) NOT NULL

--Adding primary key

ALTER TABLE AQS_Sites
ADD PRIMARY KEY (State_Code,County_Code,Site_Number)

--Altering columns to not null for adding foreign key

ALTER TABLE Temperature
ALTER COLUMN State_Code VARCHAR(50) NOT NULL
ALTER TABLE Temperature
ALTER COLUMN County_Code VARCHAR(50) NOT NULL
ALTER TABLE Temperature
ALTER COLUMN Site_Num VARCHAR(50) NOT NULL
ALTER TABLE Temperature
ALTER COLUMN Date_Local datetime NOT NULL

--Altering Date_Local field to date from datetime so that time doesnot show.

alter table temperature 
alter column Date_Local date null

select * from Temperature

--Adding foreign keys

ALTER TABLE Temperature
ADD FOREIGN KEY (State_Code,County_Code,Site_Num) REFERENCES AQS_Sites(State_Code,County_Code,Site_Number)

--Part 3 Problems--

--1. Determine the date range of the records in the Temperature table--

SELECT FORMAT(MIN(Date_Local),'yyyy-MM-dd') AS 'First_Date', FORMAT(MAX(Date_Local),'yyyy-MM-dd') AS 'Last_Date' FROM Temperature

-- Que 2.	Find the minimum, maximum and average temperature for each state--

Begin
SELECT State_Name, MIN(Average_Temp) AS 'MIN_TEMP', MAX(Average_Temp) AS 'MAX_TEMP', AVG(Average_Temp) AS 'AVG_TEMP' 
FROM Temperature T, AQS_Sites A
WHERE T.State_Code=A.State_Code AND
T.County_Code=A.County_Code AND
T.Site_Num=A.Site_Number
GROUP BY State_Name
ORDER BY State_Name
end

-- Que 3.  The results from question #2 show issues with the database.  
-- Obviously, a temperature of -99 degrees Fahrenheit in Arizona is not an accurate reading as most likely is 135.5 degrees.  --
-- Write the queries to find all suspect temperatures (below -39o and above 105o). 
-- Sort your output by State Name and Average Temperature.--

SELECT A.State_Name,A.State_Code,A.County_Code,A.Site_Number,MIN(Average_Temp) AS Average_TEMP, FORMAT(MAX(Date_Local),'yyyy-MM-dd') AS 'DATE_LOCAL'
FROM AQS_Sites A, Temperature T
WHERE T.State_Code=A.State_Code AND
T.County_Code=A.County_Code AND
T.Site_Num=A.Site_Number
GROUP BY A.State_Name,A.State_Code,A.County_Code,A.Site_Number, Average_Temp, Date_Local
HAVING (Average_Temp <-39 OR Average_Temp > 105)
ORDER BY State_Name DESC, Average_Temp

-- Que 4.	You noticed that the average temperatures become questionable below -39 o and above 125 o and 
--		that it is unreasonable to have temperatures over 105 o for state codes 30, 29, 37, 26, 18, 38. 
--		Write the queries that remove the questionable entries for these 3 set of circumstances.

Delete From Temperature Where Average_Temp < -39 OR
			Average_Temp > 125

Delete From Temperature Where Average_Temp > 105 AND
			State_Code IN (30, 29, 37, 26, 18, 38)

-- Que 5. Using the SQL RANK statement, rank the states by Average Temperature

SELECT State_Name,MIN(Average_Temp) AS 'MINIMUM TEMP',
			MAX(ABS(Average_Temp)) AS 'Maximum TEMP', AVG(Average_Temp) AS 'AVG_Temp',
			RANK() OVER(order BY avg(Average_Temp) DESC) AS STATE_RANK
			FROM AQS_Sites A, Temperature T
	WHERE T.State_Code=A.State_Code AND
	T.County_Code=A.County_Code AND
	T.Site_Num=A.Site_Number
	GROUP BY State_Name





-- Que 6.	You decide that you are only interested in living in the United States, not Canada or the US 
--	territories. You will need to include SQL statements in all the remaining queries to limit the data 
--	returned in the remaining queries.

--	(Puerto Rico, Virgin Islands, Country of Mexico) has to be left out
--	Where State_Code <> 72, 78, 80 




--7--You remember from your statistics classes that to get a smoother distribution of the 
--	temperatures and eliminate the small daily changes that you should use a moving average instead of 
--	the actual temperatures. Using the windowing within a ranking function to create a 4 day moving 
--	average, calculate the moving average for each day of the year. 

CREATE INDEX idx_AvgTemp
ON Temperature(Average_Temp);

CREATE INDEX idx_DailyHighTemp
ON Temperature(Daily_High_Temp);

CREATE INDEX idx_date
ON Temperature(Date_Local);

CREATE INDEX idx_primarykeys
on Temperature(State_Code,County_Code,Site_Num);

CREATE INDEX idx_primarykeys_aqs_sites
on AQS_Sites(State_Code,County_Code,Site_Number);

--To see if the indexing help, add print statements that write the start and stop time for the query in 
--question #2 and run the query before and after the indexes are created. Note the differences in the 
--times. Also make sure that the create index steps include a check to see if the index exists before 
--trying to create it.
--The following is a sample of the output that should appear in the messages tab that you will need to 
--calculate the difference in execution times before and after the indexes are created

Print 'Begin Question 2 after Index Create At - ' + 
		(CAST(convert(varchar,getdate(),108) AS nvarchar(30)))
Select ta.State_Name, MIN(ta.Average_Temp) as 'Minimum Temp', 
		MAX(ta.Average_Temp) as 'Maximum Temp', AVG(ta.Average_Temp) as 'Average Temp' 
	From (Select a.State_Name, a.State_Code, a.County_Code, a.Site_Number, t.Average_Temp, t.Daily_High_Temp
		From Temperature t, AQS_Sites a
		Where a.State_Code = t.State_Code and
		a.County_Code = t.County_Code and
		a.Site_Number = t.Site_Num) ta
		Group by ta.State_Name
		Order by ta.State_Name
	Print 'Complete Question 2 after Index Create At - ' + 
		(CAST(convert(varchar,getdate(),108) AS nvarchar(30)))

--8--- You’ve decided that you want to see the ranking of each high temperatures for each city in each 
--	state to see if that helps you decide where to live. Write a query that ranks (using the rank 
--	function) the states by averages temperature and then ranks the cities in each state. The ranking 
--	of the cities should restart at 1 when the query returns a new state. You also want to only show 
--	results for the 15 states with the highest average temperatures.

with ranktable as 
	(select T.State_Code, T.State_rank, Temperature.County_Code,Temperature.Site_Num, 
		avg(Temperature.Average_Temp) as avg_temperature, dense_rank() over(partition by T.state_rank order by avg(Temperature.average_temp) desc) as State_city_rank  
	from Temperature ,
	(select top 15 State_code, avg(Average_temp) as avg_temp, DENSE_RANK() over( order by avg(Average_temp) desc) as State_rank 
	from Temperature where state_code <= 56 group by state_code) T 
	where Temperature.State_Code = T.State_Code  
	group by  Site_Num,County_Code , T.state_code, T.state_rank) 

select distinct ranktable.State_rank, aqs_sites.State_Name, ranktable.State_city_rank, aqs_sites.City_Name, ranktable.avg_temperature 
	from ranktable left join aqs_sites on ranktable.State_Code = aqs_sites.State_Code and 
	ranktable.County_Code = aqs_sites.County_Code and 
	ranktable.Site_Num = aqs_sites.Site_Number 
	order by State_rank, State_city_rank

-- Que 9. You notice in the results that sites with Not in a City as the City Name are include but do not provide 
--you useful information. Exclude these sites from all future answers. 
                                     
if OBJECT_ID(N'dbo.[NotCity]',N'V') is not null
begin
drop view NotCity
end
go
Create view NotCity as	
	(select County_Code+','+Site_Number as CScode 
	from aqs_sites 
	where city_name like '%not in a city%');


 -- Que 10. You’ve decided that the results in #8 provided too much information and you only want to 
--	2 cities with the highest temperatures and group the results by state rank then city rank. 

with ranktable as 
	(select  T.State_Code, T.State_rank, Temperature.County_Code,Temperature.Site_Num, avg(Temperature.Average_Temp) as avg_temperature, 
		DENSE_RANK() over (partition by T.state_rank order by avg(Temperature.average_temp) desc) as State_city_rank  
	from Temperature ,
	(select top 15 State_code, avg(Average_temp) as avg_temp, DENSE_RANK() over( order by avg(Average_temp) desc) as State_rank 
	from Temperature where state_code <= 56 
	group by state_code) T 
	where Temperature.State_Code = T.State_Code  and (Temperature.County_Code+','+Temperature.Site_Num) 
	not in (select CScode from NotCity) 
	group by  Site_Num,County_Code , T.state_code, T.state_rank) 

select distinct ranktable.State_rank, aqs_sites.State_Name, ranktable.State_city_rank, aqs_sites.City_Name, ranktable.avg_temperature 
	from ranktable left join aqs_sites 
	on ranktable.State_Code = aqs_sites.State_Code and 
	ranktable.County_Code = aqs_sites.County_Code and 
	ranktable.Site_Num = aqs_sites.Site_Number  
		where State_city_rank <= 2
		group by State_rank,State_city_rank,State_Name,City_Name,avg_temperature 
		order by State_rank, State_city_rank                                                       


-- Que 11. You decide you like the average temperature to be in the 80's' so you decide to research 
--	Pinellas Park, Mission, and Tucson in more detail. For Ludlow, California, calculate the average 
--	temperature by month. You also decide to include a count of the number of records for each of the 
--	cities to make sure your comparisons are being made with comparable data for each city.

Select a.City_Name, DATEPART(MONTH,Date_Local) as Month, COUNT(*) as 'Num of Records', 
AVG(t.Average_Temp) as Average_Temp
From Temperature t, AQS_Sites a
Where a.State_Code = t.State_Code and 
	a.County_Code = t.County_Code and
	a.Site_Number = t.Site_Num and
	a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson', 'Ludlow') and
	a.State_Name IN ('Florida', 'Texas', 'Arizona', 'California')
Group by a.City_Name, DATEPART(MONTH,Date_Local)
Order by a.City_Name, DATEPART(MONTH,Date_Local)

-- Que 12- You assume that the temperatures follow a normal distribution and that the majority of the 
--	temperatures will fall within the 40% to 60% range of the cumulative distribution. Using the 
--	CUME_DIST function, show the temperatures for the same 3 cities that fall within the range.

Select *
From	(Select distinct a.City_Name, t.Average_Temp, 
			CUME_DIST() Over (Partition by a.City_Name Order by t.Average_Temp) as Temp_Cume_Dist
			From Temperature t, AQS_Sites a
			Where a.State_Code = t.State_Code and 
				a.County_Code = t.County_Code and
				a.Site_Number = t.Site_Num and
				a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and
				a.State_Name IN ('Florida', 'Texas', 'Arizona')) TCum
Where TCum.Temp_Cume_Dist between 0.4 and 0.6

-- Que 13.You decide this is helpful, but too much information. You decide to write a query that shows 
--	the first temperature and the last temperature that fall within the 40% and 60% range for the 
--	3 cities your focusing on.

select DISTINCT City_Name, PERCENTILE_DISC(0.4) WITHIN GROUP (ORDER BY AVERAGE_TEMP) OVER (PARTITION BY CITY_NAME) AS '40 PERCENTILE TEMP',
		PERCENTILE_DISC(0.6) WITHIN GROUP (ORDER BY AVERAGE_TEMP) OVER (PARTITION BY CITY_NAME) AS '60 PERCENTILE TEMP'
			from AQS_Sites A,Temperature T WHERE City_Name IN ('Pinellas Park', 'Mission', 'Tucson')
			AND A.County_Code=T.County_Code AND A.State_Code=T.State_Code AND 
A.Site_Number=T.Site_Num
ORDER BY City_Name

-- Que 14. You decide you want more detail regarding the temperature ranges and you think of using the 
--	NTILE function to group the temperatures into 10 groups. You write a query that shows the minimum 
--	and maximum temperature in each of the ntiles by city for the 3 cities you are focusing on.

Select tt.City_Name, tt.Percentile, MIN(tt.Average_Temp) as MIN_Temp, MAX(tt.Average_Temp) as MAX_Temp
		From(Select a.City_Name, t.Average_Temp, NTILE(10) Over (Partition by a.City_Name Order by t.Average_Temp) as Percentile
			From Temperature t, AQS_Sites a
			Where a.State_Code = t.State_Code and 
				a.County_Code = t.County_Code and
				a.Site_Number = t.Site_Num and
				a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and
				a.State_Name IN ('Florida', 'Texas', 'Arizona')) tt
		Group by tt.City_Name, tt.Percentile


-- Que 15. You now want to see the percent of the time that will be at a given average temperature. 
--To make the percentages meaningful, you only want to use the whole number portion of the average temperature. 
--You write a query that uses the percent_rank function to create a table of each temperature for each of the 3 cities sorted by percent_rank. 
--The percent_rank needs to be formatted as a percentage with 2 decimal places.

Select tt.City_Name, tt.Average_Temp,
	FORMAT(PERCENT_RANK() Over (Partition by tt.City_Name Order by tt.Average_Temp), 'P') as 'Percentage'
	From (Select distinct a.City_Name, CAST(t.Average_Temp as INT) as Average_Temp
		From Temperature t, AQS_Sites a
		Where a.State_Code = t.State_Code and 
			a.County_Code = t.County_Code and
			a.Site_Number = t.Site_Num and
			a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and
			a.State_Name IN ('Florida', 'Texas', 'Arizona')) tt

-- Que 16. You remember from your statistics classes that to get a smoother distribution of the 
--	temperatures and eliminate the small daily changes that you should use a moving average instead of 
--	the actual temperatures. Using the windowing within a ranking function to create a 4 day moving 
--	average, calculate the moving average for each day of the year. 

Select TDay.City_Name, TDay.[Day of the Year], 
	AVG(TDay.Average_Temp) Over (Partition by TDay.City_Name Order by TDay.[Day of the Year] 
			ROWS BETWEEN 3 Preceding AND 1 following) as Rolling_Avg_Temp
		From(Select distinct a.City_Name, DATEPART(DY, t.Date_Local) as 'Day of the Year', AVG(t.Average_Temp) as Average_Temp
			From Temperature t, AQS_Sites a
			Where a.State_Code = t.State_Code and 
				a.County_Code = t.County_Code and
				a.Site_Number = t.Site_Num and
				a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and
				a.State_Name IN ('Florida', 'Texas', 'Arizona')	
			Group by a.City_Name, DATEPART(DY,t.Date_Local)) TDay
                                                      














