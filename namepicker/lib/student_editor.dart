import 'package:flutter/material.dart';
import 'student.dart';
import 'student_db.dart';

class StudentEditorPage extends StatefulWidget {
  const StudentEditorPage({Key? key}) : super(key: key);

  @override
  State<StudentEditorPage> createState() => _StudentEditorPageState();
}

class _StudentEditorPageState extends State<StudentEditorPage> {
  Future<void> _importCsvDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('从早期NamePicker版本导入'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('请粘贴CSV内容（使用文本编辑器打开csv文件，复制内容并粘贴即可，需要包含表头）'),
            SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 6,
              maxLines: 12,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: Text('导入'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (result == true && controller.text.trim().isNotEmpty) {
      final error = await _importCsv(controller.text.trim());
      if (error != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('导入失败'),
            content: Text(error),
            actions: [TextButton(child: Text('确定'), onPressed: () => Navigator.of(ctx).pop())],
          ),
        );
      } else {
        await _loadStudents();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入完成')));
      }
    }
  }

  Future<String?> _importCsv(String csvText) async {
    final lines = csvText.split(RegExp(r'\r?\n'));
    if (lines.isEmpty || lines.length < 2) {
      return '内容为空或没有数据行。';
    }
    final header = lines.first.trim().toLowerCase();
    if (!(header.contains('name') && header.contains('sex') && header.contains('no'))) {
      return '首行必须包含字段：name,sex,no';
    }
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 3) {
        return '第${i+1}行字段数量不足（应为3个，用英文逗号分隔）';
      }
      final name = parts[0].trim();
      final sexRaw = parts[1].trim();
      final no = parts[2].trim();
      if (name.isEmpty || no.isEmpty) {
        return '第${i+1}行姓名或学号为空';
      }
      String gender = '男';
      if (sexRaw == '1') gender = '女';
      // 其他值视为男
      final student = Student(name: name, gender: gender, studentId: no);
      await StudentDatabase.instance.create(student);
    }
    return null;
  }
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
      // appBar: AppBar(title: Text('名单编辑器')),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () => _addOrEditStudent(),
            child: Icon(Icons.add),
            tooltip: '添加学生',
          ),
          SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _importCsvDialog,
            child: Icon(Icons.upload_file),
            tooltip: '从早期NamePicker版本导入',
          ),
        ],
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
