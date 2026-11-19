export type Pr = {
  number: number
  url: string
  status: 'draft' | 'open' | 'merged' | 'closed'
  ci: 'pass' | 'fail' | 'pending' | 'none'
  review: string
  unresolved: number
  hasConflict: boolean
}

export type Ask = { text: string; options: string[]; isCurrent: boolean }

export type Board = {
  summary: string
  asks: Ask[]
  decisions: string[]
  prs: string[]
  error: string | null
  updatedAt: string
}

export type PrState = { prs: Pr[]; error: string | null }

declare module 'claude-code' {
  interface PluginState {
    'session-board': { board: Shaped<Board>; pr: Shaped<PrState>; updating: Shaped<number> }
  }
}
