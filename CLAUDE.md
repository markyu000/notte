# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build
xcodebuild build -scheme Notte -destination "platform=iOS Simulator,name=iPhone 16"

# Run all tests
xcodebuild test -scheme Notte -destination "platform=iOS Simulator,name=iPhone 16"

# Run a single test class
xcodebuild test -scheme Notte -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:NotteTests/CollectionListViewModelTests

# Run a single test method
xcodebuild test -scheme Notte -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:NotteTests/CollectionListViewModelTests/testMethodName
```

No external dependencies — the project uses only Apple native frameworks (SwiftUI, SwiftData, CloudKit, XCTest).

## Architecture

The app follows **Clean Architecture** with MVVM for the presentation layer. The strict layering is intentional — do not bypass it.

```
Features/<Feature>/
  Views/          → SwiftUI screens and sheets
  Components/     → Reusable UI within the feature
  ViewModels/     → @Published state, calls use cases
  UseCases/       → One business action per file

Domain/
  Entities/       → Pure Swift value types (no SwiftData imports)
  Protocols/      → Repository interfaces
  Enums/          → RepositoryError

Data/
  Models/         → SwiftData @Model classes with toDomain() mapping
  Repositories/   → Concrete repository implementations
  Persistence/    → SwiftData container, schema migration (SchemaV1)

Shared/Theme/     → ColorTokens, TypographyTokens, SpacingTokens
Infrastructure/   → AppError, AppErrorPresenter, logging
App/              → NotteApp, AppBootStrap, DependencyContainer, AppRouter
```

### Data flow

View → ViewModel → UseCase → Repository (protocol) → Repository (impl) → SwiftData

Domain entities are pure value types. SwiftData `@Model` classes live exclusively in `Data/Models/` and expose a `toDomain()` method to convert to domain entities. Never import SwiftData in the Domain or Features layers.

### Core domain hierarchy

```
Collection → Page → Node → Block
```

All entities carry `UUID id`, `createdAt`, `updatedAt`, and `sortIndex`.

### Dependency injection

`DependencyContainer` (in `App/`) instantiates concrete repositories and passes them down. ViewModels receive repository protocols via constructor injection. Tests use `MockCollectionRepository`.

### Navigation

`AppRouter` owns a `NavigationStack` with a typed route enum. Add new screens by extending the route enum and the `destination(for:)` switch in `RootView`.

## Key Conventions

- **Naming:** Follow the conventions documented in `Notte/Docs/Notte命名规范.md`
- **Git:** Follow branch and commit conventions in `Notte/Docs/NotteGit规范.md`
- **Design tokens:** Use `ColorTokens`, `TypographyTokens`, `SpacingTokens` — never raw hex values or magic numbers in views
- **Error handling:** Use `RepositoryError` at the data layer and `AppError` at the presentation layer
- **Sort ordering:** `SortIndexNormalizer` and `SortIndexPolicy` in `Shared/Utilities/` govern all reordering logic — use these, don't roll custom sort logic
- **Tests:** ViewModels and UseCases are unit-tested with mock repositories; repositories have integration tests using an in-memory SwiftData container

## iOS & Swift Requirements

- iOS 17.0+ (required by SwiftData)
- Swift 5.9+
- iPhone is the primary target; iPad is out of scope for MVP
