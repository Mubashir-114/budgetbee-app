/// FinTrack 2.0 - Phase 5E FIN Living Companion Models
///
/// Typed models for FIN's character states, action previews,
/// navigation actions, and persistent relationship preferences.
library;

enum FinCharacterState {
  idle,
  greeting,
  listening,
  attentive,
  thinking,
  explaining,
  happy,
  celebrating,
  encouraging,
  concerned,
  caution,
  confused,
  emptyData,
  error;

  static FinCharacterState fromString(String? value) {
    if (value == null) return FinCharacterState.idle;
    switch (value.toLowerCase().trim().replaceAll('-', '_')) {
      case 'greeting':
        return FinCharacterState.greeting;
      case 'listening':
        return FinCharacterState.listening;
      case 'attentive':
        return FinCharacterState.attentive;
      case 'thinking':
        return FinCharacterState.thinking;
      case 'explaining':
        return FinCharacterState.explaining;
      case 'happy':
        return FinCharacterState.happy;
      case 'celebrating':
        return FinCharacterState.celebrating;
      case 'encouraging':
        return FinCharacterState.encouraging;
      case 'concerned':
        return FinCharacterState.concerned;
      case 'caution':
        return FinCharacterState.caution;
      case 'confused':
        return FinCharacterState.confused;
      case 'empty_data':
      case 'emptydata':
        return FinCharacterState.emptyData;
      case 'error':
        return FinCharacterState.error;
      case 'idle':
      default:
        return FinCharacterState.idle;
    }
  }

  String get key => name;

  String get label {
    if (name.isEmpty) return '';
    if (name == 'emptyData') return 'Empty Data';
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}

class FinActionPreview {
  final String capability;
  final String title;
  final String description;
  final Map<String, dynamic> parameters;
  final String impact;
  final bool requiresConfirmation;

  const FinActionPreview({
    required this.capability,
    required this.title,
    required this.description,
    required this.parameters,
    required this.impact,
    this.requiresConfirmation = true,
  });

  /// Alias for description
  String get summary => description;

  /// Alias for impact
  String get impactNote => impact;

  factory FinActionPreview.fromJson(Map<String, dynamic> json) {
    return FinActionPreview(
      capability: json['capability'] as String? ?? '',
      title: json['title'] as String? ?? 'Action Preview',
      description: json['description'] as String? ?? json['summary'] as String? ?? '',
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? {},
      impact: json['impact'] as String? ?? json['impactNote'] as String? ?? '',
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'capability': capability,
    'title': title,
    'description': description,
    'parameters': parameters,
    'impact': impact,
    'requiresConfirmation': requiresConfirmation,
  };
}

class FinNavigationAction {
  final String route;
  final String? explicitLabel;

  const FinNavigationAction({
    required this.route,
    String? label,
  }) : explicitLabel = label;

  String get label {
    final l = explicitLabel;
    if (l != null && l.isNotEmpty) return l;
    switch (route) {
      case '/reports':
        return 'Open Reports';
      case '/planning':
        return 'Open Savings Goals & Planning';
      case '/budgets':
        return 'View Budgets';
      case '/transactions':
        return 'View Transactions';
      case '/dashboard':
      default:
        return 'Go to Dashboard';
    }
  }

  factory FinNavigationAction.fromJson(Map<String, dynamic> json) {
    return FinNavigationAction(
      route: json['route'] as String? ?? '/dashboard',
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'route': route,
    if (explicitLabel != null) 'label': explicitLabel,
  };
}

class CompanionPreferences {
  final String? preferredName;
  final String responseStyle; // 'friendly' | 'concise' | 'detailed'
  final bool enablePersonalizedGreetings;
  final bool enableCharacterAnimations;
  final int? priorityGoalId;
  final String? focusCategory;

  bool get animationsEnabled => enableCharacterAnimations;
  bool get personalizedGreetings => enablePersonalizedGreetings;

  const CompanionPreferences({
    this.preferredName,
    this.responseStyle = 'friendly',
    bool? enablePersonalizedGreetings,
    bool? enableCharacterAnimations,
    bool? personalizedGreetings,
    bool? animationsEnabled,
    this.priorityGoalId,
    this.focusCategory,
  })  : enablePersonalizedGreetings =
            personalizedGreetings ?? enablePersonalizedGreetings ?? true,
        enableCharacterAnimations =
            animationsEnabled ?? enableCharacterAnimations ?? true;

  factory CompanionPreferences.fromJson(Map<String, dynamic> json) {
    return CompanionPreferences(
      preferredName: json['preferredName'] as String?,
      responseStyle: json['responseStyle'] as String? ?? 'friendly',
      enablePersonalizedGreetings:
          json['enablePersonalizedGreetings'] as bool? ??
          json['personalizedGreetings'] as bool? ??
          true,
      enableCharacterAnimations:
          json['enableCharacterAnimations'] as bool? ??
          json['animationsEnabled'] as bool? ??
          true,
      priorityGoalId: (json['priorityGoalId'] as num?)?.toInt(),
      focusCategory: json['focusCategory'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (preferredName != null) 'preferredName': preferredName,
    'responseStyle': responseStyle,
    'enablePersonalizedGreetings': enablePersonalizedGreetings,
    'enableCharacterAnimations': enableCharacterAnimations,
    if (priorityGoalId != null) 'priorityGoalId': priorityGoalId,
    if (focusCategory != null) 'focusCategory': focusCategory,
  };

  CompanionPreferences copyWith({
    String? preferredName,
    String? responseStyle,
    bool? enablePersonalizedGreetings,
    bool? enableCharacterAnimations,
    bool? personalizedGreetings,
    bool? animationsEnabled,
    int? priorityGoalId,
    String? focusCategory,
  }) {
    return CompanionPreferences(
      preferredName: preferredName ?? this.preferredName,
      responseStyle: responseStyle ?? this.responseStyle,
      enablePersonalizedGreetings: personalizedGreetings ??
          enablePersonalizedGreetings ??
          this.enablePersonalizedGreetings,
      enableCharacterAnimations: animationsEnabled ??
          enableCharacterAnimations ??
          this.enableCharacterAnimations,
      priorityGoalId: priorityGoalId ?? this.priorityGoalId,
      focusCategory: focusCategory ?? this.focusCategory,
    );
  }
}
