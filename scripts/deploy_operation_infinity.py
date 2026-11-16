# /// script
# requires-python = ">=3.12"
# dependencies = ["psutil"]
# ///
"""
Pull the latest repo, repack Operation Infinity, and restart the DCS server.

1. git pull (fast-forward only)
2. Pack the mission to a temp file (the server stays up if this fails)
3. Stop any running DCS server
4. Move the packed mission to Saved Games/DCS.dcs_serverrelease/Missions
5. Start the DCS server

Requires git on PATH. Run as the same user as the DCS server:

    uv run scripts/deploy_operation_infinity.py
"""

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import psutil

REPO_ROOT = Path(__file__).resolve().parent.parent
PACK_SCRIPT = REPO_ROOT / "missions" / "operation-infinity" / "pack_mission.py"
DEFAULT_SERVER_EXE = Path(
    r"C:\Program Files\Eagle Dynamics\DCS World Server\bin\DCS_server.exe"
)
SERVER_PROCESS_NAMES = {"dcs_server.exe", "dcs.exe"}


def find_server_processes() -> list[psutil.Process]:
    """Find running DCS server processes owned by any user we can inspect."""
    found = []
    for proc in psutil.process_iter(["name", "exe"]):
        name = (proc.info["name"] or "").lower()
        exe = proc.info["exe"] or ""
        if name in SERVER_PROCESS_NAMES and "server" in exe.lower():
            found.append(proc)
    return found


def stop_server(timeout: int) -> Path | None:
    """Stop running DCS servers. Returns the executable path of the first one."""
    procs = find_server_processes()
    if not procs:
        print("    No running server found")
        return None
    exe = Path(procs[0].info["exe"])
    for proc in procs:
        proc.kill()
    _, alive = psutil.wait_procs(procs, timeout=timeout)
    if alive:
        raise RuntimeError(f"Server did not exit within {timeout}s: {alive}")
    print(f"    Stopped {len(procs)} process(es)")
    return exe


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--server-exe",
        type=Path,
        default=DEFAULT_SERVER_EXE,
        help="Used only when no server is running; otherwise the running "
        "server's path is reused",
    )
    parser.add_argument("--write-dir", default="DCS.dcs_serverrelease")
    parser.add_argument("--saved-games", type=Path, default=Path.home() / "Saved Games")
    parser.add_argument("--stop-timeout", type=int, default=60)
    args = parser.parse_args()

    missions_dir = args.saved_games / args.write_dir / "Missions"
    target = missions_dir / "Operation Infinity.miz"

    print(f"==> Pulling {REPO_ROOT}")
    subprocess.run(["git", "-C", str(REPO_ROOT), "pull", "--ff-only"], check=True)

    with tempfile.TemporaryDirectory() as tmp:
        staging = Path(tmp) / "Operation Infinity.miz"

        print("==> Packing mission")
        subprocess.run(
            [sys.executable, str(PACK_SCRIPT), "--output", str(staging)], check=True
        )

        print("==> Stopping DCS server")
        server_exe = stop_server(args.stop_timeout) or args.server_exe

        print(f"==> Installing mission to {target}")
        missions_dir.mkdir(parents=True, exist_ok=True)
        shutil.move(staging, target)

    print(f"==> Starting {server_exe}")
    if not server_exe.exists():
        print(f"ERROR: Server executable not found: {server_exe} (pass --server-exe)")
        return 1
    subprocess.Popen(
        [str(server_exe), "-w", args.write_dir],
        cwd=server_exe.parent,
        creationflags=getattr(subprocess, "DETACHED_PROCESS", 0)
        | getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0),
        close_fds=True,
    )

    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
