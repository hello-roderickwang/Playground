
-- How many country region with confirmed 0-1000 1000-5000 5000-10000 >=10000

select *
from [dbo].[udfConfirmedInDay]('2020-04-03')
order by case ConfirmedRange
	when '0-1000' then 1
	when '1000-5000' then 2
	when '5000-10000' then 3
	else 4 end

--get chi2 test value between two countries
select * 
from [dbo].[Chi2TwoCountry]('Germany', 'US')
union
select * 
from [dbo].[Chi2TwoCountry]('United Kingdom', 'Spain')
union
select * 
from [dbo].[Chi2TwoCountry]('Spain', 'China')

--get Z-value for fatalities weekly in COVID_19_aggr
select [dbo].[getZValue]('US', 'Germany')