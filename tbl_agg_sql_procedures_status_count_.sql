DROP TABLE IF EXISTS tbl_agg_status_idec;
create table tbl_agg_status_idec(
    id bigint unsigned PRIMARY KEY auto_increment,
    created_date DATE NOT NULL,
    day bigint unsigned not null,
    dayname varchar(140) NOT NULL DEFAULT 'Not Specified',
    quarter int not null,
    year year not null,
    status_id bigint unsigned null,
    application_status VARCHAR(140) NOT NULL DEFAULT 'Not Specified',
    status_counter numeric default 0,
    updated_at datetime not null
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED;

INSERT INTO tbl_agg_status_idec(created_date,status_id,day,dayname,year,quarter,
                         application_status,updated_at)

select distinct CAST(ta.created_at AS date) AS create_date,ta.status_id,day(ta.created_at),
                dayname(ta.created_at),year(created_at) year,quarter(ta.created_at),
                tls.name application_status,now()
from tbl_applications ta
left join tbl_lk_status tls on ta.status_id = tls.id;

update tbl_agg_status_idec t
join
(select distinct CAST(ta.created_at AS date) AS create_date,ta.status_id,day(ta.created_at),
                dayname(ta.created_at),year(created_at) year,quarter(ta.created_at),
                tls.name application_status,count(ta.id)  AS count_app
from tbl_applications ta
left join tbl_lk_status tls on ta.status_id = tls.id
group by 1,2,3,4,5,6,7) t2
on t.created_date=t2.create_date
       and t.status_id=t2.status_id
       and t.application_status=t2.application_status
set t.status_counter = t2.count_app;

# The parameters/arguments inside pd_Idec will come from the tbl_applications
# table which is the FACT TABLE that gets inserted into or updated whenever someone makes an application
delimiter $$
drop procedure if exists pd_Status;
create procedure pd_Status(old_statusid bigint unsigned,new_statusid bigint unsigned,
                            create_date timestamp,update_date timestamp)
begin
    declare count_id bigint unsigned;
    declare oldstatus varchar(140);
    declare newstatus varchar(140);

    select count(id) into count_id
    from tbl_agg_status_idec
    where date(created_date)=date(create_date);
    select name into oldstatus
    from tbl_lk_status
    where id=old_statusid;
    select name into newstatus
    from tbl_lk_status
    where id=new_statusid;

    if count_id>=1 and old_statusid is null and new_statusid in (select status_id from tbl_agg_status_idec
                                            where created_date=date(create_date)) then
        update tbl_agg_status_idec
        set status_counter=status_counter+1,
            updated_at=now()
        where status_id=new_statusid and created_date=date(create_date);

    elseif count_id>=1 and old_statusid is null and new_statusid not in (select status_id from tbl_agg_status_idec
                                            where created_date=date(create_date)) then
        insert into tbl_agg_status_idec(created_date,status_id,day,dayname,year,quarter,
                         application_status,status_counter,updated_at)
        values(date(create_date),new_statusid,day(create_date),dayname(create_date),year(create_date),quarter(create_date),newstatus,1,now());

    elseif count_id>=1 and old_statusid is not null and new_statusid in (select status_id from tbl_agg_status_idec
                                            where created_date=date(create_date)) then
        update tbl_agg_status_idec
        set status_counter = status_counter-1,
            updated_at=now()
        where status_id=old_statusid and created_date=date(create_date);
        update tbl_agg_status_idec
        set status_counter=status_counter+1,
            updated_at=now()
        where status_id=new_statusid and created_date=date(create_date);

    elseif count_id>=1 and old_statusid is not null and new_statusid not in (select status_id from tbl_agg_status_idec
                                                where created_date=date(create_date)) then
        update tbl_agg_status_idec
        set status_counter = status_counter-1,
            updated_at=now()
        where status_id=old_statusid and created_date=date(create_date);

        insert into tbl_agg_status_idec(created_date,status_id,day,dayname,year,quarter,
                         application_status,status_counter,updated_at)
        values(date(create_date),new_statusid,day(create_date),dayname(create_date),year(create_date),quarter(create_date),newstatus,1,now());

    elseif count_id=0 then
        insert into tbl_agg_status_idec(created_date,status_id,day,dayname,year,quarter,
                         application_status,status_counter,updated_at)
        values(date(create_date),new_statusid,day(create_date),dayname(create_date),year(create_date),quarter(create_date),newstatus,1,now());
    end if;
end;
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS aiStatusDailyCount;
CREATE TRIGGER aiStatusDailyCount
AFTER INSERT
ON tbl_applications FOR EACH ROW
BEGIN
    CALL pd_Status (
        null, NEW.status_id,NEW.created_at,NEW.updated_at);
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS auStatusDailyCount;
CREATE TRIGGER auStatusDailyCount
AFTER UPDATE
ON tbl_applications FOR EACH ROW
BEGIN
    CALL pd_Status (
        OLD.status_id, NEW.status_id,OLD.created_at,NEW.updated_at);
END$$
DELIMITER ;
