drop procedure if exists pd_getStatusCounter;
create procedure pd_getStatusCounter()
begin
    select application_status, sum(status_counter) status_counter
    from tbl_agg_status_idec
        group by 1 order by sum(status_counter) desc;
end;

drop procedure if exists pd_getTopBenefittingSector_Approved;
create procedure pd_getTopBenefittingSector_Approved()
begin
    select sector sector_with_approved_applications, sum(daily_waiver_value) total_waiver
    from tbl_agg_sector_approved_idec
        group by 1 order by sum(daily_waiver_value) desc;
end;

drop procedure if exists pd_getTotalWaiverBySector;
create procedure pd_getTotalWaiverBySector()
begin
    select sector,sum(daily_waiver_value) total_waiver
    from tbl_agg_sector_idec
        group by 1 order by sum(daily_waiver_value) desc;
end;

drop procedure if exists pd_getTotalWaiverByUserType;
create procedure pd_getTotalWaiverByUserType()
begin
    select user_category, sum(daily_waiver_value) total_waiver
    from tbl_agg_user_type_idec
        group by 1 order by sum(daily_waiver_value) desc;
end;

drop procedure if exists pd_getTotalRegisteredUsers;
create procedure pd_getTotalRegisteredUsers()
begin
    select count(id) total_registered_users
    from tbl_users;
end;

drop procedure if exists pd_getTotalShippingAndWaiver;
create procedure pd_getTotalShippingAndWaiver()
begin
    select sum(daily_waiver_value) total_waiver, sum(daily_shipping_value) total_shipping
    from tbl_agg_sector_idec;
end;

call pd_getTopBenefittingSector_Approved();
call pd_getTotalWaiverBySector();
call pd_getTotalShippingAndWaiver();
call pd_getTotalWaiverByUserType();
call pd_getStatusCounter();
call pd_getTotalRegisteredUsers();

select sum(total_shipping_amount) from tbl_applications;

update tbl_applications
set actual_waiver_amount = total_shipping_amount * 0.1;


select max(total_shipping_amount) from tbl_applications;

select created_date,
       max(daily_waiver_value) over (partition by created_date)
from tbl_agg_sector_approved_idec

select sa.created_date, daily_waiver_value,sector,
       rank() over (partition by created_date order by daily_waiver_value desc) rnk,
       dense_rank() over (partition by created_date order by daily_waiver_value desc) drnk,
       row_number() over (partition by created_date order by daily_waiver_value desc) rn
from tbl_agg_sector_approved_idec sa

select u.created_date,u.daily_waiver_value,
       lag(daily_waiver_value) over(),
       lead(daily_waiver_value) over ()
from (select created_date,sum(daily_waiver_value) daily_waiver_value
      from tbl_agg_sector_approved_idec sa group by 1)u




with total as (select count(id) total from tbl_applications)

select count(id)/(select total from total) from tbl_applications
	where hour(timediff(created_at,updated_at))*60 + minute(timediff(created_at,updated_at)) < 27;

select hour(timediff(created_at,updated_at))*60 + minute(timediff(created_at,updated_at)) minutes,
       minute(timediff(created_at,updated_at))
       from tbl_applications

select avg(total_shipping_amount) from tbl_applications

select *
from orders
left join customers c
on o.customer_id=c.id
where customer_id in month(start_time) and month(start_time)-1

select sum(count) from
(select count(user_id) count from tbl_applications
where user_id in (select user_id from tbl_applications where month(created_at)=10)
  and user_id in (select user_id from tbl_applications where month(created_at)=11)
union all
select count(user_id) count from tbl_applications
where user_id in (select user_id from tbl_applications where month(created_at)=11)
  and user_id in (select user_id from tbl_applications where month(created_at)=1))u;


select distinct(month(created_at)) from tbl_applications