// Recipe methods are stored as HTML from the rich-text editor ("<ol><li>Toast the <strong>rice</strong>…").
// Older methods (and recipe imports) are plain text, so we convert those on the fly.
import DOMPurify from 'dompurify'

// Only the formatting the editor can make. Anything else (scripts, links, styles, images)
// is stripped before display — see cleanMethodHtml below.
const ALLOWED_TAGS = ['p', 'br', 'strong', 'em', 'ol', 'ul', 'li']
const ALLOWED_ATTR = ['start'] // <ol start="3"> keeps numbering that doesn't begin at 1

const looksLikeHtml = (text) => /^\s*</.test(text)

const escape = (text) =>
  text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

const NUMBERED = /^\s*(\d+)[.)]\s+(.*)$/ // "1. Toast the rice" or "2) Add water"
const BULLET = /^\s*[-*•]\s+(.*)$/ //       "- salt" or "• pepper"

// Plain text → HTML.
//   Lines starting "1." become a numbered list, lines starting "-" or "•" a bulleted list,
//   anything else a paragraph. A blank line between list items doesn't break the list,
//   so "1. …(blank)2. …" stays ONE list numbered 1, 2 instead of two lists both numbered 1.
export function textToHtml(text) {
  const lines = text.replace(/\r\n/g, '\n').split('\n')
  const html = []
  let list = null // { tag: 'ol' | 'ul', items: [] }
  let paragraph = [] // lines of the current paragraph

  const closeParagraph = () => {
    if (paragraph.length) html.push(`<p>${paragraph.map(escape).join('<br>')}</p>`)
    paragraph = []
  }
  const closeList = () => {
    if (list) html.push(`<${list.tag}${list.start > 1 ? ` start="${list.start}"` : ''}>${list.items.map((i) => `<li><p>${escape(i)}</p></li>`).join('')}</${list.tag}>`)
    list = null
  }

  for (const line of lines) {
    const numbered = line.match(NUMBERED)
    const bullet = !numbered && line.match(BULLET)
    if (numbered || bullet) {
      closeParagraph()
      const tag = numbered ? 'ol' : 'ul'
      if (list && list.tag !== tag) closeList()
      if (!list) list = { tag, items: [], start: numbered ? Number(numbered[1]) : 1 }
      list.items.push(numbered ? numbered[2] : bullet[1])
    } else if (line.trim() === '') {
      closeParagraph() // a blank line ends a paragraph, but not a list
    } else {
      closeList()
      paragraph.push(line.trim())
    }
  }
  closeParagraph()
  closeList()
  return html.join('')
}

// Whatever is stored (HTML, plain text or nothing) → HTML for the editor or the recipe screen.
export function methodToHtml(method) {
  if (!method || !method.trim()) return ''
  return looksLikeHtml(method) ? method : textToHtml(method)
}

// ALWAYS clean HTML before putting it on the page with dangerouslySetInnerHTML.
// Without this, a method containing <img src=x onerror="…"> would run that code in the app
// (an XSS attack). DOMPurify keeps only the tags listed above.
export function cleanMethodHtml(method) {
  return DOMPurify.sanitize(methodToHtml(method), { ALLOWED_TAGS, ALLOWED_ATTR })
}
