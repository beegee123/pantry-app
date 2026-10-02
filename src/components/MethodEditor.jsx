import { useEditor, useEditorState, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import { methodToHtml } from '../lib/methodHtml.js'

// The rich-text box for a recipe's method: bold, italics, numbered and bulleted lists.
// Typing "1. " or "- " at the start of a line also starts a list, and Enter continues it.
//
// Props:
//   value    — the stored method (HTML, or plain text from older recipes)
//   onChange — function(html), called on every change ('' when empty)
export default function MethodEditor({ value, onChange, id }) {
  const editor = useEditor({
    extensions: [
      // StarterKit bundles the common pieces; we switch off the ones we don't offer,
      // so pasted text can't bring in headings, links, code blocks and so on.
      StarterKit.configure({
        heading: false,
        code: false,
        codeBlock: false,
        blockquote: false,
        horizontalRule: false,
        strike: false,
        underline: false,
        link: false,
        trailingNode: false, // no empty paragraph added at the end
      }),
    ],
    content: methodToHtml(value), // only used when the editor first appears
    editorProps: {
      attributes: { class: 'method-editor-text', id, 'aria-label': 'Method' },
    },
    onUpdate: ({ editor }) => onChange(editor.isEmpty ? '' : editor.getHTML()),
  })

  // Which buttons should look pressed? Re-checked as the cursor moves.
  const active = useEditorState({
    editor,
    selector: ({ editor }) => ({
      bold: editor?.isActive('bold') ?? false,
      italic: editor?.isActive('italic') ?? false,
      ordered: editor?.isActive('orderedList') ?? false,
      bullet: editor?.isActive('bulletList') ?? false,
    }),
  })

  if (!editor) return null

  // onMouseDown + preventDefault keeps the cursor in the text while you tap a button.
  const button = (label, name, isOn, run) => (
    <button
      type="button"
      className={isOn ? 'method-tool is-on' : 'method-tool'}
      aria-label={name}
      aria-pressed={isOn}
      onMouseDown={(e) => e.preventDefault()}
      onClick={() => run(editor.chain().focus()).run()}
    >
      {label}
    </button>
  )

  return (
    <div className="method-editor">
      <div className="method-toolbar" role="toolbar" aria-label="Formatting">
        {button(<strong>B</strong>, 'Bold', active.bold, (c) => c.toggleBold())}
        {button(<em>I</em>, 'Italic', active.italic, (c) => c.toggleItalic())}
        {button('1.', 'Numbered list', active.ordered, (c) => c.toggleOrderedList())}
        {button('•', 'Bulleted list', active.bullet, (c) => c.toggleBulletList())}
      </div>
      <EditorContent editor={editor} />
    </div>
  )
}
