---
description: Scaffold a new feature screen following the Feature-First architecture with proper separation between Controller (state) and Screen (UI).
---

# Create Screen Method

## Purpose
Scaffold a new feature screen following the Feature-First architecture with proper separation between Controller (state) and Screen (UI).

## Prerequisites
- Feature domain entities defined
- Repository contract defined (if needed)

## Steps

### 1. Create Feature Directory Structure
```
lib/presentation/<module>/<feature>/
├── <feature>_screen.dart          # Pure UI
├── <feature>_controller.dart      # State management
├── widgets/                        # Feature-specific widgets
│   └── <widget>_widget.dart
└── models/                         # UI-specific models (if needed)
```

### 2. Implement Controller
The controller owns all business logic and state:

```dart
@injectable
class YourFeatureController {
  final YourRepository _repository;
  
  YourFeatureController(this._repository);

  // State using StreamValue
  final _state = StreamValue<YourEntity?>(null);
  Stream<YourEntity?> get state => _state.stream;
  YourEntity? get currentState => _state.value;

  // Business logic methods
  Future<void> loadData(String id) async {
    try {
      final entity = await _repository.fetchById(id);
      _state.add(entity);
    } catch (e) {
      _state.addError(e);
    }
  }

  Future<void> performAction() async {
    final current = currentState;
    if (current == null) return;
    
    // Business logic here
    await _repository.updateEntity(current);
  }

  void dispose() {
    _state.close();
  }
}
```

### 3. Implement Screen (Pure UI)
The screen is a pure UI component that consumes controller state:

```dart
@RoutePage()
class YourFeatureScreen extends StatelessWidget {
  const YourFeatureScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I<YourFeatureController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Feature')),
      body: StreamBuilder<YourEntity?>(
        stream: controller.state,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          }
          
          if (!snapshot.hasData) {
            return const LoadingWidget();
          }

          final entity = snapshot.data!;
          return YourFeatureContent(
            entity: entity,
            onAction: controller.performAction,
          );
        },
      ),
    );
  }
}
```

### 4. Create Feature-Specific Widgets
Follow "one widget per file" rule:

```dart
// widgets/your_feature_content.dart
class YourFeatureContent extends StatelessWidget {
  final YourEntity entity;
  final VoidCallback onAction;

  const YourFeatureContent({
    Key? key,
    required this.entity,
    required this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(entity.name),
        ElevatedButton(
          onPressed: onAction,
          child: const Text('Perform Action'),
        ),
      ],
    );
  }
}
```

### 5. Register Dependencies
Add to the appropriate module:

```dart
@module
abstract class YourFeatureModule {
  @singleton
  YourFeatureController provideController(YourRepository repository) {
    return YourFeatureController(repository);
  }
}
```

### 6. Register Route
Add to `app_router.dart`:

```dart
AutoRoute(
  page: YourFeatureRoute.page,
  path: '/your-feature',
),
```

### 7. Generate Code
```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

### 8. Verify
- Run `fvm flutter analyze` - must be clean
- Test screen navigation
- Verify state updates correctly
- Check error handling

## Architecture Principles
- **Controller Owns State**: All business logic and state in controller, never in widgets
- **Pure UI**: Screens and widgets are stateless, receive data via streams or parameters
- **StreamValue Pattern**: Use `StreamValue` for reactive state management
- **Dependency Injection**: Controllers injected via GetIt, registered in modules
- **Feature-First**: All feature code in one directory

## Critical Rules
- **NO StatefulWidget for business state** - only for UI state (animations, focus)
- **NO business logic in widgets** - delegate to controller
- **ONE widget per file** - improves readability and reusability
- **Pass primitives to widgets** - or use DI fallback for shared services
