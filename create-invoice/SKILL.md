---
name: create-invoice
description: Generate and send invoices through the Invoice Ninja API. Triggers on invoice creation, billing, generating a quote/devis.
---

# Create Invoice via Invoice Ninja

Generate and send invoices through the Invoice Ninja API.

## Prerequisites

- API token stored in a secret manager (Bitwarden / Vaultwarden / 1Password) — never hardcode
- Client must already exist in Invoice Ninja, or create them first
- Self-hosted Invoice Ninja or hosted at `invoiceninja.com`

## Steps

1. **Gather info** from user:
   - Client name (or ID)
   - Line items (description, quantity, unit price)
   - Due date
   - Any notes or payment terms (e.g. "Net 30", VAT details)

2. **Look up client**: `GET /api/v1/clients?filter=<name>` with `X-API-TOKEN` header

3. **Create invoice**: `POST /api/v1/invoices`
   ```json
   {
     "client_id": "<id>",
     "line_items": [
       {"product_key": "consulting", "notes": "Q1 advisory", "quantity": 1, "cost": 100}
     ],
     "due_date": "YYYY-MM-DD"
   }
   ```

4. **Verify response** — check status code is 200. On 500: retry once, then surface the error.

5. **Download PDF** if needed: `GET /api/v1/invoices/<id>/download`

6. **Upload to a shared drive** if the user has a folder convention (e.g. company shared Drive `/Invoices/<year>/`)

## Error Handling

- Auth errors → ask user to refresh the API token in their secret manager
- 5xx errors → retry once only, then report failure with the request body so the user can replay manually
- Image/encoding errors during PDF download → tell user to retry in a fresh session
