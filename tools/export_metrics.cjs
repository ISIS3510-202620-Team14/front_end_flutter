const fs = require('node:fs');
const path = require('node:path');
const cliRoot = process.env.FIREBASE_TOOLS_ROOT || path.join(process.env.APPDATA || '', 'npm', 'node_modules', 'firebase-tools');
const auth = require(path.join(cliRoot, 'lib', 'auth.js'));

function decode(value) {
  if ('stringValue' in value) { return value.stringValue; }
  if ('integerValue' in value) { return Number(value.integerValue); }
  if ('doubleValue' in value) { return value.doubleValue; }
  if ('timestampValue' in value) { return value.timestampValue; }
  if ('booleanValue' in value) { return value.booleanValue; }
  return null;
}
function quoted(value) { return '"' + String(value ?? '').replaceAll('"', '""') + '"'; }

async function main() {
  const account = auth.getGlobalDefaultAccount();
  if (!account) { throw new Error('Firebase CLI login required'); }
  const credentials = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const rows = [];
  let pageToken = '';
  let excluded = 0;
  do {
    const url = new URL('https://firestore.googleapis.com/v1/projects/enad-movil/databases/(default)/documents/events');
    url.searchParams.set('pageSize', '1000');
    if (pageToken) { url.searchParams.set('pageToken', pageToken); }
    const response = await fetch(url, { headers: { Authorization: 'Bearer ' + credentials.access_token } });
    if (!response.ok) { throw new Error('Firestore read failed: ' + response.status); }
    const data = await response.json();
    for (const document of data.documents ?? []) {
      const event = {};
      for (const [key, value] of Object.entries(document.fields ?? {})) { event[key] = decode(value); }
      if (event.platform !== 'flutter') { excluded++; continue; }
      if (!['activity_selected', 'grouping_method_selected'].includes(event.name)) { continue; }
      rows.push({ date: event.date || new Date(Date.parse(event.createdAt) - 5 * 60 * 60 * 1000).toISOString().slice(0, 10), name: event.name,
        title: event.title ?? '', subject: event.subject ?? '', source: event.source ?? '',
        method: event.method ?? '', classSize: event.classSize ?? '', count: 1, platform: 'flutter' });
    }
    pageToken = data.nextPageToken ?? '';
  } while (pageToken);
  const columns = ['date', 'name', 'title', 'subject', 'source', 'method', 'classSize', 'count', 'platform'];
  const csv = '\uFEFF' + columns.join(',') + '\n' + rows.map(function(row) {
    return columns.map(function(column) { return quoted(row[column]); }).join(',');
  }).join('\n') + '\n';
  const destination = path.resolve(process.argv[2] || 'analytics-export');
  fs.mkdirSync(destination, { recursive: true });
  fs.writeFileSync(path.join(destination, 'flutter_bq_events.csv'), csv, 'utf8');
  fs.writeFileSync(path.join(destination, 'metrics_cutoff.json'), JSON.stringify({
    project: 'enad-movil', extractedAt: new Date().toISOString(), rows: rows.length,
    excludedOtherOrUnknownPlatform: excluded,
    source: 'Firestore events; platform=flutter only',
    limitations: ['Legacy groupingEvents have no verifiable platform; excluded.', 'New Flutter grouping selections appear after using the updated app.'],
  }, null, 2));
  console.log(JSON.stringify({ exportedRows: rows.length, excludedRows: excluded }));
}
main().catch(function(error) { console.error(error.message); process.exitCode = 1; });
