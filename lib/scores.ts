const VIEW = 'all_time_heroes'
const COLUMNS = 'id,rank,player_name,score,achieved_at,platform,country_code,region'

type Row = {
  id: string
  rank: number
  player_name: string
  score: number
  achieved_at: string
  platform: string
  country_code: string
  region: string
}

export type PublicScore = {
  id: string
  rank: number
  initials: string
  score: number
  achievedAt: Date
  platform: string
  countryCode: string
  region: string
}

function config() {
  const url = process.env.SUPABASE_URL
  const key = process.env.SUPABASE_ANON_KEY
  if (!url || !key) throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY must be set')
  return { url, key }
}

async function query(params: string, init?: { count?: boolean }) {
  const { url, key } = config()
  const response = await fetch(`${url}/rest/v1/${VIEW}?${params}`, {
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      ...(init?.count ? { Prefer: 'count=exact' } : {}),
    },
    next: { revalidate: 30 },
  })
  if (!response.ok) throw new Error(`Supabase ${VIEW} request failed: ${response.status}`)
  return response
}

function toPublic(row: Row): PublicScore {
  return {
    id: row.id,
    rank: row.rank,
    initials: row.player_name,
    score: Number(row.score),
    achievedAt: new Date(row.achieved_at),
    platform: row.platform,
    countryCode: row.country_code,
    region: row.region,
  }
}

export async function getTopScores(limit = 10) {
  const response = await query(`select=${COLUMNS}&order=rank.asc&limit=${limit}`)
  return ((await response.json()) as Row[]).map(toPublic)
}

export async function getRecentScores(limit = 8) {
  const response = await query(`select=${COLUMNS}&order=achieved_at.desc&limit=${limit}`)
  return ((await response.json()) as Row[]).map(toPublic)
}

export async function getTotalScores() {
  const response = await query('select=id&limit=1', { count: true })
  // PostgREST returns the exact total as "0-0/123" in Content-Range.
  return Number(response.headers.get('content-range')?.split('/')[1]) || 0
}
