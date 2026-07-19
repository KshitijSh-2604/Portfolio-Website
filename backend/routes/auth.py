import os
from fastapi import APIRouter, HTTPException, status, Body
from auth_utils import create_access_token
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/login")
async def login(password: str = Body(embed=True)):
    expected = os.getenv("PORTFOLIO_PASSWORD")
    if not expected:
        raise HTTPException(status_code=500, detail="Auth not configured on server")
    
    if password != expected:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect password",
        )
    
    access_token = create_access_token(data={"sub": "owner"})
    return {"token": access_token}
