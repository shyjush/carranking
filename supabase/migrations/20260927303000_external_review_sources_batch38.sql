begin;

insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select
 g.id,'expert_road_test','오토뷰',
 '[체험기] 쉐보레 더 넥스트 스파크',
 'https://www.autoview.co.kr/ko-kr/articles/55962',
 date '2015-07-01',date '2026-09-27',
 '오토뷰 뉴스팀','1.0 가솔린 / C-TECH',
 'M400 더 넥스트 스파크 출시 직후 미디어 시승에서 차체 감각·조향·승차감·파워트레인과 실내 상품성을 직접 평가한 전용 자료. 공식 계측 로드테스트 전 체험기이므로 B로 분류.',
 'B','approved_reference','unique',false,false,false,false
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='쉐보레' and cm.name='스파크' and g.generation_code='M400'
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,
 source_type=excluded.source_type,
 source_name=excluded.source_name,
 title=excluded.title,
 published_date=excluded.published_date,
 observed_date=excluded.observed_date,
 author_label=excluded.author_label,
 powertrain_hint=excluded.powertrain_hint,
 summary=excluded.summary,
 source_confidence='B',
 approval_status='approved_reference',
 dedupe_status='unique',
 owner_score_eligible=false,
 value_score_eligible=false,
 updated_at=now();

commit;
