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
              ? 'http://10.0.2.2:3000/api' // Android emulator uses 10.0.2.2 to access host machine's localhost
              : 'http://localhost:3000/api') {
    // Debug: Print the base URL being used
    print('🔗 API Base URL: $baseUrl');
    print('📱 Platform: ${Platform.operatingSystem}');

    _dio = Dio(
      BaseOptions(
        baseUrl: this.baseUrl,
        connectTimeout: const Duration(seconds: 60), // Increased for Render.com
        receiveTimeout: const Duration(
          seconds: 60,
        ), // Increased for slow database queries
        // sendTimeout: const Duration(seconds: 30),
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

      // Handle specific DioException types
      if (e is DioException) {
        // Handle 503 Service Unavailable (database connection issue)
        if (e.response?.statusCode == 503) {
          final errorMessage =
              e.response?.data?['message'] ??
              'Service temporarily unavailable. Database connection issue.';
          throw Exception(errorMessage);
        }

        // Handle timeout errors
        if (e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          throw Exception(
            'Request timeout. The server is taking too long to respond. '
            'This may happen on Render.com free tier. Please try again.',
          );
        }

        // Handle connection errors
        if (e.type == DioExceptionType.connectionError) {
          throw Exception(
            'Cannot connect to server. Please check your internet connection.',
          );
        }

        // Handle other HTTP errors
        if (e.response != null) {
          final statusCode = e.response!.statusCode;
          final errorMessage =
              e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              'Server error ($statusCode)';
          throw Exception(errorMessage);
        }
      }

      throw Exception('Failed to fetch tasks: ${e.toString()}');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final response = await _dio.post('/tasks', data: task.toJson());
      final serverTask = Task.fromJson(response.data['data'] ?? response.data);
      return _mergeWithLocal(serverTask, task);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 503) {
          final errorMessage =
              e.response?.data?['message'] ??
              'Service temporarily unavailable. Database connection issue.';
          throw Exception(errorMessage);
        }
        if (e.response != null) {
          final errorMessage =
              e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              'Server error (${e.response!.statusCode})';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Failed to create task: ${e.toString()}');
    }
  }

  /// Create task with only raw user input (no classification)
  /// Backend will handle all classification logic
  Future<Task> createTaskRaw(Map<String, dynamic> rawData) async {
    try {
      // Send only user input: title, description, due_date, assigned_to
      // NO category, priority, extractedEntities, suggestedActions
      final response = await _dio.post('/tasks', data: rawData);
      final serverTask = Task.fromJson(response.data['data'] ?? response.data);
      return serverTask; // Use server's response directly (backend did classification)
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 503) {
          final errorMessage =
              e.response?.data?['message'] ??
              'Service temporarily unavailable. Database connection issue.';
          throw Exception(errorMessage);
        }
        if (e.response != null) {
          final errorMessage =
              e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              'Server error (${e.response!.statusCode})';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Failed to create task: ${e.toString()}');
    }
  }

  /// Update task with category/priority override
  /// categoryName should be one of: scheduling, finance, technical, safety, general
  Future<Task> updateTaskOverride(
    String taskId, {
    required String categoryName,
    required TaskPriority priority,
  }) async {
    try {
      final response = await _dio.patch(
        '/tasks/$taskId',
        data: {
          'category':
              categoryName, // Send backend category name (e.g., "finance", "scheduling")
          'priority': priority.value,
        },
      );
      final serverTask = Task.fromJson(response.data['data'] ?? response.data);
      return serverTask;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 503) {
          final errorMessage =
              e.response?.data?['message'] ??
              'Service temporarily unavailable. Database connection issue.';
          throw Exception(errorMessage);
        }
        if (e.response != null) {
          final errorMessage =
              e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              'Server error (${e.response!.statusCode})';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Failed to update task override: ${e.toString()}');
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
      if (e is DioException) {
        if (e.response?.statusCode == 503) {
          final errorMessage =
              e.response?.data?['message'] ??
              'Service temporarily unavailable. Database connection issue.';
          throw Exception(errorMessage);
        }
        if (e.response != null) {
          final errorMessage =
              e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              'Server error (${e.response!.statusCode})';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Failed to update task: ${e.toString()}');
    }
  }

  Task _mergeWithLocal(Task server, Task local) {
    // Some backends omit optional fields in the response; keep local values when missing.
    // Always use server's ID if available (backend generates the real ID)
    // For extractedEntities/suggestedActions: Always use what we sent (local),
    // because we generate them client-side and backend may return empty/incomplete data
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
      // Always use what we sent - we generate extractedEntities client-side
      extractedEntities: local.extractedEntities,
      suggestedActions: local.suggestedActions,
    );
  }

  Future<void> deleteTask(String id) async {
    try {
      // Validate ID
      if (id.isEmpty) {
        throw Exception('Cannot delete task: Invalid task ID');
      }

      // URL encode the ID to handle special characters
      final encodedId = Uri.encodeComponent(id);
      print('🗑️ Attempting to delete task with ID: $id (encoded: $encodedId)');
      await _dio.delete('/tasks/$encodedId');
      print('✅ Task deleted successfully');
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          final errorMessage =
              e.response?.data?['message'] ??
              'Task not found (ID: $id). It may have already been deleted.';
          throw Exception(errorMessage);
        }
        if (e.response?.statusCode == 503) {
          final errorMessage =
              e.response?.data?['message'] ??
              'Service temporarily unavailable. Database connection issue.';
          throw Exception(errorMessage);
        }
        if (e.response != null) {
          final errorMessage =
              e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              'Server error (${e.response!.statusCode})';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Failed to delete task: ${e.toString()}');
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
