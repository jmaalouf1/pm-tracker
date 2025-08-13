export function pageParams(req, fallbackSize = 20, maxSize = 100) {
  const page = Math.max(1, parseInt(req.query.page || '1', 10));
  const pageSize = Math.min(maxSize, Math.max(1, parseInt(req.query.pageSize || fallbackSize, 10)));
  const offset = (page - 1) * pageSize;
  return { page, pageSize, offset };
}
export function like(s) {
  if (!s) return '%';
  return `%${String(s).trim().replace(/[%_]/g, m => '\\' + m)}%`;
}
