# MT5 Auto Trading Platform

Initial implementation for MT5 Demo integration.

## Scope V0.1
- MT5 Expert Advisor heartbeat
- Account/balance/equity telemetry
- Symbol price telemetry
- Open-position telemetry
- Cloudflare Worker API bridge
- D1 schema for accounts, bots, settings, signals, orders and logs
- Auto-trading execution is disabled by default

## Target demo environment
- MetaTrader 5
- MetaQuotes-Demo
- Hedge account
- XAUUSD

## Safety
The EA ships with `EnableTrading=false`. Do not enable live trading until connection, risk rules, backtest and demo forward testing are verified.

## MT5 setup
1. Compile `mt5/EA/AutoTrader.mq5` in MetaEditor.
2. In MT5, allow WebRequest for the deployed API origin.
3. Attach the EA to XAUUSD.
4. Keep `EnableTrading=false` for the first connection test.
5. Confirm the Experts/Journal tab shows `API heartbeat OK`.
