// backend/routes/projects.js
const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/authMiddleware');

/**
 * Helpers
 */
function toJSONorNull(v) {
  if (v == null) return null;
  // if already array/object, store as JSON; if string, try parse else keep string
  if (typeof v === 'string') {
    try {
      const parsed = JSON.parse(v);
      return JSON.stringify(parsed);
    } catch {
      // not JSON text; for safety, keep as string column? our columns are JSON so stringify scalar
      return JSON.stringify(v);
    }
  }
  // arrays/objects
  return JSON.stringify(v);
}

function toNumOrNull(v) {
  if (v === '' || v == null) return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function toIntOrNull(v) {
  if (v === '' || v == null) return null;
  const n = parseInt(v, 10);
  return Number.isFinite(n) ? n : null;
}

/**
 * GET /projects
 * Optional filters:
 *   q             - free text (searches project_id, description, customer name)
 *   year          - integer
 *   customer_id   - integer
 *   status        - delivery_status enum
 * Returns nested payment_terms as array
 */
router.get('/', verifyToken, async (req, res) => {
  const { q, year, customer_id, status } = req.query;
  const where = [];
  const params = [];

  if (q) {
    where.push(`(p.project_id LIKE ? OR p.description LIKE ? OR c.name LIKE ?)`);
    params.push(`%${q}%`, `%${q}%`, `%${q}%`);
  }
  if (year) {
    where.push(`p.year = ?`);
    params.push(toIntOrNull(year));
  }
  if (customer_id) {
    where.push(`p.customer_id = ?`);
    params.push(toIntOrNull(customer_id));
  }
  if (status) {
    where.push(`p.delivery_status = ?`);
    params.push(status);
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';

  try {
    const [rows] = await db.query(
      `
      SELECT
        p.id, p.project_id, p.customer_id, p.description, p.total_amount, p.currency,
        p.segments, p.service_lines, p.partner, p.delivery_status, p.year,
        p.payment_terms AS _deprecated_json_terms, -- legacy column if still present (ignored by UI)
        p.assigned_resources, p.created_by, p.created_at, p.updated_at,
        c.name AS customer_name,
        COALESCE(
          JSON_ARRAYAGG(
            IF(
              pt.id IS NULL, NULL,
              JSON_OBJECT(
                'id', pt.id,
                'label', pt.label,
                'percent', pt.percent,
                'amount', pt.amount,
                'status_id', pt.status_id,
                'status_label', ps.label,
                'due_date', pt.due_date,
                'notes', pt.notes
              )
            )
          ),
          JSON_ARRAY()
        ) AS payment_terms
      FROM projects p
      LEFT JOIN customers c ON c.id = p.customer_id
      LEFT JOIN payment_terms pt ON pt.project_id = p.id
      LEFT JOIN payment_statuses ps ON ps.id = pt.status_id
      ${whereSql}
      GROUP BY p.id
      ORDER BY p.created_at DESC
      `,
      params
    );

    const data = rows.map((r) => ({
      ...r,
      segments: r.segments && typeof r.segments === 'string' ? JSON.parse(r.segments) : r.segments,
      service_lines:
        r.service_lines && typeof r.service_lines === 'string'
          ? JSON.parse(r.service_lines)
          : r.service_lines,
      payment_terms:
        r.payment_terms && typeof r.payment_terms === 'string'
          ? JSON.parse(r.payment_terms)
          : r.payment_terms || [],
    }));

    res.json(data);
  } catch (err) {
    console.error('Error fetching projects:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

/**
 * GET /projects/:id
 * Returns project + nested payment_terms
 */
router.get('/:id', verifyToken, async (req, res) => {
  const { id } = req.params;

  try {
    const [rows] = await db.query(
      `
      SELECT
        p.id, p.project_id, p.customer_id, p.description, p.total_amount, p.currency,
        p.segments, p.service_lines, p.partner, p.delivery_status, p.year,
        p.assigned_resources, p.created_by, p.created_at, p.updated_at,
        c.name AS customer_name,
        COALESCE(
          JSON_ARRAYAGG(
            IF(
              pt.id IS NULL, NULL,
              JSON_OBJECT(
                'id', pt.id,
                'label', pt.label,
                'percent', pt.percent,
                'amount', pt.amount,
                'status_id', pt.status_id,
                'status_label', ps.label,
                'due_date', pt.due_date,
                'notes', pt.notes
              )
            )
          ),
          JSON_ARRAY()
        ) AS payment_terms
      FROM projects p
      LEFT JOIN customers c ON c.id = p.customer_id
      LEFT JOIN payment_terms pt ON pt.project_id = p.id
      LEFT JOIN payment_statuses ps ON ps.id = pt.status_id
      WHERE p.id = ?
      GROUP BY p.id
      `,
      [id]
    );

    if (!rows.length) return res.status(404).json({ message: 'Project not found' });

    const r = rows[0];
    const project = {
      ...r,
      segments: r.segments && typeof r.segments === 'string' ? JSON.parse(r.segments) : r.segments,
      service_lines:
        r.service_lines && typeof r.service_lines === 'string'
          ? JSON.parse(r.service_lines)
          : r.service_lines,
      payment_terms:
        r.payment_terms && typeof r.payment_terms === 'string'
          ? JSON.parse(r.payment_terms)
          : r.payment_terms || [],
    };

    res.json(project);
  } catch (err) {
    console.error('Error fetching project:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

/**
 * POST /projects
 * Body:
 * {
 *   project_id (required),
 *   customer_id (required),
 *   description, total_amount, currency,
 *   segments (array or JSON), service_lines (array or JSON),
 *   partner, delivery_status, year, assigned_resources,
 *   payment_terms: [
 *     { label(required), percent, amount, status_id, due_date, notes }
 *   ]
 * }
 */
router.post('/', verifyToken, async (req, res) => {
  const {
    project_id,
    customer_id,
    description,
    total_amount,
    currency,
    segments,
    service_lines,
    partner,
    delivery_status,
    year,
    assigned_resources,
    payment_terms,
  } = req.body;

  if (!project_id || !customer_id) {
    return res.status(400).json({ message: 'project_id and customer_id are required' });
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    const created_by = req.user?.id || null;

    const [result] = await conn.execute(
      `
      INSERT INTO projects (
        project_id, customer_id, description, total_amount, currency,
        segments, service_lines, partner, delivery_status, year,
        assigned_resources, created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      [
        project_id,
        toIntOrNull(customer_id),
        description ?? null,
        toNumOrNull(total_amount),
        currency ?? null,
        toJSONorNull(segments),
        toJSONorNull(service_lines),
        partner ?? null,
        delivery_status ?? null,
        toIntOrNull(year),
        toJSONorNull(assigned_resources),
        created_by,
      ]
    );

    const projectId = result.insertId;

    // Optional: insert payment terms
    if (Array.isArray(payment_terms) && payment_terms.length) {
      // get total_amount to compute percentages if needed
      const total = toNumOrNull(total_amount);

      const values = payment_terms
        .filter((t) => t && t.label) // label required
        .map((t) => {
          let amt = toNumOrNull(t.amount);
          const pct = toNumOrNull(t.percent);
          if ((amt == null || Number.isNaN(amt)) && pct != null && total != null) {
            amt = Math.round((total * pct) )/100; // avoid fp; but ok
            // better rounding:
            amt = Math.round((total * pct / 100) * 100) / 100;
          }
          return [
            projectId,
            t.label,
            pct,
            amt,
            t.status_id ?? null,
            t.due_date ?? null,
            t.notes ?? null,
          ];
        });

      if (values.length) {
        await conn.query(
          `INSERT INTO payment_terms (project_id, label, percent, amount, status_id, due_date, notes)
           VALUES ?`,
          [values]
        );
      }
    }

    await conn.commit();
    res.status(201).json({ message: 'Project created', project_id: projectId });
  } catch (err) {
    await conn.rollback();
    console.error('Error creating project:', err);
    res.status(500).json({ message: 'Internal server error' });
  } finally {
    conn.release();
  }
});

/**
 * PUT /projects/:id
 * Same body as POST.
 * If body contains payment_terms (array), we **replace** existing terms for that project.
 */
router.put('/:id', verifyToken, async (req, res) => {
  const { id } = req.params;

  const {
    project_id,
    customer_id,
    description,
    total_amount,
    currency,
    segments,
    service_lines,
    partner,
    delivery_status,
    year,
    assigned_resources,
    payment_terms,
  } = req.body;

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    const [result] = await conn.execute(
      `
      UPDATE projects SET
        project_id = ?, customer_id = ?, description = ?, total_amount = ?, currency = ?,
        segments = ?, service_lines = ?, partner = ?, delivery_status = ?, year = ?,
        assigned_resources = ?
      WHERE id = ?
      `,
      [
        project_id ?? null,
        toIntOrNull(customer_id),
        description ?? null,
        toNumOrNull(total_amount),
        currency ?? null,
        toJSONorNull(segments),
        toJSONorNull(service_lines),
        partner ?? null,
        delivery_status ?? null,
        toIntOrNull(year),
        toJSONorNull(assigned_resources),
        id,
      ]
    );

    if (!result.affectedRows) {
      await conn.rollback();
      return res.status(404).json({ message: 'Project not found' });
    }

    // Replace payment terms if provided
    if (Array.isArray(payment_terms)) {
      await conn.query('DELETE FROM payment_terms WHERE project_id = ?', [id]);

      if (payment_terms.length) {
        // fetch (possibly updated) total_amount for accurate computation
        let total = toNumOrNull(total_amount);
        if (total == null) {
          const [[p]] = await conn.query('SELECT total_amount FROM projects WHERE id = ?', [id]);
          total = p?.total_amount != null ? Number(p.total_amount) : null;
        }

        const values = payment_terms
          .filter((t) => t && t.label)
          .map((t) => {
            let amt = toNumOrNull(t.amount);
            const pct = toNumOrNull(t.percent);
            if ((amt == null || Number.isNaN(amt)) && pct != null && total != null) {
              amt = Math.round((total * pct / 100) * 100) / 100;
            }
            return [id, t.label, pct, amt, t.status_id ?? null, t.due_date ?? null, t.notes ?? null];
          });

        if (values.length) {
          await conn.query(
            `INSERT INTO payment_terms (project_id, label, percent, amount, status_id, due_date, notes)
             VALUES ?`,
            [values]
          );
        }
      }
    }

    await conn.commit();
    res.json({ message: 'Project updated' });
  } catch (err) {
    await conn.rollback();
    console.error('Error updating project:', err);
    res.status(500).json({ message: 'Internal server error' });
  } finally {
    conn.release();
  }
});

/**
 * DELETE /projects/:id
 * (payment_terms rows are removed via FK ON DELETE CASCADE)
 */
router.delete('/:id', verifyToken, async (req, res) => {
  const { id } = req.params;
  try {
    const [result] = await db.execute('DELETE FROM projects WHERE id = ?', [id]);
    if (!result.affectedRows) {
      return res.status(404).json({ message: 'Project not found' });
    }
    res.json({ message: 'Project deleted' });
  } catch (err) {
    console.error('Error deleting project:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;

