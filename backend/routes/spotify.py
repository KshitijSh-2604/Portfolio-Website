import os
import base64
import httpx
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, HTTPException, Depends, Request
from fastapi.responses import RedirectResponse
from database import get_supabase
from supabase import Client
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(prefix="/spotify", tags=["spotify"])

CLIENT_ID = os.getenv("SPOTIFY_CLIENT_ID")
CLIENT_SECRET = os.getenv("SPOTIFY_CLIENT_SECRET")
# Ensure this matches exactly what is in your Spotify Developer Dashboard
REDIRECT_URI = "http://127.0.0.1:8000/api/spotify/callback"
# After processing, redirect user back to the frontend
FRONTEND_URL = "http://localhost:3000"

async def get_access_token(supabase: Client):
    try:
        response = supabase.table("spotify_tokens").select("*").eq("id", 1).execute()
        if not response.data:
            return None
        
        token_row = response.data[0]
        # Handle 'Z' or '+00:00' suffix
        expires_str = token_row["expires_at"].replace("Z", "+00:00")
        expires_at = datetime.fromisoformat(expires_str)
        
        # If valid (with 60s buffer), return
        if expires_at.timestamp() > datetime.now(timezone.utc).timestamp() + 60:
            return token_row["access_token"]
        
        # Refresh
        auth_str = f"{CLIENT_ID}:{CLIENT_SECRET}"
        auth_b64 = base64.b64encode(auth_str.encode()).decode()
        
        payload = {
            "grant_type": "refresh_token",
            "refresh_token": token_row["refresh_token"],
        }
        
        headers = {
            "Authorization": f"Basic {auth_b64}",
            "Content-Type": "application/x-www-form-urlencoded",
        }
        
        async with httpx.AsyncClient() as client:
            resp = await client.post("https://accounts.spotify.com/api/token", data=payload, headers=headers)
            if resp.status_code != 200:
                return None
            
            data = resp.json()
            new_access_token = data["access_token"]
            new_refresh_token = data.get("refresh_token", token_row["refresh_token"])
            new_expires_at = (datetime.now(timezone.utc) + timedelta(seconds=data["expires_in"])).isoformat()
            
            supabase.table("spotify_tokens").update({
                "access_token": new_access_token,
                "refresh_token": new_refresh_token,
                "expires_at": new_expires_at
            }).eq("id", 1).execute()
            
            return new_access_token
    except Exception:
        return None

@router.get("/auth")
async def spotify_auth():
    if not CLIENT_ID:
        raise HTTPException(status_code=503, detail="Spotify not configured")
    
    scopes = "user-read-currently-playing user-read-playback-state"
    params = {
        "response_type": "code",
        "client_id": CLIENT_ID,
        "scope": scopes,
        "redirect_uri": REDIRECT_URI,
    }
    query_str = "&".join([f"{k}={v}" for k, v in params.items()])
    return RedirectResponse(f"https://accounts.spotify.com/authorize?{query_str}")

@router.get("/callback")
async def spotify_callback(code: str = None, error: str = None, supabase: Client = Depends(get_supabase)):
    if error or not code:
        return RedirectResponse(f"{FRONTEND_URL}?error={error or 'no_code'}")

    try:
        auth_str = f"{CLIENT_ID}:{CLIENT_SECRET}"
        auth_b64 = base64.b64encode(auth_str.encode()).decode()
        
        payload = {
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": REDIRECT_URI,
        }
        
        headers = {
            "Authorization": f"Basic {auth_b64}",
            "Content-Type": "application/x-www-form-urlencoded",
        }
        
        async with httpx.AsyncClient() as client:
            resp = await client.post("https://accounts.spotify.com/api/token", data=payload, headers=headers)
            if resp.status_code != 200:
                # Return JSON error to debug exchange issues
                return {"error": "token_exchange_failed", "status": resp.status_code, "body": resp.text}
            
            data = resp.json()
            access_token = data["access_token"]
            refresh_token = data["refresh_token"]
            # Ensure ISO format with timezone
            expires_at = (datetime.now(timezone.utc) + timedelta(seconds=data["expires_in"])).isoformat()

            # Update or insert token with id=1
            supabase.table("spotify_tokens").upsert({
                "id": 1,
                "access_token": access_token,
                "refresh_token": refresh_token,
                "expires_at": expires_at
            }).execute()

            return RedirectResponse(FRONTEND_URL)
    except Exception as e:
        return {"error": "internal_crash", "details": str(e)}

@router.get("/now-playing")
async def now_playing(supabase: Client = Depends(get_supabase)):
    if not CLIENT_ID:
        return {"isPlaying": False}
    
    access_token = await get_access_token(supabase)
    if not access_token:
        return {"isPlaying": False}
    
    try:
        async with httpx.AsyncClient() as client:
            headers = {"Authorization": f"Bearer {access_token}"}
            response = await client.get("https://api.spotify.com/v1/me/player/currently-playing", headers=headers)
            
            if response.status_code == 204 or response.status_code != 200:
                return {"isPlaying": False}
            
            data = response.json()
            if not data.get("item"):
                return {"isPlaying": data.get("is_playing", False)}
            
            item = data["item"]
            return {
                "isPlaying": data["is_playing"],
                "trackName": item["name"],
                "artistName": ", ".join([a["name"] for a in item["artists"]]),
                "albumName": item["album"]["name"],
                "albumArt": item["album"]["images"][0]["url"] if item["album"]["images"] else None,
                "trackUrl": item["external_urls"]["spotify"],
                "progressMs": data.get("progress_ms"),
                "durationMs": item["duration_ms"],
            }
    except Exception:
        return {"isPlaying": False}
