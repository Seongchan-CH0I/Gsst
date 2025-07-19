import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, Column, Integer, String, DateTime, func
from sqlalchemy.orm import sessionmaker, declarative_base
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta, timezone
from typing import List, Optional

# --- 1. 데이터베이스 설정 및 연결 (Foundation) ---

# .env 파일에서 환경 변수 로드
# auth.py 파일의 위치를 기준으로 상위 디렉토리의 .env 파일을 찾습니다.
dotenv_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), '.env')
load_dotenv(dotenv_path=dotenv_path)

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

# SQLAlchemy 데이터베이스 URL 생성
DATABASE_URL = f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# SQLAlchemy 엔진 생성
engine = create_engine(DATABASE_URL)

# 데이터베이스 세션 생성을 위한 SessionLocal 클래스
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 데이터베이스 모델의 기본 클래스
Base = declarative_base()

# FastAPI 의존성으로 사용될 데이터베이스 세션 제공 함수
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

print(f"데이터베이스 연결 설정 완료. URL: {DATABASE_URL}")

# --- 2. 데이터베이스 모델 정의 (Foundation) ---

# users 테이블에 매핑될 User 클래스
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password = Column(String(255), nullable=True)  # 소셜 로그인의 경우 null일 수 있음
    name = Column(String(100), nullable=False)
    social_provider = Column(String(50), nullable=True)
    social_id = Column(String(255), nullable=True)
    
    # server_default와 onupdate를 사용하여 DB에서 자동으로 시간 관리
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

print("데이터베이스 모델 정의 완료: User")


# --- 다음 단계에 구현될 코드 영역 ---
# 3. 데이터 스키마 정의
# 4. 보안 유틸리티 구현
# 5. 데이터베이스 CRUD 함수 구현
# 6. API 라우터 및 엔드포인트 구현
