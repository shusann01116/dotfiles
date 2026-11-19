import type { On } from 'claude-code'
import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'session-board',
  component: 'Pane',
  requestId: 'session-board',
  surface: 'terminal',
  props: {
    title: 'Session',
    isFocused: false,
    bodyColumns: 40,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 30 },
    view: {},
  },
} as const

const USAGE = { input_tokens: 0, output_tokens: 0, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 }
const answered = (text: string) => ({ value: { isAnswered: true as const, text, usage: USAGE } })
const ABORTED = '(aborted)'
const PENDING = '(pending)'
const TURN = { answer: 'done', durationMs: 1, isAborted: false, turnId: 't', reason: 'answer' } as const
const NO_PR = { exitCode: 1, stdout: '', stderr: 'no pull requests found', isStdoutTruncated: false, isStderrTruncated: false }
const out = (stdout: string) => ({ value: { ...NO_PR, exitCode: 0, stdout, stderr: '' } })

type Run = { argv: readonly string[] }
type Ran = { value: typeof NO_PR }
const engine = (
  on: On,
  replies: string[],
  gh: (_: unknown, e: Run) => Ran = () => ({ value: NO_PR }),
  store = new Map<string, unknown>(),
) => {
  on('session.info', () => ({ value: { transcriptPath: '/t/one.jsonl' } }))
  on('store.get', (_, e) => ({ value: store.get(e.key) }))
  on('store.set', (_, e) => {
    store.set(e.key, e.value)

    return { value: undefined }
  })
  on('store.keys', () => ({ value: [...store.keys()] }))
  on('store.delete', (_, e) => {
    store.delete(e.key)

    return { value: undefined }
  })
  on('turn.complete', () => ({ text: 'done' }))
  on('clock.now', () => ({ value: 0 }))
  on('clock.after', () => ({ value: undefined }))
  on('process.run', gh)
  on('model.fork', () => {
    const text = replies.shift()

    if (text === PENDING) return new Promise<never>(() => {})
    if (text === ABORTED) return { value: { isAnswered: false as const, reason: 'aborted' as const, usage: USAGE } }

    return text === undefined
      ? { value: { isAnswered: false as const, reason: 'nothing-to-fork' as const } }
      : answered(text)
  })
}
// turn.complete のフックは更新を待たずに返るので、テスト側で落ち着くまで待つ。
declare const setTimeout: (fn: () => void, ms: number) => unknown
const settle = () => new Promise<void>(resolve => setTimeout(resolve, 20))
const texts = async (ui: { findAll: (q: { type: string }) => Promise<{ text?: string }[]> }) =>
  (await ui.findAll({ type: 'Text' })).map(t => t.text ?? '')

test('fork が JSON を返すと 3 欄が出る', async ($, on) => {
  engine(on, ['前置き {"summary":"S","asks":["A1"],"decisions":["D1"]} 後置き'])
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  const all = (await texts(ui)).join('\n')
  expect(all).toContain('S')
  expect(all).toContain('A1')
  expect(all).toContain('D1')
  expect(all).toContain('PR なし')
  await ui.unmount()
})

test('壊れた返答では前回の内容が残る', async ($, on) => {
  engine(on, ['{"summary":"S","asks":["A1"],"decisions":[]}', 'すみません'])
  await $.turn.complete(TURN)
  await settle()
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  const all = (await texts(ui)).join('\n')
  expect(all).toContain('A1')
  expect(all).toMatch(/更新失敗/)
  await ui.unmount()
})

test('nothing-to-fork（resume 直後など）では前回の内容を残し、エラーにしない', async ($, on) => {
  engine(on, ['{"summary":"S","asks":["A1"],"decisions":[]}'])
  await $.turn.complete(TURN)
  await settle()
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  const all = (await texts(ui)).join('\n')
  expect(all).toContain('A1')
  expect(all).not.toMatch(/更新失敗/)
  expect(all).toMatch(/いまは要約できません/)
  await ui.unmount()
})

test('6 件以上と非文字列は切る', async ($, on) => {
  engine(on, ['{"summary":"S","asks":["a1",2,"a2","a3","a4","a5","a6","a7"],"decisions":[]}'])
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  const all = (await texts(ui)).join('\n')
  expect(all).toContain('a5')
  expect(all).not.toMatch(/a6|a7/)
  expect(all).toContain('あなたの判断待ち (5)')
  await ui.unmount()
})

test('PR があると番号と状態が出る', async ($, on) => {
  engine(on, [], (_, e) =>
    e.argv.includes('graphql')
      ? out('2\n')
      : out(
          JSON.stringify({
            number: 3470,
            url: 'https://github.com/o/r/pull/3470',
            isDraft: true,
            state: 'OPEN',
            reviewDecision: '',
            mergeable: 'MERGEABLE',
            statusCheckRollup: [{ conclusion: 'SUCCESS', status: 'COMPLETED' }],
          }),
        ),
  )
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  const all = [(await ui.find({ type: 'Link' }))?.text ?? '', ...(await texts(ui))].join('\n')
  expect(all).toMatch(/#3470/)
  expect(all).toMatch(/Draft/)
  expect(all).toMatch(/指摘 2/)
  expect(all).toMatch(/CI ✓/)
  await ui.unmount()
})

test('gh が PR なし以外の理由で失敗したら前回の PR を残す', async ($, on) => {
  let isDown = false
  engine(on, [], (_, e) =>
    isDown
      ? { value: { ...NO_PR, stderr: 'HTTP 401: Bad credentials' } }
      : e.argv.includes('graphql')
        ? out('0\n')
        : out(JSON.stringify({ number: 3470, url: 'https://github.com/o/r/pull/3470', isDraft: false, state: 'OPEN', statusCheckRollup: [] })),
  )
  await $.turn.complete(TURN)
  await settle()
  isDown = true
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  const all = (await texts(ui)).join('\n')
  expect((await ui.find({ type: 'Link' }))?.text).toMatch(/#3470/)
  expect(all).toMatch(/更新失敗/)
  await ui.unmount()
})

test('判断待ちの選択肢を押すと、その答えが送信される', async ($, on) => {
  const sent: string[] = []
  engine(on, ['{"summary":"S","asks":[{"text":"方式を選ぶ","options":["A","B"]},"選択肢なし"],"decisions":[]}'])
  on('prompt.submit', (_, e) => {
    sent.push(e.text)

    return { text: e.text }
  })
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  expect((await texts(ui)).join('\n')).toContain('選択肢なし')
  expect((await ui.findAll({ type: 'Button' })).map(b => b.text)).toEqual(['更新', 'A', 'B'])
  await ui.press({ key: 'ask-0-1' })
  expect(sent).toEqual(['「方式を選ぶ」への回答: B'])
  await ui.unmount()
})

test('Claude が決めたことの「議論」を押すと、議論の依頼が送信される', async ($, on) => {
  const sent: string[] = []
  engine(on, ['{"summary":"S","asks":[],"decisions":["effort を low に固定"]}'])
  on('prompt.submit', (_, e) => {
    sent.push(e.text)

    return { text: e.text }
  })
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  await ui.press({ key: 'discuss-0' })
  expect(sent.length).toBe(1)
  expect(sent[0]).toContain('effort を low に固定')
  expect(sent[0]).toContain('議論')
  await ui.unmount()
})

test('fork が中断で返ったら、前回の内容を残して中断と表示する', async ($, on) => {
  engine(on, ['{"summary":"S","asks":[],"decisions":[]}', ABORTED])
  await $.turn.complete(TURN)
  await settle()
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  const all = (await texts(ui)).join('\n')
  expect(all).toContain('S')
  expect(all).toMatch(/更新中断/)
  await ui.unmount()
})

test('セッション開始時と mod の再読み込み時にも要約する', async ($, on) => {
  engine(on, ['{"summary":"S","asks":[],"decisions":[]}'])
  on('command.register', () => ({ value: { command: 'board' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('clock.every', () => ({ value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await settle()

  const ui = await $.ui.mount(PANE)
  expect((await texts(ui)).join('\n')).toContain('S')
  await ui.unmount()
})

const BAND = {
  plugin: 'session-board',
  component: 'AbovePrompt',
  surface: 'terminal',
  props: {
    hasSurvey: false,
    isCollapsed: false,
    isWorking: false,
    maxRows: 6,
    bodyColumns: 80,
    scroll: { offset: 0, bodyRows: 6 },
    view: {},
  },
} as const

test('直前の返答の判断はプロンプトの上にボタンで出て、押すと送信して消える', async ($, on) => {
  const sent: string[] = []
  engine(on, [
    '{"summary":"S","asks":[{"text":"古い件","options":["はい"],"current":false},{"text":"方式を選ぶ","options":["A","B"],"current":true}],"decisions":[]}',
  ])
  on('prompt.submit', (_, e) => {
    sent.push(e.text)

    return { text: e.text }
  })
  await $.turn.complete(TURN)
  await settle()

  const band = await $.ui.mount(BAND)
  expect((await texts(band)).join('\n')).toContain('方式を選ぶ')
  expect((await band.findAll({ type: 'Button' })).map(b => b.text)).toEqual(['A', 'B'])
  await band.press({ key: 'now-1-0' })
  expect(sent).toEqual(['「方式を選ぶ」への回答: A'])
  expect(await band.findAll({ type: 'Button' })).toEqual([])
  await band.unmount()
})

test('要約の更新中は「更新中」と出て、終わると消える', async ($, on) => {
  engine(on, ['{"summary":"S","asks":[],"decisions":[]}', PENDING])
  await $.turn.complete(TURN)
  await settle()

  const done = await $.ui.mount(PANE)
  expect((await texts(done)).join('\n')).not.toMatch(/更新中/)
  await done.unmount()

  await $.turn.complete(TURN)
  await settle()

  const busy = await $.ui.mount(PANE)
  expect((await texts(busy)).join('\n')).toMatch(/更新中/)
  await busy.unmount()
})

test('要約はセッションごとに保存される', async ($, on) => {
  const store = new Map<string, unknown>()
  engine(on, ['{"summary":"S","asks":["A1"],"decisions":["D1"]}'], undefined, store)
  await $.turn.complete(TURN)
  await settle()

  expect([...store.keys()]).toEqual(['board:/t/one.jsonl'])
  expect(store.get('board:/t/one.jsonl')).toMatchObject({ summary: 'S', decisions: ['D1'] })
})

test('resume 直後は、保存してあった要約を表示する', async ($, on) => {
  const saved = { summary: 'S', asks: [{ text: 'A1', options: ['はい'], isCurrent: true }], decisions: ['D1'], updatedAt: '09:00' }
  engine(on, [], undefined, new Map<string, unknown>([['board:/t/one.jsonl', saved]]))
  on('command.register', () => ({ value: { command: 'board' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('clock.every', () => ({ value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await settle()

  const ui = await $.ui.mount(PANE)
  const all = (await texts(ui)).join('\n')
  expect(all).toContain('S')
  expect(all).toContain('A1')
  expect(all).toContain('D1')
  expect(all).toContain('要約 09:00')
  expect(all).not.toMatch(/いまは要約できません/)
  await ui.unmount()
})

test('日本語と英単語が混ざった文を、幅いっぱいで折り返す', async ($, on) => {
  const decision =
    '最後の要約を mod の永続領域に、会話ファイルのパスを鍵にして保存することにした（最大 200 セッション分、古い順に削除。PR 欄は保存しない）。'
  engine(on, [JSON.stringify({ summary: 'S', asks: [], decisions: [decision] })])
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  const all = await texts(ui)
  const from = all.findIndex(t => t.startsWith('最後の要約'))
  const lines = all.slice(from, all.findIndex((t, i) => i > from && t.endsWith('しない）。')) + 1)
  const width = (t: string) => [...t].reduce((n, c) => n + ((c.codePointAt(0) ?? 0) >= 0x1100 ? 2 : 1), 0)

  // PANE の bodyColumns は 40、印の分 2 桁を引いた 38 桁が本文の幅。
  expect(lines.join('').replace(/ /g, '')).toBe(decision.replace(/ /g, ''))
  expect(lines.every(l => width(l) <= 38)).toBe(true)
  expect(lines.slice(0, -1).every(l => width(l) >= 32)).toBe(true)
  expect(lines.some(l => /^[、。）」]/.test(l))).toBe(false)
  expect(lines.some(l => /\bmo$|^d\b|\bP$|^R\b|20$/.test(l))).toBe(false)
  await ui.unmount()
})

test('文中の URL は、幅に収まらなくても全体を指すリンクとして出す', async ($, on) => {
  const long = 'https://github.com/SSK-TBD/canary-cloud-owned-hp-platform/pull/3470#discussion_r123456789'
  const short = 'https://example.com/a'
  engine(on, [JSON.stringify({ summary: 'S', asks: [], decisions: [`詳細は ${long} を見る。`, `手順は ${short}、を参照。`] })])
  await $.turn.complete(TURN)
  await settle()

  const ui = await $.ui.mount(PANE)
  const links = await ui.findAll({ type: 'Link' })
  const width = (t: string) => [...t].reduce((n, c) => n + ((c.codePointAt(0) ?? 0) >= 0x1100 ? 2 : 1), 0)

  expect(links.map(l => l.props.href)).toEqual([long, short])
  // テストキットはリンクの text を「href + 表示文字列」で返す。
  const shown = links.map(l => (l.text ?? '').slice(String(l.props.href).length))
  expect(shown.every(t => width(t) <= 38)).toBe(true)
  expect(shown[0]).toMatch(/^https:\/\/github\.com\/.*…$/)
  expect(shown[1]).toBe(short)
  await ui.unmount()
})
