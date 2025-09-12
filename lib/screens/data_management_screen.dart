import 'package:flutter/material.dart';
import 'teacher_management_screen.dart';
import 'subject_management_screen.dart';
import 'constraints_management_screen.dart';
import 'class_management_screen.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Modern card-like header with tabs
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Management',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        TabBar(
                          isScrollable: true,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(width: 3.0, color: Theme.of(context).colorScheme.primary),
                            insets: const EdgeInsets.symmetric(horizontal: 12.0),
                          ),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                          tabs: const [
                            Tab(text: 'Teachers'),
                            Tab(text: 'Classes'),
                            Tab(text: 'Constraints'),
                            Tab(text: 'Subjects'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    TeacherManagementScreen(),
                    ClassManagementScreen(),
                    ConstraintsManagementScreen(),
                    SubjectManagementScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
