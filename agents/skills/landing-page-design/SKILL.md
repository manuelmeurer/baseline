---
name: landing-page-design
description: Implement landing pages from existing designs. Use when building a landing page from a Figma design, screenshot, mockup, or reference URL.
---

This skill is only applicable when creating or editing a landing page in a Rails app that uses Baseline.

## Process

When implementing a new landing page or adding new sections, always start with a planning phase — do not immediately start implementing. Only begin implementation once the plan has been confirmed by the user. For smaller changes to existing sections (copy updates, style tweaks, etc.), this process is not necessary.

### 1. Analyze the source design

Read the source design the user has supplied (Figma, screenshot, mockup, or URL) and divide the landing page into sections.

### 2. Map sections to Baseline partials

Read the section partials in Baseline (`baseline/app/views/baseline/sections/`) and decide for each section of the source design whether one of these partials can be used, or whether the section is so unique that no existing partial fits.

- **Always prefer using an existing partial.** This reduces the amount of custom HTML and ensures a consistent design.
- If no partial can be used, use the Baseline `section` helper (`baseline/lib/baseline/helper.rb`) to define a custom section.

### 3. Present the plan

Present the section-by-section plan to the user, showing which partial (or custom section) will be used for each part of the design. Wait for confirmation before proceeding.

### 4. Implement

Once the plan is confirmed, build the landing page section by section.

## Reuse over pixel-perfection

Reusing existing components, partials, helpers, and styles from the app or Baseline is more important than implementing the landing page 100% pixel-perfect to the source design. Before planning, study what the app and Baseline have to offer — check other landing pages in the app for reusable patterns and conventions.

## Image naming

Name images after their section. For background images, append `_bg`. If a section has multiple images, append `_01`, `_02`, etc.

Examples: `hero_bg`, `features_01`, `features_02`.

## Styling with Bootstrap

If the app uses Bootstrap, always style the landing page with existing Bootstrap styles and components.

### Buttons

Use Bootstrap button classes (e.g. `class="btn btn-primary"` or `class="btn btn-secondary"`) instead of generating custom buttons, even if they look slightly different from the buttons in the source design. After implementation, if the buttons differ from the source design, mention this to the user and suggest options to customize the buttons (while keeping the base Bootstrap button classes) in specific sections.

### Colors

Prefer `$primary`, `$secondary`, and any existing hex colors defined in custom Sass variables (check the Sass files in the "web" namespace) over defining new Sass/CSS variables or using hard-coded hex values.
