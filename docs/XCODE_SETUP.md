# Xcode/Toolchain 셋업 가이드

## 1) Xcode 설치 및 선택

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

## 2) 상태 점검

```bash
./scripts/check_xcode_toolchain.sh
```

정상 예시:
- `xcodebuild -version` 이 버전을 출력
- `swift --version` 정상 출력

## 3) Xcode 프로젝트 생성

```bash
brew install xcodegen
./scripts/generate_xcodeproj.sh
```

생성 파일:
- `ClassicLaunch.xcodeproj`

## 4) 아카이브 준비

- Signing Team 설정
- Bundle ID 확정 (`ai.openclaw.classiclaunch` → 실제 배포용으로 교체 권장)
- Release 구성으로 Archive 실행
