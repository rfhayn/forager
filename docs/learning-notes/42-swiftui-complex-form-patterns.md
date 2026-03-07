# Learning Note 42: SwiftUI Complex Form Patterns

**Milestone**: M10.6–M10.8 — Recipe Import & Editing Forms
**Date**: March 7, 2026
**Scope**: Focus management, form inputs, modal navigation, state/binding patterns, visual feedback, component reuse

---

## Context

M10.6 through M10.8 introduced the most complex editing forms in Forager — recipe import preview, multi-section recipe editing, and ingredient review screens. Each form juggles multiple editable regions (ingredients, steps, metadata), inline autocomplete, and modal category selection. The patterns documented here emerged from solving real interaction problems: focus fights between fields, navigation confusion inside sheets, and stale indices after list mutations.

---

## 1. Focus Management (@FocusState Patterns)

### Multiple @FocusState Mutual Exclusion

The recipe editing form has three independently focusable regions: an ingredient field, a step field, and metadata fields (title, source URL, notes). Declaring three separate `@FocusState` properties provides automatic mutual exclusion — setting one to a non-nil value nils the others.

```swift
@FocusState private var focusedIngredientId: UUID?
@FocusState private var focusedStepIndex: Int?
@FocusState private var focusedMetadata: MetadataFocus?

enum MetadataFocus { case title, sourceURL, notes }
```

When the user taps an ingredient, `focusedIngredientId` is set to that ingredient's UUID. SwiftUI automatically nils `focusedStepIndex` and `focusedMetadata`. Each property has an `.onChange` handler that commits pending edits for its region when it goes nil. This eliminates all manual "exit other editing modes" coordination code — the framework handles it.

### UUID vs Index-Based FocusState

UUID-based focus tracking (`focusedIngredientId: UUID?`) is essential when the list supports reorder and delete. Integer indices go stale the moment a row is inserted, removed, or moved — the focused field silently shifts to the wrong item.

The import preview screen uses `focusedStepIndex: Int?` safely because its step list is static during editing. But the recipe editing screen, where ingredients can be reordered and deleted mid-edit, must use UUIDs.

**Rule of thumb**: If the list mutates while the user is editing, use UUID. If the list is frozen for the duration of the interaction, Int indices are acceptable and simpler.

### FocusState + Conditional Views

Setting `@FocusState` before the target view exists races with SwiftUI's view insertion. This manifests as a TextField that should appear focused but isn't:

```swift
// BUG: focus set before TextField is in the hierarchy
focusedMetadata = .title
showTitleField = true  // conditionally renders TextField

// FIX: set focus AFTER the view appears
if showTitleField {
    TextField("Title", text: $title)
        .focused($focusedMetadata, equals: .title)
        .onAppear { focusedMetadata = .title }
}
```

The `.onAppear` on the TextField itself guarantees the view exists in the hierarchy before focus is requested. This pattern is required any time `@FocusState` targets a conditionally rendered view.

---

## 2. Form Input Patterns

### TextField axis:vertical + submitLabel

`TextField("", text: $binding, axis: .vertical)` with `.submitLabel(.done)` provides the best of both worlds for ingredient and step text: the field wraps long text visually (no horizontal scrolling), while the Done key on the keyboard fires `.onSubmit` instead of inserting a newline.

```swift
TextField("Ingredient", text: $ingredientText, axis: .vertical)
    .submitLabel(.done)
    .onSubmit { commitIngredient() }
```

Without `axis: .vertical`, long ingredient text like "2 cans (14.5 oz each) diced tomatoes, drained" scrolls off-screen horizontally. Without `.submitLabel(.done)`, the return key inserts a newline — useless for single-entry fields that should advance to the next item.

### Context Menu Async Actions

SwiftUI `.contextMenu` button actions cannot be `async` directly. Wrapping in `Task` works for fire-and-forget operations, and `@State` mutations from the async closure update the UI correctly because they dispatch to `@MainActor`:

```swift
.contextMenu {
    Button("Recategorize") {
        Task {
            await recategorizeIngredient(ingredient)
            // @State mutation here updates UI on MainActor
        }
    }
}
```

---

## 3. Navigation in Modals

### Menu vs NavigationLink for Selection in Sheets

Category selection inside a sheet originally used `NavigationLink`, which pushes a new view onto the sheet's internal navigation stack. This created three problems: the user loses context of what they're editing, the interactive dismiss gesture stops working on the pushed view, and the back button text is often truncated.

Replacing `NavigationLink` with `Menu` keeps the user on the same screen. The category list appears as a native dropdown overlay:

```swift
// BAD: pushes navigation inside sheet, confusing UX
NavigationLink("Select Category") {
    CategoryPickerView(selection: $category)
}

// GOOD: dropdown stays on same screen
Menu {
    ForEach(categories) { cat in
        Button(cat.name) { category = cat }
    }
} label: {
    Text(category?.name ?? "Select Category")
}
```

This is broadly applicable: any selection within a modal that has fewer than ~15 options works better as a `Menu` than a `NavigationLink`.

### Sheet interactiveDismissDisabled Scope

`.interactiveDismissDisabled()` must be applied on the `.sheet` modifier's content at the call site — not just inside the modal struct's body. When a shared modal (e.g., `RecipeFormSheet`) gains this requirement, every caller must be updated:

```swift
// The modifier goes HERE, at the call site
.sheet(isPresented: $showEditor) {
    RecipeFormSheet(recipe: recipe)
        .interactiveDismissDisabled(hasUnsavedChanges)
}
```

Placing it only inside `RecipeFormSheet`'s body may appear to work in some contexts but fails when the sheet is presented with different navigation wrappers.

### Toolbar Coordination Between Parent and Child

When a child view needs its own Cancel/Save toolbar within a parent's `NavigationStack`, the parent must hide its own toolbar items for that state. A computed property on the state enum makes this clean:

```swift
// Parent checks state before showing its toolbar
.toolbar {
    if !importState.isReviewing {
        ToolbarItem(placement: .primaryAction) {
            Button("Import") { ... }
        }
    }
}
```

The `isReviewing` computed property on `ImportJobState` centralizes the logic for when the child is in control of the toolbar, preventing the parent's and child's items from colliding.

---

## 4. State & Binding Patterns

### Binding from Enum Associated Values

When a parent models state as an enum with associated values, child views that need `Binding<T>` require a custom getter/setter:

```swift
enum EditState {
    case idle
    case editing(draft: RecipeDraft)
}

@State private var state: EditState = .idle

var draftBinding: Binding<RecipeDraft> {
    Binding(
        get: {
            if case .editing(let draft) = state { return draft }
            return RecipeDraft.empty  // fallback
        },
        set: { newDraft in
            state = .editing(draft: newDraft)
        }
    )
}
```

This avoids flattening the enum into separate `@State` properties (which lose the mutual exclusion that enums provide) while still giving child views the `Binding` they need.

### StateObject + EnvironmentObject Init Gap

Views using `@EnvironmentObject` cannot access environment services in `init()` — environment injection happens after initialization. When a `@StateObject` depends on an environment service, the workaround is to initialize from a shared singleton:

```swift
// Can't do this — environment not available in init()
// @StateObject var viewModel = ViewModel(service: environmentService)

// Instead, use the shared instance directly
@StateObject var viewModel = ViewModel(
    context: PersistenceController.shared.viewContext
)
```

This is a fundamental SwiftUI lifecycle constraint. The `@EnvironmentObject` property is nil during `init()` and only populated when SwiftUI inserts the view into the hierarchy.

### Text Concatenation Deprecation (iOS 26)

`Text("A") + Text("B")` operator concatenation is deprecated in iOS 26. The replacement uses string interpolation, which preserves per-segment modifiers:

```swift
// DEPRECATED
Text("2 ").bold() + Text("cups")

// iOS 26+
Text("\(Text("2 ").bold())\(Text("cups"))")
```

Each interpolated `Text` retains its own modifiers (bold, color, font). The interpolation syntax is more verbose but avoids the deprecation warning.

---

## 5. Visual Feedback

### Three-State Visual Feedback Over Binary Checks

The import preview initially used binary status checks — `categoryName != nil` for a green checkmark, `nil` for a warning icon. This conflated two distinct problems: "needs a category assignment" and "needs a template created." Users couldn't tell what action was required.

Introducing a three-state enum with distinct icons made the feedback actionable:

```swift
enum IngredientMatchResult {
    case ready           // checkmark.circle.fill (green)
    case needsCategory   // folder.badge.questionmark (amber)
    case needsTemplate   // plus.circle (blue)

    var status: Status {
        switch self {
        case .ready: return .ready
        case .needsCategory: return .needsCategory
        case .needsTemplate: return .needsTemplate
        }
    }
}
```

**Principle**: When a visual indicator drives user action, the number of visual states should match the number of distinct actions. Binary indicators work when there's one thing to do; anything more needs an enum.

---

## 6. Component Reuse

### Autocomplete Reuse Across Views

The ingredient autocomplete dropdown (search field + filtered results + selection highlight) appeared in three views: recipe creation, recipe editing, and import preview. The UI and search logic were identical — only the selection handler differed.

Extracting the dropdown as a reusable component with a closure parameter for selection eliminated three copies of the same layout and search code:

```swift
IngredientAutocomplete(
    searchText: $searchText,
    onSelect: { template in
        // View-specific handling — the only varying part
        assignTemplate(template, to: currentIngredient)
    }
)
```

The search service call, debouncing, result layout, and keyboard interaction are all internal to the component. Each call site provides only its selection handler. When autocomplete behavior needed tuning (debounce timing, result count), the fix was in one place.

---

## Key Takeaways

| Pattern | When to Apply | Risk if Ignored |
|---------|---------------|-----------------|
| Multiple @FocusState mutual exclusion | Forms with 2+ editable regions | Focus fights, uncommitted edits |
| UUID-based focus tracking | Editable lists with reorder/delete | Focus jumps to wrong item |
| .onAppear focus for conditional views | Any @FocusState + conditional render | TextField appears unfocused |
| TextField axis:vertical + .submitLabel | Multi-word input fields | Horizontal scroll or unwanted newlines |
| Menu over NavigationLink in sheets | Selection with <15 options in modal | Confusing nested navigation |
| Binding from enum associated values | Enum-modeled state passed to children | Forced to flatten state into loose @State vars |
| Three-state visual feedback | Status indicators that drive user action | Users can't tell what to do |
| Autocomplete reuse via closure | Same UI + search, different selection | Three copies of identical code diverging |

---

**Promoted from**: Insights Log entries — SwiftUI/FocusState (M10.6), SwiftUI/TextFieldAxis (M10.6), SwiftUI/ContextMenuAsync (M10.7), SwiftUI/SheetDismiss (M10.7), SwiftUI/MenuVsNavLink (M10.6), SwiftUI/ToolbarCoordination (M10.8), SwiftUI/BindingFromEnum (M10.7), SwiftUI/TextDeprecation (M10.8), SwiftUI/ThreeStateFeedback (M10.6), SwiftUI/StateObjectInit (M10.7), SwiftUI/AutocompleteReuse (M10.8)
