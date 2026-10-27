#!/usr/bin/env python3
"""Publish transparent review status without republishing unverified prices."""
import html,json,pathlib
R=pathlib.Path('research/followup-20261027');rows=json.loads((R/'depreciation-audit.json').read_text());targets=(R/'target-specs.txt').read_text().splitlines();assert len(rows)==len(targets)==63
prices={r['depreciation_id']:r for r in json.loads((R/'original-price-evidence.json').read_text())}
db={d['id']:d for d in json.loads((R/'before-depreciation.json').read_text())}
esc=html.escape;articles=[]
for r,target in zip(rows,targets):
 r['target_spec']=target;r['generation_id']=db[r['depreciation_id']]['generation_id'];p=prices.get(r['depreciation_id'])
 if p:r['partial_original_price']=p;r['missing'][-1]='공식 기본가격 일부 확보. 개별 차량 계약월의 세율·선택 옵션 및 매물 가격과의 일치 확인 필요'
 title=f"{r['model']} {r['generation']} · {r['model_year']}년식"
 partial=f"<p><strong>신차 기본가격 부분 근거 확보</strong> · {p['price_krw']:,}원</p><p>{esc(p['scope'])}</p><p>{esc(p['limitations'])}</p><a href=\"{esc(p['source_url'],quote=True)}\" target=\"_blank\" rel=\"noopener noreferrer\">신차가격 원문 ↗</a>" if p else '<p>해당 연식의 세율·옵션까지 일치하는 공식 신차가격 증빙 미완료</p>'
 aggregate=f'<a href="{esc(r["aggregate_url"],quote=True)}" target="_blank" rel="noopener noreferrer">외부 집계 참고 원문 ↗</a> · 개별 매물 검증에 사용하지 않음' if 'aggregate_fetch' in r else '<p>기존 집계 경로는 404 응답으로 원문 대조 불가</p>'
 articles.append(f'<article class="panel audit-item" data-generation="{r["generation_id"]}"><h2>{esc(title)}</h2><p>{esc(target)}</p><p class="badge">C등급 · 감가율 검증 보류</p>{partial}<details><summary>부족한 증빙과 대조 결과</summary><ul>'+''.join('<li>'+esc(v)+'</li>' for v in r['missing'])+f'</ul>{aggregate}<p>검토일 2026-10-27 · 시세 관측일·감가율 검증일 갱신 아님</p></details></article>')
(R/'depreciation-audit.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
page='''<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>감가율 근거·검증 상태 | CarRanking</title><meta name="description" content="차량별 감가율 검증 상태와 확보한 신차가격 원문, 부족한 실매물 증빙을 확인하세요."><link rel="canonical" href="https://carranking.kr/value-evidence.html"><link rel="stylesheet" href="/vehicle-tools.css?v=20261027b"><style>.audit-item h2{font-size:1.15rem}.audit-item{overflow-wrap:anywhere}.audit-item li{margin:.5rem 0}[hidden]{display:none!important}</style></head><body><header class="top"><a class="brand" href="/">CarRanking <span>자동차랭킹</span></a><nav aria-label="주 메뉴"><a href="/vehicle-tools.html">사양 비교·유지비</a></nav></header><main><section class="panel"><h1>감가율 근거·검증 상태</h1><p>2026-10-27 검토: 기존 감가율 63건은 모두 C등급이며 검증을 보류합니다. 신차가격 부분 근거 5건을 확보했습니다. 개별 실매물의 가격·사양·상태·중복 검증이 완료된 시세 스냅샷은 0건입니다.</p><p>신차 기본가격만 확인한 자료를 검증된 감가율로 사용하지 않습니다. 미검증 중고가격과 감가율은 이 페이지에 제시하지 않습니다.</p><label for="evidenceSearch">차량·연식·사양 찾기<input id="evidenceSearch" type="search" placeholder="예: G70, 2021, 프레스티지"></label><p id="evidenceCount" role="status"></p><button class="quiet" type="button" id="showAll">전체 차량 보기</button></section>'''+''.join(articles)+'''</main><footer>© CarRanking · 근거와 검증 상태를 함께 공개합니다.</footer><script src="/value-evidence.js?v=20261027b"></script></body></html>'''
pathlib.Path('value-evidence.html').write_text(page)
