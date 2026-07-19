import asyncio
from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from database import get_supabase
from supabase import Client
from typing import Set, Optional
from pydantic import BaseModel

router = APIRouter(prefix="/analytics", tags=["analytics"])

class VisitorRequest(BaseModel):
    visitor_id: str

# In-memory storage for current active websocket connections
active_connections: Set[WebSocket] = set()

@router.get("/views")
async def get_views(supabase: Client = Depends(get_supabase)):
    res = supabase.table("analytics").select("value").eq("key", "total_views").single().execute()
    return {"views": res.data["value"] if res.data else 0}

@router.post("/views/increment")
async def increment_views(req: VisitorRequest, supabase: Client = Depends(get_supabase)):
    visitor_id = req.visitor_id
    
    # Try to log this visitor
    try:
        # We use upsert-like logic or just insert and catch error
        log_res = supabase.table("visitor_logs").insert({"id": visitor_id}).execute()
        
        # If insert succeeded, increment the counter
        if log_res.data:
            res = supabase.table("analytics").select("value").eq("key", "total_views").single().execute()
            current_value = res.data["value"] if res.data else 0
            supabase.table("analytics").update({"value": current_value + 1}).eq("key", "total_views").execute()
            return {"views": current_value + 1, "unique": True}
    except Exception as e:
        # Probably duplicate key error, which means not a unique view
        pass

    # Return current value without incrementing
    res = supabase.table("analytics").select("value").eq("key", "total_views").single().execute()
    return {"views": res.data["value"] if res.data else 0, "unique": False}

@router.websocket("/current-viewers")
async def current_viewers(websocket: WebSocket):
    await websocket.accept()
    active_connections.add(websocket)
    try:
        # Broadcast the new count to all connected clients
        await broadcast_current_viewers()
        while True:
            # Keep connection alive
            await websocket.receive_text()
    except WebSocketDisconnect:
        active_connections.remove(websocket)
        await broadcast_current_viewers()

async def broadcast_current_viewers():
    count = len(active_connections)
    disconnected = set()
    for connection in active_connections:
        try:
            await connection.send_json({"count": count})
        except Exception:
            disconnected.add(connection)
    
    for conn in disconnected:
        active_connections.remove(conn)
