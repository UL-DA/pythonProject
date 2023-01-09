-- [datadam_gentrification] 젠트리피케이션
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


-- [datadam_price] 예측분양가
with date as (
select '202208' as base_ym
)
select A.pnu, A.emd_cd, A.price
from (-- PNU별 가치환원법
	select pnu, substring(pnu,1,10) as emd_cd, round((min_price_1 + max_price_1)/2,0) as price
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
;


-- 면적당 매출액
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
;


-- [datadam_sales_per_income] 소득대비 매출액
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
;