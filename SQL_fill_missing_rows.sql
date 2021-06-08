/* Table abc
	a	b	 c        d    
R1	a	b	1/1/2020    20   
R2	a	b	1/17/2020   30  
R3	a	b	1/23/2020	40      
R4	c	d	1/5/2020	10
R5	c	d	1/25/2020	20
R6	c	d	1/28/2020	30
R7	e	f	1/9/2020	10
R8	g	h	3/14/2020	20
R9	g	h	3/24/2020	10
*/

Select * from abc


Select *, datediff(dd, cast(c as date), cast(Nextdate as date)) as diff_days into #tmp from 
(
Select * , lead(c) over(partition by a, b order by cast(c as date) asc) as NextDate
from abc
) a


declare @maxcntr int = (select Max(diff_days) from #tmp)
declare @cntr int = 1


while @cntr <= @maxcntr
begin
insert into abc
Select a,b,dateadd( d, 1, cast(c as date)), d from #tmp where coalesce(diff_days,1) >1

truncate table #tmp

insert into #tmp 
Select *, datediff(dd, cast(c as date), cast(Nextdate as date)) as diff_days  from 
(
Select * , lead(c) over(partition by a, b order by cast(c as date) asc) as NextDate
from abc
) a

Select *, datediff(dd, cast(c as date), cast(Nextdate as date)) as diff_days  from 
(
Select * , lead(c) over(partition by a, b order by cast(c as date) asc) as NextDate
from abc
) a

Set @cntr = @cntr +1
end

drop table #tmp

Select * from abc order by  a,b,c



