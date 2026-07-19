import os
import httpx
from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel
from typing import Any
from auth_utils import get_current_user
from database import get_supabase
from supabase import Client
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(prefix="/portfolio", tags=["portfolio"])

class PortfolioUpdate(BaseModel):
    content: Any

@router.get("")
async def get_portfolio(supabase: Client = Depends(get_supabase)):
    try:
        res = supabase.table("portfolio_data").select("*").execute()
        # Convert list of rows to a dictionary keyed by section
        data = {row["section"]: row["content"] for row in res.data}
        return data
    except Exception as e:
        print(f"Error fetching portfolio: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch portfolio data")

@router.patch("/{section}")
async def update_portfolio(section: str, update: PortfolioUpdate, supabase: Client = Depends(get_supabase), user: str = Depends(get_current_user)):
    try:
        res = supabase.table("portfolio_data").upsert({
            "section": section,
            "content": update.content,
            "updated_at": "now()"
        }).execute()
        
        if not res.data:
            raise HTTPException(status_code=400, detail="Failed to update section")
            
        return {"status": "success", "section": section}
    except Exception as e:
        print(f"Error updating portfolio section {section}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/update-location")
async def update_location(request: Request, supabase: Client = Depends(get_supabase), user: str = Depends(get_current_user)):
    try:
        # 1. Detect location via Vercel Headers or Client IP
        city = "Delhi"
        country = "IN"
        
        # Priority: Vercel Geo Headers
        vercel_city = request.headers.get("x-vercel-ip-city")
        vercel_country = request.headers.get("x-vercel-ip-country")
        
        if vercel_city and vercel_country:
            city = vercel_city
            country = vercel_country
        else:
            # Fallback: IP-based lookup using real client IP
            client_ip = request.headers.get("x-forwarded-for", "").split(",")[0].strip()
            async with httpx.AsyncClient() as client:
                url = f"http://ip-api.com/json/{client_ip}" if client_ip else "http://ip-api.com/json/"
                ip_res = await client.get(url, timeout=5.0)
                if ip_res.status_code == 200:
                    ip_data = ip_res.json()
                    if ip_data.get("status") == "success":
                        city = ip_data.get("city", "Delhi")
                        country = ip_data.get("countryCode", "IN")
        
        full_location = f"{city},{country}"
        
        # 2. Get current basics
        res = supabase.table("portfolio_data").select("content").eq("section", "basics").single().execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Basics section not found")
        
        basics = res.data["content"]
        basics["location"] = full_location
        
        # 3. Save back to DB
        supabase.table("portfolio_data").upsert({
            "section": "basics",
            "content": basics,
            "updated_at": "now()"
        }).execute()
        
        return {"status": "success", "location": full_location}
    except Exception as e:
        print(f"Error updating location: {e}")
        raise HTTPException(status_code=500, detail=str(e))
