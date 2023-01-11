-- 테이블 생성
--drop table if exists m2.cremao_permit_point;
create table m2.cremao_permit (
base_ym	varchar(6)
,mgm_bldrgst_pk	varchar(33)
,mgm_bldrgst_flr_pk	varchar(33)
,pnu	varchar(19)
,bjdong_cd	varchar(5)
,main_purps_cd_nm	varchar(200)
,prpos_area_dstrc_nm	varchar(300)
,jimok	varchar(200)
,atch_gb_cd_nm	varchar(100)
,bld_nm	varchar(200)
,plat_area	double precision
,arch_area	double precision
,bc_rat	double precision
,tot_area	double precision
,vl_rat	double precision
,vl_rat_estm_tot_area	double precision
,main_bld_cnt	bigint
,atch_bld_dong_cnt	bigint
,stcns_sched_day	date
,stcns_delay_day	date
,real_stcns_day	date
,arch_pms_day	date
,use_apr_day	date
);

--delete from m2.cremao_permit_point where 1=1;

create table m2.cremao_permit_point (
mgm_bldrgst_pk        varchar(33)
,pnu        varchar(19)
,point        geography
);





select *
from m2.cremao_permit_point
where 1=1
--and base_ym = '202211'
--and mgm_bldrgst_pk='11110-100042751'
and pnu like '11110109001000100%'
--and poly isnull
limit 10
;

select *
from m2.cremao_land
where 1=1
and pnu like '11110109001000100%'
limit 10
;

select *
from m1.pnu p
where pnu like '111101090010001%'
limit 10;

-- 1111010900100010033 / 1111010900100010033 / 서울특별시 종로구 누상동 산 1-33번지 / pnu.서울특별시 종로구 누상동 1-1
select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, *
from m1.building_permit_flr_info 
where mgm_bldrgst_pk='11110-100042751'
limit 10;


-- 모집단

--select t1.mgm_bldrgst_pk
--	, case when t1.pnu isnull then t2.pnu else t1.pnu end as pnu
--	, t3.poly as point -- point insert test
with date as (
    select '202211'::text as base_ym
)
select count(*)
from (
    select table1.*
    from (
    -- 건축인허가 (건물단위)
	    select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, *
	    from m1.building_permit_info
        where arch_gb_cd_nm in ('신축','증축','개축','대수선','용도변경','이전') -- 허가구분 조건
	    and arch_pms_day >= 2020-01-01 -- 허가일 기준 3년 데이터
	    and base_ym = (select base_ym from date) -- 기준월
	    and substring(pnu, 1, 2) = '11' -- 시도 ======================================================================================
    )as table1
    -- PNU 존재
    join m2.cremao_land as table2
        on table1.pnu = table2.pnu
    -- 건물 존재
    join (
        select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
        from m1.bld_rgst as table3
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
    ) T3
        on table1.pnu = table2.pnu
) as t1
left join ( 
	select pnu
         , ST_Transform(ST_SetSRID(poly::geometry, 5174), 4326)::geography as poly
    from m1.pnu
    where 1=1
        and substring(pnu, 1, 2) = '27' -- 시도 
) t3
	on t1.pnu = t3.pnu
limit 100;










-- 인허가 메인 쿼리 (permit, point)
--insert into m2.cremao_permit_point (
with date as (
    select '202211'::text as base_ym
)
select t1.mgm_bldrgst_pk, case when t1.pnu isnull then t2.pnu else t1.pnu end as pnu, t3.poly as point -- point insert test
--select count(*)
--select (select base_ym from date) as base_ym (notnull)
--	, t1.mgm_bldrgst_pk, t2.mgm_bldrgst_flr_pk -- PK (notnull)
--	, case when t1.pnu isnull then t2.pnu else t1.pnu end as pnu -- pnu  (notnull)
--	, t1.bjdong_cd -- 법정동 코드 (notnull)
--	, case when t2.main_purps_cd_nm isnull then t1.main_purps_cd_nm else t2.main_purps_cd_nm end as main_purps_cd_nm -- 주용도 (notnull)
--	, t4.prpos_area_dstrc_nm -- 용도지역 (null : 37472304)
--	, t3.jimok -- 지목 (nul: 37434779)
--	, t2.atch_gb_cd_nm -- 허가구분 (nul: 30770)
--	, case when t2.bld_nm isnull then t1.bld_nm else t2.bld_nm end as bld_nm -- 건물명 (null : 8629999)
--	, t1.plat_area, t1.arch_area, t1.bc_rat, t1.tot_area, t1.vl_rat_estm_tot_area, t1.vl_rat, t1.main_bld_cnt, t1.atch_bld_dong_cnt -- 건물 정보  (notnull)
--	, t1.stcns_sched_day, t1.stcns_delay_day, t1.real_stcns_day, t1.arch_pms_day, t1.use_apr_day -- 날짜 관련 (arch_pms_day is notnull, 나머지는 널값 많음) 
--	, t3.poly as point -- cremao_permit_point 에만 적재 (null : 37434676)
from (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, *
	from m1.building_permit_info
	where arch_gb_cd_nm in ('신축','증축','개축','대수선','용도변경','이전') -- 허가구분 조건
	and arch_pms_day >= 2020-01-01 -- 허가일 기준 3년 데이터
	and base_ym = (select base_ym from date) -- 기준월
	and substring(pnu, 1, 2) = '44' -- 시도 ======================================================================================
) as t1
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, *
	from m1.building_permit_flr_info
	where base_ym = (select base_ym from date) -- 기준월
	and substring(pnu, 1, 2) = '44' -- 시도 ======================================================================================
) as t2
	on t1.mgm_bldrgst_pk = t2.mgm_bldrgst_pk
left join (
	select pnu
         , case when right(jibun_jimok, 1) in ('전','답','과','목','임','광','염','대','장','학','차','주','창','도','철','제','천','구','유','양','수','공','체','원','종','사','묘','잡') 
                then right(jibun_jimok, 1) end as jimok
         , ST_Transform(ST_SetSRID(poly::geometry, 5174), 4326)::geography as poly
    from m1.pnu
    where 1=1
        and substring(pnu, 1, 2) = '44' -- 시도 
) t3
	on nvl(t1.pnu, t2.pnu) = t3.pnu
left join (
    select pnu
         , listagg(prpos_area_dstrc_nm, ',') within group (order by prpos_area_dstrc_cd) as prpos_area_dstrc_nm
    from (
        select distinct pnu
                      , prpos_area_dstrc_cd
                      , prpos_area_dstrc_nm
        from m1.land_use
        where 1=1
            and substring(pnu, 1, 2) = '44' -- 시도 
            and prpos_area_dstrc_cd in ('UQA111','UQA112','UQA121','UQA122','UQA123',
                                        'UQA130','UQA210','UQA220','UQA230','UQA240',
                                        'UQA310','UQA320','UQA330','UQA410','UQA420',
                                        'UQA430','UQB300','UQB200','UQB100','UQC001','UQD001')
    )
    group by 1
) t4
	on nvl(t1.pnu, t2.pnu, t3.pnu) = t4.pnu
where t1.pnu notnull and t2.pnu notnull
limit 50
--)
;





-- data type table
drop table if exists m1.tmp;
create table m1.tmp (
 day_date	date
,day_varchar	varchar(100)
);

select *
from m1.tmp
limit 10;

insert into m1.tmp (
select distinct stcns_sched_day, stcns_sched_day
from m1.building_permit_info
where base_ym = '202211'
limit 50
);

select distinct stcns_sched_day, stcns_sched_day
from m1.building_permit_info
where base_ym = '202211'
limit 50;


