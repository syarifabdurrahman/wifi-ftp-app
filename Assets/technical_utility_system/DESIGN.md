---
name: Technical Utility System
colors:
  surface: '#f9f9ff'
  surface-dim: '#d8dae2'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3fb'
  surface-container: '#ecedf6'
  surface-container-high: '#e7e8f0'
  surface-container-highest: '#e1e2ea'
  on-surface: '#191c21'
  on-surface-variant: '#424752'
  inverse-surface: '#2e3037'
  inverse-on-surface: '#eff0f8'
  outline: '#727783'
  outline-variant: '#c2c6d4'
  surface-tint: '#005db6'
  primary: '#00478d'
  on-primary: '#ffffff'
  primary-container: '#005eb8'
  on-primary-container: '#c8daff'
  inverse-primary: '#a9c7ff'
  secondary: '#505f76'
  on-secondary: '#ffffff'
  secondary-container: '#d0e1fb'
  on-secondary-container: '#54647a'
  tertiary: '#793100'
  on-tertiary: '#ffffff'
  tertiary-container: '#9f4300'
  on-tertiary-container: '#ffcfb9'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d6e3ff'
  primary-fixed-dim: '#a9c7ff'
  on-primary-fixed: '#001b3d'
  on-primary-fixed-variant: '#00468c'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#ffdbcb'
  tertiary-fixed-dim: '#ffb691'
  on-tertiary-fixed: '#341100'
  on-tertiary-fixed-variant: '#793100'
  background: '#f9f9ff'
  on-background: '#191c21'
  surface-variant: '#e1e2ea'
typography:
  display:
    fontFamily: Geist
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Geist
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: '0'
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: '0'
  label-md:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  code-sm:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: '0'
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container_margin: 16px
  gutter: 12px
---

## Brand & Style
This design system focuses on the intersection of technical utility and seamless user experience. Designed for a WiFi FTP utility, the aesthetic prioritizes clarity and speed of information retrieval. 

The design style is **Corporate / Modern**, leaning heavily into a systematic, utility-first approach. It avoids decorative elements in favor of functional clarity. The interface uses generous whitespace and a rigid structural hierarchy to ensure users feel in control of their data transfers. The emotional goal is to evoke a sense of "quiet power"—a tool that is incredibly capable but stays out of the way until needed.

## Colors
The palette is rooted in an **Electric Blue** primary, chosen for its association with high-tech infrastructure and reliable connectivity. 

- **Primary (#005EB8):** Used for critical actions, branding, and active indicators.
- **Secondary (#64748B):** A muted slate grey used for secondary text and decorative icons.
- **Accent (#0EA5E9):** A softer, brighter blue specifically reserved for active states, progress bars, and selection highlights to provide a subtle "glow" effect without overwhelming the user.
- **Surfaces:** The background uses a very cool light grey (#F8FAFC) to reduce eye strain, while cards and interactive surfaces use pure white (#FFFFFF) for maximum contrast.

## Typography
The system uses a pairing of **Geist** for structural elements and **Inter** for content. Geist provides a technical, precise feel for headlines and labels, while Inter ensures maximum legibility for file paths and IP addresses.

- **Headlines:** Use Geist with tighter letter spacing for a modern, engineered look.
- **Body Text:** Use Inter for all multi-line content and descriptions.
- **Technical Data:** For IP addresses, port numbers, and FTP paths, a monospaced font (JetBrains Mono) is introduced sparingly to help users distinguish between similar characters (like '0' and 'O').

## Layout & Spacing
This design system utilizes a **Fluid Grid** model based on a 4px baseline. In mobile views, the standard container margin is 16px.

- **Rhythm:** Vertical spacing between related items (like file list entries) should follow the 8px (sm) or 12px increments. 
- **Layout:** Elements should align to a 4-column mobile grid. For complex data views (like transfer logs), use the 12px gutter to separate columns of information while maintaining a compact density suitable for technical tools.

## Elevation & Depth
Depth is conveyed through **Tonal Layers** and **Low-contrast outlines**. This avoids the "heavy" feel of traditional shadows and maintains a professional, flat aesthetic.

- **Level 0 (Background):** #F8FAFC. The lowest layer.
- **Level 1 (Cards/Lists):** Pure white background with a 1px border (#E2E8F0). No shadow.
- **Level 2 (Active/Floating):** Pure white background with a 1px border (#CBD5E1) and a very soft, highly diffused ambient shadow (0px 4px 20px rgba(0, 0, 0, 0.04)).
- **Interactions:** When an item is pressed, it should not lift; instead, it should show a subtle inner-fill change to the Accent color at 8% opacity.

## Shapes
The shape language is **Soft**, reflecting precision rather than playfulness. 

- **Components:** Standard buttons and input fields use a 4px (0.25rem) corner radius.
- **Containers:** Larger elements like cards or modal sheets use an 8px (0.5rem) radius.
- **Active Indicators:** Small pill shapes (fully rounded) are used only for status chips (e.g., "Connected") to differentiate them from interactive buttons.

## Components
- **Buttons:** Primary buttons use the Primary Blue background with white text. Secondary buttons use a ghost style with a 1px slate border.
- **Cards:** Used for grouping server settings or storage stats. Should have a 1px border (#E2E8F0) and no shadow by default.
- **File Lists:** High-density rows with 2px stroke-based icons. Icons should be themed (e.g., folder, image, zip) using the Secondary color.
- **Input Fields:** Use a 1px border. When focused, the border changes to the Accent Blue with a 2px outer "glow" (Accent color at 20% opacity).
- **Progress Bars:** Thin 4px tracks. The track is light grey, while the fill is the Accent Blue, indicating active data movement.
- **Connection Toggle:** A prominent, stylized switch or large button that uses the Primary color when "On" and a light grey when "Off," providing an unmistakable visual state.
- **Icons:** Use 24px bounding boxes with a consistent 2px stroke weight. Avoid filled icons unless indicating a selected bottom-navigation state.