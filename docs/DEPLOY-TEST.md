# V0.1 Deploy and Demo Test

## A. Cloudflare

From the repository root:

```bash
npx wrangler login
npx wrangler d1 create mt5-auto-trading
```

Copy the returned database ID into `wrangler.toml` in place of `REPLACE_WITH_D1_DATABASE_ID`.

Apply the schema:

```bash
npx wrangler d1 execute mt5-auto-trading --remote --file=database/schema.sql
```

Set the bridge key:

```bash
npx wrangler secret put MT5_BRIDGE_KEY
```

Deploy:

```bash
npx wrangler deploy
```

Record the deployed Worker URL and use it as the EA `ApiBaseUrl`.

## B. MT5

1. Open MetaEditor.
2. Open `mt5/EA/AutoTrader.mq5`.
3. Compile.
4. In MT5 open `Tools > Options > Expert Advisors`.
5. Enable `Allow WebRequest for listed URL` and add the Worker origin, for example `https://your-worker.workers.dev`.
6. Attach `AutoTrader` to the `XAUUSD` chart.
7. Set `ApiBaseUrl` to the deployed Worker URL.
8. Set `ApiKey` to the same value stored as `MT5_BRIDGE_KEY`.
9. Keep `EnableTrading=false`.
10. Confirm `Experts` shows `API heartbeat OK` every heartbeat interval.

## C. API tests

```bash
curl https://YOUR-WORKER.workers.dev/health
curl "https://YOUR-WORKER.workers.dev/api/mt5/status?login=112258581" -H "x-api-key: YOUR_KEY"
```

Expected after EA heartbeat:
- health returns `ok: true`
- account login `112258581` exists
- `ea_status` becomes `ONLINE`
- balance/equity/free margin update from MT5

## D. Important

V0.1 does not place orders even if `EnableTrading=true`; the execution engine is intentionally not implemented yet. The next stage adds multi-timeframe analysis, signal scoring, risk checks, and demo-only order execution behind explicit safeguards.
