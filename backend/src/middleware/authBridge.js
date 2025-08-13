// Adapts whatever src/middleware/auth.js exports into a standard auth middleware
import * as Auth from './auth.js';

function pickAuth() {
  const candidates = [
    Auth.authMiddleware,  // preferred name
    Auth.default,         // default export
    Auth.auth,
    Auth.requireAuth,
    Auth.ensureAuth,
    Auth.verifyAuth,
    Auth.protect,
    Auth.guard,
  ].filter(fn => typeof fn === 'function');

  if (candidates.length) return candidates[0];

  // fallback: any exported (req,res,next) function
  const anyFn = Object.values(Auth).find(fn => typeof fn === 'function' && fn.length >= 3);
  if (anyFn) return anyFn;

  throw new Error("middleware/auth.js: no compatible auth middleware export found");
}

const authMiddleware = pickAuth();
export default authMiddleware;
export { authMiddleware };
