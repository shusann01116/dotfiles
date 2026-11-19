import { atom, read, update } from 'claude-code'
import type { EngineInterface, ModelForkResult, Register } from 'claude-code'

import type { Ask, Board, Pr, PrState } from '../types'

const PANE = 'session-board'
const TITLE = 'Session'
const MAX = 5
const MAX_OPTIONS = 4
// ponytail: 保存はセッションごとに 1 件、古い順に捨てて 200 件まで。足りなくなったら日付で捨てる。
const MAX_SAVED = 200
const EMPTY: Board = { summary: '', asks: [], decisions: [], prs: [], error: null, updatedAt: '' }

const board = atom({ plugin: 'session-board', key: 'board' } as const, EMPTY, { shape: 'board-5' })
// 要約と PR は別々に更新が走るので、互いの書き込みを踏まないよう atom を分ける。
const prState = atom({ plugin: 'session-board', key: 'pr' } as const, { prs: [], error: null } as PrState, {
  shape: 'pr-3',
})

// 走っている要約の数。0 より大きい間はペインに「更新中」と出す。
const updating = atom({ plugin: 'session-board', key: 'updating' } as const, 0, { shape: 'updating-1' })

const ASK = `ここまでの会話を読み、次の JSON だけを返してください。前後に文章を付けないこと。
{"summary": "いま何をしていて、どの段階か。2〜3 文", "asks": [{"text": "あなた（Claude）がユーザーに求めていて、まだ答えをもらっていない判断。1 件 1 文", "options": ["ユーザーが押すだけで答えになる短い回答候補"], "current": "あなたの直前の返答で求めた判断なら true、それより前から残っている判断なら false"}], "decisions": ["ユーザーに聞かずにあなたが決めたことのうち、ユーザーが決めたほうがよさそうなもの。1 件 1 文"], "prs": ["このセッションで作成・更新・レビュー対応・監視している PR の URL（https://github.com/owner/repo/pull/番号 の形。#番号 だけなら会話中のリポジトリで補う）"]}
asks と decisions と prs は最大 ${MAX} 件、重要な順。
options の決め方: あなたが会話で選択肢を示していればそれをそのまま使う。示していなくても、はい / いいえ、進めてよい / 止める、確認の結果（例: 出た / 出ない）のように短い答えで足りる判断なら、その候補を入れる。自由記述でしか答えられない判断だけ空配列にする。最大 ${MAX_OPTIONS} 件、各 12 文字以内。前回 options が空だった項目も、毎回この基準で見直すこと。
該当がなければ空配列。前回の内容と意味が同じ項目は文言を変えないこと。
前回: `

// 端末の折り返しは空白でしか切らないので、空白の少ない日本語に英単語が混ざると行の長さが大きくばらつく。
// 表示幅（全角 2 桁、半角 1 桁）で自前に折り返す。英数字の並びは切らず、句読点と閉じ括弧は行頭に置かない。
const NO_LINE_START = '、。，．）」』】！？・ー…'
const cellWidth = (text: string): number =>
  [...text].reduce((n, c) => n + ((c.codePointAt(0) ?? 0) >= 0x1100 ? 2 : 1), 0)

// 1 行は、地の文と URL の並び。URL は表示を切り詰めても href に全体を持たせ、クリックで開けるようにする。
type Part = { text: string; href?: string }

const wrapText = (text: string, columns: number): Part[][] => {
  // 行頭禁則の文字をぶら下げる 2 桁分を残して詰める。
  const limit = Math.max(8, columns) - 2
  const out: Part[][] = []
  let line: Part[] = []
  let used = 0
  const push = (part: Part) => {
    const last = line.at(-1)
    if (last && !last.href && !part.href) last.text += part.text
    else line.push(part)
    used += cellWidth(part.text)
  }
  const breakLine = () => {
    if (line.length > 0) out.push(line)
    line = []
    used = 0
  }
  for (const token of text.match(/https?:\/\/[\x21-\x7e]+|[\x21-\x7e]+|\s+|[^\x21-\x7e\s]/gu) ?? []) {
    if (/^\s+$/.test(token)) {
      if (used > 0 && used < limit) push({ text: ' ' })
      continue
    }
    // URL の末尾に付いた句読点や閉じ括弧は URL に含めない。
    const url = /^https?:\/\//.test(token) ? token.replace(/[.,;:!?)\]}'"]+$/, '') : undefined
    const rest = url === undefined ? '' : token.slice(url.length)
    const word = url ?? token
    if (used + cellWidth(word) > limit && !NO_LINE_START.includes(word)) breakLine()
    if (url !== undefined) {
      // 幅より長い URL は、表示だけ末尾を省略する。
      push({ text: cellWidth(url) > limit ? `${url.slice(0, limit - 1)}…` : url, href: url })
      if (rest) push({ text: rest })
      continue
    }
    // 幅より長い英数字の並びは、やむを得ず途中で切る。
    let left = word
    while (cellWidth(left) > limit) {
      push({ text: left.slice(0, limit) })
      breakLine()
      left = left.slice(limit)
    }
    push({ text: left })
  }
  breakLine()

  return out
}

const lines = (value: unknown): string[] =>
  Array.isArray(value) ? value.filter((v): v is string => typeof v === 'string').slice(0, MAX) : []

// 選択肢のない判断待ちは文字列だけで返ってくることがある。
const toAsks = (value: unknown): Ask[] =>
  (Array.isArray(value) ? value : [])
    .map((v): Ask | undefined => {
      if (typeof v === 'string') return { text: v, options: [], isCurrent: false }
      if (typeof v !== 'object' || v === null) return undefined
      const { text, options, current } = v as Record<string, unknown>

      return typeof text === 'string'
        ? { text, options: lines(options).slice(0, MAX_OPTIONS), isCurrent: current === true }
        : undefined
    })
    .filter((v): v is Ask => v !== undefined)
    .slice(0, MAX)

type Summary = Pick<Board, 'summary' | 'asks' | 'decisions' | 'prs'>

const PR_URL = /^https:\/\/github\.com\/[^/\s]+\/[^/\s]+\/pull\/\d+$/

const toSummary = (got: unknown): Summary | undefined => {
  if (typeof got !== 'object' || got === null) return undefined
  const { summary, asks, decisions, prs } = got as Record<string, unknown>
  if (typeof summary !== 'string') return undefined

  return { summary, asks: toAsks(asks), decisions: lines(decisions), prs: lines(prs).filter(u => PR_URL.test(u)) }
}

const parse = (text: string): Summary | undefined => {
  try {
    return toSummary(JSON.parse(text.slice(text.indexOf('{'), text.lastIndexOf('}') + 1)))
  } catch {
    return undefined
  }
}

// セッション内の状態は resume で消えるので、最後の要約を会話ファイルのパスを鍵にして保存しておく。
const savedKey = async ($: EngineInterface): Promise<string> => `board:${(await $.session.info()).transcriptPath}`

const save = async ($: EngineInterface, summary: Summary, updatedAt: string): Promise<void> => {
  // 保存した asks は isCurrent を current として読み戻す。
  const asks = summary.asks.map(a => ({ text: a.text, options: a.options, current: a.isCurrent }))
  await $.store.set(await savedKey($), { ...summary, asks, updatedAt })
  const keys = (await $.store.keys()).filter(k => k.startsWith('board:'))
  await Promise.all(keys.slice(0, Math.max(0, keys.length - MAX_SAVED)).map(k => $.store.delete(k)))
}

const restore = async ($: EngineInterface): Promise<void> => {
  if ((await read($, board)).summary) return
  const saved = await $.store.get(await savedKey($))
  const summary = toSummary(saved)
  if (!summary) return
  const updatedAt = String((saved as Record<string, unknown>).updatedAt ?? '')
  await update($, board, b => (b.summary ? b : { ...b, ...summary, updatedAt }))
}

const clock = async ($: EngineInterface): Promise<string> => {
  const now = new Date(await $.clock.now())
  const two = (n: number) => String(n).padStart(2, '0')

  return `${two(now.getHours())}:${two(now.getMinutes())}`
}
const failedAt = async ($: EngineInterface): Promise<string> => `更新失敗 ${await clock($)}`

// 更新中に次のターンが終わったら、後から始めた更新の結果だけを採用する。
let latest = 0
// resume したセッションでは、ボタンやタイマーの $ から呼んだ fork が「複製元なし」で返る。
// ターン終了フックの $ からなら通るので、直近のフックが作った呼び出しを使い回す。
let forkAtTurn: ((prompt: string) => Promise<ModelForkResult>) | undefined

const refreshBoard = async ($: EngineInterface, isQuiet = false): Promise<void> => {
  await update($, updating, n => n + 1)
  try {
    await summarize($, isQuiet)
  } finally {
    await update($, updating, n => Math.max(0, n - 1))
  }
}

const summarize = async ($: EngineInterface, isQuiet: boolean): Promise<void> => {
  const mine = ++latest
  const { summary, asks, decisions, prs } = await read($, board)
  const prompt = ASK + JSON.stringify({ summary, asks, decisions, prs })
  const reply = await (forkAtTurn ? forkAtTurn(prompt) : $.model.fork({ prompt, effort: 'low' }))
  if (mine !== latest) return

  if (!reply.isAnswered) {
    // nothing-to-fork は、複製できるリクエストがまだない（resume 直後など）。どの場合も前回の内容は残す。
    // 読み込み時の自動更新では毎回起きるので、そのときは何も出さない。
    if (reply.reason === 'nothing-to-fork' && isQuiet) return
    const error =
      reply.reason === 'nothing-to-fork'
        ? `いまは要約できません ${await clock($)}`
        : reply.reason === 'aborted'
          ? `更新中断 ${await clock($)}`
          : await failedAt($)
    const next = { error }
    await update($, board, b => ({ ...b, ...next }))

    return
  }

  const parsed = parse(reply.text)
  if (!parsed) {
    const error = await failedAt($)
    await update($, board, b => ({ ...b, error }))

    return
  }
  const updatedAt = await clock($)
  await update($, board, b => ({ ...b, ...parsed, error: null, updatedAt }))
  await save($, parsed, updatedAt)
  // PR の一覧は要約から取るので、変わったらすぐ取り直す。
  if (parsed.prs.join() !== prs.join()) void refreshPr($)
}

const THREADS = `query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100){nodes{isResolved}}}}}`

const ci = (rollup: unknown): Pr['ci'] => {
  const checks = Array.isArray(rollup) ? (rollup as Record<string, unknown>[]) : []
  if (checks.length === 0) return 'none'
  // CheckRun は conclusion、StatusContext は state に結果を持つ。
  const results = checks.map(c => String(c.conclusion || c.state || ''))
  if (results.some(r => ['FAILURE', 'ERROR', 'TIMED_OUT', 'CANCELLED', 'ACTION_REQUIRED'].includes(r))) return 'fail'
  if (results.some(r => r === '' || r === 'PENDING' || r === 'EXPECTED')) return 'pending'

  return 'pass'
}

// target を省くと、カレントディレクトリのブランチの PR を読む。
const fetchPr = async ($: EngineInterface, target?: string): Promise<Pr | null> => {
  const view = await $.process.run([
    'gh', 'pr', 'view', ...(target ? [target] : []), '--json', 'number,url,isDraft,state,reviewDecision,mergeable,statusCheckRollup',
  ])
  // PR のないブランチは非 0 終了。失敗ではなく「PR なし」。認証切れなど他の理由は失敗として扱う。
  if (view.exitCode !== 0) {
    if (view.stderr.includes('no pull requests found')) return null
    throw new Error(view.stderr)
  }
  const pr = JSON.parse(view.stdout) as Record<string, unknown>
  const number = Number(pr.number)
  const url = String(pr.url ?? '')
  // 別リポジトリの PR もあるので、owner と repo は PR の URL から取る。
  const [, owner = '', repo = ''] = new URL(url).pathname.split('/')
  const threads = await $.process.run([
    'gh', 'api', 'graphql', '-f', `query=${THREADS}`, '-f', `owner=${owner}`, '-f', `repo=${repo}`, '-F', `number=${number}`,
    '--jq', '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved | not)] | length',
  ])

  return {
    number,
    url,
    status: pr.state === 'MERGED' ? 'merged' : pr.state === 'CLOSED' ? 'closed' : pr.isDraft ? 'draft' : 'open',
    ci: ci(pr.statusCheckRollup),
    review: String(pr.reviewDecision ?? ''),
    unresolved: threads.exitCode === 0 ? Number(threads.stdout.trim()) || 0 : 0,
    hasConflict: pr.mergeable === 'CONFLICTING',
  }
}

const refreshPr = async ($: EngineInterface): Promise<void> => {
  try {
    const { prs: mentioned } = await read($, board)
    const got = await Promise.all([undefined, ...mentioned].map(t => fetchPr($, t)))
    const prs = got
      .filter((p): p is Pr => p !== null)
      .filter((p, i, all) => all.findIndex(q => q.url === p.url) === i)
      .slice(0, MAX)
    await update($, prState, () => ({ prs, error: null }))
  } catch {
    // gh が起動できない・出力が壊れている。前回の PR 表示を残す。
    const error = await failedAt($)
    await update($, prState, s => ({ ...s, error }))
  }
}

// 選択肢を押したら答えを送り、同じボタンを二度押せないよう帯から外す。次の更新で項目ごと消える。
const answer = ($: EngineInterface, ask: Ask, option: string): void => {
  void $.prompt.submit({ text: `「${ask.text}」への回答: ${option}`, asUser: true })
  void update($, board, b => ({
    ...b,
    asks: b.asks.map(a => (a.text === ask.text ? { ...a, isCurrent: false } : a)),
  }))
}

const refresh = ($: EngineInterface): Promise<unknown> => Promise.all([refreshBoard($), refreshPr($)])

const STATUS = { draft: 'Draft', open: 'Ready', merged: 'Merged', closed: 'Closed' } as const
const CI = { pass: 'CI ✓', fail: 'CI ✗', pending: 'CI …', none: 'CI なし' } as const
const REVIEW: Record<string, string> = {
  APPROVED: '承認済み',
  CHANGES_REQUESTED: '修正依頼',
  REVIEW_REQUIRED: 'レビュー待ち',
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'board', description: 'セッションの状態ペインを開く' })
    void $.ui.open({ id: PANE, title: TITLE })
    // 再読み込みで途中の要約が捨てられると、数えた分が戻らず「更新中」が出たままになる。
    await update($, updating, () => 0)
    await restore($)
    // 再読み込みでもここを通る。直前のターン終了は古いモジュールが受けていて、そのタイマーは再読み込みで止まる。
    $.clock.after(500, () => void Promise.all([refreshBoard($, true), refreshPr($)]))
    $.clock.every(120_000, () => void refreshPr($))

    return next(e)
  })

  on('command.run', { command: 'board' }, async $ => {
    const opened = await $.ui.open({ id: PANE, title: TITLE })

    return { text: opened.isPlaced ? 'Session ペインを開きました。' : `開けません: ${opened.reason}` }
  })

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    // サブエージェントのターンでは更新しない。主セッションの会話だけを要約する。
    if (e.agentId === undefined) {
      forkAtTurn = prompt => $.model.fork({ prompt, effort: 'low' })
      void refresh($)
    }

    return done
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const { asks } = await read($, board)
    // 行の key はペインと揃えず、asks 全体での位置で振る。
    const now = asks.map((ask, i) => ({ ask, i })).filter(({ ask }) => ask.isCurrent && ask.options.length > 0)
    if (e.props.hasSurvey || now.length === 0) return next(e)
    const { Box, Text, Button } = $.ui.resolve(e)

    return (
      <Box flexDirection="column">
        {now.map(({ ask, i }) => (
          <Box key={`now-${i}`} flexDirection="row" gap={1}>
            <Text dimColor>{ask.text}</Text>
            {ask.options.map((option, j) => (
              <Button key={`now-${i}-${j}`} onPress={() => answer($, ask, option)}>
                {option}
              </Button>
            ))}
          </Box>
        ))}
      </Box>
    )
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button, Link } = $.ui.resolve(e)
    const { summary, asks, decisions, error, updatedAt } = await read($, board)
    const { prs, error: prError } = await read($, prState)
    const isUpdating = (await read($, updating)) > 0
    const discuss = (decision: string) =>
      void $.prompt.submit({
        text: `「${decision}」について議論したい。そう決めた理由と、他に取りうる選択肢、それぞれの得失を説明して。実装は私が答えるまで進めないで。`,
        asUser: true,
      })
    const rule = (key: string) => (
      <Box key={key}>
        <Text dimColor wrap="truncate">
          {'─'.repeat(Math.max(8, e.props.bodyColumns))}
        </Text>
      </Box>
    )
    const wrapped = (text: string, columns: number) =>
      wrapText(text, columns).map(parts =>
        parts.length === 1 && !parts[0]?.href ? (
          <Text wrap="truncate">{parts[0]?.text.trimEnd()}</Text>
        ) : (
          <Box flexDirection="row">
            {parts.map(part =>
              part.href ? <Link href={part.href}>{part.text}</Link> : <Text wrap="truncate">{part.text}</Text>,
            )}
          </Box>
        ),
      )
    // 印の 2 桁を引いた幅が、項目の本文に使える。
    const itemColumns = e.props.bodyColumns - 2
    // 件数が 0 の見出しは沈め、あるときだけ色で目立たせる。
    const head = (title: string, count: number, color: 'yellow' | 'cyan') => (
      <Text bold={count > 0} dimColor={count === 0} color={count > 0 ? color : undefined}>
        {`${title} (${count})`}
      </Text>
    )
    const CI_COLOR = { pass: 'green', fail: 'red', pending: 'yellow', none: undefined } as const

    return (
      <Box flexDirection="column">
        <Box key="status" flexDirection="row" gap={1}>
          <Button key="refresh" dimColor onPress={() => void refresh($)}>
            更新
          </Button>
          {isUpdating ? <Text color="yellow">更新中…</Text> : updatedAt && <Text dimColor>{`要約 ${updatedAt}`}</Text>}
        </Box>
        {error && <Text color="red">{`要約: ${error}`}</Text>}
        {prError && <Text color="red">{`PR: ${prError}`}</Text>}
        {prs.length === 0 && <Text dimColor>PR なし</Text>}
        {prs.map(pr => (
          <Box key={`pr-${pr.url}`} flexDirection="row" flexWrap="wrap" columnGap={1}>
            <Link href={pr.url}>{`#${pr.number} ${STATUS[pr.status]}`}</Link>
            <Text color={CI_COLOR[pr.ci]}>{CI[pr.ci]}</Text>
            {REVIEW[pr.review] && <Text>{REVIEW[pr.review]}</Text>}
            {pr.unresolved > 0 && <Text color="yellow">{`指摘 ${pr.unresolved}`}</Text>}
            {pr.hasConflict && <Text color="red">競合あり</Text>}
          </Box>
        ))}
        {rule('rule-summary')}
        <Box key="summary" flexDirection="column">
          <Text bold>概要</Text>
          {summary ? wrapped(summary, e.props.bodyColumns) : <Text dimColor>まだ要約はありません</Text>}
        </Box>
        {rule('rule-decisions')}
        <Box key="decisions" flexDirection="column">
          {head('Claude が決めたこと', decisions.length, 'cyan')}
          {decisions.map((decision, i) => (
            <Box key={`decision-${i}`} flexDirection="row" marginTop={i === 0 ? 0 : 1}>
              <Box key={`decision-${i}-mark`} width={2} flexShrink={0}>
                <Text color="cyan">◆</Text>
              </Box>
              <Box key={`decision-${i}-body`} flexDirection="column" flexGrow={1} flexShrink={1}>
                {wrapped(decision, itemColumns)}
                <Box key={`decision-${i}-act`} flexDirection="row">
                  <Button key={`discuss-${i}`} dimColor onPress={() => discuss(decision)}>
                    議論する
                  </Button>
                </Box>
              </Box>
            </Box>
          ))}
        </Box>
        {rule('rule-asks')}
        <Box key="asks" flexDirection="column">
          {head('あなたの判断待ち', asks.length, 'yellow')}
          {asks.map((ask, i) => (
            <Box key={`ask-${i}`} flexDirection="row" marginTop={i === 0 ? 0 : 1}>
              <Box key={`ask-${i}-mark`} width={2} flexShrink={0}>
                <Text color="yellow">●</Text>
              </Box>
              <Box key={`ask-${i}-body`} flexDirection="column" flexGrow={1} flexShrink={1}>
                {wrapped(ask.text, itemColumns)}
                {ask.options.length > 0 && (
                  <Box key={`ask-${i}-options`} flexDirection="row" flexWrap="wrap" columnGap={1}>
                    {ask.options.map((option, j) => (
                      <Button key={`ask-${i}-${j}`} onPress={() => answer($, ask, option)}>
                        {option}
                      </Button>
                    ))}
                  </Box>
                )}
              </Box>
            </Box>
          ))}
        </Box>
      </Box>
    )
  })
}
