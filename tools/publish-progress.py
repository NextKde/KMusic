#!/usr/bin/env python3
"""Publish reviewed live captures and honest progress to the two evidence branches."""
import argparse
import hashlib
import json
import os
import platform
from pathlib import Path
import shutil
import struct
import subprocess
import time
from datetime import datetime
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[1]
TARGETS = {
    "music": (ROOT, "NextKde/KMusic"),
    "gallery": (ROOT.parent / "nextkdeAppDemo", "NextKde/nextkdeAppDemo"),
}


def run(args, cwd=None):
    return subprocess.run(args, cwd=cwd, check=True, text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          timeout=120).stdout.strip()


def source_state(path):
    status = run(["git", "status", "--porcelain"], path)
    patch = run(["git", "diff", "HEAD", "--binary"], path)
    return {"revision": run(["git", "rev-parse", "HEAD"], path),
            "branch": run(["git", "branch", "--show-current"], path),
            "dirty": bool(status), "changedPaths": status.splitlines(),
            "trackedDiffSha256": hashlib.sha256(patch.encode()).hexdigest()}


def evidence_checkout(key, source, repo):
    path = ROOT / ".task" / "evidence" / key
    if not (path / ".git").exists():
        path.mkdir(parents=True, exist_ok=True)
        run(["git", "init", "-b", "ui-evidence", str(path)])
        run(["git", "remote", "add", "origin", f"https://github.com/{repo}.git"], path)
        for setting in ("user.name", "user.email"):
            run(["git", "config", setting, run(["git", "config", setting], source)], path)
        remote = run(["git", "ls-remote", "--heads", "origin", "ui-evidence"], path)
        if remote:
            run(["git", "fetch", "origin", "ui-evidence"], path)
            run(["git", "reset", "--hard", "FETCH_HEAD"], path)
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--music-image", action="append", default=[])
    parser.add_argument("--gallery-image", action="append", default=[])
    parser.add_argument("--music-data", action="append", default=[])
    parser.add_argument("--gallery-data", action="append", default=[])
    parser.add_argument("--summary", required=True)
    parser.add_argument("--music-status", required=True)
    parser.add_argument("--gallery-status", required=True)
    parser.add_argument("--scale", type=float, default=2.0,
                        help="Observed live-window device pixel ratio")
    parser.add_argument("--reviewed", action="store_true", required=True,
                        help="Coordinator has personally inspected all supplied captures")
    args = parser.parse_args()
    now = datetime.now(ZoneInfo("Asia/Shanghai"))
    stamp = now.strftime("%Y%m%d-%H%M%S")
    state_file = ROOT / ".task" / "publication.json"
    state = json.loads(state_file.read_text()) if state_file.exists() else {}
    sources = {key: source_state(path) for key, (path, _) in TARGETS.items()}
    runtime_file = ROOT / ".task" / "runtime.json"
    runtime = json.loads(runtime_file.read_text()) if runtime_file.exists() else None
    published = {}
    for key, (source, repo) in TARGETS.items():
        checkout = evidence_checkout(key, source, repo)
        relative = Path("screenshots") / f"round-{stamp}"
        output = checkout / relative
        output.mkdir(parents=True, exist_ok=True)
        images = []
        for filename in getattr(args, key + "_image"):
            image = Path(filename).resolve()
            data = image.read_bytes()
            if data[:8] != b"\x89PNG\r\n\x1a\n":
                raise ValueError(f"Expected original PNG capture: {image}")
            width, height = struct.unpack(">II", data[16:24])
            shutil.copyfile(image, output / image.name)
            runtime_sidecar = Path(str(image) + ".runtime.json")
            capture_runtime = json.loads(runtime_sidecar.read_text()) if runtime_sidecar.exists() else None
            images.append({"file": image.name, "width": width, "height": height,
                           "captureRuntime": capture_runtime,
                           "devicePixelRatio": args.scale,
                           "logicalWidth": width / args.scale,
                           "logicalHeight": height / args.scale,
                           "theme": "dark" if "dark" in image.stem or image.parent.name == "dark" or image.parent.name.startswith("dark-") else "light" if "light" in image.stem or image.parent.name == "light" or image.parent.name.startswith("light-") else "unspecified",
                           "sha256": hashlib.sha256(data).hexdigest(),
                           "capturedAt": datetime.fromtimestamp(image.stat().st_mtime,
                               ZoneInfo("Asia/Shanghai")).isoformat()})
        attachments = []
        for filename in getattr(args, key + "_data"):
            data_file = Path(filename).resolve()
            if data_file.suffix != ".json":
                raise ValueError("Only reviewed JSON evidence data is supported")
            json.loads(data_file.read_text())
            destination = "data-" + data_file.parent.name + "-" + data_file.name
            shutil.copyfile(data_file, output / destination)
            attachments.append(destination)
        captured = next((item["captureRuntime"] for item in images if item["captureRuntime"]), {})
        metadata = {"round": stamp, "publishedAt": now.isoformat(),
                    "reviewedData": attachments,
                    "summary": args.summary, "status": getattr(args, key + "_status"),
                    "source": sources[key], "relatedSources": sources,
                    "appRuntime": (images[0]["captureRuntime"] or runtime) if key == "music" and images else None,
                    "runtimeAtPublication": runtime if key == "music" else None,
                    "captureMethod": "Visible Qt Quick window item grab; no image editing",
                    "captureHost": captured.get("host", "unspecified; see per-image runtime"),
                    "captureLimit": "Client content only; compositor chrome and separate popup windows excluded",
                    "sessionType": captured.get("sessionType", "unknown"),
                    "system": captured.get("system", "unknown"),
                    "architecture": captured.get("architecture", "unknown"),
                    "qtVersion": captured.get("qtVersion", "unknown"),
                    "publicationHost": {"system": platform.system(), "architecture": platform.machine()},
                    "images": images, "personallyReviewed": True}
        (output / "metadata.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")
        body = f"# {'KMusic' if key == 'music' else 'Gallery'} progress\n\n"
        body += f"Updated: {now.isoformat()}\n\n{args.summary}\n\n{metadata['status']}\n\n"
        body += f"Source: [`{sources[key]['revision'][:12]}`](https://github.com/{repo}/commit/{sources[key]['revision']})"
        body += f" · Branch: `{sources[key]['branch']}` · Local changes: {sources[key]['dirty']}\n\n"
        body += "Captures and builds document progress; UI acceptance is recorded separately.\n\n"
        if images:
            body += "\n\n".join(f"![{item['file']}](./{item['file']})\n\n{item['width']} × {item['height']} original pixels" for item in images) + "\n\n"
        else:
            body += "No current application image available in this preparation round; see status above.\n\n"
        body += "[Capture and revision metadata](./metadata.json)\n"
        body += "".join(f"\n[Reviewed state/timing data: {name}](./{name})\n" for name in attachments)
        (output / "README.md").write_text(body)
        index = body.replace("](./", f"]({relative.as_posix()}/")
        index += f"\n[All rounds](./screenshots) · [Other project](https://github.com/{TARGETS['gallery' if key == 'music' else 'music'][1]}/blob/ui-evidence/README.md)\n"
        (checkout / "README.md").write_text(index)
        run(["git", "add", "README.md", str(relative)], checkout)
        run(["git", "commit", "-m", f"Record local UI progress {stamp}"], checkout)
        print(f"Publishing {repo} {stamp}", flush=True)
        for attempt in range(3):
            try:
                run(["git", "-c", "http.version=HTTP/1.1", "push", "-u", "origin", "ui-evidence"], checkout)
                break
            except subprocess.CalledProcessError:
                if attempt == 2:
                    raise
                time.sleep(1 + attempt)
        revision = run(["git", "rev-parse", "HEAD"], checkout)
        published[key] = {"revision": revision, "round": stamp,
                          "url": f"https://github.com/{repo}/blob/ui-evidence/README.md"}
        state["last_evidence_push_at"] = now.isoformat()
        state.setdefault("targets", {}).update({key: published[key]})
        state_file.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(published, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.stderr or str(error))
