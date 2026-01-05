import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String assignedTo;
  final TaskStatus status;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? extractedEntities;
  final List<String>? suggestedActions;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.assignedTo,
    required this.status,
    required this.category,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.extractedEntities,
    this.suggestedActions,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? assignedTo,
    TaskStatus? status,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? extractedEntities,
    List<String>? suggestedActions,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      extractedEntities: extractedEntities ?? this.extractedEntities,
      suggestedActions: suggestedActions ?? this.suggestedActions,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    try {
      return Task(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        dueDate: json['dueDate'] != null || json['due_date'] != null
            ? DateTime.tryParse(
                (json['dueDate'] ?? json['due_date']).toString(),
              )
            : null,
        assignedTo: (json['assignedTo'] ?? json['assigned_to'] ?? '')
            .toString(),
        status: TaskStatus.fromString(
          json['status']?.toString() ??
              json['task_status']?.toString() ??
              'Pending',
        ),
        category: TaskCategory.fromString(
          json['category']?.toString() ?? 'Other',
        ),
        priority: TaskPriority.fromString(
          json['priority']?.toString() ?? 
          json['task_priority']?.toString() ?? 
          'Medium',
        ),
        createdAt:
            DateTime.tryParse(
              (json['createdAt'] ?? json['created_at'] ?? '').toString(),
            ) ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(
              (json['updatedAt'] ?? json['updated_at'] ?? '').toString(),
            ) ??
            DateTime.now(),
        // Preserve detected category name from backend if it's a descriptive name
        extractedEntities: () {
          final categoryFromBackend = json['category']?.toString() ?? '';
          final descriptiveCategories = ['Scheduling', 'Finance', 'Technical', 'Safety', 'General'];
          
          // Get existing extractedEntities or create new map
          Map<String, dynamic>? entities;
          if (json['extractedEntities'] != null || json['extracted_entities'] != null) {
            entities = Map<String, dynamic>.from(
              json['extractedEntities'] ?? json['extracted_entities'] ?? {},
            );
          } else {
            entities = <String, dynamic>{};
          }
          
          // If backend sent a descriptive category name, preserve it
          if (descriptiveCategories.contains(categoryFromBackend)) {
            entities['detected_category'] = categoryFromBackend;
          }
          
          return entities.isEmpty ? null : entities;
        }(),
        suggestedActions:
            json['suggestedActions'] != null ||
                json['suggested_actions'] != null
            ? List<String>.from(
                json['suggestedActions'] ?? json['suggested_actions'] ?? [],
              )
            : null,
      );
    } catch (e) {
      print('❌ Error parsing Task from JSON: $e');
      print('📦 JSON data: $json');
      rethrow;
    }
  }

  // Get the display category name (Scheduling, Finance, Technical, Safety, General)
  // Uses detected_category from extractedEntities if available, otherwise uses category enum value
  String getDisplayCategoryName() {
    if (extractedEntities != null && 
        extractedEntities!.containsKey('detected_category')) {
      return extractedEntities!['detected_category'] as String;
    }
    // If category is from backend and is a descriptive name, return it
    // Otherwise return enum value
    return category.value;
  }

  Map<String, dynamic> toJson() {
    // Use detected category name from extractedEntities if available, otherwise use enum value
    String categoryValue = category.value;
    if (extractedEntities != null && 
        extractedEntities!.containsKey('detected_category')) {
      categoryValue = extractedEntities!['detected_category'] as String;
    }
    
    return {
      'id': id,
      'title': title,
      'description': description,
      // Send both camelCase and snake_case to align with backend expectations
      'dueDate': dueDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'assignedTo': assignedTo,
      'assigned_to': assignedTo,
      'status': status.value,
      'task_status': status.value,
      'category': categoryValue, // Use detected category name (Scheduling, Finance, etc.)
      'priority': priority.value,
      'task_priority': priority.value, // Also send snake_case for backend compatibility
      'createdAt': createdAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (extractedEntities != null) 'extractedEntities': extractedEntities,
      if (extractedEntities != null) 'extracted_entities': extractedEntities,
      if (suggestedActions != null) 'suggestedActions': suggestedActions,
      if (suggestedActions != null) 'suggested_actions': suggestedActions,
    };
  }
}

// Model for auto-classification preview
class TaskClassification {
  final TaskCategory category;
  final TaskPriority priority;
  final Map<String, dynamic>? extractedEntities;
  final List<String>? suggestedActions;

  TaskClassification({
    required this.category,
    required this.priority,
    this.extractedEntities,
    this.suggestedActions,
  });

  factory TaskClassification.fromJson(Map<String, dynamic> json) {
    return TaskClassification(
      category: TaskCategory.fromString(
        json['category']?.toString() ?? 'Other',
      ),
      priority: TaskPriority.fromString(
        json['priority']?.toString() ?? 'Medium',
      ),
      extractedEntities:
          json['extractedEntities'] != null ||
              json['extracted_entities'] != null
          ? (json['extractedEntities'] ?? json['extracted_entities'])
                as Map<String, dynamic>?
          : null,
      suggestedActions:
          json['suggestedActions'] != null || json['suggested_actions'] != null
          ? List<String>.from(
              json['suggestedActions'] ?? json['suggested_actions'] ?? [],
            )
          : null,
    );
  }
}

enum TaskStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed');

  final String value;
  const TaskStatus(this.value);

  static TaskStatus fromString(String value) {
    final normalized = value.trim();
    // Try case-sensitive match first
    for (final status in TaskStatus.values) {
      if (status.value == normalized) {
        return status;
      }
    }
    // Try case-insensitive match
    for (final status in TaskStatus.values) {
      if (status.value.toLowerCase() == normalized.toLowerCase()) {
        return status;
      }
    }
    // Handle common variations
    final lowerValue = normalized.toLowerCase();
    if (lowerValue == 'in progress' ||
        lowerValue == 'inprogress' ||
        lowerValue == 'in_progress') {
      return TaskStatus.inProgress;
    }
    if (lowerValue == 'completed' || lowerValue == 'complete') {
      return TaskStatus.completed;
    }
    if (lowerValue == 'pending') {
      return TaskStatus.pending;
    }
    return TaskStatus.pending;
  }
}

enum TaskCategory {
  work('Work'),
  personal('Personal'),
  shopping('Shopping'),
  health('Health'),
  other('Other');

  final String value;
  const TaskCategory(this.value);

  static TaskCategory fromString(String value) {
    final normalized = value.trim();
    
    // First try exact match with enum values
    for (final category in TaskCategory.values) {
      if (category.value.toLowerCase() == normalized.toLowerCase()) {
        return category;
      }
    }
    
    // Handle descriptive category names (Scheduling, Finance, Technical, Safety, General)
    // Map them to appropriate enum values
    final lowerValue = normalized.toLowerCase();
    switch (lowerValue) {
      case 'scheduling':
      case 'finance':
      case 'technical':
        return TaskCategory.work; // All map to Work
      case 'safety':
        return TaskCategory.health; // Safety maps to Health
      case 'general':
        return TaskCategory.other; // General maps to Other
      default:
        return TaskCategory.other;
    }
  }

  static Color getColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return Colors.blue;
      case TaskCategory.personal:
        return Colors.green;
      case TaskCategory.shopping:
        return Colors.orange;
      case TaskCategory.health:
        return Colors.red;
      case TaskCategory.other:
        return Colors.grey;
    }
  }
}

enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  final String value;
  const TaskPriority(this.value);

  static TaskPriority fromString(String value) {
    if (value.isEmpty || value.trim().isEmpty) {
      return TaskPriority.medium;
    }
    
    final normalized = value.trim().toLowerCase();

    // First try to match display values like "Low", "Medium", "High" ignoring case
    for (final p in TaskPriority.values) {
      if (p.value.toLowerCase() == normalized) {
        return p;
      }
    }

    // Handle common variations and raw backend values
    switch (normalized) {
      case 'low':
      case '1':
      case 'lowest':
        return TaskPriority.low;
      case 'high':
      case '3':
      case 'highest':
      case 'urgent':
      case 'critical':
        return TaskPriority.high;
      case 'medium':
      case '2':
      case 'normal':
      case 'moderate':
      default:
        return TaskPriority.medium;
    }
  }

  static Color getColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}
