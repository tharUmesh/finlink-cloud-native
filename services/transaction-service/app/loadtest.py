"""
Load test endpoints for Person 3's ACA auto-scaling demo.
Hit POST /load-test/burst to simulate a payday spike.
"""
import asyncio
import time
from fastapi import APIRouter

load_router = APIRouter(prefix="/load-test", tags=["Load Test"])


@load_router.get("/ping")
async def ping():
    """Basic ping — used to verify the service is alive under load."""
    return {"status": "ok", "timestamp": time.time()}


@load_router.post("/burst")
async def burst(requests: int = 10):
    """
    Simulates processing N concurrent requests.
    Person 3 calls this repeatedly to trigger ACA scale-out.
    Max 100 per call to avoid self-DoS.
    """
    requests = min(requests, 100)
    start = time.time()

    async def fake_transaction():
        await asyncio.sleep(0.2)  # simulates DB + Service Bus latency
        return {"processed": True}

    results = await asyncio.gather(*[fake_transaction() for _ in range(requests)])
    elapsed = time.time() - start

    return {
        "simulated_requests": requests,
        "elapsed_seconds": round(elapsed, 3),
        "throughput": round(requests / elapsed, 1),
        "message": f"Processed {requests} simulated transactions in {elapsed:.3f}s"
    }