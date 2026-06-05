---
name: Vitality Core
colors:
  surface: '#fcf8fb'
  surface-dim: '#dcd9dc'
  surface-bright: '#fcf8fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f5'
  surface-container: '#f0edef'
  surface-container-high: '#eae7ea'
  surface-container-highest: '#e4e2e4'
  on-surface: '#1b1b1d'
  on-surface-variant: '#3e4942'
  inverse-surface: '#303032'
  inverse-on-surface: '#f3f0f2'
  outline: '#6e7a71'
  outline-variant: '#bdcac0'
  surface-tint: '#006c47'
  primary: '#006b47'
  on-primary: '#ffffff'
  primary-container: '#00875a'
  on-primary-container: '#ffffff'
  inverse-primary: '#71dba6'
  secondary: '#556158'
  on-secondary: '#ffffff'
  secondary-container: '#d9e6da'
  on-secondary-container: '#5b675e'
  tertiary: '#9b403e'
  on-tertiary: '#ffffff'
  tertiary-container: '#ba5855'
  on-tertiary-container: '#ffffff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#8df7c1'
  primary-fixed-dim: '#71dba6'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005235'
  secondary-fixed: '#d9e6da'
  secondary-fixed-dim: '#bdcabe'
  on-secondary-fixed: '#131e17'
  on-secondary-fixed-variant: '#3e4a41'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3af'
  on-tertiary-fixed: '#410005'
  on-tertiary-fixed-variant: '#7d2a2a'
  background: '#fcf8fb'
  on-background: '#1b1b1d'
  surface-variant: '#e4e2e4'
  background-alt: '#F8F9FA'
  text-secondary: '#6E6E73'
  status-warning: '#D97706'
  border-subtle: '#E5E5EA'
  icon-inactive: '#94A3B8'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-card:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-default:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  caption:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.2px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  margin-page: 1.25rem
  gutter-grid: 1rem
  stack-sm: 0.5rem
  stack-md: 1rem
  stack-lg: 1.5rem
---

## Brand & Style

The design system is engineered for the "Skrining Lansia" platform, focusing on the intersection of high-end consumer technology and compassionate healthcare. The brand personality is **dependable, serene, and sophisticated**, designed to instill confidence in healthcare providers (Bidan) while remaining accessible to elderly users.

The aesthetic follows a **Corporate Modern** style with heavy **iOS-inspired** influence. This is characterized by:
- **Spaciousness:** Utilizing generous white space to reduce cognitive load during medical screenings.
- **Soft Precision:** Combining the mathematical rigor of Material 3 with the organic, "squircle" softness of Apple’s design language.
- **Clarity:** A "content-first" approach where UI elements recede into the background, allowing vital health data to take center stage.

## Colors

The palette is anchored in "Emerald Health," a premium green that evokes vitality and professional medical care.

- **Primary:** Used for the most critical actions, active navigation states, and branding elements.
- **Secondary:** Used as a high-softness background for cards or highlighted containers to create a tonal relationship with the primary brand color.
- **Neutral/Background:** A strict adherence to off-whites and "near-blacks" ensures maximum legibility. Pure black is avoided to prevent visual fatigue on mobile screens.
- **Status Colors:** Functional accents like `status-warning` are calibrated for high visibility without appearing aggressive or "alarming," maintaining the calm aesthetic.

## Typography

This design system utilizes **Plus Jakarta Sans** for its friendly yet modern geometric proportions. The hierarchy is strictly enforced to guide the user through complex screening workflows:

- **Headlines:** Reserved for page titles and high-level section headers.
- **Title Card:** Specifically sized for dashboard summaries and list items to ensure they remain scannable.
- **Body:** Optimized for legibility in health descriptions and user instructions.
- **Micro-copy:** Used for metadata, captions, and secondary labels to provide context without competing for attention.

## Layout & Spacing

The design system employs a **Fluid Grid** model with high horizontal margins to create an "airy" feel.

- **Mobile (Default):** 4-column grid with 20px (`1.25rem`) side margins.
- **Vertical Spacing:** Follows an 8px base grid. Use `stack-md` for related elements within a card and `stack-lg` to separate distinct sections of the application.
- **Safe Zones:** Ensure all clickable elements maintain a minimum hit area of 44x44pt, following accessibility standards for elderly-focused applications.

## Elevation & Depth

Visual hierarchy is primarily achieved through **Tonal Layers** and **Ambient Shadows**, avoiding heavy gradients or skeuomorphism.

- **Surfaces:** Main content lives on `Background-alt` (#F8F9FA). Interactive cards and containers use pure `#FFFFFF` to "float" above the base layer.
- **Shadows:** Utilize a "Large Blur, Low Opacity" shadow for primary containers to simulate soft, natural light.
    *   *Formula:* `0px 4px 24px rgba(0, 0, 0, 0.04)`
- **Dividers:** For list-heavy views, use a subtle 1px border (`#E5E5EA`) instead of shadows to maintain a clean, organized iOS-style list appearance.

## Shapes

The shape language is defined by **Continuous Curves**. This eliminates the harshness of standard geometric corners, contributing to the premium, approachable medical aesthetic.

- **Standard Cards:** Use `rounded-lg` (16px) for major dashboard components.
- **Buttons and Inputs:** Use `rounded-md` (12px) to provide a distinct look from larger containers while remaining soft.
- **Profile Avatars:** Always use circular masks to provide a friendly, human element.

## Components

### Buttons
- **Primary:** Filled with `#00875A`, white text, 12px corner radius. No border.
- **Secondary/Google Login:** White background, 12px corner radius, with a soft shadow. Use the `caption` typography for secondary labeling.

### Cards
- **Dashboard Grid:** Cards should have equal height in a 2-column layout. Use `secondary_color` (#E8F5E9) for icon backgrounds within cards to provide a subtle "pop" of color.
- **Borders:** Only use borders for non-elevated states, using `#E5E5EA`.

### Input Fields
- Rounded 12px corners. High-contrast labels above the field. Focused state uses a 2px stroke of `primary_color`.

### Bottom Navigation
- Minimalist background (no heavy top border).
- **Active State:** Icon and label change to `#00875A`.
- **Inactive State:** Icon and label use `#94A3B8`.

### Lists
- Borderless rows separated by a 1px `#E5E5EA` line.
- Icons on the left should be contained within a soft-cornered square (8px radius) using a desaturated version of the brand colors.