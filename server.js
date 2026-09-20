const fs = require('fs');
const path = require('path');
const http = require('http');

function loadEnv(filePath) {
  const data = fs.existsSync(filePath) ? fs.readFileSync(filePath, 'utf8') : '';
  const env = {};
  for (const line of data.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const idx = trimmed.indexOf('=');
    if (idx === -1) continue;
    const key = trimmed.slice(0, idx).trim();
    const value = trimmed.slice(idx + 1).trim();
    env[key] = value.replace(/^['"]|['"]$/g, '');
  }
  return env;
}

const env = loadEnv(path.join(__dirname, '.env'));
const PORT = env.PORT || 3000;
const root = __dirname;
const envUrl = env.SUPABASE_URL || '';
const envAnon = env.SUPABASE_ANON_KEY || '';

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.txt': 'text/plain; charset=utf-8'
};

function resolveFile(requestPath) {
  const safe = (requestPath === '/' ? '/index.html' : requestPath).replace(/\\/g, '/');
  const target = path.join(root, safe.replace(/^\//, ''));
  if (target.startsWith(root) && fs.existsSync(target) && fs.statSync(target).isFile()) return target;
  return null;
}

function serveFile(filePath, res) {
  const ext = path.extname(filePath).toLowerCase();
  const content = fs.readFileSync(filePath);
  res.writeHead(200, { 'Content-Type': mime[ext] || 'application/octet-stream' });
  res.end(content);
}

function injectEnvIntoLedger(filePath) {
  let html = fs.readFileSync(filePath, 'utf8');
  html = html.replace(/__SUPABASE_URL__/, envUrl);
  html = html.replace(/__SUPABASE_ANON_KEY__/, envAnon);
  return html;
}

const server = http.createServer((req, res) => {
  const requestPath = new URL(req.url, 'http://localhost:' + PORT).pathname;
  const filePath = resolveFile(requestPath);

  if (!filePath) {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Not found');
    return;
  }

  if (filePath.endsWith('ledger.html')) {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(injectEnvIntoLedger(filePath));
    return;
  }

  serveFile(filePath, res);
});

server.listen(PORT, () => {
  console.log('Ikimina ledger running at http://localhost:' + PORT);
  console.log('Using SUPABASE_URL:', envUrl);
  console.log('Using SUPABASE_ANON_KEY:', envAnon ? envAnon.slice(0, 20) + '...' : 'missing');
});
