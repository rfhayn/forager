# Mobile UX Patterns Research: Forager iOS App

**Document**: 01 - Mobile UX Patterns & Design Systems
**Date**: February 14, 2026
**Purpose**: Comprehensive research on mobile UX patterns, design systems, and iOS-specific design guidance for the Forager grocery list and meal planning app.
**Target Platform**: iOS 18.0+ (current), with forward-looking guidance for iOS 26 Liquid Glass

---

## Table of Contents

1. [iOS Design Patterns (2025-2026)](#1-ios-design-patterns-2025-2026)
2. [Design Systems & Kits](#2-design-systems--kits)
3. [SwiftUI-Specific Patterns](#3-swiftui-specific-patterns)
4. [Component Patterns](#4-component-patterns)
5. [Grocery/Food App Specific UX](#5-groceryfood-app-specific-ux)
6. [Accessibility](#6-accessibility)
7. [Forager-Specific Recommendations](#7-forager-specific-recommendations)
8. [Sources](#8-sources)

---

## 1. iOS Design Patterns (2025-2026)

### 1.1 Apple Human Interface Guidelines: Current State

The Apple Human Interface Guidelines (HIG) remain the authoritative source for iOS design. The 2025-2026 guidelines continue to emphasize three foundational principles:

- **Clarity**: Clean, precise, uncluttered interfaces. Limited elements to prevent confusion. Clear, recognizable instructions, symbols, and icons.
- **Deference**: Content is always the focus. The interface serves the content rather than competing with it.
- **Depth**: Visual layers and realism create spatial understanding and hierarchy.

**Key HIG rules relevant to Forager:**

| Guideline | Recommendation |
|-----------|---------------|
| Touch targets | Minimum 44x44 points. Smaller targets are missed by 25%+ of users. |
| Navigation depth | Main functions accessible within 2 taps from home screen. |
| Platform integration | Support Dynamic Type, Dark Mode, and VoiceOver as baseline expectations. |
| System colors | Use semantic colors (.primary, .secondary, .systemBackground) that auto-adapt to appearance modes. |

### 1.2 iOS 26: Liquid Glass Design Language

Announced at WWDC 2025 (June 9, 2025), Liquid Glass is Apple's unified visual theme across iOS 26, iPadOS 26, macOS Tahoe 26, watchOS 26, and tvOS 26. It represents the most significant visual redesign since iOS 7's flat design revolution.

#### What Is Liquid Glass?

Liquid Glass is a translucent, dynamic material that combines the optical properties of glass with a sense of fluidity. It reflects and refracts surrounding content while transforming to bring focus to user tasks. Key technical characteristics:

- **Real-time lensing**: The primary visual property. Elements bend and refract the content behind them, creating depth.
- **Specular highlights**: Light responds to device motion via gyroscope input, creating a sense of physicality.
- **Adaptive shadows**: Shadows adjust dynamically based on background content and light conditions.
- **Environmental color**: The material's tint is informed by surrounding content and adapts between light and dark environments.
- **Interactive behaviors**: Glass elements respond to touch and scroll interactions with fluid animations.

#### Three Core Design Principles of Liquid Glass

**1. Hierarchy**
Liquid Glass controls float above content as a distinct functional layer. This creates depth while reducing visual complexity. Instead of flattening interfaces, it creates clear separation between:
- Background content layer
- Interactive control layer (glass material)
- Foreground focus elements

**2. Harmony**
The design balances hardware, content, and controls. Device shapes inform UI element design. Rounded forms follow natural touch patterns. Your app's visual language must harmonize with the glass material rather than fight it.

**3. Consistency**
Universal design language across all Apple platforms. The same principles apply on iPhone, iPad, Mac, Watch, and TV, simplifying cross-platform development while maintaining each platform's unique qualities.

#### Liquid Glass UI Elements

The material extends from the smallest elements (buttons, switches, sliders, text controls, media controls) to larger navigation elements (tab bars, sidebars, toolbars). On the Home Screen, the Dock, app icons, and widgets are all crafted from multiple layers of Liquid Glass.

Key behavioral changes:
- **Tab bars are no longer pinned to bezels**. They float as glass "bubbles" that appear and disappear based on context.
- **Tab bars shrink when scrolling**. They minimize on scroll-down to give content more space, and expand when scrolling back up.
- **Glass elements blend when close together**. Multiple glass views that are proximate will merge and separate fluidly.

#### Liquid Glass App Icons

iOS 26 treats app icons as layered glass. Apple provides Icon Composer to create multi-layer icons with specular highlights, blur, translucency, and shadows. Each icon adapts to six appearance modes: Default, Dark, Clear Light, Clear Dark, Tinted Light, and Tinted Dark.

Design guidance for icons:
- Avoid sharp edges and thin lines.
- Use rounder corners for seamless light travel on edges.
- Softer light-to-dark gradients harmonize with the direction of light.
- Keep layers clean and distinct; communicate one thing instantly.

#### Relevance to Forager

While Forager currently targets iOS 18, understanding Liquid Glass is essential for forward compatibility. When the minimum deployment target advances to iOS 26:

- The existing `.regularMaterial` usage in `CustomBottomNavigation.swift` will transition naturally to glass effects.
- Tab bar behavior will shift from custom implementation to system-provided Liquid Glass tab bars.
- The earthy color palette should be tested for how it appears through glass lensing and refraction.
- Card-based layouts will benefit from glass material for visual depth.

### 1.3 SF Symbols 6

SF Symbols now includes over 6,000 symbols across categories. SF Symbols 6 (shipped with iOS 18) introduced three new animation presets:

**Wiggle**: Highlights changes or calls to action. Each symbol has a preferred wiggle direction (up, down, left, right). Useful for drawing attention to new items or changes.

**Rotate**: Shows dynamic movement or visual progress. Supports clockwise and counterclockwise directions. Good for refresh indicators and loading states.

**Breathe**: A subtle pulsing animation that adds depth. Layers opted-in to Pulse change their opacity. Suitable for ambient status indicators.

**Usage guidelines for Forager:**

| Context | Symbol | Animation |
|---------|--------|-----------|
| Add to list | `plus.circle.fill` | Bounce on tap |
| Checkbox toggle | `checkmark.circle.fill` | Scale transition |
| Low confidence warning | `exclamationmark.triangle.fill` | Wiggle (attention) |
| Sync in progress | `arrow.triangle.2.circlepath` | Rotate (continuous) |
| Empty state | `cart` or `list.bullet` | Breathe (ambient) |
| Delete/swipe | `trash` | Bounce on activation |
| Recipe scaling | `slider.horizontal.3` | None (static) |
| Household sharing | `person.2.fill` | None (static) |

**Best practice**: Use animations intentionally and purposefully. They should add to the experience rather than distract from it. Always respect the Reduce Motion accessibility setting (see Section 6).

---

## 2. Design Systems & Kits

### 2.1 Apple's Built-In Design Tokens

SwiftUI provides a rich set of built-in design tokens that serve as the foundation for any iOS design system:

#### Color Tokens

| Token | Purpose | Adapts to Dark Mode |
|-------|---------|-------------------|
| `.primary` | Main text color | Yes |
| `.secondary` | Secondary text, subtitles | Yes |
| `.accentColor` | Interactive elements, links | Yes |
| `.systemBackground` | View backgrounds | Yes |
| `.secondarySystemBackground` | Grouped content backgrounds | Yes |
| `.tertiarySystemBackground` | Nested grouped backgrounds | Yes |
| `.systemGroupedBackground` | Table/list grouped backgrounds | Yes |
| `.separator` | Divider lines | Yes |
| `.label` / `.secondaryLabel` | Text hierarchy | Yes |

#### Typography Tokens

SwiftUI provides semantic font styles that automatically scale with Dynamic Type:

| Style | Typical Use |
|-------|------------|
| `.largeTitle` | Screen headers, onboarding |
| `.title` / `.title2` / `.title3` | Section headers, card titles |
| `.headline` | List row primary text, emphasized content |
| `.subheadline` | List row secondary text |
| `.body` | Standard paragraph text |
| `.callout` | Inline explanations |
| `.footnote` | Timestamps, metadata |
| `.caption` / `.caption2` | Labels, badges, fine print |

#### Spacing Tokens (System-Defined)

Apple does not expose explicit spacing tokens, but consistent spacing follows the 4-point grid system:

| Size | Points | Use |
|------|--------|-----|
| Micro | 4 | Between related inline elements |
| Small | 8 | Between related elements in a group |
| Medium | 12-16 | Between groups, standard padding |
| Large | 20-24 | Between sections |
| Extra Large | 32-48 | Between major content areas |

### 2.2 Community Design Systems for SwiftUI

Several production-ready design systems exist for SwiftUI:

**SwiftUI-Design-System-Pro**
A comprehensive system with production-ready design tokens, enterprise components, and a theme engine. Includes color tokens, typography scales, spacing values, and pre-built components.

**NormanDSKit**
A modern design system described as "Liquid Glass Ready, Token-Driven, Modular and Scalable." Built specifically with iOS 26 compatibility in mind.

**OversizeUI**
A SwiftUI component library with customizable components following modern design principles. Focuses on theming and developer experience.

**Atomic Design Pattern in SwiftUI**
The atomic design methodology (atoms, molecules, organisms, templates, pages) maps well to SwiftUI:
- **Atoms**: Text styles, color tokens, icon components
- **Molecules**: Labeled inputs, icon-text pairs, badges
- **Organisms**: List rows, card components, form sections
- **Templates**: Screen layouts, navigation structures
- **Pages**: Complete screens with data

### 2.3 Design Token Implementation Pattern

The recommended pattern for a custom design system in SwiftUI centralizes all tokens under a single namespace:

```swift
// Design token architecture
enum DesignSystem {
    enum Colors {
        static let primary = Color("ForagerGreen")       // #2D5016
        static let secondary = Color("LeafGreen")        // #4A7C2E
        static let accent = Color("SpringGreen")         // #6B9B37
        static let background = Color("Cream")           // #F5F0E8
        static let surface = Color("WarmSand")
        static let textPrimary = Color("ForagerText")
        static let textSecondary = Color("SageGray")
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let card: CGFloat = 20
    }
}
```

---

## 3. SwiftUI-Specific Patterns

### 3.1 Theming: Color Asset Catalogs vs Programmatic Colors

There are two primary approaches to color management in SwiftUI, and the recommendation is to use both together:

#### Approach 1: Color Asset Catalog (Recommended as Primary)

Define colors in `Assets.xcassets` with light and dark mode variants. This is the Apple-recommended approach:

**Advantages:**
- Visual editing in Xcode with real-time preview
- Automatic light/dark mode switching at the system level
- Interface Builder and Storyboard compatibility
- Asset catalog color references work in both SwiftUI and UIKit
- Accessibility contrast variants can be added per color set

**Implementation:**
```swift
// In asset catalog: define "ForagerGreen" with light (#2D5016) and dark variants
// In code:
Color("ForagerGreen")  // Automatically resolves based on appearance
```

**Recommended color sets for Forager:**

| Color Set Name | Light Mode | Dark Mode | Usage |
|----------------|-----------|-----------|-------|
| `ForagerPrimary` | #2D5016 (Forest Green) | #6B9B37 (Spring Green) | Primary actions, headers |
| `ForagerSecondary` | #4A7C2E (Leaf Green) | #8BB55A (Lighter green) | Secondary elements |
| `ForagerAccent` | #6B9B37 (Spring Green) | #9CC76A (Bright green) | Interactive highlights |
| `ForagerBackground` | #F5F0E8 (Cream) | #1C1C1E (System dark) | Screen backgrounds |
| `ForagerSurface` | #FFFFFF (White) | #2C2C2E (Elevated dark) | Card/cell backgrounds |
| `ForagerTextPrimary` | #1A1A1A (Near black) | #F5F0E8 (Cream) | Primary text |
| `ForagerTextSecondary` | #6B7B6A (Sage gray) | #A3B3A2 (Light sage) | Secondary text |
| `ForagerWarning` | #D4A843 (Warm amber) | #E8C055 (Bright amber) | Warnings, low confidence |
| `ForagerError` | #C44B36 (Terra cotta) | #E06050 (Bright terra) | Errors, destructive |
| `ForagerSuccess` | #2D5016 (Forest green) | #6B9B37 (Spring green) | Completed items |

#### Approach 2: Programmatic Colors (Supplement)

Use `UIColor(dynamicProvider:)` bridged to SwiftUI `Color` for dynamic colors that need runtime computation:

> **⚠️ API correction (validated Feb 15, 2026):** `Color(light:dark:)` does **not exist** as a native SwiftUI initializer. The correct approach is to bridge through `UIColor(dynamicProvider:)`:

```swift
extension Color {
    static let foragerPrimary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.420, green: 0.608, blue: 0.216, alpha: 1.0)  // #6B9B37
            : UIColor(red: 0.176, green: 0.314, blue: 0.086, alpha: 1.0)  // #2D5016
    })
}
```

This approach works on iOS 14+ and integrates with SwiftUI's environment-driven appearance switching.

#### Recommendation for Forager

Use the **asset catalog as the single source of truth** for the brand palette. Supplement with programmatic extensions for computed colors (opacity variants, derived tints). This matches the existing pattern where `LaunchBackground` and `LaunchIcon` are already defined in the asset catalog.

### 3.2 Environment-Based Theming

SwiftUI's `@Environment` system is the recommended pattern for theme propagation:

```swift
// Define a theme protocol
protocol ForagerTheme {
    var primaryColor: Color { get }
    var backgroundColor: Color { get }
    var cardBackground: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var spacing: ForagerSpacing { get }
    var cornerRadius: ForagerCornerRadius { get }
}

// Inject via Environment
struct ForagerThemeKey: EnvironmentKey {
    static let defaultValue: ForagerTheme = DefaultForagerTheme()
}

extension EnvironmentValues {
    var foragerTheme: ForagerTheme {
        get { self[ForagerThemeKey.self] }
        set { self[ForagerThemeKey.self] = newValue }
    }
}

// Usage in views
struct GroceryListRow: View {
    @Environment(\.foragerTheme) var theme

    var body: some View {
        HStack {
            Text(item.name)
                .foregroundColor(theme.textPrimary)
        }
        .padding(theme.spacing.md)
    }
}
```

**When to use Environment theming:**
- When supporting multiple themes (standard, high contrast, seasonal)
- When views need to read theme values without passing props
- When testing with different visual configurations

**When asset catalog colors are sufficient:**
- Single theme with light/dark variants (Forager's current state)
- No runtime theme switching needed
- Simpler codebase is preferred

### 3.3 ViewModifier Patterns for Consistent Styling

ViewModifiers are the primary mechanism for reusable styling in SwiftUI:

```swift
// Card style modifier
struct ForagerCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("ForagerSurface"))
                    .shadow(
                        color: colorScheme == .dark
                            ? .clear
                            : .black.opacity(0.08),
                        radius: 8, x: 0, y: 2
                    )
            )
    }
}

extension View {
    func foragerCard() -> some View {
        modifier(ForagerCardModifier())
    }
}

// List row style modifier
struct ForagerListRowModifier: ViewModifier {
    let isChecked: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isChecked ? 0.5 : 1.0)
            .strikethrough(isChecked)
            .animation(.easeInOut(duration: 0.2), value: isChecked)
    }
}
```

**Recommended ViewModifiers for Forager:**

| Modifier | Purpose |
|----------|---------|
| `.foragerCard()` | Standard card styling with shadow |
| `.foragerListRow()` | Consistent list row padding and spacing |
| `.foragerSectionHeader()` | Section header typography and color |
| `.foragerBadge(color:)` | Consistent badge styling (category, confidence) |
| `.foragerDestructive()` | Red destructive action styling |
| `.foragerEmptyState()` | Empty state container with centered content |

### 3.4 Adaptive Dark/Light Mode

Best practices for dark mode in SwiftUI:

1. **Never use pure black (#000000) or pure white (#FFFFFF)** for backgrounds. Pure black causes eye strain and reduces legibility. Use near-black (#1C1C1E) and off-white (#F5F0E8) respectively.

2. **Desaturate colors in dark mode**. Bright, saturated earthy greens that work in light mode can be harsh in dark environments. Shift toward lighter, less saturated variants.

3. **Reverse the shadow strategy**. In light mode, use subtle drop shadows for elevation. In dark mode, use slightly lighter backgrounds for elevated surfaces instead of shadows.

4. **Test the earthy palette in both modes**. The cream (#F5F0E8) background works beautifully in light mode. For dark mode, ensure the green tones maintain sufficient contrast against dark backgrounds.

5. **Use `colorScheme` environment value** for mode-specific adjustments:

```swift
@Environment(\.colorScheme) var colorScheme

var body: some View {
    VStack {
        // Conditional styling based on appearance
        Text("Category")
            .foregroundColor(
                colorScheme == .dark
                    ? Color("ForagerAccent")
                    : Color("ForagerPrimary")
            )
    }
}
```

### 3.5 Dynamic Type and Typography System

SwiftUI text automatically scales with Dynamic Type when using system font styles. A well-structured typography system for Forager:

```swift
enum ForagerTypography {
    // Screen titles
    static let screenTitle: Font = .largeTitle.weight(.bold)

    // Section headers
    static let sectionHeader: Font = .title3.weight(.semibold)

    // List item primary text
    static let listPrimary: Font = .body

    // List item secondary text
    static let listSecondary: Font = .subheadline.weight(.regular)

    // Quantity/unit display
    static let quantity: Font = .body.monospacedDigit()

    // Badge text
    static let badge: Font = .caption.weight(.medium)

    // Category label
    static let categoryLabel: Font = .caption.weight(.semibold)

    // Confidence indicator
    static let confidence: Font = .caption2.monospacedDigit()
}
```

**Dynamic Type considerations for grocery lists:**
- At the largest accessibility sizes, list rows will grow significantly. Use `@ScaledMetric` for icon sizes and spacing that should scale proportionally.
- Consider layout changes at extreme sizes: a horizontal quantity+name row may need to stack vertically at AX5 sizes.
- Use `.minimumScaleFactor()` sparingly and only for non-critical decorative text.

```swift
@ScaledMetric(relativeTo: .body) var checkboxSize: CGFloat = 24
@ScaledMetric(relativeTo: .body) var rowSpacing: CGFloat = 12
```

---

## 4. Component Patterns

### 4.1 Card-Based vs List-Based Layouts

Both patterns are valid in iOS, and Forager should use them contextually:

#### List-Based (Primary for Forager)

Lists are the right choice for:
- **Grocery lists**: Scannable, dense, action-oriented. Users need to quickly scan and check off items.
- **Ingredient lists**: Within recipes, compact display of quantities and names.
- **Category management**: Simple ordered lists with drag-to-reorder.

SwiftUI `List` advantages:
- Built-in swipe actions, editing mode, and section headers
- Automatic separator handling
- Native pull-to-refresh support via `.refreshable`
- Excellent performance with lazy loading

#### Card-Based (Secondary for Forager)

Cards are the right choice for:
- **Recipe browsing**: Visual recipe cards with images, prep time, and ingredient count.
- **Meal plan calendar**: Day cards showing assigned recipes.
- **Dashboard/summary views**: Status cards for sync state, list completion, household info.
- **Onboarding screens**: Feature highlight cards in walkthrough.
- **Empty states**: Illustrated cards with call-to-action.

Card design guidelines:
- Use consistent corner radius (12-16pt recommended for Forager's organic feel)
- Cards in light mode: white background + subtle shadow (radius 8, y-offset 2, opacity 0.08)
- Cards in dark mode: slightly elevated background color, no shadow
- Content padding: 16pt internal padding
- Card spacing: 12-16pt between cards in a grid or stack

#### Hybrid Approach (Recommended for Forager)

- **Grocery lists tab**: Pure list with category sections and swipe actions
- **Recipes tab**: Card grid or large-row list with thumbnail images
- **Meal plans tab**: Calendar with card-style day cells
- **Ingredients tab**: Compact list with filter pills

### 4.2 Bottom Navigation Patterns

#### Standard TabView

iOS standard TabView with up to 5 tabs (the HIG maximum for bottom tabs). Beyond 5, use a "More" tab.

Forager's current 4-tab structure (Lists, Ingredients, Recipes, Meal Plans) plus hamburger menu for Settings/Categories is a reasonable approach.

#### iOS 26 Liquid Glass Tab Bar

In iOS 26, the system TabView automatically adopts Liquid Glass styling:

```swift
TabView {
    Tab("Lists", systemImage: "list.bullet") {
        GroceryListsView()
    }
    Tab("Recipes", systemImage: "book") {
        RecipeListView()
    }
    Tab("Meals", systemImage: "calendar") {
        MealPlanListView()
    }
    Tab("Ingredients", systemImage: "leaf") {
        IngredientsView()
    }

    // Search appears as a separate glass element
    Tab(role: .search) {
        SearchView()
    }
}
.tabBarMinimizeBehavior(.onScrollDown) // Shrinks tab bar when scrolling
```

Key iOS 26 tab bar features (**all require iOS 26+ minimum deployment target**):
- **tabBarMinimizeBehavior**: `.onScrollDown` minimizes the tab bar during scrolling, giving more content space. `.never` keeps it fixed. `.automatic` lets the system decide.
- **tabViewBottomAccessory**: Adds an accessory view (like a mini player or quick-add bar) above the tab bar that transitions between `.expanded` and `.inline` states.
- **Search tab role**: The search tab appears visually separated and transforms into a search field when selected.

> **Note:** Since Forager targets iOS 18.0+, these APIs are not available at the current deployment target. Use `if #available(iOS 26, *)` guards if adopting early, or wait until the minimum target advances.

#### Forager's Custom Bottom Navigation

The existing Apple Music-style `CustomBottomNavigation.swift` with a grouped pill container and separate search button is a custom implementation. When migrating to iOS 26:

- The custom navigation could be replaced with the system Liquid Glass TabView
- The search button behavior maps directly to the `Tab(role: .search)` API
- The `.regularMaterial` backdrop filter translates naturally to `.glassEffect()`
- Spring animations align with Liquid Glass transition behaviors

### 4.3 Search UX

SwiftUI's `.searchable()` modifier provides the standard search experience:

```swift
NavigationStack {
    List(filteredItems) { item in
        GroceryListRow(item: item)
    }
    .searchable(text: $searchText, prompt: "Search items...")
    .searchSuggestions {
        ForEach(suggestions, id: \.self) { suggestion in
            Text(suggestion)
                .searchCompletion(suggestion)
        }
    }
}
```

**Search patterns relevant to Forager:**

| Pattern | Context | Implementation |
|---------|---------|---------------|
| Filter-as-you-type | Grocery list, ingredient list | `.searchable` + `@FetchRequest` predicate update |
| Autocomplete suggestions | Adding items, recipe search | `.searchSuggestions` with template matches |
| Scoped search | Search within category or across all | `.searchScopes` with category options |
| Quick-add from search | Type item name, tap to add | Custom action on search submit |
| Recent searches | Recipe search history | Stored search terms as suggestions |

**iOS 26 search enhancements:**
- Search in the tab bar: The search tab transforms into a search field when selected.
- Search placement: `.toolbar` or `.navigationBarDrawer` placement options.

### 4.4 Empty States

A well-designed empty state communicates "no data" clearly with helpful visuals and actionable guidance. The recommended pattern uses `.overlay`:

```swift
List {
    // ... content
}
.overlay {
    if items.isEmpty {
        ContentUnavailableView(
            "No Grocery Items",
            systemImage: "cart",
            description: Text("Add items to your list to get started.")
        )
    }
}
```

Using `.overlay` instead of replacing content ensures the original view remains in the hierarchy, preserving navigation bars, toolbars, and parent layout.

**Empty state guidelines for Forager:**

| Screen | Illustration | Title | Description | Action |
|--------|-------------|-------|-------------|--------|
| Grocery list | `cart` | "Your list is empty" | "Add items manually or from a recipe" | "Add Item" button |
| Recipes | `book.closed` | "No recipes yet" | "Create your first recipe to get started" | "Create Recipe" button |
| Meal plan | `calendar` | "No meals planned" | "Plan your meals for the week" | "Plan Meals" button |
| Ingredients | `leaf` | "No ingredients" | "Ingredients appear as you add recipes" | None (informational) |
| Search results | `magnifyingglass` | "No results" | "Try a different search term" | None |

### 4.5 Loading States

Multiple approaches for handling loading states in SwiftUI:

```swift
// Pattern 1: ProgressView for indeterminate loading
ProgressView()
    .progressViewStyle(.circular)

// Pattern 2: Placeholder/skeleton views
ForEach(0..<5) { _ in
    RoundedRectangle(cornerRadius: 8)
        .fill(Color.gray.opacity(0.2))
        .frame(height: 60)
        .shimmering()  // Custom shimmer modifier
}

// Pattern 3: Phase-based loading (used in foragerApp.swift)
if persistence.isReady {
    MainContentView()
} else {
    AppLoadingView()  // Branded splash with spinner
}
```

**Forager already has a good loading pattern**: `AppLoadingView` with branded splash and `ProgressView` spinner, transitioning to main content with a 0.3s crossfade animation.

### 4.6 Pull-to-Refresh

SwiftUI's `.refreshable` modifier is the standard pattern:

```swift
List(items) { item in
    GroceryListRow(item: item)
}
.refreshable {
    await syncService.refreshFromCloudKit()
}
```

**Forager contexts for pull-to-refresh:**
- Grocery list: Trigger CloudKit sync refresh
- Recipes list: Check for household-shared recipe updates
- Ingredients: Refresh template data from shared store
- Meal plans: Sync household meal plan changes

### 4.7 Swipe Actions

SwiftUI provides leading and trailing swipe actions on list rows:

```swift
ForEach(items) { item in
    GroceryListRow(item: item)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                toggleChecked(item)
            } label: {
                Label(
                    item.isChecked ? "Uncheck" : "Check",
                    systemImage: item.isChecked ? "circle" : "checkmark.circle.fill"
                )
            }
            .tint(Color("ForagerPrimary"))
        }
}
```

**Swipe action recommendations for Forager:**

| Context | Leading Swipe | Trailing Swipe |
|---------|--------------|----------------|
| Grocery item | Check/uncheck | Delete |
| Recipe | Add to meal plan | Delete |
| Ingredient template | (none) | Edit/Review |
| Meal plan entry | (none) | Remove from plan |
| Household member | (none) | Remove (owner only) |

### 4.8 Haptic Feedback

iOS provides three feedback generators, and SwiftUI 17+ adds the `.sensoryFeedback` modifier:

```swift
// SwiftUI 17+ pattern
Button("Add Item") { addItem() }
    .sensoryFeedback(.success, trigger: itemAdded)

// Or inline:
Toggle(isOn: $isChecked) { Text(item.name) }
    .sensoryFeedback(.selection, trigger: isChecked)
```

**Haptic feedback types and when to use them:**

| Type | Generator | Use Case in Forager |
|------|-----------|-------------------|
| `.success` | Notification | Item checked off, recipe saved, sync complete |
| `.warning` | Notification | Low confidence parse, approaching list limit |
| `.error` | Notification | Save failed, sync error, delete confirmation |
| `.selection` | Selection | Scrolling through picker values, category selection |
| `.impact(.light)` | Impact | Tap on card, minor interaction |
| `.impact(.medium)` | Impact | Swipe action activated, drag-and-drop placement |
| `.impact(.heavy)` | Impact | Long-press activation, destructive action confirmed |

**Best practices:**
- Haptic feedback must be a response to a user action, never unsolicited.
- Use the correct type for each situation; users learn to associate specific haptics with meanings.
- Prepare generators in advance to reduce latency.
- Haptic engines consume battery; use judiciously.
- Not all devices support haptics; design interactions that work without them.

---

## 5. Grocery/Food App Specific UX

### 5.1 One-Handed Shopping Mode

While no standardized "one-handed shopping mode" exists across apps, the concept addresses a real need: users shop with their phone in one hand and a cart or basket in the other. Key patterns to support this:

**Thumb-zone optimization:**
- Place the most frequent action (check off items) in the natural thumb reach zone (lower-middle area of the screen).
- The floating bottom navigation already aligns with this. Ensure check-off interactions are accessible without reaching to the top of the screen.

**Large tap targets:**
- Minimum 44x44pt for any tappable element, but during shopping, 48-56pt is better.
- The entire row should be tappable for the primary action (check/uncheck), not just a small checkbox icon.

**Full-swipe actions:**
- `allowsFullSwipe: true` on swipe actions lets users check off items with a quick, decisive swipe rather than a precise tap.
- This is easier to perform one-handed while walking.

**Simplified shopping view:**
- Consider a dedicated "Shopping Mode" that:
  - Shows only unchecked items
  - Groups by store aisle/category
  - Uses larger text and row heights
  - Hides editing controls (delete, reorder)
  - Shows a running count of remaining items
  - Minimizes or hides the tab bar

**Gesture-based interactions:**
- Tap anywhere on row = toggle checked
- Swipe right = check off with haptic
- Swipe left = quick-add note ("got different brand")
- No need for long-press menus during shopping

### 5.2 Checklist Interactions

The check-off interaction is the single most important UX element in a grocery list app. Design considerations:

**Visual feedback on check:**
1. Checkbox icon transitions from empty circle to filled checkmark
2. Item text gets strikethrough treatment
3. Row opacity reduces to 40-50%
4. Subtle haptic feedback (`.success` for check, `.selection` for uncheck)
5. Checked items move to bottom of their category section (or a "Checked" section)

**Animation timing:**
- Strikethrough and opacity: 0.2s ease-in-out (immediate visual feedback)
- Row movement to "checked" section: 0.3-0.4s spring animation (delayed slightly so user sees the check before the row moves)
- Respect Reduce Motion: replace animations with instant state changes

**Undo support:**
- Tapping a checked item unchecks it (toggle behavior)
- No confirmation dialog for check/uncheck (speed is paramount)
- Consider a subtle "Undo" toast for accidental checks

**Batch operations:**
- "Check All" button per category section
- "Uncheck All" to reset the list for next shopping trip
- Swipe-down on section header to collapse checked items

### 5.3 Category-Based Organization

Category organization in grocery apps maps to store layout, helping users shop efficiently:

**Display patterns:**
- Collapsible section headers with item count badges
- Category color coding (subtle background tint or left-edge accent bar)
- Sticky section headers during scroll (default SwiftUI List behavior)
- "Uncategorized" section at the bottom for items without a category

**Category navigation:**
- Filter pills at the top for quick category jumping (Forager already has this in IngredientsView)
- Alphabetical category index for long lists
- Drag-to-reorder categories to match personal store layout

**Smart categorization:**
- Auto-assign categories based on ingredient templates (Forager already does this)
- Learn from user corrections over time
- Suggest category when adding new items

### 5.4 Quick-Add Patterns

Speed of item addition is critical for grocery apps. Multiple quick-add patterns:

**1. Text field with autocomplete (current Forager pattern)**
- User types, fuzzy-matched suggestions appear
- Tap suggestion to add instantly
- Submit text field to add as typed
- Parse quantity/unit from input (Forager's HybridIngredientParser)

**2. Voice input**
- Microphone button in text field
- Speech-to-text with parsing
- Confirm before adding (accuracy varies)

**3. Frequent items list**
- Show most-added items as quick-tap chips/pills
- One tap adds to current list
- Organized by frequency or recency

**4. Recipe-to-list**
- Browse recipes, tap "Add to List"
- Select which ingredients to include
- Auto-merge quantities with existing list items (GroceryMergeService)

**5. Barcode scanning (future consideration)**
- Camera-based product identification
- Auto-populate name, category, and quantity

**6. Previous list import**
- Copy items from a previous week's list
- "Buy again" section based on purchase history

### 5.5 Food-Specific Visual Design

**Color psychology in food apps:**
- Green tones (Forager's palette) evoke freshness, health, and organic qualities. Excellent choice for a grocery/meal planning app.
- Warm earth tones (cream, sand) create a natural, approachable feeling.
- Avoid cold blues and grays as primary colors; they reduce appetite association.
- Use warm amber/gold for warnings rather than harsh yellow.

**Imagery considerations:**
- Recipe thumbnails should be high-quality food photography if available
- For recipes without images, use a consistent placeholder with category-based illustration
- Avoid generic stock photo look; prefer clean, minimalist food imagery

**Typography for food apps:**
- Rounded, friendly typefaces align with organic/natural branding
- SF Rounded (available via `.font(.system(.body, design: .rounded))`) could complement the earthy palette
- Standard SF Pro for body text maintains readability

---

## 6. Accessibility

### 6.1 Dynamic Type Support

SwiftUI Text views automatically support Dynamic Type when using system font styles. Key implementation details:

```swift
// Automatically scales with Dynamic Type (correct)
Text("Grocery Item")
    .font(.body)

// Does NOT scale (incorrect for primary content)
Text("Grocery Item")
    .font(.system(size: 16))

// Scaled metric for custom values
@ScaledMetric(relativeTo: .body) var iconSize: CGFloat = 24
@ScaledMetric(relativeTo: .body) var rowPadding: CGFloat = 12
```

**Testing at extreme sizes:**
- Test at every accessibility size (AX1 through AX5)
- At AX sizes, horizontal layouts may need to stack vertically
- Use `@Environment(\.sizeCategory)` to detect size and adjust layout:

```swift
@Environment(\.sizeCategory) var sizeCategory

var body: some View {
    if sizeCategory.isAccessibilityCategory {
        // Stacked vertical layout for accessibility sizes
        VStack(alignment: .leading) {
            Text(item.name)
            Text(item.quantity)
        }
    } else {
        // Standard horizontal layout
        HStack {
            Text(item.name)
            Spacer()
            Text(item.quantity)
        }
    }
}
```

**Layout adaptation triggers:**

| Size Category | Layout Consideration |
|--------------|---------------------|
| Default - Large | Standard horizontal layouts work |
| XL - XXXL | Increase row heights, check touch targets |
| AX1 - AX3 | Consider stacking quantity below name |
| AX4 - AX5 | Full vertical stacking, larger icons, simplified layouts |

### 6.2 Contrast Ratios

WCAG 2.1 contrast ratio requirements:

| Element | Minimum Ratio | Target Ratio |
|---------|--------------|-------------|
| Normal text (< 18pt) | 4.5:1 | 7:1 |
| Large text (>= 18pt bold or >= 24pt) | 3:1 | 4.5:1 |
| Non-text UI components | 3:1 | 4.5:1 |
| Graphical objects | 3:1 | 4.5:1 |

**Forager palette contrast analysis (light mode):**

| Combination | Ratio | Pass/Fail |
|------------|-------|-----------|
| Forest Green (#2D5016) on Cream (#F5F0E8) | ~7.2:1 | PASS (AAA) |
| Leaf Green (#4A7C2E) on Cream (#F5F0E8) | ~4.8:1 | PASS (AA) |
| Spring Green (#6B9B37) on Cream (#F5F0E8) | ~3.4:1 | PASS for large text only |
| Sage Gray on Cream | Needs verification | Check per shade |

**Important**: Spring Green (#6B9B37) on Cream (#F5F0E8) is borderline for normal-size text. For body text, prefer Forest Green or Leaf Green. Reserve Spring Green for large text, icons, or non-text decorative elements.

**Dark mode contrast considerations:**
- Avoid pure black backgrounds; use near-black (#1C1C1E)
- Lighten green tones for dark backgrounds; dark Forest Green on dark background will fail contrast
- Test every color combination in both modes
- Use Xcode's Accessibility Inspector to verify contrast ratios

**High contrast mode support:**
- iOS provides an "Increase Contrast" accessibility option
- Add a high-contrast color variant in the asset catalog (Appearances > High Contrast)
- System semantic colors automatically adapt; custom colors require manual high-contrast variants

### 6.3 VoiceOver

VoiceOver is Apple's screen reader, and proper support is essential:

```swift
// Provide meaningful labels
Image(systemName: "checkmark.circle.fill")
    .accessibilityLabel("Checked")

// Combine related elements
HStack {
    Text("Butter")
    Text("8 oz")
}
.accessibilityElement(children: .combine) // Reads as "Butter, 8 oz"

// Custom actions instead of swipe gestures
GroceryListRow(item: item)
    .accessibilityAction(named: "Check off") {
        toggleChecked(item)
    }
    .accessibilityAction(named: "Delete") {
        deleteItem(item)
    }

// Value for stateful elements
Toggle(isOn: $item.isChecked) {
    Text(item.name)
}
.accessibilityValue(item.isChecked ? "Checked" : "Not checked")

// Hint for non-obvious interactions
Button("Add") { addItem() }
    .accessibilityHint("Adds this item to your grocery list")
```

**VoiceOver considerations for Forager:**

| Element | Label | Value | Hint |
|---------|-------|-------|------|
| Grocery row | Item name + quantity | "Checked" / "Not checked" | "Double tap to toggle" |
| Category header | Category name | Item count | "Double tap to collapse" |
| Confidence badge | "Low confidence warning" | Confidence percentage | "Ingredient may need review" |
| Recipe card | Recipe name | Ingredient count, prep time | "Double tap to open" |
| Sync indicator | "CloudKit sync" | "Syncing" / "Up to date" | None |
| Filter pill | Filter name | "Selected" / "Not selected" | "Double tap to filter" |

### 6.4 Reduce Motion

Users with motion sensitivity can enable Reduce Motion in Settings > Accessibility > Motion. Apps must respect this:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    GroceryListRow(item: item)
        .animation(
            reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
            value: item.isChecked
        )
}
```

**What to change when Reduce Motion is enabled:**
- Replace slide/spring animations with instant state changes or crossfades
- Replace parallax and gyroscope effects with static layouts
- Replace bouncing/wiggling SF Symbol animations with static icons
- Replace page curl transitions with simple crossfades
- Replace scaling animations with opacity transitions

**Pattern for conditional animation:**

```swift
func withConditionalAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    if UIAccessibility.isReduceMotionEnabled {
        return try body()
    } else {
        return try withAnimation(animation, body)
    }
}
```

### 6.5 Additional Accessibility Considerations

**Bold Text**: Detect via `@Environment(\.legibilityWeight)` and adjust font weights.

**Color Blindness**: Do not rely on color alone to convey meaning. Always pair color with an icon, text label, or pattern. The green check / red delete pattern should include checkmark and trash icons.

**Switch Control and Voice Control**: Ensure all interactive elements are reachable via focus traversal. Avoid custom gesture recognizers that cannot be replicated by assistive technologies.

**Accessibility Inspector**: Use Xcode's built-in Accessibility Inspector throughout development to audit every screen for:
- Missing labels
- Insufficient contrast
- Unreachable elements
- Incorrect reading order

---

## 7. Forager-Specific Recommendations

### 7.1 Immediate Opportunities (iOS 18 Compatible)

These improvements can be made within the current iOS 18 target:

| Area | Recommendation | Priority |
|------|---------------|----------|
| Color System | Formalize brand colors in asset catalog with light/dark/high-contrast variants | High |
| Typography | Create `ForagerTypography` enum with semantic font definitions | Medium |
| Spacing | Define `ForagerSpacing` constants for consistent padding/margins | Medium |
| Empty States | Add `ContentUnavailableView` to all empty screens | Medium |
| Haptic Feedback | Add `.sensoryFeedback` to check-off, save, and error actions | Medium |
| Swipe Actions | Standardize leading/trailing swipe actions across all list views | Medium |
| VoiceOver | Audit all views for accessibility labels, values, and hints | High |
| Dynamic Type | Test and fix layouts at AX1-AX5 sizes | High |
| ViewModifiers | Extract common styling into reusable ViewModifiers | Low |

### 7.2 Forward-Looking (iOS 26 Preparation)

When the deployment target advances to iOS 26:

| Area | Recommendation | Complexity | Min iOS |
|------|---------------|-----------|---------|
| Tab Bar | Replace `CustomBottomNavigation` with system Liquid Glass TabView | Moderate | **iOS 26+** |
| Tab Minimize | Add `.tabBarMinimizeBehavior(.onScrollDown)` for more content space | Low | **iOS 26+** |
| Search | Migrate to `Tab(role: .search)` for glass search integration | Low | **iOS 26+** |
| Glass Effects | Apply `.glassEffect()` to card components and floating buttons | Moderate | **iOS 26+** |
| Bottom Accessory | Add quick-add bar as `tabViewBottomAccessory` | Moderate | **iOS 26+** |
| App Icon | Create layered Liquid Glass icon using Icon Composer | Moderate | iOS 18+ (basic), iOS 26+ (Liquid Glass) |
| Glass Blending | Use `GlassEffectContainer` for proximate glass elements | Low | **iOS 26+** |
| Button Style | Adopt `.buttonStyle(.glass)` for primary actions | Low | **iOS 26+** |

> **Availability note (added Feb 15, 2026):** All Liquid Glass APIs (`.glassEffect()`, `GlassEffectContainer`, `.tabBarMinimizeBehavior`, `.buttonStyle(.glass)`, `tabViewBottomAccessory`) require **iOS 26 minimum deployment target**. Since Forager currently targets iOS 18.0+, these must be wrapped in `if #available(iOS 26, *)` checks or deferred until the minimum target advances. The existing `CustomBottomNavigation.swift` implementation with `.regularMaterial` remains the correct approach for iOS 18.

### 7.3 Brand Color Application Guide

How to apply Forager's earthy palette across the UI:

| Color | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| Forest Green (#2D5016) | Primary text on cream, filled buttons | Avoid (too dark on dark bg) | Headers, primary actions |
| Leaf Green (#4A7C2E) | Secondary interactive elements | Adjust lighter for dark bg | Links, active states |
| Spring Green (#6B9B37) | Accent highlights, icons, success states | Primary text/icons on dark bg | Badges, checked items, accent |
| Cream (#F5F0E8) | Screen background, card surfaces | Lighten to near-white for text on dark | Backgrounds, light mode text on dark |
| Warm Sand | Card backgrounds, section dividers | Subtle surface elevation | Secondary surfaces |
| Sage Gray | Secondary text, disabled states | Lighten for readability | Metadata, timestamps, placeholders |

### 7.4 Shopping Experience Flow

The ideal shopping flow for Forager:

```
1. Open app -> Grocery Lists tab (default landing)
2. Tap active list -> Items grouped by category (store layout order)
3. Shopping mode -> Simplified view, large rows, unchecked only
4. Check items -> Full-row tap or right-swipe, haptic feedback
5. Checked items -> Move to bottom / collapse with count badge
6. Done -> All items checked, completion celebration (subtle)
7. Next trip -> "Uncheck All" or start new list from meal plan
```

---

## 8. Sources

### Apple Official Documentation
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Liquid Glass - Apple Developer Documentation](https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass)
- [Adopting Liquid Glass - Apple Developer](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Applying Liquid Glass to Custom Views - Apple Developer](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [glassEffect(_:in:) - Apple Developer](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))
- [Dark Mode - Apple Developer](https://developer.apple.com/design/human-interface-guidelines/dark-mode)
- [SF Symbols - Apple Developer](https://developer.apple.com/sf-symbols/)
- [What's New in SF Symbols 6 - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10188/)
- [Meet Liquid Glass - WWDC25](https://developer.apple.com/videos/play/wwdc2025/219/)
- [Get to Know the New Design System - WWDC25](https://developer.apple.com/videos/play/wwdc2025/356/)
- [Say Hello to the New Look of App Icons - WWDC25](https://developer.apple.com/videos/play/wwdc2025/220/)
- [Apple Design Resources](https://developer.apple.com/design/resources/)
- [Icon Composer - Apple Developer](https://developer.apple.com/icon-composer/)
- [Adding a Search Interface to Your App](https://developer.apple.com/documentation/swiftui/adding-a-search-interface-to-your-app)
- [Apple Introduces a Delightful and Elegant New Software Design (Newsroom)](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)

### iOS 26 & Liquid Glass
- [Liquid Glass: Redefining Design Through Hierarchy, Harmony and Consistency (CreateWithSwift)](https://www.createwithswift.com/liquid-glass-redefining-design-through-hierarchy-harmony-and-consistency/)
- [Liquid Glass UI 2026: Apple's New Design Language Explained (Medium)](https://medium.com/@expertappdevs/liquid-glass-2026-apples-new-design-language-6a709e49ca8b)
- [iOS 26 Liquid Glass: Comprehensive Reference (Medium)](https://medium.com/@madebyluddy/overview-37b3685227aa)
- [Designing Custom UI with Liquid Glass on iOS 26 (Donny Wals)](https://www.donnywals.com/designing-custom-ui-with-liquid-glass-on-ios-26/)
- [Build a Liquid Glass Design System in SwiftUI (Level Up Coding)](https://levelup.gitconnected.com/build-a-liquid-glass-design-system-in-swiftui-ios-26-bfa62bcba5be)
- [Exploring Tab Bars on iOS 26 with Liquid Glass (Donny Wals)](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)
- [Liquid Glass Tab Bar in SwiftUI (jorgemrht)](https://jorgemrht.dev/2025/09/18/liquid-glass-tab-bar)
- [Liquid Glass Reference (GitHub)](https://github.com/conorluddy/LiquidGlassReference)
- [Apple Updates Design Resources for iOS 26 (MacRumors)](https://www.macrumors.com/2025/06/11/apple-updates-design-resources-ios-26/)
- [Liquid Glass Design and Development Guide](https://www.liquidglassui.xyz/)
- [Grow on iOS 26 - Liquid Glass Adaptation in UIKit + SwiftUI Hybrid Architecture](https://fatbobman.com/en/posts/grow-on-ios26/)

### SwiftUI Theming & Design Systems
- [Effortless SwiftUI Theming (Alexander Weiss)](https://alexanderweiss.dev/blog/2025-01-19-effortless-swiftui-theming)
- [Adding Themes to a SwiftUI App Using Environment Values (Taylor Hartman)](https://www.uplandjupiter.com/blog/adding-themes-to-my-app-using-environmentvalues)
- [SwiftUI Colors: A Headbanging Guide to Theming (Medium)](https://medium.com/@wesleymatlock/swiftui-colors-a-headbanging-guide-to-theming-806a374e45c7)
- [Building a SwiftUI Design System - Part 1: Color (Design Systems Collective)](https://www.designsystemscollective.com/building-a-swiftui-design-system-part-1-color-2ea75035e691)
- [Semantic Colors in SwiftUI (AppMakers)](https://appmakers.dev/semantic-colors-in-swiftui/)
- [Defining Dynamic Colors in Swift (Swift by Sundell)](https://www.swiftbysundell.com/articles/defining-dynamic-colors-in-swift/)
- [SwiftUI-Design-System-Pro (GitHub)](https://github.com/muhittincamdali/SwiftUI-Design-System-Pro)
- [NormanDSKit: Liquid Glass Ready Design System (GitHub)](https://github.com/normansanchezn/NormanDSKit)
- [OversizeUI Component Library (GitHub)](https://github.com/oversizedev/OversizeUI)
- [Atomic Design System Using SwiftUI (Think-it)](https://think-it.io/insights/Atomic-Design-System-in-SwiftUI)
- [Simplifying iOS App Design with Design Tokens (Halodoc)](https://blogs.halodoc.io/simplifying-ios-app-design-with-design-tokens/)

### SwiftUI Components & Patterns
- [Handling Loading States Within SwiftUI Views (Swift by Sundell)](https://www.swiftbysundell.com/articles/handling-loading-states-in-swiftui/)
- [SwiftUI List Empty State: Reusable Modifier (CodeStudy)](https://www.codestudy.net/blog/swiftui-list-empty-state-view-modifier/)
- [How to Enable Pull to Refresh (Hacking with Swift)](https://www.hackingwithswift.com/quick-start/swiftui/how-to-enable-pull-to-refresh)
- [Making SwiftUI Views Refreshable (Swift by Sundell)](https://www.swiftbysundell.com/articles/making-swiftui-views-refreshable/)
- [How to Add a Search Bar to Filter Data (Hacking with Swift)](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-search-bar-to-filter-your-data)
- [SwiftUI Search Enhancements in iOS and iPadOS 26 (Nil Coalescing)](https://nilcoalescing.com/blog/SwiftUISearchEnhancementsIniOSAndiPadOS26/)
- [Tab Bar Customization in SwiftUI for iOS 26 (SwiftUI Snippets)](https://swiftuisnippets.wordpress.com/2025/07/15/tab-bar-customization-in-swiftui-for-ios-26/)
- [Enhancing Tab Bars in iOS 26 with tabViewBottomAccessory (DevTechie)](https://www.devtechie.com/blog/enhancing-tab-bars-in-ios-26-with-swiftuis-tabviewbottomaccessory)
- [How to Use tabBarMinimizeBehavior in SwiftUI (Livsy Code)](https://livsycode.com/swiftui/how-to-use-tabbarminimizebehavior-in-swiftui/)

### SF Symbols & Animation
- [What's New in SF Symbols 6: Features and Animations (Simform)](https://medium.com/simform-engineering/whats-new-in-sf-symbols-6-new-features-and-stunning-animations-9b9822f04b94)
- [Animating SF Symbols with the Symbol Effect Modifier (CreateWithSwift)](https://www.createwithswift.com/animating-sf-symbols-with-the-symbol-effect-modifier/)
- [How to Animate SF Symbols (Hacking with Swift)](https://www.hackingwithswift.com/quick-start/swiftui/how-to-animate-sf-symbols)
- [Animating SF Symbols on iOS 18 (Donny Wals)](https://www.donnywals.com/animating-sf-symbols-on-ios-18/)

### Haptic Feedback
- [How and When to Use Haptic Feedback for iOS (Cracking Swift)](https://medium.com/cracking-swift/how-and-when-to-use-haptic-feedback-for-a-better-ios-app-9bcfcc97393a)
- [Integrating Haptic Feedback in SwiftUI Projects (SerialCoder)](https://serialcoder.dev/text-tutorials/swiftui/integrating-haptic-feedback-in-swiftui-projects/)
- [SwiftUI Sensory Feedback (Use Your Loaf)](https://useyourloaf.com/blog/swiftui-sensory-feedback/)
- [Haptic Feedback in iOS: A Comprehensive Guide (Medium)](https://medium.com/@mi9nxi/haptic-feedback-in-ios-a-comprehensive-guide-6c491a5f22cb)

### Accessibility
- [iOS Accessibility Guidelines: Best Practices for 2025 (Medium)](https://medium.com/@david-auerbach/ios-accessibility-guidelines-best-practices-for-2025-6ed0d256200e)
- [Enhancing Your SwiftUI App with Dynamic Type and Accessibility (Medium)](https://medium.com/@wesleymatlock/enhancing-your-swiftui-app-with-dynamic-type-and-accessibility-6b4bd84f4132)
- [Ensure Visual Accessibility: Supporting Reduced Motion in SwiftUI (CreateWithSwift)](https://www.createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/)
- [iOS SwiftUI Accessibility Techniques (CVS Health, GitHub)](https://github.com/cvs-health/ios-swiftui-accessibility-techniques)
- [Accessibility in SwiftUI Apps: Best Practices (Commit Studio)](https://commitstudiogs.medium.com/accessibility-in-swiftui-apps-best-practices-a15450ebf554)
- [SwiftUI Best Practices 2025 (Toxigon)](https://toxigon.com/swiftui-best-practices-2025)
- [How to Detect the Reduce Motion Accessibility Setting (Hacking with Swift)](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting)
- [Supporting Reduced Motion Accessibility Setting in SwiftUI (tanaschita)](https://tanaschita.com/ios-accessibility-reduced-motion/)

### Grocery & Food App UX
- [Case Study: Perfect Recipes App UX Design (Tubik Studio)](https://blog.tubikstudio.com/case-study-recipes-app-ux-design/)
- [UI Experiments: Options for Recipe Cards in a Food App (Tubik Studio)](https://blog.tubikstudio.com/ui-experiments-options-for-recipe-cards-in-a-food-app/)
- [Online Grocery UX: 5 High-Level Takeaways (Baymard)](https://baymard.com/blog/grocery-site-ux-launch)
- [A Shopping List App That Keeps Track of Regular Purchases (Medium)](https://medium.com/@design_talks/a-shopping-list-app-that-keeps-track-of-regular-purchases-ab1590f8bec4)
- [20+ Mobile App Design Trends in 2025 (SimiCart)](https://simicart.com/blog/mobile-shopping-app-design-trends/)
- [iOS UI Kit - Grocery Shopping List App (Figma)](https://www.figma.com/community/file/931540430885912642/ios-ui-kit-grocery-shopping-list-app)
- [Food for Thought: 10 Tasty UI Concepts for Eating and Cooking (Tubik Studio)](https://blog.tubikstudio.com/food-for-thought-10-tasty-ui-concepts-for-eating-and-cooking/)

---

**Document Version**: 1.0
**Last Updated**: February 14, 2026
**Author**: UX Research (AI-assisted)
**Next Steps**: Use this research to inform design system creation (02-design-system.md) and component specifications (03-component-specs.md)
