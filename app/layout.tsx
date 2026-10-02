import type { Metadata, Viewport } from 'next'
import { JetBrains_Mono, Press_Start_2P } from 'next/font/google'
import './globals.css'

const pressStart = Press_Start_2P({ weight: '400', subsets: ['latin'], variable: '--font-press-start' })
const jetbrains = JetBrains_Mono({ subsets: ['latin'], variable: '--font-jetbrains' })

export const metadata: Metadata = {
  title: 'Robotron Cloud High Scores | MAME4iOS',
  description: 'Global Robotron: 2084 leaderboard for MAME4iOS players, with a simple JSON API for submitting scores.',
}

export const viewport: Viewport = {
  themeColor: '#07070d',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${pressStart.variable} ${jetbrains.variable}`}>
      <body className="min-h-dvh bg-background text-foreground antialiased">{children}</body>
    </html>
  )
}
