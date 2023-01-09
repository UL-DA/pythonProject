-- 모집단 (실제로 존재하는 PNU 데이터 뽑기)
with date as (
    select '202208' as base_ym
)
select A.ftc_cate2_cd, A.pred_slng_amt, substring(A.bd_mgt_sn, 1, 19), B.poly, C.tot_area
from (-- 건물당 매출액, 업종코드 
	select *
	from m1.kt_bldg_sales 
	where base_ym = (select base_ym from date)
	) A
join m1.pnu B -- 반경 계산할 폴리곤 or 실제 pnu 확인용
	on substring(A.bd_mgt_sn, 1, 19) = B.pnu
join (-- 연면적 조인	
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, sum(tot_area) as tot_area
	from m1.bld_rgst
	where base_ym = (select base_ym from date)
	group by 1
) C
	on substring(A.bd_mgt_sn, 1, 19) = C.pnu
limit 10
;

--left join m1.kt_bldg_base D -- 연면적
--	on 1=1
--		and A.bd_mgt_sn = D.bd_mgt_sn
--		and A.base_ym   = D.base_ym


-- 평균 소득
select cur_lgl_dong_cd||'00' as emd_nm, avg(avg_mon_income) as income_avg
  from m1.kcb_stat_cm
 where bs_yr_mon = '202209'
 group by cur_lgl_dong_cd
 limit 10
;

-- pnu별 연면적
select sigungu_cd||bjdong_cd||case when plat_gb_cd = '1' then '2' else '1' end||bun||ji as pnu, avg(tot_area) as avg_area
  from m1.bld_rgst
 where main_purps_cd_nm not in 
    (
    select distinct main_purps_cd_nm
    from m1.bld_rgst
    where main_purps_cd_nm like '%주택%'
    )
   and base_ym = '202209'
 group by sigungu_cd||bjdong_cd||case when plat_gb_cd = '1' then '2' else '1' end||bun||ji
limit 10;

-- pnu별 연면적 (최종본)
select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, avg(tot_area) as avg_area, substring(pnu,0,11) as emd_cd
  from m1.bld_rgst
 where main_purps_cd_nm not like '%주택%'
   and base_ym = '202209'
 group by sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji
 limit 10;

-- 법정동 단위 거주인구
select cur_lgl_dong_cd, pop_cnt
  from m1.kcb_stat_cm 
 where bs_yr_mon = '202209'
limit 10
;

-- 주용도명 
select sigungu_cd||bjdong_cd||case when plat_gb_cd = '1' then '2' else '1' end||bun||ji as pnu, main_purps_cd_nm
  from m1.bld_rgst
 limit 10
;

--[pnu 생성] sigungu_cd||bjdong_cd||case when plat_gb_cd = '1' then '2' else '1' end||bun||ji as pnu
select tot_area, sigungu_cd||bjdong_cd||case when plat_gb_cd = '1' then '2' else '1' end||bun||ji as pnu
  from m1.bld_rgst
 where main_purps_cd_nm not in 
	(
	select distinct main_purps_cd_nm
	from m1.bld_rgst
	where main_purps_cd_nm like '%주택%'
	)
 and base_ym = '202209'
limit 10
;

-- pnu 별 상업용 부동산 수
select count(mgm_bldrgst_pk), sigungu_cd||bjdong_cd||case when plat_gb_cd = '1' then '2' else '1' end||bun||ji as pnu
  from m1.bld_rgst
 where main_purps_cd_nm not in 
	(
	select distinct main_purps_cd_nm
	from m1.bld_rgst
	where main_purps_cd_nm like '%주택%'
	)
group by sigungu_cd||bjdong_cd||case when plat_gb_cd = '1' then '2' else '1' end||bun||ji
limit 10
;




-- 예측분양가 테이블 생성
--drop table if exists m2.datadam_predict_price;
create table m2.datadam_predict_price (
 base_ym	varchar(6)
,pnu		varchar(19)
,emd_cd		varchar(8)
,price		int8
,create_at	date
,update_at	date
,work_user	varchar(15)
)
compound sortkey(base_ym, pnu);
commit;

select count(*) from m2.datadam_predict_price;

-- 예측분양가 쿼리 ver1
select pnu, substring(pnu,1,10) as emd_cd, round((min_price_1 + max_price_1)/2,0) as price 
  from m2.cremao_price
 where base_ym = '202208';

-- 예측분양가 쿼리 ver2
with date as (
    select '202208' as base_ym
)
select A.pnu, A.emd_cd, A.price
from (-- PNU별 가치환원법
	select pnu, substring(pnu,1,8) as emd_cd, round((min_price_1 + max_price_1)/2,0) as price
	from m2.cremao_price A -- 예측 분양가
	where base_ym = (select base_ym from date)
	) A
join m1.pnu B -- 실제 PNU 확인
	on substring(A.pnu, 1, 19) = B.pnu
join (-- 실제 건물 확인	
	select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
	from m1.bld_rgst
	where base_ym = (select base_ym from date)
) C
	on substring(A.pnu, 1, 19) = C.pnu
limit 10;

-- 예측분양가 쿼리 ver3
with date as (
    select '202208' as base_ym
)
select A.base_ym
	 , A.pnu
	 , A.emd_cd
	 , A.price
	 , sysdate::date as create_at
     , sysdate::date as update_at
     , 'du.Park' as work_user
from (-- PNU별 가치환원법
	select pnu, substring(pnu,1,8) as emd_cd, round((min_price_1 + max_price_1)/2,0) as price, base_ym
	from m2.cremao_price A -- 예측 분양가
	where base_ym = (select base_ym from date)
	) A
join m1.pnu B -- 실제 PNU 확인
	on substring(A.pnu, 1, 19) = B.pnu
join (-- 실제 건물 확인	
	select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
	from m1.bld_rgst
	where base_ym = (select base_ym from date)
) C
	on substring(A.pnu, 1, 19) = C.pnu
limit 10;

-- 예측분양가 쿼리 ver4 (FINAL)
insert into m2.datadam_predict_price (
	with date as (
	    select '202208' as base_ym
	)
	select A.base_ym
		 , A.pnu
		 , A.emd_cd
		 , A.price
		 , sysdate::date as create_at
	     , sysdate::date as update_at
	     , 'du.Park' as work_user
	from (-- PNU별 가치환원법
		select pnu, substring(pnu,1,8) as emd_cd, round((min_price_1 + max_price_1)/2,0) as price, base_ym
		from m2.cremao_price A -- 예측 분양가
		where base_ym = (select base_ym from date)
		) A
	join m1.pnu B -- 실제 PNU 확인
		on substring(A.pnu, 1, 19) = B.pnu
	join (-- 실제 건물 확인	
		select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
		from m1.bld_rgst
		where base_ym = (select base_ym from date)
	) C
		on substring(A.pnu, 1, 19) = C.pnu
);




-- 면적당 매출액
--drop table if exists m2.datadam_sales_per_area;
create table m2.SALES_PER_AREA (    
PNU varchar(19)
, EMD_CD varchar(8)
, INDUSTRY_CD varchar(10)
, SALES double precision
, BASE_YM varchar(6)
)
distkey(PNU)
compound sortkey(EMD_CD, INDUSTRY_CD, BASE_YM);
commit;

-- 상업용 부동산 면적당 업종별 매출액 ver1
select t1.pnu, t1.emd_cd, t1.ftc_cate2_cd, t1.sales, t2.gross_area
from (
	select substring (bd_mgt_sn, 0, 20) as pnu, pred_slng_amt as sales, ftc_cate2_cd, emd_cd||'00' as emd_cd
	  from m1.kt_bldg_sales
	 where base_ym = '202209'
	)as t1
left join (
	select bd_mgt_sn as pnu, emd_cd||'00' as emd_cd, gross_area
	  from m1.kt_bldg_base
	 where base_ym = '202209'
	   and bdtyp_nm not like '%주택%'
	) as t2
  on t1.emd_cd = t2.emd_cd
limit 10
;

-- 면적당 매출액 ver2
select *
from (
	select substring (bd_mgt_sn, 0, 20) as pnu, pred_slng_amt as sales, ftc_cate2_cd, emd_cd||'00' as emd_cd
	  from m1.kt_bldg_sales
	 where base_ym = '202209'
	)as t1
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, avg(tot_area) as avg_area, substring(pnu,0,11) as emd_cd
	  from m1.bld_rgst
	 where main_purps_cd_nm not like '%주택%'
	   and base_ym = '202209'
	 group by sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji
	) as t2
  on t1.emd_cd = t2.emd_cd
limit 10
;

-- 면적당 매출액 ver3 (계산해서 + emd_cd로 잘라서 가져오기)
select distinct emd_cd from m1.pnu; -- for 돌릴 pnu 값 가져오기 

with date as (
    select '202209' as base_ym
)
select substring(A.bd_mgt_sn, 1, 19) as pnu
	 , B.emd_cd
	 , A.ftc_cate2_cd
	 , case 
	 	when A.pred_slng_amt > 0 and C.tot_area > 0 then round(A.pred_slng_amt/C.tot_area, 2)
	 	else 0 -- 면적이나 매출액 중 한 개라도 null인 경우 0으로 처리
	 end as sales_per_area
	 , B.poly
from ( -- 건물당 매출액, 업종코드 
	select *
	from m1.kt_bldg_sales 
	where base_ym = (select base_ym from date)
	  and pred_slng_amt notnull 
	  and pred_slng_amt > 0
	) A
join m1.pnu B -- 반경 계산할 폴리곤 조인
	on substring(A.bd_mgt_sn, 1, 19) = B.pnu
join (-- 연면적 조인	
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, sum(tot_area) as tot_area
	from m1.bld_rgst
	where base_ym = (select base_ym from date)
	  and tot_area notnull
	  and tot_area > 0
	group by 1
) C
	on substring(A.bd_mgt_sn, 1, 19) = C.pnu
where B.emd_cd = '3114010100'
limit 50
;

-- 면적당 매출액 ver4 (계산해서 가져오기) (final)
with date as (
    select '202209' as base_ym
)
select substring(A.bd_mgt_sn, 1, 19) as pnu, B.emd_cd, A.ftc_cate2_cd, round(A.pred_slng_amt/C.tot_area, 0) as sales_per_area
from ( -- 건물당 매출액, 업종코드 
	select *
	from m1.kt_bldg_sales 
	where base_ym = (select base_ym from date)
	  and pred_slng_amt notnull 
	  and pred_slng_amt > 0
	) A
join m1.pnu B -- 실제 pnu 여부 확인
	on substring(A.bd_mgt_sn, 1, 19) = B.pnu
join (-- 실제 건물 여부 확인
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu, sum(tot_area) as tot_area
	from m1.bld_rgst
	where base_ym = (select base_ym from date)
	  and tot_area notnull
	  and tot_area > 0
	group by 1
) C
	on substring(A.bd_mgt_sn, 1, 19) = C.pnu
limit 50
;



-- 1. 젠트리피케이션
--drop table if exists m2.datadam_gentrificastion_score;
create table m2.datadam_gentrificastion_score (    
base_ym varchar(6)
, pnu varchar(19)
, emd_cd varchar(8)
, score double precision
, create_at date
, update_at date
, work_user varchar(15)
)
compound sortkey(base_ym, pnu);
commit;

-- z-score test 
with sales_stats as (
    select avg(sale_12m) as mean, stddev(sale_12m) as std
    from m2.ibk_pnu_01
)
select round((sale_12m - sales_stats.mean) / sales_stats.std,4) as z_score_sales
from m2.ibk_pnu_01, sales_stats
limit 10;

-- 젠트리피케이션 ver1
with sale_stats as
    (select avg(sale_12m) as mean, stddev(sale_12m) as std
    from m2.ibk_pnu_01 where base_ym = (select base_ym from date)),
    comp_stats as
    (select avg(comp_12m) as mean, stddev(comp_12m) as std
    from m2.ibk_pnu_01 where base_ym = (select base_ym from date)),
    fltg_stats as
    (select avg(fltg_12m) as mean, stddev(fltg_12m) as std
    from m2.ibk_pnu_01 where base_ym = (select base_ym from date)),
    wpop_stats as
    (select avg(wpop_12m) as mean, stddev(wpop_12m) as std
    from m2.ibk_pnu_01 where base_ym = (select base_ym from date)),
    lpop_stats as
    (select avg(lpop_12m) as mean, stddev(lpop_12m) as std
    from m2.ibk_pnu_01 where base_ym = (select base_ym from date)),
    date as (
    select '202209' as base_ym)
select A.pnu, substring(A.pnu, 1, 10) as emd_cd, A.score --(A.sale_score + A.comp_score + A.fltg_score + A.wpop_score + A.lpop_score)/5
from ( -- z-score
	select pnu
		 , round(((sale_12m - sale_stats.mean) / sale_stats.std)*5 +75, 2) as sale_score
		 , round(((comp_12m - comp_stats.mean) / comp_stats.std)*5 +75, 2) as comp_score
		 , round(((fltg_12m - fltg_stats.mean) / fltg_stats.std)*5 +75, 2) as fltg_score
		 , round(((wpop_12m - wpop_stats.mean) / wpop_stats.std)*5 +75, 2) as wpop_score
		 , round(((lpop_12m - lpop_stats.mean) / lpop_stats.std)*5 +75, 2) as lpop_score
		 , (sale_score + comp_score + fltg_score + wpop_score + lpop_score)/5 as score
	from m2.ibk_pnu_01, sale_stats, comp_stats, fltg_stats, wpop_stats, lpop_stats
	where base_ym = (select base_ym from date)
	) A
join m1.pnu B -- 실제 pnu 여부 확인
	on A.pnu = B.pnu
join (-- 실제 건물 여부 확인
	select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
	from m1.bld_rgst
	where base_ym = (select base_ym from date)
) C
	on A.pnu = C.pnu
;

-- 젠트리피케이션 ver2
select A.pnu
	 , substring(A.pnu, 1, 10) as emd_cd
	 , case when
	   round(
		 (
			   (((A.sale_12m - B.sale_12m_avg) / B.sale_12m_std)*5 + 75)
			 + (((A.comp_12m - B.comp_12m_avg) / B.comp_12m_std)*5 + 75)
			 + (((A.fltg_12m - B.fltg_12m_avg) / B.fltg_12m_std)*5 + 75)
			 + (((A.wpop_12m - B.wpop_12m_avg) / B.wpop_12m_std)*5 + 75)
			 + (((A.lpop_12m - B.lpop_12m_avg) / B.lpop_12m_std)*5 + 75)
		 )/5 -- 각 pnu별 평균
	 , 4) 
	  > 100 then 100 else
	  round(
		 (
			   (((A.sale_12m - B.sale_12m_avg) / B.sale_12m_std)*5 + 75)
			 + (((A.comp_12m - B.comp_12m_avg) / B.comp_12m_std)*5 + 75)
			 + (((A.fltg_12m - B.fltg_12m_avg) / B.fltg_12m_std)*5 + 75)
			 + (((A.wpop_12m - B.wpop_12m_avg) / B.wpop_12m_std)*5 + 75)
			 + (((A.lpop_12m - B.lpop_12m_avg) / B.lpop_12m_std)*5 + 75)
		 )/5 -- 각 pnu별 평균
	 , 4) end
	  as score -- 소수점 4째 자리까지 표기
from ( -- base table
	select *
	from m2.ibk_pnu_01
	where base_ym = '202209'
	  and sale_12m > 0
	  and comp_12m > 0
	  and fltg_12m > 0
	  and wpop_12m > 0
	  and lpop_12m > 0
) A
left join (
	select avg(case when sale_12m > 0 then sale_12m end) as sale_12m_avg
		 , stddev(case when sale_12m > 0 then sale_12m end) as sale_12m_std
		 , avg(case when comp_12m > 0 then comp_12m end) as comp_12m_avg
		 , stddev(case when comp_12m > 0 then comp_12m end) as comp_12m_std
		 , avg(case when fltg_12m > 0 then fltg_12m end) as fltg_12m_avg
		 , stddev(case when fltg_12m > 0 then fltg_12m end) as fltg_12m_std
		 , avg(case when wpop_12m > 0 then wpop_12m end) as wpop_12m_avg
		 , stddev(case when wpop_12m > 0 then wpop_12m end) as wpop_12m_std
		 , avg(case when lpop_12m > 0 then lpop_12m end) as lpop_12m_avg
		 , stddev(case when lpop_12m > 0 then lpop_12m end) as lpop_12m_std
	from m2.ibk_pnu_01
	where base_ym = '202209'
) B
	on 1=1
join m1.pnu C -- 실제 pnu 여부 확인
	on A.pnu = C.pnu
join (        -- 실제 건물 여부 확인
	select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
	from m1.bld_rgst
	where base_ym = '202209'
) D
	on A.pnu = D.pnu
;

-- 젠트리피케이션 ver3 (final)
with date as (
	select '202209'::text as base_ym
)
select A.pnu
	 , substring(A.pnu, 1, 8) as emd_cd
	 , case when round((((A.sale_12m - D.sale_12m_avg) / D.sale_12m_std * 5 + 75)
					  + ((A.comp_12m - D.comp_12m_avg) / D.comp_12m_std * 5 + 75)
					  + ((A.fltg_12m - D.fltg_12m_avg) / D.fltg_12m_std * 5 + 75)
					  + ((A.wpop_12m - D.wpop_12m_avg) / D.wpop_12m_std * 5 + 75)
					  + ((A.lpop_12m - D.lpop_12m_avg) / D.lpop_12m_std * 5 + 75))/5, 2) > 100 then 100 
			else round((((A.sale_12m - D.sale_12m_avg) / D.sale_12m_std * 5 + 75)
					  + ((A.comp_12m - D.comp_12m_avg) / D.comp_12m_std * 5 + 75)
					  + ((A.fltg_12m - D.fltg_12m_avg) / D.fltg_12m_std * 5 + 75)
					  + ((A.wpop_12m - D.wpop_12m_avg) / D.wpop_12m_std * 5 + 75)
					  + ((A.lpop_12m - D.lpop_12m_avg) / D.lpop_12m_std * 5 + 75))/5, 2) end as score
from (
	select *
	from m2.ibk_pnu_01
	where 1=1
		and base_ym = (select base_ym from date)
		and sale_12m > 0 and comp_12m > 0 and fltg_12m > 0 and wpop_12m > 0 and lpop_12m > 0
) A
join m1.pnu B
	on A.pnu = B.pnu
join (
	select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
	from m1.bld_rgst
	where base_ym = (select base_ym from date)
) C
	on A.pnu = C.pnu
left join (
	select avg(sale_12m) as sale_12m_avg
		 , avg(comp_12m) as comp_12m_avg
		 , avg(fltg_12m) as fltg_12m_avg
		 , avg(wpop_12m) as wpop_12m_avg
		 , avg(lpop_12m) as lpop_12m_avg
		 , stddev(sale_12m) as sale_12m_std
		 , stddev(comp_12m) as comp_12m_std
		 , stddev(fltg_12m) as fltg_12m_std
		 , stddev(wpop_12m) as wpop_12m_std
		 , stddev(lpop_12m) as lpop_12m_std
	from m2.ibk_pnu_01
	where 1=1
		and base_ym = (select base_ym from date)
		and sale_12m > 0 and comp_12m > 0 and fltg_12m > 0 and wpop_12m > 0 and lpop_12m > 0
) D
	on 1=1
limit 100;

-- 젠트리피케이션 최종
with date as (
    select '""" + date + """'::text as base_ym
)
select (select base_ym from date) as base_ym
     , A.pnu
     , substring(A.pnu, 1, 8) as emd_cd
     , case when 
            round(
                    (
                        ((avg(B.sale_12m) - avg(C.sale_12m_avg)) / avg(C.sale_12m_std) * 5 + 75) +
                        ((avg(B.comp_12m) - avg(C.comp_12m_avg)) / avg(C.comp_12m_std) * 5 + 75) +
                        ((avg(B.fltg_12m) - avg(C.fltg_12m_avg)) / avg(C.fltg_12m_std) * 5 + 75) +
                        ((avg(B.lpop_12m) - avg(C.lpop_12m_avg)) / avg(C.lpop_12m_std) * 5 + 75) +
                        ((avg(B.wpop_12m) - avg(C.wpop_12m_avg)) / avg(C.wpop_12m_std) * 5 + 75)
                    ) / 5, 2
                 ) > 100 then 100
            else
            round(
                    (
                        ((avg(B.sale_12m) - avg(C.sale_12m_avg)) / avg(C.sale_12m_std) * 5 + 75) +
                        ((avg(B.comp_12m) - avg(C.comp_12m_avg)) / avg(C.comp_12m_std) * 5 + 75) +
                        ((avg(B.fltg_12m) - avg(C.fltg_12m_avg)) / avg(C.fltg_12m_std) * 5 + 75) +
                        ((avg(B.lpop_12m) - avg(C.lpop_12m_avg)) / avg(C.lpop_12m_std) * 5 + 75) +
                        ((avg(B.wpop_12m) - avg(C.wpop_12m_avg)) / avg(C.wpop_12m_std) * 5 + 75)
                    ) / 5, 2
                 ) end as score
    , sysdate::date as create_at
    , sysdate::date as update_at
    , 'du.Park' as work_user
from (
    -- 모집단 가져오기 : KT매출 & PNU존재 & 건물존재
    select T1.pnu
         , ST_Centroid(T2.poly::geometry) as poly
    from (
        -- KT매출 존재
        select distinct substring(bd_mgt_sn, 1, 19) as pnu
        from m1.kt_bldg_sales
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
            and substring(bd_mgt_sn, 1, 5) = '""" + str(i) + """' -- 시군구
    ) T1
    -- PNU 존재
    join m2.cremao_land T2
        on T1.pnu = T2.pnu
    -- 건물 존재
    join (
        select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
        from m1.bld_rgst br 
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
    ) T3
        on T1.pnu = T3.pnu
) A
left join (
    -- 반경 150m 데이터 가져오기
    select ST_Centroid(T2.poly::geometry) as poly
         , T1.sale_12m, T1.comp_12m, T1.fltg_12m, T1.lpop_12m, T1.wpop_12m
    from (
        -- 증감률 데이터
        select *
        from m2.ibk_pnu_01 
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
            and sale_12m > 0 and comp_12m > 0 and fltg_12m > 0 and wpop_12m > 0 and lpop_12m > 0 -- 특이값 제외
            and substring(pnu, 1, 5) = '""" + str(i) + """' -- 시군구
    ) T1
    -- polygon
    join m2.cremao_land T2
        on T1.pnu = T2.pnu
) B
    on ST_DistanceSphere(A.poly, B.poly) < 150 -- 반경 150m PNU
left join (
    -- 지역평균, 표준편차 가져오기
    select avg(sale_12m) as sale_12m_avg
         , avg(comp_12m) as comp_12m_avg
         , avg(fltg_12m) as fltg_12m_avg
         , avg(wpop_12m) as wpop_12m_avg
         , avg(lpop_12m) as lpop_12m_avg
         , stddev(sale_12m) as sale_12m_std
         , stddev(comp_12m) as comp_12m_std
         , stddev(fltg_12m) as fltg_12m_std
         , stddev(wpop_12m) as wpop_12m_std
         , stddev(lpop_12m) as lpop_12m_std
    from m2.ibk_pnu_01
    where 1=1
        and base_ym = (select base_ym from date) -- 기준월
        and sale_12m > 0 and comp_12m > 0 and fltg_12m > 0 and wpop_12m > 0 and lpop_12m > 0 -- 특이값 제외
        and substring(pnu, 1, 5) = '""" + str(i) + """' -- 시군구
) C
    on 1=1
group by 1, 2, 3
having score is not null -- score null 제외
);


-- 소득대비 매출액
drop table if exists m2.datadam_sales_per_income;
create table m2.datadam_sales_per_income (
pnu varchar(19)
, emd_cd varchar(10)
, industry_cd varchar(10)
, income_per_sales double precision
, create_at varchar(10)
, update_at varchar(10)
, work_user varchar(15)
)
distkey(pnu)
compound sortkey(emd_cd, create_at, update_at);
commit;

-- 소득대비 매출액 전국 ver
with date as (
  select '202209' as base_ym
)
select substring(A.bd_mgt_sn, 1, 19) as pnu, substring(A.bd_mgt_sn, 1, 10), A.ftc_cate2_cd, round(A.pred_slng_amt/D.income, 4) as sales_per_income
from (    -- 건물당 매출액, 업종코드
	select *
	from m1.kt_bldg_sales
	where base_ym = (select base_ym from date)
	and pred_slng_amt notnull
	and pred_slng_amt > 0
) A
join (    -- 반경 500m 설정
	select *
	from m1.pnu
) B
	on ST_DWithin(B.poly::geometry, B.poly::geometry, 500)
join (    -- 실제 건물 여부 확인
	select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
	from m1.bld_rgst
	where base_ym = (select base_ym from date)
) C
	on substring(A.bd_mgt_sn, 1, 19) = C.pnu
join (    -- PNU별 소득
	select pnu, (emd_mon_income * pnu_pop_cnt) as income
	from m2.live_pop
	where base_ym = (select base_ym from date)
) D
	on substring(A.bd_mgt_sn, 1, 19) = D.pnu
limit 10
;

-- 세종 test
select B.*, A.ftc_cate2_cd
from (    -- 건물당 매출액, 업종코드
	select *
	from m1.kt_bldg_sales
	where base_ym = '202209'
	and pred_slng_amt notnull
	and pred_slng_amt > 0
	limit 100
) A
join (    -- 반경 500m 설정
	select pnu, poly, area
	from m1.pnu
	where substring(pnu, 1, 2) in ('26') -- 세종 test
--	group by pnu
	limit 100
) B
	on ST_DWithin(B.poly::geometry, B.poly::geometry, 500)
;

-- 소득대비 매출액 ver1
with date as (
  select '202209' as base_ym
)
select substring(A.bd_mgt_sn, 1, 19) as pnu, substring(A.bd_mgt_sn, 1, 10), A.ftc_cate2_cd, round(A.pred_slng_amt/D.income, 4) as sales_per_income
from (    -- 건물당 매출액, 업종코드
	select *
	from m1.kt_bldg_sales
	where base_ym = (select base_ym from date)
	and pred_slng_amt notnull
	and pred_slng_amt > 0
) A
join (    -- 반경 500m 설정
	select *
	from m1.pnu
	where substring(pnu, 1, 2) in ('26') -- 세종 test
) B
	on ST_DWithin(B.poly::geometry, B.poly::geometry, 500)
join (    -- 실제 건물 여부 확인
	select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
	from m1.bld_rgst
	where base_ym = (select base_ym from date)
) C
	on substring(A.bd_mgt_sn, 1, 19) = C.pnu
join (    -- PNU별 소득
	select pnu, (emd_mon_income * pnu_pop_cnt) as income
	from m2.live_pop
	where base_ym = (select base_ym from date)
) D
	on substring(A.bd_mgt_sn, 1, 19) = D.pnu
limit 10
;

-- 소득대비 매출액 ver2 test
with date as (
	select '202209'::text as base_ym
)
select (select base_ym from date) as base_ym
	 , A.pnu
	 , substring(A.pnu, 1, 8)||'00' as emd_cd
	 , case when sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)) = 0 then 0 else round(1.0 * sum(nvl(E.tot_area, 0)) / sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)), 4) end as commercial_per_population
from (
	select pnu, poly
	from m2.cremao_land
	where 1=1
		and jimok = '대' -- 지목 '대' 조건
		and pnu = '1111010100100010000' -- 쿼리 테스트용 나중에 주석처리
) A -- 지목 '대' 토지만 추출 -> 모집단
left join (
	select pnu, poly
	from m2.cremao_land
	where substring(pnu, 1, 2) = '11' -- 쿼리 테스트용 나중에 주석처리
) B -- 모집단 PNU 기준 반경 100m 내 PNU 모두 가져오기
	on ST_DistanceSphere(ST_Centroid(A.poly::geometry), ST_Centroid(B.poly::geometry)) < 100
left join m2.live_ pop C -- 반경 100m 거주인구 -> B의 PNU랑 조인해서 가져오기
	on B.pnu = C.pnu
left join m2.work_pop D -- 반경 100m 직장인구 -> B의 PNU랑 조인해서 가져오기
	on B.pnu = D.pnu
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
		 , sum(tot_area) as tot_area
	from m1.building_permit_info
	where 1=1
		and arch_pms_day between (select dateadd(month, -11, to_date(base_ym||'01', 'yyyymmdd'))::date from date) and (select last_day(to_date(base_ym||'01', 'yyyymmdd')) from date) -- 최근1년 조건
		and (main_purps_cd_nm like '%업무%' or main_purps_cd_nm like '%근린%') -- 상업, 업무용 부동산 조건
		and arch_gb_cd_nm in ('신축','증축','재축') -- 신축, 중축, 재건축만 가져오기
	group by 1
) E -- 반경 100m 상업용부동산 공급 연면적SUM -> B의 PNU랑 조인해서 가져오기
	on B.pnu = E.pnu
group by 1, 2, 3
order by 1, 2, 3
limit 100;




-- 2. 인구당 상가면적
create table m2.datadam_area_per_population (    
pnu varchar(19)
, emd_cd varchar(10)
, area_per_population double precision
, create_at varchar(10)
, update_at varchar(10)
, work_user varchar(15)
)
distkey(pnu)
compound sortkey(emd_cd, create_at, update_at);
commit;

-- 2. [datadam_area_per_population] 배후지 인구 1인당 상업용 부동산 면적 ver1
with date as (
	select '202209'::text as base_ym
)
select (select base_ym from date) as base_ym
	 , A.pnu
	 , substring(A.pnu, 1, 8) as emd_cd
	 , round(1.0 * sum(nvl(E.tot_area, 0)) / sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)), 4) as area_per_population
from (
	select pnu, poly
	from m2.cremao_land
	where 1=1
		and jimok = '대'
) A -- 지목 '대' 토지만 추출
left join (
	select pnu, poly
	from m2.cremao_land
) B -- 반경 100m PNU 가져오기
	on ST_DistanceSphere(ST_Centroid(A.poly::geometry), ST_Centroid(B.poly::geometry)) < 100
left join m2.live_pop C -- 반경 100m 거주인구 가져오기
	on B.pnu = C.pnu
left join m2.work_pop D
	on B.pnu = D.pnu
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
		 , sum(tot_area) as tot_area
	from m1.bld_rgst
	where 1=1
		and base_ym = (select base_ym from date)
		and (main_purps_cd_nm like '%업무%' or main_purps_cd_nm like '%근린%')
	group by 1
) E -- 반경 100m 상업용부동산 연면적 가져오기
	on B.pnu = E.pnu
group by 1, 2, 3
order by 1, 2, 3
limit 100;

-- 2. 배후지 인구 1인당 상업용 부동산 면적 ver2 
with date as (
	select '202209'::text as base_ym
)
select (select base_ym from date) as base_ym
	 , A.pnu
	 , substring(A.pnu, 1, 8) as emd_cd
	 , case when sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)) = 0 then 0 else round(1.0 * sum(nvl(E.tot_area, 0)) / sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)), 4) end as area_per_population
from (
	select pnu, poly
	from m2.cremao_land
	where 1=1
		and jimok = '대' -- 지목 '대' 조건
		and pnu = '1111010100100010000' -- 쿼리 테스트용 나중에 주석처리
) A -- 지목 '대' 토지만 추출 -> 모집단
left join (
	select pnu, poly
	from m2.cremao_land
	where substring(pnu, 1, 2) = '11' -- 쿼리 테스트용 나중에 주석처리
) B -- 모집단 PNU 기준 반경 100m 내 PNU 모두 가져오기
	on ST_DistanceSphere(ST_Centroid(A.poly::geometry), ST_Centroid(B.poly::geometry)) < 100
left join m2.live_pop C -- 반경 100m 거주인구 -> B의 PNU랑 조인해서 가져오기
	on B.pnu = C.pnu
left join m2.work_pop D -- 반경 100m 직장인구 -> B의 PNU랑 조인해서 가져오기
	on B.pnu = D.pnu
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
		 , sum(tot_area) as tot_area
	from m1.bld_rgst
	where 1=1
		and base_ym = (select base_ym from date) -- 기준월 조건
		and (main_purps_cd_nm like '%업무%' or main_purps_cd_nm like '%근린%') -- 상업, 업무용 부동산 조건
	group by 1
) E -- 반경 100m 상업용부동산 연면적SUM -> B의 PNU랑 조인해서 가져오기
	on B.pnu = E.pnu
group by 1, 2, 3
order by 1, 2, 3
limit 100;

-- 2. 배후지 인구 1인당 상업용 부동산 면적 ver3 (final)
with date as (
	select '202209'::text as base_ym
)
select (select base_ym from date) as base_ym
	 , A.pnu
	 , substring(A.pnu, 1, 8) as emd_cd
--	 , case when sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)) = 0 then 0 else round(1.0 * sum(nvl(E.tot_area, 0)) / sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)), 4) end as area_per_population
from (
	select pnu, poly
	from m2.cremao_land
	where 1=1
		and jimok = '대'
) A -- 지목 '대' 토지만 추출 (모집단)
left join (
	select pnu, poly
	from m2.cremao_land
) B -- 모집단 PNU 기준 반경 100m 내 PNU 모두 가져오기
	on ST_DistanceSphere(ST_Centroid(A.poly::geometry), ST_Centroid(B.poly::geometry)) < 50
left join m2.live_pop C -- 반경 100m 거주인구
	on B.pnu = C.pnu
left join m2.work_pop D -- 반경 100m 직장인구
	on B.pnu = D.pnu
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
		 , sum(tot_area) as tot_area
	from m1.bld_rgst
	where 1=1
		and base_ym = (select base_ym from date)
		and (main_purps_cd_nm like '%업무%' or main_purps_cd_nm like '%근린%') -- 상업, 업무용 부동산 조건
	group by 1
) E -- 반경 100m 상업용부동산 연면적SUM
	on B.pnu = E.pnu
group by 1, 2, 3
order by 1, 2, 3
limit 100;



-- 3. 인구당 상가공급면적	
create table m2.datadam_commercial_per_population (    
pnu varchar(19)
, emd_cd varchar(10)
, commercial_per_population double precision
, create_at varchar(10)
, update_at varchar(10)
, work_user varchar(15)
)
distkey(pnu)
compound sortkey(emd_cd, create_at, update_at);
commit;

-- 3. [datadam_commercial_per_population] 배후지 인구 1인당 상업용 부동산 공급면적 ver1
with date as (
	select '202209'::text as base_ym
)
select (select base_ym from date) as base_ym
	 , A.pnu
	 , substring(A.pnu, 1, 8) as emd_cd
	 , round(1.0 * sum(nvl(E.tot_area, 0)) / sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)), 4) as commercial_per_population
from (
	select pnu, poly
	from m2.cremao_land
	where 1=1
		and jimok = '대'
) A -- 지목 '대' 토지만 추출
left join (
	select pnu, poly
	from m2.cremao_land
) B -- 반경 100m PNU 가져오기
	on ST_DistanceSphere(ST_Centroid(A.poly::geometry), ST_Centroid(B.poly::geometry)) < 100
left join m2.live_pop C -- 반경 100m 거주인구 가져오기
	on B.pnu = C.pnu
left join m2.work_pop D -- 반경 100m 직장인구 가져오기
	on B.pnu = D.pnu
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
		 , sum(tot_area) as tot_area
	from m1.building_permit_info
	where 1=1
		and arch_pms_day between (select dateadd(month, -11, to_date(base_ym||'01', 'yyyymmdd'))::date from date) and (select last_day(to_date(base_ym||'01', 'yyyymmdd')) from date)
		and (main_purps_cd_nm like '%업무%' or main_purps_cd_nm like '%근린%')
		and arch_gb_cd_nm in ('신축','증축','재축')
	group by 1
) E -- 반경 100m 상업용부동산 공급 연면적 가져오기(최근1년)
	on B.pnu = E.pnu
group by 1, 2, 3
order by 1, 2, 3
limit 100;

-- 3. 배후지 인구 1인당 상업용 부동산 공급면적 (설명본) ver2
with date as (
	select '202209'::text as base_ym
)
select (select base_ym from date) as base_ym
	 , A.pnu
	 , substring(A.pnu, 1, 8)||'00' as emd_cd
	 , case when sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)) = 0 then 0 else round(1.0 * sum(nvl(E.tot_area, 0)) / sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)), 4) end as commercial_per_population
from (
	select pnu, poly
	from m2.cremao_land
	where 1=1
		and jimok = '대' -- 지목 '대' 조건
		and pnu = '1111010100100010000' -- 쿼리 테스트용 나중에 주석처리
) A -- 지목 '대' 토지만 추출 -> 모집단
left join (
	select pnu, poly
	from m2.cremao_land
	where substring(pnu, 1, 2) = '11' -- 쿼리 테스트용 나중에 주석처리
) B -- 모집단 PNU 기준 반경 100m 내 PNU 모두 가져오기
	on ST_DistanceSphere(ST_Centroid(A.poly::geometry), ST_Centroid(B.poly::geometry)) < 100
left join m2.live_pop C -- 반경 100m 거주인구 -> B의 PNU랑 조인해서 가져오기
	on B.pnu = C.pnu
left join m2.work_pop D -- 반경 100m 직장인구 -> B의 PNU랑 조인해서 가져오기
	on B.pnu = D.pnu
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
		 , sum(tot_area) as tot_area
	from m1.building_permit_info
	where 1=1
		and arch_pms_day between (select dateadd(month, -11, to_date(base_ym||'01', 'yyyymmdd'))::date from date) and (select last_day(to_date(base_ym||'01', 'yyyymmdd')) from date) -- 최근1년 조건
		and (main_purps_cd_nm like '%업무%' or main_purps_cd_nm like '%근린%') -- 상업, 업무용 부동산 조건
		and arch_gb_cd_nm in ('신축','증축','재축') -- 신축, 중축, 재건축만 가져오기
	group by 1
) E -- 반경 100m 상업용부동산 공급 연면적SUM -> B의 PNU랑 조인해서 가져오기
	on B.pnu = E.pnu
group by 1, 2, 3
order by 1, 2, 3
limit 100;

-- 3. 배후지 인구 1인당 상업용 부동산 공급면적 ver3 (final)
with date as (
	select '202209'::text as base_ym
)
select (select base_ym from date) as base_ym
	 , A.pnu
	 , substring(A.pnu, 1, 8)||'00' as emd_cd
	 , case when sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)) = 0 then 0 else round(1.0 * sum(nvl(E.tot_area, 0)) / sum(nvl(C.pnu_pop_cnt, 0) + nvl(D.pnu_pop_cnt, 0)), 4) end as commercial_per_population
from (
	select pnu, poly
	from m2.cremao_land
	where 1=1
		and jimok = '대'
) A -- 지목 '대' 토지만 추출 -> 모집단
left join (
	select pnu, poly
	from m2.cremao_land
) B -- 모집단 PNU 기준 반경 100m 내 PNU 모두 가져오기
	on ST_DistanceSphere(ST_Centroid(A.poly::geometry), ST_Centroid(B.poly::geometry)) < 100
left join m2.live_pop C -- 반경 100m 거주인구
	on B.pnu = C.pnu
left join m2.work_pop D -- 반경 100m 직장인구
	on B.pnu = D.pnu
left join (
	select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
		 , sum(tot_area) as tot_area
	from m1.building_permit_info
	where 1=1
		and arch_pms_day between (select dateadd(month, -11, to_date(base_ym||'01', 'yyyymmdd'))::date from date) and (select last_day(to_date(base_ym||'01', 'yyyymmdd')) from date) -- 최근1년 조건
		and (main_purps_cd_nm like '%업무%' or main_purps_cd_nm like '%근린%') -- 상업, 업무용 부동산 조건
		and arch_gb_cd_nm in ('신축','증축','재축') -- 신축, 중축, 재건축만 가져오기
	group by 1
) E -- 반경 100m 상업용부동산 공급 연면적SUM
	on B.pnu = E.pnu
group by 1, 2, 3
order by 1, 2, 3
limit 100;





-- SNS 노출 & 유동인구 지수 
create table m2.datadam_sns_floating_population_score (
base_ym varchar(6)
, pnu varchar(19)
, emd_cd varchar(8)
, score double precision
, create_at date
, update_at date
, work_user varchar(15)
)
compound sortkey (base_ym, pnu);
commit;

-- ver1
with date as (
	select '202209'::text as base_ym
)
select substring(B.bd_mgt_sn, 0, 20) as pnu, A.emd_cd, (B.pop / A.cnt) as population_per_sns
from ( -- pnu별 유동인구
	select bd_mgt_sn, avg(f_tot) as pop
	from m1.kt_bldg_xy_info
	where base_ym = (select base_ym from date)
	group by substring(bd_mgt_sn, 0, 20)
) A
left join ( -- sns 노출 수
	select *
	from m1.instagram_emd_cnt
	where base_ym = (select base_ym from date)
) B
	on A.emd_cd = substring(B.bd_mgt_sn, 0, 20)
;

-- ver 2
insert into m2.datadam_sns_floating_population_score (
with date as (
    select '202209' as base_ym
)
select (select base_ym from date) as base_ym
     , A.pnu
     , substring(A.pnu, 1, 8) as emd_cd
     , case when round((B.cnt + C.pop)/2, 4) > 100 then 100 else round((B.cnt + C.pop)/2, 4) end as score -- (sns 노출수 + 유동인구)/2
     , sysdate::date as create_at
     , sysdate::date as update_at
     , 'du.Park' as work_user
from (
    -- 모집단 가져오기 : KT매출 & PNU존재 & 건물존재
    select T1.pnu
    from (
        -- KT매출 존재
        select distinct substring(bd_mgt_sn, 1, 19) as pnu
        from m1.kt_bldg_sales
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
            and substring(bd_mgt_sn, 1, 5) = '11110' -- 시군구
    ) T1
    -- PNU 존재
    join m2.cremao_land T2
        on T1.pnu = T2.pnu
    -- 건물 존재
    join (
        select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
        from m1.bld_rgst
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
    ) T3
        on T1.pnu = T3.pnu
) A
join ( -- sns 노출 수 join (n:1 매칭)
	select *
	from m1.instagram_emd_cnt
	where cnt > 0
) B
    on substring(A.pnu, 1, 8) = substring(B.emd_cd, 1, 8)
left join ( -- 유동인구 join (1:1 매칭)
	select substring(bd_mgt_sn, 1, 18) as pnu, avg(f_tot) as pop
	from m1.kt_bldg_xy_info
	where base_ym = (select base_ym from date) -- 기준월
	group by 1
) C
	on substring(A.pnu, 1, 18) = substring(C.pnu, 1, 18)
);

-- ver 3 (final)
--insert into m2.datadam_sns_floating_population_score (
with date as (
	select '202209'::text as base_ym
)
select (select base_ym from date) as base_ym
     , A.pnu
     , substring(A.pnu, 1, 8) as emd_cd
     , round((((case when ((B.cnt - C.cnt_avg) / C.cnt_std * 5 + 75) > 100 then 100 else ((B.cnt - C.cnt_avg) / C.cnt_std * 5 + 75) end) 
	   + (case when ((D.f_tot - E.pop_avg) / E.pop_std * 5 + 75) > 100 then 100 else ((D.f_tot - E.pop_avg) / E.pop_std * 5 + 75) end))/2), 2) as score
     , sysdate::date as create_at
     , sysdate::date as update_at
     , 'du.Park' as work_user
from (
    -- 모집단 가져오기 : KT매출 & PNU존재 & 건물존재
    select T1.pnu
    from (
        -- KT매출 존재
        select distinct substring(bd_mgt_sn, 1, 19) as pnu
        from m1.kt_bldg_sales
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
    ) T1
    -- PNU 존재
    join m2.cremao_land T2
        on T1.pnu = T2.pnu
    -- 건물 존재
    join (
        select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
        from m1.bld_rgst
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
    ) T3
        on T1.pnu = T3.pnu
) A
join ( -- sns 노출 수 join (n:1 매칭) - B, C
	select *
	from m1.instagram_emd_cnt
) B
    on substring(A.pnu, 1, 8) = substring(B.emd_cd, 1, 8)
left join (
	select avg(cnt) as cnt_avg
		 , stddev(cnt::integer) as cnt_std
	from m1.instagram_emd_cnt
	where cnt > 0 and cnt notnull
) C
	on 1=1
join ( -- 유동인구 join (1:1 매칭) - D, E
	select substring(bd_mgt_sn, 1, 19) as pnu, avg(f_tot) as f_tot
	from m1.kt_bldg_xy_info
	where base_ym = (select base_ym from date) -- 기준월
	and f_tot > 0
	group by 1
) D
	on A.pnu = D.pnu
left join (
	select avg(f_tot) 	 as pop_avg
		 , stddev(f_tot) as pop_std
	from m1.kt_bldg_xy_info
	where base_ym = (select base_ym from date) -- 기준월
	and f_tot > 0
) E
	on 1=1
--)
;



 
-- 공실률 & 매매가 지수
--drop table if exists m2.datadam_vacant_price_score;
create table m2.datadam_vacant_price_score (
base_ym varchar(6)
, pnu varchar(19)
, emd_cd varchar(8)
, score double precision
, create_at date
, update_at date
, work_user varchar(15)
)
compound sortkey (base_ym, pnu);

-- ver1 (final)
--insert into m2.datadam_vacant_price_score (
with date as (
    select '202201'::text as base_ym
)
select (select base_ym from date) as base_ym
     , A.pnu
     , substring(A.pnu, 1, 8) as emd_cd
     , case when
            round(
                    (
                        nvl((avg(B.vac_rate) - avg(C.vac_rate_avg)) / avg(C.vac_rate_std) * 5 + 75, 75) +
                        nvl((avg(D.deal_amount_per_area) - avg(E.deal_amount_avg)) / avg(E.deal_amount_std) * 5 + 75, 75)
                    ) / 2, 2
                ) > 100 then 100
            else
            round(
                    (
                        nvl((avg(B.vac_rate) - avg(C.vac_rate_avg)) / avg(C.vac_rate_std) * 5 + 75, 75) +
                        nvl((avg(D.deal_amount_per_area) - avg(E.deal_amount_avg)) / avg(E.deal_amount_std) * 5 + 75, 75)
                    ) / 2, 2
                ) end as score
     , sysdate::date as create_at
     , sysdate::date as update_at
     , 'du.Park' as work_user
from (
    -- 모집단 가져오기 : KT매출 & PNU존재 & 건물존재
    select T1.pnu
         , ST_Centroid(T2.poly::geometry) as poly
    from (
        -- KT매출 존재
        select distinct substring(bd_mgt_sn, 1, 19) as pnu
        from m1.kt_bldg_sales
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
            and substring(bd_mgt_sn, 1, 5) = '11110' -- 시군구
    ) T1
    -- PNU 존재
    join m2.cremao_land T2
        on T1.pnu = T2.pnu
    -- 건물 존재
    join (
        select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
        from m1.bld_rgst
        where base_ym = (select base_ym from date) -- 기준월
    ) T3
        on T1.pnu = T3.pnu
) A
left join (
	select *
	from m1.vacant_rate
	where research_date = '202201' -- 기준분기
) B
    on substring(A.pnu, 1, 7) = B.region_cd
left join (
    select avg(vac_rate) as vac_rate_avg
         , stddev(vac_rate) as vac_rate_std 
    from m1.vacant_rate
    where 1=1
        and research_date = '202201' -- 기준분기
        and substring(region_cd, 1, 5) = '11110' -- 시군구
) C
    on 1=1
left join (
    select ST_Centroid(T2.poly::geometry) as poly
         , round(1.0 * T1.deal_amount * 10000 / T1.building_area, 0) as deal_amount_per_area
    from m2.cremao_building_trade_case T1
    left join m2.cremao_land T2
        on T1.pnu = T2.pnu
    where 1=1
        and T1.contract_year_month between (select dateadd(month, -59, to_date(base_ym||'01', 'yyyymmdd'))::date from date) and (select last_day(to_date(base_ym||'01', 'yyyymmdd')) from date) -- 최근 3년
        and substring(T1.pnu, 1, 5) = '11110' -- 시군구
) D
    on ST_DistanceSphere(A.poly, D.poly) < 150 -- 반경 150m PNU
left join (
    select round(avg(1.0 * deal_amount * 10000 / building_area), 0) as deal_amount_avg
         , round(stddev(1.0 * deal_amount * 10000 / building_area), 0) as deal_amount_std
    from m2.cremao_building_trade_case
    where 1=1
        and contract_year_month between (select dateadd(month, -59, to_date(base_ym||'01', 'yyyymmdd'))::date from date) and (select last_day(to_date(base_ym||'01', 'yyyymmdd')) from date) -- 최근 3년
        and substring(pnu, 1, 5) = '11110' -- 시군구
) E
    on 1=1
group by 1, 2, 3
limit 100
--)
;





-- 부동산 거래량 & 유동인구
create table m2.datadam_commercial_population_score (
base_ym varchar(6)
, pnu varchar(19)
, emd_cd varchar(8)
, score double precision
, create_at date
, update_at date
, work_user varchar(15)
)
compound sortkey (base_ym, pnu);

-- ver1
--insert into m2.datadam_commercial_population_score as (
with date as (
    select '202201'::text as base_ym
)
select (select base_ym from date) as base_ym
     , A.pnu
     , substring(A.pnu, 1, 8) as emd_cd
     , case when
            round(
                    (
                        nvl((avg(B.f_tot) - avg(C.f_tot_avg)) / avg(C.f_tot_std) * 5 + 75, 75) +
                        nvl((avg(D.deal_amount_per_area) - avg(E.deal_amount_avg)) / avg(E.deal_amount_std) * 5 + 75, 75)
                    ) / 2, 2
                ) > 100 then 100
            else
            round(
                    (
                        nvl((avg(B.f_tot) - avg(C.f_tot_avg)) / avg(C.f_tot_std) * 5 + 75, 75) +
                        nvl((avg(D.deal_amount_per_area) - avg(E.deal_amount_avg)) / avg(E.deal_amount_std) * 5 + 75, 75)
                    ) / 2, 2
                ) end as score
     , sysdate::date as create_at
     , sysdate::date as update_at
     , 'du.Park' as work_user
from (
    -- 모집단 가져오기 : KT매출 & PNU존재 & 건물존재
    select T1.pnu
         , ST_Centroid(T2.poly::geometry) as poly
    from (
        -- KT매출 존재
        select distinct substring(bd_mgt_sn, 1, 19) as pnu
        from m1.kt_bldg_sales
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
            and substring(bd_mgt_sn, 1, 5) = '11110' -- 시군구
    ) T1
    -- PNU 존재
    join m2.cremao_land T2
        on T1.pnu = T2.pnu
    -- 건물 존재
    join (
        select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
        from m1.bld_rgst
        where base_ym = (select base_ym from date) -- 기준월
    ) T3
        on T1.pnu = T3.pnu
) A
left join (
    select substring(bd_mgt_sn, 1, 19) as pnu
         , avg(f_tot) as f_tot
    from m1.kt_bldg_xy_info
    where 1=1
        and base_ym = (select base_ym from date) -- 기준월
        and substring(bd_mgt_sn, 1, 5) = '11110' -- 시군구
    group by 1
) B
    on A.pnu = B.pnu
left join (
    select avg(f_tot) as f_tot_avg
         , stddev(f_tot) as f_tot_std 
    from m1.kt_bldg_xy_info
    where 1=1
        and base_ym = (select base_ym from date) -- 기준월
        and substring(bd_mgt_sn, 1, 5) = '11110' -- 시군구
) C
    on 1=1
left join (
    select ST_Centroid(T2.poly::geometry) as poly
         , round(1.0 * T1.deal_amount * 10000 / T1.building_area, 0) as deal_amount_per_area
    from m2.cremao_building_trade_case T1
    left join m2.cremao_land T2
        on T1.pnu = T2.pnu
    where 1=1
        and T1.contract_year_month between (select dateadd(month, -59, to_date(base_ym||'01', 'yyyymmdd'))::date from date) and (select last_day(to_date(base_ym||'01', 'yyyymmdd')) from date) -- 최근 3년
        and substring(T1.pnu, 1, 5) = '11110' -- 시군구
) D
    on ST_DistanceSphere(A.poly, D.poly) < 150 -- 반경 150m PNU
left join (
    select round(avg(1.0 * deal_amount * 10000 / building_area), 0) as deal_amount_avg
         , round(stddev(1.0 * deal_amount * 10000 / building_area), 0) as deal_amount_std
    from m2.cremao_building_trade_case
    where 1=1
        and contract_year_month between (select dateadd(month, -59, to_date(base_ym||'01', 'yyyymmdd'))::date from date) and (select last_day(to_date(base_ym||'01', 'yyyymmdd')) from date) -- 최근 3년
        and substring(pnu, 1, 5) = '11110' -- 시군구
) E
    on 1=1
group by 1, 2, 3
limit 100
--)
;




-- datadam_commercial_per_population / datadam_commercial_population_score / datadam_vacant_price_score
select *
from m2.datadam_sales_per_area
where 1=1
--and score notnull
--and base_ym = '202206' -- 기준월
--and pnu = '1111010500100980020'
--and industry_cd = 'B19'
order by base_ym asc
limit 10
;

select count(*) from m2.datadam_predict_price where base_ym = '202208';


--delete from m2.datadam_predict_price where 1=1;





with date as (
    select '202211'::text as base_ym
)
select (select base_ym from date) as base_ym
     , A.pnu
     , substring(A.pnu, 1, 8) as emd_cd
     , case when
            round(
                    (
                        nvl((avg(B.vac_rate) - avg(C.vac_rate_avg)) / avg(C.vac_rate_std) * -5 + 75, 75) +
                        nvl((avg(D.deal_amount_per_area) - avg(E.deal_amount_avg)) / avg(E.deal_amount_std) * 5 + 75, 75)
                    ) / 2, 2
                ) > 100 then 100
            else
            round(
                    (
                        nvl((avg(B.vac_rate) - avg(C.vac_rate_avg)) / avg(C.vac_rate_std) * -5 + 75, 75) +
                        nvl((avg(D.deal_amount_per_area) - avg(E.deal_amount_avg)) / avg(E.deal_amount_std) * 5 + 75, 75)
                    ) / 2, 2
                ) end as score
     , sysdate::date as create_at
     , sysdate::date as update_at
     , 'du.Park' as work_user
from (
    -- 모집단 가져오기 : KT매출 & PNU존재 & 건물존재
    select T1.pnu
         , ST_Centroid(T2.poly::geometry) as poly
    from (
        -- KT매출 존재
        select distinct substring(bd_mgt_sn, 1, 19) as pnu
        from m1.kt_bldg_sales
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
            and substring(bd_mgt_sn, 1, 5) = '11110' -- 시군구
    ) T1
    -- PNU 존재
    join m2.cremao_land T2
        on T1.pnu = T2.pnu
    -- 건물 존재
    join (
        select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
        from m1.bld_rgst
        where base_ym = (select base_ym from date) -- 기준월
    ) T3
        on T1.pnu = T3.pnu
) A
left join (
    -- 시도단위 임대료 데이터
    select T1.sidocode as sido_cd
         , avg(T2.vac_rate) as vac_rate
    from m1.polygon_area T1
    left join (
        select region_nm
             , avg(vac_rate) as vac_rate
        from m1.vacant_rate
        where research_date = '202203' -- 기준분기
        group by 1
    ) T2
        on T1.cname = T2.region_nm
    group by 1
) B
    on substring(A.pnu, 1, 2) = B.sido_cd
left join (
    select avg(vac_rate) as vac_rate_avg
         , stddev(vac_rate) as vac_rate_std 
    from m1.vacant_rate
    where 1=1
        and research_date = '202203' -- 기준분기
) C
    on 1=1
left join (
    select ST_Centroid(T2.poly::geometry) as poly
         , round(1.0 * T1.deal_amount * 10000 / T1.building_area, 0) as deal_amount_per_area
    from m2.cremao_real_estate_trade_case T1
    left join m2.cremao_land T2
        on T1.pnu = T2.pnu
    where 1=1
        and T1.contract_date between (select dateadd(month, -59, to_date(base_ym||'01', 'yyyymmdd'))::date from date) and (select last_day(to_date(base_ym||'01', 'yyyymmdd')) from date) -- 최근 3년
        and substring(T1.pnu, 1, 5) = '11110' -- 시군구
) D
    on ST_DistanceSphere(A.poly, D.poly) < 150 -- 반경 150m PNU
left join (
    select round(avg(1.0 * deal_amount * 10000 / building_area), 0) as deal_amount_avg
         , round(stddev(1.0 * deal_amount * 10000 / building_area), 0) as deal_amount_std
    from m2.cremao_real_estate_trade_case
    where 1=1
        and contract_date between (select dateadd(month, -59, to_date(base_ym||'01', 'yyyymmdd'))::date from date) and (select last_day(to_date(base_ym||'01', 'yyyymmdd')) from date) -- 최근 3년
        and substring(pnu, 1, 5) = '11110' -- 시군구
        and building_type not in ('토지')
) E
    on 1=1
group by 1, 2, 3
limit 10;





with date as (
    select '202211'::text as base_ym
)
select (select base_ym from date) as base_ym
     , A.pnu
     , substring(A.pnu, 1, 8) as emd_cd
     , case when sum(B.pop) = 0 then -99 else round(1.0 * sum(B.tot_area) / sum(B.pop), 2) end as area
     , sysdate::date as create_at
     , sysdate::date as update_at
     , 'du.Park' as work_user
from (
    -- 모집단 가져오기 : KT매출 & PNU존재 & 건물존재
    select T1.pnu
         , ST_Centroid(T2.poly::geometry) as poly
    from (
        -- KT매출 존재
        select distinct substring(bd_mgt_sn, 1, 19) as pnu
        from m1.kt_bldg_sales
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
            and substring(bd_mgt_sn, 1, 5) = '11110' -- 시군구
    ) T1
    -- PNU 존재
    join m2.cremao_land T2
        on T1.pnu = T2.pnu
    -- 건물 존재
    join (
        select distinct sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
        from m1.bld_rgst
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
    ) T3
        on T1.pnu = T3.pnu
) A
left join (
    -- 반경 150m 데이터
    select nvl(T1.pnu, T2.pnu, T3.pnu) as pnu
         , nvl(T1.pnu_pop_cnt, 0) + nvl(T2.pnu_pop_cnt, 0) as pop
         , nvl(T3.tot_area, 0) as tot_area
         , ST_Centroid(T4.poly::geometry) as poly
    from (
        select *
        from m2.live_pop
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
            and substring(pnu, 1, 5) = '11110' -- 시군구
            and pnu_pop_cnt > 0 -- 인구수 1이상
    ) T1
    full join (
        select *
        from m2.work_pop
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
            and substring(pnu, 1, 5) = '11110' -- 시군구
            and pnu_pop_cnt > 0 -- 인구수 1이상
    ) T2
        on T1.pnu = T2.pnu
    full join (
        select sigungu_cd||bjdong_cd||case when plat_gb_cd = '0' then '1' else plat_gb_cd end||bun||ji as pnu
             , sum(tot_area) as tot_area
        from m1.bld_rgst
        where 1=1
            and base_ym = (select base_ym from date) -- 기준월
            and substring(pnu, 1, 5) = '11110' -- 시군구
            and (main_purps_cd_nm like '%업무%' or main_purps_cd_nm like '%공장%' or main_purps_cd_nm like '%근린%') -- 상업업무용 부동산
        group by 1
    ) T3
        on nvl(T1.pnu, T2.pnu) = T3.pnu
    join m2.cremao_land T4
        on nvl(T1.pnu, T2.pnu, T3.pnu) = T4.pnu
) B
    on ST_DistanceSphere(A.poly, B.poly) < 150 -- 반경 150m PNU
group by 1, 2, 3
having area >= 0;

select *
from m2.datadam_commercial_population_score  
where score isnull 
and score <= 0
limit 10;



