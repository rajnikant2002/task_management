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

  Future<List<Task>> getTasks({
    TaskStatus? status,
    String? category,
    TaskPriority? priority,
    String? search,
  }) async {
    try {
      // Build query parameters for backend filtering
      final queryParams = <String, dynamic>{};
      if (status != null) {
        // Convert status enum to backend format (e.g., "Pending", "In Progress", "Completed")
        queryParams['status'] = status.value;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (priority != null) {
        queryParams['priority'] = priority.value;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get('/tasks', queryParameters: queryParams);

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

  /// Fetch a single task by ID with history
  Future<Task> getTaskById(String id) async {
    try {
      // URL encode the ID to handle special characters
      final encodedId = Uri.encodeComponent(id);
      final response = await _dio.get('/tasks/$encodedId');

      // Handle different response structures
      Map<String, dynamic> data;
      if (response.data is Map && response.data.containsKey('data')) {
        data = response.data['data'] as Map<String, dynamic>;
      } else if (response.data is Map) {
        data = response.data as Map<String, dynamic>;
      } else {
        throw Exception('Invalid response format');
      }

      return Task.fromJson(data);
    } catch (e) {
      print('❌ Error fetching task by ID: $e');

      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          throw Exception('Task not found');
        }
        if (e.response?.statusCode == 503) {
          final errorMessage =
              e.response?.data?['message'] ??
              'Service temporarily unavailable. Database connection issue.';
          throw Exception(errorMessage);
        }
        if (e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          throw Exception(
            'Request timeout. The server is taking too long to respond.',
          );
        }
        if (e.type == DioExceptionType.connectionError) {
          throw Exception(
            'Cannot connect to server. Please check your internet connection.',
          );
        }
        if (e.response != null) {
          final statusCode = e.response!.statusCode;
          final errorMessage =
              e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              'Server error ($statusCode)';
          throw Exception(errorMessage);
        }
      }

      throw Exception('Failed to fetch task: ${e.toString()}');
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

  /// Update task with raw data to trigger re-classification (when title/description changes)
  Future<Task> updateTaskRaw(
    String taskId,
    Map<String, dynamic> rawData,
  ) async {
    try {
      // Send only raw user input to trigger backend re-classification
      final response = await _dio.patch('/tasks/$taskId', data: rawData);
      final serverTask = Task.fromJson(response.data['data'] ?? response.data);
      return serverTask; // Backend re-classified the task
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

  Future<Task> updateTask(Task task) async {
    try {
      // Backend uses PATCH /api/tasks/{id}
      final response = await _dio.patch(
        '/tasks/${task.id}',
        data: task.toJson(),
      );
      // Backend is source of truth - use server response directly
      return Task.fromJson(response.data['data'] ?? response.data);
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
}
