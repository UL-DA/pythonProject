select t2.pnu, t2.base_year 
from land_price2 as t1
right join (
	select *
	from land_price2
	where base_year not like '%2018%'
) t2
	on t1.pnu = t2.pnu
where t2.pnu = '4215031029101720000'
limit 50;


DROP TABLE IF EXISTS building_eap_info2;

select *
from cremao_building_trade_case
-- where pnu = '1111010100100010000'
limit 10;