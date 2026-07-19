from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from database import get_supabase
from models import PostCreate, PostOut
from auth_utils import get_current_user
from supabase import Client

router = APIRouter(prefix="/posts", tags=["posts"])

@router.get("", response_model=List[PostOut])
async def list_posts(supabase: Client = Depends(get_supabase)):
    response = supabase.table("posts").select("*").order("created_at", desc=True).execute()
    return response.data

@router.get("/{post_id}", response_model=PostOut)
async def get_post(post_id: int, supabase: Client = Depends(get_supabase)):
    response = supabase.table("posts").select("*").eq("id", post_id).single().execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Post not found")
    return response.data

@router.post("", response_model=PostOut, status_code=status.HTTP_201_CREATED)
async def create_post(
    post: PostCreate, 
    supabase: Client = Depends(get_supabase), 
    current_user: str = Depends(get_current_user)
):
    # Use field names (snake_case) for DB insertion explicitly
    data = post.model_dump(exclude_none=True, by_alias=False)
    response = supabase.table("posts").insert(data).execute()
    if not response.data:
        raise HTTPException(status_code=500, detail="Failed to create post")
    return response.data[0]

@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_post(
    post_id: int, 
    supabase: Client = Depends(get_supabase), 
    current_user: str = Depends(get_current_user)
):
    # Fetch the post to get image paths
    res = supabase.table("posts").select("images", "video_url").eq("id", post_id).single().execute()
    if res.data:
        file_names = []
        # Cleanup images
        if res.data.get("images"):
            for url in res.data["images"]:
                if "uploads/" in url:
                    file_names.append(url.split("uploads/")[-1])
        
        # Cleanup video
        video_url = res.data.get("videoUrl") or res.data.get("video_url")
        if video_url and "uploads/" in video_url:
            file_names.append(video_url.split("uploads/")[-1])
        
        # Delete from Supabase Storage
        if file_names:
            try:
                supabase.storage.from_("uploads").remove(file_names)
            except Exception as e:
                print(f"Failed to cleanup storage: {e}")

    # Delete the post record
    response = supabase.table("posts").delete().eq("id", post_id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Post not found")
    return None
