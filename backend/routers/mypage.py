from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.orm import Session
import shutil
import os
from PIL import Image

# auth.py에서 필요한 의존성 및 스키마를 가져옵니다.
from backend.auth.auth import get_current_user, UserInDB, get_db, User

router = APIRouter()

# --- API 엔드포인트 ---

@router.get("/me", response_model=UserInDB)
async def read_users_me(current_user: UserInDB = Depends(get_current_user)):
    return current_user

@router.post("/me/profile-image", response_model=UserInDB)
async def upload_profile_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    static_dir = "static"
    os.makedirs(static_dir, exist_ok=True)

    # Convert image to PNG
    image = Image.open(file.file)
    if image.mode != 'RGB':
        image = image.convert('RGB')
        
    # Change file extension to .png
    file_name, _ = os.path.splitext(file.filename)
    new_filename = f"{current_user.id}_{file_name}.png"
    file_path = os.path.join(static_dir, new_filename)

    image.save(file_path, 'PNG')

    file_url = f"/static/{new_filename}"

    current_user.profile_image_url = file_url
    db.add(current_user)
    db.commit()
    db.refresh(current_user)

    return current_user

