"""Copy credits and font licenses beside the exported game."""
from pathlib import Path
import shutil

root = Path(__file__).resolve().parent.parent
target = root / "build" / "web"
if not (target / "index.html").is_file():
    raise SystemExit("Export the Web preset before running this script.")
shutil.copy2(root / "CREDITS.txt", target / "CREDITS.txt")
for source in (root / "assets" / "fonts").glob("*-OFL.txt"):
    relative = source.relative_to(root)
    (target / relative).parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target / relative)
(target / ".nojekyll").touch()
print("Web build ready:", target)
