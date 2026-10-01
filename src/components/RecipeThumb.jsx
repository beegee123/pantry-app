// A recipe's photo, or — when there isn't one — a tile with the first letter of its name.
//
// Props:
//   name — the recipe name (for the letter and the alt text)
//   url  — the photo's link, or null
//   size — 'small' (list thumbnail) or 'hero' (top of the detail screen)
export default function RecipeThumb({ name, url, size = 'small' }) {
  if (url) {
    return <img className={`recipe-thumb recipe-thumb--${size}`} src={url} alt={`Photo of ${name}`} loading="lazy" />
  }
  return (
    <span className={`recipe-thumb recipe-thumb--${size} recipe-thumb--letter`} aria-hidden="true">
      {name.trim().charAt(0).toUpperCase()}
    </span>
  )
}
