import os
from contextlib import asynccontextmanager
from pathlib import Path

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, StreamingResponse
from starlette.background import BackgroundTask

API_URL = os.getenv("API_URL", "http://host.docker.internal:8080")
STATIC_DIR = Path(__file__).parent

_client: httpx.AsyncClient


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _client
    _client = httpx.AsyncClient(base_url=API_URL, timeout=300.0)
    yield
    await _client.aclose()


app = FastAPI(lifespan=lifespan)


@app.get("/")
def index():
    return FileResponse(STATIC_DIR / "index.html")


@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def proxy(request: Request, path: str):
    url = path
    if request.url.query:
        url = f"{url}?{request.url.query}"

    body = await request.body()
    headers = {
        k: v
        for k, v in request.headers.items()
        if k.lower() not in ("host", "content-length")
    }

    req = _client.build_request(request.method, url, content=body, headers=headers)
    response = await _client.send(req, stream=True)

    return StreamingResponse(
        response.aiter_bytes(),
        status_code=response.status_code,
        media_type=response.headers.get("content-type", "text/plain"),
        background=BackgroundTask(response.aclose),
    )
