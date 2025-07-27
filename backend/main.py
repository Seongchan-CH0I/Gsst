from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.routers import recommend, mypage
from backend.auth import auth
from backend.auth.auth import engine, Base # 데이터베이스 엔진과 Base 모델 가져오기

# 데이터베이스 테이블 생성
# 애플리케이션이 시작될 때, User 모델에 정의된 스키마를 바탕으로
# 데이터베이스에 'users' 테이블이 없으면 새로 생성합니다.
Base.metadata.create_all(bind=engine)

app = FastAPI()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

# 라우터 등록
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(recommend.router, prefix="/recipes", tags=["Recipes"])
app.include_router(mypage.router, prefix="/mypage", tags=["My Page"])