-- 중복 제거 (새 체이블 생성 > 로넘으로 동일 행 개수 파악하는 컬럼 추가 > )
create table m1.tmp (
atclNo varchar(10)
,cortarNo varchar(10)
,atclNm varchar(200)
,atclStatCd varchar(20)
,rletTpCd varchar(20)
,uprRletTpCd varchar(20)
,rletTpNm varchar(100)
,tradTpCd varchar(20)
,tradTpNm varchar(100)
,vrfcTpCd varchar(20)
,flrInfo varchar(20)
,prc varchar(20)
,rentPrc varchar(20)
,spc1 varchar(20)
,spc2 varchar(20)
,direction varchar(20)
,atclCfmYmd varchar(20)
,lat double precision
,lng double precision
,atclFetrDesc varchar(500)
,cpid varchar(20)
,cpNm varchar(200)
,rltrNm varchar(200)
,base_ym varchar(6)
,num bigint
)
distkey(cortarNo)
compound sortkey(cortarNo,atclCfmYmd,prc,base_ym);

-- tmp table 에 202211월 값 인서트
insert into m1.tmp
select *
	 , row_number() over (partition by atclno, cortarno, atclstatcd, rlettpcd) as num
from m1.asking_price
where base_ym = '202211';

-- 중복값 제거
delete from m1.tmp where num > 1;
commit;

-- 컬럼 삭제
alter table m1.tmp drop column num;

-- asking_price table 에서 202211월 데이터 삭제
delete from m1.asking_price where base_ym = '202211';

-- tmp > asking_price 값 이동
insert into m1.asking_price select * from m1.tmp;

-- 개수 확인
select count(*) from m1.asking_price where base_ym = '202211' limit 10;

-- drop tmp table
drop table if exists m1.tmp;
commit;
