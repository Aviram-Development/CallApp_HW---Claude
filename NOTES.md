# Notes

What I changed, what I left alone, and why.

## The bugs I found

**Fetching contacts blocked the main thread.** The single worst thing in the project. The project
builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so `ContactsStore` was main-actor-isolated,
and `CNContactStore.enumerateContacts` is a *synchronous, blocking* call. Every launch froze the UI
for the length of the fetch. The file's own changelog comment made this one easy to date: `@concurrent`
was added on 08-18 "so fetching doesn't block the main thread", and the 08-20 "refactored per developer
request" entry silently dropped it. Note that under approachable concurrency a plain `nonisolated async`
function still runs on the caller's actor, so simply marking it `nonisolated` would not have fixed it.
`CNContactsRepository` is an `actor`, which moves the work to a background executor and — unlike
`@concurrent` on a type holding a shared `CNContactStore` — needs no `@unchecked Sendable`.

**`Contact` equality was unstable.** `LabeledValue.id` was a fresh `UUID()` per initialization and
participated in `Contact`'s synthesized `Hashable`. Two fetches of the same contact therefore never
compared equal, which quietly corrupted `List` diffing and `NavigationStack` path matching. The
synthesized conformance also hashed `thumbnailData`, so every comparison hashed a whole image. Identity
is now the contact identifier and nothing else, and `LabeledValue.id` is derived from position and
content. `ContactTests.identicalContactsAreEqual` is the regression guard.

The existing test passed only because it compared one instance to itself.

**A `print` in the search predicate.** `matches(contact:query:)` logged once per contact per keystroke.
The filtered list was also computed twice per render — once for the rows, once to decide whether to show
the empty state.

**Dead code.** `ContactDetailView` carried its own private copy of `requestAccessIfNeeded()`,
copy-pasted from the store and never called. `MockGenerator` shipped in the app target, imported UIKit,
and had zero call sites — because the project contained no previews to use it.

## The structure

The layering (models / services / use cases / view models, with dependencies injected explicitly) is
heavier than 700 lines of app strictly needs, and I want to be straight about that: for an app this
size, folding the use cases into the view models would also be defensible.

What makes it earn its keep here is testability. The interesting logic — search matching, the
three-way permission branch, favourites persistence — was previously trapped inside views and static
`UserDefaults` calls, which is why none of it was tested. `ContactSearchMatcher` and
`ContactSectionBuilder` are pure functions over values; `LoadContactsUseCase` is driven by a fake
repository. The suite went from 1 test to 64, and every one of those tests is possible only because
the logic came out of the views.

`AppDependencies` is a plain value passed down by initializer injection, deliberately not a singleton
or an environment lookup: nothing can reach a service it was not handed.

## Judgment calls

**Sorting and sectioning both key off `displayName`.** The original fetched with
`sortOrder = .userDefault`. Sectioning by family name while sorting by the user's display-order
preference would let headers and order disagree. Keying both off `displayName` means a contact always
files under the letter you can see it starts with. `CNContactFormatter` already honours the user's
given/family order preference, so this follows that preference rather than fighting it.

**Favourites are duplicated, not moved.** A pinned favourite also stays in its letter section.
Removing it would mean scrolling to "S" for a favourited Emma Stone and not finding her. The pinned
section is suppressed while searching, where duplicates would just look like duplicate results.

**I did not debounce the search field** — a deviation from my own plan. Once the `print` was gone and
the double-computation collapsed to one, filtering is a linear pass over an in-memory array and takes
well under a frame. Debouncing would have added latency to clearing the field in exchange for solving
a problem the profiler does not have. The cost was never the filter; it was the logging.

**`sections` is computed, not cached.** Caching it would mean invalidating on three inputs (contacts,
query, favourites). `@Observable` already invalidates a computed property correctly and for free, and
there is no cache to go stale. The view reads it into a local once per render, which is what actually
fixed the double-computation.

**`UserDefaults` for favourites, and the same storage key.** A flat set of identifiers read once at
launch does not warrant SwiftData or a file. Keeping the `favoriteContactIDs` key means anyone already
running the app keeps their favourites; `FavoritesStoreTests.readsLegacyKey` pins that down.

## What I left alone

- The **`ContentUnavailableView` empty states** for denied permission and load failure. They were
  already good — clear, actionable, with an Open Settings button. I added a re-check on returning to
  the foreground so granting access in Settings takes effect on return, and an empty-address-book state
  distinct from "nothing loaded".
- The **`displayName` and `initials` fallback chains**. The logic was sound; I deleted the commented-out
  branch above `displayName` and covered both chains with tests.
- The **refresh-failure semantics**: a failed reload keeps the list already on screen rather than
  blanking it. That was a good instinct in the original code and I kept it, with a test.
- **`CNContactFormatter.descriptorForRequiredKeys`** in the fetch keys. The changelog says it was added
  to fix a crash, and it is genuinely required — `fullName` comes from the formatter, which needs its
  own keys. It moved to `Contact.fetchKeys`, next to the code that reads those keys.
- **No third-party dependencies.** Nothing here needed one.

## Verification

`xcodebuild test` — 64 tests, no warnings. Release configuration builds clean, and `nm` confirms no
`PreviewData` symbols reach the shipping binary (`#Preview` blocks compile in release too, so they are
inside `#if DEBUG` as well).

I ran the app on an iPhone 17 Pro simulator and confirmed the list, sectioning, coloured avatars,
search field and index bar render correctly, and fixed an index-bar/chevron overlap found that way.
I was not able to drive taps on this machine — the simulator automation needed `xcode-select` pointed
at the full Xcode — so the detail screen, the quick actions and the favourites section were verified
through previews and the test suite rather than by tapping through a running build.

## What I would do next

1. **UI tests** for the two flows that unit tests cannot reach: the permission prompt on a cold launch,
   and starring a contact in the detail screen showing up in the list behind it.
2. **`CNContactStoreDidChange`** — the list is only refreshed on launch and on pull-to-refresh, so an
   edit made in the Contacts app while this one is backgrounded is not picked up.
3. **Incremental loading.** `enumerateContacts` builds the whole array before anything renders. On a
   very large address book, streaming the first screenful would show something sooner.
4. **Localization.** Every user-facing string is a hard-coded English literal.
