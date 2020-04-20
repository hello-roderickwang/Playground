CREATE FUNCTION dbo.DataHistogram (@country NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT
        Mode,
        Variance,
        StandardVariance,
        CV
    FROM
        (
            SELECT
                VAR(ConfirmedSum) AS Variance,
                STDEV(ConfirmedSum) AS StandardVariance,
                STDEV(ConfirmedSum)/AVG(ConfirmedSum) AS CV
                -- confirmedSum
            FROM
                (
                    SELECT
                        SUM(ConfirmedCases) AS ConfirmedSum
                    FROM
                        covid19
                    WHERE
                        Country_Region = 'US'
                    GROUP BY
                        [Date]
                ) o
        ) source,
        (
            -- get mode
            SELECT
                TOP 1 ConfirmedSum AS Mode
            FROM
                (
                    SELECT
                        SUM(ConfirmedCases) AS ConfirmedSum
                    FROM
                        covid19
                    WHERE
                        Country_Region = 'US'
                    GROUP BY
                        [Date]
                ) o
            GROUP BY
                ConfirmedSum
            ORDER BY
                COUNT(*) DESC
        ) m  
);
GO