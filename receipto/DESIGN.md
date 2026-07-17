---
name: Receipto
colors:
  surface: '#0b1323'
  surface-dim: '#0b1323'
  surface-bright: '#31394a'
  surface-container-lowest: '#060e1d'
  surface-container-low: '#131c2b'
  surface-container: '#18202f'
  surface-container-high: '#222a3a'
  surface-container-highest: '#2d3546'
  on-surface: '#dbe2f8'
  on-surface-variant: '#c2c6d6'
  inverse-surface: '#dbe2f8'
  inverse-on-surface: '#283041'
  outline: '#8c909f'
  outline-variant: '#424754'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e6a'
  primary-container: '#4d8eff'
  on-primary-container: '#00285d'
  inverse-primary: '#005ac2'
  secondary: '#5de6ff'
  on-secondary: '#00363e'
  secondary-container: '#00cbe6'
  on-secondary-container: '#00515d'
  tertiary: '#4edea3'
  on-tertiary: '#003824'
  tertiary-container: '#00a572'
  on-tertiary-container: '#00311f'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a42'
  on-primary-fixed-variant: '#004395'
  secondary-fixed: '#a2eeff'
  secondary-fixed-dim: '#2fd9f4'
  on-secondary-fixed: '#001f25'
  on-secondary-fixed-variant: '#004e5a'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#0b1323'
  on-background: '#dbe2f8'
  surface-variant: '#2d3546'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.02em
  code-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  container-max: 1200px
  gutter: 24px
---

## Brand & Style

The brand identity is built on the pillars of precision, security, and forward-thinking intelligence. Targeted at high-net-worth individuals and tech-savvy professionals, the visual language evokes the feeling of a premium digital vault. 

The aesthetic is a sophisticated blend of **Minimalism** and **Glassmorphism**. It borrows the structural clarity of high-end productivity tools and the tactile depth of modern fintech interfaces. Every interaction should feel intentional, utilizing subtle translucency, vibrant background blurs, and precise borders to create a multi-layered, immersive experience. The AI features are distinguished by a signature purple luminescence, signaling a layer of intelligent automation atop the core financial data.

## Colors

The palette is anchored in deep, midnight blues to provide a sense of stability and depth.
- **Primary Background (#0B0F19):** Used for the lowest level of the application shell.
- **Surface Secondary (#141A26):** Used for sidebars, navigation bars, and grouping elements.
- **Card Surface (#1B2333):** The primary container for content modules, often applied with 80-90% opacity for glass effects.
- **Accents:** Electric Blue and Cyan are used for primary actions and data visualization. Emerald Green is reserved for positive financial growth and success states.
- **AI Highlight:** A vibrant purple-to-magenta gradient is used exclusively for AI-driven insights, automated categorization, and "smart" features to differentiate them from manual entries.

## Typography

This design system uses a triple-font approach to maximize clarity and technical sophistication.
- **Headings (Hanken Grotesk):** Modern, sharp, and highly legible. Use bold weights for financial totals and section headers to establish a clear hierarchy.
- **Body (Inter):** The workhorse for transaction lists, descriptions, and settings. It provides high readability at small sizes.
- **Technical/Labels (Geist):** Used for metadata, receipt IDs, and AI-generated tags. Its monospaced-adjacent metrics provide a developer-grade, precise feel to financial data.

## Layout & Spacing

The system follows a strict **8px linear grid**. All dimensions, padding, and margins must be multiples of 8 to ensure visual harmony and mathematical balance.

- **Desktop:** 12-column fluid grid with 24px gutters and 40px side margins. Content is typically centered within a 1200px max-width container.
- **Tablet:** 8-column grid with 24px gutters and 24px margins.
- **Mobile:** 4-column grid with 16px gutters and 16px margins. 

Layouts should favor vertical stacking for receipt lists and horizontal scrolling "swipes" for card carousels. Use white space aggressively to prevent the dark theme from feeling cramped or overwhelming.

## Elevation & Depth

Hierarchy is established through **translucency and background blurs** rather than traditional heavy shadows.

- **Level 0 (Base):** #0B0F19.
- **Level 1 (Cards):** #1B2333 at 85% opacity with a 20px Backdrop Blur. A 1px border (#FFFFFF at 10% opacity) provides definition against the background.
- **Level 2 (Modals/Popovers):** #1B2333 at 95% opacity with a 40px Backdrop Blur. Includes a soft, 30px spread ambient shadow (#000000 at 40% opacity).
- **AI Elements:** Elements touched by AI use a subtle outer glow using the primary purple accent color to simulate "energy" emanating from the surface.

## Shapes

The shape language is "Organic-Geometric." Large corner radii (24px) for cards create a friendly, premium feel reminiscent of physical credit cards. Smaller components like buttons and inputs use a 12px radius to maintain a precise, functional look. 

Buttons and interactive containers should never have completely sharp corners. For secondary tags or chips, use fully pill-shaped (999px) containers.

## Components

- **Glass Cards:** The signature component. Constructed with #1B2333 at reduced opacity, a 1px inner stroke for "highlight" edges, and high-intensity backdrop blur.
- **Gradient Buttons:** Primary actions use a linear gradient from Electric Blue to Cyan. AI-specific actions use the Purple/Magenta gradient. All buttons feature a subtle 1px border that is 10% lighter than the fill color.
- **Outlined Icons:** Icons must be 2px stroke width, using consistent "Round" join and cap settings. They should be monochromatic (White/Grey) except when indicating status (Green/Red).
- **Transaction Lists:** Use high-contrast typography for amounts. Use the Emerald Green accent for income and pure white for expenses. Each row should have a subtle separator line (#FFFFFF at 5% opacity).
- **Inputs:** Darker than the card background (#0B0F19), with a 1px border that glows Electric Blue when focused.
- **Smart Chips:** Used for AI-detected categories (e.g., "Travel", "Dining"). These should use a low-opacity version of the purple gradient as a background with high-contrast white text.