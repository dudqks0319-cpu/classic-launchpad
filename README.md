# ClassicLaunch

macOS 업그레이드 이후 Launchpad가 사라져 불편한 사용자를 위한 **클래식 런처 복원 프로젝트**입니다.

## 현재 구현 (MVP)

- ✅ 설치 앱 자동 인덱싱 (`/Applications`, `/System/Applications`, `~/Applications`)
- ✅ Launchpad 스타일 그리드 + 페이지네이션
- ✅ 실시간 검색 (앱 이름/경로/번들 ID)
- ✅ 폴더 생성/해제/이름 변경
- ✅ 드래그 드롭
  - 엔트리 재정렬
  - 앱 → 폴더 드롭으로 폴더에 앱 추가
  - 앱 → 앱 드롭으로 새 폴더 생성
- ✅ 앱 실행 (클릭)
- ✅ 전역 런처 토글 단축키 (`⌥⌘L`)
- ✅ 로컬 JSON 상태 저장 (`~/Library/Application Support/ClassicLaunch/launcher-state.json`)
- ✅ 로컬 처리 프라이버시 문구 제공
- ✅ 부팅 중복 로딩 방지 + 앱 ID 캐시(초기 렌더 성능 개선)

## 제품 방향 (요청 반영)

### 개발자 관점 반영
1. 문제정의: “혁신”이 아니라 **사라진 UX 복원**
2. 근육기억 우선: 기존 Launchpad 흐름(그리드/검색/폴더/드래그) 중심
3. 확장보다 패리티 우선: MVP에 핵심 동선 집중
4. App Store 리스크 관리: private API 사용 금지, 독자 브랜딩
5. 성능 우선: 로컬 캐시 + 경량 상태 구조

### 소비자 관점 반영
1. 첫 실행부터 클래식한 기본값
2. 폴더/정렬 복구를 쉽게
3. 안정성 우선 (상태 복원 중심 구조)
4. 프라이버시 투명성 (로컬 저장만)
5. 가격 정책은 향후 Free + Pro 구조 고려

## App Store 배포 시 주의

- 시스템 Launchpad를 "대체"한다고 직접 명시하지 말고, **클래식 런처 경험 제공**으로 설명
- Apple 고유 브랜딩/아이콘/문구 카피 금지
- private API 및 비허용 접근성 훅 사용 금지
- 샌드박스 권한 최소화

## 실행

```bash
cd classic-launchpad
swift build
swift run ClassicLaunch
```

> 현재는 Swift Package 기반 소스 구조이며, App Store 아카이브를 위해 `project.yml`(XcodeGen)도 함께 제공합니다.

## Xcode 프로젝트 생성 (App Store용)

```bash
cd classic-launchpad
brew install xcodegen
./scripts/generate_xcodeproj.sh
```

생성 결과: `ClassicLaunch.xcodeproj`

## 테스트

```bash
cd classic-launchpad
swift test
```

## 트러블슈팅

만약 아래 같은 에러가 나오면(Manifest에서 `PackageDescription.Package.__allocating_init` 심볼 누락),
현재 Command Line Tools와 SwiftPM 링크 구성이 깨진 상태일 가능성이 큽니다.

- `Undefined symbols for architecture arm64`
- `PackageDescription.Package.__allocating_init...`

해결 권장:

1. Xcode 정식 설치 또는 재설치
2. `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
3. `sudo xcodebuild -runFirstLaunch`
4. 필요 시 `xcode-select --install`로 CLT 재설치
5. 점검 스크립트 실행: `./scripts/check_xcode_toolchain.sh`
