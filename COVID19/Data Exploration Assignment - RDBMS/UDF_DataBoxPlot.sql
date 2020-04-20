CREATE FUNCTION dbo.DataBoxPlot (@country NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT
        MIN(source.FatalitiesDaily) AS MinValue,
        MAX(source.FatalitiesDaily) AS MaxValue,
        MAX(source.FatalitiesDaily)-MIN(source.FatalitiesDaily) AS RangeValue,
        AVG(source.FatalitiesDaily) AS MeanValue,
        MIN(source.MedianValue) AS MedianValue
    FROM
        (
            SELECT
                SUM(FatalitiesDaily) as FatalitiesDaily,
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SUM(FatalitiesDaily)) OVER () AS MedianValue
            FROM
                COVID_19_aggr
            WHERE
                Country_Region = @country
            GROUP BY
                WeekOfYear
        ) source
);
GO