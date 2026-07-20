import os
import httpx
from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel
from typing import Any, Optional
from auth_utils import get_current_user
from database import get_supabase
from supabase import Client
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(prefix="/portfolio", tags=["portfolio"])

class PortfolioUpdate(BaseModel):
    content: Any

class LocationUpdate(BaseModel):
    lat: Optional[float] = None
    lon: Optional[float] = None

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
async def update_location(request: Request, update: LocationUpdate, supabase: Client = Depends(get_supabase), user: str = Depends(get_current_user)):
    try:
        city = "Delhi"
        country = "IN"
        full_location = "Delhi,IN"
        lat = update.lat
        lon = update.lon

        # 1. If GPS coordinates provided, prioritize them
        if lat is not None and lon is not None:
            # Try reverse geocoding to get a city name for display
            api_key = os.getenv("OPENWEATHER_API_KEY")
            if api_key:
                try:
                    async with httpx.AsyncClient() as client:
                        geo_url = f"http://api.openweathermap.org/geo/1.0/reverse?lat={lat}&lon={lon}&limit=1&appid={api_key}"
                        geo_res = await client.get(geo_url, timeout=5.0)
                        if geo_res.status_code == 200:
                            geo_data = geo_res.json()
                            if geo_data:
                                city = geo_data[0].get("name", "Delhi")
                                country = geo_data[0].get("country", "IN")
                                full_location = f"{city},{country}"
                except Exception:
                    pass
        else:
            # Fallback to IP-based detection if GPS not provided
            vercel_city = request.headers.get("x-vercel-ip-city")
            vercel_country = request.headers.get("x-vercel-ip-country")
            
            if vercel_city and vercel_country:
                city = vercel_city
                country = vercel_country
                full_location = f"{city},{country}"
            else:
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
                            # Also grab coords from IP as secondary backup
                            lat = ip_data.get("lat")
                            lon = ip_data.get("lon")

        # 2. Get current basics
        res = supabase.table("portfolio_data").select("content").eq("section", "basics").single().execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Basics section not found")
        
        basics = res.data["content"]
        basics["location"] = full_location
        basics["lat"] = lat
        basics["lon"] = lon
        
        # 3. Save back to DB
        supabase.table("portfolio_data").upsert({
            "section": "basics",
            "content": basics,
            "updated_at": "now()"
        }).execute()
        
        return {"status": "success", "location": full_location, "lat": lat, "lon": lon}
    except Exception as e:
        print(f"Error updating location: {e}")
        raise HTTPException(status_code=500, detail=str(e))
