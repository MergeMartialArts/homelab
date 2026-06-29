import asyncio
import json as json_lib
import os
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import Response, StreamingResponse

SERVICES_DIR = Path(os.getenv("SERVICES_DIR", str(Path(__file__).parent.parent.resolve())))
SERVICES_SH = SERVICES_DIR / "services.sh"

app = FastAPI(title="Homelab API")


def _list_services() -> list[str]:
    return sorted(
        d.name
        for d in SERVICES_DIR.iterdir()
        if d.is_dir() and (d / "docker-compose.yml").exists()
    )


def _require_service(name: str) -> None:
    if name not in _list_services():
        raise HTTPException(status_code=404, detail=f"Unknown service: {name}")


async def _stream(cmd: list[str], cwd: Path) -> StreamingResponse:
    async def generate():
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
            stdin=asyncio.subprocess.DEVNULL,
            cwd=str(cwd),
        )
        async for line in process.stdout:
            yield line.decode(errors="replace")
        await process.wait()
        status = "ok" if process.returncode == 0 else "error"
        yield f"[exit {process.returncode}: {status}]\n"

    return StreamingResponse(generate(), media_type="text/plain")


@app.get("/services")
def list_services():
    return {"services": _list_services()}


@app.post("/services/all/start")
async def start_all():
    return await _stream(["bash", str(SERVICES_SH), "--start"], SERVICES_DIR)


@app.post("/services/all/stop")
async def stop_all():
    return await _stream(["bash", str(SERVICES_SH), "--stop"], SERVICES_DIR)


@app.post("/services/all/setup")
async def setup_all():
    return await _stream(["bash", str(SERVICES_SH), "--setup"], SERVICES_DIR)


@app.get("/services/{name}/status")
async def service_status(name: str):
    _require_service(name)
    compose_file = str(SERVICES_DIR / name / "docker-compose.yml")
    proc = await asyncio.create_subprocess_exec(
        "docker", "compose", "-f", compose_file, "ps", "--format", "json",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
    )
    stdout, _ = await proc.communicate()
    output = stdout.decode(errors="replace").strip()

    if not output:
        return {"status": "stopped"}

    containers = []
    for line in output.splitlines():
        try:
            containers.append(json_lib.loads(line))
        except json_lib.JSONDecodeError:
            pass

    if not containers:
        return {"status": "stopped"}

    containers = [
        c for c in containers
        if "homelab.monitor-only-for-possible-updates=true" not in c.get("Labels", "")
    ]

    states  = [c.get("State",  "") for c in containers]
    healths = [c.get("Health", "") for c in containers]

    if all(s != "running" for s in states):
        return {"status": "stopped"}
    if any(h == "unhealthy" for h in healths):
        return {"status": "unhealthy"}
    if any(h == "starting" for h in healths):
        return {"status": "starting"}
    if any(h == "healthy" for h in healths):
        return {"status": "healthy"}
    return {"status": "running"}


@app.get("/services/{name}/readme")
def service_readme(name: str):
    _require_service(name)
    readme = SERVICES_DIR / name / "README.md"
    if not readme.exists():
        raise HTTPException(status_code=404, detail=f"No README.md for {name}")
    return Response(content=readme.read_text(), media_type="text/plain; charset=utf-8")


@app.post("/services/{name}/setup")
async def setup_service(name: str):
    _require_service(name)
    setup = SERVICES_DIR / name / "setup.sh"
    if not setup.exists():
        raise HTTPException(status_code=404, detail=f"No setup.sh for {name}")
    return await _stream(["bash", str(setup)], SERVICES_DIR / name)


@app.post("/services/{name}/start")
async def start_service(name: str):
    _require_service(name)
    return await _stream(["bash", str(SERVICES_SH), "--start", f"--{name}"], SERVICES_DIR)


@app.post("/services/{name}/stop")
async def stop_service(name: str):
    _require_service(name)
    return await _stream(["bash", str(SERVICES_SH), "--stop", f"--{name}"], SERVICES_DIR)


@app.get("/health")
async def health():
    return await _stream(["bash", str(SERVICES_SH), "--health"], SERVICES_DIR)
