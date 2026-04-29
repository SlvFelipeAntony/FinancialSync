-- Tabela de Usuários
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    password TEXT NOT NULL
);

-- Tabela de Contas com CHECK Constraint
CREATE TABLE accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    balance REAL NOT NULL DEFAULT 0.0,
    user_id INTEGER NOT NULL,
    CONSTRAINT fk_accounts_users 
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT check_account_type 
        CHECK (type IN ('corrente', 'poupanca', 'investimento', 'carteira'))
);

-- Transações de Conta (Débito/Pix/Dinheiro)
CREATE TABLE account_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    description TEXT NOT NULL,
    value REAL NOT NULL,
    category TEXT NOT NULL,
    date TEXT NOT NULL, -- Formato ISO8601 (YYYY-MM-DD)
    time TEXT,          -- Formato HH:MM:SS
    application TEXT,
    link TEXT,
    accounts_id INTEGER NOT NULL,
    FOREIGN KEY (accounts_id) REFERENCES accounts (id) ON DELETE CASCADE
);

-- Cartões de Crédito
CREATE TABLE credit_card (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    lastdigits TEXT NOT NULL,
    limit_value REAL NOT NULL,
    closingdate TEXT NOT NULL,
    expirationdate TEXT NOT NULL,
    account_id INTEGER NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
);

-- Transações de Cartão de Crédito
CREATE TABLE credit_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    description TEXT NOT NULL,
    value REAL NOT NULL,
    category TEXT NOT NULL,
    date TEXT NOT NULL,
    time TEXT,
    application TEXT,
    link TEXT,
    installment INTEGER DEFAULT 1,
    credit_card_id INTEGER NOT NULL,
    FOREIGN KEY (credit_card_id) REFERENCES credit_card (id) ON DELETE CASCADE
);