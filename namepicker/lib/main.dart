// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sprintf/sprintf.dart';
import 'settings_card.dart';

// BIN 1 1111 1111 1111 0000 0000 0000 = DEC 33550336
// 众人将与一人离别，惟其人将觐见奇迹

// 「在彩虹桥的尽头，天空之子将缝补晨昏」
final version = "v3.0.0ea1";
final codename = "Hyacine";
void main() {
  runApp(MyApp());
}

randomGen(min, max) {
  var x = Random().nextInt(max) + min;
  return x.floor();
}

pass(){
  return Void;
}

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
  var current = "0";
  var history = <String>[];

  GlobalKey? historyListKey;

  // 0: 跟随系统 1: 亮色 2: 暗色
  int themeMode = 0;
  int minValue = 0;
  int maxValue = 20;

  void setThemeMode(int mode) {
    themeMode = mode;
    notifyListeners();
  }

  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    // var names = ["sunxiaochuan","fxpick","abcdccb"];
    animatedList?.insertItem(0);
    current = sprintf("%s",[randomGen(minValue, maxValue)]);
    notifyListeners();
  }

  void setRange(int min, int max) {
    if (min > max) {
      final tmp = min;
      min = max;
      max = tmp;
    }
    minValue = min;
    maxValue = max;
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
      appBar: AppBar(
        title: Text("NamePicker"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            // Use a more mobile-friendly layout with BottomNavigationBar
            // on narrow screens.
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
    );
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  late TextEditingController minController;
  late TextEditingController maxController;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<MyAppState>(context, listen: false);
    minController = TextEditingController(text: appState.minValue.toString());
    maxController = TextEditingController(text: appState.maxValue.toString());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<MyAppState>(context, listen: false);
    minController.text = appState.minValue.toString();
    maxController.text = appState.maxValue.toString();
  }

  @override
  void dispose() {
    minController.dispose();
    maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(),
          ),
          SizedBox(height: 10),
          BigCard(pair: pair),
          SizedBox(height: 10),
          // 数字范围选择
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('范围：'),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '最小',
                  ),
                  onSubmitted: (v) {
                    final min = int.tryParse(v) ?? appState.minValue;
                    appState.setRange(min, appState.maxValue);
                  },
                ),
              ),
              Text(' ~ '),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '最大',
                  ),
                  onSubmitted: (v) {
                    final max = int.tryParse(v) ?? appState.maxValue;
                    appState.setRange(appState.minValue, max);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  // 先同步输入框内容到状态
                  final min = int.tryParse(minController.text) ?? appState.minValue;
                  final max = int.tryParse(maxController.text) ?? appState.maxValue;
                  appState.setRange(min, max);
                  appState.getNext();
                  // 保证输入框内容和状态同步
                  minController.text = appState.minValue.toString();
                  maxController.text = appState.maxValue.toString();
                },
                child: Text('点击抽选'),
              ),
            ],
          ),
          Spacer(flex: 2),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Placeholder()
      ]
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();
    return Column(
      spacing: 20,
      children: [
        SizedBox(width: 10,),
        Text("外观", style: TextStyle(fontSize: 20)),
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
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        SafeArea(child: Image(image: AssetImage('assets/NamePicker.png',),width: 200,height: 200,)),
        Center(
          child: Text(
            sprintf("NamePicker %s - Codename %s",[version,codename]),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: "HarmonyOS_Sans_SC",fontSize: 20,fontWeight: FontWeight.w600),
          )
        ),
        Text(
            "「云间城邦随岁月离析，昏光庭院再度敞开门扉，为永夜捎来微光」",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: "HarmonyOS_Sans_SC",fontSize: 15,fontWeight: FontWeight.w400),
        ),
        Text(
            "开发者 灵魂歌手er",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: "HarmonyOS_Sans_SC",fontSize: 15,fontWeight: FontWeight.w400),
        ),
        Text(
            "当前版本为Early Access早期体验版本，仅供体验，并非最终品质",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: "HarmonyOS_Sans_SC",fontSize: 15,fontWeight: FontWeight.w400),
        ),
      ]
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
