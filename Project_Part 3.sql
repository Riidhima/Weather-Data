--Project Members: Dhara Patel and Ridhima Shinde

use Weather;

DECLARE @WKT AS VARCHAR(8000);
SET @WKT =
  STUFF(
    (SELECT ',' + CAST( TD.[Day of the Year] AS VARCHAR(30) ) + ' ' + CAST(AVG(TD.Average_Temp) AS VARCHAR(30) )
	
    FROM  
	(select DATEPART(DY, t.Date_Local) as 'Day of the Year', AVG(t.Average_Temp) as Average_Temp
			From Temperature t, AQS_Sites a Where a.State_Code = t.State_Code and 
			a.County_Code = t.County_Code and a.Site_Number = t.Site_Num and a.City_Name IN ('Tucson')
			 Group by  DATEPART(DY,t.Date_Local)
			 
			 UNION

			 select DATEPART(DY, t1.Date_Local) as 'Day of the Year', AVG(t1.Average_Temp) as Average_Temp
			From Temperature t1, AQS_Sites a1 Where a1.State_Code = t1.State_Code and 
			a1.County_Code = t1.County_Code and a1.Site_Number = t1.Site_Num and a1.City_Name IN ('Tucson')
			 Group by  DATEPART(DY,t1.Date_Local)

			 )TD 
	GROUP BY TD.[Day of the Year]
	ORDER BY TD.[Day of the Year]

	 FOR XML PATH('')), 1, 1, '');

SELECT geometry::STGeomFromText( 'LINESTRING(' + @WKT + ')', 0 );
