-- Project Members: Dhara Patel and Ridhima Shinde
use Weather;

ALTER TABLE AQS_Sites Add GeoLocation Geography;

UPDATE AQS_Sites
SET GeoLocation = geography::STPointFromText('POINT(' + CAST(Longitude AS VARCHAR(20)) + ' ' + 
                    CAST(Latitude AS VARCHAR(20)) + ')', 4326)
					where Latitude <> '';

DECLARE @h geography;
SET @h = geography::STGeomFromText('POINT(74.1790 40.7420)', 4326);
SELECT top 5 County_Name, City_Name, Zip_Code, (GeoLocation.STDistance(@h)) as distance
from AQS_Sites 
where Latitude <> '' and 
	City_Name <> 'Not in a city'
order by distance;
 
 Select * from aqs_sites

------------------------------------------Stored Procedure--------------------------------------------------------------------------------
IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'[dbo].[Spring2018_Calc_GEO_Distance]')
                    AND type IN ( N'P', N'PC' ) ) 
BEGIN
    DROP PROCEDURE [dbo].[Spring2018_Calc_GEO_Distance]
END
GO

Create Procedure [dbo].[Spring2018_Calc_GEO_Distance] (
	@Longitude nvarchar(255),
	@Latitude nvarchar(255),
	@State_Name nvarchar(255),
	@rows integer
)
As
Begin	
	Set Nocount On;
	Declare @home geography;
	Declare @state varchar(50); 
	Set @home = geography::STGeomFromText('POINT(' + @longitude + ' ' + @Latitude + ')', 4326);
	Set @state = @State_Name;

	SELECT top (@rows) Site_Number,
	case when Local_Site_name='' then Site_Number+' '+City_Name
	ELSE Local_Site_Name END AS local_site_name,
	Address, City_Name, State_Name, Zip_Code, GeoLocation.STDistance(@home) as Distance, 
	Latitude, Longitude,(GeoLocation.STDistance(@home))/80000 as Hours_Of_Travel
	from AQS_Sites 
	where Latitude <> '' and
		State_Name = @state and
		City_Name <> 'Not in a city'
	order by Distance;
End

exec Spring2018_Calc_GEO_Distance @longitude = '-99.05518229', @LATITUDE = '31.31505573', @State_Name = 'Texas', @rows = 20
exec Spring2018_Calc_GEO_Distance @longitude = '-75.52979524', @LATITUDE = '43.16422988', @State_Name = 'New York', @rows = 20

