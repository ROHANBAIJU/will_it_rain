from fastapi import FastAPI
from .api import routes

# Create the FastAPI app instance
app = FastAPI(
    title="Will It Rain API",
    description="An API to get weather probabilities using NASA data.",
    version="1.0.0"
)

# Include the router from api/routes.py
app.include_router(routes.router)