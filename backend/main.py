from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.routers import recommend

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
app.include_router(recommend.router)

@app.get("/")
def read_root():
    return {"message": "Recipe recommendation API is running."}