# App Store 제출 가이드 (ClassicLaunch)

## 금지/주의

- ❌ private API 사용 금지
- ❌ Apple 시스템 기능/브랜드를 오해하게 만드는 카피 금지
- ❌ 시스템 Launchpad를 완전 대체한다고 주장 금지
- ❌ Apple 로고/고유 아이콘 모사 금지

## 권장 메시지

- "Classic launcher experience for people who miss grid-based app launching."
- "All indexing and layout data stays on-device."

## 제출 전 체크리스트

- [ ] Sandboxed 빌드 확인
- [ ] Entitlements 최소화
- [ ] 개인정보 처리 문구(온디바이스 처리) 포함
- [ ] 접근성/키보드 조작 점검
- [ ] 500+ 앱 환경 성능 점검
- [ ] 크래시 없는지 24시간 번인 테스트
- [ ] 메타데이터 초안 반영 (`docs/APP_STORE_METADATA_DRAFT.md`)
- [ ] 전역 단축키 충돌 검사(한/영 전환, Spotlight와의 충돌 여부)
