from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .api import routes, auth_routes
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Create the FastAPI app instance
app = FastAPI(
    title="Will It Rain API",
    description="Weather prediction API with NASA data, AI insights, and Firebase Authentication",
    version="2.0.0"
)

# Configure CORS for Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your Flutter app domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(routes.router)
app.include_router(auth_routes.router)