import json
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import os
import google.generativeai as genai
from dotenv import load_dotenv
import requests
from bs4 import BeautifulSoup
from googleapiclient.discovery import build

router = APIRouter()

# --- 데이터 모델 ---

class Recipe(BaseModel):
    name: str
    description: Optional[str] = None
    ingredients: List[str]
    cooking_time: int
    cost: int
    tags: List[str]
    instructions: List[str]
    source_url: Optional[str] = None

class RecommendationRequest(BaseModel):
    meal_goal: Optional[str] = None
    cooking_time: Optional[int] = None
    cost: Optional[int] = None
    include_ingredients: Optional[List[str]] = []
    available_ingredients: Optional[List[str]] = []
    preference_keywords: Optional[List[str]] = []
    avoid_keywords: Optional[List[str]] = []

# --- API 및 모델 설정 ---
try:
    # .env 파일의 절대 경로를 동적으로 계산
    dotenv_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), '.env')
    load_dotenv(dotenv_path=dotenv_path)
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
    GOOGLE_CSE_ID = os.getenv("GOOGLE_CSE_ID")

    if not all([GEMINI_API_KEY, GOOGLE_API_KEY, GOOGLE_CSE_ID]):
        raise ValueError("하나 이상의 필수 환경 변수가 설정되지 않았습니다.")

    genai.configure(api_key=GEMINI_API_KEY)
    gemini_model = genai.GenerativeModel('gemini-2.5-flash')
    google_search_service = build("customsearch", "v1", developerKey=GOOGLE_API_KEY)
    print("API 및 모델 초기화 성공 (recommend.py)")

except Exception as e:
    print(f"API 초기화 오류 (recommend.py): {e}")
    gemini_model = None
    google_search_service = None

# --- 헬퍼 함수 ---

def search_google(query: str, num: int = 1) -> List[str]:
    if not google_search_service:
        return []
    try:
        result = google_search_service.cse().list(
            q=query,
            cx=GOOGLE_CSE_ID,
            num=num,
            siteSearch="www.10000recipe.com",
            siteSearchFilter="i"
        ).execute()
        return [item['link'] for item in result.get('items', [])]
    except Exception as e:
        print(f"Google 검색 오류: {e}")
        return []

def crawl_recipe(url: str) -> Optional[str]:
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 레시피 제목, 재료, 설명, 조리법 등 주요 정보를 포함하는 영역 선택
        # (만개의 레시피 사이트 구조에 따라 셀렉터는 변경될 수 있음)
        title = soup.find('h3').get_text(strip=True) if soup.find('h3') else "제목 없음"
        ingredients = soup.find('div', class_='ready_ingre3')
        ingredients_text = ingredients.get_text('\n', strip=True) if ingredients else "재료 정보 없음"
        
        recipe_steps = soup.find_all('div', class_='view_step_cont')
        steps_text = "\n".join([f"{i+1}. {step.get_text(strip=True)}" for i, step in enumerate(recipe_steps)])
        
        full_text = f"URL: {url}\n제목: {title}\n재료: {ingredients_text}\n조리법:\n{steps_text}"
        return full_text
    except Exception as e:
        print(f"크롤링 오류 ({url}): {e}")
        return None

# --- API 엔드포인트 ---

@router.post("/recommend", response_model=List[Recipe])
async def recommend_recipe(request: RecommendationRequest):
    if not gemini_model:
        raise HTTPException(status_code=500, detail="Gemini API 모델이 초기화되지 않았습니다.")

    # --- 1단계: 검색 키워드 생성 ---
    keyword_prompt = f"""
    사용자의 다음 요청에 가장 적합한 '만개의 레시피' 검색 키워드 3개를 생성해줘.
    각 키워드는 검색에 최적화된 단순하고 명확한 형태로, 한 줄에 하나씩만 응답해줘.
    
    [사용자 요청]
    - 식사 목표: {request.meal_goal or '지정 안 함'}
    - 최대 조리 시간: {request.cooking_time or '지정 안 함'}분
    - 최대 비용: {request.cost or '지정 안 함'}원
    - 포함할 재료: {', '.join(request.include_ingredients) or '없음'}
    - 보유 재료: {', '.join(request.available_ingredients) or '없음'}
    - 선호 키워드: {', '.join(request.preference_keywords) or '없음'}
    - 기피 키워드: {', '.join(request.avoid_keywords) or '없음'}
    
    [검색 키워드 예시]
    닭가슴살 다이어트 요리
    초간단 김치찌개
    자취생 간단요리
    """
    
    try:
        response = await gemini_model.generate_content_async(keyword_prompt)
        search_keywords = [kw.strip() for kw in response.text.split('\n') if kw.strip()]
        print(f"생성된 검색 키워드: {search_keywords}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"키워드 생성 중 오류: {e}")

    # --- 2단계: 크롤링 ---
    crawled_texts = []
    for keyword in search_keywords[:3]: # 최대 3개 키워드 사용
        urls = search_google(keyword, num=1)
        if not urls: continue
        
        text = crawl_recipe(urls[0])
        if text:
            crawled_texts.append(text)

    if not crawled_texts:
        raise HTTPException(status_code=404, detail="관련 레시피를 찾거나 크롤링할 수 없습니다.")

    # --- 3단계: 순위화 및 JSON 변환 ---
    final_prompt = f"""
    다음은 내가 '만개의 레시피'에서 수집한 레시피 정보다.
    
    [사용자 최초 요청]
    - 식사 목표: {request.meal_goal or '지정 안 함'}
    - 최대 조리 시간: {request.cooking_time or '지정 안 함'}분
    - 최대 비용: {request.cost or '지정 안 함'}원
    - 포함할 재료: {', '.join(request.include_ingredients) or '없음'}
    - 보유 재료: {', '.join(request.available_ingredients) or '없음'}
    - 선호 키워드: {', '.join(request.preference_keywords) or '없음'}
    - 기피 키워드: {', '.join(request.avoid_keywords) or '없음'}
    
    [수집된 레시피 정보]
    {"---".join(crawled_texts)}
    
    [너의 임무]
    1. 위 [사용자 최초 요청]에 가장 부합하는 순서대로 [수집된 레시피 정보]의 순위를 매겨라.
    2. 순위가 매겨진 3개의 레시피를 각각 아래 JSON 형식에 맞춰 완벽하게 정리해라.
    3. 최종 결과는 반드시 3개의 JSON 객체를 포함하는 단일 JSON 배열(리스트)로만 응답해라. 다른 텍스트는 절대 포함하지 마라.

    [JSON 응답 형식]
    {json.dumps([{"name": "string", "description": "string", "ingredients": ["string"], "cooking_time": 0, "cost": 0, "tags": ["string"], "instructions": ["string"], "source_url": "string"}], ensure_ascii=False, indent=2)}
    """

    try:
        response = await gemini_model.generate_content_async(final_prompt)
        response_text = response.text.strip()
        if response_text.startswith("```json"):
            json_str = response_text[len("```json"):-len("```")].strip()
        else:
            json_str = response_text
            
        recipes_data = json.loads(json_str)
        return [Recipe(**data) for data in recipes_data]
        
    except Exception as e:
        print(f"최종 레시피 생성 오류: {e}")
        print(f"오류 발생 당시 Gemini 응답: {response.text if 'response' in locals() else 'N/A'}")
        raise HTTPException(status_code=500, detail=f"최종 레시피 생성 중 오류 발생: {e}")