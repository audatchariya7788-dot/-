#property strict
#property version   "0.1.0"
#property description "MT5 Auto Trading bridge - telemetry first, trading disabled by default"

input string ApiBaseUrl = "https://YOUR-WORKER.workers.dev";
input string ApiKey = "";
input int HeartbeatSeconds = 10;
input bool EnableTrading = false;
input string TradeSymbol = "XAUUSD";

string TrimTrailingSlash(string value)
{
   while(StringLen(value) > 0 && StringGetCharacter(value, StringLen(value) - 1) == '/')
      value = StringSubstr(value, 0, StringLen(value) - 1);
   return value;
}

string JsonEscape(string value)
{
   StringReplace(value, "\\", "\\\\");
   StringReplace(value, "\"", "\\\"");
   return value;
}

string BuildHeartbeatJson()
{
   MqlTick tick;
   SymbolInfoTick(TradeSymbol, tick);

   long login = AccountInfoInteger(ACCOUNT_LOGIN);
   string server = AccountInfoString(ACCOUNT_SERVER);
   string currency = AccountInfoString(ACCOUNT_CURRENCY);
   long marginMode = AccountInfoInteger(ACCOUNT_MARGIN_MODE);

   int positions = PositionsTotal();

   string body = "{";
   body += "\"login\":" + (string)login + ",";
   body += "\"server\":\"" + JsonEscape(server) + "\",";
   body += "\"accountType\":\"" + (string)marginMode + "\",";
   body += "\"currency\":\"" + JsonEscape(currency) + "\",";
   body += "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
   body += "\"equity\":" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + ",";
   body += "\"margin\":" + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN), 2) + ",";
   body += "\"freeMargin\":" + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2) + ",";
   body += "\"symbol\":\"" + JsonEscape(TradeSymbol) + "\",";
   body += "\"bid\":" + DoubleToString(tick.bid, _Digits) + ",";
   body += "\"ask\":" + DoubleToString(tick.ask, _Digits) + ",";
   body += "\"positions\":" + (string)positions;
   body += "}";
   return body;
}

bool SendHeartbeat()
{
   string base = TrimTrailingSlash(ApiBaseUrl);
   if(StringFind(base, "YOUR-WORKER") >= 0)
   {
      Print("Set ApiBaseUrl before running the EA.");
      return false;
   }

   string url = base + "/api/mt5/heartbeat";
   string headers = "Content-Type: application/json\r\n";
   if(StringLen(ApiKey) > 0)
      headers += "x-api-key: " + ApiKey + "\r\n";

   string body = BuildHeartbeatJson();
   char post[];
   char result[];
   string resultHeaders;

   int bodySize = StringToCharArray(body, post, 0, -1, CP_UTF8);
   if(bodySize > 0 && post[bodySize - 1] == 0)
      ArrayResize(post, bodySize - 1);

   ResetLastError();
   int code = WebRequest("POST", url, headers, 10000, post, result, resultHeaders);
   if(code == -1)
   {
      PrintFormat("WebRequest failed. Error=%d. Add API URL to MT5 Tools > Options > Expert Advisors > Allow WebRequest.", GetLastError());
      return false;
   }

   string response = CharArrayToString(result, 0, -1, CP_UTF8);
   if(code >= 200 && code < 300)
   {
      PrintFormat("API heartbeat OK. HTTP=%d Response=%s", code, response);
      return true;
   }

   PrintFormat("API heartbeat rejected. HTTP=%d Response=%s", code, response);
   return false;
}

int OnInit()
{
   if(HeartbeatSeconds < 2)
      HeartbeatSeconds = 2;

   if(!SymbolSelect(TradeSymbol, true))
      PrintFormat("Warning: could not select %s", TradeSymbol);

   EventSetTimer(HeartbeatSeconds);
   PrintFormat("AutoTrader initialized. Account=%I64d Server=%s Trading=%s",
               AccountInfoInteger(ACCOUNT_LOGIN), AccountInfoString(ACCOUNT_SERVER),
               EnableTrading ? "ENABLED" : "DISABLED");

   SendHeartbeat();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   PrintFormat("AutoTrader stopped. reason=%d", reason);
}

void OnTimer()
{
   SendHeartbeat();
}

void OnTick()
{
   // V0.1 intentionally does not place orders.
   // Trading logic will be enabled only after bridge/risk tests pass.
   if(!EnableTrading)
      return;
}
