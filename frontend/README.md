# GSST Frontend

GSST 프로젝트의 프론트엔드 애플리케이션입니다. Flutter로 개발되었으며, 사용자에게 직관적인 UI를 제공하고 백엔드 API와 통신하여 다양한 기능을 수행합니다.

## 🚀 주요 기능

- 사용자 회원가입 및 로그인 (카카오 로그인 연동)
- 스마트 목표 설정 및 관리
- 레시피 팁 조회 및 등록
- 마이페이지 (닉네임 설정 등)

## 🛠️ 기술 스택

- **Framework**: Flutter
- **State Management**: (코드 분석 후 추가 예정)
- **HTTP 통신**: http
- **로컬 저장소**: flutter_secure_storage
- **인증**: kakao_flutter_sdk
- **환경 변수 관리**: flutter_dotenv
- **이미지 선택**: image_picker

## ⚙️ 실행 방법

1.  **Flutter SDK 설치**
    [Flutter 공식 문서](https://flutter.dev/docs/get-started/install)를 참조하여 Flutter SDK를 설치합니다.

2.  **의존성 설치**
    프로젝트 루트 디렉토리에서 다음 명령어를 실행합니다.
    ```bash
    flutter pub get
    ```

3.  **환경 변수 설정**
    `.env` 파일을 생성하고 필요한 환경 변수 (예: 백엔드 API URL, 카카오 API 키)를 설정합니다.

4.  **애플리케이션 실행**
    ```bash
    flutter run
    ```
    또는 특정 디바이스에서 실행하려면:
    ```bash
    flutter run -d <device_id>
    ```

## 📁 디렉토리 구조

```
frontend/
├── lib/              # Dart 소스 코드
│   ├── main.dart     # 애플리케이션 진입점
│   ├── app/          # 앱의 전반적인 구조 및 초기 화면
│   ├── auth/         # 인증 관련 화면 (로그인, 회원가입)
│   ├── mypage/       # 마이페이지 관련 화면
│   └── recipe_tips/  # 레시피 팁 관련 화면
├── assets/           # 이미지, 폰트 등 리소스 파일
├── pubspec.yaml      # 프로젝트 의존성 및 메타데이터
└── .env.example      # 환경 변수 예시 파일
```