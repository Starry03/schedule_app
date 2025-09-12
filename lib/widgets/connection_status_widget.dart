import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (dataProvider.isOnline && dataProvider.lastError == null) {
          // Connection is good, don't show anything to avoid clutter
          return const SizedBox.shrink();
        }
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: dataProvider.isOnline ? Colors.orange.shade100 : Colors.red.shade100,
          child: Row(
            children: [
              Icon(
                dataProvider.isOnline ? Icons.warning : Icons.cloud_off,
                color: dataProvider.isOnline ? Colors.orange : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dataProvider.lastError ?? 'Problemi di connessione al server',
                  style: TextStyle(
                    color: dataProvider.isOnline ? Colors.orange.shade800 : Colors.red.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!dataProvider.isOnline)
                TextButton(
                  onPressed: () {
                    // Try to reconnect by attempting to fetch teachers
                    dataProvider.fetchTeachers();
                  },
                  child: Text(
                    'Riprova',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}