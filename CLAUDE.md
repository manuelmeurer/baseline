# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby gem called "baseline" that provides a collection of modules and patterns for Rails applications. It's a personal gem by Manuel Meurer containing reusable components, concerns, and services.

## Development Commands

### Linting
```bash
bundle exec rubocop
```

### Testing
```bash
bundle exec rspec
```

## Architecture

### Core Structure
- **Engine**: Rails engine (`lib/baseline/engine.rb`) that isolates the namespace and loads rake tasks
- **ApplicationCore**: Main application configuration concern (`lib/baseline/application_core.rb`) that handles URL options, asset hosts, and credentials
- **Configuration**: Centralized configuration management (`lib/baseline/configuration.rb`)

### Key Directories
- `lib/baseline/` - Main gem code
- `lib/baseline/controller_concerns/` - Controller mixins (Authentication, PageTitle, etc.)
- `lib/baseline/model_concerns/` - Model mixins (ActsAs*, Has* patterns)
- `lib/baseline/services/` - Service objects organized by domain
- `lib/baseline/components/` - ViewComponent classes
- `lib/baseline/avo/` - Avo admin interface components
- `lib/baseline/initializers/` - Framework initializers
- `lib/baseline/spec/` - Test helpers
- `app/javascript/baseline/` - Frontend JavaScript (Stimulus controllers)
- `app/views/baseline/` - Partial templates (HAML)
- `app/assets/stylesheets/baseline/` - SCSS stylesheets

### Service Architecture
Services are organized into namespaced modules under `lib/baseline/services/`:
- `external/` - Third-party integrations
  - `google/oauth/` - Google OAuth (authorizer, helpers, service)
  - `cloudflare.rb` - Cloudflare integration
  - `lexoffice.rb` - German accounting software
  - `pretix.rb` - Event ticketing platform
  - `slack_simple.rb` - Slack notifications
  - `todoist.rb` - Task management API
- `google_drive/` - Google Drive specific operations
- `lexoffice/` - Lexoffice accounting integration (helpers, PDF download)
- `invoicing_details/` - Invoice management
- `tasks/` - Task management with Todoist integration
- `messages/` - Message generation services
- `notifications/` - Notification system
- `sitemaps/` - SEO and sitemap generation
- `recurring/` - Recurring job base classes

### Model Concerns
The gem provides mixins following Rails conventions in `lib/baseline/model_concerns/`:
- **ActsAs patterns** - Behavior mixins:
  - `acts_as_avo_resource.rb` - Avo admin interface
  - `acts_as_category.rb` / `acts_as_category_association.rb` - Category management
  - `acts_as_credit_note.rb` - Credit note functionality
  - `acts_as_invoicing_details.rb` - Invoice details
  - `acts_as_message.rb` - Message behavior
  - `acts_as_notification.rb` - Notification behavior
  - `acts_as_pdf_file.rb` - PDF file handling
  - `acts_as_task.rb` - Task management
  - `acts_as_todoist_event.rb` - Todoist event integration
- **Has patterns** - Attribute mixins:
  - `has_categories.rb` - Category associations
  - `has_charge_vat.rb` - VAT handling
  - `has_country.rb` - Country support
  - `has_dummy_image_attachment.rb` - Image placeholders
  - `has_email.rb` - Email functionality
  - `has_first_and_last_name.rb` / `has_full_name.rb` - Name handling
  - `has_friendly_id.rb` - Friendly URL IDs
  - `has_gender.rb` - Gender support
  - `has_locale.rb` - Localization
  - `has_messageable.rb` - Message associations
  - `has_password.rb` - Password functionality
  - `has_pdf_files.rb` - PDF file associations
  - `has_timestamps.rb` - Timestamp management
- **Core mixins**:
  - `model_core.rb` - Base model functionality
  - `touch_async.rb` - Asynchronous touch operations
  - `wizardable.rb` - Multi-step wizard support

### Controller Concerns
Located in `lib/baseline/controller_concerns/`:
- `admin_sessions_controllable.rb` - Admin authentication
- `api_controller_core.rb` / `api_todoist_controllable.rb` - API controllers
- `authentication.rb` - Authentication system
- `avo_application_controllable.rb` - Avo integration
- `contact_request_controllable.rb` - Contact form handling
- `controller_core.rb` - Base controller functionality
- `errors_controllable.rb` - Error handling
- `essentials_controllable.rb` - Essential controller features
- `frames_controllable.rb` - Frame support
- `google_oauth_controllable.rb` - Google OAuth integration
- `i18n_scopes.rb` - Internationalization scoping
- `mission_control_jobs_base_controllable.rb` - Job management
- `namespace_layout.rb` - Layout management
- `page_title.rb` - Page title handling
- `passwords_controllable.rb` - Password management
- `set_locale.rb` - Locale setting
- `web_base_controllable.rb` - Web base functionality
- `wizardify.rb` - Wizard controller support

### ViewComponents
Reusable UI components in `lib/baseline/components/`:
- `accordion_component` - Collapsible content sections
- `avatar_box_component` - User avatar display
- `card_component` - Card layouts
- `contact_request_form_component` - Contact forms
- `copyable_text_field_component` - Copyable text inputs
- `form_actions_component` - Form action buttons
- `form_field_component` - Form field wrapper
- `item_list_component` - List displays
- `loading_component` - Loading indicators
- `modal_component` - Modal dialogs
- `navbar_component` - Navigation bars
- `tab_panels_component` - Tabbed interfaces
- `toast_component` - Toast notifications
- `wizard_links_component` - Wizard navigation

### External Integrations
- **Google OAuth** - Authentication and Drive access
- **Todoist** - Task management API integration
- **Lexoffice** - German accounting software integration
- **Slack** - Notification system
- **Pretix** - Event ticketing platform
- **Cloudflare** - CDN and security services

## Code Conventions

### Ruby Style
- Uses `rubocop-rails-omakase` as base configuration
- Enforces table-style hash alignment (`EnforcedColonStyle: table`)
- Uses indented method call style (`EnforcedStyle: indented`)
- Allows empty lines at method/block beginnings
- No spaces inside array literal brackets

### File Organization
- Services follow single responsibility principle in `lib/baseline/services/`
- Concerns are prefixed with behavior type (`ActsAs`, `Has`) in `lib/baseline/model_concerns/`
- External services are namespaced under `External/`
- Test helpers are in `lib/baseline/spec/`
- Components follow ViewComponent conventions with paired `.rb` and `.html.haml` files
- Initializers are in `lib/baseline/initializers/`

### Component Structure
- ViewComponents for reusable UI elements with HAML templates
- Stimulus controllers for JavaScript behavior in `app/javascript/baseline/`
- SCSS stylesheets organized in `app/assets/stylesheets/baseline/`
- I18n support with locale files in `config/locales/`

### Dependencies
- **Core**: zeitwerk (autoloading)
- **Development**: rubocop-rails-omakase, rspec
- **Runtime**: Rails engine pattern with isolated namespace

## Testing
- Uses RSpec for testing framework
- Test files excluded from gem packaging
- Spec helpers available in `lib/baseline/spec/`
