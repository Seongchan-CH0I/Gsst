from fastapi import APIRouter, Depends

# auth.py에서 필요한 의존성 및 스키마를 가져옵니다.
from backend.auth.auth import get_current_user, UserInDB

router = APIRouter()

# --- API 엔드포인트 ---

@router.get("/me", response_model=UserInDB, summary="내 정보 조회")
async def get_my_info(current_user: UserInDB = Depends(get_current_user)):

    return current_user