begin;

-- Replace an older Avante MD media URL that is consistently unreachable in automated audits.
update public.external_review_sources
set approval_status='hold',
    source_confidence='C',
    summary='동일 MD 세대에 오토뷰 A급 계측 근거가 별도로 확보되어 있으며, 이 원문은 자동 URL 감사에서 안정적으로 확인되지 않아 보류.',
    updated_at=now()
where canonical_url='https://www.kookje.co.kr/news2011/asp/newsbody.asp?code=0200&key=20101004.22013210538';

with src(brand,model,generation_code,source_type,source_name,title,url,published_date,author_label,powertrain,summary,confidence) as (
values
('메르세데스-벤츠','E-클래스','W213','expert_road_test','오토뷰',
 '[시승기] 메르세데스-벤츠, E300 4MATIC Exclusive',
 'https://www.autoview.co.kr/ko-kr/articles/59337',
 date '2016-08-08','오토뷰 로드테스트팀','E300 4MATIC',
 'W213 10세대 E클래스의 정숙성·가속·제동·승차감과 주행 완성도를 계측한 전문 로드테스트.','A'),

('토요타','캠리','XV70','expert_road_test','오토뷰',
 '[시승기] 토요타, 캠리 2.5',
 'https://www.autoview.co.kr/ko-kr/articles/63430',
 date '2018-01-16','오토뷰 로드테스트팀','2.5 가솔린',
 'XV70 캠리의 출력·가속·제동·고속 안정성·주행 보조 기능을 직접 시험한 전문 로드테스트.','A'),

('쉐보레','스파크','M300','expert_road_test','오토뷰',
 '[시승기] GM대우, 마티즈 크리에이티브',
 'https://www.autoview.co.kr/ko-kr/articles/33111',
 null,'오토뷰 로드테스트팀','1.0 가솔린',
 'M300 계열 마티즈 크리에이티브의 0-100km/h 가속·정숙성·주행 특성을 계측한 전문 로드테스트.','A'),

('현대','쏘나타','NF','expert_road_test','이데일리',
 '(시승기) 쏘나타 트랜스폼 세련된 실내디자인 눈길',
 'https://www.edaily.co.kr/News/Read?mediaCodeNo=257&newsId=01462886583363112',
 date '2007-12-28','양효석','N20 프리미엄 블랙',
 'NF 쏘나타 트랜스폼을 실제 도로에서 주행해 엔진·변속기·소음·진동과 상품성 변화를 평가한 독립 시승기사.','B'),

('현대','그랜저','TG','expert_road_test','이코노미조선',
 'GRANDEUR L330 시승기',
 'https://economychosun.com/site/data/html_dir/2005/06/22/2005062200048.html',
 date '2005-06-22','오성택','L330',
 'TG 4세대 그랜저 L330의 고속 안정성·승차감·접지력과 주행 감각을 실제 시승으로 평가한 독립 전문 기사.','B'),

('현대','싼타페','CM','expert_road_test','카이즈유',
 '현대 뉴 싼타페 시승기',
 'https://www.carisyou.com/car/2723/Magazine/38093',
 date '2005-11-28',null,'CM 2.2 디젤',
 'CM 2세대 싼타페의 출시 초기 독립 시승자료. 세대·차종은 정확히 일치하지만 계측 범위가 제한적이어서 B로 분류.','B')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,s.source_type,s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,s.confidence,'approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type=excluded.source_type,source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence=excluded.source_confidence,approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();

commit;
