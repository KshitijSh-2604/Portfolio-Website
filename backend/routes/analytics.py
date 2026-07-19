import asyncio
from fastapi import APIRouter, Depends
from database import get_supabase
from supabase import Client
from typing import Set, Optional
from pydantic import BaseModel

router = APIRouter(prefix="/analytics", tags=["analytics"])

class VisitorRequest(BaseModel):
    visitor_id: str

@router.get("/views")
async def get_views(supabase: Client = Depends(get_supabase)):
    res = supabase.table("analytics").select("value").eq("key", "total_views").single().execute()
    return {"views": res.data["value"] if res.data else 0}

@router.post("/views/increment")
async def increment_views(req: VisitorRequest, supabase: Client = Depends(get_supabase)):
    visitor_id = req.visitor_id
    
    try:
        log_res = supabase.table("visitor_logs").insert({"id": visitor_id}).execute()
        
        if log_res.data:
            res = supabase.table("analytics").select("value").eq("key", "total_views").single().execute()
            current_value = res.data["value"] if res.data else 0
            supabase.table("analytics").update({"value": current_value + 1}).eq("key", "total_views").execute()
            return {"views": current_value + 1, "unique": True}
    except Exception:
        pass

    res = supabase.table("analytics").select("value").eq("key", "total_views").single().execute()
    return {"views": res.data["value"] if res.data else 0, "unique": False}
