# Implementation Plan: Spotify Connection Experience & Feedback

This plan improves the Spotify connection flow by providing a dedicated success page and persistent connection status feedback on the portfolio.

## Proposed Changes

### 1. Backend (FastAPI)

#### [MODIFY] [spotify.py](file:///C:/Users/Kshitij/Desktop/portfolio_website/backend/routes/spotify.py)
- **New Success Page**: Update `spotify_callback` to return a styled `HTMLResponse` instead of redirecting back to the main site.
    - Features: "Success!" message, owner's name, and a "Close Window" button.
    - Benefit: Prevents the "duplicate tab" confusion and gives clear confirmation.
- **Enhanced Status**: Update `now-playing` endpoint to include an `isLinked` boolean.
    - Returns `true` if a valid refresh token exists in the database, even if no music is active.

### 2. Frontend (Flutter)

#### [MODIFY] [spotify_model.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/models/spotify_model.dart)
- Add `isLinked` boolean field to the model and factory.

#### [MODIFY] [post_feed.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/widgets/post_feed.dart)
- **Persistent Feedback**: Update `_buildSpotifySection` to show a "Spotify Linked • No music playing" status if `isLinked` is true but `isPlaying` is false.
- **Improved Empty State**: Make the "Connect" button more professional if the account is not yet linked.

---

## Verification Plan

### Manual Verification
1. **Connect Flow**: Click "Connect" on the live site. Verify it opens a new tab, you authorize, and you land on a "Success!" page.
2. **Tab Closure**: Close the tab and return to your portfolio.
3. **Linked Status**: Verify the Spotify bar now says "Spotify Linked" even if you stop playing music.
4. **Active Playback**: Play a song and verify the full player UI (large art, timers) takes over as expected.
