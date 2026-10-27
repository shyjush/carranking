#!/usr/bin/env python3
"""Publish transparent review status without republishing unverified prices."""
import html,json,pathlib
R=pathlib.Path('research/followup-20261027');rows=json.loads((R/'depreciation-audit.json').read_text());targets=(R/'target-specs.txt').read_text().splitlines();assert len(rows)==len(targets)==63
price_files=[R/'original-price-evidence.json',pathlib.Path('research/phase3-20261028/original-price-evidence.json')]
prices={r['depreciation_id']:r for f in price_files if f.exists() for r in json.loads(f.read_text())}
db={d['id']:d for d in json.loads((R/'before-depreciation.json').read_text())}
esc=html.escape;articles=[]
review_file=pathlib.Path('research/phase2-20261028/listing-review.json')
listing_reviews={r['depreciation_id']:r for r in json.loads(review_file.read_text())} if review_file.exists() else {}
for r,target in zip(rows,targets):
 r['target_spec']=target;r['generation_id']=db[r['depreciation_id']]['generation_id'];p=prices.get(r['depreciation_id'])
 if p:r['partial_original_price']=p;r['missing'][-1]='공식 기본가격 일부 확보. 개별 차량 계약월의 세율·선택 옵션 및 매물 가격과의 일치 확인 필요'
 title=f"{r['model']} {r['generation']} · 저장 연도 {r['model_year']}"
 partial=f"<p><strong>신차 기본가격 부분 근거 확보</strong> · {p['price_krw']:,}원</p><p>{esc(p['scope'])}</p><p>원문 발표일 {esc(p['source_date'])} · 가격 원문 대조일 {esc(p.get('reviewed_on','2026-10-27'))}</p><p>{esc(p['limitations'])}</p><a href=\"{esc(p['source_url'],quote=True)}\" target=\"_blank\" rel=\"noopener noreferrer\">신차가격 원문 ↗</a>" if p else '<p>해당 연식의 세율·옵션까지 일치하는 공식 신차가격 증빙 미완료</p>'
 aggregate=f'<a href="{esc(r["aggregate_url"],quote=True)}" target="_blank" rel="noopener noreferrer">외부 집계 참고 원문 ↗</a> · 개별 매물 검증에 사용하지 않음' if 'aggregate_fetch' in r else '<p>기존 집계 경로는 404 응답으로 원문 대조 불가</p>'
 review=listing_reviews.get(r['depreciation_id'])
 listing=(f'<section class="listing-review"><h3>개별 매물 대조 결과</h3><p>{esc(review["reason"])}</p><a href="{esc(review["url"],quote=True)}" target="_blank" rel="noopener noreferrer">대조한 매물 원문 ↗</a><p>2026-10-27 검색 수록본 검토 · 현재 판매 여부와 가격 관측일 미확인. 시세 표본·검증된 감가율로 사용하지 않습니다.</p></section>') if review else ''
 articles.append(f'<article class="panel audit-item" data-generation="{r["generation_id"]}"><h2>{esc(title)}</h2><p>{esc(target)}</p><p class="badge">C등급 · 감가율 검증 보류</p>{partial}{listing}<details><summary>부족한 증빙과 대조 결과</summary><ul>'+''.join('<li>'+esc(v)+'</li>' for v in r['missing'])+f'</ul>{aggregate}<p>검토일 2026-10-27 · 시세 관측일·감가율 검증일 갱신 아님</p></details></article>')
# Preserve historical audits; this build only regenerates the public page.
page='''<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>감가율 근거·검증 상태 | CarRanking</title><meta name="description" content="차량별 감가율 검증 상태와 확보한 신차가격 원문, 부족한 실매물 증빙을 확인하세요."><link rel="canonical" href="https://carranking.kr/value-evidence.html"><link rel="stylesheet" href="/vehicle-tools.css?v=20261027b"><style>.audit-item h2{font-size:1.15rem}.audit-item{overflow-wrap:anywhere}.audit-item li{margin:.5rem 0}[hidden]{display:none!important}</style></head><body><header class="top"><a class="brand" href="/">CarRanking <span>자동차랭킹</span></a><nav aria-label="주 메뉴"><a href="/vehicle-tools.html">사양 비교·유지비</a></nav></header><main><section class="panel"><h1>감가율 근거·검증 상태</h1><p>2026-10-28 가격 근거 보강: 기존 감가율 63건은 모두 C등급이며 검증을 보류합니다. 신차가격 부분 근거 __PRICE_COUNT__건을 확보했습니다. 개별 실매물의 가격·사양·상태·중복 검증이 완료된 시세 스냅샷은 0건입니다.</p><p>신차 기본가격만 확인한 자료를 검증된 감가율로 사용하지 않습니다. 미검증 중고가격과 감가율은 이 페이지에 제시하지 않습니다. 저장 연도는 모델연도 검증 완료를 뜻하지 않으며 출시연도·최초등록연도와 구분해 확인합니다.</p><label for="evidenceSearch">차량·연식·사양 찾기<input id="evidenceSearch" type="search" placeholder="예: G70, 2021, 프레스티지"></label><p id="evidenceCount" role="status"></p><button class="quiet" type="button" id="showAll">전체 차량 보기</button></section>'''+''.join(articles)+'''</main><footer>© CarRanking · 근거와 검증 상태를 함께 공개합니다.</footer><script src="/value-evidence.js?v=20261027b"></script></body></html>'''
page=page.replace('__PRICE_COUNT__',str(len(prices)))
pathlib.Path('value-evidence.html').write_text(page)
