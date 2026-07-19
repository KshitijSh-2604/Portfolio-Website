# Implementation Plan: Robust "Live Viewers" via Supabase Realtime

This plan replaces the flaky Backend-based WebSocket with **Supabase Realtime (Presence)**. This is a production-grade solution that works perfectly on serverless platforms like Vercel.

## User Action Required

> [!IMPORTANT]
> **Supabase Anon Key**: To make this work securely on the frontend, you need your **`SUPABASE_ANON_KEY`**.
> 1. Go to your [Supabase Dashboard](https://app.supabase.com/project/bmopigwhkmipvyeibizb/settings/api).
> 2. Copy the **`anon` `public`** key.
> 3. Provide it to me or add it to your `frontend` project (I will guide you where to put it).
>
> **CRITICAL**: Never use the `SERVICE_ROLE_KEY` on the frontend. It bypasses all security and would give visitors full access to your database!

## Proposed Changes

### 1. Frontend (Flutter)

#### [MODIFY] [pubspec.yaml](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/pubspec.yaml)
- Add `supabase_flutter: ^2.8.1`.

#### [MODIFY] [app_provider.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/providers/app_provider.dart)
- **Initialize Supabase**: Connect to your project using your URL and the **Anon Key**.
- **Presence Logic**:
    - Join a channel called `viewers`.
    - Use `channel.track({'online_at': DateTime.now().toIso8601String()})` to announce the visitor.
    - Listen to `sync` events: `channel.onPresenceSync((_) { ... })`.
    - Update `_currentViewers = channel.presenceState().length`.

#### [MODIFY] [api_service.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/services/api_service.dart)
- Remove `currentViewersWsUrl` getter.

### 2. Backend (FastAPI)

#### [MODIFY] [analytics.py](file:///C:/Users/Kshitij/Desktop/portfolio_website/backend/routes/analytics.py)
- **Delete** the `@router.websocket("/current-viewers")` endpoint.
- **Delete** the `active_connections` set and `broadcast_current_viewers` function.
- This makes the backend purely stateless and perfect for Vercel.

---

## Verification Plan

### Manual Verification
1. **Local Test**: Run the app locally.
2. **Multiple Tabs**: Open the website in 3 different browser tabs.
3. **Accuracy**: Verify the "Current Viewers" counter shows `3`.
4. **Real-time Exit**: Close two tabs. Verify the counter in the remaining tab drops to `1` within a few seconds.
5. **Vercel Build**: Push to GitHub and verify the counter works on the live site where WebSockets previously failed.
