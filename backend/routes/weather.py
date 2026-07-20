import os
import httpx
from fastapi import APIRouter, HTTPException, Depends
from supabase import Client
from database import get_supabase
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(prefix="/weather", tags=["weather"])

@router.get("")
async def get_weather(supabase: Client = Depends(get_supabase)):
    api_key = os.getenv("OPENWEATHER_API_KEY")
    
    # 1. Fetch location and coordinates from portfolio_data
    city = "Delhi,IN"
    lat = None
    lon = None
    try:
        res = supabase.table("portfolio_data").select("content").eq("section", "basics").single().execute()
        if res.data:
            content = res.data["content"]
            city = content.get("location", "Delhi,IN")
            lat = content.get("lat")
            lon = content.get("lon")
    except Exception:
        pass

    if not api_key:
        return {
            "condition": "Clear",
            "temperature": 32,
            "feelsLike": 35,
            "description": f"clear sky (Mocked for {city})",
            "icon": "01d",
            "humidity": 45,
            "windSpeed": 3.5,
            "location": city.split(",")[0]
        }
    
    try:
        # Prioritize Coordinates for pinpoint accuracy
        if lat is not None and lon is not None:
            url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}&units=metric"
        else:
            url = f"https://api.openweathermap.org/data/2.5/weather?q={city}&appid={api_key}&units=metric"
            
        async with httpx.AsyncClient() as client:
            response = await client.get(url)
            if response.status_code == 200:
                data = response.json()
                return {
                    "condition": data["weather"][0]["main"],
                    "temperature": round(data["main"]["temp"]),
                    "feelsLike": round(data["main"]["feels_like"]),
                    "description": data["weather"][0]["description"],
                    "icon": data["weather"][0]["icon"],
                    "humidity": data["main"]["humidity"],
                    "windSpeed": data["wind"]["speed"],
                    "location": data.get("name", city.split(",")[0])
                }
    except Exception as e:
        print(f"Weather error: {e}")
    
    raise HTTPException(status_code=502, detail="Weather service error")
