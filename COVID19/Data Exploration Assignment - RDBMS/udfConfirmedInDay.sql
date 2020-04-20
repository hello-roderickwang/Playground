SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udfConfirmedInDay] (
    @selectDate Date
)
RETURNS TABLE
AS
RETURN
	select 	
	tmp.ConfirmedRange,
	count(*) as Countries,
	count(*) * 100.0 / sum(count(*)) over () as CountPercent
	from(
		select 
			case when o.ConfirmedCases < 1000 then '0-1000'
				when o.ConfirmedCases >= 1000 and o.ConfirmedCases < 5000 then '1000-5000'
				when o.ConfirmedCases >= 5000 and o.ConfirmedCases < 10000 then '5000-10000'
				when o.ConfirmedCases >= 10000 then '>= 10000'
			end as ConfirmedRange
		from (
			select 
				o.Country_Region,
				sum(o.ConfirmedCases) as ConfirmedCases,
				sum(o.Fatalities) as Fatalities
			from [dbo].[origin] o
			where o.Date = @selectDate
			group by o.Country_Region
		) o
	) tmp
	group by tmp.ConfirmedRange
GO
