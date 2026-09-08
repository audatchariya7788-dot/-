const json = (data, status = 200) => new Response(JSON.stringify(data), {
  status,
  headers: { 'content-type': 'application/json; charset=utf-8' }
});

const cors = (response) => {
  const h = new Headers(response.headers);
  h.set('access-control-allow-origin', '*');
  h.set('access-control-allow-methods', 'GET,POST,OPTIONS');
  h.set('access-control-allow-headers', 'content-type,x-api-key');
  return new Response(response.body, { status: response.status, headers: h });
};

function auth(request, env) {
  const configured = env.MT5_BRIDGE_KEY;
  if (!configured) return true;
  return request.headers.get('x-api-key') === configured;
}

async function readBody(request) {
  try { return await request.json(); } catch { return null; }
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return cors(new Response(null, { status: 204 }));

    const url = new URL(request.url);
    if (url.pathname === '/health') {
      return cors(json({ ok: true, service: 'mt5-auto-trading', version: env.APP_VERSION || '0.1.0' }));
    }

    if (!auth(request, env)) return cors(json({ ok: false, error: 'unauthorized' }, 401));

    if (request.method === 'POST' && url.pathname === '/api/mt5/heartbeat') {
      const body = await readBody(request);
      if (!body?.login || !body?.server) return cors(json({ ok: false, error: 'login and server are required' }, 400));

      const now = new Date().toISOString();
      await env.DB.prepare(`
        INSERT INTO mt5_accounts
          (login, server, account_type, currency, balance, equity, margin, free_margin, ea_status, last_seen_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'ONLINE', ?, ?)
        ON CONFLICT(login) DO UPDATE SET
          server=excluded.server,
          account_type=excluded.account_type,
          currency=excluded.currency,
          balance=excluded.balance,
          equity=excluded.equity,
          margin=excluded.margin,
          free_margin=excluded.free_margin,
          ea_status='ONLINE',
          last_seen_at=excluded.last_seen_at,
          updated_at=excluded.updated_at
      `).bind(
        String(body.login), String(body.server), body.accountType || null, body.currency || null,
        Number(body.balance || 0), Number(body.equity || 0), Number(body.margin || 0), Number(body.freeMargin || 0), now, now
      ).run();

      await env.DB.prepare(`INSERT INTO system_logs(level, source, message, metadata_json) VALUES('INFO','MT5','heartbeat',?)`)
        .bind(JSON.stringify({ login: body.login, symbol: body.symbol, bid: body.bid, ask: body.ask })).run();

      return cors(json({ ok: true, serverTime: now, action: 'KEEP_ALIVE' }));
    }

    if (request.method === 'POST' && url.pathname === '/api/mt5/positions') {
      const body = await readBody(request);
      return cors(json({ ok: true, received: Array.isArray(body?.positions) ? body.positions.length : 0 }));
    }

    if (request.method === 'GET' && url.pathname === '/api/mt5/status') {
      const login = url.searchParams.get('login');
      if (!login) return cors(json({ ok: false, error: 'login is required' }, 400));
      const row = await env.DB.prepare(`SELECT * FROM mt5_accounts WHERE login=?`).bind(login).first();
      return cors(json({ ok: true, account: row || null }));
    }

    return cors(json({ ok: false, error: 'not_found' }, 404));
  }
};
