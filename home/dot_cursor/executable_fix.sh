#!/usr/bin/env bash
# Silences Cursor's "installation appears to be corrupt" warning after
# "Enable/Reload Custom CSS and JS": rewrites the checksums in product.json
# to match the patched files. Run (./fix.sh) after each reload or
# Cursor update.
set -euo pipefail

app="/Applications/Cursor.app/Contents/Resources/app"
[ -f "$app/product.json.orig" ] || cp "$app/product.json" "$app/product.json.orig"

python3 -I - "$app" <<'EOF'
import base64, hashlib, json, os, sys

app = sys.argv[1]
path = os.path.join(app, "product.json")
product = json.load(open(path))
changed = []
for name, old in product.get("checksums", {}).items():
    data = open(os.path.join(app, "out", name), "rb").read()
    new = base64.b64encode(hashlib.sha256(data).digest()).decode().rstrip("=")
    if new != old:
        product["checksums"][name] = new
        changed.append(name)
if changed:
    json.dump(product, open(path, "w"), indent="\t")
    print("Updated:", *changed, sep="\n  ")
else:
    print("Checksums already match.")
EOF
echo "Restart Cursor to apply."
