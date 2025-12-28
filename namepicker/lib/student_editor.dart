import 'main.dart';
import 'package:flutter/material.dart';
import 'student.dart';
import 'student_db.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

class StudentEditorPage extends StatefulWidget {
  const StudentEditorPage({Key? key}) : super(key: key);

  @override
  State<StudentEditorPage> createState() => _StudentEditorPageState();
}

class _StudentEditorPageState extends State<StudentEditorPage> {
  List<ListGroup> lists = [];
  int? currentListId;
  List<Student> students = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initLists();
  }

  Future<void> _initLists({bool notifyGlobal = false}) async {
    lists = await StudentDatabase.instance.readAllLists();
    if (lists.isEmpty) {
      int id = await StudentDatabase.instance.createList('默认名单');
      lists = await StudentDatabase.instance.readAllLists();
      currentListId = id;
    } else {
      currentListId = lists.first.id;
    }
    await _loadStudents();
    setState(() {});
    if (notifyGlobal) {
      // 通知全局 Provider 刷新
      if (mounted) {
        final appState = Provider.of<MyAppState>(context, listen: false);
        appState.notifyListeners();
      }
    }
  }

  Future<void> _loadStudents() async {
    if (currentListId == null) return;
    students = await StudentDatabase.instance.readAll(currentListId!);
    setState(() {
      loading = false;
    });
  }

  Future<void> _addOrEditStudent([Student? student]) async {
    final result = await showDialog<Student>(
      context: context,
      builder: (context) => StudentDialog(student: student),
    );
    if (result != null) {
      if (student == null) {
        await StudentDatabase.instance.create(result, currentListId!);
      } else {
        await StudentDatabase.instance.update(result);
      }
      await _loadStudents();
      // 通知全局 Provider 刷新
      if (mounted) {
        final appState = Provider.of<MyAppState>(context, listen: false);
        appState.notifyListeners();
      }
    }
  }

  Future<void> _deleteStudent(Student student) async {
    await StudentDatabase.instance.delete(student.id!);
    await _loadStudents();
    // 通知全局 Provider 刷新
    if (mounted) {
      final appState = Provider.of<MyAppState>(context, listen: false);
      appState.notifyListeners();
    }
  }

  Future<void> _exportCsvDialog() async {
    final buffer = StringBuffer();
    buffer.writeln('name,sex,no');
    for (final s in students) {
      final sexRaw = s.gender == '女' ? '1' : '0';
      buffer.writeln('${s.name},${sexRaw},${s.studentId}');
    }
    if (kIsWeb) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Web端暂不支持导出')));
      return;
    }
    if (Platform.isAndroid) {
      final dir = '/storage/emulated/0/Download';
      final file = File('$dir/namepicker.csv');
      await file.writeAsString(buffer.toString(), flush: true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出完成: $dir/namepicker.csv')));
    } else {
      String? outputPath;
      try {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: '导出名单为CSV',
          fileName: 'namepicker.csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );
      } catch (e) {
        outputPath = null;
      }
      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(buffer.toString(), flush: true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出完成: $outputPath')));
      }
    }
  }

  Future<void> _importCsvDialog() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: "选择早期NamePicker版本的名单文件",
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final error = await _importCsv(content);
      if (error != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('导入失败'),
            content: Text(error),
            actions: [
              TextButton(
                child: Text('确定'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      } else {
        await _loadStudents();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入完成')));
      }
    }
  }

  Future<String?> _importCsv(String csvText) async {
    if (currentListId == null) return '请先选择名单';
    final lines = csvText.split(RegExp(r'\r?\n'));
    if (lines.isEmpty || lines.length < 2) {
      return '内容为空或没有数据行。';
    }
    final header = lines.first.trim().toLowerCase();
    if (!(header.contains('name') &&
        header.contains('sex') &&
        header.contains('no'))) {
      return '首行必须包含字段：name,sex,no';
    }
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 3) {
        return '第{i+1}行字段数量不足（应为3个，用英文逗号分隔）';
      }
      final name = parts[0].trim();
      final sexRaw = parts[1].trim();
      final no = parts[2].trim();
      if (name.isEmpty || no.isEmpty) {
        return '第{i+1}行姓名或学号为空';
      }
      String gender = '男';
      if (sexRaw == '1') gender = '女';
      final student = Student(name: name, gender: gender, studentId: no);
      await StudentDatabase.instance.create(student, currentListId!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('名单编辑器'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: PopupMenuButton<int>(
              tooltip: '选择/管理名单',
              initialValue: currentListId,
              onSelected: (id) async {
                currentListId = id;
                await _loadStudents();
                setState(() {});
              },
              itemBuilder: (context) => [
                for (final l in lists)
                  PopupMenuItem<int>(
                    value: l.id,
                    child: Row(
                      children: [
                        Icon(
                          l.id == currentListId
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: l.id == currentListId
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text(l.name)),
                        IconButton(
                          icon: Icon(Icons.edit, size: 16),
                          tooltip: '重命名',
                          onPressed: () async {
                            Navigator.pop(context); // 关闭菜单
                            final name = await showDialog<String>(
                              context: context,
                              builder: (ctx) {
                                final controller = TextEditingController(
                                  text: l.name,
                                );
                                return AlertDialog(
                                  title: Text('重命名单'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: '名单名',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('取消'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, controller.text),
                                      child: Text('保存'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (name != null && name.isNotEmpty) {
                              await StudentDatabase.instance.updateList(
                                ListGroup(id: l.id, name: name),
                              );
                              await _initLists(notifyGlobal: true);
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 16),
                          tooltip: '删除',
                          onPressed: () async {
                            Navigator.pop(context); // 关闭菜单
                            if (lists.length == 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('至少保留一个名单')),
                              );
                              return;
                            }
                            await StudentDatabase.instance.deleteList(l.id!);
                            await _initLists(notifyGlobal: true);
                          },
                        ),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem<int>(
                  value: -1,
                  enabled: true,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 8),
                      Text('新建名单'),
                    ],
                  ),
                  onTap: () async {
                    final name = await showDialog<String>(
                      context: context,
                      builder: (ctx) {
                        final controller = TextEditingController();
                        return AlertDialog(
                          title: Text('新建名单'),
                          content: TextField(
                            controller: controller,
                            decoration: InputDecoration(labelText: '名单名'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('取消'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, controller.text),
                              child: Text('创建'),
                            ),
                          ],
                        );
                      },
                    );
                    if (name != null && name.isNotEmpty) {
                      await StudentDatabase.instance.createList(name);
                      await _initLists(notifyGlobal: true);
                    }
                  },
                ),
              ],
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    lists.isEmpty
                        ? '无名单'
                        : (lists
                              .firstWhere(
                                (l) => l.id == currentListId,
                                orElse: () => lists.first,
                              )
                              .name),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
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
        onPressed: () async {
          final selected = await showModalBottomSheet<String>(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.add),
                    title: Text('添加学生'),
                    onTap: () => Navigator.of(ctx).pop('add'),
                  ),
                  ListTile(
                    leading: Icon(Icons.upload_file),
                    title: Text('导入名单'),
                    onTap: () => Navigator.of(ctx).pop('import'),
                  ),
                  ListTile(
                    leading: Icon(Icons.download),
                    title: Text('导出名单'),
                    onTap: () => Navigator.of(ctx).pop('export'),
                  ),
                ],
              ),
            ),
          );
          if (selected == 'add') {
            _addOrEditStudent();
          } else if (selected == 'import') {
            _importCsvDialog();
          } else if (selected == 'export') {
            _exportCsvDialog();
          }
        },
        child: Icon(Icons.add),
        tooltip: '操作',
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
            items: [
              '男',
              '女',
            ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => setState(() => gender = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),
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
