# GSST Backend

GSST 프로젝트의 백엔드 서버입니다. FastAPI를 기반으로 구축되었으며, 사용자 인증, 데이터 처리 및 프론트엔드 애플리케이션에 필요한 API를 제공합니다.

## 🚀 주요 기능

- 사용자 회원가입 및 로그인 (JWT 기반 인증)
- AI를 활용한 추천 기능
- 레시피 팁 제공
- 마이페이지 기능

## 🛠️ 기술 스택

- **Framework**: FastAPI
- **Web Server**: Uvicorn
- **Authentication**: python-jose, passlib
- **Database**: MySQL (mysql-connector-python)
- **AI**: google-generativeai
- **Etc**: requests, beautifulsoup4, Pillow

## ⚙️ 실행 방법

1.  **가상 환경 생성 및 활성화**
    ```bash
    python -m venv venv
    source venv/bin/activate  # Windows: venv\Scripts\activate
    ```

2.  **의존성 설치**
    ```bash
    pip install -r requirements.txt
    ```

3.  **환경 변수 설정**
    `.env` 파일을 생성하고 필요한 환경 변수 (예: 데이터베이스 정보, API 키)를 설정합니다.

4.  **서버 실행**
    ```bash
    uvicorn main:app --reload
    ```
    서버는 `http://127.0.0.1:8000`에서 실행됩니다.

## 📁 디렉토리 구조

```
backend/
├── main.py           # FastAPI 애플리케이션의 메인 파일
├── requirements.txt  # 프로젝트 의존성 목록
├── .env.example      # 환경 변수 예시 파일
├── auth/             # 인증 관련 로직 (로그인, 회원가입)
├── routers/          # API 엔드포인트 (라우터) 정의
└── static/           # 정적 파일 (이미지 등)
```
