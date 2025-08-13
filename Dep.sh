# 0) Go to the folder that contains both backend+frontend
cd ~/projects

# 1) Safety backup of current code
tar -czf ~/server-snapshot.$(date +%F-%H%M).tgz .

# 2) Initialize git here
rm -rf .git
git init

# 3) .gitignore (avoid huge commits / secrets)
cat > .gitignore <<'EOF'
node_modules/
frontend/dist/
*.log
.env
backend/.env
frontend/.env
.DS_Store
EOF

# 4) Commit all server files
git add -A
git status
git commit -m "Initial commit from live server (backend + frontend)"

# 5) Connect to your GitHub repo
git remote add origin https://github.com/jmaalouf1/pm-tracker.git

# 6) Fetch remote and create a local backup pointer of origin/main (just in case)
git fetch origin
git branch backup/pre-server-sync origin/main || true

# 7) Push your server code to a new branch first (safe)
BR=server-sync-$(date +%F)
git push -u origin HEAD:$BR

echo "Review your branch on GitHub: https://github.com/jmaalouf1/pm-tracker/tree/$BR"
echo "If everything looks correct and you want it to become main:"

# 8) (optional) Replace main with your server branch
# This rewrites GitHub's main to match your server state
# Only run when you're sure:
git push --force-with-lease origin $BR:main
