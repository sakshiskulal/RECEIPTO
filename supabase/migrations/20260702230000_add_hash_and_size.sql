-- Migration to add receipt_hash and file_size columns to receipts table
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS receipt_hash TEXT NULL;
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS file_size BIGINT NULL;
