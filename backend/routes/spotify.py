import os
import base64
import httpx
from urllib.parse import urlencode
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, HTTPException, Depends, Request
from fastapi.responses import RedirectResponse, HTMLResponse
from database import get_supabase
from supabase import Client
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(prefix="/spotify", tags=["spotify"])

CLIENT_ID = os.getenv("SPOTIFY_CLIENT_ID")
CLIENT_SECRET = os.getenv("SPOTIFY_CLIENT_SECRET")
# Use dynamic environment variables for deployment, ensuring no trailing/leading spaces
REDIRECT_URI = os.getenv("SPOTIFY_REDIRECT_URI", "http://127.0.0.1:8000/api/spotify/callback").strip()
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:3000").strip()

SUCCESS_HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Spotify Connected!</title>
    <style>
        body { background-color: #0A0A14; color: white; font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .card { background: rgba(255,255,255,0.05); padding: 40px; border-radius: 20px; text-align: center; border: 1px solid rgba(255,255,255,0.1); }
        h1 { color: #1DB954; margin-bottom: 10px; }
        p { color: rgba(255,255,255,0.6); margin-bottom: 30px; }
        button { background: #1DB954; border: none; color: white; padding: 12px 30px; border-radius: 30px; font-weight: bold; cursor: pointer; }
    </style>
</head>
<body>
    <div class="card">
        <h1>✔ Spotify Connected</h1>
        <p>Your portfolio is now linked to your account.<br>You can close this tab now.</p>
        <button onclick="window.close()">Close Window</button>
    </div>
</body>
</html>
"""

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
    return RedirectResponse(f"https://accounts.spotify.com/authorize?{urlencode(params)}")

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

            return HTMLResponse(content=SUCCESS_HTML)
    except Exception as e:
        return {"error": "internal_crash", "details": str(e)}

@router.get("/now-playing")
async def now_playing(supabase: Client = Depends(get_supabase)):
    if not CLIENT_ID:
        return {"isPlaying": False, "isLinked": False}
    
    access_token = await get_access_token(supabase)
    is_linked = access_token is not None
    
    if not is_linked:
        return {"isPlaying": False, "isLinked": False}
    
    try:
        async with httpx.AsyncClient() as client:
            headers = {"Authorization": f"Bearer {access_token}"}
            response = await client.get("https://api.spotify.com/v1/me/player/currently-playing", headers=headers)
            
            if response.status_code == 204 or response.status_code != 200:
                return {"isPlaying": False, "isLinked": True}
            
            data = response.json()
            if not data.get("item"):
                return {"isPlaying": data.get("is_playing", False), "isLinked": True}
            
            item = data["item"]
            return {
                "isPlaying": data["is_playing"],
                "isLinked": True,
                "trackName": item["name"],
                "artistName": ", ".join([a["name"] for a in item["artists"]]),
                "albumName": item["album"]["name"],
                "albumArt": item["album"]["images"][0]["url"] if item["album"]["images"] else None,
                "trackUrl": item["external_urls"]["spotify"],
                "progressMs": data.get("progress_ms"),
                "durationMs": item["duration_ms"],
            }
    except Exception:
        return {"isPlaying": False, "isLinked": True}
