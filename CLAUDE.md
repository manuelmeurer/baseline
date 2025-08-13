# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby gem called "baseline" that provides a collection of modules and patterns for Rails applications. It's a personal gem by Manuel Meurer containing reusable components, concerns, and services.

## Development Commands

### Linting
```bash
bundle exec rubocop
```

### Other Bin Scripts
- `bin/deploy` - Deployment script
- `bin/prod-console` - Production console access
- `bin/sync-assets` - Asset synchronization

## Architecture

### Core Structure
- **Engine**: Rails engine that isolates the namespace and loads rake tasks
- **ApplicationCore**: Main application configuration concern that handles URL options, asset hosts, and credentials
- **Configuration**: Centralized configuration management

### Key Directories
- `lib/baseline/` - Main gem code
- `lib/baseline/controller_concerns/` - Controller mixins (Authentication, PageTitle, etc.)
- `lib/baseline/model_concerns/` - Model mixins (ActsAs*, Has* patterns)
- `lib/baseline/services/` - Service objects organized by domain
- `lib/baseline/components/` - ViewComponent classes
- `app/javascript/baseline/` - Frontend JavaScript
- `app/views/baseline/` - Partial templates

### Service Architecture
Services are organized into namespaced modules:
- `External/` - Third-party integrations (Google OAuth, Lexoffice, Todoist, Slack, Pretix)
- `GoogleDrive/` - Google Drive specific operations
- `Lexoffice/` - Lexoffice accounting integration
- `Tasks/` - Task management with Todoist integration
- `Messages/`, `Notifications/` - Communication services
- `Sitemaps/` - SEO and sitemap generation

### Model Patterns
The gem provides mixins following Rails conventions:
- `ActsAs*` - Behavior mixins (ActsAsTask, ActsAsMessage, etc.)
- `Has*` - Attribute mixins (HasFullName, HasCountry, etc.)
- `ModelCore` - Base model functionality

### External Integrations
- **Google OAuth** - Authentication and Drive access
- **Todoist** - Task management API
- **Lexoffice** - German accounting software
- **Slack** - Notifications
- **Pretix** - Event ticketing

## Code Conventions

### Ruby Style
- Uses rubocop-rails-omakase as base configuration
- Enforces table-style hash alignment
- Allows empty lines at method/block beginnings
- Indented method call style

### File Organization
- Services follow single responsibility principle
- Concerns are prefixed with behavior type (`ActsAs`, `Has`)
- External services are namespaced under `External/`
- Test helpers are in `lib/baseline/spec/`

### Component Structure
- ViewComponents for reusable UI elements
- Stimulus controllers for JavaScript behavior
- HAML templates for views
