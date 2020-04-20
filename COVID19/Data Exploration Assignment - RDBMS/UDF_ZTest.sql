CREATE FUNCTION dbo.ZTest (@country NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT
        (avgC-avgF)/SQRT((varC/num)+(varF/num)) AS ZTest
    FROM
    (
        SELECT
            AVG(Confirmed) AS avgC,
            AVG(Fatalities) AS avgF,
            VAR(Confirmed) AS varC,
            VAR(Fatalities) AS varF,
            COUNT(*) AS num
        FROM
            (
                SELECT
                    SUM(ConfirmedCases) as Confirmed,
                    SUM(Fatalities) as Fatalities
                FROM
                    covid19
                WHERE
                    Country_Region = @country
                GROUP BY
                    [Date]
            ) source
    ) com
    GROUP BY avgC, avgF, varC, varF, num
);
GO