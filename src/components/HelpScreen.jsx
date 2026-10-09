import { Link } from 'react-router'

// The user guide: /help, opened from the ? button on the Kitchen.
// Each section is a <details> element: the browser handles tapping to open and close,
// so there's no state to manage, and screen readers announce them as expandable.
export default function HelpScreen() {
  return (
    <div className="screen">
      <header className="screen-header screen-header--sub">
        <Link to="/" className="back-link">
          ‹ Kitchen
        </Link>
        <span className="eyebrow">HOW IT WORKS</span>
        <h1>Help</h1>
      </header>

      <main className="item-list help">
        <p className="help-intro">
          One shared kitchen for the household. Anything you change shows up on everyone’s phone straight away.
        </p>

        <details open>
          <summary>The basics: In, Low, Out</summary>
          <p>Every pantry item has one status:</p>
          <ul>
            <li>
              <strong>In</strong>: you have it.
            </li>
            <li>
              <strong>Low</strong>: running out; buy more soon.
            </li>
            <li>
              <strong>Out</strong>: none left.
            </li>
          </ul>
          <p>
            Low and Out items go on the Shopping list automatically, and recipes use them to work out what you can
            cook. There are no quantities to count: salt, oil and water are assumed to be in stock.
          </p>
        </details>

        <details>
          <summary>Kitchen</summary>
          <ul>
            <li>Tap In, Low or Out next to an item to change it.</li>
            <li>Tap an item’s name to edit it: name, usual amount, category, stores, or delete it.</li>
            <li>
              <strong>Search</strong> narrows the list as you type. If nothing matches, tap “+ Add … as a new
              item” to create it with the name filled in.
            </li>
            <li>
              The <strong>All / In / Low / Out</strong> chips show just one status; they work together with search.
            </li>
            <li>
              <strong>+</strong> adds a new item. The <strong>usual amount</strong> (“1 bag”) is shown on the
              Shopping list.
            </li>
            <li>
              <strong>Stores</strong>: add, rename or remove where you shop. On an item, tick every store that sells
              it and mark one as ★ Preferred.
            </li>
            <li>
              <strong>Categories</strong>: add, rename, reorder (↑ ↓) or remove the Kitchen’s sections. Removing one
              that’s in use asks where its items should go.
            </li>
          </ul>
        </details>

        <details>
          <summary>Shopping</summary>
          <ul>
            <li>Lists every Low and Out item. The number on the Shopping tab is how many.</li>
            <li>
              <strong>All</strong> shows each item once, under its preferred store, so nothing gets bought twice.
            </li>
            <li>
              A <strong>store chip</strong> (e.g. Costco) shows everything you can buy there, with “also at” for
              items another store sells too. <strong>Any store</strong> is for items with no store picked.
            </li>
            <li>
              <strong>This week</strong> (today to Sunday) and <strong>Next week</strong> (Monday to Sunday) show only
              what those weeks’ planned dinners need, the same weeks as the Menu tab. Those items also say which
              dinner they’re for (“For Thu Jollof rice”; next week’s add the date, “For Tue 13 …”). An item both
              weeks need is in both chips, but it’s one item: tick it once.
            </li>
            <li>Tick items as they go in the cart.</li>
            <li>
              <strong>Finish trip</strong> sets every ticked item back to In, and they leave the list.
            </li>
          </ul>
        </details>

        <details>
          <summary>Recipes</summary>
          <ul>
            <li>
              Each recipe shows whether you can cook it: <strong>Ready</strong>, <strong>Low</strong> (something is
              running out) or <strong>Missing</strong> (something is Out). Ready recipes come first.
            </li>
            <li>
              Search by name, or use <strong>★ Favourites</strong> and <strong>Under 30 min</strong>.
            </li>
            <li>
              <strong>+</strong> adds a recipe. Ingredients are always pantry items: search for one, or add a new one
              to the pantry on the spot. Amounts like “2 cups” are just for reading.
            </li>
            <li>
              <strong>Assumed basics</strong> (salt, oil…) are a note only and never affect Ready / Missing.
            </li>
            <li>
              In the <strong>method</strong>, type “1. ” to start numbered steps or “- ” for bullets; Enter
              continues the list. B and I make text bold or italic.
            </li>
          </ul>
          <p>On a recipe:</p>
          <ul>
            <li>
              <strong>‹ ›</strong> at the top go to the previous or next recipe in the Recipes list (as searched or
              filtered), without going back to the list.
            </li>
            <li>
              Tap an ingredient’s <strong>status</strong> to change it: In → Low → Out → In. It changes the pantry
              item everywhere.
            </li>
            <li>
              Missing items are already on your Shopping list; the link takes you there.
            </li>
            <li>
              <strong>Add photo</strong> takes or picks one picture (it’s shrunk to save data).
            </li>
            <li>
              <strong>Duplicate</strong> starts a new recipe from this one; nothing is saved until you press Save.
            </li>
            <li>
              <strong>Edit</strong> changes it; Delete is at the bottom of the edit screen.
            </li>
          </ul>
        </details>

        <details>
          <summary>Menu</summary>
          <ul>
            <li>Plans one dinner a day, Monday to Sunday. ‹ › moves between weeks.</li>
            <li>
              Tap <strong>+ Pick a recipe</strong> on an empty day, or <strong>Change</strong> on a planned one. The
              picker shows dinners first, ready ones at the top, and “Also Thu” if a recipe is already that week. It
              can also clear the day.
            </li>
            <li>Tap a planned recipe to open it.</li>
            <li>
              <strong>Rearrange</strong> (next to the dinner count) moves dinners between days: tap a dinner, then
              the day you want it on. If that day has a dinner, the two swap. Tap <strong>Done</strong> when finished.
            </li>
            <li>
              The card below the week lists what the remaining dinners still need. Those items are already on the
              Shopping list.
            </li>
          </ul>
          <p>
            <strong>Generate week</strong> fills days for you:
          </p>
          <ul>
            <li>Pick the days. Days that already have a dinner are marked; ticking one replaces it.</li>
            <li>
              <strong>Use what I have</strong> favours recipes you can cook now; <strong>Balanced</strong> weighs
              stock less; <strong>Don’t care</strong> ignores it.
            </li>
            <li>
              Rules: no repeats, avoid last week’s dinners, favourites more often, and long recipes (over 45 min) on
              weekends only.
            </li>
            <li>
              Only recipes with the meal type <strong>Dinner</strong> are used. If a day stays empty, add more dinner
              recipes or switch a rule off.
            </li>
          </ul>
        </details>

        <details>
          <summary>Tips</summary>
          <ul>
            <li>
              Add the app to your home screen: in the browser’s menu, choose <strong>Add to Home screen</strong>.
            </li>
            <li>Everyone in the household sees the same pantry, recipes and menu.</li>
            <li>If something looks out of date (say, after the phone was offline), close and reopen the app.</li>
            <li>
              <strong>Sign out</strong> is at the top of the Kitchen.
            </li>
          </ul>
        </details>
      </main>
    </div>
  )
}
