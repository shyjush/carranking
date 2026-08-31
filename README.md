# CarRanking Web V2

배포 준비형 자동차랭킹 정적 웹 프로토타입입니다.

## 포함
- 홈 / 가치보존율 랭킹 / 필터 / 인기비교 / 내 차 몇 점 / 리뷰 빈상태
- GitHub Pages Actions 자동배포 workflow
- `.nojekyll`
- Supabase REST API 전환용 `config.js`
- Supabase 미연결 시 8개 초기 랭킹 데이터를 fallback으로 표시

## GitHub Pages
저장소의 `main` 브랜치에 이 파일들을 올린 뒤,
GitHub → Settings → Pages → Source를 `GitHub Actions`로 선택하면 됩니다.

## Supabase 연결
CarRanking Supabase 프로젝트가 생성되면 `config.js`의:
- `supabaseUrl`
- `supabasePublishableKey`
- `useSupabase: true`
를 설정합니다.

웹은 `web_value_ranking` View를 REST로 조회하도록 준비되어 있습니다.

주의: publishable key만 프론트에 사용하고 service_role/secret key는 절대 넣지 않습니다.
