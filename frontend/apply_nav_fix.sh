set -euo pipefail
FRONT=~/projects/frontend
SRC="$FRONT/src"

# --- CSS: convert fixed to sticky, remove spacer usage
sed -i \
  -e 's/\.navbar\.fixed-top/.navbar.sticky-top/g' \
  -e '/\.nav-spacer\s*{/,/}/d' \
  "$SRC/app.css"

# Ensure sticky has z-index + shadow + gradient
awk '1; /\/\* Fixed navbar \*\//{print ".navbar.sticky-top{position:sticky;top:0;z-index:1030;box-shadow:var(--shadow);background:linear-gradient(90deg,var(--brand),var(--brand-700));}"}' \
  "$SRC/app.css" | sponge "$SRC/app.css" 2>/dev/null || true

# 2) Layout.jsx: change class, remove spacer node
sed -i \
  -e "s/className=\"navbar navbar-expand-lg fixed-top\"/className=\"navbar navbar-expand-lg sticky-top\"/" \
  -e "s#<div className=\"nav-spacer\" />##" \
  "$SRC/components/Layout.jsx"

# 3) Login.jsx: remove spacer there too (we already handle spacing via sticky)
sed -i \
  -e 's#<div className="nav-spacer" />##' \
  "$SRC/pages/Login.jsx"

# 4) Rebuild & serve
cd "$FRONT"
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

echo "Navbar switched to sticky, spacer removed. Refresh the page."
