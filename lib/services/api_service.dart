import 'package:dio/dio.dart';
import '../models/task.dart';

class ApiService {
  late final Dio _dio;
  final String baseUrl;

  ApiService({this.baseUrl = 'http://localhost:3000/api'}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
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
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final response = await _dio.post('/tasks', data: task.toJson());
      return Task.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      final response = await _dio.put('/tasks/${task.id}', data: task.toJson());
      return Task.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('/tasks/$id');
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<Map<String, dynamic>> classifyTask(
    String title,
    String description,
  ) async {
    try {
      final response = await _dio.post(
        '/tasks/classify',
        data: {'title': title, 'description': description},
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      // Return default values if classification fails
      return {'category': 'other', 'priority': 'medium'};
    }
  }
}
