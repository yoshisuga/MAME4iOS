import type { PublicScore } from '@/lib/scores'

const rankTone = ['text-gold', 'text-accent', 'text-primary']

export function Leaderboard({ scores }: { scores: PublicScore[] }) {
  return (
    <section aria-labelledby="leaderboard-title" className="rounded-md border border-border bg-surface">
      <div className="flex items-center justify-between border-b border-border px-4 py-3">
        <h2 id="leaderboard-title" className="font-display text-xs text-foreground">
          All-time top 10
        </h2>
        <span className="text-xs text-muted">Global</span>
      </div>
      {scores.length === 0 ? (
        <div className="flex flex-col items-center gap-3 px-4 py-16 text-center">
          <p className="font-display text-sm text-primary">Player 1 ready</p>
          <p className="max-w-sm text-sm text-muted">
            No scores yet. Finish a game of Robotron in MAME4iOS to claim the first slot.
          </p>
        </div>
      ) : (
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-xs uppercase tracking-widest text-muted">
              <th scope="col" className="px-4 py-3 font-normal">Rank</th>
              <th scope="col" className="px-4 py-3 font-normal">Name</th>
              <th scope="col" className="px-4 py-3 text-right font-normal">Score</th>
              <th scope="col" className="hidden px-4 py-3 text-right font-normal sm:table-cell">Region</th>
            </tr>
          </thead>
          <tbody>
            {scores.map((s, i) => (
              <tr key={s.id} className="border-t border-border">
                <td className={`px-4 py-3 font-display text-xs ${rankTone[i] ?? 'text-muted'}`}>
                  {String(s.rank).padStart(2, '0')}
                </td>
                <td className="px-4 py-3 font-display text-xs tracking-widest text-foreground">{s.initials}</td>
                <td className={`px-4 py-3 text-right font-bold tabular-nums ${i === 0 ? 'text-gold' : 'text-foreground'}`}>
                  {s.score.toLocaleString('en-US')}
                </td>
                <td className="hidden px-4 py-3 text-right text-muted sm:table-cell">
                  {s.region} · {s.countryCode}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  )
}
