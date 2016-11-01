SELECT 'Authentication script started...' AS Message;
CREATE USER odoo WITH CREATEDB NOCREATEROLE PASSWORD 'odoo';
SELECT 'Authentication script ended.' AS Message;