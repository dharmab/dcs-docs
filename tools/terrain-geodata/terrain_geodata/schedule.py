"""Run several jobs' work on one process pool, most urgent work first.

A job is a generator. Each time it needs work done it yields a dict of
``Call`` objects and is resumed with a dict of their results under the same
keys. Calls from every job share one pool: a call with a lower ``priority``
tuple runs first, so a job can put the steps that hold up its finish (a long
single-threaded read, the final write) ahead of bulk work that any free core
can pick up. A call's ``then`` runs in this process on its result as soon as it
arrives, and the job gets what ``then`` returns, so a job can consume large
results one at a time rather than holding them all.
"""

from __future__ import annotations

import heapq
import itertools
from collections.abc import Callable, Generator
from concurrent.futures import FIRST_COMPLETED, Future, ProcessPoolExecutor, wait
from dataclasses import dataclass, field
from typing import Any


@dataclass(order=True)
class Call:
    priority: tuple
    fn: Callable[..., Any] = field(compare=False)
    args: tuple = field(compare=False, default=())
    then: Callable[[Any], Any] | None = field(compare=False, default=None)


Job = Generator[dict[Any, Call], dict[Any, Any]]


@dataclass
class _Batch:
    job: Job
    results: dict[Any, Any] = field(default_factory=dict)
    pending: int = 0


def run(jobs: list[Job], workers: int) -> None:
    """Run ``jobs`` to completion on ``workers`` processes (in-process if 1)."""
    queue: list[tuple[Call, int, _Batch, Any]] = []
    seq = itertools.count()

    def advance(job: Job, value: dict[Any, Any] | None) -> None:
        # Resume a job until it asks for work or finishes.
        while True:
            try:
                calls = next(job) if value is None else job.send(value)
            except StopIteration:
                return
            if calls:
                break
            value = {}
        batch = _Batch(job, pending=len(calls))
        for key, call in calls.items():
            heapq.heappush(queue, (call, next(seq), batch, key))

    def finish(call: Call, batch: _Batch, key: Any, result: Any) -> None:
        batch.results[key] = result if call.then is None else call.then(result)
        batch.pending -= 1
        if batch.pending == 0:
            advance(batch.job, batch.results)

    for job in jobs:
        advance(job, None)

    if workers == 1:
        while queue:
            call, _, batch, key = heapq.heappop(queue)
            finish(call, batch, key, call.fn(*call.args))
        return

    # Keep a second round queued in the pool so workers stay busy while this
    # process composites results, at the cost of new urgent calls waiting
    # behind at most that many.
    limit = 2 * workers
    running: dict[Future, tuple[Call, _Batch, Any]] = {}
    with ProcessPoolExecutor(workers) as pool:
        try:
            while queue or running:
                while queue and len(running) < limit:
                    call, _, batch, key = heapq.heappop(queue)
                    running[pool.submit(call.fn, *call.args)] = (call, batch, key)
                done, _ = wait(running, return_when=FIRST_COMPLETED)
                for fut in done:
                    call, batch, key = running.pop(fut)
                    finish(call, batch, key, fut.result())
        except BaseException:
            pool.shutdown(cancel_futures=True)
            raise
