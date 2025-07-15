import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
import google.generativeai as genai
from dotenv import load_dotenv # 이 줄을 추가합니다.

app = FastAPI()

# CORS 설정
origins = [
    "http://localhost",
    "http://localhost:8080", # Flutter web default port
    "http://127.0.0.1:8080",
    "http://localhost:5000", # Another common Flutter web port
    "http://127.0.0.1:5000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Data Models ---

class Recipe(BaseModel):
    name: str
    description: Optional[str] = None
    ingredients: List[str]
    cooking_time: int  # minutes
    cost: int  # KRW
    tags: List[str]
    instructions: List[str]
    source_url: Optional[str] = None

class RecommendationRequest(BaseModel):
    meal_goal: Optional[str] = None
    cooking_time: Optional[int] = None # max cooking time in minutes
    cost: Optional[int] = None # max cost in KRW
    include_ingredients: Optional[List[str]] = []
    available_ingredients: Optional[List[str]] = []
    preference_keywords: Optional[List[str]] = []
    avoid_keywords: Optional[List[str]] = []

# --- Gemini API 설정 ---
try:
    load_dotenv() # 이 줄을 추가합니다. .env 파일에서 환경 변수를 로드합니다.
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    print(f"Loaded GEMINI_API_KEY: {GEMINI_API_KEY[:5]}...") 
    if not GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY 환경 변수가 설정되지 않았습니다.")
    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel('gemini-2.5-flash')
    print("Gemini model initialized successfully.")
except Exception as e:
    print(f"Gemini API 초기화 오류: {e}")
    model = None # 모델 초기화 실패 시 None으로 설정

# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"message": "Recipe recommendation API is running."}

@app.post("/recommend", response_model=Recipe)
def recommend_recipe(request: RecommendationRequest):
    if model is None:
        raise HTTPException(status_code=500, detail="Gemini API 모델이 초기화되지 않았습니다.")

    # 프롬프트 생성
    prompt_parts = [
        "사용자의 요청에 따라 레시피를 생성해줘. 다음 JSON 형식으로 응답해야 해:",
        json.dumps({
            "name": "string",
            "description": "string",
            "ingredients": ["string"],
            "cooking_time": "integer",
            "cost": "integer",
            "tags": ["string"],
            "instructions": ["string"],
            "source_url": "string or null"
        }, ensure_ascii=False, indent=2),
        "\n요청 조건:",
    ]

    if request.meal_goal:
        prompt_parts.append(f"- 식사 목표: {request.meal_goal}")
    if request.cooking_time:
        prompt_parts.append(f"- 최대 조리 시간: {request.cooking_time}분")
    if request.cost:
        prompt_parts.append(f"- 최대 비용: {request.cost}원")
    if request.include_ingredients:
        prompt_parts.append(f"- 반드시 포함할 재료: {', '.join(request.include_ingredients)}")
    if request.available_ingredients:
        prompt_parts.append(f"- 보유 중인 재료: {', '.join(request.available_ingredients)}")
    if request.preference_keywords:
        prompt_parts.append(f"- 선호 키워드: {', '.join(request.preference_keywords)}")
    if request.avoid_keywords:
        prompt_parts.append(f"- 기피 키워드: {', '.join(request.avoid_keywords)}")

    full_prompt = "\n".join(prompt_parts)
    print(f"Gemini 프롬프트:\n{full_prompt}")

    try:
        response = model.generate_content(full_prompt)
        print(f"Gemini Raw Response: {response.text}") # Gemini 모델의 원본 응답 출력
        # Gemini 응답에서 JSON 문자열 추출 및 파싱
        # 응답이 코드 블록으로 올 수 있으므로 파싱 로직 추가
        response_text = response.text.strip()
        if response_text.startswith("```json") and response_text.endswith("```"):
            json_str = response_text[len("```json"):-len("```")].strip()
        else:
            json_str = response_text # 코드 블록이 아니면 전체를 JSON으로 간주

        recipe_data = json.loads(json_str)
        return Recipe(**recipe_data)
    except Exception as e:
        print(f"Gemini API 호출 또는 응답 파싱 오류: {e}")
        raise HTTPException(status_code=500, detail=f"레시피 생성 중 오류 발생: {e}")
