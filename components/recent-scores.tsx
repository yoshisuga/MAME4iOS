import type { PublicScore } from '@/lib/scores'

const timeFormat = new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })

export function RecentScores({ scores }: { scores: PublicScore[] }) {
  return (
    <section aria-labelledby="recent-title" className="rounded-md border border-border bg-surface">
      <h2 id="recent-title" className="border-b border-border px-4 py-3 font-display text-xs text-foreground">
        Latest runs
      </h2>
      {scores.length === 0 ? (
        <p className="px-4 py-6 text-sm text-muted">Waiting for the first submission.</p>
      ) : (
        <ul className="flex flex-col">
          {scores.map((s) => (
            <li key={s.id} className="flex items-center justify-between gap-3 border-t border-border px-4 py-3 first:border-t-0">
              <div className="flex flex-col gap-1">
                <span className="font-display text-xs tracking-widest text-accent">{s.initials}</span>
                <span className="text-xs text-muted">
                  <time dateTime={s.achievedAt.toISOString()}>{timeFormat.format(s.achievedAt)}</time>
                  {` · ${s.platform}`}
                </span>
              </div>
              <span className="tabular-nums text-sm font-bold text-foreground">{s.score.toLocaleString('en-US')}</span>
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}
