// Route catalog exposed by wireguard-ui (Go server, `main.go`).
// All routes expect a session cookie `session_token` unless `DisableLogin`
// or explicitly public endpoints apply.
//
// Base: `{origin}{basePath}` — e.g. `https://host/wg`.
//
// Authentication:
//   POST {base}/login  (JSON: username, password, rememberMe) → Set-Cookie
//   GET  {base}/logout
//
// Peers / clients:
//   GET  {base}/api/clients
//   GET  {base}/api/client/:id
//   POST {base}/new-client
//   POST {base}/update-client
//   POST {base}/client/set-status   (JSON: id, status)
//   POST {base}/api/apply-wg-config  (after edits; empty body or restart_wireguard)
//   POST {base}/remove-client       (JSON: id)
//   GET  {base}/download?clientid=
//
// Metrics:
//   GET  {base}/api/dashboard-stats
//   GET  {base}/api/wg-peer-stats   (map pubkey → {rx,tx})
//   GET  {base}/api/wg-traffic-series?range=24h|7d|30d
//
// Tunnel:
//   GET  {base}/api/wireguard/tunnel-status
//
// Logs (requires realtime enabled on server):
//   GET  {base}/api/system-logs     → may return 403
//   POST {base}/api/global-settings/realtime-stats  JSON {realtime_stats_enabled}  (admin)
//
// UI metadata:
//   GET  {base}/api/ui-nav-hints
//
// IPs:
//   GET  {base}/api/suggest-client-ips?sr=
//
// Application (admin / advanced; not all used by this client):
//   GET  {base}/test-hash              → status true = pending changes (same as web needsWgConfApply)
//   POST {base}/api/apply-wg-config
//
// This Flutter client mainly implements `WguRepository` methods.
