# RecipePickerSheet UI Redesign Proposal

**Current Status**: Functional but cluttered  
**Goal**: Clean, scannable, iOS-native feel

---

## 🎨 Design Principles

1. **Hierarchy**: Most important info (recipe name) should be largest
2. **Scannability**: Quick visual identification of recipes
3. **Efficiency**: Common case (default servings) should be fast
4. **Flexibility**: Still allow servings adjustment when needed

---

## Option 1: Simplified Rows with Expandable Details

### Visual Mock
```
┌─────────────────────────────────────┐
│ Cancel          Add Recipe          │ ← Simplified title
├─────────────────────────────────────┤
│ 🗓️  Adding to Thu, Nov 6           │ ← Compact banner
├─────────────────────────────────────┤
│ 🔍 Search recipes                   │
├─────────────────────────────────────┤
│                                     │
│ 🍴 Bow Tie Pasta            →       │ ← Clean, simple
│    3 ingredients • 4 servings       │ ← Metadata as subtitle
│                                     │
│ 🍴 Cheesesteaks             →       │
│    1 ingredient • 4 servings        │
│                                     │
│ 🍴 Test Recipe              →       │
│    3 ingredients • 4 servings       │
│                                     │
│ 🍴 White Chicken Chili      →       │
│    2 ingredients • 4 servings       │
│                                     │
└─────────────────────────────────────┘
```

**Behavior**:
- Tap recipe → Show confirmation sheet with servings adjuster
- Default servings used if just tap
- Two-tap flow: Select → Confirm & Adjust

**Pros**:
- Clean, scannable list
- Fast for default servings (most common case)
- Familiar iOS pattern (select → confirm)

**Cons**:
- Extra tap if adjusting servings

---

## Option 2: Inline Servings on Selection (Recommended)

### Visual Mock
```
┌─────────────────────────────────────┐
│ Cancel          Add Recipe          │
├─────────────────────────────────────┤
│ 📅 Adding to Thu, Nov 6             │ ← Icon + compact
├─────────────────────────────────────┤
│ 🔍 Search recipes                   │
├─────────────────────────────────────┤
│                                     │
│ 🍴 Bow Tie Pasta            →       │
│    3 ingredients • Serves 4         │
│                                     │
│ 🍴 Cheesesteaks             →       │ ← Selected
│    1 ingredient • Serves 4          │
│    ┌───────────────────────────┐   │ ← Expanded
│    │ Servings:    ➖  4  ➕    │   │
│    │                           │   │
│    │        [Add to Plan]      │   │
│    └───────────────────────────┘   │
│                                     │
│ 🍴 Test Recipe              →       │
│    3 ingredients • Serves 4         │
│                                     │
└─────────────────────────────────────┘
```

**Behavior**:
- Tap recipe → Expands inline with servings + Add button
- Tap another → Collapses previous, expands new
- One-tap to select, see servings, then Add

**Pros**:
- Context stays in place
- No modal-over-modal
- Adjust servings without extra navigation
- Visual feedback on selection

**Cons**:
- Slightly more complex implementation

---

## Option 3: Bottom Sheet with Preview (Most Modern)

### Visual Mock
```
┌─────────────────────────────────────┐
│              Add Recipe             │ ← Centered
├─────────────────────────────────────┤
│ 📅 Thu, Nov 6                       │ ← Minimal
├─────────────────────────────────────┤
│ 🔍 Search                           │
├─────────────────────────────────────┤
│                                     │
│ 🍴 Bow Tie Pasta                    │ ← Just name
│ 🍴 Cheesesteaks                     │ ← Simple list
│ 🍴 Test Recipe                      │
│ 🍴 White Chicken Chili              │
│                                     │
└─────────────────────────────────────┘

[User taps "Cheesesteaks"]

┌─────────────────────────────────────┐
│              Add Recipe             │
├─────────────────────────────────────┤
│ [List dimmed in background]         │
│                                     │
│ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│ ┃ 🍴 Cheesesteaks               ┃ │ ← Bottom sheet
│ ┃                               ┃ │
│ ┃ 📅 Thu, Nov 6                 ┃ │
│ ┃ 🥘 1 ingredient               ┃ │
│ ┃ 👥 Serves 4                   ┃ │
│ ┃                               ┃ │
│ ┃ Servings:      ➖  4  ➕      ┃ │
│ ┃                               ┃ │
│ ┃        [Add to Plan]          ┃ │
│ ┃        [Cancel]               ┃ │
│ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
└─────────────────────────────────────┘
```

**Behavior**:
- Tap recipe → Bottom sheet slides up
- Shows recipe preview + servings
- Tap outside → Dismiss, select another
- Native iOS pattern (like Apple Music)

**Pros**:
- Most modern iOS feel
- Clear selection state
- Recipe preview before adding
- Familiar interaction pattern

**Cons**:
- More complex implementation
- Requires bottom sheet library or custom view

---

## 📊 Recommendation: Option 2 (Inline Expansion)

**Why**:
1. ✅ **Best balance** of simplicity and functionality
2. ✅ **No extra navigation** - everything in one screen
3. ✅ **Familiar pattern** - like expandable lists in Settings app
4. ✅ **Quick for power users** - see servings immediately
5. ✅ **Moderate complexity** - achievable without custom components

**Key Improvements**:
- Simplified recipe rows (remove clutter)
- Inline servings adjustment (no modal-over-modal)
- Better date banner (more prominent but compact)
- Clear selected state (blue background on expansion)
- Single "Add to Plan" button (clear action)

---

## 🎨 Detailed Design Specs for Option 2

### Date Banner
```swift
HStack(spacing: 8) {
    Image(systemName: "calendar")
        .font(.title3)
        .foregroundColor(.blue)
    
    Text("Adding to \(formattedDate)")
        .font(.headline)
    
    Spacer()
}
.padding()
.background(Color.blue.opacity(0.1))
```

**Changes**:
- Larger icon (title3 vs system default)
- Headline font (more prominent)
- Light blue background (stands out)
- Shorter text format ("Thu, Nov 6" instead of full date)

### Recipe Row (Collapsed)
```swift
VStack(alignment: .leading, spacing: 4) {
    HStack {
        Image(systemName: "fork.knife")
            .foregroundColor(.blue)
        
        Text("Bow Tie Pasta")
            .font(.body)
            .fontWeight(.medium)
        
        Spacer()
        
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    Text("3 ingredients • Serves 4")
        .font(.caption)
        .foregroundColor(.secondary)
}
.padding()
.background(Color(UIColor.secondarySystemGroupedBackground))
.cornerRadius(10)
```

**Changes**:
- Remove extra labels (cleaner)
- Single line metadata (compact)
- Rounded corners (modern feel)
- Better spacing

### Recipe Row (Expanded)
```swift
VStack(alignment: .leading, spacing: 12) {
    // Header (same as collapsed)
    HStack {
        Image(systemName: "fork.knife")
            .foregroundColor(.blue)
        Text("Cheesesteaks")
            .font(.body)
            .fontWeight(.semibold) // Bold when selected
        Spacer()
    }
    
    Text("1 ingredient • Serves 4")
        .font(.caption)
        .foregroundColor(.secondary)
    
    Divider()
    
    // Servings adjuster
    HStack {
        Text("Servings:")
            .font(.subheadline)
        
        Spacer()
        
        Button { /* decrease */ } label: {
            Image(systemName: "minus.circle.fill")
                .font(.title2)
        }
        
        Text("4")
            .font(.title3)
            .fontWeight(.semibold)
            .frame(minWidth: 40)
        
        Button { /* increase */ } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
        }
    }
    
    // Add button
    Button {
        // Add to plan
    } label: {
        Text("Add to Plan")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
    }
}
.padding()
.background(Color.blue.opacity(0.1)) // Highlight selected
.cornerRadius(10)
.overlay(
    RoundedRectangle(cornerRadius: 10)
        .stroke(Color.blue, lineWidth: 2) // Blue border
)
```

**Changes**:
- Blue tinted background (shows selection)
- Blue border (clear selected state)
- Larger servings buttons (easier to tap)
- Prominent "Add to Plan" button
- Divider for visual separation

### Empty State (If No Recipes)
```swift
VStack(spacing: 16) {
    Image(systemName: "fork.knife.circle")
        .font(.system(size: 64))
        .foregroundColor(.secondary)
    
    Text("No Recipes Yet")
        .font(.title2)
        .fontWeight(.semibold)
    
    Text("Create recipes in the Recipes tab\nto add them to your meal plan")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    
    Button("Go to Recipes") {
        // Dismiss and switch to Recipes tab
    }
    .buttonStyle(.borderedProminent)
}
```

**Changes**:
- Larger icon
- Better copy
- Action button to navigate to Recipes tab

---

## 💻 Implementation Approach

### Phase 1: Simplify (15 min)
1. Remove servings adjuster from every row
2. Simplify recipe row to just name + metadata
3. Improve date banner styling

### Phase 2: Add Expansion (20 min)
1. Add @State for selected recipe
2. Show expanded view when recipe tapped
3. Collapse previous when new one selected

### Phase 3: Polish (10 min)
1. Add animations for expand/collapse
2. Blue highlight for selected
3. Better spacing and sizing

**Total**: ~45 minutes

---

## 🎯 Success Criteria

**Before** (Current):
- Cluttered rows with all info upfront
- Servings adjusters everywhere
- Hard to scan quickly
- Feels busy

**After** (Improved):
- Clean, scannable list
- Quick selection with one tap
- Servings only when needed
- Modern iOS feel
- Clear visual hierarchy

---

## 📱 Mobile-First Considerations

1. **Thumb Zone**: "Add to Plan" button in easy reach
2. **Tap Targets**: All buttons min 44pt
3. **Scrolling**: List should scroll smoothly even with 20+ recipes
4. **Animations**: Subtle expand/collapse for polish

---

Would you like me to implement **Option 2 (Inline Expansion)** with the detailed specs above?

**Or** would you prefer a different option (1 or 3)?

Let me know and I'll code it up! 🚀