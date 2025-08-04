from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, func, ForeignKey
from sqlalchemy.orm import relationship
from ..auth.auth import Base, get_db, engine, User, get_current_user

# --- SQLAlchemy Model (데이터베이스 테이블 정의) ---

class RecipeTip(Base):
    __tablename__ = "recipe_tips"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(100), index=True)
    content = Column(String(1000))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    owner_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="tips")

# 데이터베이스에 테이블 생성
Base.metadata.create_all(bind=engine)

router = APIRouter(
    tags=["tips"],
)

# --- Pydantic Schemas (API 데이터 형식 정의) ---

class TipOwner(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True

class TipBase(BaseModel):
    title: str
    content: str

class TipCreate(TipBase):
    pass

class Tip(TipBase):
    id: int
    created_at: datetime
    owner: TipOwner

    class Config:
        from_attributes = True


# --- API Endpoints (라우터) ---

@router.get("/", response_model=list[Tip])
def read_tips(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    tips = db.query(RecipeTip).offset(skip).limit(limit).all()
    return tips

@router.post("/", response_model=Tip)
def create_tip(tip: TipCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_tip = RecipeTip(**tip.dict(), owner_id=current_user.id)
    db.add(db_tip)
    db.commit()
    db.refresh(db_tip)
    return db_tip

@router.get("/{tip_id}", response_model=Tip)
def read_tip(tip_id: int, db: Session = Depends(get_db)):
    db_tip = db.query(RecipeTip).filter(RecipeTip.id == tip_id).first()
    if db_tip is None:
        raise HTTPException(status_code=404, detail="Tip not found")
    return db_tip

@router.put("/{tip_id}", response_model=Tip)
def update_tip(tip_id: int, tip: TipCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_tip = db.query(RecipeTip).filter(RecipeTip.id == tip_id).first()
    if db_tip is None:
        raise HTTPException(status_code=404, detail="Tip not found")
    if db_tip.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this tip")
    
    for key, value in tip.dict().items():
        setattr(db_tip, key, value)
        
    db.commit()
    db.refresh(db_tip)
    return db_tip

@router.delete("/{tip_id}")
def delete_tip(tip_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_tip = db.query(RecipeTip).filter(RecipeTip.id == tip_id).first()
    if db_tip is None:
        raise HTTPException(status_code=404, detail="Tip not found")
    if db_tip.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this tip")
        
    db.delete(db_tip)
    db.commit()
    return {"ok": True}
