import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final taskController = TextEditingController();
  String? userId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    } else {
      // If user is not logged in, go back to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    }
  }

  void addTask() {
    if (taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a task")),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
      return;
    }

    final taskText = taskController.text.trim();
    taskController.clear();

    FirebaseFirestore.instance
        .collection("users")
        .doc(userId!)
        .collection("tasks")
        .add({
      "title": taskText,
      "done": false,
      "timestamp": Timestamp.now(),
    }).then((_) {
      // Task added successfully
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding task: $e")),
        );
        taskController.text = taskText;
      }
    });
  }

  void updateTask(String id, String newTitle) {
    if (newTitle.trim().isEmpty || userId == null) return;
    
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId!)
        .collection("tasks")
        .doc(id)
        .update({"title": newTitle.trim()});
  }

  void deleteTask(String id) {
    if (userId == null) return;
    
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId!)
        .collection("tasks")
        .doc(id)
        .delete();
  }

  void toggleDone(String id, bool value) {
    if (userId == null) return;
    
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId!)
        .collection("tasks")
        .doc(id)
        .update({"done": value});
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            },
            child: Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.blue.shade600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add a new task",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: taskController,
                      decoration: InputDecoration(
                        hintText: "What needs to be done?",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(
                          Icons.add_circle_outline,
                          color: Colors.blue.shade600,
                        ),
                        suffixIcon: Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                            onPressed: addTask,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: userId == null
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .doc(userId!)
                          .collection("tasks")
                          .orderBy("timestamp", descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No tasks yet",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Add your first task to get started",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final id = docs[index].id;
                            final data = docs[index].data();

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () => toggleDone(id, !data["done"]),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: data["done"] ? Colors.green.shade600 : Colors.grey.shade200,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          data["done"] ? Icons.check : Icons.circle,
                                          color: data["done"] ? Colors.white : Colors.grey.shade400,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  data["title"],
                                  style: TextStyle(
                                    decoration: data["done"]
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: data["done"] ? Colors.grey.shade500 : Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18, color: Colors.blue.shade600),
                                          SizedBox(width: 8),
                                          Text("Edit"),
                                        ],
                                      ),
                                      onTap: () {
                                        Future.delayed(Duration.zero, () {
                                          final editController =
                                              TextEditingController(text: data["title"]);

                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text("Edit Task"),
                                              content: TextField(
                                                controller: editController,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    updateTask(id, editController.text);
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Save"),
                                                ),
                                              ],
                                            ),
                                          );
                                        });
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text("Delete"),
                                        ],
                                      ),
                                      onTap: () {
                                        Future.delayed(Duration.zero, () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text("Delete Task"),
                                              content: Text("Are you sure you want to delete this task?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    deleteTask(id);
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    taskController.dispose();
    super.dispose();
  }
}
