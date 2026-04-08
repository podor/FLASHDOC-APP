import { useState, useEffect, useCallback } from 'react'
import { apiGet, apiPost, apiPut } from './api.js'

// ── Couleurs FlashDoc ─────────────────────────────────────────
const C = {
  primary:  '#0066FF',
  doctor:   '#00A878',
  warning:  '#F59E0B',
  error:    '#EF4444',
  success:  '#10B981',
  bg:       '#F5F7FA',
  card:     '#FFFFFF',
  border:   '#E5E7EB',
  text:     '#1A1A2E',
  muted:    '#6B7280',
}

// ── Status labels ─────────────────────────────────────────────
const STATUS_LABELS = {
  PENDING_DOCS:      { label: 'Docs manquants',    color: C.muted,   bg: '#F3F4F6' },
  PENDING_REVIEW:    { label: 'En cours d\'examen', color: C.warning, bg: '#FEF3C7' },
  PENDING_INTERVIEW: { label: 'En attente interview', color: C.primary, bg: '#EFF6FF' },
  APPROVED:          { label: 'Approuvé',           color: C.success, bg: '#D1FAE5' },
  SUSPENDED:         { label: 'Suspendu',           color: C.error,   bg: '#FEE2E2' },
  BANNED:            { label: 'Radié',              color: '#7F1D1D', bg: '#FCA5A5' },
}

// ─────────────────────────────────────────────────────────────
// COMPOSANTS UI
// ─────────────────────────────────────────────────────────────

function Badge({ status }) {
  const s = STATUS_LABELS[status] || { label: status, color: C.muted, bg: '#F3F4F6' }
  return (
    <span style={{
      padding: '3px 10px', borderRadius: 20, fontSize: 11,
      fontWeight: 700, color: s.color, background: s.bg,
      border: `1px solid ${s.color}22`,
    }}>
      {s.label}
    </span>
  )
}

function Btn({ children, onClick, color = C.primary, outline, small, disabled }) {
  return (
    <button onClick={onClick} disabled={disabled} style={{
      padding: small ? '6px 14px' : '10px 20px',
      borderRadius: 10, fontSize: small ? 12 : 14,
      fontWeight: 600, cursor: disabled ? 'not-allowed' : 'pointer',
      border: `2px solid ${color}`,
      background: outline ? 'white' : color,
      color: outline ? color : 'white',
      opacity: disabled ? 0.5 : 1,
      transition: 'all 0.15s',
    }}>
      {children}
    </button>
  )
}

function Card({ children, style }) {
  return (
    <div style={{
      background: C.card, borderRadius: 16, border: `1px solid ${C.border}`,
      boxShadow: '0 2px 8px rgba(0,0,0,0.05)', padding: 20, ...style,
    }}>
      {children}
    </div>
  )
}

function Stat({ label, value, color, icon }) {
  return (
    <Card style={{ textAlign: 'center', flex: 1 }}>
      <div style={{ fontSize: 28, marginBottom: 4 }}>{icon}</div>
      <div style={{ fontSize: 28, fontWeight: 800, color }}>{value}</div>
      <div style={{ fontSize: 12, color: C.muted, marginTop: 4 }}>{label}</div>
    </Card>
  )
}

// ─────────────────────────────────────────────────────────────
// LOGIN
// ─────────────────────────────────────────────────────────────

function Login({ onLogin }) {
  const [phone, setPhone] = useState('+237600000000')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleLogin(e) {
    e.preventDefault()
    setLoading(true); setError('')
    try {
      const res = await fetch('https://api.flashdoc.tchoukheadcorp.net/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone, password }),
      })
      const data = await res.json()
      if (!data.success) throw new Error(data.message)
      if (data.data.user.role !== 'ADMIN') throw new Error('Accès réservé aux administrateurs')
      localStorage.setItem('fd_admin_token', data.data.accessToken)
      localStorage.setItem('fd_admin_user', JSON.stringify(data.data.user))
      onLogin(data.data.user)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  const inp = {
    width: '100%', padding: '12px 14px', borderRadius: 10, fontSize: 14,
    border: `1.5px solid ${C.border}`, outline: 'none', marginBottom: 12,
    background: '#F9FAFB',
  }

  return (
    <div style={{
      minHeight: '100vh', background: C.bg,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <div style={{ width: 380 }}>
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{ fontSize: 32, fontWeight: 900, marginBottom: 4 }}>
            <span style={{ color: C.primary }}>Flash</span>
            <span style={{ color: C.doctor }}>Doc</span>
          </div>
          <div style={{ fontSize: 13, color: C.muted }}>Administration</div>
        </div>
        <Card>
          <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, color: C.text }}>
            Connexion Admin
          </h2>
          <form onSubmit={handleLogin}>
            <label style={{ fontSize: 12, fontWeight: 600, color: C.muted }}>Téléphone</label>
            <input style={inp} value={phone}
              onChange={e => setPhone(e.target.value)} placeholder="+237600000000" />
            <label style={{ fontSize: 12, fontWeight: 600, color: C.muted }}>Mot de passe</label>
            <input style={inp} type="password" value={password}
              onChange={e => setPassword(e.target.value)} placeholder="••••••••" />
            {error && (
              <div style={{ background: '#FEE2E2', color: C.error, padding: '10px 14px',
                borderRadius: 8, fontSize: 13, marginBottom: 12 }}>
                {error}
              </div>
            )}
            <button type="submit" disabled={loading} style={{
              width: '100%', padding: '13px', borderRadius: 10, fontSize: 15,
              fontWeight: 700, background: C.primary, color: 'white',
              border: 'none', cursor: loading ? 'not-allowed' : 'pointer',
              opacity: loading ? 0.7 : 1,
            }}>
              {loading ? 'Connexion...' : 'Se connecter'}
            </button>
          </form>
        </Card>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
// SIDEBAR
// ─────────────────────────────────────────────────────────────

const MENU = [
  { id: 'dashboard',    label: 'Dashboard',        icon: '📊' },
  { id: 'doctors',      label: 'Dossiers médecins', icon: '🩺' },
  { id: 'patients',     label: 'Patients',          icon: '👤' },
  { id: 'consultations',label: 'Consultations',     icon: '💬' },
  { id: 'payments',     label: 'Paiements',         icon: '💳' },
]

function Sidebar({ active, onNav, user, onLogout }) {
  return (
    <div style={{
      width: 240, minHeight: '100vh', background: C.text,
      display: 'flex', flexDirection: 'column', padding: '24px 0',
      position: 'fixed', left: 0, top: 0, bottom: 0,
    }}>
      {/* Logo */}
      <div style={{ padding: '0 20px 24px', borderBottom: '1px solid #ffffff15' }}>
        <div style={{ fontSize: 22, fontWeight: 900 }}>
          <span style={{ color: C.primary }}>Flash</span>
          <span style={{ color: C.doctor }}>Doc</span>
        </div>
        <div style={{ fontSize: 10, color: '#ffffff50', marginTop: 2 }}>
          Administration
        </div>
      </div>

      {/* Menu */}
      <nav style={{ padding: '16px 12px', flex: 1 }}>
        {MENU.map(m => (
          <button key={m.id} onClick={() => onNav(m.id)} style={{
            width: '100%', display: 'flex', alignItems: 'center', gap: 12,
            padding: '10px 12px', borderRadius: 10, marginBottom: 4,
            background: active === m.id ? C.primary : 'transparent',
            color: active === m.id ? 'white' : '#ffffff80',
            border: 'none', cursor: 'pointer', fontSize: 14,
            fontWeight: active === m.id ? 600 : 400,
            transition: 'all 0.15s', textAlign: 'left',
          }}>
            <span>{m.icon}</span>
            <span>{m.label}</span>
          </button>
        ))}
      </nav>

      {/* User */}
      <div style={{ padding: '16px 20px', borderTop: '1px solid #ffffff15' }}>
        <div style={{ fontSize: 13, color: '#ffffff80', marginBottom: 4 }}>
          {user?.firstName} {user?.lastName}
        </div>
        <button onClick={onLogout} style={{
          background: 'none', border: 'none', color: '#ff6b6b',
          cursor: 'pointer', fontSize: 12, fontWeight: 600, padding: 0,
        }}>
          Se déconnecter
        </button>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────────────────────────

function Dashboard() {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      apiGet('/admin/stats').catch(() => null),
      apiGet('/admin/doctors').catch(() => ({ data: { doctors: [] } })),
      apiGet('/admin/patients').catch(() => ({ data: { patients: [] } })),
      apiGet('/admin/consultations').catch(() => ({ data: { consultations: [] } })),
    ]).then(([s, d, p, c]) => {
      setStats({
        doctors:       d?.data?.doctors?.length || 0,
        pendingDocs:   d?.data?.doctors?.filter(x => x.status === 'PENDING_REVIEW').length || 0,
        patients:      p?.data?.patients?.length || 0,
        consultations: c?.data?.consultations?.length || 0,
      })
    }).finally(() => setLoading(false))
  }, [])

  if (loading) return <Loading />

  return (
    <div>
      <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 24, color: C.text }}>
        Dashboard
      </h1>

      <div style={{ display: 'flex', gap: 16, marginBottom: 24 }}>
        <Stat label="Médecins affiliés"    value={stats?.doctors || 0}
          color={C.doctor}  icon="🩺" />
        <Stat label="Dossiers à traiter"   value={stats?.pendingDocs || 0}
          color={C.warning} icon="📋" />
        <Stat label="Patients inscrits"    value={stats?.patients || 0}
          color={C.primary} icon="👤" />
        <Stat label="Consultations totales" value={stats?.consultations || 0}
          color="#8B5CF6"   icon="💬" />
      </div>

      {stats?.pendingDocs > 0 && (
        <Card style={{ background: '#FEF3C7', border: `1px solid ${C.warning}` }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ fontSize: 24 }}>⚠️</span>
            <div>
              <div style={{ fontWeight: 700, color: '#92400E' }}>
                {stats.pendingDocs} dossier(s) en attente de vérification
              </div>
              <div style={{ fontSize: 13, color: '#B45309' }}>
                Des médecins attendent votre validation pour accéder à la plateforme.
              </div>
            </div>
          </div>
        </Card>
      )}
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
// DOSSIERS MÉDECINS — cœur du back-office
// ─────────────────────────────────────────────────────────────

function DoctorsList() {
  const [doctors, setDoctors] = useState([])
  const [loading, setLoading] = useState(true)
  const [selected, setSelected] = useState(null)
  const [filter, setFilter] = useState('ALL')

  const load = useCallback(() => {
    setLoading(true)
    apiGet('/admin/doctors')
      .then(r => setDoctors(r.data?.doctors || []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => { load() }, [load])

  const filtered = filter === 'ALL'
    ? doctors
    : doctors.filter(d => d.status === filter)

  if (selected) {
    return <DoctorDetail doctor={selected} onBack={() => { setSelected(null); load() }} />
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, color: C.text }}>
          Dossiers médecins
        </h1>
        <div style={{ display: 'flex', gap: 8 }}>
          {['ALL', 'PENDING_REVIEW', 'PENDING_INTERVIEW', 'APPROVED', 'SUSPENDED'].map(s => (
            <button key={s} onClick={() => setFilter(s)} style={{
              padding: '6px 14px', borderRadius: 8, fontSize: 12, fontWeight: 600,
              border: `1.5px solid ${filter === s ? C.primary : C.border}`,
              background: filter === s ? C.primary : 'white',
              color: filter === s ? 'white' : C.muted,
              cursor: 'pointer',
            }}>
              {s === 'ALL' ? 'Tous' :
               s === 'PENDING_REVIEW' ? 'À examiner' :
               s === 'PENDING_INTERVIEW' ? 'Interview' :
               s === 'APPROVED' ? 'Approuvés' : 'Suspendus'}
            </button>
          ))}
        </div>
      </div>

      {loading ? <Loading /> : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {filtered.length === 0 && (
            <Card style={{ textAlign: 'center', padding: 40, color: C.muted }}>
              Aucun dossier dans cette catégorie
            </Card>
          )}
          {filtered.map(d => (
            <DoctorCard key={d.id} doctor={d} onClick={() => setSelected(d)} onRefresh={load} />
          ))}
        </div>
      )}
    </div>
  )
}

function DoctorCard({ doctor, onClick, onRefresh }) {
  const user = doctor.user || {}
  const createdAt = doctor.createdAt
    ? new Date(doctor.createdAt).toLocaleDateString('fr-FR')
    : '—'

  return (
    <Card style={{ cursor: 'pointer' }} onClick={onClick}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        {/* Avatar */}
        <div style={{
          width: 48, height: 48, borderRadius: '50%',
          background: `linear-gradient(135deg, ${C.doctor}, ${C.primary})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'white', fontWeight: 700, fontSize: 18, flexShrink: 0,
        }}>
          {(user.firstName?.[0] || '?')}
        </div>

        {/* Infos */}
        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontWeight: 700, fontSize: 15, color: C.text }}>
              Dr. {user.firstName} {user.lastName}
            </span>
            <Badge status={doctor.status} />
          </div>
          <div style={{ fontSize: 12, color: C.muted, marginTop: 2 }}>
            {doctor.speciality} • ONMC: {doctor.onmcNumber} • {user.phone}
          </div>
          <div style={{ fontSize: 11, color: C.muted, marginTop: 2 }}>
            Soumis le {createdAt}
            {doctor.city && ` • ${doctor.city}`}
          </div>
        </div>

        {/* Actions rapides */}
        <div style={{ display: 'flex', gap: 8 }} onClick={e => e.stopPropagation()}>
          {doctor.status === 'PENDING_REVIEW' && (
            <Btn small color={C.doctor} onClick={async () => {
              await apiPut(`/admin/doctors/${doctor.id}/status`, { status: 'PENDING_INTERVIEW' })
              onRefresh()
            }}>
              → Interview
            </Btn>
          )}
          {doctor.status === 'PENDING_INTERVIEW' && (
            <Btn small color={C.success} onClick={async () => {
              await apiPut(`/admin/doctors/${doctor.id}/status`, { status: 'APPROVED' })
              onRefresh()
            }}>
              ✓ Approuver
            </Btn>
          )}
          <Btn small outline color={C.text} onClick={onClick}>
            Voir dossier →
          </Btn>
        </div>
      </div>
    </Card>
  )
}

// ─────────────────────────────────────────────────────────────
// DÉTAIL DOSSIER MÉDECIN
// ─────────────────────────────────────────────────────────────

function DoctorDetail({ doctor, onBack }) {
  const [note, setNote] = useState('')
  const [loading, setLoading] = useState(false)
  const [currentStatus, setCurrentStatus] = useState(doctor.status)
  const user = doctor.user || {}

  async function changeStatus(newStatus) {
    setLoading(true)
    try {
      await apiPut(`/admin/doctors/${doctor.id}/status`, {
        status: newStatus,
        note: note || undefined,
      })
      setCurrentStatus(newStatus)
      alert(`Statut mis à jour : ${STATUS_LABELS[newStatus]?.label}`)
    } catch (e) {
      alert('Erreur : ' + e.message)
    } finally {
      setLoading(false)
    }
  }

  const row = (label, value) => (
    <div style={{ display: 'flex', padding: '8px 0',
      borderBottom: `1px solid ${C.border}` }}>
      <span style={{ width: 180, fontSize: 13, color: C.muted, flexShrink: 0 }}>
        {label}
      </span>
      <span style={{ fontSize: 13, fontWeight: 600, color: C.text }}>
        {value || '—'}
      </span>
    </div>
  )

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 24 }}>
        <button onClick={onBack} style={{
          background: 'none', border: `1.5px solid ${C.border}`,
          borderRadius: 8, padding: '8px 14px', cursor: 'pointer',
          fontSize: 13, color: C.muted,
        }}>
          ← Retour
        </button>
        <h1 style={{ fontSize: 20, fontWeight: 700, color: C.text, flex: 1 }}>
          Dr. {user.firstName} {user.lastName}
        </h1>
        <Badge status={currentStatus} />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        {/* Colonne gauche */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>

          {/* Infos personnelles */}
          <Card>
            <h3 style={{ fontSize: 14, fontWeight: 700, color: C.doctor, marginBottom: 12 }}>
              👤 Informations personnelles
            </h3>
            {row('Prénom', user.firstName)}
            {row('Nom', user.lastName)}
            {row('Téléphone', user.phone)}
            {row('Email', user.email)}
            {row('Ville', doctor.city)}
            {row('Langues', doctor.languages?.join(', '))}
          </Card>

          {/* Infos professionnelles */}
          <Card>
            <h3 style={{ fontSize: 14, fontWeight: 700, color: C.doctor, marginBottom: 12 }}>
              🩺 Informations professionnelles
            </h3>
            {row('Spécialité', doctor.speciality)}
            {row('Numéro ONMC', doctor.onmcNumber)}
            {row('Bio', doctor.bio)}
            {row('Note moyenne', doctor.averageRating > 0 ? `${doctor.averageRating}/10` : 'Nouveau')}
            {row('Consultations', doctor.totalConsults)}
          </Card>

          {/* Documents */}
          <Card>
            <h3 style={{ fontSize: 14, fontWeight: 700, color: C.warning, marginBottom: 12 }}>
              📁 Documents fournis
            </h3>
            <DocItem label="Diplôme de médecine" url={doctor.diplomaUrl} />
            <DocItem label="Carte ONMC"          url={doctor.licenseUrl} />
          </Card>
        </div>

        {/* Colonne droite */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>

          {/* Processus de validation */}
          <Card>
            <h3 style={{ fontSize: 14, fontWeight: 700, color: C.primary, marginBottom: 16 }}>
              ✅ Processus de validation
            </h3>
            <ProcessStep
              number={1} label="Documents soumis"
              done={['PENDING_REVIEW','PENDING_INTERVIEW','APPROVED'].includes(currentStatus)}
            />
            <ProcessStep
              number={2} label="Documents vérifiés"
              done={['PENDING_INTERVIEW','APPROVED'].includes(currentStatus)}
            />
            <ProcessStep
              number={3} label="Interview planifiée"
              done={currentStatus === 'PENDING_INTERVIEW' || currentStatus === 'APPROVED'}
              active={currentStatus === 'PENDING_INTERVIEW'}
            />
            <ProcessStep
              number={4} label="Médecin approuvé"
              done={currentStatus === 'APPROVED'}
            />
          </Card>

          {/* Actions */}
          <Card>
            <h3 style={{ fontSize: 14, fontWeight: 700, color: C.text, marginBottom: 12 }}>
              ⚡ Actions administratives
            </h3>
            <textarea
              placeholder="Note interne (optionnel)..."
              value={note}
              onChange={e => setNote(e.target.value)}
              style={{
                width: '100%', padding: '10px 12px', borderRadius: 8,
                border: `1.5px solid ${C.border}`, fontSize: 13,
                resize: 'vertical', minHeight: 80, marginBottom: 12,
                outline: 'none', fontFamily: 'inherit',
              }}
            />
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {currentStatus === 'PENDING_DOCS' && (
                <Btn color={C.warning} onClick={() => changeStatus('PENDING_REVIEW')} disabled={loading}>
                  📋 Marquer docs reçus → En examen
                </Btn>
              )}
              {currentStatus === 'PENDING_REVIEW' && (
                <Btn color={C.primary} onClick={() => changeStatus('PENDING_INTERVIEW')} disabled={loading}>
                  🎥 Docs OK → Planifier interview
                </Btn>
              )}
              {currentStatus === 'PENDING_INTERVIEW' && (
                <Btn color={C.success} onClick={() => changeStatus('APPROVED')} disabled={loading}>
                  ✅ Interview OK → Approuver le médecin
                </Btn>
              )}
              {currentStatus === 'APPROVED' && (
                <Btn color={C.warning} outline onClick={() => changeStatus('SUSPENDED')} disabled={loading}>
                  ⏸️ Suspendre temporairement
                </Btn>
              )}
              {currentStatus === 'SUSPENDED' && (
                <Btn color={C.success} onClick={() => changeStatus('APPROVED')} disabled={loading}>
                  ▶️ Réactiver
                </Btn>
              )}
              {currentStatus !== 'BANNED' && (
                <Btn color={C.error} outline
                  onClick={() => window.confirm('Confirmer la radiation définitive ?') && changeStatus('BANNED')}
                  disabled={loading}>
                  🚫 Radier définitivement
                </Btn>
              )}
            </div>
          </Card>
        </div>
      </div>
    </div>
  )
}

function DocItem({ label, url }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '8px 0', borderBottom: `1px solid ${C.border}` }}>
      <span style={{ fontSize: 13, color: C.text }}>{label}</span>
      {url ? (
        <a href={url} target="_blank" rel="noreferrer" style={{
          fontSize: 12, color: C.primary, fontWeight: 600, textDecoration: 'none',
        }}>
          📄 Voir →
        </a>
      ) : (
        <span style={{ fontSize: 12, color: C.muted }}>Non fourni</span>
      )}
    </div>
  )
}

function ProcessStep({ number, label, done, active }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
      <div style={{
        width: 28, height: 28, borderRadius: '50%', flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 12, fontWeight: 700,
        background: done ? C.success : active ? C.primary : C.bg,
        color: done || active ? 'white' : C.muted,
        border: `2px solid ${done ? C.success : active ? C.primary : C.border}`,
      }}>
        {done ? '✓' : number}
      </div>
      <span style={{
        fontSize: 13, fontWeight: active ? 700 : 400,
        color: done ? C.success : active ? C.primary : C.muted,
      }}>
        {label}
      </span>
      {active && (
        <span style={{ fontSize: 10, background: C.primary, color: 'white',
          padding: '2px 8px', borderRadius: 10, fontWeight: 700 }}>
          EN COURS
        </span>
      )}
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
// PATIENTS
// ─────────────────────────────────────────────────────────────

function PatientsList() {
  const [patients, setPatients] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')

  useEffect(() => {
    apiGet('/admin/patients')
      .then(r => setPatients(r.data?.patients || []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const filtered = patients.filter(p => {
    const q = search.toLowerCase()
    const u = p.user || {}
    return !q || u.firstName?.toLowerCase().includes(q) ||
      u.lastName?.toLowerCase().includes(q) || u.phone?.includes(q)
  })

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, color: C.text }}>Patients</h1>
        <input
          placeholder="🔍 Rechercher..."
          value={search} onChange={e => setSearch(e.target.value)}
          style={{ padding: '8px 14px', borderRadius: 8, border: `1.5px solid ${C.border}`,
            fontSize: 13, outline: 'none', width: 220 }}
        />
      </div>
      {loading ? <Loading /> : (
        <Card style={{ padding: 0, overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: C.bg }}>
                {['Patient', 'Téléphone', 'Groupe sanguin', 'Ville', 'Inscrit le'].map(h => (
                  <th key={h} style={{ padding: '12px 16px', textAlign: 'left',
                    fontSize: 12, fontWeight: 600, color: C.muted }}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((p, i) => {
                const u = p.user || {}
                return (
                  <tr key={p.id} style={{
                    borderTop: `1px solid ${C.border}`,
                    background: i % 2 === 0 ? 'white' : '#FAFAFA',
                  }}>
                    <td style={{ padding: '12px 16px' }}>
                      <div style={{ fontWeight: 600, fontSize: 14 }}>
                        {u.firstName} {u.lastName}
                      </div>
                      <div style={{ fontSize: 11, color: C.muted }}>{u.email}</div>
                    </td>
                    <td style={{ padding: '12px 16px', fontSize: 13 }}>{u.phone}</td>
                    <td style={{ padding: '12px 16px' }}>
                      {p.bloodType ? (
                        <span style={{ background: '#FEE2E2', color: C.error,
                          padding: '2px 8px', borderRadius: 8, fontSize: 12, fontWeight: 700 }}>
                          {p.bloodType}
                        </span>
                      ) : '—'}
                    </td>
                    <td style={{ padding: '12px 16px', fontSize: 13, color: C.muted }}>
                      {p.city || '—'}
                    </td>
                    <td style={{ padding: '12px 16px', fontSize: 12, color: C.muted }}>
                      {p.createdAt ? new Date(p.createdAt).toLocaleDateString('fr-FR') : '—'}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </Card>
      )}
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
// CONSULTATIONS
// ─────────────────────────────────────────────────────────────

function ConsultationsList() {
  const [consultations, setConsultations] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    apiGet('/admin/consultations')
      .then(r => setConsultations(r.data?.consultations || []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const STATUS_C = {
    COMPLETED: C.success, IN_PROGRESS: C.primary, WAITING_DOCTOR: C.warning,
    EXPIRED: C.muted, CANCELLED: C.error, MATCHED: C.doctor,
  }

  return (
    <div>
      <h1 style={{ fontSize: 22, fontWeight: 700, color: C.text, marginBottom: 20 }}>
        Consultations
      </h1>
      {loading ? <Loading /> : (
        <Card style={{ padding: 0, overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: C.bg }}>
                {['Patient', 'Médecin', 'Statut', 'Mode', 'Montant', 'Date'].map(h => (
                  <th key={h} style={{ padding: '12px 16px', textAlign: 'left',
                    fontSize: 12, fontWeight: 600, color: C.muted }}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {consultations.map((c, i) => {
                const patient = c.patient?.user || {}
                const doctor  = c.doctor?.user  || {}
                const color = STATUS_C[c.status] || C.muted
                return (
                  <tr key={c.id} style={{
                    borderTop: `1px solid ${C.border}`,
                    background: i % 2 === 0 ? 'white' : '#FAFAFA',
                  }}>
                    <td style={{ padding: '12px 16px', fontSize: 13 }}>
                      {patient.firstName} {patient.lastName}
                    </td>
                    <td style={{ padding: '12px 16px', fontSize: 13 }}>
                      {doctor.firstName ? `Dr. ${doctor.firstName} ${doctor.lastName}` : '—'}
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <span style={{ background: color + '20', color, padding: '3px 10px',
                        borderRadius: 20, fontSize: 11, fontWeight: 700 }}>
                        {c.status}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px', fontSize: 13 }}>{c.mode}</td>
                    <td style={{ padding: '12px 16px', fontSize: 13, fontWeight: 600 }}>
                      {c.totalAmount?.toLocaleString()} F
                    </td>
                    <td style={{ padding: '12px 16px', fontSize: 12, color: C.muted }}>
                      {c.createdAt ? new Date(c.createdAt).toLocaleDateString('fr-FR') : '—'}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </Card>
      )}
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
// PAIEMENTS
// ─────────────────────────────────────────────────────────────

function PaymentsList() {
  const [payments, setPayments] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    apiGet('/admin/payments')
      .then(r => setPayments(r.data?.payments || []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const total = payments.reduce((sum, p) => p.status === 'SUCCESS' ? sum + p.amount : sum, 0)
  const commission = total * 0.25

  return (
    <div>
      <h1 style={{ fontSize: 22, fontWeight: 700, color: C.text, marginBottom: 20 }}>
        Paiements
      </h1>

      <div style={{ display: 'flex', gap: 16, marginBottom: 20 }}>
        <Stat label="Volume total"    value={`${total.toLocaleString()} F`}
          color={C.primary} icon="💰" />
        <Stat label="Commission FlashDoc (25%)" value={`${commission.toLocaleString()} F`}
          color={C.success} icon="📈" />
        <Stat label="Transactions"    value={payments.length}
          color={C.doctor}  icon="💳" />
      </div>

      {loading ? <Loading /> : (
        <Card style={{ padding: 0, overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: C.bg }}>
                {['Patient', 'Montant', 'Opérateur', 'Statut', 'Date'].map(h => (
                  <th key={h} style={{ padding: '12px 16px', textAlign: 'left',
                    fontSize: 12, fontWeight: 600, color: C.muted }}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {payments.map((p, i) => {
                const color = p.status === 'SUCCESS' ? C.success
                  : p.status === 'FAILED' ? C.error : C.warning
                return (
                  <tr key={p.id} style={{
                    borderTop: `1px solid ${C.border}`,
                    background: i % 2 === 0 ? 'white' : '#FAFAFA',
                  }}>
                    <td style={{ padding: '12px 16px', fontSize: 13 }}>
                      {p.patient?.user?.firstName} {p.patient?.user?.lastName}
                    </td>
                    <td style={{ padding: '12px 16px', fontWeight: 700, fontSize: 14 }}>
                      {p.amount?.toLocaleString()} F
                    </td>
                    <td style={{ padding: '12px 16px', fontSize: 13 }}>
                      {p.provider === 'ORANGE_MONEY' ? '🟠 Orange Money' : '🟡 MTN MoMo'}
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <span style={{ background: color + '20', color,
                        padding: '3px 10px', borderRadius: 20,
                        fontSize: 11, fontWeight: 700 }}>
                        {p.status}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px', fontSize: 12, color: C.muted }}>
                      {p.createdAt ? new Date(p.createdAt).toLocaleDateString('fr-FR') : '—'}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </Card>
      )}
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
// LOADING
// ─────────────────────────────────────────────────────────────

function Loading() {
  return (
    <div style={{ textAlign: 'center', padding: 60, color: C.muted }}>
      <div style={{ fontSize: 32, marginBottom: 8 }}>⏳</div>
      Chargement...
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
// APP PRINCIPALE
// ─────────────────────────────────────────────────────────────

export default function App() {
  const [user, setUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem('fd_admin_user')) }
    catch { return null }
  })
  const [page, setPage] = useState('dashboard')

  function handleLogout() {
    localStorage.removeItem('fd_admin_token')
    localStorage.removeItem('fd_admin_user')
    setUser(null)
  }

  if (!user) return <Login onLogin={setUser} />

  const PAGES = {
    dashboard:     <Dashboard />,
    doctors:       <DoctorsList />,
    patients:      <PatientsList />,
    consultations: <ConsultationsList />,
    payments:      <PaymentsList />,
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: C.bg }}>
      <Sidebar active={page} onNav={setPage} user={user} onLogout={handleLogout} />
      <main style={{ marginLeft: 240, flex: 1, padding: 32 }}>
        {PAGES[page] || <Dashboard />}
      </main>
    </div>
  )
}
