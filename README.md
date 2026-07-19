# 🌌 Kshitij Sharma — Interactive Personal Portfolio

A premium, full-stack personal portfolio and blog built with **Flutter Web**, **FastAPI**, and **Supabase**. This project features real-time weather-reactive themes, Spotify integration, and an immersive media experience.

## 🚀 Features

-   **Weather-Reactive UI**: The website's theme (colors, particles, and animations) changes in real-time based on the owner's live location.
-   **Spotify "Now Playing"**: Immersive integration showing real-time playback, live timers, and album art.
-   **Life Snapshots**: A custom-built blog/gallery feed supporting multiple images and auto-playing videos.
-   **Advanced Media Suite**: Full-screen viewer with keyboard navigation, zoom support, and mobile gestures.
-   **Owner Mode**: Secure, password-protected session to edit profile details, projects, and certifications directly from the UI.
-   **Professional Image Editor**: Built-in suite to crop, rotate, and align profile photos before upload.
-   **Global Reach**: Optimized for both Desktop and Mobile with fluid entry animations and glassmorphism.

## 🛠️ Tech Stack

-   **Frontend**: [Flutter](https://flutter.dev) (Web)
-   **Backend**: [FastAPI](https://fastapi.tiangolo.com) (Python 3.10+)
-   **Database**: [Supabase](https://supabase.com) (PostgreSQL + Storage)
-   **Deployment**: 
    -   Frontend: [GitHub Pages](https://pages.github.com)
    -   Backend: [Vercel](https://vercel.com)

## 📦 Project Structure

```text
.
├── backend/    # FastAPI application (Logic, API, Auth)
├── frontend/   # Flutter application (UI, State Management)
├── db/         # Database schema and migration scripts
└── README.md
```

## 🎨 Deployment

### Backend (Vercel)
1. Import the `backend/` directory to Vercel.
2. Set Environment Variables: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `OPENWEATHER_API_KEY`, `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`, `JWT_SECRET`.

### Frontend (GitHub Pages)
1. Update `productionBaseUrl` in `api_service.dart`.
2. Build: `flutter build web --release --base-href "/Portfolio-Website/"`.
3. Push `build/web` to the `gh-pages` branch.

---
Developed with ❤️ by [Kshitij Sharma](https://github.com/KshitijSh-2604)
