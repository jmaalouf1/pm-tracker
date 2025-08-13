# --- Additions for v1.2 ---
paths:
  /customers:
    get: { summary: List/search customers }
    post: { summary: Create customer (with optional contacts) }
  /customers/{id}:
    get: { summary: Get customer with contacts }
    put: { summary: Update customer fields }
  /customers/{id}/contacts:
    post: { summary: Add contact }
  /customers/{id}/contacts/{contactId}:
    put: { summary: Update contact }
    delete: { summary: Delete contact }
  /projects/{id}/terms:
    get: { summary: List project payment terms }
    put: { summary: Replace all project terms (sum of percentages must be 100) }
