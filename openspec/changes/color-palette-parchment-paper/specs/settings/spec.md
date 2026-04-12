## MODIFIED Requirements

### Requirement: Theme color token values
ForagerTheme SHALL define semantic color tokens that provide visible contrast between canvas backgrounds and card surfaces in both light and dark mode. Canvas backgrounds SHALL use warm tones. Card surfaces SHALL use cool/neutral tones to create temperature-based contrast.

#### Scenario: Light mode card visibility
- **WHEN** the app displays in light mode
- **THEN** card surfaces are visually distinguishable from the canvas background through both luminance and color temperature difference

#### Scenario: Dark mode card visibility
- **WHEN** the app displays in dark mode
- **THEN** card surfaces are visually distinguishable from the canvas background with neutral gray cards on warm-black canvas
