--**************************************** DROP EXISTING DATABASE AND CREATE NEW DATA WAREHOUSE ***********************************************************************

use master

alter database StayMoreReviewsWH set single_user with rollback immediate
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'StayMoreReviewsWH')
    DROP DATABASE [StayMoreReviewsWH]

CREATE DATABASE [StayMoreReviewsWH]

use StayMoreReviewsWH



--**************************************** TABLES CREATION IN DATA WAREHOUSE ***********************************************************************


if exists (select * from sysobjects where id = object_id('StayMoreReviewsWH.dbo.DimReviewers') )
	drop table [StayMoreReviewsWH].[dbo].[DimReviewers]

CREATE TABLE DimReviewers(
	[Reviewer_Key] INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	[Reviewer_ID] INT NOT NULL,
	[Reviewer_name] NVARCHAR(50) NOT NULL -- max string was 41 characters therefore nvarchar (50) seems ok

);

if exists (select * from sysobjects where id = object_id('StayMoreReviewsWH.dbo.DimProperties') )
	drop table [StayMoreReviewsWH].[dbo].[DimProperties]

CREATE TABLE DimProperties(
	[Property_Key] INT identity(1,1) NOT NULL PRIMARY KEY,
	[Property_ID] INT NOT NULL,
	[Latitude] FLOAT NOT NULL,
	[Longitude] FLOAT NOT NULL,									 --we had a typo here on longitude before (12-12-2020)
	[Accommodates] INT NOT NULL,								 --we had a typo here on accommodates before (12-12-2020)
	[Availability_365] INT NOT NULL,
	[Has_availability] INT NOT NULL,
	[Reviews_per_month] FLOAT NOT NULL,
	[Calculated_host_listings_count] FLOAT NOT NULL,
	[Instant_bookable] INT NOT NULL,
	[Property_type] NVARCHAR(40) NOT NULL,
	[Room_type] NVARCHAR(40) NOT NULL,
	[Bedrooms] INT NOT NULL,
	[Beds] INT NOT NULL,
	[Bathrooms] FLOAT NOT NULL,									 --this is where we will transform bathroom_texts string to a float
	[Bathrooms_type] NVARCHAR(20) NOT NULL,						 -- description of type of bath (transformed by bathroom_texts)
	[Neighbourhood_cleansed] NVARCHAR(40) NOT NULL,						 --this is int by default values are 0..100
	[Number_of_reviews] INT NOT NULL,
	[Number_of_reviews_l30d] INT NOT NULL,
	[Review_scores_rating] INT NOT NULL,
	[Review_scores_accuracy] FLOAT NOT NULL,
	[Review_scores_cleanliness] FLOAT NOT NULL,
	[Review_scores_checkin] FLOAT NOT NULL,
	[Review_scores_communication] FLOAT NOT NULL,
	[Review_scores_location] FLOAT NOT NULL,
	[Review_scores_value] FLOAT NOT NULL,
	[Amenity_Count] INT NOT NULL
);


if exists (select * from sysobjects where id = object_id('StayMoreReviewsWH.dbo.DimHosts') )
	drop table StayMoreReviewsWH.[dbo].[DimHosts]

CREATE TABLE DimHosts(
	[Host_Key] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[Host_ID] INT NOT NULL,
	[Host_url] NVARCHAR(100) NOT NULL,
	[Host_name] NVARCHAR(100) NOT NULL,
	[Host_since] NVARCHAR(20) NOT NULL,
	[Host_response_time] NVARCHAR(25) NOT NULL,	--max char count was "within a few hours" with 18 chars  , 5 NULL(can convert to 'N/A') , 11,825 'N/A' values out of 16,254 rows
	[Host_response_rate] FLOAT NOT NULL,			-- values between 0 - 1 , 11,830 NULL values -> we can convert to 0
	[Host_acceptance_rate] FLOAT NOT NULL,		-- values between 0 - 1 , 7,852 NULL values -> we can convert to 'N/A'
	[Host_is_superhost] INT NOT NULL,				-- we can transform values f,t to 0,1 ---- 5 NULL values
	[Host_total_listings_count] INT NOT NULL,		-- 5 NULL values
	[Host_identity_verified] INT NOT NULL,			-- we can transform values f,t to 0,1 ---- 5 NULL values
	[Calculated_host_listings_count] INT NOT NULL
);


if exists (select * from sysobjects where id = object_id('StayMoreReviewsWH.dbo.DimDates') )
	drop table [StayMoreReviewsWH].[dbo].[DimDates]

CREATE TABLE	DimDates (
		[Date_Key] INT PRIMARY KEY NOT NULL,
		[Date] DATE not null,
		[FullDate] CHAR(10) not null, -- Date in dd-MM-yyyy format
		[DayOfMonth] VARCHAR(2) not null, -- Field will hold day number of Month
		[DayName] VARCHAR(9) not null, -- Contains name of the day, Sunday, Monday 
		[DayOfWeek] INT not null, --CHAR(1),-- First Day Monday=1 and Sunday=7
		[DayOfWeekInMonth] INT not null, --VARCHAR(2), --1st Monday or 2nd Monday in Month
		[DayOfWeekInYear] INT not null, --VARCHAR(2),
		[DayOfQuarter] INT not null, --VARCHAR(3),
		[DayOfYear] INT not null, --VARCHAR(3),
		[WeekOfMonth] INT not null, --VARCHAR(1),-- Week Number of Month 
		[WeekOfQuarter] INT not null, --VARCHAR(2), --Week Number of the Quarter
		[WeekOfYear] INT not null, --VARCHAR(2),--Week Number of the Year
		[Month] INT not null, --VARCHAR(2), --Number of the Month 1 to 12
		[MonthName] VARCHAR(9) not null,--January, February etc
		[MonthOfQuarter] INT not null, --VARCHAR(2),-- Month Number belongs to Quarter
		[Quarter] INT not null, --CHAR(1),
		[Year] INT not null, --CHAR(4),-- Year value of Date stored in Row
		[MMYYYY] CHAR(6) not null,
		[FirstDayOfMonth] DATE not null,
		[LastDayOfMonth] DATE not null,
		[FirstDayOfQuarter] DATE not null,
		[LastDayOfQuarter] DATE not null,
		[FirstDayOfYear] DATE not null,
		[LastDayOfYear] DATE not null
	);


if exists (select * from sysobjects where id = object_id('StayMoreReviewsWH.dbo.FactReviews') )
	drop table [StayMoreReviewsWH].[dbo].[FactReviews]

CREATE TABLE FactReviews(
	[Reviewer_Key] INT NOT NULL,
	[Property_Key] INT NOT NULL,
	[Date_Key] INT NOT NULL,
	[Host_Key] INT NOT NULL,
	[Comments] NVARCHAR(4000) NOT NULL --largest comment found was 6,184 characters long. Only 10 out of almost 1 million had over 4,000 (this is the limit by our DB)
	
);




--**************************************** CONSTRAINTS: PRIMARY KEYS & FOREIGN KEYS ***********************************************************************



--FactReviews Foreign Keys

alter table [StayMoreReviewsWH].[dbo].FactReviews
	add constraint Reviews_DimReviewers_Reviewer_Key_fk
		foreign key (Reviewer_Key) references [StayMoreReviewsWH].[dbo].DimReviewers(Reviewer_Key);

alter table [StayMoreReviewsWH].[dbo].FactReviews
	add constraint Reviews_Properties_Property_Key_fk
		foreign key (Property_Key) references [StayMoreReviewsWH].[dbo].DimProperties(Property_Key);

alter table [StayMoreReviewsWH].[dbo].FactReviews
	add constraint Reviews_Date_Date_ID_fk
		foreign key (Date_Key) references [StayMoreReviewsWH].[dbo].DimDates(Date_key);

alter table [StayMoreReviewsWH].[dbo].FactReviews
	add constraint Reviews_Hosts_Host_Key_fk
		foreign key (Host_Key) references [StayMoreReviewsWH].[dbo].DimHosts(Host_Key);




--**************************************** TRANSFORM & INSERT VALUES ***********************************************************************

--- DimReviewers
INSERT INTO [StayMoreReviewsWH].[dbo].[DimReviewers]( 
	[reviewer_ID],
	[reviewer_name]) 
SELECT
	[StayMore].[dbo].[DimReviewers].[Reviewer_ID],
	[StayMore].[dbo].[DimReviewers].[Reviewer_name]
FROM [StayMore].[dbo].[DimReviewers]

--DimProperties
INSERT INTO [StayMoreReviewsWH].[dbo].[DimProperties] (
	[Property_ID],
	[Latitude],
	[Longitude],			
	[Accommodates],		
	[Availability_365],
	[Has_availability],
	[Reviews_per_month],	
	[Calculated_host_listings_count],
	[Instant_bookable],
	[Property_type],
	[Room_type],
	[Bedrooms],
	[Beds],
	[Bathrooms],
	[Bathrooms_type],
	[Neighbourhood_cleansed],
	[Number_of_reviews],
	[Number_of_reviews_l30d],
	[Review_scores_rating],
	[Review_scores_accuracy],
	[Review_scores_cleanliness],
	[Review_scores_checkin],
	[Review_scores_communication],
	[Review_scores_location],
	[Review_scores_value],
	[Amenity_Count]
	)
SELECT
	[Property_ID],
	[Latitude],
	[Longitude],			
	[Accommodates],		
	[Availability_365],
	[Has_availability],
	[Reviews_per_month],	
	[Calculated_host_listings_count],
	[Instant_bookable],
	[Property_type],
	[Room_type],
	[Bedrooms],
	[Beds],
	[Bathrooms],
	[Bathrooms_type],
	[Neighbourhood_cleansed],
	[Number_of_reviews],
	[Number_of_reviews_l30d],
	[Review_scores_rating],
	[Review_scores_accuracy],
	[Review_scores_cleanliness],
	[Review_scores_checkin],
	[Review_scores_communication],
	[Review_scores_location],
	[Review_scores_value],
	[Amenity_Count]
FROM [StayMore].[dbo].[dimProperties]

--DimHosts
INSERT INTO [StayMoreReviewsWH].[dbo].[DimHosts]( 
	[Host_ID],
	[Host_url],
	[Host_name],
	[Host_since],
	[host_response_time],
	[host_response_rate],
	[host_acceptance_rate],
	[host_is_superhost],
	[host_total_listings_count],
	[host_identity_verified],
	[Calculated_host_listings_count]
	)
SELECT
	[Host_ID],
	[Host_url],
	[Host_name],
	[Host_since],
	[host_response_time],
	[host_response_rate],
	[host_acceptance_rate],
	[host_is_superhost],
	[host_total_listings_count],
	[host_identity_verified],
	[Calculated_host_listings_count]		--host_identity_verified 5 NULL values -> 0, the rest are t or f (mapped to 1 or 0)
FROM [StayMore].[dbo].[DimHosts]

------DIMDATES
INSERT INTO [StayMoreReviewsWH].[dbo].[DimDates](
		[Date_Key],
		[Date],
		[FullDate],
		[DayOfMonth],
		[DayName],
		[DayOfWeek],
		[DayOfWeekInMonth],
		[DayOfWeekInYear],
		[DayOfQuarter],
		[DayOfYear],
		[WeekOfMonth],
		[WeekOfQuarter],
		[WeekOfYear],
		[Month],
		[MonthName],
		[MonthOfQuarter],
		[Quarter],
		[Year],
		[MMYYYY],
		[FirstDayOfMonth],
		[LastDayOfMonth],
		[FirstDayOfQuarter],
		[LastDayOfQuarter],
		[FirstDayOfYear],
		[LastDayOfYear])
	SELECT 
		[Date_Key],
		[Date],
		[FullDate],
		[DayOfMonth],
		[DayName],
		[DayOfWeek],
		[DayOfWeekInMonth],
		[DayOfWeekInYear],
		[DayOfQuarter],
		[DayOfYear],
		[WeekOfMonth],
		[WeekOfQuarter],
		[WeekOfYear],
		[Month],
		[MonthName],
		[MonthOfQuarter],
		[Quarter],
		[Year],
		[MMYYYY],
		[FirstDayOfMonth],
		[LastDayOfMonth],
		[FirstDayOfQuarter],
		[LastDayOfQuarter],
		[FirstDayOfYear],
		[LastDayOfYear]
	FROM [StayMore].[dbo].[DimDates]



----Reviews

truncate table [StayMoreReviewsWH].[dbo].[FactReviews]

INSERT INTO [StayMoreReviewsWH].[dbo].[FactReviews](
		[Reviewer_Key],
		[Property_Key],
		[Date_Key],
		[Host_Key],
		[comments])
	SELECT 
		[StayMoreReviewsWH].[dbo].[DimReviewers].[Reviewer_Key],
		[StayMoreReviewsWH].[dbo].[DimProperties].[Property_Key],
		[StayMoreReviewsWH].[dbo].[DimDates].[Date_Key],
		[StayMoreReviewsWH].[dbo].[DimHosts].[Host_Key],
		[StayMore].[dbo].[FactReviews].[comments]
FROM [StayMore].[dbo].[FactReviews] 
join [StayMoreReviewsWH].[dbo].[DimReviewers]
on [StayMore].[dbo].[FactReviews].[Reviewer_Key] = [StayMoreReviewsWH].[dbo].[DimReviewers].[Reviewer_Key]
join [StayMoreReviewsWH].[dbo].[DimProperties]
on [StayMore].[dbo].[FactReviews].[Property_Key] = [StayMoreReviewsWH].[dbo].[DimProperties].[Property_Key]
join [StayMoreReviewsWH].[dbo].[DimDates]
on [StayMore].[dbo].[FactReviews].[Date_Key] = [StayMoreReviewsWH].[dbo].[DimDates].[Date_Key]
join [StayMoreReviewsWH].[dbo].[DimHosts]
on [StayMoreReviewsWH].[dbo].[DimHosts].[Host_Key] = [StayMore].[dbo].[FactReviews].[Host_Key]