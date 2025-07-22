from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.routers import recommend, mypage
from backend.auth import auth

app = FastAPI()

# CORS 설정
origins = [
    "http://localhost",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 등록
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(recommend.router, prefix="/recipes", tags=["Recipes"])
app.include_router(mypage.router, prefix="/mypage", tags=["My Page"])

@app.get("/")
def read_root():
    return {"message": "Recipe recommendation API is running."}