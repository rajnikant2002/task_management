import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String assignedTo;
  final TaskStatus status;
  final TaskCategory? category; // Optional - use backendCategoryName instead
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? extractedEntities;
  final List<String>? suggestedActions;
  final String?
  backendCategoryName; // Store original backend category name (scheduling, finance, etc.)

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.assignedTo,
    required this.status,
    this.category,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.extractedEntities,
    this.suggestedActions,
    this.backendCategoryName,
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
    String? backendCategoryName,
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
      backendCategoryName: backendCategoryName ?? this.backendCategoryName,
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
        // Category enum not needed - use backendCategoryName instead
        category: null,
        // Store backend category name directly (just fetch and store)
        backendCategoryName: json['category']?.toString().toLowerCase(),
        // Parse priority from backend (just convert string to enum for type safety)
        priority: TaskPriority.fromString(
          json['priority']?.toString() ??
              json['task_priority']?.toString() ??
              'medium',
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
        // Use extractedEntities directly from backend - no client-side modifications
        extractedEntities:
            json['extractedEntities'] != null ||
                json['extracted_entities'] != null
            ? Map<String, dynamic>.from(
                json['extractedEntities'] ?? json['extracted_entities'] ?? {},
              )
            : null,
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

  // Get the display category name directly from backend
  String getDisplayCategoryName() => backendCategoryName ?? 'general';

  Map<String, dynamic> toJson() {
    // Send only user-editable fields in snake_case (backend format)
    // Priority, category, extracted_entities, suggested_actions come from backend auto-suggestion
    // Used only for regular updates (not raw updates)
    final json = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      'assigned_to': assignedTo,
      'status':
          status.value, // Status can be user-changed (e.g., mark as completed)
      // Priority comes from backend - don't send
      // Category comes from backend - don't send (unless override)
      // extracted_entities and suggested_actions come from backend - don't send
    };

    return json;
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

// Minimal enum - only kept for type safety, not used for logic
enum TaskCategory {
  work('Work'),
  personal('Personal'),
  shopping('Shopping'),
  health('Health'),
  other('Other');

  final String value;
  const TaskCategory(this.value);
}

// Helper class for backend category colors (not using enum)
class TaskCategoryHelper {
  // Get color based on backend category name
  static Color getColorFromBackendCategory(String? backendCategoryName) {
    switch (backendCategoryName?.toLowerCase()) {
      case 'scheduling':
        return Colors.green;
      case 'finance':
        return Colors.orange;
      case 'technical':
        return Colors.blue;
      case 'safety':
        return Colors.red;
      case 'general':
        return Colors.grey;
      default:
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

  // Simple parsing - backend sends "low", "medium", or "high"
  static TaskPriority fromString(String value) {
    final normalized = value.trim().toLowerCase();

    // Backend sends: "low", "medium", "high" (case-insensitive)
    switch (normalized) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'medium':
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
