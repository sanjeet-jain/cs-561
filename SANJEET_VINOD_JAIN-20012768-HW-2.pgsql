-- 
-- CS561 – SQL Programming Assignment 2
-- Author: SANJEET VINOD JAIN
-- CWID: 20012768
-- 
select 
  CAST(
    '1.  For each customer, product, month and state combination, compute 
    1 the 
customers average sale of this product for the given month and state, 
2 the 
customers average sale for the given month and state, but for all other products 
3 the customers average sale for the given product and state, but for all other months  
and 
4 the average sale of the product and the month but for all other states. 'as varchar(1000)) as report_1;

select cust,prod,month,state,sum(quant)as s,count(quant) as c, avg(quant) as a
into  temp table temp_master
from sales
group by cust,prod,month,state
;

select 
tm.cust, 
tm.prod, 
tm.month,
tm.state,
cast (sum(tm.s)/sum(tm.c) as int) as cust_avg,
cast (sum(t1.s)/sum(t1.c) as int) as other_prod_avg,
cast (sum(t2.s)/sum(t2.c) as int) as other_month_avg,
cast (sum(t3.s)/sum(t3.c) as int) as other_state_avg
from temp_master as tm
left join temp_master as t1 
on tm.cust = t1.cust and
tm.prod <> t1.prod and
tm.month= t1.month and
tm.state= t1.state
left join temp_master as t2 
on tm.cust  = t2.cust and
tm.prod     = t2.prod and
tm.month    <>t2.month and
tm.state    = t2.state
left join temp_master as t3 
on tm.cust  = t3.cust and
tm.prod     = t3.prod and
tm.month    =t3.month and
tm.state    <> t3.state

group by tm.cust, 
tm.prod, 
tm.month,
tm.state
order by cust,prod,month,state
;
drop table temp_master;

--------------------------------------------------------------

select 
  CAST(
    '2.For customer, product and state, show the average sales before and after each month
(e.g., February (month 2), show average sales of January (month 1) and March
(month 3). For “before” January and “after” December, display <NULL>. The “YEAR” 
attribute is not considered for this query – for example, both January of 2017 and 
January of 2018 are considered January regardless of the year 'as varchar(1000)) as report_2;

select cust,prod,state,month, avg(quant) as average
into temp table temp_master
from sales 
group by cust,prod,state,month
order by cust,prod,state,month
;

select tm.cust,tm.prod,tm.state,tm.month, 
cast( t1.average as int ) as before_average,
cast( t2.average as int ) as after_average
from temp_master as tm
left join temp_master as t1
on
tm.cust = t1.cust and
tm.prod = t1.prod and
tm.state = t1.state and 
t1.month = tm.month -1

left join temp_master as t2
on
tm.cust = t2.cust and
tm.prod = t2.prod and
tm.state = t2.state and 
t2.month = tm.month +1
;
drop table temp_master;

--------------------------------------------------------------------------------

select 
  CAST(
    '3.For each product, find the median sales quantity (assume an odd number of sales for 
simplicity of presentation). (NOTE – “median” is defined as “denoting or relating to a 
value or quantity lying at the midpoint of a frequency distribution of observed values or 
quantities, such that there is an equal probability of falling above or below it.” E.g., 
Median value of the list {13, 23, 12, 16, 15, 9, 29} is 15'as varchar(1000)) as report_3;

with q1 as (
select
-- we will rank the list of quant values in a descending order witht the largest element having
-- highest rank of 1, for duplicates we re use the same rank number
prod, quant, rank() over ( partition by prod order by quant desc) as rn 
from sales
),
q2 as (
select prod,
-- using the logic of medians that is when the number of elements in the list is even we 
-- consider both the values next to the middle most rank 
-- else when number of elements is odd we take middle ranked value
--example {2, 3, 11, *13*, 26, 34, 47}. The median is the number in the middle that is 13
-- {2, 3, 11, *13, 17*, 27, 34, 47}. The median is the average of the two numbers in the middle 
-- which in this case is fifteen {(13 + 17) ÷ 2 = 15}.
case when cast(max(rn)+min(rn) as decimal )/2  % 1 <> 0 then cast(max(rn)+min(rn) as decimal )/2 +1 else cast(max(rn)+min(rn) as decimal )/2 end as median
from q1
group by prod
)
select q2.prod,cast(avg(q1.quant)as decimal(10,2)) as median_quant
from q2
inner join q1 
on q2.prod= q1.prod and ( q1.rn = q2.median or q1.rn between q2.median -0.5 and q2.median + 0.5)
group by q2.prod
order by q2.prod
;
--------------------------------------------------------------------------------------------------
select 
  CAST(
    '4.For customer and product, find the month by which time, 75% of the sales quantities 
have been purchased. Again, for this query, the “YEAR” attribute is not considered. 
Another way to view this query is to pretend all 10,000 rows of sales data are from the 
same year'as varchar(1000)) as report_3;

 
with q1 as (
    -- first we tabulate expenses done upto the end of each month by adding the expenses of the current month and months before it for each combination of cust,prod
    with q1 as (
    select cust,prod, month,sum(quant) as month_total
    from sales
    group by cust,prod,month
    order by cust,prod,month
    )
    select q1.cust,q1.prod,q1.month,sum(q2.month_total) as upto_month_total
    from q1 
    full outer join q1 as q2
    on q1.prod = q2.prod and q1.cust = q2.cust
    and q1.month>=q2.month
    group by q1.cust,q1.prod,q1.month
    order by cust,prod,month,upto_month_total

)
-- now we select the top rows of the above result and take only those rows that satify the 75% condition
select 
distinct on(cust,prod)
cust,prod,month
from q1
where upto_month_total > ( 
    select max(upto_month_total)*0.75 
    from q1 as q2 
    where q1.cust = q2.cust and q1.prod = q2.prod
    group by cust,prod
    )
order by cust,prod,month,upto_month_total
;
