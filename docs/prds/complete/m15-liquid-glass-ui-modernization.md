# M15: Liquid Glass UI Modernization - PRD

**Version**: 1.0
**Created**: February 6, 2026
**Status**: PLANNED
**Dependencies**: M9 Complete, iOS 26 Adoption > 50%
**Estimated Effort**: 12-18 hours (2-3 weeks part-time)
**Minimum iOS**: 26.0 (up from 18.5)

---

## EXECUTIVE SUMMARY

M15 modernizes Forager's UI to adopt Apple's "Liquid Glass" design language introduced at WWDC 2025. This milestone transforms the app's visual identity using iOS 26's new SwiftUI APIs including `GlassEffectContainer`, `.glassEffect()`, and `.tabViewBottomAccessory()`.

**Key Outcomes:**
- **Modern Visual Identity**: Translucent, refractive UI matching iOS 26 system apps
- **Enhanced Tab Bar**: Floating capsule architecture with scroll-responsive behavior
- **Active Plan Mini Bar**: "Now Playing"-style accessory for current meal plan
- **Platform Consistency**: Harmonious design across iOS 26, iPadOS 26, macOS Tahoe 26

**Why This Milestone?**
- iOS 26 introduces the most significant design evolution since iOS 7
- Users expect apps to adopt new platform paradigms
- Liquid Glass APIs provide polish that would take months to build custom
- Competitive differentiation in the grocery/meal planning space

---

## CONTEXT: iOS 26 LIQUID GLASS

### What is Liquid Glass?

Liquid Glass is Apple's new design language announced at WWDC 2025 (June 9, 2025). It's a dynamic material combining:
- **Refraction**: Content from below shows through with distortion
- **Reflection**: Light from surroundings reflects off surfaces
- **Lensing**: Edges create depth and motion effects
- **Morphing**: Shapes blend and transform fluidly

### Reference Materials

- **WWDC25 Session 323**: [Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- **Apple Newsroom**: [Liquid Glass Announcement](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)
- **Developer Documentation**: [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- **Community Reference**: [LiquidGlassReference on GitHub](https://github.com/conorluddy/LiquidGlassReference)

---

## OBJECTIVES

### Primary Goals

1. **Adopt Floating Tab Bar**: Replace fixed footer with iOS 26 capsule architecture
2. **Implement Active Plan Accessory**: Add "Now Playing"-style mini bar for current meal plan
3. **Apply Glass Effects**: Use `GlassEffectContainer` and `.glassEffect()` throughout UI
4. **Enable Tab Minimization**: Implement scroll-responsive tab bar behavior

### Secondary Goals

1. Add morphing search button (Tab with `.search` role)
2. Ensure Dark Mode compatibility with glass materials
3. Optimize glass rendering performance
4. Document glass effect patterns for future features

### Non-Goals

- Complete app redesign beyond Liquid Glass adoption
- New feature development
- UIKit migration (remain SwiftUI-first)
- Backward compatibility with iOS 18-25 (clean break)

---

## TECHNICAL ARCHITECTURE

### Core SwiftUI APIs (iOS 26+)

| API | Purpose | Documentation |
|-----|---------|---------------|
| `GlassEffectContainer` | Groups glass elements for morphing/reflection | [Apple Docs](https://developer.apple.com/documentation/swiftui/glasseffectcontainer) |
| `.glassEffect(_:in:isEnabled:)` | Applies Liquid Glass to views | [Apple Docs](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views) |
| `.tabViewBottomAccessory()` | Adds "Now Playing"-style accessory above tab bar | [Apple Docs](https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(content:)) |
| `.tabBarMinimizeBehavior()` | Controls tab bar collapse on scroll | System modifier |
| `Tab(role: .search)` | Creates separated, morphing search button | Tab API |
| `TabViewBottomAccessoryPlacement` | Detects `.inline` vs `.expanded` state | [Apple Docs](https://developer.apple.com/documentation/SwiftUI/TabViewBottomAccessoryPlacement) |

### Target Tab View Structure

```swift
import SwiftUI

struct ForagerMainTabView: View {
    @State private var searchText = ""
    @StateObject private var mealPlanService = MealPlanService.shared

    var body: some View {
        TabView {
            // Primary Navigation Tabs
            Tab("Lists", systemImage: "list.bullet.clipboard.fill") {
                GroceryListsView()
            }

            Tab("Recipes", systemImage: "book.fill") {
                RecipeListView()
            }

            Tab("Plan", systemImage: "calendar") {
                MealPlanView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }

            // Morphing Search Button (separated from tab group)
            Tab(role: .search) {
                NavigationStack {
                    UnifiedSearchView()
                }
                .searchable(text: $searchText)
            }
        }
        // Active Meal Plan Mini Bar (like Apple Music's Now Playing)
        .tabViewBottomAccessory {
            if let activePlan = mealPlanService.currentMealPlan {
                ActivePlanMiniBar(mealPlan: activePlan)
            }
        }
        // Tab bar minimizes on scroll, expands on scroll up
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
```

### Active Plan Mini Bar Component

```swift
struct ActivePlanMiniBar: View {
    let mealPlan: MealPlan
    @Environment(\.tabViewBottomAccessoryPlacement) var placement

    var body: some View {
        GlassEffectContainer(shape: .capsule) {
            HStack(spacing: 12) {
                // Meal Plan Icon
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())

                // Plan Info (hidden when inline)
                if placement == .expanded {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mealPlan.displayName)
                            .font(.headline)
                            .lineLimit(1)
                        Text(mealPlan.dateRangeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // Quick Actions
                Button(action: { /* Navigate to plan */ }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .padding(.horizontal)
    }
}
```

---

## PHASED IMPLEMENTATION PLAN

### PHASE 1: Foundation & Tab Bar (4-6 hours)

**M15.1: Deployment Target & Tab View Migration**

**Tasks:**

1. **Update Deployment Target** (30 min)
   - Change minimum iOS from 18.5 to 26.0
   - Update Info.plist
   - Remove any iOS 18-25 compatibility code
   - Update App Store metadata for iOS 26 requirement

2. **Migrate to iOS 26 Tab API** (2-3h)
   - **File**: `forager/ContentView.swift` (or main tab view)
   - Replace current `TabView` with new `Tab` syntax
   - Add `Tab(role: .search)` for unified search
   - Implement `.tabBarMinimizeBehavior(.onScrollDown)`
   - Test tab switching and navigation

3. **Remove Legacy Tab Customization** (1h)
   - Remove `.background(Color.black)` or similar on tab bar
   - Remove `.toolbarBackground()` overrides
   - Remove custom safe area handling (system handles this now)
   - Delete any custom tab bar appearance code

4. **Testing** (1h)
   - Verify all 6 tabs function correctly
   - Test tab minimization on scroll
   - Verify search tab morphing behavior
   - Test on multiple device sizes

**Deliverables:**
- iOS 26 deployment target active
- Floating capsule tab bar operational
- Tab minimization working on scroll
- Search tab separated and morphing

**Success Metrics:**
- Tab bar matches iOS 26 system apps
- Smooth minimize/expand animations
- No visual glitches during transitions

---

### PHASE 2: Active Plan Accessory (3-4 hours)

**M15.2: Tab View Bottom Accessory Implementation**

**Tasks:**

1. **Create ActivePlanMiniBar Component** (1.5-2h)
   - Create `forager/Views/Components/ActivePlanMiniBar.swift`
   - Implement responsive layout (`.expanded` vs `.inline`)
   - Use `GlassEffectContainer` for consistent materiality
   - Add tap gesture to navigate to full meal plan

2. **Integrate with MealPlanService** (1h)
   - Add `currentMealPlan` computed property if not exists
   - Determine "active" plan logic (current date within range)
   - Handle no active plan state (hide accessory)

3. **Add Quick Actions** (30 min)
   - Navigate to plan detail
   - Mark today's meal as complete
   - Quick add to grocery list

4. **Testing** (30 min)
   - Verify accessory shows/hides correctly
   - Test inline vs expanded states during scroll
   - Verify glass effect matches tab bar

**Deliverables:**
- ActivePlanMiniBar component complete
- Accessory integrated with MealPlanService
- Responsive to scroll state
- Quick actions functional

**Success Metrics:**
- Matches Apple Music "Now Playing" bar behavior
- Smooth transitions between inline/expanded
- Glass effect consistent with tab bar

---

### PHASE 3: Glass Effects Throughout (4-6 hours)

**M15.3: GlassEffectContainer & .glassEffect() Adoption**

**Tasks:**

1. **Identify Glass Effect Candidates** (30 min)
   - Audit all modal sheets
   - Identify floating action buttons
   - Review card-style components
   - List toolbar/navigation elements

2. **Apply Glass Effects to Sheets** (1.5-2h)
   - **Priority files**:
     - AddListItemSheet
     - RecipePickerSheet
     - CreateHouseholdSheet
     - DatePickerSheet
   - Wrap content in `GlassEffectContainer`
   - Test blur/refraction with various backgrounds

3. **Apply Glass Effects to Cards** (1-1.5h)
   - Recipe cards in list view
   - Meal plan day cards
   - Grocery list category headers
   - Use `.glassEffect()` modifier appropriately

4. **Apply Glass Effects to Floating Elements** (1h)
   - Floating action buttons (if any)
   - Toast/alert overlays
   - Context menus

5. **Performance Optimization** (30 min)
   - Profile glass rendering with Instruments
   - Reduce unnecessary glass layers
   - Use `isEnabled` parameter for conditional glass

6. **Testing** (30 min)
   - Test glass effects in light/dark mode
   - Verify performance on older devices (A14+)
   - Check glass morphing between nearby elements

**Deliverables:**
- Glass effects on all modal sheets
- Card components with appropriate glass treatment
- Performance validated
- Light/dark mode both polished

**Success Metrics:**
- Consistent glass materiality throughout app
- No performance degradation (maintain 60fps)
- Glass elements blend with system UI

---

### PHASE 4: Polish & Dark Mode (2-3 hours)

**M15.4: Visual Polish & Color Refinement**

**Tasks:**

1. **Dark Mode Optimization** (1h)
   - Replace any `#000000` (true black) with `Color(uiColor: .systemBackground)`
   - True black kills Liquid Glass lensing effect
   - Audit all background colors
   - Test glass refraction in dark mode

2. **Color Palette Alignment** (30 min)
   - Ensure accent colors work with glass materials
   - Test tint colors through glass layers
   - Adjust any colors that look wrong with refraction

3. **Animation Refinement** (30 min)
   - Verify morphing animations are smooth
   - Tune any custom animations to match system timing
   - Test glass transitions during navigation

4. **Edge Case Handling** (30 min)
   - Test with accessibility settings (reduce transparency, etc.)
   - Test with reduced motion preference
   - Verify fallback behavior if glass disabled

5. **Documentation** (30 min)
   - Document glass effect usage patterns
   - Add to coding standards
   - Create component library notes

**Deliverables:**
- Dark mode fully optimized for glass
- All animations polished
- Accessibility compliance verified
- Documentation complete

**Success Metrics:**
- Glass effects look correct in both light/dark modes
- Respects accessibility preferences
- Documentation enables future glass adoption

---

## REQUIREMENTS SUMMARY

### Functional Requirements

| ID | Requirement | Phase | Priority |
|----|-------------|-------|----------|
| **FR-LG-001** | Adopt iOS 26 floating capsule tab bar architecture | Phase 1 | P0 |
| **FR-LG-002** | Implement tab bar minimize behavior on scroll | Phase 1 | P0 |
| **FR-LG-003** | Add morphing search button with Tab(role: .search) | Phase 1 | P1 |
| **FR-LG-004** | Create ActivePlanMiniBar component | Phase 2 | P0 |
| **FR-LG-005** | Integrate bottom accessory with MealPlanService | Phase 2 | P0 |
| **FR-LG-006** | Apply GlassEffectContainer to modal sheets | Phase 3 | P1 |
| **FR-LG-007** | Apply .glassEffect() to card components | Phase 3 | P1 |
| **FR-LG-008** | Optimize Dark Mode for glass materials | Phase 4 | P0 |
| **FR-LG-009** | Ensure accessibility compliance | Phase 4 | P0 |

### Non-Functional Requirements

| ID | Requirement | Target | Priority |
|----|-------------|--------|----------|
| **NFR-LG-001** | Maintain 60fps during glass animations | 60fps | P0 |
| **NFR-LG-002** | No increase in app launch time | < 1.5s | P0 |
| **NFR-LG-003** | Memory overhead from glass effects | < 50MB | P1 |
| **NFR-LG-004** | Glass rendering on A14+ devices | Smooth | P0 |

---

## RISKS & MITIGATION

### High Risk: iOS 26 Adoption Timeline

**Risk:** Insufficient iOS 26 adoption delays milestone value

**Mitigation:**
- Monitor iOS 26 adoption rates post-release
- Target milestone when adoption > 50%
- Consider feature flags for gradual rollout
- Maintain iOS 18.5 branch for legacy support if needed

**Contingency:** Delay milestone until Q4 2026 if adoption lags

---

### Medium Risk: Performance on Older Devices

**Risk:** Glass effects may degrade performance on A14 chips

**Mitigation:**
- Profile early on oldest supported device
- Use `isEnabled` parameter to conditionally disable glass
- Reduce glass layer count in complex views
- Test with Instruments throughout development

**Contingency:** Disable glass effects on A14, enable on A15+

---

### Low Risk: Breaking Design Consistency

**Risk:** Partial glass adoption looks inconsistent

**Mitigation:**
- Apply glass effects systematically (all sheets, then all cards)
- Use GlassEffectContainer for grouped elements
- Follow Apple HIG for glass usage patterns

**Contingency:** Complete all phases before shipping (no partial release)

---

## DEPENDENCIES

### Prerequisites

- **M9 Complete**: Clean codebase for modernization
- **iOS 26 Released**: Public release (expected Fall 2026)
- **iOS 26 Adoption > 50%**: User base ready for breaking change
- **Xcode 17+**: Required for iOS 26 SDK

### Blocking Dependencies

- iOS 26 SDK availability
- Physical device running iOS 26 for testing

### Related Work

- **M10-M14**: Will benefit from glass-native components
- **Future UI work**: Establishes glass patterns for all new features

---

## TIMELINE ESTIMATE

### Aggressive Timeline (12 hours)
- **Phase 1**: 4h - Tab bar migration
- **Phase 2**: 3h - Bottom accessory
- **Phase 3**: 4h - Glass effects
- **Phase 4**: 1h - Polish

### Conservative Timeline (18 hours)
- **Phase 1**: 6h - Tab bar migration
- **Phase 2**: 4h - Bottom accessory
- **Phase 3**: 6h - Glass effects
- **Phase 4**: 2h - Polish

### Recommended Timing

**Execute when:**
- iOS 26 public release (Fall 2026)
- iOS 26 adoption reaches 50%+ of Forager users
- M9 technical debt complete

**Estimated calendar:** Q4 2026 or Q1 2027

---

## SUCCESS METRICS

| Metric | Target | Measurement |
|--------|--------|-------------|
| Tab bar matches system apps | Visual parity | Manual comparison |
| Glass animations smooth | 60fps | Instruments |
| User satisfaction | Positive feedback | TestFlight/App Store reviews |
| Performance maintained | No regression | Benchmark comparison |
| Accessibility compliance | VoiceOver works | Manual testing |

---

## APPENDIX: DESIGN REFERENCE

### Apple Music Comparison

| Apple Music Feature | Forager Equivalent |
|--------------------|--------------------|
| Floating tab bar | Same architecture |
| "Now Playing" mini bar | Active Plan mini bar |
| Search morphing button | Unified search tab |
| Tab minimization | Same behavior |
| Glass album art | Glass recipe cards |

### Files to Modify

| File | Changes |
|------|---------|
| `ContentView.swift` | Tab view structure |
| `foragerApp.swift` | Deployment target |
| `Info.plist` | iOS minimum version |
| `AddListItemSheet.swift` | GlassEffectContainer |
| `RecipePickerSheet.swift` | GlassEffectContainer |
| `CreateHouseholdSheet.swift` | GlassEffectContainer |
| **NEW** `ActivePlanMiniBar.swift` | Bottom accessory |
| **NEW** `UnifiedSearchView.swift` | Search tab content |

---

**Document Status**: DRAFT
**Next Review**: When iOS 26 SDK released
**Owner**: Rich Hayn
**Last Updated**: February 6, 2026
