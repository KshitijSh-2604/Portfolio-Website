from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import auth, posts, weather, spotify, upload, analytics, contact, portfolio

app = FastAPI(title="Portfolio API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api")
app.include_router(posts.router, prefix="/api")
app.include_router(weather.router, prefix="/api")
app.include_router(spotify.router, prefix="/api")
app.include_router(upload.router, prefix="/api")
app.include_router(analytics.router, prefix="/api")
app.include_router(contact.router, prefix="/api")
app.include_router(portfolio.router, prefix="/api")

@app.get("/health")
def health_check():
    return {"status": "ok"}
