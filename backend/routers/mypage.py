from fastapi import APIRouter, Depends

# auth.py에서 필요한 의존성 및 스키마를 가져옵니다.
from backend.auth.auth import get_current_user, UserInDB

router = APIRouter()

# --- API 엔드포인트 ---

