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
  List<Task> _filteredTasks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  TaskCategory? _selectedCategory;
  TaskPriority? _selectedPriority;
  TaskStatus? _selectedStatus;

  List<Task> get tasks => _filteredTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _connectivityService.isConnected;

  // Filter getters
  TaskCategory? get selectedCategory => _selectedCategory;
  TaskPriority? get selectedPriority => _selectedPriority;
  TaskStatus? get selectedStatus => _selectedStatus;

  int get pendingCount =>
      _tasks.where((t) => t.status == TaskStatus.pending).length;
  int get inProgressCount =>
      _tasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get completedCount =>
      _tasks.where((t) => t.status == TaskStatus.completed).length;

  Future<void> _loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _apiService.getTasks();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTasks() async {
    await _loadTasks();
  }

  Future<void> createTask(Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTask = await _apiService.createTask(task);
      _tasks.add(newTask);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedTask = await _apiService.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        _applyFilters();
      }
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
      await _apiService.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> classifyTask(
    String title,
    String description,
  ) async {
    try {
      return await _apiService.classifyTask(title, description);
    } catch (e) {
      return {'category': 'other', 'priority': 'medium'};
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setCategoryFilter(TaskCategory? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setPriorityFilter(TaskPriority? priority) {
    _selectedPriority = priority;
    _applyFilters();
  }

  void setStatusFilter(TaskStatus? status) {
    _selectedStatus = status;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedPriority = null;
    _selectedStatus = null;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredTasks = _tasks.where((task) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == null || task.category == _selectedCategory;
      final matchesPriority =
          _selectedPriority == null || task.priority == _selectedPriority;
      final matchesStatus =
          _selectedStatus == null || task.status == _selectedStatus;

      return matchesSearch &&
          matchesCategory &&
          matchesPriority &&
          matchesStatus;
    }).toList();
    notifyListeners();
  }
}
