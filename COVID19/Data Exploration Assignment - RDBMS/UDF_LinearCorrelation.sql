CREATE FUNCTION dbo.LinearCorrelation (@country NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT
        ((CF-(F*C/num))/SQRT((FF-POWER(F,2.0)/num)*(CC-POWER(C,2.0)/num))) AS PearsonCorrelation
    FROM
    (
        SELECT
            SUM(Confirmed) AS C,
            SUM(Fatalities) AS F,
            SUM(Confirmed*Confirmed) AS CC,
            SUM(Fatalities*Fatalities) AS FF,
            SUM(Confirmed*Fatalities) AS CF,
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
    GROUP BY C, F, CC, FF, CF, num
);
GO