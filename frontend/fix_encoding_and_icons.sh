set -euo pipefail
FRONT=~/projects/frontend
SRC="$FRONT/src"

# 0) Ensure UTF-8 meta
if ! grep -qi '<meta[^>]*charset *= *"utf-8"' "$FRONT/index.html"; then
  sed -i '1,20{s#<head>#<head>\n  <meta charset="utf-8">#; t; }' "$FRONT/index.html"
fi

# 1) Replace problematic unicode characters with ASCII across src/
#    (ellipsis, en/em dash, smart quotes, bullet, NBSP)
find "$SRC" -type f -name '*.*' -print0 | xargs -0 perl -i -pe '
  s/\x{2026}/.../g;        # …
  s/[\x{2013}\x{2014}]/-/g;# – —
  s/[\x{2018}\x{2019}]/'\''/g;  # ‘ ’
  s/[\x{201C}\x{201D}]/"/g;     # “ ”
  s/\x{00A0}/ /g;          # NBSP
  s/\x{2022}/•/g;          # bullet (kept, safe)
'

# 2) Replace specific placeholder that showed a bad glyph
grep -RIl "Description contains" "$SRC" | xargs -r sed -i 's/Description contains.*/Description contains/g'

# 3) Add tiny inline SVG icons we can import (no fonts)
mkdir -p "$SRC/components"
cat > "$SRC/components/Icons.jsx" <<'JSX'
export const SearchIcon = ({size=16}) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M11.742 10.344l3.387 3.387-.707.707-3.387-3.387a6 6 0 111.414-1.414zM6.5 11a4.5 4.5 0 100-9 4.5 4.5 0 000 9z" fill="currentColor"/>
  </svg>
);
export const ChevronDown = ({size=16}) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M3.2 5.8l4.8 4.8 4.8-4.8-.8-.8L8 9.2 4 5l-.8.8z" fill="currentColor"/>
  </svg>
);
JSX

# 4) Global CSS: draw chevron/search with CSS inline SVG so selects/search boxes always show
cat > "$SRC/app.css" <<'CSS'
:root{
  --brand:#1f6feb; --brand-700:#1a5fd1;
  --bg:#f7f9fc; --card:#ffffff; --text:#0f172a; --muted:#64748b;
  --radius:12px; --shadow:0 4px 14px rgba(16,24,40,.08);
}
html,body{background:var(--bg); color:var(--text); min-height:100%;}
/* Simple navbar (non-fixed) */
.navbar{background:linear-gradient(90deg,var(--brand),var(--brand-700)); box-shadow:var(--shadow); padding:.5rem 0;}
.navbar .navbar-brand,.navbar .nav-link{color:#fff !important}
.navbar .navbar-brand{font-weight:800; letter-spacing:.2px}
.navbar .nav-link{padding:.35rem .6rem}
.container-page{max-width:1200px; margin-inline:auto; padding:20px;}
.card{border:none; border-radius:var(--radius); background:var(--card); box-shadow:var(--shadow);}
.table thead th{position:sticky; top:0; background:#fff; z-index:1}
.footer-copy{color:#6b7280; font-size:.86rem; text-align:center; padding:16px 0 24px}

/* Text-only pagination (no fonts) */
.pagination .btn{min-width:84px}

/* Select chevron via inline SVG */
.form-select{
  background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16'%3e%3cpath fill='%2364748b' d='M3.2 5.8l4.8 4.8 4.8-4.8-.8-.8L8 9.2 4 5l-.8.8z'/%3e%3c/svg%3e");
  background-repeat: no-repeat;
  background-position: right .85rem center;
  background-size: 16px 16px;
  padding-right: 2rem; /* space for chevron */
}

/* Search input with inline SVG */
.input-search{position:relative}
.input-search input{padding-left:38px}
.input-search:before{
  content:"";
  position:absolute; left:12px; top:50%; transform:translateY(-50%);
  width:16px; height:16px;
  background-image:url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16'%3e%3cpath fill='%2364748b' d='M11.742 10.344l3.387 3.387-.707.707-3.387-3.387a6 6 0 111.414-1.414zM6.5 11a4.5 4.5 0 100-9 4.5 4.5 0 000 9z'/%3e%3c/svg%3e");
  background-size:16px 16px; background-repeat:no-repeat;
}

/* Login layout (clean ASCII only) */
.login-wrap{display:grid; grid-template-columns:1fr; gap:24px; min-height:calc(100vh - 80px); align-items:center}
@media (min-width: 992px){ .login-wrap{ grid-template-columns: 1.1fr 0.9fr; } }
.login-hero{display:none}
@media (min-width: 992px){
  .login-hero{display:block; margin:10px 10px 10px 0; padding:28px; border-radius:16px; background:linear-gradient(135deg, #eef3ff, #f7fbff); box-shadow:var(--shadow);}
}
.login-hero h1{font-weight:800; margin-bottom:8px}
.login-hero p{color:var(--muted)}
.login-panel{width:100%; max-width:420px; background:var(--card); border-radius:14px; box-shadow:var(--shadow); padding:22px}
.copy-muted{color:#94a3b8; font-size:.92rem}
CSS

# 5) Make our search boxes use the CSS search icon helper class
#    (safe no-op if files don’t contain the target markup)
grep -RIl "<input className=\"form-control\" placeholder=\"Search projects\"" "$SRC" | \
  xargs -r sed -i 's/<div className="flex-grow-1">/<div className="flex-grow-1 input-search">/'

# 6) Build + re-serve
cd "$FRONT"
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

echo "Encoding normalized, icons switched to inline SVG, selects/search fixed. Hard refresh the browser."
