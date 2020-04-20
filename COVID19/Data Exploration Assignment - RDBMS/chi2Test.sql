SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[Chi2TwoCountry](
	@Country1 varchar(50),
	@Country2 varchar(50)
)
RETURNS @t table(freeDgree INT, chi2Value INT)
AS
begin 
-- get table
   declare @twoCountry table(Country_Region nvarchar(40), WeekOfYear INT, FatalitiesDaily INT)
   insert into @twoCountry(Country_Region, WeekOfYear, FatalitiesDaily)
   (
	select
		c.Country_Region,
		c.WeekOfYear,
		c.FatalitiesDaily
	from [dbo].[COVID_19_aggr] c
	where c.Country_Region = @Country1 or c.Country_Region = @Country2
	)
-- Compute the sum value
	declare @ConfirmedSum INT
    select @ConfirmedSum = sum(FatalitiesDaily) from @twoCountry
-- Compute the groupe sum value for later utilization
	declare @groupTable table(Country_Region nvarchar(40), WeekOfYear INT, ConfirmedWeek INT)
	insert into @groupTable(Country_Region, WeekOfYear, ConfirmedWeek) 
	(
	select
		a.Country_Region,
		a.WeekOfYear, 
		sum(a.FatalitiesDaily) as confirmedWeek
	from @twoCountry a
	group by grouping sets (a.WeekOfYear, a.Country_Region)
	)
--Compute the expectation
	declare @tmp table(N INT, E float)
	insert into @tmp (N, E)
	(
	SELECT 
		c.FatalitiesDaily,
		cast(b.confirmedWeek as float) * a.confirmedWeek / @ConfirmedSum as E
	from @groupTable a, @groupTable b, @twoCountry c
	where a.WeekOfYear = c.WeekOfYear and b.Country_Region = c.Country_Region
	)
--Compute chi2
	insert into @t (freeDgree, chi2Value)
	(
	select
		10,
		sum(square(N - E) / E)
	from @tmp
	where E <> 0
	)
	return
end
GO
