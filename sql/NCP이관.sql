-- 테이블 생성
drop table if exists m2.cremao_bus;
create table m1.bus_xy(
node_id        varchar(30)
,node_nm        varchar(100)
,node_tp        varchar(5)
,center_yn        varchar(5)
,node_enm        varchar(100)
,lon        double precision
,lat        double precision
,work_datetime        timestamp
,node_mobile_id        varchar(15)
,sido_cd        varchar(5)
,sido_nm        varchar(100)
,point        geography
,base_ym        varchar(6)
)
distkey(node_nm)
compound sortkey(base_ym, node_nm);
commit;

-- 조회
select count (*) from m1.bld_rgst limit 100; -- 7915833
select * from m1.subway s limit 100;
select * from m1.subway s limit 100;

-- 지하철 조회
select base_dt, line_nm ,station_nm ,sum(ride) as ride, sum(alight) as alight 
  from m1.subway t1 
 group by base_dt , station_nm , line_nm 
 limit 10
;

-- subway join 
SELECT distinct  t1.line_nm , t2.station_cd, t1.station_nm, t1.ride, t1.alight --, t2.point
  from m1.subway as t1
 left JOIN m1.subway_xy as t2
   ON t1.line_nm = t2.line_nm
where 1=1
--and base_dt = '2022-09-01'
--   and t2.line_nm is null
  and t1.station_nm = '정자'
-- and point is null
   --  limit 100
 ;

-- 조인 
SELECT t1.base_ym, t2.line_nm, t2.station_cd, t2.station_nm, t1.ride_pasgr, t1.alight_pasgr, t2.point
  FROM m1.subway as t1
 left JOIN m1.subway_xy as t2
    ON t1.station_cd = t2.station_cd
;

select count(*)
from m2.cremao_subway cs 
where line_nm is null;

create table m2.cremao_bus (
base_ym        varchar(6)
,local_nm        varchar(50)
,station_nm        varchar(200)
,point        geography
)
distkey(station_nm)
compound sortkey(base_ym, station_nm);


-- 값 인서트
insert into m2.cremao_subway 
SELECT t1.base_ym, t2.line_nm, t2.station_cd, t2.station_nm, t2.point, t1.ride_pasgr, t1.alight_pasgr
  FROM m1.subway as t1
  LEFT JOIN m1.subway_xy as t2
    ON t1.station_cd = t2.station_cd
;

commit;
select * from m2.cremao_subway;

select count(*) from m1.bus_xy bx limit 100;
insert into m2.cremao_bus select * from m1.cremao_bus;

select distinct (base_ym)
from m1.bus_xy bx 
;

select count(*) from m2.cremao_subway cs ;
select * from m2.cremao_subway cs limit 100;

-- 로 삭제
delete from m2.cremao_subway
where base_ym is not null
;

-- 8월 달만 조회 (with 가상 테이블 조회) 615개
--insert into m2.cremao_subway 
with date as (
	select date_add('month', -2, sysdate) as base_dt
)
select t1.base_ym, t2.line_nm, t2.station_cd, t2.station_nm, t2.point ,t1.ride_pasgr, t1.alight_pasgr
--select count(*)
from (
	select *
	from m1.subway
	where base_ym = (select to_char(base_dt, 'yyyymm') from date)
) t1
join m1.subway_xy t2
	on t1.station_cd = t2.station_cd ;

select * from m1.subway_xy;
commit;

-- tmp 테이블 생성
drop table if exists m1.tmp;
create table m1.tmp(
base_ym	varchar(6)
,line_nm	varchar(50)
,station_cd	varchar(4)
,station_nm	varchar(50)
,lat	double precision
,lon	double precision
,ride_pasgr	bigint
,alight_pasgr	bigint
)
distkey(station_cd)
compound sortkey(base_ym, station_nm);
commit;

-- 값 인서트
insert into m1.tmp 
SELECT t1.base_ym, t2.line_nm, t2.station_cd, t2.station_nm, t1.ride_pasgr, t1.alight_pasgr, t2.lat, t2.lon
  FROM m1.subway as t1
 INNER JOIN m1.subway_xy as t2
    ON t1.station_cd = t2.station_cd
;

select * from m1.tmp t;

-- 좌표 조회 (좌표 말기)
select ST_Distance_Sphere(point(t1.lat, t1.lon))
from m1.tmp as t1;


