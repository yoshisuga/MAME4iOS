import { connection } from 'next/server'
import { Leaderboard } from '@/components/leaderboard'
import { RecentScores } from '@/components/recent-scores'
import { SiteHeader } from '@/components/site-header'
import { StatsBar } from '@/components/stats-bar'
import { getRecentScores, getTopScores, getTotalScores } from '@/lib/scores'

export default async function Page() {
  await connection()
  const [top, recent, total] = await Promise.all([getTopScores(), getRecentScores(), getTotalScores()])

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-10 px-4 py-10 md:py-14">
      <SiteHeader />
      <main className="flex flex-col gap-10">
        <StatsBar total={total} best={top[0]?.score ?? 0} />
        <div className="flex flex-col gap-8 lg:flex-row">
          <div className="flex-1">
            <Leaderboard scores={top} />
          </div>
          <aside className="lg:w-80">
            <RecentScores scores={recent} />
          </aside>
        </div>
      </main>
      <footer className="border-t border-border pt-6 text-xs text-muted">
        {'Part of the MAME4iOS project. Robotron: 2084 is a trademark of its respective owners.'}
      </footer>
    </div>
  )
}
