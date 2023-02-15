DROP TABLE IF EXISTS tbl_agg_sector_approved_idec;
create table tbl_agg_sector_approved_idec(
    id bigint unsigned PRIMARY KEY auto_increment,
    created_date DATE NOT NULL,
    day bigint unsigned not null,
    dayname varchar(140) NOT NULL DEFAULT 'Not Specified',
    quarter int not null,
    year year not null,
    sector_id int not null,
    sector VARCHAR(50) NOT NULL DEFAULT 'Not Specified',
    daily_waiver_value double unsigned null default '0.00',
    updated_at datetime not null
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED;


INSERT INTO tbl_agg_sector_approved_idec(created_date,day,dayname,year,quarter,sector_id,sector,updated_at)
select distinct CAST(ta.created_at AS date) AS create_date,day(ta.created_at),
                dayname(ta.created_at),year(created_at) year,quarter(ta.created_at),ta.sector_id,tls.name sector,now()
from (select * from tbl_applications where status_id=5) ta
left join tbl_lk_sectors tls on ta.sector_id = tls.id;


update tbl_agg_sector_approved_idec t
join
(select distinct CAST(ta.created_at AS date) AS create_date,day(ta.created_at),dayname(ta.created_at),
                 year(created_at) year,quarter(ta.created_at),ta.sector_id,tls.name sector,
                 sum(actual_waiver_amount) daily_waiver
from (select * from tbl_applications where status_id=5) ta
left join tbl_lk_sectors tls on ta.sector_id = tls.id
group by 1,2,3,4,5,6,7) t2
on t.created_date=t2.create_date
       and t.sector_id=t2.sector_id
       and t.sector=t2.sector
set t.daily_waiver_value= t2.daily_waiver;

delimiter $$
drop procedure if exists pd_Sector_Approved;
create procedure pd_Sector_Approved(sectorid int,oldstatusid int,newstatusid int, waiver double,create_date timestamp,update_date timestamp)
begin
    declare count_id bigint;
    declare sector varchar(255);

    select count(id) into count_id
    from tbl_agg_sector_approved_idec
    where date(created_date)=date(create_date);

    select name into sector
    from tbl_lk_sectors
    where id=sectorid;

    if count_id>=1 and oldstatusid is null and newstatusid=5 and
       sectorid in (select sector_id from tbl_agg_sector_approved_idec
            where created_date = date(create_date)) then
        update tbl_agg_sector_approved_idec
        set daily_waiver_value=daily_waiver_value+waiver,
            updated_at=now()
        where sector_id=sectorid and
              created_date=date(create_date);

    elseif count_id>=1 and oldstatusid is null and newstatusid=5 and
           sectorid not in (select sector_id from tbl_agg_sector_approved_idec
            where created_date = date(create_date)) then
        insert into tbl_agg_sector_approved_idec(created_date,day,dayname,year,quarter,sector_id,sector,daily_waiver_value,
                                                 updated_at)
        values(date(create_date),day(create_date),dayname(create_date),year(create_date),quarter(create_date),
               sectorid,sector,waiver,now());

    elseif count_id>=1 and oldstatusid is not null and newstatusid=5 and
           sectorid in (select sector_id from tbl_agg_sector_approved_idec
                        where created_date = date(create_date)) then
        update tbl_agg_sector_approved_idec
        set daily_waiver_value=daily_waiver_value+waiver,
            updated_at=now()
        where sector_id=sectorid and
              created_date=date(create_date);

     elseif count_id>=1 and oldstatusid is not null and newstatusid=5 and
           sectorid not in (select sector_id from tbl_agg_sector_approved_idec
                        where created_date = date(create_date)) then
        insert into tbl_agg_sector_approved_idec(created_date,day,dayname,year,quarter,sector_id,sector,daily_waiver_value,
                                                 updated_at)
        values(date(create_date),day(create_date),dayname(create_date),year(create_date),quarter(create_date),
               sectorid,sector,waiver,now());

    elseif count_id=0 and newstatusid=5 then
        insert into tbl_agg_sector_approved_idec(created_date,day,dayname,year,quarter,sector_id,sector,daily_waiver_value,
                                                 updated_at)
        values(date(create_date),day(create_date),dayname(create_date),year(create_date),quarter(create_date),
               sectorid,sector,waiver,now());

    end if;
end;
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS aiSectorDailyApproved;
CREATE TRIGGER aiSectorDailyApproved
AFTER INSERT
ON tbl_applications FOR EACH ROW
BEGIN
    CALL pd_Sector_Approved (
        NEW.sector_id,null,NEW.status_id,NEW.actual_waiver_amount,
        NEW.created_at,NEW.updated_at);
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS auSectorDailyApproved;
CREATE TRIGGER auSectorDailyApproved
AFTER UPDATE
ON tbl_applications FOR EACH ROW
BEGIN
    CALL pd_Sector_Approved (
        NEW.sector_id,OLD.status_id,NEW.status_id,NEW.actual_waiver_amount,
        NEW.created_at,NEW.updated_at);
END$$
DELIMITER ;

