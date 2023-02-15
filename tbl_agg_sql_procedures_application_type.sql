DROP TABLE IF EXISTS tbl_agg_application_type_idec;
create table tbl_agg_application_type_idec(
    id bigint unsigned PRIMARY KEY auto_increment,
    created_date DATE NOT NULL,
    day bigint unsigned not null,
    dayname varchar(140) NOT NULL DEFAULT 'Not Specified',
    quarter int not null,
    year year not null,
    application_type_id int not null,
    application_type VARCHAR(50) NOT NULL DEFAULT 'Not Specified',
    daily_application_type_count numeric unsigned null default '0',
    daily_waiver_value double unsigned null default '0.00',
    updated_at datetime not null
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED;


INSERT INTO tbl_agg_application_type_idec(created_date,day,dayname,quarter,year,application_type_id,
                         application_type,updated_at)
select distinct CAST(ta.created_at AS date) AS create_date,day(ta.created_at),dayname(ta.created_at),quarter(ta.created_at),
                year(ta.created_at),ta.application_type_id,tlat.name application_type,now()
from tbl_applications ta
left join tbl_lk_application_types tlat on ta.application_type_id = tlat.id;


update tbl_agg_application_type_idec t
join
(select distinct CAST(ta.created_at AS date) AS create_date,day(ta.created_at),dayname(ta.created_at),quarter(ta.created_at),
                year(ta.created_at),ta.application_type_id,tlat.name application_type,count(ta.id) count_app
from tbl_applications ta
left join tbl_lk_application_types tlat on ta.application_type_id = tlat.id
group by 1,2,3,4,5,6,7) t2
on t.created_date=t2.create_date
       and t.application_type_id=t2.application_type_id
       and t.application_type=t2.application_type
set t.daily_application_type_count = t2.count_app;

update tbl_agg_application_type_idec t
join
(select distinct CAST(ta.created_at AS date) AS create_date,day(ta.created_at),dayname(ta.created_at),quarter(ta.created_at),
                year(ta.created_at),ta.application_type_id,tlat.name application_type,sum(ta.actual_waiver_amount) total_waiver
from tbl_applications ta
left join tbl_lk_application_types tlat on ta.application_type_id = tlat.id
group by 1,2,3,4,5,6,7) t2
on t.created_date=t2.create_date
       and t.application_type_id=t2.application_type_id
       and t.application_type=t2.application_type
set t.daily_waiver_value = t2.total_waiver;


delimiter $$
drop procedure if exists pd_Application_type;
create procedure pd_Application_type(type_id int,waiver double,create_date timestamp,update_date timestamp)
begin
    declare count_id bigint;
    declare applicationtype varchar(255);

    select count(id) into count_id
    from tbl_agg_application_type_idec
    where date(created_date)=date(create_date);

    select name into applicationtype
    from tbl_lk_application_types
    where id=type_id;

    if count_id>=1 and type_id in (select application_type_id from tbl_agg_application_type_idec
                                      where created_date = date(create_date)) then
        update tbl_agg_application_type_idec
        set daily_application_type_count=daily_application_type_count+1,
            daily_waiver_value=daily_waiver_value+waiver,
            updated_at=now()
        where application_type_id=type_id and
              created_date=date(create_date);

    elseif count_id>=1 and type_id not in (select application_type_id from tbl_agg_application_type_idec
                                      where created_date = date(create_date)) then
        INSERT INTO tbl_agg_application_type_idec(created_date,day,dayname,quarter,year,application_type_id,
                         application_type,daily_application_type_count,daily_waiver_value,updated_at)
        values(date(create_date),day(create_date),dayname(create_date),quarter(create_date),year(create_date),
               type_id,applicationtype,1,waiver,now());

    elseif count_id=0 then
        INSERT INTO tbl_agg_application_type_idec(created_date,day,dayname,quarter,year,application_type_id,
                         application_type,daily_application_type_count,daily_waiver_value,updated_at)
        values(date(create_date),day(create_date),dayname(create_date),quarter(create_date),year(create_date),
               type_id,applicationtype,1,waiver,now());
    end if;
end;
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS aiApplicationTypeDailyCount;
CREATE TRIGGER aiApplicationTypeDailyCount
AFTER INSERT
ON tbl_applications FOR EACH ROW
BEGIN
    CALL pd_Application_type (
        NEW.application_type_id, NEW.actual_waiver_amount,NEW.created_at,NEW.updated_at);
END$$
DELIMITER ;