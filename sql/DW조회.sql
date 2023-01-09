-- 테이블 삭제
--drop table if exists m1.small_arcade;

-- 테이블 생성
create table m1.small_arcade (
base_year        varchar(4)
,base_quarter        varchar(1)
,sample_gb        varchar(40)
,commercial_wide_area        varchar(40)
,cname        varchar(200)
,sido        varchar(100)
,own_type        varchar(40)
,own_cnt        varchar(40)
,land_use_nm1        varchar(100)
,land_use_nm2        varchar(100)
,use_district_nm1        varchar(100)
,use_district_nm2        varchar(100)
,ground_floor        varchar(100)
,under_ground_floor        varchar(100)
,useapr_day        varchar(100)
,building_structure        varchar(100)
,main_purps_nm        varchar(200)
,bc_rat        varchar(100)
,vl_rat        varchar(100)
,subway_distance        varchar(40)
,bus_distance        varchar(40)
,main_crossroad        varchar(40)
,road_interface_nm        varchar(100)
,indoor_parking_gb        varchar(40)
,outdoor_parking_gb        varchar(40)
,passenger_elevator_gb        varchar(40)
,freight_elevator_gb        varchar(40)
,plat_area        varchar(100)
,arch_area        varchar(100)
,net_leasable_area        varchar(100)
,common_area        varchar(100)
,net_leasable_ratio        varchar(100)
,lease_contract_area        varchar(100)
,vacant_area        varchar(100)
,non_lease_area        varchar(100)
,special_area        varchar(100)
,etc_area        varchar(100)
,total_parking_area        varchar(100)
,ground_parking_area        varchar(100)
,under_ground_parking_area        varchar(100)
,piriti_parking_area        varchar(100)
,outdoor_parking_area        varchar(100)
,jimok_nm        varchar(40)
,land_area        varchar(100)
,conversion_rate        varchar(100)
,invest_floor        varchar(100)
,tenant_usage_status        varchar(100)
,business_type_large        varchar(40)
,business_type_small        varchar(40)
,net_leasable_ho_area        varchar(100)
,common_ho_area        varchar(100)
,sum_area        varchar(100)
,contract_deposit_1st        varchar(100)
,contract_monthly_rent_sum_1st        varchar(100)
,contract_monthly_rent_1st        varchar(100)
,selling_deposit_1st        varchar(100)
,selling_monthly_rent_sum_1st        varchar(100)
,selling_monthly_rent_1st        bigint
,admin_cost_1st        varchar(100)
,admin_actual_cost_1st        varchar(100)
,vacant_1        varchar(40)
,contract_deposit_2nd        varchar(100)
,contract_monthly_rent_sum_2nd        varchar(100)
,contract_monthly_rent_2nd        varchar(100)
,selling_deposit_2nd        varchar(100)
,selling_monthly_rent_sum_2nd        varchar(100)
,selling_monthly_rent_2nd        bigint
,admin_cost_2nd        varchar(100)
,admin_actual_cost_2nd        varchar(100)
,vacant_2        varchar(40)
,contract_deposit_3rd        varchar(100)
,contract_monthly_rent_sum_3rd        varchar(100)
,contract_monthly_rent_3rd        varchar(100)
,selling_deposit_3rd        varchar(100)
,selling_monthly_rent_sum_3rd        varchar(100)
,selling_monthly_rent_3rd        bigint
,admin_cost_3rd        varchar(100)
,admin_actual_cost_3rd        varchar(100)
,vacant_3        varchar(40)
,current_contract_date        varchar(40)
,current_contract_term        varchar(100)
,first_current_contract_date        varchar(100)
,final_land_area_amt        bigint
,final_tot_area_amt        bigint
);
commit;

-- 값 삭제
--delete from m1.bld_eap_info where base_ym = '202210';

-- 조회
select deal_amount, building_area, pnu, *
from m2.cremao_real_estate_trade_case
where deal_amount notnull
limit 10;

-- 진행상황 확인
select *
from stv_recents
where status= 'Running';

-- 테이블 정보 조회 (MB 단위) 
select unsorted
	 , size
	 , tbl_rows
	 , *
from svv_table_info
where 1=1
--   	   schema = 'm1' 
and schema = 'm2'
and "table" like 'datadam_%'
order by size desc;

-- 날짜계산
select arch_pms_day::timestamp + interval'3 day' as day1, arch_pms_day
from m1.building_permit_info
limit 100;

-- 좌표 변환 조회
select ST_Transform(ST_SetSRID(poly::geometry, 5174), 4326)::geography
from m1.pnu
limit 100;

-- 법정동 단위 거주인구
select cur_lgl_dong_cd||'00' as emd_cd , avg(case when pop_cnt = -1 then 1.5 else pop_cnt end) as pop_cnt
  from m1.kcb_stat_cm 
 where bs_yr_mon = '202209'
 group by cur_lgl_dong_cd 
limit 10;

select cur_lgl_dong_cd, count(*)
from m1.kcb_stat_cm
--where pop_cnt < 0
group by cur_lgl_dong_cd
limit 100;

-- 일치 정보 조회
select count (sx.station_nm) 
from m1.subway s 
   , m1.subway_xy sx 
where s.station_nm = sx.station_nm
and s.line_nm = sx.line_nm 
--  and s.base_ym = '2022018'
;

-- 중복조회
SELECT atclno, cortarno, atclstatcd, rlettpcd, COUNT(*) as cnt
FROM m1.asking_price
GROUP BY atclno, cortarno, atclstatcd, rlettpcd
HAVING COUNT(atclno) > 1 AND COUNT(cortarno) > 1 AND COUNT(atclstatcd) > 1 AND COUNT(rlettpcd) > 1
;

-- PNU별 인구합
select substring(bd_mgt_sn, 0, 20), sum(f_tot)
from m1.kt_bldg_xy_info 
where base_ym between 202001 and 202012
group by substring(bd_mgt_sn, 0, 20)
;

-- 컬럼 추가
alter table m1.rtms_trade add column floor_ varchar(4);

-- 컬럼 삭제
--alter table m1.rtms_trade drop column floor_;

-- 로 추가
insert into m1.rtms_trade values ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1');

-- 로 삭제
--delete from m2.cremao_bus where base_ym is not null;

-- 데이터 타입 변경
ALTER TABLE m1.subway
ALTER COLUMN line_nm TYPE varchar(50);

-- 키 설정
 ALTER TABLE m1.convert_rate 
 ALTER distkey region_cd
,ALTER compound sortkey (research_date, region_cd, buld_gbn);

-- 값 변경
UPDATE m1.building_permit_info 
   SET jigucdnm = null 
 WHERE jigucdnm = ' ';




