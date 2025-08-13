import { pool } from '../db.js';

export const CustomersController = {
  async list(req, res) {
    const q = (req.query.q || '').trim();
    const where = q ? 'WHERE c.name LIKE ? OR c.commercial_registration LIKE ? OR c.vat_number LIKE ?' : '';
    const params = q ? [`%${q}%`, `%${q}%`, `%${q}%`] : [];
    const [rows] = await pool.query(
      `SELECT c.*,
              (SELECT COUNT(*) FROM customer_contacts cc WHERE cc.customer_id=c.id) AS contacts_count
         FROM customers c ${where}
         ORDER BY c.name`, params);
    res.json(rows);
  },
  async get(req, res) {
    const { id } = req.params;
    const [[c]] = await pool.query('SELECT * FROM customers WHERE id = ?', [id]);
    if (!c) return res.status(404).json({ error: 'Not found' });
    const [contacts] = await pool.query('SELECT * FROM customer_contacts WHERE customer_id = ? ORDER BY id', [id]);
    res.json({ ...c, contacts });
  },
  async create(req, res) {
    const { name, country, type, commercial_registration, vat_number, contacts } = req.body || {};
    if (!name) return res.status(400).json({ error: 'name required' });
    const [r] = await pool.query(
      'INSERT INTO customers (name,country,type,commercial_registration,vat_number) VALUES (?,?,?,?,?)',
      [name, (country||null), (type||null), (commercial_registration||null), (vat_number||null)]
    );
    const id = r.insertId;
    if (Array.isArray(contacts) && contacts.length) {
      for (const ct of contacts) {
        await pool.query(
          'INSERT INTO customer_contacts (customer_id,role,name,email,phone) VALUES (?,?,?,?,?)',
          [id, (ct.role||null), ct.name, (ct.email||null), (ct.phone||null)]
        );
      }
    }
    res.status(201).json({ id });
  },
  async update(req, res) {
    const { id } = req.params;
    const { name, country, type, commercial_registration, vat_number } = req.body || {};
    const fields = []; const params = [];
    if (name !== undefined) { fields.push('name = ?'); params.push(name); }
    if (country !== undefined) { fields.push('country = ?'); params.push(country || null); }
    if (type !== undefined) { fields.push('type = ?'); params.push(type || null); }
    if (commercial_registration !== undefined) { fields.push('commercial_registration = ?'); params.push(commercial_registration || null); }
    if (vat_number !== undefined) { fields.push('vat_number = ?'); params.push(vat_number || null); }
    if (!fields.length) return res.status(400).json({ error: 'No changes' });
    params.push(id);
    const [r] = await pool.query(`UPDATE customers SET ${fields.join(', ')} WHERE id = ?`, params);
    res.json({ affected: r.affectedRows });
  },
  async addContact(req, res) {
    const { id } = req.params;
    const { role, name, email, phone } = req.body || {};
    if (!name) return res.status(400).json({ error: 'contact name required' });
    const [r] = await pool.query('INSERT INTO customer_contacts (customer_id,role,name,email,phone) VALUES (?,?,?,?,?)',
      [id, (role||null), name, (email||null), (phone||null)]);
    res.status(201).json({ id: r.insertId });
  },
  async updateContact(req, res) {
    const { id, contactId } = req.params;
    const { role, name, email, phone } = req.body || {};
    const fields = []; const params = [];
    if (role !== undefined) { fields.push('role = ?'); params.push(role || null); }
    if (name !== undefined) { fields.push('name = ?'); params.push(name); }
    if (email !== undefined) { fields.push('email = ?'); params.push(email || null); }
    if (phone !== undefined) { fields.push('phone = ?'); params.push(phone || null); }
    if (!fields.length) return res.status(400).json({ error: 'No changes' });
    params.push(id, contactId);
    const [r] = await pool.query(`UPDATE customer_contacts SET ${fields.join(', ')} WHERE customer_id = ? AND id = ?`, params);
    res.json({ affected: r.affectedRows });
  },
  async deleteContact(req, res) {
    const { id, contactId } = req.params;
    await pool.query('DELETE FROM customer_contacts WHERE customer_id = ? AND id = ?', [id, contactId]);
    res.status(204).send();
  }
};
