import 'package:flutter/material.dart';
import '../providers/task_provider.dart';

class OfflineIndicator extends StatelessWidget {
  final TaskProvider taskProvider;

  const OfflineIndicator({super.key, required this.taskProvider});

  @override
  Widget build(BuildContext context) {
    if (taskProvider.isConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.red,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'No Internet Connection',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}