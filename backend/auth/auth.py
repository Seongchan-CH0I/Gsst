import os
import requests
from dotenv import load_dotenv
from sqlalchemy import create_engine, Column, Integer, String, DateTime, func
from sqlalchemy.orm import sessionmaker, declarative_base, Session, relationship
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta, timezone
from typing import List, Optional

# --- 1. 데이터베이스 설정 및 연결 (Foundation) ---
# DB = 창고, 엔진 = 창고의 중앙 전력 시스템, 세션 = 창고 안 물품을 가져와서 작업하는 공간, 베이스 = 창고의 지도

dotenv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env')
load_dotenv(dotenv_path=dotenv_path)
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

DATABASE_URL = f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}" #  SQLAlchemy에게 DB의 위치와 구조 전달

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- 2. 데이터베이스 모델 정의 (Foundation) ---

class User(Base):
    # id : 유저의 주민등록번호 역할 (고유 식별 번호)
    # email : 유저의 집 주소 역할 (언제든지 바뀔 수 있는 번호. 실제로 유저에게 보이는 데이터 값이므로 프로젝트의 중요 로직에 활용하기 어려움)
    # 굳이 나눠야하나? : 유지보수성(현존 어플들 대부분 이렇게 해옴), 접근성(외래키로 id를 사용하는 게 더 간편), 확장성(이메일 변경 기능이 언제 필요할지도 모름)
    # id - primary_key: users 테이블의 각 행이 모두 고유의 키를 가지도록 함. (users 테이블의 대표 식별자를 지정함)
    # email - unique: users 테이블의 각 행이 모두 고유의 이메일을 가지도록 함. (email 컬럼이 중복이 불가능하도록 함)
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False) 
    password = Column(String(255), nullable=True)
    name = Column(String(100), nullable=False)
    social_provider = Column(String(50), nullable=True)
    social_id = Column(String(255), nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    profile_image_url = Column(String(255), nullable=True)

    tips = relationship("RecipeTip", back_populates="owner")


# --- 3. 데이터 스키마 정의 (Schemas) ---

class UserBase(BaseModel):
    email: str

class UserCreate(UserBase):
    password: str

class SocialUserCreate(UserBase):
    social_provider: str
    social_id: str

class UserInDB(UserBase):
    id: int
    name: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    profile_image_url: Optional[str] = None
    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenResponse(Token):
    nickname_required: bool

class TokenData(BaseModel):
    email: Optional[str] = None

class NicknameUpdate(BaseModel):
    name: str

class KakaoAccessToken(BaseModel):
    access_token: str
class DevLoginRequest(BaseModel):
    email: str


# --- 4. 보안 유틸리티 (Security) ---
# 토큰 관련 작업이 이루어지는 곳

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
ALGORITHM = os.getenv("JWT_ALGORITHM")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
KAKAO_CLIENT_ID = os.getenv("KAKAO_CLIENT_ID")
KAKAO_REDIRECT_URI = os.getenv("KAKAO_REDIRECT_URI")


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


# --- 5. 데이터베이스 CRUD 함수 구현 (CRUD) ---

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def create_user(db: Session, user: UserCreate):
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        password=hashed_password,
        name=""
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def create_social_user(db: Session, user_info: SocialUserCreate):
    db_user = User(
        email=user_info.email,
        social_provider=user_info.social_provider,
        social_id=user_info.social_id,
        name=""
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


# --- 6. API 라우터 및 엔드포인트 구현 (API Layer) ---

router = APIRouter()

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception
    
    user = get_user_by_email(db, email=token_data.email)
    if user is None:
        raise credentials_exception
    return user

@router.post("/register", response_model=UserInDB, status_code=status.HTTP_201_CREATED, summary="회원가입")
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")
    return create_user(db=db, user=user)

@router.post("/login", response_model=TokenResponse, summary="로그인")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = get_user_by_email(db, email=form_data.username)
    if not user or not user.password or not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "nickname_required": user.name == ""
    }

@router.post("/login/kakao", response_model=TokenResponse, summary="카카오 소셜 로그인")
async def login_kakao(kakao_access_token: KakaoAccessToken, db: Session = Depends(get_db)):
    access_token = kakao_access_token.access_token

    # 1. 액세스 토큰으로 사용자 정보 요청
    user_info_url = "https://kapi.kakao.com/v2/user/me"
    user_info_headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-type": "application/x-www-form-urlencoded;charset=utf-8",
    }
    user_info_res = requests.get(user_info_url, headers=user_info_headers)
    user_info_json = user_info_res.json()

    if user_info_res.status_code != 200:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="카카오 사용자 정보 조회 실패")

    kakao_account = user_info_json.get("kakao_account")
    if not kakao_account or "email" not in kakao_account:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="카카오 계정에 이메일 정보가 없습니다. (사용자 동의 필요)")

    email = kakao_account.get("email")
    social_id = str(user_info_json.get("id"))

    # 2. 사용자 조회 및 생성
    user = get_user_by_email(db, email=email)
    if not user:
        user_info = SocialUserCreate(
            email=email,
            social_provider="kakao",
            social_id=social_id
        )
        user = create_social_user(db, user_info)
    
    # 3. 서비스 JWT 토큰 발급
    service_access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    service_access_token = create_access_token(
        data={"sub": user.email}, expires_delta=service_access_token_expires
    )
    return {
        "access_token": service_access_token,
        "token_type": "bearer",
        "nickname_required": user.name == ""
    }

@router.put("/me/nickname", response_model=UserInDB, summary="닉네임 설정")
async def update_nickname(nickname_data: NicknameUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not nickname_data.name or len(nickname_data.name.strip()) == 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nickname cannot be empty")
    
    current_user.name = nickname_data.name
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user

@router.post("/dev-login", response_model=Token, summary="개발용 로그인", include_in_schema=False)
async def dev_login_for_access_token(request: DevLoginRequest, db: Session = Depends(get_db)):
    user = get_user_by_email(db, email=request.email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found. Please register the user first.",
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserInDB, summary="현재 사용자 정보 확인")
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user