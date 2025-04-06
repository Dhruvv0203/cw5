import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TaskListScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const TaskListScreen({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool loading = true;

  String selectedDay = 'Monday';
  String selectedSlot = '9am-10am';

  Map<String, Map<String, List<Map<String, dynamic>>>> taskMap = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => loading = true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _firestore
        .collection('tasks')
        .where('user', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .get();

    final Map<String, Map<String, List<Map<String, dynamic>>>> data = {};
    for (final doc in snapshot.docs) {
      final t = doc.data();
      final day = t['day'] ?? 'Unknown';
      final slot = t['slot'] ?? 'Unknown';
      data[day] ??= {};
      data[day]![slot] ??= [];
      data[day]![slot]!.add({...t, 'id': doc.id});
    }

    setState(() {
      taskMap = data;
      loading = false;
    });
  }

  Future<void> _addTask() async {
    final titleController = TextEditingController();
    String localDay = selectedDay;
    String localSlot = selectedSlot;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('New Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Enter task')),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: localDay,
                  isExpanded: true,
                  onChanged: (value) => setDialogState(() => localDay = value!),
                  items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
                DropdownButton<String>(
                  value: localSlot,
                  isExpanded: true,
                  onChanged: (value) => setDialogState(() => localSlot = value!),
                  items: ['9am-10am', '10am-11am', '12pm-1pm', '2pm-3pm']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final uid = _auth.currentUser!.uid;
                  await _firestore.collection('tasks').add({
                    'title': titleController.text,
                    'user': uid,
                    'done': false,
                    'created_at': Timestamp.now(),
                    'day': localDay,
                    'slot': localSlot,
                  });
                  Navigator.pop(context);
                  _loadTasks();
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskTile(Map<String, dynamic> task) {
    return ListTile(
      title: Text(task['title']),
      leading: Checkbox(
        value: task['done'],
        onChanged: (val) async {
          await _firestore.collection('tasks').doc(task['id']).update({'done': val});
          _loadTasks();
        },
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          await _firestore.collection('tasks').doc(task['id']).delete();
          _loadTasks();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Task',
            onPressed: _addTask,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _auth.signOut();
            },
          ),
          IconButton(
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
            tooltip: 'Toggle Theme',
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : taskMap.isEmpty
              ? const Center(child: Text('No tasks yet. Add one using the "+" icon.'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: taskMap.entries.map((dayEntry) {
                    final day = dayEntry.key;
                    final slots = dayEntry.value;
                    return ExpansionTile(
                      title: Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      children: slots.entries.map((slotEntry) {
                        final slot = slotEntry.key;
                        final tasks = slotEntry.value;
                        return ExpansionTile(
                          title: Text(slot),
                          children: tasks.map(_buildTaskTile).toList(),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
    );
  }
}
....