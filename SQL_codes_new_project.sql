use trips_db;
use targets_db;
                 -- BUSINESS REQUESTS
                 
-- Business Request 1 : City-Level Fare and Trip Summary Report
select * 
from trips_db.fact_trips;

select count(*)
from trips_db.fact_trips;

with cte1 as(select city_id, count(trip_id) as total_trips, round(sum(fare_amount)/sum(distance_travelled_km),2) as avg_fare_per_km, round(sum(fare_amount)/count(trip_id),2) as avg_fare_per_trip, round(count(trip_id)/425903 * 100 ,2) as percentage_contribution_to_total_trips
from trips_db.fact_trips 
group by city_id)
select dim_city.city_name, cte1.total_trips, cte1.avg_fare_per_km, cte1.avg_fare_per_trip, cte1.percentage_contribution_to_total_trips
from cte1
join trips_db.dim_city
on cte1.city_id = dim_city.city_id;


-- Business Request 2 : Monthly City-Level Trips Target Performance Report
select *
from targets_db.monthly_target_trips;

select * 
from trips_db.fact_trips;

-- fact_trips table from trips_db
with cte5 as (with cte3 as (with cte2 as (select city_id, trip_id, monthname(date) as month_name
from trips_db.fact_trips)
select month_name, city_id, count(trip_id) as actual_trips
from cte2
group by month_name, city_id),

-- monthly_target_trips table from targets_db
cte4 as (select monthname(month) as month_name, city_id, total_target_trips as target_trips
from targets_db.monthly_target_trips)

-- final table without city_name column
select cte3.month_name, cte3.city_id, target_trips, actual_trips
from cte3
join cte4
on cte3.month_name = cte4.month_name and cte3.city_id = cte4.city_id)

-- final table having city_name column from dim_city table
select city_name, month_name, actual_trips, target_trips, case when (actual_trips>target_trips) then "Above Target" else "Below Target" end  as performance_status, round (((actual_trips - target_trips)/actual_trips)*100, 2) as percentage_difference
from cte5
join trips_db.dim_city
on cte5.city_id = trips_db.dim_city.city_id;


-- Business Request 3 : City-Level Repeat Passenger Trip Frequency Report
select *
from trips_db.dim_repeat_trip_distribution;

with cte6 as (select city_id, trip_count, sum(repeat_passenger_count) as counts
from trips_db.dim_repeat_trip_distribution
group by trip_count, city_id)
select city_id, 
sum(case when trip_count = '2-Trips' then counts end) as '2-Trips',
sum(case when trip_count = '3-Trips' then counts end) as '3-Trips',
sum(case when trip_count = '4-Trips' then counts end) as '4-Trips',
sum(case when trip_count = '5-Trips' then counts end) as '5-Trips',
sum(case when trip_count = '6-Trips' then counts end) as '6-Trips',
sum(case when trip_count = '7-Trips' then counts end) as '7-Trips',
sum(case when trip_count = '8-Trips' then counts end) as '8-Trips',
sum(case when trip_count = '9-Trips' then counts end) as '9-Trips',
sum(case when trip_count = '10-Trips' then counts end) as '10-Trips'
from cte6
group by city_id;


-- Business Request 4 : Identify Cities with Highest and Lowest Total New Passangers
select *
from trips_db.fact_passenger_summary;

with cte8 as ((select city_id, sum(new_passengers) as total_new_passengers, "Top 3" as city_category
from trips_db.fact_passenger_summary 
group by city_id
order by total_new_passengers desc
limit 3)
union all
(select city_id, sum(new_passengers) as total_new_passengers, "Bottom 3" as city_category
from trips_db.fact_passenger_summary 
group by city_id
order by total_new_passengers asc
limit 3))

select city_name, total_new_passengers, city_category
from cte8
join trips_db.dim_city
on cte8.city_id = dim_city.city_id
order by total_new_passengers desc;


-- Business Request 5 : Identify Month with Highest Revenue for Each City
select *
from trips_db.fact_trips;

with cte11 as (with cte10 as (with cte9  as (select monthname(date) as month_name, city_id, sum(fare_amount) as month_revenue
from trips_db.fact_trips
group by month_name, city_id)
select *, sum(month_revenue) over(partition by city_id) as Total_revenue, rank() over(partition by city_id order by month_revenue desc) as rk
from cte9)
select city_id, month_name as highest_revenue_month, month_revenue as revenue, round((month_revenue/Total_revenue)*100,2) as percentage_contribution
from cte10
where rk=1)
select city_name, highest_revenue_month, revenue, percentage_contribution
from cte11
join trips_db.dim_city
on cte11.city_id = dim_city.city_id;


-- Business Request 6 : Repeat Passenger Rate Analysis
select *
from trips_db.fact_passenger_summary;

-- Month and City Wise Repeat passenger Rate
select monthname(month) as month_name, city_name, total_passengers, repeat_passengers, round((repeat_passengers/total_passengers)*100,2) as monthly_repeat_passanger_rate
from trips_db.fact_passenger_summary
join trips_db.dim_city
on trips_db.fact_passenger_summary.city_id = dim_city.city_id;

-- City Wise Repeat Passenger Rate 
with cte13 as(select city_id, sum(total_passengers) as city_wise_total_passengers, sum(repeat_passengers) as city_wise_repeat_passengers 
from trips_db.fact_passenger_summary
group by city_id)
select city_name, city_wise_total_passengers, city_wise_repeat_passengers, round((city_wise_repeat_passengers/city_wise_total_passengers)*100,2) as city_repeat_passenger_rate
from cte13
join trips_db.dim_city
on cte13.city_id = dim_city.city_id
