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
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      assignedTo: json['assignedTo'] as String,
      status: TaskStatus.fromString(json['status'] as String),
      category: TaskCategory.fromString(json['category'] as String),
      priority: TaskPriority.fromString(json['priority'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'assignedTo': assignedTo,
      'status': status.value,
      'category': category.value,
      'priority': priority.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

enum TaskStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed');

  final String value;
  const TaskStatus(this.value);

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskStatus.pending,
    );
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
    return TaskCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskCategory.other,
    );
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
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.medium,
    );
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