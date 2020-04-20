SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER FUNCTION [dbo].[getZValue] 
(
	@Country1 varchar(50),
	@Country2 varchar(50)
)
RETURNS float
AS
BEGIN
	-- Declare the return variable here
	declare @res float
	DECLARE @tmp table(Country_region varchar(50), N INT, X INT, S float)

	insert into @tmp (Country_region, N, X, S)
	(
	select 
		a.Country_Region,
		count(*) as N,
		AVG(a.FatalitiesDaily) as X,
		VAR(a.FatalitiesDaily) as S
	from (
	select * from [dbo].[COVID_19_aggr]
	where Country_Region = @Country1 or Country_Region = @Country2
	 ) a
	group by a.Country_Region
	)
	-- Add the T-SQL statements to compute the return value here
	SELECT
		@res = (a.X - b.X)/sqrt(SQUARE(a.S) / a.N + SQUARE(b.S) / b.N)
	from @tmp a, @tmp b
	where a.Country_region = @Country1 and b.Country_region = @Country2

	return @res

END
GO

