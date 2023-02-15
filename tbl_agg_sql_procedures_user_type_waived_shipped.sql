DROP TABLE IF EXISTS tbl_agg_user_type_idec;
create table tbl_agg_user_type_idec(
    id bigint unsigned PRIMARY KEY auto_increment,
    created_date DATE NOT NULL,
    day bigint unsigned not null,
    dayname varchar(140) NOT NULL DEFAULT 'Not Specified',
    quarter int not null,
    year year not null,
    user_type_id int not null,
    user_category VARCHAR(50) NOT NULL DEFAULT 'Not Specified',
    daily_count numeric unsigned null default '0',
    daily_shipping_value double unsigned null default '0.00',
    daily_waiver_value double unsigned null default '0.00',
    updated_at datetime not null
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED;

INSERT INTO tbl_agg_user_type_idec(created_date,day,dayname,quarter,year,user_type_id,user_category,updated_at)
select distinct CAST(t1.created_at AS date),day(t1.created_at),dayname(t1.created_at),quarter(t1.created_at),
                year(t1.created_at),tut.id, tut.name,now()
from (select ta.created_at,tu.user_type_id,ta.actual_waiver_amount,ta.total_shipping_amount
    from tbl_applications ta
    left join tbl_users tu on ta.user_id=tu.id) t1
left join tbl_lk_user_types tut on t1.user_type_id=tut.id;

update tbl_agg_user_type_idec t
join
(select distinct CAST(t1.created_at AS date) create_date,day(t1.created_at),dayname(t1.created_at),quarter(t1.created_at),
                year(t1.created_at),tut.id type_id, tut.name user_type,count(t1.apply_id) count
from (select ta.id apply_id, ta.created_at,tu.user_type_id,ta.actual_waiver_amount,ta.total_shipping_amount
    from tbl_applications ta
    left join tbl_users tu on ta.user_id=tu.id) t1
left join tbl_lk_user_types tut on t1.user_type_id=tut.id
group by 1,2,3,4,5,6,7) t2
on t.created_date=t2.create_date
       and t.user_type_id=t2.type_id
       and t.user_category=t2.user_type
set t.daily_count = t2.count;

update tbl_agg_user_type_idec t
join
(select distinct CAST(t1.created_at AS date) create_date,day(t1.created_at),dayname(t1.created_at),quarter(t1.created_at),
                year(t1.created_at),tut.id type_id, tut.name user_type,sum(t1.total_shipping_amount) daily_shipping
from (select ta.id apply_id, ta.created_at,tu.user_type_id,ta.actual_waiver_amount,ta.total_shipping_amount
    from tbl_applications ta
    left join tbl_users tu on ta.user_id=tu.id) t1
left join tbl_lk_user_types tut on t1.user_type_id=tut.id
group by 1,2,3,4,5,6,7) t2
on t.created_date=t2.create_date
       and t.user_type_id=t2.type_id
       and t.user_category=t2.user_type
set t.daily_shipping_value = t2.daily_shipping;

update tbl_agg_user_type_idec t
join
(select distinct CAST(t1.created_at AS date) create_date,day(t1.created_at),dayname(t1.created_at),quarter(t1.created_at),
                year(t1.created_at),tut.id type_id, tut.name user_type,sum(t1.actual_waiver_amount) daily_waiver
from (select ta.id apply_id, ta.created_at,tu.user_type_id,ta.actual_waiver_amount,ta.total_shipping_amount
    from tbl_applications ta
    left join tbl_users tu on ta.user_id=tu.id) t1
left join tbl_lk_user_types tut on t1.user_type_id=tut.id
group by 1,2,3,4,5,6,7) t2
on t.created_date=t2.create_date
       and t.user_type_id=t2.type_id
       and t.user_category=t2.user_type
set t.daily_waiver_value = t2.daily_waiver;

delimiter $$
drop procedure if exists pd_UserType;
create procedure pd_UserType(userid int,waiver double,shipping double,create_date timestamp,update_date timestamp)
begin
    declare count_id bigint unsigned;
    declare usertypeid bigint;
    declare usercategory varchar(255);

    select count(id) into count_id
    from tbl_agg_user_type_idec
    where created_date=date(create_date);

    select user_type_id into usertypeid
    from tbl_users
    where id=userid;

    select name into usercategory
    from tbl_lk_user_types
    where id=usertypeid;

    if count_id>=1 and usertypeid in (select user_type_id from tbl_agg_user_type_idec
                                      where created_date = date(create_date)) then
        update tbl_agg_user_type_idec
        set daily_count=daily_count+1,
            daily_waiver_value=daily_waiver_value+waiver,
            daily_shipping_value=daily_shipping_value+shipping,
            updated_at=now()
        where user_type_id=usertypeid
          and created_date=date(create_date);

    elseif count_id>=1 and usertypeid not in (select user_type_id from tbl_agg_user_type_idec
                                      where created_date = date(create_date)) then
        insert into tbl_agg_user_type_idec(created_date,day,dayname,quarter,year,user_type_id,user_category,
                                           daily_count,daily_waiver_value,daily_shipping_value,updated_at)
        values(date(create_date),day(create_date),dayname(create_date),quarter(create_date),year(create_date),
               usertypeid,usercategory,1,waiver,shipping,now());

    elseif count_id=0 then
        insert into tbl_agg_user_type_idec(created_date,day,dayname,quarter,year,user_type_id,user_category,
                                           daily_count,daily_waiver_value,daily_shipping_value,updated_at)
        values(date(create_date),day(create_date),dayname(create_date),quarter(create_date),year(create_date),
               usertypeid,usercategory,1,waiver,shipping,now());
    end if;
end;
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS aiUserTypeDaily;
CREATE TRIGGER aiUserTypeDaily
AFTER INSERT
ON tbl_applications FOR EACH ROW
BEGIN
    CALL pd_UserType (
        NEW.user_id,NEW.actual_waiver_amount,NEW.total_shipping_amount,
        NEW.created_at,NEW.updated_at);
END$$
DELIMITER ;


