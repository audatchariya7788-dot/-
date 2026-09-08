PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS mt5_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  login TEXT NOT NULL UNIQUE,
  server TEXT NOT NULL,
  account_type TEXT,
  currency TEXT,
  balance REAL DEFAULT 0,
  equity REAL DEFAULT 0,
  margin REAL DEFAULT 0,
  free_margin REAL DEFAULT 0,
  ea_status TEXT DEFAULT 'OFFLINE',
  last_seen_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  symbol TEXT NOT NULL DEFAULT 'XAUUSD',
  enabled INTEGER NOT NULL DEFAULT 0,
  enable_trading INTEGER NOT NULL DEFAULT 0,
  profit_per_trade REAL DEFAULT 20,
  loss_per_trade REAL DEFAULT 10,
  daily_profit_target REAL DEFAULT 100,
  daily_loss_limit REAL DEFAULT 50,
  max_drawdown_pct REAL DEFAULT 10,
  max_open_positions INTEGER DEFAULT 3,
  min_signal_score INTEGER DEFAULT 80,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(account_id) REFERENCES mt5_accounts(id)
);

CREATE TABLE IF NOT EXISTS bot_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bot_id INTEGER NOT NULL,
  timeframe TEXT NOT NULL,
  ema_fast INTEGER DEFAULT 20,
  ema_slow INTEGER DEFAULT 50,
  rsi_period INTEGER DEFAULT 14,
  rsi_buy_min REAL DEFAULT 55,
  rsi_sell_max REAL DEFAULT 45,
  stop_loss_points INTEGER DEFAULT 200,
  take_profit_points INTEGER DEFAULT 400,
  trailing_stop_points INTEGER DEFAULT 0,
  break_even_points INTEGER DEFAULT 0,
  FOREIGN KEY(bot_id) REFERENCES bots(id)
);

CREATE TABLE IF NOT EXISTS signals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bot_id INTEGER NOT NULL,
  symbol TEXT NOT NULL,
  timeframe TEXT NOT NULL,
  action TEXT NOT NULL,
  score INTEGER NOT NULL,
  reason TEXT,
  price REAL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(bot_id) REFERENCES bots(id)
);

CREATE TABLE IF NOT EXISTS orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bot_id INTEGER NOT NULL,
  mt5_ticket TEXT,
  symbol TEXT NOT NULL,
  side TEXT NOT NULL,
  volume REAL,
  entry_price REAL,
  stop_loss REAL,
  take_profit REAL,
  exit_price REAL,
  profit REAL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'OPEN',
  opened_at TEXT,
  closed_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(bot_id) REFERENCES bots(id)
);

CREATE TABLE IF NOT EXISTS risk_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bot_id INTEGER,
  event_type TEXT NOT NULL,
  value REAL,
  message TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(bot_id) REFERENCES bots(id)
);

CREATE TABLE IF NOT EXISTS system_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  level TEXT NOT NULL,
  source TEXT NOT NULL,
  message TEXT NOT NULL,
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_signals_bot_time ON signals(bot_id, created_at);
CREATE INDEX IF NOT EXISTS idx_orders_bot_time ON orders(bot_id, created_at);
CREATE INDEX IF NOT EXISTS idx_accounts_last_seen ON mt5_accounts(last_seen_at);
