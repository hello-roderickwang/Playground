SHOW DATABASES;
CREATE DATABASE COVID19;
USE COVID19;
SHOW TABLES;
CREATE TABLE covid19 (Id INT, Province_State VARCHAR(50), Country_Region VARCHAR(50),
Date DATE, ConfirmedCases INT, Fatalities INT);
SHOW TABLES;
SELECT * FROM covid19 LIMIT 5;

     

USE COVID_19_aggr;
SHOW TABLES;
CREATE TABLE COVID_19_aggr (Country_Region VARCHAR(50), WeekOfYear INT, ConfirmedDaily INT, FatalitiesDaily INT);
select * from COVID_19_aggr;


-- GROUP BY ROLLUP
SELECT Country_Region, WeekOfYear, SUM(ConfirmedDaily), SUM(FatalitiesDaily)
FROM COVID_19_aggr
GROUP BY Country_Region, WeekOfYear WITH ROLLUP


-- GROUP BY CUBE
SELECT Country_Region, WeekOfYear, SUM(ConfirmedDaily), FatalitiesDaily
FROM COVID_19_aggr
GROUP BY Country_Region, WeekOfYear WITH ROLLUP
UNION
SELECT Country_Region, WeekOfYear, ConfirmedDaily, SUM(FatalitiesDaily)
FROM COVID_19_aggr
GROUP BY Country_Region, WeekOfYear WITH ROLLUP
ORDER BY Country_Region


-- GROUPING SETS
SELECT Country_Region, NULL,
        SUM(ConfirmedDaily) sum,
        SUM(FatalitiesDaily) sum
FROM COVID_19_aggr
GROUP BY Country_Region
union All
SELECT NULL, WeekOfYear,
        SUM(ConfirmedDaily) sum,
        SUM(FatalitiesDaily) sum
FROM COVID_19_aggr
GROUP BY WeekOfYear


-- RANK
SELECT Country_Region, WeekOfYear, ConfirmedDaily,
RANK() OVER (PARTITION BY Country_Region ORDER BY ConfirmedDaily DESC)
FROM COVID_19_aggr


-- DENSE_RANK
SELECT Country_Region, WeekOfYear, ConfirmedDaily,
DENSE_RANK() OVER (PARTITION BY Country_Region ORDER BY ConfirmedDaily)
FROM COVID_19_aggr


-- PERCENT_RANK
SELECT Country_Region, WeekOfYear, ConfirmedDaily,
ROUND(PERCENT_RANK() OVER (PARTITION BY Country_Region ORDER BY ConfirmedDaily), 2)
FROM COVID_19_aggr


-- CUME_DIST
SELECT Country_Region, ConfirmedDaily,
CUME_DIST() OVER (ORDER BY ConfirmedDaily)
FROM COVID_19_aggr
GROUP BY Country_Region, WeekOfYear WITH ROLLUP
ORDER BY ConfirmedDaily DESC


-- PIVOT CONFIRMED
SELECT
  Country_Region,
  max(IF(WeekOfYear = 4, ConfirmedDaily, NULL)) AS 'WEEK 4',
  max(IF(WeekOfYear = 5, ConfirmedDaily, NULL)) AS 'WEEK 5',
  max(IF(WeekOfYear = 6, ConfirmedDaily, NULL)) AS 'WEEK 6',
  max(IF(WeekOfYear = 7, ConfirmedDaily, NULL)) AS 'WEEK 7',
  max(IF(WeekOfYear = 8, ConfirmedDaily, NULL)) AS 'WEEK 8',
  max(IF(WeekOfYear = 9, ConfirmedDaily, NULL)) AS 'WEEK 9',
  max(IF(WeekOfYear = 10, ConfirmedDaily, NULL)) AS 'WEEK 10',
  max(IF(WeekOfYear = 11, ConfirmedDaily, NULL)) AS 'WEEK 11',
  max(IF(WeekOfYear = 12, ConfirmedDaily, NULL)) AS 'WEEK 12',
  max(IF(WeekOfYear = 13, ConfirmedDaily, NULL)) AS 'WEEK 13',
  max(IF(WeekOfYear = 14, ConfirmedDaily, NULL)) AS 'WEEK 14'
FROM
  COVID_19_aggr
GROUP BY
  Country_Region
ORDER BY
  SUM(ConfirmedDaily) DESC
LIMIT 10


-- PIVOT FATALITIES
SELECT
  Country_Region,
  max(IF(WeekOfYear = 4, FatalitiesDaily, NULL)) AS 'WEEK 4',
  max(IF(WeekOfYear = 5, FatalitiesDaily, NULL)) AS 'WEEK 5',
  max(IF(WeekOfYear = 6, FatalitiesDaily, NULL)) AS 'WEEK 6',
  max(IF(WeekOfYear = 7, FatalitiesDaily, NULL)) AS 'WEEK 7',
  max(IF(WeekOfYear = 8, FatalitiesDaily, NULL)) AS 'WEEK 8',
  max(IF(WeekOfYear = 9, FatalitiesDaily, NULL)) AS 'WEEK 9',
  max(IF(WeekOfYear = 10, FatalitiesDaily, NULL)) AS 'WEEK 10',
  max(IF(WeekOfYear = 11, FatalitiesDaily, NULL)) AS 'WEEK 11',
  max(IF(WeekOfYear = 12, FatalitiesDaily, NULL)) AS 'WEEK 12',
  max(IF(WeekOfYear = 13, FatalitiesDaily, NULL)) AS 'WEEK 13',
  max(IF(WeekOfYear = 14, FatalitiesDaily, NULL)) AS 'WEEK 14'
FROM
  COVID_19_aggr
GROUP BY
  Country_Region
ORDER BY
  SUM(FatalitiesDaily) DESC
LIMIT 10