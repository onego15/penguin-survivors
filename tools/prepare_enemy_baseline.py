"""Prepare the pinned, ignored comparison copy used by the enemy audit tools."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
revision = "305a423"
destination = root / ".godot" / "enemy-baseline"
files = subprocess.check_output(
    ["git", "ls-tree", "-r", "--name-only", revision, "scripts", "scenes"],
    cwd=root, encoding="utf-8",
).splitlines()
for name in files:
    if not name.endswith((".gd", ".tscn")):
        continue
    output = (destination / name).resolve()
    assert output.is_relative_to(destination.resolve())
    source = subprocess.check_output(
        ["git", "show", f"{revision}:{name}"], cwd=root, encoding="utf-8",
    )
    for folder in ("scripts", "scenes"):
        source = source.replace(f"res://{folder}/", f"res://.godot/enemy-baseline/{folder}/")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(source, encoding="utf-8")
print(f"Prepared {revision} in {destination}")
