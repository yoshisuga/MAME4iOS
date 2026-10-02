export function StatsBar({ total, best }: { total: number; best: number }) {
  const items = [
    { label: 'Top score', value: best.toLocaleString('en-US'), tone: 'text-gold' },
    { label: 'Scores logged', value: total.toLocaleString('en-US'), tone: 'text-accent' },
    { label: 'Romset', value: 'robotron', tone: 'text-primary' },
  ]
  return (
    <dl className="flex flex-col gap-3 sm:flex-row">
      {items.map((item) => (
        <div key={item.label} className="flex-1 rounded-md border border-border bg-surface p-4">
          <dt className="text-xs uppercase tracking-widest text-muted">{item.label}</dt>
          <dd className={`mt-2 font-display text-lg ${item.tone}`}>{item.value}</dd>
        </div>
      ))}
    </dl>
  )
}
