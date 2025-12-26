import 'dart:io';
import 'package:dio/dio.dart';
import '../models/task.dart';

class ApiService {
  late final Dio _dio;
  final String baseUrl;

  ApiService({String? baseUrl})
    : baseUrl =
          baseUrl ??
          (Platform.isAndroid
              ? 'http://10.0.2.2:3000/api' // Android emulator uses 10.0.2.2 to access host machine
              : 'http://localhost:3000/api') {
    // Debug: Print the base URL being used
    print('🔗 API Base URL: $baseUrl');
    print('📱 Platform: ${Platform.operatingSystem}');

    _dio = Dio(
      BaseOptions(
        baseUrl: this.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle unauthorized
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<List<Task>> getTasks() async {
    try {
      final response = await _dio.get('/tasks');

      // Handle different response structures
      List<dynamic> data;
      if (response.data is List) {
        // Response is directly a list
        data = response.data as List<dynamic>;
      } else if (response.data is Map && response.data.containsKey('data')) {
        // Response is wrapped in a 'data' key
        data = response.data['data'] as List<dynamic>;
      } else if (response.data is Map && response.data.containsKey('tasks')) {
        // Response might have 'tasks' key
        data = response.data['tasks'] as List<dynamic>;
      } else {
        // Fallback: try to use response.data as is
        data = [response.data];
      }

      return data.map((json) {
        try {
          return Task.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('❌ Error parsing task: $e');
          print('📦 Task data: $json');
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('❌ Error fetching tasks: $e');
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final response = await _dio.post('/tasks', data: task.toJson());
      final serverTask = Task.fromJson(response.data['data'] ?? response.data);
      return _mergeWithLocal(serverTask, task);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      // Backend uses PATCH /api/tasks/{id}
      final response = await _dio.patch(
        '/tasks/${task.id}',
        data: task.toJson(),
      );
      final serverTask = Task.fromJson(response.data['data'] ?? response.data);
      return _mergeWithLocal(serverTask, task);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Task _mergeWithLocal(Task server, Task local) {
    // Some backends omit optional fields in the response; keep local values when missing.
    return local.copyWith(
      id: server.id.isNotEmpty ? server.id : local.id,
      title: server.title.isNotEmpty ? server.title : local.title,
      description: server.description.isNotEmpty
          ? server.description
          : local.description,
      dueDate: server.dueDate ?? local.dueDate,
      assignedTo: server.assignedTo.isNotEmpty
          ? server.assignedTo
          : local.assignedTo,
      status: server.status,
      category: server.category,
      priority: server.priority,
      createdAt: server.createdAt,
      updatedAt: server.updatedAt,
    );
  }

  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('/tasks/$id');
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Get auto-classification for a task before creating it
  Future<TaskClassification> getAutoClassification({
    required String title,
    required String description,
  }) async {
    try {
      // Call backend to get auto-classification
      // This endpoint should analyze the title/description and return classification
      final response = await _dio.post(
        '/tasks/classify',
        data: {'title': title, 'description': description},
      );

      // Handle response structure
      final data = response.data['data'] ?? response.data;
      return TaskClassification.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      // If classification endpoint doesn't exist, return defaults
      // In a real scenario, you might want to handle this differently
      print('⚠️ Classification endpoint not available, using defaults: $e');
      return TaskClassification(
        category: TaskCategory.other,
        priority: TaskPriority.medium,
      );
    }
  }
}
