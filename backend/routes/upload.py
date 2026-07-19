import os
import uuid
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from supabase import Client
from database import get_supabase
from auth_utils import get_current_user
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(prefix="/upload", tags=["upload"])

@router.post("")
async def upload_file(
    file: UploadFile = File(...),
    current_user: str = Depends(get_current_user),
    supabase: Client = Depends(get_supabase)
):
    # Enforce 50MB limit
    MAX_SIZE = 50 * 1024 * 1024 # 50MB
    
    # Read file content into memory
    contents = await file.read()
    file_size = len(contents)
    
    if file_size > MAX_SIZE:
        raise HTTPException(status_code=413, detail="File too large. Max limit is 50MB.")

    # Allow images and videos
    if not (file.content_type.startswith("image/") or file.content_type.startswith("video/")):
        raise HTTPException(status_code=400, detail="Only images and videos are allowed")
    
    file_ext = file.filename.split(".")[-1]
    file_name = f"{uuid.uuid4()}.{file_ext}"
    
    try:
        supabase.storage.from_("uploads").upload(
            path=file_name,
            file=contents,
            file_options={"content-type": file.content_type}
        )
        
        url = supabase.storage.from_("uploads").get_public_url(file_name)
        return {"url": url}
    except Exception as e:
        print(f"Upload error: {e}")
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")
