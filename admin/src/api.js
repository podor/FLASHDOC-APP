// ── API client ──────────────────────────────────────────────────
const BASE = 'https://api.flashdoc.tchoukheadcorp.net/api'

function getToken() {
  return localStorage.getItem('fd_admin_token')
}

async function api(method, path, data) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(getToken() ? { Authorization: `Bearer ${getToken()}` } : {}),
    },
    body: data ? JSON.stringify(data) : undefined,
  })
  const json = await res.json()
  if (!res.ok) throw new Error(json.message || 'Erreur API')
  return json
}

export const apiGet  = (path)       => api('GET',  path)
export const apiPost = (path, data) => api('POST', path, data)
export const apiPut  = (path, data) => api('PUT',  path, data)
