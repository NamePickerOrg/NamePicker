import 'package:flutter/material.dart';
import 'student.dart';
import 'student_db.dart';

class StudentEditorPage extends StatefulWidget {
  const StudentEditorPage({Key? key}) : super(key: key);

  @override
  State<StudentEditorPage> createState() => _StudentEditorPageState();
}

class _StudentEditorPageState extends State<StudentEditorPage> {
  List<Student> students = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    students = await StudentDatabase.instance.readAll();
    setState(() { loading = false; });
  }

  Future<void> _addOrEditStudent([Student? student]) async {
    final result = await showDialog<Student>(
      context: context,
      builder: (context) => StudentDialog(student: student),
    );
    if (result != null) {
      if (student == null) {
        await StudentDatabase.instance.create(result);
      } else {
        await StudentDatabase.instance.update(result);
      }
      await _loadStudents();
    }
  }

  Future<void> _deleteStudent(Student student) async {
    await StudentDatabase.instance.delete(student.id!);
    await _loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('名单编辑器')),
      body: Container(
        color: colorScheme.surfaceContainer,
        child: loading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final s = students[index];
                  return ListTile(
                    title: Text(s.name),
                    subtitle: Text('学号: ${s.studentId} | 性别: ${s.gender}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _addOrEditStudent(s),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteStudent(s),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditStudent(),
        child: Icon(Icons.add),
        tooltip: '添加学生',
      ),
    );
  }
}

class StudentDialog extends StatefulWidget {
  final Student? student;
  const StudentDialog({Key? key, this.student}) : super(key: key);

  @override
  State<StudentDialog> createState() => _StudentDialogState();
}

class _StudentDialogState extends State<StudentDialog> {
  late TextEditingController nameController;
  late TextEditingController idController;
  String gender = '男';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.student?.name ?? '');
    idController = TextEditingController(text: widget.student?.studentId ?? '');
    gender = widget.student?.gender ?? '男';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.student == null ? '添加学生' : '编辑学生'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: '姓名'),
          ),
          TextField(
            controller: idController,
            decoration: InputDecoration(labelText: '学号'),
          ),
          DropdownButton<String>(
            value: gender,
            items: ['男', '女'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => setState(() => gender = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final s = Student(
              id: widget.student?.id,
              name: nameController.text,
              gender: gender,
              studentId: idController.text,
            );
            Navigator.pop(context, s);
          },
          child: Text('保存'),
        ),
      ],
    );
  }
}
