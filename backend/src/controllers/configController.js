import { pool } from '../db.js';

const map = {
  customers: 'customers',
  segments: 'segments',
  service_lines: 'service_lines',
  partners: 'partners',
  statuses: 'statuses'
};

export const ConfigController = {
  async getOptions(req, res) {
    const types = (req.query.types || '').split(',').map(s => s.trim()).filter(Boolean);
    const out = {};
    for (const t of types) {
      const table = map[t];
      if (!table) continue;
      const [rows] = t === 'statuses'
        ? await pool.query('SELECT id,type,name,is_active FROM statuses ORDER BY name')
        : await pool.query('SELECT id,name,is_active FROM ' + table + ' ORDER BY name');
      out[t] = rows;
    }
    res.json(out);
  },

  async createOption(req, res) {
    const { type } = req.params;
    const { name, statusType } = req.body || {};
    const table = map[type];
    if (!table) return res.status(400).json({ error: 'Unsupported type' });

    if (type === 'statuses') {
      if (!statusType || !name) return res.status(400).json({ error: 'statusType and name are required' });
      const [r] = await pool.query('INSERT INTO statuses (type,name) VALUES (?,?)', [statusType, name]);
      return res.status(201).json({ id: r.insertId });
    } else {
      if (!name) return res.status(400).json({ error: 'name is required' });
      const [r] = await pool.query('INSERT INTO ' + table + ' (name) VALUES (?)', [name]);
      return res.status(201).json({ id: r.insertId });
    }
  },

  async updateOption(req, res) {
    const { type, id } = req.params;
    const { name, is_active } = req.body || {};
    const table = map[type];
    if (!table) return res.status(400).json({ error: 'Unsupported type' });

    const fields = [];
    const params = [];
    if (name != null) { fields.push('name = ?'); params.push(name); }
    if (is_active != null) { fields.push('is_active = ?'); params.push(!!is_active ? 1 : 0); }
    if (!fields.length) return res.status(400).json({ error: 'No changes' });

    params.push(id);
    if (type === 'statuses') {
      await pool.query('UPDATE statuses SET ' + fields.join(', ') + ' WHERE id = ?', params);
    } else {
      await pool.query('UPDATE ' + table + ' SET ' + fields.join(', ') + ' WHERE id = ?', params);
    }
    res.json({ ok: true });
  }
};
