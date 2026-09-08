# MT5 Demo Connection Test — V0.1

This is the first live integration test using MetaTrader 5 Demo only. Order execution remains disabled.

## Target
- MT5: MetaTrader 5
- Broker/server: MetaQuotes-Demo
- Account: 112258581 (or the currently logged-in Demo account)
- Symbol: XAUUSD
- EA: `mt5/EA/AutoTrader.mq5`

## 1. Create the D1 database
From the repository root:

```bash
npx wrangler d1 create mt5-auto-trading
```

Copy the returned `database_id` into `wrangler.toml`:

```toml
[[d1_databases]]
binding = "DB"
database_name = "mt5-auto-trading"
database_id = "YOUR_REAL_DATABASE_ID"
```

Then initialize the remote schema:

```bash
npx wrangler d1 execute mt5-auto-trading --remote --file=database/schema.sql
```

## 2. Deploy the API

```bash
npx wrangler deploy
```

The command returns a Worker URL such as:

`https://mt5-auto-trading.<subdomain>.workers.dev`

Verify:

```bash
curl https://mt5-auto-trading.<subdomain>.workers.dev/health
```

Expected shape:

```json
{"ok":true,"service":"mt5-auto-trading","version":"0.1.0"}
```

## 3. Optional API key
For the first private test, set a bridge key:

```bash
npx wrangler secret put MT5_BRIDGE_KEY
```

Use the same value in the EA `ApiKey` input. Never commit the key to GitHub.

## 4. Compile the EA
Open `mt5/EA/AutoTrader.mq5` in MetaEditor and compile it.

Set these inputs:

- `ApiBaseUrl` = deployed Worker URL
- `ApiKey` = bridge key if configured
- `HeartbeatSeconds` = 10
- `EnableTrading` = `false`
- `TradeSymbol` = `XAUUSD`

## 5. Allow WebRequest in MT5
MT5:

`Tools > Options > Expert Advisors > Allow WebRequest for listed URL`

Add only the deployed Worker origin, for example:

`https://mt5-auto-trading.<subdomain>.workers.dev`

## 6. Attach EA
Open XAUUSD, attach `AutoTrader` and enable Algo Trading.

The EA must remain in telemetry-only mode. It will not place orders while `EnableTrading=false`.

## 7. Verify
In MT5 `Experts` / `Journal`, expect:

`API heartbeat OK`

Then verify the account:

```bash
curl "https://mt5-auto-trading.<subdomain>.workers.dev/api/mt5/status?login=112258581"
```

The response should contain the account row with balance, equity, free margin, server and `ea_status: ONLINE`.

## Acceptance criteria
- API `/health` returns HTTP 200.
- EA initializes without compile errors.
- MT5 WebRequest succeeds.
- Worker receives heartbeat.
- D1 contains the MT5 account.
- Dashboard/API reports EA `ONLINE`.
- No trade/order is placed.

## Next stage
After this test passes, implement V0.2 market analysis and signal evaluation. Only after V0.2 is verified should order execution be enabled in a separate Demo-only test.
