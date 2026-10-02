export function SiteHeader() {
  const facts = [
    ['MAME ROM version', '0.139u1'],
    ['MAME4iOS original author', 'David Valdeita (Seleuco)'],
    ['Original arcade game', '1982 · Eugene Jarvis (DRJ) and Larry DeMar (LED)'],
    ['Robotron-specific modifications', 'Scott Crosby · dual joysticks and other game-specific controls'],
  ]

  return (
    <header className="flex flex-col gap-4">
      <p className="text-xs uppercase tracking-[0.3em] text-accent">ALL HAIL VID KIDZ</p>
      <h1 className="font-display text-2xl leading-relaxed text-balance text-primary md:text-4xl">
        Robotron: 2084
        <span className="block text-foreground">Cloud High Score Board</span>
      </h1>
      <p className="max-w-2xl text-sm leading-relaxed text-muted text-pretty">
        IN 2084, the ROBOTRONS CONCLUDE: THE HUMAN RACE IS INEFFICIENT, AND THEREFORE MUST BE DESTROYED. YOU ARE THE LAST HOPE OF MANKIND.
      </p>
      <table className="w-full max-w-2xl border-collapse text-left text-xs">
        <tbody>
          {facts.map(([label, value]) => (
            <tr key={label} className="border-t border-border last:border-b">
              <th scope="row" className="w-1/3 py-2 pr-4 font-normal text-accent">{label}</th>
              <td className="py-2 text-muted">{value}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </header>
  )
}
