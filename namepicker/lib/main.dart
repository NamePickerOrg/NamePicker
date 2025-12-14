// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sprintf/sprintf.dart';
import 'settings_card.dart';
import 'student_editor.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'student_db.dart';
import 'student.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:url_launcher/url_launcher.dart';

// BIN 1 1111 1111 1111 0000 0000 0000 = DEC 33550336
// 众人将与一人离别，惟其人将觐见奇迹

// 「在彩虹桥的尽头，天空之子将缝补晨昏」
final version = "v3.0.0fin";
final codename = "Hyacine";
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();
  if (Platform.isMacOS) {
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
  } else {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  }
  await windowManager.setSize(const Size(900, 600));
  await windowManager.setMinimumSize(const Size(600, 400));
  await windowManager.center();
  runApp(MyApp());
}

randomGen(min, max) {
  var x = Random().nextInt(max) + min;
  return x.floor();
}

// 我萤伟大，无需多言
class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, _) {
          ThemeMode themeMode;
          switch (appState.themeMode) {
            case 0:
              themeMode = ThemeMode.system;
              break;
            case 1:
              themeMode = ThemeMode.light;
              break;
            case 2:
              themeMode = ThemeMode.dark;
              break;
            default:
              themeMode = ThemeMode.system;
          }
          return MaterialApp(
            title: 'NamePicker',
            theme: ThemeData(
              useMaterial3: true,
              useSystemColors: true,
              fontFamily: "HarmonyOS_Sans_SC",
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              useSystemColors: true,
              fontFamily: "HarmonyOS_Sans_SC",
              brightness: Brightness.dark,
            ),
            themeMode: themeMode,
            home: MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  MyAppState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    allowRepeat = prefs.getBool('allowRepeat') ?? true;
    themeMode = prefs.getInt('themeMode') ?? 0;
    filterGender = prefs.getString('filterGender') ?? "全部";
    filterNumberType = prefs.getString('filterNumberType') ?? "全部";
    notifyListeners();
  }
  // 是否允许重复抽取
  bool allowRepeat = true;
  // 已抽过学生id列表
  List<int> pickedIds = [];

  void setAllowRepeat(bool value) {
    allowRepeat = value;
    pickedIds.clear();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('allowRepeat', value);
    });
    notifyListeners();
  }
  var current = "别紧张...";
  var history = <String>[];

  GlobalKey? historyListKey;

  // 0: 跟随系统 1: 亮色 2: 暗色
  int themeMode = 0;

  // 筛选条件
  String filterGender = "全部"; // "全部" "男" "女"
  String filterNumberType = "全部"; // "全部" "单号" "双号"

  void setThemeMode(int mode) {
    themeMode = mode;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('themeMode', mode);
    });
    notifyListeners();
  }

  void setFilterGender(String gender) {
    filterGender = gender;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('filterGender', gender);
    });
    notifyListeners();
  }

  void setFilterNumberType(String type) {
    filterNumberType = type;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('filterNumberType', type);
    });
    notifyListeners();
  }

  Future<void> getNextStudent() async {
    // 获取所有学生
    final all = await StudentDatabase.instance.readAll();
    // 按性别筛选
    List<Student> filtered = all;
    if (filterGender != "全部") {
      filtered = filtered.where((s) => s.gender == filterGender).toList();
    }
    // 按学号单双筛选
    if (filterNumberType != "全部") {
      filtered = filtered.where((s) {
        final num = int.tryParse(s.studentId);
        if (num == null) return false;
        if (filterNumberType == "单号") return num % 2 == 1;
        if (filterNumberType == "双号") return num % 2 == 0;
        return true;
      }).toList();
    }
    // 不允许重复时，过滤已抽过
    if (!allowRepeat) {
      filtered = filtered.where((s) => !pickedIds.contains(s.id)).toList();
      if (filtered.isEmpty && all.isNotEmpty) {
        // 所有人都抽过，重置
        pickedIds.clear();
        filtered = all;
        if (filterGender != "全部") {
          filtered = filtered.where((s) => s.gender == filterGender).toList();
        }
        if (filterNumberType != "全部") {
          filtered = filtered.where((s) {
            final num = int.tryParse(s.studentId);
            if (num == null) return false;
            if (filterNumberType == "单号") return num % 2 == 1;
            if (filterNumberType == "双号") return num % 2 == 0;
            return true;
          }).toList();
        }
      }
    }
    if (filtered.isEmpty) {
      current = "无符合条件学生";
    } else {
      final picked = filtered[Random().nextInt(filtered.length)];
      current = "${picked.name}（${picked.studentId}）";
      if (!allowRepeat && picked.id != null) {
        pickedIds.add(picked.id!);
      }
    }
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = NameListPage();
        break;
      case 2:
        page = SettingsPage();
        break;
      case 3:
        page = AboutPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // The container for the current page, with its background color
    // and subtle switching animation.
    var mainArea = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          if (!Platform.isMacOS) CustomTitleBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 450) {
                  return Column(
                    children: [
                      Expanded(child: mainArea),
                      SafeArea(
                        child: BottomNavigationBar(
                          items: [
                            BottomNavigationBarItem(
                              icon: Icon(Icons.home),
                              label: '主页',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.list),
                              label: '名单',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.settings),
                              label: '设置',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.info),
                              label: '关于',
                            ),
                          ],
                          currentIndex: selectedIndex,
                          onTap: (value) {
                            setState(() {
                              selectedIndex = value;
                            });
                          },
                        ),
                      )
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      SafeArea(
                        child: NavigationRail(
                          extended: constraints.maxWidth >= 600,
                          destinations: [
                            NavigationRailDestination(
                              icon: Icon(Icons.home),
                              label: Text("主页"),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.list),
                              label: Text("名单"),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.settings),
                              label: Text("设置"),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.info),
                              label: Text("关于"),
                            ),
                          ],
                          selectedIndex: selectedIndex,
                          onDestinationSelected: (value) {
                            setState(() {
                              selectedIndex = value;
                            });
                          },
                        ),
                      ),
                      Expanded(child: mainArea),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
  );
  }
}

class CustomTitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) {
        windowManager.startDragging();
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surfaceContainerHighest.withValues(alpha:0.95),
              colorScheme.primary.withValues(alpha:0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant, width: 1)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha:0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/NamePicker.png', width: 28, height: 28),
            ),
            SizedBox(width: 10),
            Text(
              'NamePicker',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: "HarmonyOS_Sans_SC",
                color: colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(width: 8),
            Container(
              width: 1, height: 20,
              color: colorScheme.outlineVariant,
            ),
            Spacer(),
            _TitleBarButton(
              icon: Icons.minimize,
              tooltip: '最小化',
              onTap: () => windowManager.minimize(),
              color: colorScheme.onSurfaceVariant,
            ),
            _TitleBarButton(
              icon: Icons.crop_square,
              tooltip: '最大化/还原',
              onTap: () async {
                bool isMax = await windowManager.isMaximized();
                if (isMax) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              color: colorScheme.onSurfaceVariant,
            ),
            _TitleBarButton(
              icon: Icons.close,
              tooltip: '关闭',
              onTap: () => windowManager.close(),
              color: colorScheme.error,
              hoverColor: colorScheme.errorContainer,
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _TitleBarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  final Color? hoverColor;
  const _TitleBarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
    this.hoverColor,
  });

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _hovering
                ? (widget.hoverColor ?? Theme.of(context).colorScheme.primary..withValues(alpha:0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          width: 32,
          height: 32,
          child: Icon(widget.icon, size: 18, color: widget.color),
        ),
      ),
    );
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  // 已移除范围相关控制器和生命周期方法

  int _pickCount = 1;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // 展示最近抽选的结果列表（取前N条）
    final resultList = appState.history.take(_pickCount).toList();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            // 抽选结果列表（修复overflow，限制最大高度并可滚动）
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list_alt_outlined, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 8),
                        Text('抽选结果', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (resultList.isEmpty)
                      Text('暂无抽选结果', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    if (resultList.isNotEmpty)
                      SizedBox(
                        // 限制最大高度，超出可滚动
                        height: 200,
                        child: ListView.separated(
                          itemCount: resultList.length,
                          separatorBuilder: (_, __) => Divider(height: 1),
                          itemBuilder: (context, idx) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text('${idx + 1}', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                              ),
                              title: Text(resultList[idx], style: TextStyle(fontWeight: FontWeight.w500)),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_alt_outlined, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 8),
                        Text('筛选条件', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('性别：'),
                        DropdownButton<String>(
                          value: appState.filterGender,
                          items: ['全部', '男', '女'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => appState.setFilterGender(v!),
                        ),
                        SizedBox(width: 20),
                        Text('学号类型：'),
                        DropdownButton<String>(
                          value: appState.filterNumberType,
                          items: ['全部', '单号', '双号'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => appState.setFilterNumberType(v!),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      spacing: 10,
                      children: [
                        Text("抽选人数:"),
                        IconButton(
                          onPressed: () {
                            if(_pickCount <= 1){
                              setState(() {
                                _pickCount = 1;
                              });
                            }else{
                              setState(() {
                                _pickCount -= 1;
                              });
                            }
                          },
                          icon: Icon(Icons.remove),
                        ),
                        Text(_pickCount.toString()),
                        IconButton(
                          onPressed: () {          
                            setState(() {
                              _pickCount += 1;
                            });
                          },
                          icon: Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.casino_outlined),
                  onPressed: () async {
                    int count = _pickCount;
                    for (int i = 0; i < count; i++) {
                      await appState.getNextStudent();
                    }
                  },
                  label: Text('抽选'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.pair,
  }) : super(key: key);

  final String pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSize(
          duration: Duration(milliseconds: 200),
          // Make sure that the compound word wraps correctly when the window
          // is too narrow.
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  pair,
                  style: style.copyWith(fontWeight: FontWeight.w200,fontFamily: "HarmonyOS_Sans_SC"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NameListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();
    return StudentEditorPage();
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();
    return Column(
      spacing: 3,
      children: [
        SizedBox(width: 10,),
        SettingsCard(
          title: Text("主题模式"),
          leading: Icon(Icons.brightness_6_outlined),
          description: "选择亮色、暗色或跟随系统主题",
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: "跟随系统",
                child: Row(
                  children: [
                    Text("跟随系统"),
                    Radio<int>(
                      value: 0,
                      groupValue: appState.themeMode,
                      onChanged: (v) => appState.setThemeMode(v!),
                    ),
                  ]
                ),
              ),
              Tooltip(
                message: "亮色",
                child: Row(
                  children: [
                    Text("亮色"),
                    Radio<int>(
                      value: 1,
                      groupValue: appState.themeMode,
                      onChanged: (v) => appState.setThemeMode(v!),
                    ),
                  ]
                ),
              ),
              Tooltip(
                message: "暗色",
                child: Row(
                  children: [
                    Text("暗色"),
                    Radio<int>(
                      value: 2,
                      groupValue: appState.themeMode,
                      onChanged: (v) => appState.setThemeMode(v!),
                    ),
                  ]
                ),
              ),
            ],
          ),
        ),
        SettingsCard(
          title: Text("允许重复抽取"),
          leading: Icon(Icons.repeat),
          description: "关闭后，所有人都抽过才会重置名单",
          trailing: Switch(
            value: appState.allowRepeat,
            onChanged: (v) => appState.setAllowRepeat(v),
          ),
        ),
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            color: colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/NamePicker.png', width: 120, height: 120),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sprintf("NamePicker %s", [version]),
                        style: TextStyle(fontFamily: "HarmonyOS_Sans_SC", fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Codename $codename',
                    style: TextStyle(fontFamily: "HarmonyOS_Sans_SC", fontSize: 15, color: colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 16),
                  Divider(height: 32, thickness: 1, color: colorScheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "「云间城邦随岁月离析，昏光庭院再度敞开门扉，为永夜捎来微光」",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: "HarmonyOS_Sans_SC", fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.primary),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primaryContainer,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset('assets/avaters/lhgser.jpg', width: 60, height: 60),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "开发者 灵魂歌手er",
                        style: TextStyle(fontFamily: "HarmonyOS_Sans_SC", fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      const url = 'https://github.com/NamePickerOrg/NamePicker';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: Icon(Icons.open_in_new),
                    label: Text("访问GitHub仓库"),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "© 2025-2025 NamePickerOrg",
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({Key? key}) : super(key: key);

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  /// Needed so that [MyAppState] can tell [AnimatedList] below to animate
  /// new items.
  final _key = GlobalKey();

  /// Used to "fade out" the history items at the top, to suggest continuation.
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.transparent, Colors.black],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient)
      // and applies it to the destination (i.e. our animated list).
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: EdgeInsets.only(top: 200),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: HistoryCard(pair: pair),
            ),
          );
        },
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.pair,
  });

  final String pair;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Card(
        child: Text(
          sprintf("  %s  ",[pair]),
          semanticsLabel: pair,
        ),
      ),
    );
  }
}
// 成为英雄吧，救世主。
