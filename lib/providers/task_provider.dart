import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  TaskProvider({
    required ApiService apiService,
    required ConnectivityService connectivityService,
  }) : _apiService = apiService,
       _connectivityService = connectivityService {
    _loadTasks();
    _connectivityService.connectivityStream.listen((isConnected) {
      notifyListeners();
    });
  }

  List<Task> _tasks = [];
  List<Task> _allTasksForCounts = []; // Keep all tasks for summary counts
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String?
  _selectedCategory; // Use backend category name (scheduling, finance, etc.)
  TaskPriority? _selectedPriority;
  TaskStatus? _selectedStatus;

  List<Task> get tasks => _tasks; // Tasks are already filtered by backend
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _connectivityService.isConnected;

  // Filter getters
  String? get selectedCategory => _selectedCategory; // Backend category name
  TaskPriority? get selectedPriority => _selectedPriority;
  TaskStatus? get selectedStatus => _selectedStatus;

  // Get a task by ID from the full task list (not filtered)
  Task? getTaskById(String id) {
    try {
      // First check filtered tasks
      return _tasks.firstWhere((t) => t.id == id);
    } catch (e) {
      // If not found in filtered list, check all tasks
      try {
        return _allTasksForCounts.firstWhere((t) => t.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  /// Fetch a single task from API by ID (includes history)
  Future<Task> fetchTaskById(String id) async {
    try {
      final task = await _apiService.getTaskById(id);
      // Update the task in local lists if it exists
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = task;
      }
      final allIndex = _allTasksForCounts.indexWhere((t) => t.id == id);
      if (allIndex != -1) {
        _allTasksForCounts[allIndex] = task;
      }
      notifyListeners();
      return task;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  int get pendingCount =>
      _allTasksForCounts.where((t) => t.status == TaskStatus.pending).length;
  int get inProgressCount =>
      _allTasksForCounts.where((t) => t.status == TaskStatus.inProgress).length;
  int get completedCount =>
      _allTasksForCounts.where((t) => t.status == TaskStatus.completed).length;

  Future<void> _loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch filtered tasks from backend
      _tasks = await _apiService.getTasks(
        status: _selectedStatus,
        category: _selectedCategory,
        priority: _selectedPriority,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      // Also fetch all tasks for summary counts (without filters)
      _allTasksForCounts = await _apiService.getTasks();

      _error = null; // Clear error on success
    } catch (e) {
      // Extract clean error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      _error = errorMessage;
      print('❌ TaskProvider error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTasks() async {
    await _loadTasks();
  }

  /// Create task with raw user input only (backend handles classification)
  Future<Task> createTaskRaw(Map<String, dynamic> rawData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTask = await _apiService.createTaskRaw(rawData);
      // Reload tasks from backend to get filtered results
      await _loadTasks();
      return newTask;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update task with raw data to trigger re-classification
  Future<Task> updateTaskRaw(
    String taskId,
    Map<String, dynamic> rawData,
  ) async {
    try {
      final updatedTask = await _apiService.updateTaskRaw(taskId, rawData);
      // Reload tasks from backend to get filtered results
      await _loadTasks();
      return updatedTask;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Update task with category/priority override
  /// Note: Doesn't set loading state to avoid blank screen during dialog confirmation
  Future<void> updateTaskWithOverride(
    String taskId, {
    required String categoryName,
    required TaskPriority priority,
  }) async {
    // Don't set loading state - this is called during dialog confirmation
    // Setting loading would cause blank screen when dialogs close
    _error = null;

    try {
      await _apiService.updateTaskOverride(
        taskId,
        categoryName: categoryName,
        priority: priority,
      );
      // Reload tasks from backend to get filtered results
      await _loadTasks();
      notifyListeners(); // Notify after update
    } catch (e) {
      _error = e.toString();
      notifyListeners(); // Notify even on error
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateTask(task);
      // Reload tasks from backend to get filtered results
      await _loadTasks();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate ID
      if (id.isEmpty) {
        throw Exception('Cannot delete task: Invalid task ID');
      }

      // Try to delete from API first
      await _apiService.deleteTask(id);

      // Reload tasks from backend to get filtered results
      await _loadTasks();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      _error = errorMessage;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _loadTasks(); // Reload from backend with new search query
  }

  void setCategoryFilter(String? categoryName) {
    _selectedCategory = categoryName;
    _loadTasks(); // Reload from backend with new category filter
  }

  void setPriorityFilter(TaskPriority? priority) {
    _selectedPriority = priority;
    _loadTasks(); // Reload from backend with new priority filter
  }

  void setStatusFilter(TaskStatus? status) {
    _selectedStatus = status;
    _loadTasks(); // Reload from backend with new status filter
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedPriority = null;
    _selectedStatus = null;
    _loadTasks(); // Reload from backend without filters
  }
}
