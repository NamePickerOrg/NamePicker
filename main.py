import os
import sys
import pandas as pd
import tempfile
import random
import traceback
from loguru import logger
from PyQt5.QtCore import *
from PyQt5.QtWidgets import *
from PyQt5.QtGui import QIcon,QPainter,QPixmap
from qfluentwidgets import *

temp_dir = tempfile.gettempdir()
VERSION = "v2.0.0rel"
CODENAME = "Tribbie"

QApplication.setHighDpiScaleFactorRoundingPolicy(Qt.HighDpiScaleFactorRoundingPolicy.PassThrough)
QApplication.setAttribute(Qt.AA_EnableHighDpiScaling)
QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps)

class Config(QConfig):
    allowRepeat = ConfigItem("General","allowRepeat",False,BoolValidator())
    supportCS = ConfigItem("General", "supportCS", False, BoolValidator())
    eco = ConfigItem("Huanyu", "ecoMode", False, BoolValidator())
    logLevel = OptionsConfigItem("Debug", "logLevel", "INFO", OptionsValidator(["DEBUG", "INFO", "WARNING","ERROR"]), restart=True)

cfg = Config()
qconfig.load('config.json', cfg)

if os.path.exists("out.log"):
    os.remove("out.log")
logger.remove(0)
logger.add("out.log")
logger.add(sys.stderr, level=cfg.get(cfg.logLevel))

logger.info("⌈缇宝，明天见⌋")

def hookExceptions(exc_type, exc_value, exc_tb):
    error_details = ''.join(traceback.format_exception(exc_type, exc_value, exc_tb))
    logger.error(error_details)
sys.excepthook = hookExceptions

class Choose(QFrame):

    def __init__(self, text: str, parent=None):
        super().__init__(parent=parent)
        self.names = []
        self.sexlen = [0,0,0]
        self.sexl = [[],[],[]]
        self.numlen = [0,0,0]
        self.numl = [[],[],[]]
        self.chosen = []
        self.loadname()

        self.hBoxLayout = QHBoxLayout(self)
        self.options = QVBoxLayout(self)

        self.pickbn = PrimaryPushButton("点击抽选")
        self.pickbn.clicked.connect(self.pickcb)
        self.pickbn.adjustSize()
        self.options.addWidget(self.pickbn,5)

        self.table = TableWidget(self)
        self.table.setBorderVisible(True)
        self.table.setBorderRadius(8)
        self.table.setWordWrap(False)
        self.table.setRowCount(10)
        self.table.setColumnCount(2)
        self.table.setHorizontalHeaderLabels(["姓名","学号"])

        self.pn = QWidget()
        self.pnl = QHBoxLayout(self)
        self.pnLabel = SubtitleLabel("抽选数量", self)
        self.pickNum = SpinBox()
        self.pickNum.setRange(1, len(self.names[0]))
        self.pnl.addWidget(self.pnLabel, 10)
        self.pnl.addWidget(self.pickNum, 5)
        self.pn.setLayout(self.pnl)
        self.options.addWidget(self.pn,5)

        self.sep = QWidget()
        self.sepl = QHBoxLayout(self)
        self.seLabel = SubtitleLabel("性别偏好", self)
        self.sexCombo = ComboBox()
        self.sexCombo.addItems(["都抽","只抽男","只抽女","只抽特殊性别"])
        self.sepl.addWidget(self.seLabel, 10)
        self.sepl.addWidget(self.sexCombo, 5)
        self.sep.setLayout(self.sepl)
        self.options.addWidget(self.sep, 5)

        self.nup = QWidget()
        self.nul = QHBoxLayout(self)
        self.nuLabel = SubtitleLabel("学号偏好", self)
        self.numCombo = ComboBox()
        self.numCombo.addItems(["都抽", "只抽单数", "只抽双数"])
        self.nul.addWidget(self.nuLabel, 10)
        self.nul.addWidget(self.numCombo, 5)
        self.nup.setLayout(self.nul)
        self.options.addWidget(self.nup, 5)

        self.opt = QWidget()
        self.opt.setLayout(self.options)

        self.hBoxLayout.addWidget(self.table,2)
        self.hBoxLayout.addWidget(self.opt,3,Qt.AlignCenter)
        self.setObjectName(text.replace(' ', 'Choose'))
        logger.info("主界面初始化完成")

        if cfg.get(cfg.eco):
            InfoBar.success(
                title='环保模式已启用',
                content="NamePicker低碳模式将大幅降低碳排放，同时大幅增加设备寿命",
                orient=Qt.Horizontal,
                isClosable=True,
                position=InfoBarPosition.TOP,
                duration=3000,
                parent=self
            )
            logger.info("NamePicker低碳模式将大幅降低碳排放，同时大幅增加设备寿命")

    def pick(self):
        global cfg
        if self.sexCombo.currentText() != "都抽":
            if self.sexCombo.currentText() == "只抽男":
                le = self.sexlen[0]
                tar = self.sexl[0]
            elif self.sexCombo.currentText() == "只抽女":
                le = self.sexlen[1]
                tar = self.sexl[1]
            else:
                le = self.sexlen[2]
                tar = self.sexl[2]
        else:
            le = self.length
            tar = self.names[0]

        if self.numCombo.currentText() != "都抽":
            if self.numCombo.currentText() == "只抽双数":
                tar = list(set(tar) & set(self.numl[0]))
                le = len(tar)
            else:
                tar = list(set(tar) & set(self.numl[1]))
                le = len(tar)
        if le != 0:
            chs = random.randint(0, le - 1)
            if not cfg.get(cfg.allowRepeat):
                if len(self.chosen) >= le:
                    self.chosen = []
                    chs = random.randint(0, le - 1)
                else:
                    while chs in self.chosen:
                        chs = random.randint(0, le - 1)
                self.chosen.append(chs)
                logger.debug(self.chosen)
            return [tar[chs], self.names[2][self.names[0].index(tar[chs])]]
        else:
            return ["尚未抽选", "尚未抽选"]

    def pickcb(self):
        logger.debug("pickcb被调用")
        self.table.setRowCount(self.pickNum.value())
        namet = []
        namel = []
        for i in range(self.pickNum.value()):
            namet.append(self.pick())
        if cfg.get(cfg.supportCS):
            with open("%s\\unread" % temp_dir, "w", encoding="utf-8") as f:
                f.write("111")
            with open("%s\\res.txt" % temp_dir, "w", encoding="utf-8") as f:
                for i in namet:
                    namel.append("%s（%s）" % (i[0], i[1]))
                f.writelines(namel)
            logger.info("文件存储完成")
        else:
            for i, t in enumerate(namet):
                for j in range(2):
                    self.table.setItem(i, j, QTableWidgetItem(t[j]))
            logger.debug("表格设置完成")


    def loadname(self):
        try:
            name = pd.read_csv("names.csv",sep=",",header=0,dtype={'name': str, 'sex': int, "no":int})
            name = name.to_dict()
            self.names.append(list(name["name"].values()))
            self.names.append(list(name["sex"].values()))
            self.names.append(list(name["no"].values()))
            self.length =len(name["name"])
            self.sexlen[0] = self.names[1].count(0)
            self.sexlen[1] = self.names[1].count(1)
            self.sexlen[2] = self.names[1].count(2)
            for i in self.names[0]:
                if self.names[1][self.names[0].index(i)] == 0:
                    self.sexl[0].append(i)
                elif self.names[1][self.names[0].index(i)] == 1:
                    self.sexl[1].append(i)
                else:
                    self.sexl[2].append(i)

            for i in self.names[0]:
                if self.names[2][self.names[0].index(i)]%2==0:
                    self.numl[0].append(i)
                else:
                    self.numl[1].append(i)
            self.numlen[0] = len(self.numl[0])
            self.numlen[1] = len(self.numl[1])
            logger.info("名单加载完成")
        except FileNotFoundError:
            logger.warning("没有找到名单文件")
            with open("names.csv","w",encoding="utf-8") as f:
                st  = ["name,sex,no\n","example,0,1"]
                f.writelines(st)
            sys.exit(114514)

class Settings(QFrame):
    def __init__(self, text: str, parent=None):
        global cfg
        super().__init__(parent=parent)
        self.setObjectName(text.replace(' ', 'Settings'))
        self.df = QVBoxLayout(self)
        self.scrollArea = ScrollArea()
        self.scrollArea.setWidgetResizable(True)
        self.scrollArea.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.optv =QWidget()
        self.opts = QVBoxLayout(self.optv)
        self.sets = [SubtitleLabel("常规"),
        SwitchSettingCard(
            configItem=cfg.allowRepeat,
            icon=FluentIcon.LIBRARY,
            title="允许重复点名",
            content="允许点到重复名字"
        ),
        SwitchSettingCard(
            configItem=cfg.supportCS,
            icon=FluentIcon.LINK,
            title="课表软件联动",
            content="启用后将在ClassIsland/Class Widgets上（而非主界面）显示抽选结果，需要安装对应插件"
        ),SubtitleLabel("调试"),
        ComboBoxSettingCard(
            configItem=cfg.logLevel,
            icon=FluentIcon.DEVELOPER_TOOLS,
            title="日志记录级别",
            content="日志的详细程度",
            texts=["DEBUG", "INFO", "WARNING","ERROR"]
        ),PushButton(FluentIcon.DOCUMENT,"测试日志输出"),
        PushButton(FluentIcon.CLOSE,"测试引发崩溃"),
        SubtitleLabel("欢愉（太有乐子了）"),
        SwitchSettingCard(
            configItem=cfg.eco,
            icon=FluentIcon.LEAF,
            title="环保模式",
            content="NamePicker致力于减少碳排放"
        )]
        for i in self.sets:
            self.opts.addWidget(i)
        self.sets[5].clicked.connect(self.testLog)
        self.sets[6].clicked.connect(self.testCrash)
        self.scrollArea.setStyleSheet("QScrollArea{background: transparent; border: none}")
        self.scrollArea.setWidget(self.optv)
        self.optv.setStyleSheet("QWidget{background: transparent}")
        self.df.addWidget(TitleLabel("设置"))
        self.df.addWidget(self.scrollArea)

        logger.info("设置界面初始化完成")

    def testLog(self):
        logger.debug("这是Debug日志")
        logger.info("这是Info日志")
        logger.warning("这是Warning日志")
        logger.error("这是Error日志")

    def testCrash(self):
        raise Exception("NamePicker实际上没有任何问题，是你自己手贱引发的崩溃")

class About(QFrame):
    def __init__(self, text: str, parent=None):
        global cfg
        super().__init__(parent=parent)
        self.setObjectName(text.replace(' ', 'About'))
        self.df = QVBoxLayout(self)
        self.about = TitleLabel("关于")
        self.image = ImageLabel("assets/NamePicker.png")
        self.ver = SubtitleLabel("NamePicker %s - Codename %s"%(VERSION,CODENAME))
        self.author = BodyLabel("By 灵魂歌手er（Github @LHGS-github）")
        self.cpleft = BodyLabel("本软件基于GNU GPLv3获得授权")
        self.ghrepo = HyperlinkButton(FluentIcon.GITHUB, "https://github.com/NamePickerOrg/NamePicker", 'GitHub Repo')

        self.df.addWidget(self.about)
        self.df.addWidget(self.image)
        self.df.addWidget(self.ver)
        self.df.addWidget(self.author)
        self.df.addWidget(self.cpleft)
        self.df.addWidget(self.ghrepo)
        logger.info("关于界面初始化")

class App(FluentWindow):
    def __init__(self):
        super().__init__()
        qconfig.theme = Theme.AUTO
        setTheme(Theme.AUTO)
        self.Choose = Choose("随机抽选",self)
        self.Settings = Settings("设置",self)
        self.About = About("关于", self)
        self.initNavigation()
        self.initWindow()
        logger.info("主界面初始化")

    def initNavigation(self):
        self.addSubInterface(self.Choose, FluentIcon.HOME, "随机抽选")
        self.addSubInterface(self.Settings, FluentIcon.SETTING, '设置', NavigationItemPosition.BOTTOM)
        self.addSubInterface(self.About, FluentIcon.INFO, '关于', NavigationItemPosition.BOTTOM)

    def initWindow(self):
        self.resize(700, 500)
        self.setWindowIcon(QIcon('assets/NamePicker.png'))
        self.setWindowTitle('NamePicker')

    def closeEvent(self, event):
        self.hide()
        event.ignore()

class SystemTrayIcon(QSystemTrayIcon):
    def __init__(self, parent):
        super().__init__(parent=parent)
        self.setIcon(parent.windowIcon())

        self.menu = SystemTrayMenu(parent=parent)
        self.menu.addActions([
            Action('退出', triggered=self.esc)
        ])
        self.setContextMenu(self.menu)

    def esc(self):
        sys.exit(0)

class TrayWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setFixedSize(100, 100)
        self.setWindowIcon(QIcon('assets/NamePickerCircle.png'))
        screen = QDesktopWidget().screenGeometry()
        self.move(int(screen.width()*0.7), int(screen.height()*0.7))
        self.systemTrayIcon = SystemTrayIcon(self)
        self.systemTrayIcon.show()

        self.drag_start_pos = None
        self.main_window = None
        self.drag = False

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            self.drag_start_pos = event.globalPos()
            event.accept()

    def mouseMoveEvent(self, event):
        if self.drag_start_pos is not None and event.buttons() == Qt.LeftButton:
            self.drag = True
            delta = event.globalPos() - self.drag_start_pos
            self.move(self.x() + delta.x(), self.y() + delta.y())
            self.drag_start_pos = event.globalPos()
            event.accept()

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.LeftButton and self.drag_start_pos:
            if not self.drag:
                self.show_main_window()
            else:
                self.drag = False
            self.drag_start_pos = None
            event.accept()

    def show_main_window(self):
        if not self.main_window:
            self.main_window = App()
            self.main_window.show()
        else:
            self.main_window.show()
            self.main_window.activateWindow()

    def paintEvent(self, event):
        painter = QPainter(self)
        pixmap = QPixmap('assets/NamePickerCircle.png')
        painter.drawPixmap(self.rect(), pixmap)
        painter.setCompositionMode(QPainter.CompositionMode_SourceIn)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    tray = TrayWindow()
    tray.show()
    sys.exit(app.exec_())