DROP TABLE IF EXISTS tbl_agg_sector_idec;
create table tbl_agg_sector_idec(
    id bigint unsigned PRIMARY KEY auto_increment,
    created_date DATE NOT NULL,
    day bigint unsigned not null,
    dayname varchar(140) NOT NULL DEFAULT 'Not Specified',
    quarter int not null,
    year year not null,
    sector_id int not null,
    sector VARCHAR(50) NOT NULL DEFAULT 'Not Specified',
    daily_count numeric unsigned null default '0',
    daily_shipping_value double unsigned null default '0.00',
    daily_waiver_value double unsigned null default '0.00',
    updated_at datetime not null
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED;


INSERT INTO tbl_agg_sector_idec(created_date,day,dayname,year,quarter,sector_id,
                         sector,updated_at)
select distinct CAST(ta.created_at AS date) AS create_date,day(ta.created_at),
                dayname(ta.created_at),year(created_at) year,quarter(ta.created_at),ta.sector_id,tls.name sector,now()
from tbl_applications ta
left join tbl_lk_sectors tls on ta.sector_id = tls.id;


update tbl_agg_sector_idec t
join
(select distinct CAST(ta.created_at AS date) AS create_date,ta.sector_id,day(ta.created_at),
                dayname(ta.created_at),year(created_at) year,quarter(ta.created_at),tls.name sector,
count(ta.id) count
from tbl_applications ta
left join tbl_lk_sectors tls on ta.sector_id = tls.id
group by 1,2,3,4,5,6,7) t2
on t.created_date=t2.create_date
       and t.sector_id=t2.sector_id
       and t.sector=t2.sector
set t.daily_count = t2.count;

update tbl_agg_sector_idec t
join
(select distinct CAST(ta.created_at AS date) AS create_date,ta.sector_id,day(ta.created_at),
                dayname(ta.created_at),year(created_at) year,quarter(ta.created_at),tls.name sector,
sum(total_shipping_amount) shipping
from tbl_applications ta
left join tbl_lk_sectors tls on ta.sector_id = tls.id
group by 1,2,3,4,6,7) t2
on t.created_date=t2.create_date
       and t.sector_id=t2.sector_id
       and t.sector=t2.sector
set t.daily_shipping_value = t2.shipping;

update tbl_agg_sector_idec t
join
(select distinct CAST(ta.created_at AS date) AS create_date,ta.sector_id,day(ta.created_at),
                dayname(ta.created_at),year(created_at) year,quarter(ta.created_at),tls.name sector,
sum(actual_waiver_amount) daily_waiver
from tbl_applications ta
left join tbl_lk_sectors tls on ta.sector_id = tls.id
group by 1,2,3,4,5,6,7) t2
on t.created_date=t2.create_date
       and t.sector_id=t2.sector_id
       and t.sector=t2.sector
set t.daily_waiver_value= t2.daily_waiver;

delimiter $$
drop procedure if exists pd_Sector;
create procedure pd_Sector(sectorid int,waiver double,shipping double,create_date timestamp,update_date timestamp)
begin
    declare count_id bigint;
    declare sectorname varchar(255);

    select count(id) into count_id
    from tbl_agg_sector_idec
    where date(created_date)=date(create_date);

    select name into sectorname
    from tbl_lk_sectors
    where id=sectorid;

    if count_id>=1 and sectorid in (select sector_id from tbl_agg_sector_idec
                                      where created_date = date(create_date)) then
        update tbl_agg_sector_idec
        set daily_count=daily_count+1,
            daily_waiver_value=daily_waiver_value+waiver,
            daily_shipping_value=daily_shipping_value+shipping,
            updated_at=now()
        where sector_id=sectorid and
              created_date=date(create_date);

    elseif count_id>=1 and sectorid not in (select sector_id from tbl_agg_sector_idec
                                                            where created_date = date(create_date)) then
        insert into tbl_agg_sector_idec(created_date,day,dayname,year,quarter,sector_id,
                         sector,daily_count,daily_waiver_value,daily_shipping_value,updated_at)
        values(date(create_date),day(create_date),dayname(create_date),year(create_date),quarter(create_date),
               sectorid,sectorname,1,waiver,shipping,now());

    elseif count_id=0 then
        insert into tbl_agg_sector_idec(created_date,day,dayname,year,quarter,sector_id,
                         sector,daily_count,daily_waiver_value,daily_shipping_value,updated_at)
        values(date(create_date),day(create_date),dayname(create_date),year(create_date),quarter(create_date),
               sectorid,sectorname,1,waiver,shipping,now());

    end if;
end;
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS aiSectorDaily;
CREATE TRIGGER aiSectorDaily
AFTER INSERT
ON tbl_applications FOR EACH ROW
BEGIN
    CALL pd_Sector (
        NEW.sector_id,NEW.actual_waiver_amount,NEW.total_shipping_amount,
        NEW.created_at,NEW.updated_at);
END$$
DELIMITER ;

