---
name: SignBridge Design System
colors:
  surface: '#041329'
  surface-dim: '#041329'
  surface-bright: '#2c3951'
  surface-container-lowest: '#010e24'
  surface-container-low: '#0d1c32'
  surface-container: '#112036'
  surface-container-high: '#1c2a41'
  surface-container-highest: '#27354c'
  on-surface: '#d6e3ff'
  on-surface-variant: '#d0c6ab'
  inverse-surface: '#d6e3ff'
  inverse-on-surface: '#233148'
  outline: '#999077'
  outline-variant: '#4d4732'
  surface-tint: '#e9c400'
  primary: '#fff6df'
  on-primary: '#3a3000'
  primary-container: '#ffd700'
  on-primary-container: '#705e00'
  inverse-primary: '#705d00'
  secondary: '#c6c6c7'
  on-secondary: '#2f3131'
  secondary-container: '#454747'
  on-secondary-container: '#b4b5b5'
  tertiary: '#f5f6ff'
  on-tertiary: '#20304f'
  tertiary-container: '#cbdaff'
  on-tertiary-container: '#4f5f80'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffe16d'
  primary-fixed-dim: '#e9c400'
  on-primary-fixed: '#221b00'
  on-primary-fixed-variant: '#544600'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c7'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#b6c6ed'
  on-tertiary-fixed: '#091b39'
  on-tertiary-fixed-variant: '#374767'
  background: '#041329'
  on-background: '#d6e3ff'
  surface-variant: '#27354c'
typography:
  headline-lg:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 32px
    fontWeight: '800'
    lineHeight: '1.2'
  headline-lg-mobile:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 28px
    fontWeight: '800'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 20px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  label-lg:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 16px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: 0.02em
  translation-display:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 40px
    fontWeight: '800'
    lineHeight: '1.1'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  space-xs: 4px
  space-sm: 8px
  space-md: 16px
  space-lg: 24px
  space-xl: 40px
  container-margin: 20px
  gutter: 16px
---

## Brand & Style

The brand personality focuses on clarity, empowerment, and seamless connection. This design system bridges the gap between auditory and visual communication through a high-accessibility framework. The target audience includes the Deaf and Hard of Hearing community, sign language learners, and professional interpreters who require a tool that is highly legible under various lighting conditions.

The aesthetic is **Minimalist and High-Contrast**. By stripping away non-essential decorative elements, the UI prioritizes the video feed and translated text. The style utilizes a "Functional Dark Mode" approach, where deep backgrounds reduce eye strain during long translation sessions, while vibrant accents guide the user's focus to critical interactive zones. The interface feels dependable, modern, and inclusive.

## Colors

This design system utilizes a high-contrast dark palette specifically optimized for accessibility (WCAG 2.1 AAA compliance where possible).

*   **Primary (Bright Yellow - #FFD700):** Used for primary actions, active states, and highlighting translated text tokens. This color provides maximum visibility against the dark background.
*   **Secondary (Snow White - #FFFFFF):** Reserved for primary typography and essential iconography to ensure crisp legibility.
*   **Neutral (Deep Navy - #0A192F):** The base surface color. It reduces glare and provides a stable foundation for visual sign recognition.
*   **Surface-Elevated (#112240):** A slightly lighter navy used for cards and containers to create subtle hierarchy without breaking the dark-mode immersion.

## Typography

The typography system prioritizes hyper-legibility. While Roboto or Poppins are requested, this system utilizes **Atkinson Hyperlegible Next** to ensure that characters are distinguishable for users with low vision. 

**Key Principles:**
*   **Bold Weights:** Use bold and extra-bold weights for interactive elements to ensure they "pop" against the navy background.
*   **Scale:** Font sizes are slightly larger than standard web defaults to improve glanceability during active signing.
*   **Translation Display:** A specialized "translation-display" style is used for the real-time text output, ensuring it is the most prominent element on the screen.

## Layout & Spacing

This design system uses a **fluid grid** model that prioritizes the video viewport. 

*   **Mobile (under 600px):** Single column layout. The video feed occupies the top 50-60% of the screen, with the translation text and controls anchored to the bottom.
*   **Tablet/Desktop:** A 12-column grid. The video feed remains central or left-aligned, with a persistent sidebar for translation history or settings.
*   **Rhythm:** A basic 8px grid system ensures consistent alignment. Large "Safe Areas" (24px+) are maintained around gesture-heavy zones to prevent accidental inputs while signing.

## Elevation & Depth

To maintain a minimalist aesthetic, depth is communicated through **Tonal Layers** rather than heavy shadows.

1.  **Level 0 (Base):** #0A192F (Deep Navy) - The main background.
2.  **Level 1 (Surface):** #112240 (Navy Blue) - Used for cards, input fields, and navigation bars.
3.  **Level 2 (Overlay):** #1C2F4D - Used for modals and floating action buttons.

**Outlines:** Instead of shadows, use 1px solid borders in #FFFFFF (at 10% opacity) for container definition. For focused or active states, use a 2px solid #FFD700 border to provide clear visual feedback.

## Shapes

The shape language is approachable and soft, utilizing **Rounded (Level 2)** settings. 

*   **Standard UI Elements:** Buttons and input fields use a 0.5rem (8px) radius.
*   **Large Containers:** Cards and video viewports use a 1rem (16px) radius.
*   **Chips/Tags:** Use a pill-shaped (full-round) radius to distinguish them from actionable buttons.

The use of rounded corners serves a dual purpose: it aligns with the "Bridge" metaphor of connection and prevents the high-contrast interface from feeling too aggressive or clinical.

## Components

*   **Buttons:**
    *   *Primary:* Solid #FFD700 background with #0A192F text. Extra bold weight.
    *   *Secondary:* Transparent background with a 2px #FFFFFF border and white text.
*   **Input Fields:** #112240 background, 8px rounded corners. The cursor and focus-border must be #FFD700 for high visibility.
*   **Cards:** #112240 background. No shadows; use a subtle #FFFFFF (10% opacity) stroke for definition. 16px padding is the minimum standard.
*   **Video Viewport:** Must have a 16px corner radius. On active translation, the viewport should have a pulsing #FFD700 outer glow (4px spread, 0.3 opacity) to indicate the system is "listening" to signs.
*   **Translation Bubbles:** High-contrast containers. Text is Snow White on a Navy Surface, with keywords highlighted in Bright Yellow.
*   **Checkboxes/Radios:** Oversized (min 24x24px) for easier interaction. The "Checked" state must use #FFD700 for the checkmark/inner-dot.