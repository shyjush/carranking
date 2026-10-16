begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('BMW','5시리즈','G60','연합뉴스',
 '[시승기] 레이싱 게임 하는 듯한 신나는 주행…BMW 뉴 520i',
 'https://www.yna.co.kr/view/AKR20231005174000003',
 date '2023-10-06','임성호','520i',
 'G60 8세대 520i를 영종도~의정부 왕복 약 150km 주행하며 승차감·가속·주행보조·인포테인먼트와 실내 상품성을 평가한 독립 시승자료.'),

('메르세데스-벤츠','E-클래스','W214','탑라이더',
 '[시승기] 벤츠 신형 E클래스, 정숙성과 완성도 업그레이드',
 'https://www.top-rider.com/article/view/trd202402070001',
 date '2024-02-07','이한승','E300 4MATIC AMG Line',
 'W214 11세대 E클래스의 정숙성·시트포지션·승차감·주행 완성도와 소재 구성을 실제 시승으로 평가한 독립 전문 자료.'),

('테슬라','Model 3','하이랜드','모터그래프',
 '''가성비''보다 중요한 ''가치'', 테슬라 모델 3 RWD [시승기]',
 'https://www.motorgraph.com/news/articleView.html?idxno=33539',
 date '2024-04-15','신화섭','Model 3 Highland RWD',
 'Model 3 하이랜드 RWD를 약 150km 주행하며 실전 효율·승차감·코너링·방음·인테리어 변화를 평가한 독립 시승자료.'),

('테슬라','Model Y','주니퍼','한국경제',
 '中 시골서도 타는데 한국은 왜…테슬라 차주들 부글부글',
 'https://www.hankyung.com/article/202505093426i',
 date '2025-05-10','백수전','Model Y Juniper Long Range',
 'Model Y 주니퍼를 이틀간 서울 강남~자유로~임진각 약 250km 주행하며 승차감·방음·가속·오토파일럿과 패밀리카 활용성을 평가한 장거리 시승자료.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test',s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,'B','approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and coalesce(g.generation_code,g.name)=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,
 source_type='expert_road_test',
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
