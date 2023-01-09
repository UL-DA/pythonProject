-- test1
with date as (
    select '202211'::text as base_ym
)
select *
from (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, *
	from m1.building_permit_info
	where arch_gb_cd_nm in ('신축','증축','개축','대수선','용도변경','이전') -- 기획서 조건 반영
	and arch_pms_day > 2020-01-01 -- 허가일 기준 3년 데이터
	and base_ym = (select base_ym from date) -- 기준월
	and mgm_bldrgst_pk = '44130-100154598'
) as t1
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, *
	from m1.building_permit_flr_info
	where base_ym = (select base_ym from date) -- 기준월 
	and mgm_bldrgst_pk = '44130-100154598'
) as t2
	on t1.mgm_bldrgst_pk = t2.mgm_bldrgst_pk
where t1.pnu notnull and t2.pnu notnull
limit 50;


-- test2
with date as (
    select '202211'::text as base_ym
)
select case when t2.main_purps_cd_nm isnull then t1.main_purps_cd_nm else t2.main_purps_cd_nm end -- 주용도
from (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, *
	from m1.building_permit_info
	where arch_gb_cd_nm in ('신축','증축','개축','대수선','용도변경','이전') -- 허가구분 조건
	and arch_pms_day > 2020-01-01 -- 허가일 기준 3년 데이터
	and base_ym = (select base_ym from date) -- 기준월
	and substring(sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji, 1, 2) = '44' -- test =============================================================
) as t1
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, *
	from m1.building_permit_flr_info
	where base_ym = (select base_ym from date) -- 기준월
	and substring(sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji, 1, 2) = '44' -- test =============================================================
) as t2
	on t1.mgm_bldrgst_pk = t2.mgm_bldrgst_pk
limit 10;



with date as (
    select '202211'::text as base_ym
)
select distinct *
from (
	select atch_gb_cd_nm
	from m1.building_permit_flr_info
	where base_ym = (select base_ym from date) -- 기준월
	and substring(sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji, 1, 2) = '44' -- test =============================================================
)
;

with date as (
    select '202211'::text as base_ym
)
select distinct mgm_bldrgst_pk, atch_gb_cd_nm
from m1.building_permit_flr_info
where base_ym = (select base_ym from date) -- 기준월
and substring(sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji, 1, 2) = '44' -- test =============================================================
limit 100;



-- 인허가 메인 쿼리 (permit, point)
with date as (
    select '202211'::text as base_ym
)
--select count(*)
select case when t1.pnu isnull then t2.pnu else t1.pnu end -- pnu 
	, '202211' as base_ym
	, t1.mgm_bldrgst_pk, t2.mgm_bldrgst_flr_pk -- PK
	, t1.bjdong_cd -- 법정동 코드
	, case when t2.main_purps_cd_nm isnull then t1.main_purps_cd_nm else t2.main_purps_cd_nm end -- 주용도
	, t1.arch_gb_cd_nm
--	, case when t2.arch_gb_cd_nm isnull then t1.arch_gb_cd_nm else t2.arch_gb_cd_nm end -- 허가구분
	, t3.jimok -- 지목
	, t4.prpos_area_dstrc_nm -- 용도지역
	, case when t2.bld_nm isnull then t1.bld_nm else t2.bld_nm end -- 건물명
	, t1.plat_area, t1.arch_area, t1.bc_rat, t1.tot_area, t1.vl_rat_estm_tot_area, t1.vl_rat, t1.main_bld_cnt, t1.atch_bld_dong_cnt -- 건문 정보
	, t1.stcns_sched_day, t1.stcns_delay_day, t1.real_stcns_day, t1.arch_pms_day, t1.use_apr_day -- 날짜 관련
	, t3.poly -- cremao_permit_point 에만 적재
from (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, *
	from m1.building_permit_info
	where arch_gb_cd_nm in ('신축','증축','개축','대수선','용도변경','이전') -- 허가구분 조건
	and arch_pms_day > 2020-01-01 -- 허가일 기준 3년 데이터
	and base_ym = (select base_ym from date) -- 기준월
	and substring(sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji, 1, 2) = '44' -- test =============================================================
) as t1
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, *
	from m1.building_permit_flr_info
	where base_ym = (select base_ym from date) -- 기준월
	and substring(sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji, 1, 2) = '44' -- test =============================================================
) as t2
	on t1.mgm_bldrgst_pk = t2.mgm_bldrgst_pk
left join (
	select pnu
         , case when right(jibun_jimok, 1) in ('전','답','과','목','임','광','염','대','장','학','차','주','창','도','철','제','천','구','유','양','수','공','체','원','종','사','묘','잡') 
                then right(jibun_jimok, 1) end as jimok
         , ST_Transform(ST_SetSRID(poly::geometry, 5174), 4326)::geography as poly
    from m1.pnu
    where 1=1
        and substring(pnu, 1, 2) = '44' -- 시도 for문용 
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
            and substring(pnu, 1, 2) = '44' -- 시도 for문용
            and prpos_area_dstrc_cd in ('UQA111','UQA112','UQA121','UQA122','UQA123',
                                        'UQA130','UQA210','UQA220','UQA230','UQA240',
                                        'UQA310','UQA320','UQA330','UQA410','UQA420',
                                        'UQA430','UQB300','UQB200','UQB100','UQC001','UQD001')
    )
    group by 1
) t4
	on nvl(t1.pnu, t2.pnu, t3.pnu) = t4.pnu
left join (
	select distinct mgm_bldrgst_pk, atch_gb_cd_nm
	from m1.building_permit_flr_info
	where base_ym = (select base_ym from date) -- 기준월
	and substring(sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji, 1, 2) = '44' -- test =============================================================
)
where t1.pnu notnull and t2.pnu notnull
limit 50;



