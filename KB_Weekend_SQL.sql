create table credit_purchased (dateofpurpose date, invoice_id varchar(10), partner varchar(10),credits_purchased int, amount_paid int, discount int)

create table subscriptions_sold (dateofsales date, subscription_id int, sold_by_partner varchar(10),credits_consumed int)


insert into credit_purchased values
(cast('11/01/2020' as date),'a','X',1200,1080,10),
(cast('11/10/2020' as date),'b','X',2000,1400,30),
(cast('12/02/2020' as date),'c','X',4000,3400,15),
(cast('12/21/2020' as date),'d','X',6000,3600,40),
(cast('11/06/2020' as date),'e','Y',600,420,30),
(cast('11/15/2020' as date),'f','Y',3400,3060,10),
(cast('11/29/2020' as date),'g','Y',2000,1600,20)

insert into subscriptions_sold values
(cast('11/01/2020' as date),1,'X',1000),
(cast('11/11/2020' as date),2,'X',1000),
(cast('12/03/2020' as date),3,'X',1000),
(cast('12/25/2020' as date),4,'X',2000),
(cast('12/12/2020' as date),5,'Y',1000),
(cast('12/12/2020' as date),6,'Y',1000),
(cast('12/16/2020' as date),7,'Y',2000)

-- ANSWER for 1 st part ---------------->>>> Please run below select statement

Select cp.*, credit_balac from (
Select *, rank()over (partition by dateofpurpose order by iif( trans = 's' , 1 , 0) desc) as rk from (
Select *, sum( credits_purchased)over(partition by partner order by dateofpurpose,trans rows between unbounded preceding and current row) as credit_balac from (
Select dateofpurpose,'p' as trans, partner,credits_purchased,amount_paid,discount  from credit_purchased
union
Select dateofsales, 's' as trans, sold_by_partner, -1* credits_consumed, -1* credits_consumed, 0 from subscriptions_sold)
k) l )m
join credit_purchased cp on cp.dateofpurpose = m.dateofpurpose
where rk =1 order by 2


-- For 2nd part , please create below function for revenue and run  this to get answer. Right now solution is not scalable. For Inventory we should create a Ledger and persist that data.

-- ANSWER ------------------  >>>>>>  Select *, dbo.revenue(s.subscription_id, s.sold_by_partner) from subscriptions_sold s

CREATE Function revenue( @subs int  , @part varchar(10) )
returns int
begin



declare @ledger table ( dateofpurpose date, invoice_id varchar(10), partner varchar(10),credits_purchased int, amount_paid int, discount int, available int, used int, partial int, cummvail int, usage int)
declare @templedger table ( dateofpurpose date, invoice_id varchar(10), partner varchar(10),credits_purchased int, amount_paid int, discount int,available int, used int, partial int, cummvail int, usage int)
declare @tmpsubs table (subscription_id int,credits_consumed int, rk int )

insert into @tmpsubs
Select subscription_id, credits_consumed, rank() over (order by subscription_id asc) as rk from subscriptions_sold where subscription_id <= @subs and sold_by_partner = @part

insert into @ledger 
Select *, credits_purchased,0,0,0,NULL 
from credit_purchased 

declare @cntr int  = 1
declare @amt int = 0
declare @CummulativeVolume int = 0
declare @str int = 0
declare @max_cntr int = (Select max(rk) from @tmpsubs)

insert into  @templedger
Select * from @ledger  where partner = @part

while @cntr <= @max_cntr
    begin

	set @amt = (Select credits_consumed from @tmpsubs where rk = @cntr)
	

	update l set
	--select  
	@CummulativeVolume = cummvail=	@CummulativeVolume + Available,
	
	Usage =	case
							when @CummulativeVolume < @amt then 1
							when @CummulativeVolume - Available < @amt then 0
							else null 
						end,																														
	Used = case
							when @CummulativeVolume < @amt then Available
							when @CummulativeVolume - Available < @amt then @amt - (@CummulativeVolume - Available)
							else null
						 end
	from 
	@templedger l


	

	update	L
	set		available = l.Available - tmp.Used, partial = tmp.partial
   from	@Ledger l
	join @templedger tmp on	l.dateofpurpose = tmp.dateofpurpose and l.partner = tmp.partner where tmp.used > 0

	
	if @cntr <> @max_cntr
	 Begin
	    delete from @templedger
	    insert into  @templedger
	    Select * from @Ledger  where partner = @part
	 end

	set @CummulativeVolume = 0
	set @cntr = @cntr +1
	end


set @str = (Select top 1 sum ( used * (100-discount)/100) from @templedger where used>0)


return  @str

end

