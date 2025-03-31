use liocinema_db;
select * from contents;
select * from subscribers;
select * from content_consumption;

use jotstar_db;
select * from contents;
select * from subscribers;
select * from content_consumption;
-- 1. Total Users & Growth Trends

/* What is the total number of users for LioCinema and Jotstar, and how do they
compare in terms of growth trends (January–November 2024)?*/

select 'liocinema' as Database_name, count(distinct user_id) as total_liocinema_users
 from liocinema_db.subscribers 
union all
select 'Jotstar' as Database_name,count(distinct user_id)  total_jotstar_users 
from jotstar_db.subscribers;

-- Growth trends
with cte as(
select 'liocinema' as Database_name, count(distinct user_id) as total_users, month(subscription_date) as mon
 from liocinema_db.subscribers 
 where year(subscription_date)=2024
 group by 1,3
union all
select 'Jotstar' as Database_name,count(distinct user_id) as total_users , month(subscription_date) as mon
from jotstar_db.subscribers
where year(subscription_date)=2024
group by 1,3)
select mon,sum(case when Database_name='Jotstar' then  total_users  end) as Jotstar_users,
sum(case when Database_name='liocinema' then  total_users end) as liocinema_users
from cte 
WHERE mon BETWEEN 1 AND 11 
group by 1
order by 1;

-- 2. Content Library Comparison
/*  What is the total number of contents available on LioCinema vs. Jotstar? How do
they differ in terms of language and content type?*/
select * from jotstar_db.contents;
select * from liocinema_db.contents;

select distinct genre from liocinema_db.contents;
with cte as(
select *,'Jotstar' as Database_name
from jotstar_db.contents
union all
select *,'liocinema' as Database_name 
from liocinema_db.contents)

select Database_name,
count(*) as total_content,
sum(case when genre='Action' then 1 else 0 end) as action,
sum(case when genre='Comedy' then 1 else 0 end) as comedy,
sum(case when genre='Drama' then 1 else 0 end) as drama,
sum(case when genre='Family' then 1 else 0 end) as family,
sum(case when genre='Romance' then 1 else 0 end) as romance,
sum(case when genre='Crime' then 1 else 0 end) as crime,
sum(case when genre='Horror' then 1 else 0 end) as horror,
sum(case when genre='Thriller' then 1 else 0 end) as thriller,
sum(case when genre='Highlights' then 1 else 0 end) as highlights,
sum(case when genre='Live matches' then 1 else 0 end) as live_matches,
sum(case when genre='Documentaries' then 1 else 0 end) as Documentaries
from cte
group by 1;
-- 3. User Demographics

/*What is the distribution of users by age group, city tier, and subscription plan for each
platform?*/
WITH cte AS (
    SELECT 
        'jotstar' AS Database_name, 
        city_tier, 
        age_group, 
        subscription_plan, 
        COUNT(*) AS total_users 
    FROM jotstar_db.subscribers
    GROUP BY 1, 2, 3, 4
    UNION ALL
    SELECT 
        'liocinema' AS Database_name, 
        city_tier, 
        age_group, 
        subscription_plan, 
        COUNT(*) AS total_users 
    FROM liocinema_db.subscribers
    GROUP BY 1, 2, 3, 4
)
SELECT 
    city_tier,
    age_group,
    subscription_plan,
    SUM(CASE WHEN Database_name = 'liocinema' THEN total_users ELSE 0 END) AS liocinema_users,
    SUM(CASE WHEN Database_name = 'jotstar' THEN total_users ELSE 0 END) AS jotstar_users
FROM cte
GROUP BY city_tier, age_group, subscription_plan
ORDER BY city_tier, age_group, subscription_plan;

-- 4. Active vs. Inactive Users

/*What percentage of LioCinema and Jotstar users are active vs. inactive? How do
these rates vary by age group and subscription plan?*/
select * from jotstar_db.subscribers;
select * from liocinema_db.subscribers;
with cte as(
select 'jotstar' as Database_name ,count(*) as total_users,
sum(case when last_active_date is null then 1 else 0 end)as total_active_users,
sum(case when last_active_date is not null then 1 else 0 end)as total_inactive_users
 from jotstar_db.subscribers

 union all 
 select 'liocinema' as Database_name ,count(*) as total_users,
sum(case when last_active_date is null then 1 else 0 end)as total_active_users,
sum(case when last_active_date is not null then 1 else 0 end)as total_inactive_users
 from liocinema_db.subscribers
)
select Database_name, (total_active_users/total_users)*100 as active_pct,
(total_inactive_users/total_users)*100 as inactive_pct
from cte;

-- 5.Watch Time Analysis

/*What is the average watch time for LioCinema vs. Jotstar during the analysis period?
How do these compare by city tier and device type?*/
select * from liocinema_db.content_consumption;
select * from jotstar_db.content_consumption;

with cte as(
select 'liocinema' as db,device_type , avg(total_watch_time_mins) as avg_watch_type
from liocinema_db.content_consumption
group by 1,2
union all
select 'jotstar' as db,device_type , avg(total_watch_time_mins)
from jotstar_db.content_consumption
group by 1,2)

select db, max(case when device_type='Mobile' then round(avg_watch_type,2) end) as mobile_users,
max(case when device_type='TV' then round(avg_watch_type,2) end) as TV_users,
max(case when device_type='Laptop' then round(avg_watch_type,2) end) as Laptop_users
from cte
group by 1;

-- 6. Inactivity Correlation

/*How do inactivity patterns correlate with total watch time or average watch time? Are
less engaged users more likely to become inactive?*/
with joined_tab as(
select 'jotstar' as Db_name,js.*, jc.total_watch_time_mins from jotstar_db.subscribers js
inner join jotstar_db.content_consumption jc
on js.user_id=jc.user_id 
union all

select 'liocinema' as Db_name,ls.*, lcc.total_watch_time_mins  from liocinema_db.subscribers ls
inner join liocinema_db.content_consumption lcc
on ls.user_id=lcc.user_id)
select Db_name,
count(*) as total_users,
sum(case when last_active_date< current_date then 1 else 0 end)as inactive_users,
avg(case when last_active_date< current_date then total_watch_time_mins else null end) as avg_consumption_time_of_inactive_users,
sum(case when last_active_date is null then 1 else 0 end)as active_users,
avg(case when last_active_date is null then total_watch_time_mins else null end) as avg_consumption_time_of_active_users
from joined_tab
group by 1
;
-- active users have much more average consumption time

-- 7. Downgrade Trends
/*How do downgrade trends differ between LioCinema and Jotstar? Are downgrades
more prevalent on one platform compared to the other?*/

select * from jotstar_db.contents;
select * from liocinema_db.contents;
-- ---------------- USERS GROWTH --------------------
with subscriber_growth as(
select 'jotstar' as db_name,month(subscription_date) as mon ,year(subscription_date) as yr ,count(*) as total_users 
from jotstar_db.subscribers
group by 1,2,3
union all
select 'liocinema' as db_name,month(subscription_date) as mon ,year(subscription_date) as yr ,count(*) as total_users 
from liocinema_db.subscribers
group by 1,2,3
)
select mon,yr,sum(case when db_name='jotstar' then total_users else null end )as jotstar_gr,
sum(case when db_name='liocinema' then total_users else null end) as liocinema_gr
from subscriber_growth
group by mon,yr
order by 1,2;
-- --------------------- SUBSCRIPTION CHANGES --------------
with sub_downgrade as(
select 'jotstar' as db_name,user_id ,month(plan_change_date) as mon ,year(plan_change_date) as yr,
case when subscription_plan ='Premium' then 1 
when  subscription_plan ='VIP' then 2
when subscription_plan ='basic' then 3
else 4
end as subscription_rating,
case when new_subscription_plan ='Premium' then 1 
when  new_subscription_plan ='VIP' then 2
when new_subscription_plan ='basic' then 3
else 4
end as new_subscription_rating
 from jotstar_db.subscribers
 
 union all 
 
select 'liocinema' as db_name, user_id ,month(plan_change_date) as mon ,year(plan_change_date) as yr,
case when subscription_plan ='Premium' then 1 
when  subscription_plan ='VIP' then 2
when subscription_plan ='basic' then 3
else 4
end as subscription_rating,
case when new_subscription_plan ='Premium' then 1 
when new_subscription_plan ='basic' then 3
else 4
end as new_subscription_rating
 from liocinema_db.subscribers)
 
 select mon,yr,
 sum(case when db_name='jotstar' and new_subscription_rating>subscription_rating then 1 else 0 end)as jotstar_downgraded_subscribers,
 sum(case when db_name='jotstar' and new_subscription_rating<subscription_rating then 1 else 0 end)as jotstar_upgraded_subscribers,
 sum(case when db_name='liocinema' and new_subscription_rating>subscription_rating then 1 else 0 end)as liocinema_downgraded_subscribers,
 sum(case when db_name='liocinema' and new_subscription_rating<subscription_rating then 1 else 0 end)as liocinema_upgraded_subscribers
 from sub_downgrade
 group by 1,2
 order by 1,2
 ; -- liocinema has more prevalent downgrade trend
 
select * from jotstar_db.subscribers;
-- 8. Upgrade Patterns
/*What are the most common upgrade transitions (e.g., Free to Basic, Free to VIP,
Free to Premium) for LioCinema and Jotstar? How do these differ across platforms?*/
with upgrades as(
select 'liocinema' as db_name,month(plan_change_date) as mon ,year(plan_change_date) as yr,
sum(case when new_subscription_plan in ('Premium','VIP','Basic') then 1 else 0 end) as total,
sum(case when subscription_plan ='Free'  and  new_subscription_plan ='Premium' then 1 else 0 end) as free_to_prem,
sum(case when subscription_plan ='Free'  and  new_subscription_plan ='VIP' then 1 else 0 end) as free_to_VIP
 from liocinema_db.subscribers
 where new_subscription_plan!=subscription_plan
 group by 1,2,3
 union all
select 'jotstar' as db_name,month(plan_change_date) as mon ,year(plan_change_date) as yr,
sum(case when new_subscription_plan in ('Premium','VIP','Basic') then 1 else 0 end) as total,
sum(case when subscription_plan ='Free'  and  new_subscription_plan ='Premium' then 1 else 0 end) as free_to_prem,
sum(case when subscription_plan ='Free'  and  new_subscription_plan ='VIP' then 1 else 0 end) as free_to_VIP
from jotstar_db.subscribers
where new_subscription_plan!=subscription_plan
 group by 1,2,3)
 
 select mon, yr,sum(case when db_name= 'jotstar' then free_to_prem  else 0 end)as jotstar_premium_changes,
 sum(case when db_name= 'jotstar' then free_to_VIP  else 0 end) as jotstar_VIP_changes,
 sum(case when db_name= 'liocinema' then free_to_prem  else 0 end) as liocinema_premium_changes,
 sum(case when db_name= 'liocinema' then free_to_VIP  else 0 end) as liocinema_VIP_changes
  from upgrades
  group by 1,2
  order by 1,2;
  
-- 9. Paid Users Distribution
/*How does the paid user percentage (e.g., Basic, Premium for LioCinema; VIP,
Premium for Jotstar) vary across different platforms? Analyse the proportion of
premium users in Tier 1, Tier 2, and Tier 3 cities and identify any notable trends or
differences.*/
with cte as(
select 'jotstar' as db_name,
user_id,
city_tier,
subscription_date,
subscription_plan,
plan_change_date,
rank() over(partition by  user_id order by COALESCE(plan_change_date, subscription_date) desc) as rn -- cases when plan_is_changed later on
from jotstar_db.subscribers
where subscription_plan <> 'Free'

union all
select 'liocinema' as db_name,
user_id,
city_tier,
subscription_date,
subscription_plan,
plan_change_date,
rank() over(partition by  user_id order by COALESCE(plan_change_date, subscription_date) desc) as rn
from liocinema_db.subscribers
where subscription_plan <> 'Free'
)

select db_name,city_Tier,
count(*) as total_users,
sum(case when subscription_plan='Premium' then 1 else 0 end)*100 /count(*) as premium_user_pct ,
sum(case when subscription_plan='VIP' then 1 else 0 end)*100/count(*) as VIP_user_pct
from cte
where rn=1
group by 1,2
order by 2;

-- 10. Revenue Analysis
/*Assume the following monthly subscription prices, calculate the total revenue
generated by both platforms (LioCinema and Jotstar) for the analysis period (January
to November 2024).
The calculation should consider:
❖ Subscribers count under each plan.
❖ Active duration of subscribers on their respective plans.
❖ Upgrades and downgrades during the period, ensuring revenue reflects the
time spent under each plan.*/


-- LioCinema -->BASIC -69 Premium -129
-- Jotstar -->VIP-159.  Premium -359
-- -------------------- REVENUS BASD ON PLANS----------------
select 'liocinema' as db_name,
count(case when subscription_plan='Basic' then 1 else null end) *69 as basic_revenue,
count(case when subscription_plan='Premium' then 1 else null end)*159 as premium_revenue,
0 as VIP_users
from liocinema_db.subscribers

union all
select 'jotstar' as db_name,
0 as basic_users,
count(case when subscription_plan='Premium' then 1 else null end)*159 as premium_revenue,
count(case when subscription_plan='VIP' then 1 else null end)*359 as VIP_revenue
from jotstar_db.subscribers;
 
 -- ------------------------REVENUE BASED ON ACTIVE DURATION-----------------
with cte as(
select 'liocinema' as db_name,
user_id,subscription_plan,
LEAST(COALESCE(plan_change_date, '2024-11-30'), '2024-11-30') AS end_date, 
GREATEST(subscription_date, '2024-01-01') AS start_date
from liocinema_db.subscribers
WHERE subscription_date <= '2024-11-30'  -- Ensuring only relevant subscriptions
      AND (plan_change_date IS NULL OR plan_change_date >= '2024-01-01') -- Active in 2024
      and subscription_PLAN<> 'Free'
      
union all
select 'jotstar' as db_name,
user_id,subscription_plan,
LEAST(COALESCE(plan_change_date, '2024-11-30'), '2024-11-30') AS end_date, 
GREATEST(subscription_date, '2024-01-01') AS start_date
from jotstar_db.subscribers
WHERE subscription_date <= '2024-11-30'  -- Ensuring only relevant subscriptions
      AND (plan_change_date IS NULL OR plan_change_date >= '2024-01-01') -- Active in 2024
      and subscription_plan<> 'Free')
      
SELECT 
    db_name,
    SUM(
        CASE 
            WHEN subscription_plan = 'Basic' AND db_name = 'jotstar' THEN 149 * (TIMESTAMPDIFF(MONTH, start_date, end_date) + 1)
            WHEN subscription_plan = 'Premium' AND db_name = 'jotstar' THEN 449 * (TIMESTAMPDIFF(MONTH, start_date, end_date) + 1)
            WHEN subscription_plan = 'VIP' AND db_name = 'jotstar' THEN 649 * (TIMESTAMPDIFF(MONTH, start_date, end_date) + 1)
            WHEN subscription_plan = 'Basic' AND db_name = 'liocinema' THEN 199 * (TIMESTAMPDIFF(MONTH, start_date, end_date) + 1)
            WHEN subscription_plan = 'Premium' AND db_name = 'liocinema' THEN 499 * (TIMESTAMPDIFF(MONTH, start_date, end_date) + 1)
            WHEN subscription_plan = 'VIP' AND db_name = 'liocinema' THEN 699 * (TIMESTAMPDIFF(MONTH, start_date, end_date) + 1)
            ELSE 0
        END
    ) AS total_revenue
FROM cte
GROUP BY db_name;
