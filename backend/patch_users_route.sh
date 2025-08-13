set -euo pipefail
SRV=~/projects/backend/src/server.js

# Import line
grep -q "import usersAdminRoutes from './routes/usersAdmin.js';" "$SRV" || \
  sed -i "1 a import usersAdminRoutes from './routes/usersAdmin.js';" "$SRV"

# Mount line (under other /api routes)
grep -q "app.use('/api/users', usersAdminRoutes);" "$SRV" || \
  sed -i "/app.use(.*api\\/auth/a app.use('/api/users', usersAdminRoutes);" "$SRV"

echo "Patched $SRV"
