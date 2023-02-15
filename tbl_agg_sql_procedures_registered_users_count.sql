DROP TABLE IF EXISTS tbl_agg_registered_users_idec;
create table tbl_agg_registered_users_idec(
    id bigint unsigned PRIMARY KEY auto_increment,
    created_date DATE NOT NULL,
    day bigint unsigned not null,
    dayname varchar(140) NOT NULL DEFAULT 'Not Specified',
    quarter int not null,
    year year not null,
    user_daily_count numeric unsigned null default '0',
    updated_at datetime not null
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED;

INSERT INTO tbl_agg_registered_users_idec(created_date,day,dayname,quarter,year,updated_at)

select distinct CAST(created_at AS date) AS create_date,day(created_at),dayname(created_at),quarter(created_at),
                year(created_at),now()
from tbl_users;

update tbl_agg_registered_users_idec t
join
(select distinct CAST(created_at AS date) AS create_date,day(created_at),dayname(created_at),quarter(created_at),
                year(created_at),count(tu.id) count_app
from tbl_users tu
group by 1,2,3,4,5) t2
on t.created_date=t2.create_date
set t.user_daily_count = t2.count_app;

delimiter $$
drop procedure if exists pd_Registered_Users;
create procedure pd_Registered_Users(user_id int,create_date timestamp,update_date timestamp)
begin
    declare count_id bigint;

    select count(id) into count_id
    from tbl_agg_registered_users_idec
    where date(created_date)=date(create_date);

    if count_id>=1 then
        update tbl_agg_registered_users_idec
        set user_daily_count=user_daily_count+1,
            updated_at=now()
        where created_date=date(create_date);
    else
        insert into tbl_agg_registered_users_idec(created_date,day,dayname,quarter,year,user_daily_count,updated_at)
        values(date(create_date),day(create_date),dayname(create_date),quarter(create_date),year(create_date),1,now());
    end if;
end;
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS aiUserDailyCount;
CREATE TRIGGER aiUserDailyCount
AFTER INSERT
ON tbl_users FOR EACH ROW
BEGIN
    CALL pd_Registered_Users (
        NEW.id,NEW.created_at,NEW.updated_at);
END$$
DELIMITER ;