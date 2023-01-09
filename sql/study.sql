-- 중복제거 (안 먹힘)
DELETE t1
FROM m1.asking_price as t1
JOIN m1.asking_price as t2
ON t1.atclno=t2.atclno AND t1.cortarno=t2.cortarno AND t1.atclstatcd=t2.atclstatcd AND t1.rlettpcd=t2.rlettpcd
WHERE t1.id > t2.id
;

-- 중복 제거2 (안 먹힘)
select *
	 , row_number() over (partition by atclno, cortarno, atclstatcd, rlettpcd)
from m1.asking_price ap 
limit 100;
delete m1.asking_price where row_number > 1;

-- 데이블명 변경

INSERT INTO m1.aggregate_bld(commercial_wide_area,cname,sido,plat_area,arch_area,tot_area,bc_rat,vl_rat,building_structure,main_purps_nm,ground_floor,under_ground_floor,useapr_day,elevator_gb,parking_area,land_use,subway_distance,bus_distance,main_crossroad,conversion_rate,traditional_market_gb,typical_floor,invest_floor,tenant_usage_status,business_type_large,business_type_small,net_leasable_area,common_area,sum_area,owner_ho,owner_type,contract_deposit_1st,contract_monthly_rent_sum_1st,contract_monthly_rent_1st,selling_deposit_1st,selling_monthly_rent_sum_1st,selling_monthly_rent_1st,admin_cost_1st,admin_actual_cost_1st,vacant_1,contract_deposit_2nd,contract_monthly_rent_sum_2nd,contract_monthly_rent_2nd,selling_deposit_2nd,selling_monthly_rent_sum_2nd,selling_monthly_rent_2nd,admin_cost_2nd,admin_actual_cost_2nd,vacant_2,contract_deposit_3rd,contract_monthly_rent_sum_3rd,contract_monthly_rent_3rd,selling_deposit_3rd,selling_monthly_rent_sum_3rd,selling_monthly_rent_3rd,admin_cost_3rd,admin_actual_cost_3rd,vacant_3,current_contract_date,current_contract_term,first_current_contract_date,invest_calculation_amt,base_ym) VALUES ('NaN'::float,'0.비상권','강원도 원주시','1000㎡ 초과 10000㎡ 이하','330㎡ 초과 1000㎡ 이하','1000㎡ 초과 10000㎡ 이하','60% 초과 70% 이하','200% 초과 300% 이하','철근콘크리트구조','판매시설','3~5층','지하층 없음','2001~2005년','설치','660㎡ 초과 1000㎡ 이하','준주거지역','없음','40','100','6% 초과 8% 이하','-',1,'3~5층','임대계약면적','G',467.0,'33㎡ 초과 66㎡ 이하','66㎡ 초과 100㎡ 이하','100㎡ 초과 330㎡ 이하',1,'개인','1백만원 초과 5백만원 이하','1십만원 초과 5십만원 이하','2000원/㎡ 초과 4000원/㎡ 이하','1백만원 초과 5백만원 이하','1십만원 초과 5십만원 이하',3000,'1십만원 이하','1십만원 초과 5십만원 이하',0,'1백만원 초과 5백만원 이하','1십만원 초과 5십만원 이하','2000원/㎡ 초과 4000원/㎡ 이하','1백만원 초과 5백만원 이하','1십만원 초과 5십만원 이하',3000,'1십만원 이하','1십만원 초과 5십만원 이하',0,'1백만원 초과 5백만원 이하','1십만원 초과 5십만원 이하','2000원/㎡ 초과 4000원/㎡ 이하','1백만원 초과 5백만원 이하','1십만원 초과 5십만원 이하',3000,'1십만원 이하','1십만원 초과 5십만원 이하',0,2018,'13~24개월','2016년 1월 이후',480000,202212)
