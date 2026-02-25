import json
import importlib
import os
import sys
import time
import hashlib
import pandas as pd
import tempfile
import random
import traceback
from loguru import logger
from PyQt5.QtCore import *
from PyQt5.QtWidgets import *
from PyQt5.QtGui import QIcon,QPainter,QPixmap,QDesktopServices
from qfluentwidgets import *
if os.name == 'nt':
    from win32com.client import Dispatch

temp_dir = tempfile.gettempdir()
VERSION = "v2.2.0Remake"
CODENAME = "ChrysosHeirs"
APIVER = 1
error_dialog = None
tray = None
unlocked = [False,False]
plugin = {}
plugin_info = {}
plugin_settings = {}
plugin_customkey = []
plugin_customkey_title = []
plugin_filters = []
plugin_filters_name = []
plugin_icon = {}
plugin_path = {}
current_name_path = ""

def load_plugins():
    for i in os.listdir("plugins"):
        if not (os.path.exists("plugins/%s/info.json"%i) and os.path.exists("plugins/%s/icon.png"%i) and os.path.exists("plugins/%s/main.py"%i)):
            logger.warning("目录%s没有有效插件"%i)
            continue
        elif os.path.exists("plugins/%s/DEL"%i):
            os.remove("plugins/%s"%i)
            logger.success(f"插件{i}被成功移除")
            continue
        else:
            with open("plugins/%s/info.json"%i,"r",encoding="utf-8") as f:
                ct = f.read()
                js = json.loads(ct)
                if js["api"] > cfg.get(cfg.apiver):
                    logger.warning("当前插件API版本过高，拒绝加载")
                    continue
                plugin_info[js["id"]] = js
            pgin = importlib.import_module("plugins.%s.main"%i)
            plugin_icon[js["id"]] = "plugins/%s/icon.png"%i
            plugin_path[js["id"]] = "plugins/%s" % i
            if hasattr(pgin,"Settings") and not os.path.exists("plugins/%s/DISABLED"%i):
                plugin_settings[js["id"]] = pgin.Settings()
            if hasattr(pgin,"Plugin"):
                if not os.path.exists("plugins/%s/DISABLED"%i):
                    plugin[js["id"]] = pgin.Plugin()
                    for i in plugin[js["id"]].customKey:
                        plugin_customkey.append(i)
                    for i in plugin[js["id"]].customKeyTitle:
                        plugin_customkey_title.append(i)
                    for i in plugin[js["id"]].filters:
                        plugin_filters.append(i)
                    for i in plugin[js["id"]].filtersName:
                        plugin_filters_name.append(i)
                else:
                    logger.warning("插件%s已被禁用" % js["id"])
                    continue
            logger.success("加载插件：%s成功"%js["id"])

def apply_customkey():
    global current_name_path
    with open(current_name_path, "r", encoding="utf-8") as f:
        namesread = f.readlines()
        for i in range(len(namesread)):
            namesread[i] = namesread[i].strip("\n")
        for i in range(len(plugin_customkey)):
            if plugin_customkey[i] not in namesread[0]:
                namesread[0] += ",%s"%plugin_customkey[i]
                for j in range(len(namesread)):
                    if j == 0:
                        continue
                    namesread[j] += ",Nope"

    with open(current_name_path,"w",encoding="utf-8") as f:
        namewrite = []
        for i in range(len(namesread)):
            namewrite.append(namesread[i]+"\n")
        f.writelines(namewrite)

QApplication.setHighDpiScaleFactorRoundingPolicy(Qt.HighDpiScaleFactorRoundingPolicy.PassThrough)
QApplication.setAttribute(Qt.AA_EnableHighDpiScaling)
QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps)

class Config(QConfig):
    allowRepeat = ConfigItem("General","allowRepeat",False,BoolValidator())
    supportCS = ConfigItem("General", "supportCS", False, BoolValidator())
    chooseKey = ConfigItem("General","chooseKey","ctrl+w")
    autoStartup = ConfigItem("General","autoStartup",False,BoolValidator())
    lockNameEdit = ConfigItem("Secure","lockNameEdit",False,BoolValidator())
    lockConfigEdit = ConfigItem("Secure","lockConfigItem",False,BoolValidator())
    keyChecksum = ConfigItem("Secure","keyChecksum","0")
    eco = ConfigItem("Huanyu", "ecoMode", False, BoolValidator())
    justice = ConfigItem("Huanyu", "justice", False, BoolValidator())
    logLevel = OptionsConfigItem("Debug", "logLevel", "INFO", OptionsValidator(["DEBUG", "INFO", "WARNING","ERROR"]), restart=True)
    apiver = ConfigItem("Version", "apiver", 1)

cfg = Config()
qconfig.load('config.json', cfg)
cfg.set(cfg.apiver,APIVER)

# 日志
if os.path.exists("out.log"):
    os.remove("out.log")
logger.remove(0)
logger.add("out.log")
logger.add(sys.stderr, level=cfg.get(cfg.logLevel))
logger.info(f"NamePicker Ver {VERSION} Codename {CODENAME} Plugin API Version {APIVER}")
logger.info("「当前演算进程：___ _ _ -_-- --- __- - --- -- --- _-_ _-_ --- _--⌋")

def hookExceptions(exc_type, exc_value, exc_tb):
    error_details = ''.join(traceback.format_exception(exc_type, exc_value, exc_tb))
    if "TypeError: disconnect() of all signals failed" in error_details:
        return
    logger.error(error_details)
    if not error_dialog:
        w = ErrorDialog(error_details)
        w.exec()
sys.excepthook = hookExceptions

class ErrorDialog(Dialog):  # 重大错误提示框
    def __init__(self, error_details='Traceback (most recent call last):', parent=None):
        # KeyboardInterrupt 直接 exit
        if error_details.endswith('KeyboardInterrupt') or error_details.endswith('KeyboardInterrupt\n'):
            sys.exit()

        super().__init__(
            'NamePicker 崩溃报告',
            '抱歉！NamePicker 发生了严重的错误从而无法正常运行。您可以保存下方的错误信息并向他人求助。'
            '若您认为这是程序的Bug，请点击“报告此问题”或联系开发者。',
            parent
        )
        global error_dialog
        error_dialog = True

        self.is_dragging = False
        self.drag_position = QPoint()
        self.title_bar_height = 30
        self.title_layout = QHBoxLayout()

        self.error_log = PlainTextEdit()
        self.ignore_error_btn = PushButton(FluentIcon.INFO, '忽略错误')
        self.report_problem = PushButton(FluentIcon.FEEDBACK, '报告此问题')
        self.copy_log_btn = PushButton(FluentIcon.COPY, '复制日志')
        self.restart_btn = PrimaryPushButton(FluentIcon.SYNC, '重新启动')

        self.titleLabel.setText('出错了（；´д｀）ゞ')
        self.titleLabel.setStyleSheet("font-family: Microsoft YaHei UI; font-size: 25px; font-weight: 500;")
        self.error_log.setReadOnly(True)
        self.error_log.setPlainText(error_details)
        self.error_log.setFixedHeight(200)
        self.restart_btn.setFixedWidth(150)
        self.yesButton.hide()
        self.cancelButton.hide()  # 隐藏取消按钮
        self.title_layout.setSpacing(12)

        # 按钮事件
        self.report_problem.clicked.connect(
            lambda: QDesktopServices.openUrl(QUrl(
                'https://github.com/NamePickerOrg/NamePicker/issues/'))
        )
        self.copy_log_btn.clicked.connect(self.copy_log)
        self.restart_btn.clicked.connect(self.restart)
        self.ignore_error_btn.clicked.connect(lambda:self.close())

        self.title_layout.addWidget(self.titleLabel)
        self.textLayout.insertLayout(0, self.title_layout)  # 页面
        self.textLayout.addWidget(self.error_log)
        self.buttonLayout.insertStretch(0, 1)  # 按钮布局
        self.buttonLayout.insertWidget(0, self.copy_log_btn)
        self.buttonLayout.insertWidget(1, self.report_problem)
        self.buttonLayout.insertWidget(2, self.ignore_error_btn)
        self.buttonLayout.insertStretch(1)
        self.buttonLayout.insertWidget(5, self.restart_btn)

    def restart(self):
        if tray:
            tray.systemTrayIcon.hide()
        os.execl(sys.executable, sys.executable, *sys.argv)

    def copy_log(self):  # 复制日志
        QApplication.clipboard().setText(self.error_log.toPlainText())
        Flyout.create(
            icon=InfoBarIcon.SUCCESS,
            title='复制成功！ヾ(^▽^*)))',
            content="日志已成功复制到剪贴板。",
            target=self.copy_log_btn,
            parent=self,
            isClosable=True,
            aniType=FlyoutAnimationType.PULL_UP
        )

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton and event.y() <= self.title_bar_height:
            self.is_dragging = True
            self.drag_position = event.globalPos() - self.frameGeometry().topLeft()

    def mouseMoveEvent(self, event):
        if self.is_dragging:
            self.move(event.globalPos() - self.drag_position)

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.LeftButton:
            self.is_dragging = False

    def closeEvent(self, event):
        global error_dialog
        error_dialog = False
        event.ignore()
        self.hide()
        self.deleteLater()

class PluginCard(CardWidget):
    def __init__(self, icon, title, content, path, parent=None):
        super().__init__(parent)
        self.path = path
        self.iconWidget = IconWidget(icon)
        self.titleLabel = BodyLabel(title, self)
        self.contentLabel = CaptionLabel(content, self)
        self.openSwitch = SwitchButton(self)
        self.deleteButton = TransparentToolButton(FluentIcon.DELETE, self)

        if not os.path.exists("%s/DISABLED"%self.path):
            self.openSwitch.setChecked(True)
        self.openSwitch.checkedChanged.connect(self.disable)
        self.deleteButton.clicked.connect(self.delete)

        self.hBoxLayout = QHBoxLayout(self)
        self.vBoxLayout = QVBoxLayout()

        self.setFixedHeight(73)
        self.iconWidget.setFixedSize(48, 48)
        self.contentLabel.setTextColor("#606060", "#d2d2d2")

        self.hBoxLayout.setContentsMargins(20, 11, 11, 11)
        self.hBoxLayout.setSpacing(15)
        self.hBoxLayout.addWidget(self.iconWidget)

        self.vBoxLayout.setContentsMargins(0, 0, 0, 0)
        self.vBoxLayout.setSpacing(0)
        self.vBoxLayout.addWidget(self.titleLabel, 0, Qt.AlignVCenter)
        self.vBoxLayout.addWidget(self.contentLabel, 0, Qt.AlignVCenter)
        self.vBoxLayout.setAlignment(Qt.AlignVCenter)
        self.hBoxLayout.addLayout(self.vBoxLayout)

        self.hBoxLayout.addStretch(1)
        self.hBoxLayout.addWidget(self.openSwitch, 0, Qt.AlignRight)
        self.hBoxLayout.addWidget(self.deleteButton, 0, Qt.AlignRight)

    def disable(self):
        if not self.openSwitch.isChecked():
            with open("%s/DISABLED"%self.path,"w",encoding="utf-8") as f:
                f.write("disabled")
            InfoBar.success(
                title='禁用成功',
                content="被禁用的插件在下次启动时不会被加载",
                orient=Qt.Horizontal,
                isClosable=True,
                position=InfoBarPosition.TOP,
                duration=3000,
                parent=self
            )
        else:
            if os.path.exists("%s/DISABLED"%self.path):
                os.remove("%s/DISABLED"%self.path)
                InfoBar.success(
                    title='启用成功',
                    content="该插件在下次启动时会被加载",
                    orient=Qt.Horizontal,
                    isClosable=True,
                    position=InfoBarPosition.TOP,
                    duration=3000,
                    parent=self
                )

    def delete(self):
        with open("%s/DEL", "w", encoding="utf-8") as f:
            f.write("delete later")
        InfoBar.success(
            title='设置成功',
            content="该插件在下次启动时会被删除",
            orient=Qt.Horizontal,
            isClosable=True,
            position=InfoBarPosition.TOP,
            duration=3000,
            parent=self
        )

class PluginSettings(QFrame):
    def __init__(self, text: str, parent=None):
        global cfg
        super().__init__(parent=parent)
        self.setObjectName(text.replace(' ', 'PluginSettings'))
        self.df = QVBoxLayout(self)
        self.scrollArea = ScrollArea()
        self.scrollArea.setWidgetResizable(True)
        self.scrollArea.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.optv =QWidget()
        self.opts = QVBoxLayout(self.optv)
        self.sets = []
        if plugin:
            for i in plugin_info.keys():
                des = "%s - By %s - Version %s"%(plugin_info[i]["description"],plugin_info[i]["author"],plugin_info[i]["version"])
                self.sets.append(PluginCard(plugin_icon[i],plugin_info[i]["name"],des,plugin_path[i]))
            for i in self.sets:
                self.opts.addWidget(i)
        else:
            self.opts.addWidget(SubtitleLabel("没有安装插件"))
        self.scrollArea.setStyleSheet("QScrollArea{background: transparent; border: none}")
        self.scrollArea.setWidget(self.optv)
        self.optv.setStyleSheet("QWidget{background: transparent}")
        self.df.addWidget(TitleLabel("插件管理"))
        QScroller.grabGesture(self.scrollArea.viewport(), QScroller.LeftMouseButtonGesture)
        self.df.addWidget(self.optv)
        logger.info("插件设置界面初始化完成")

class Choose(QFrame):

    def __init__(self, text: str, parent=None):
        global current_name_path
        super().__init__(parent=parent)
        self.names = {}
        self.namelist = []
        self.sexlen = [0,0,0]
        self.sexl = [[],[],[]]
        self.numlen = [0,0,0]
        self.numl = [[],[],[]]
        self.chosen = []
        current_name_path = f"names/{os.listdir("names")[0]}"
        self.loadname()

        self.hBoxLayout = QHBoxLayout(self)
        self.options = QVBoxLayout(self)

        for i in os.listdir("names"):
                if os.path.isfile(f"names/{i}"):
                    self.namelist.append(f"names/{i}")

        if cfg.get(cfg.justice):
            self.just = StrongBodyLabel("NamePicker绝对没有暗改概率功能")
            self.options.addWidget(self.just)

        self.pickbn = PrimaryPushButton("点击抽选")
        self.pickbn.clicked.connect(self.pickcb)
        self.pickbn.setShortcut(cfg.get(cfg.chooseKey))
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
        self.pickNum.setRange(1, len(self.names["name"]))
        self.pnl.addWidget(self.pnLabel, 10)
        self.pnl.addWidget(self.pickNum, 5)
        self.pn.setLayout(self.pnl)
        self.options.addWidget(self.pn,5)

        # self.sep = QWidget()
        # self.sepl = QHBoxLayout(self)
        # self.seLabel = SubtitleLabel("性别偏好", self)
        # self.sexCombo = ComboBox()
        # self.sexCombo.addItems(os.listdir("names"))
        # self.sepl.addWidget(self.seLabel, 10)
        # self.sepl.addWidget(self.sexCombo, 5)
        # self.sep.setLayout(self.sepl)
        # self.options.addWidget(self.sep, 5)

        self.nmp = QWidget()
        self.nmpl = QHBoxLayout(self)
        self.nmLabel = SubtitleLabel("选择名单", self)
        self.nameCombo = ComboBox()
        self.nameCombo.addItems(os.listdir("names"))
        self.nameCombo.currentIndexChanged.connect(lambda index: self.relaod(index))
        self.nmpl.addWidget(self.nmLabel, 10)
        self.nmpl.addWidget(self.nameCombo, 5)
        self.nmp.setLayout(self.nmpl)
        self.options.addWidget(self.nmp, 5)

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

        self.scrollArea = ScrollArea()
        self.scrollArea.setWidgetResizable(True)
        self.scrollArea.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)

        if plugin_filters:
            self.fil = QWidget()
            self.fill = QVBoxLayout(self)
            self.fillist = []
            self.fillwidgets = []
            self.filswitch = []
            for i in range(len(plugin_filters_name)):
                self.fillist.append(QHBoxLayout())
                self.fillist[i].addWidget(BodyLabel(plugin_filters_name[i]))
                self.filswitch.append(SwitchButton())
                self.fillist[i].addWidget(self.filswitch[i])
                self.fillwidgets.append(QWidget())
                self.fillwidgets[i].setLayout(self.fillist[i])
            for i in self.fillwidgets:
                self.fill.addWidget(i)
            self.fil.setLayout(self.fill)
            self.scrollArea.setStyleSheet("QScrollArea{background: transparent; border: none}")
            self.scrollArea.setWidget(self.fil)
            self.fil.setStyleSheet("QWidget{background: transparent}")
            self.options.addWidget(self.scrollArea)
            QScroller.grabGesture(self.scrollArea.viewport(), QScroller.LeftMouseButtonGesture)

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
            tar = self.names["name"]

        if self.numCombo.currentText() != "都抽":
            if self.numCombo.currentText() == "只抽双数":
                tar = list(set(tar) & set(self.numl[0]))
                le = len(tar)
            else:
                tar = list(set(tar) & set(self.numl[1]))
                le = len(tar)
        if plugin_filters:
            for i in range(len(tar)):
                for j in range(len(plugin_filters)):
                    if not plugin_filters[j](tar[i]):
                        tar.remove(tar[i])
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
            tmp = {"name":tar[chs],"no":str(self.names["no"][self.names["name"].index(tar[chs])])}
            for i in self.names.keys():
                if i == "name" or i == "no":
                    continue
                tmp[i] = str(self.names[i][self.names["name"].index(tar[chs])])
            return tmp
        else:
            return "尚未抽选"

    def pickcb(self):
        logger.debug("pickcb被调用")
        for i in plugin.keys():
            plugin[i].beforePick()
        self.table.setRowCount(self.pickNum.value())
        namet = []
        namel = []
        for i in range(self.pickNum.value()):
            n = self.pick()
            if n != "尚未抽选":
                namet.append(n)
            else:
                self.nost()

        if cfg.get(cfg.supportCS):
            with open("%s\\unread" % temp_dir, "w", encoding="utf-8") as f:
                f.write("111")
            with open("%s\\res.txt" % temp_dir, "w", encoding="utf-8") as f:
                for i in namet:
                    namel.append("%s（%s）" % (i[0], i[1]))
                f.writelines(namel)
            logger.info("文件存储完成")
        else:
            for i in range(len(namet)):
                self.table.setItem(i, 0, QTableWidgetItem(namet[i]["name"]))
                self.table.setItem(i, 1, QTableWidgetItem(namet[i]["no"]))
            logger.debug("表格设置完成")
        for i in plugin.keys():
            plugin[i].afterPick(namet)

    def nost(self):
        InfoBar.error(
            title='错误',
            content="没有符合筛选条件的学生",
            orient=Qt.Horizontal,
            isClosable=True,
            position=InfoBarPosition.BOTTOM,
            duration=3000,
            parent=self
        )

    def loadname(self):
        global current_name_path
        if os.path.exists("names"):
            try:
                name = pd.read_csv(current_name_path, sep=",", header=0)
                name = name.to_dict()
                self.names["name"] = list(name["name"].values())
                self.names["sex"] = list(name["sex"].values())
                self.names["no"] = list(name["no"].values())
                for i in plugin_customkey:
                    self.names[i] = list(name[i].values())
                for k in self.names.keys():
                    for i in range(len(self.names[k])):
                        self.names[k][i] = str(self.names[k][i])
                self.length =len(name["name"])
                self.sexlen[0] = self.names["sex"].count("0")
                self.sexlen[1] = self.names["sex"].count("1")
                self.sexlen[2] = self.names["sex"].count("2")
                for i in self.names["name"]:
                    if int(self.names["sex"][self.names["name"].index(i)]) == 0:
                        self.sexl[0].append(i)
                    elif int(self.names["sex"][self.names["name"].index(i)]) == 1:
                        self.sexl[1].append(i)
                    else:
                        self.sexl[2].append(i)

                for i in self.names["name"]:
                    if int(self.names["no"][self.names["name"].index(i)])%2==0:
                        self.numl[0].append(i)
                    else:
                        self.numl[1].append(i)
                self.numlen[0] = len(self.numl[0])
                self.numlen[1] = len(self.numl[1])
                logger.info("名单加载完成")
            except FileNotFoundError:
                logger.warning("没有找到名单文件")
                with open("names/names.csv","w",encoding="utf-8") as f:
                    st  = ["name,sex,no\n","example,0,1"]
                    f.writelines(st)
                current_name_path = "names/names.csv"
                w = Dialog("没有找到名单文件", "没有找到名单文件，已为您创建默认名单，请自行编辑", self)
                w.exec()
                self.loadname()
        else:
            os.mkdir("names")
            logger.warning("没有找到名单文件")
            with open("names/names.csv","w",encoding="utf-8") as f:
                st  = ["name,sex,no\n","example,0,1"]
                f.writelines(st)
            current_name_path = "names/names.csv"
            w = Dialog("没有找到名单文件", "没有找到名单文件，已为您创建默认名单，请自行编辑", self)
            w.exec()
            self.loadname()

    def relaod(self,index):
        global current_name_path
        current_name_path = f"names/{os.listdir("names")[index]}"
        self.loadname()

class NameEdit(QFrame):
    def __init__(self, text: str, parent=None):
        super().__init__(parent=parent)
        self.names = {}
        self.nametable = []
        self.loadname()
        self.editing = 0

        self.vbox = QVBoxLayout(self)
        self.title = TitleLabel("名单编辑")
        self.vbox.addWidget(self.title)

        self.expl = BodyLabel("所有更改都将自动保存至文件，可以直接编辑表格内容")
        self.vbox.addWidget(self.expl)

        self.table = TableWidget(self)
        self.table.setBorderVisible(True)
        self.table.setBorderRadius(8)
        self.table.setWordWrap(False)
        self.table.setRowCount(len(self.nametable))
        self.table.setColumnCount(3+len(plugin_customkey_title))
        self.table.adjustSize()
        htmp = ["姓名", "性别", "学号"]
        for i in plugin_customkey_title:
            htmp.append(i)
        self.table.setHorizontalHeaderLabels(htmp)
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)

        self.opv = QWidget()
        self.option = QHBoxLayout(self.opv)
        self.add = PushButton(FluentIcon.ADD,"添加一行")
        self.rem = PushButton(FluentIcon.DELETE,"删除选中行")
        self.add.clicked.connect(self.addrow)
        self.rem.clicked.connect(self.delrow)
        self.option.addWidget(self.add)
        self.option.addWidget(self.rem)
        self.vbox.addWidget(self.opv)

        self.refresh()
        self.vbox.addWidget(self.table)
        self.table.clicked.connect(self.select)
        self.table.itemChanged.connect(self.savename)
        self.selected_items = self.table.selectedItems()
        self.selected_data = [item.text() for item in self.selected_items]

        self.setObjectName(text.replace(' ', 'NameEdit'))

    def refresh(self):
        self.table.setRowCount(len(self.nametable))
        for i, t in enumerate(self.nametable):
            for j in range(len(self.names.keys())):
                self.table.setItem(i, j, QTableWidgetItem(str(t[j])))

    def addrow(self):
        tmp = ["example","男","0"]
        for t in range(len(self.names.keys())-3):
            tmp.append("None")
        self.nametable.append(tmp)
        self.refresh()

    def delrow(self):
        del self.nametable[self.editing]
        self.editing = 0
        self.refresh()

    def select(self):
        self.selected_items = self.table.selectedItems()
        self.selected_data = [item.text() for item in self.selected_items]
        self.editing = self.nametable.index(self.selected_data)
        logger.debug(self.selected_data)
        logger.debug(self.editing)

    def savename(self):
        global current_name_path
        self.selected_items = self.table.selectedItems()
        self.selected_data = [item.text() for item in self.selected_items]
        self.nametable[self.editing] = self.selected_data
        logger.debug(self.nametable)
        with open(current_name_path,"w",encoding="utf-8") as f:
            namewrite = [",".join(list(self.names.keys()))+"\n"]
            t = 0
            for i in range(len(self.nametable)):
                if self.nametable[i][1] == "男" or self.nametable[i][1] == "0":
                    t = 0
                elif self.nametable[i][1] == "女" or self.nametable[i][1] == "1":
                    t = 1
                else:
                    t = 2
                self.nametable[i][1] = str(t)
                namewrite.append(",".join(self.nametable[i])+"\n")
            logger.debug(namewrite)
            f.writelines(namewrite)

    def loadname(self):
        global current_name_path
        name = pd.read_csv(current_name_path, sep=",", header=0)
        name = name.to_dict()
        self.names["name"] = list(name["name"].values())
        self.names["sex"] = list(name["sex"].values())
        self.names["no"] = list(name["no"].values())
        for i in plugin_customkey:
            self.names[i] = list(name[i].values())
        for k in self.names.keys():
            for i in range(len(self.names[k])):
                self.names[k][i] = str(self.names[k][i])
        for i in range(len(self.names["name"])):
            if int(self.names["sex"][i]) == 0:
                t = "男"
            elif int(self.names["sex"][i]) == 1:
                t = "女"
            else:
                t = "其他"
            tmp = []
            for t in self.names.keys():
                tmp.append(self.names[t][i])
            self.nametable.append(tmp)
        logger.debug(self.nametable)
        logger.info("名单加载完成")

class Settings(QFrame):
    def __init__(self, text: str, parent=None):
        global cfg
        super().__init__(parent=parent)
        self.setObjectName(text.replace(' ', 'Settings'))
        self.stack = QStackedWidget(self)
        self.pivot = Pivot(self)
        self.df = QVBoxLayout(self)
        self.scrollArea = ScrollArea()
        self.scrollArea.setWidgetResizable(True)
        self.scrollArea.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.optv =QWidget()
        self.opts = QVBoxLayout(self.optv)
        self.tlog = PushButton(FluentIcon.DOCUMENT,"测试日志输出")
        self.rlog = PushButton(FluentIcon.SYNC,"重载日志系统")
        self.tcrash = PushButton(FluentIcon.CLOSE,"测试引发崩溃")
        self.tlog.clicked.connect(self.testLog)
        self.rlog.clicked.connect(self.reloadLog)
        self.tcrash.clicked.connect(self.testCrash)
        self.cKey=SettingCard(
            icon=FluentIcon.FONT,
            title="抽选快捷键",
            content="设置抽选的快捷键（不区分大小写，使用英文加号(+)串联多个按键），重启生效"
        )
        self.cKeyInput = LineEdit()
        self.cKeyInput.setPlaceholderText("输入快捷键")
        self.cKeyInput.setText(cfg.get(cfg.chooseKey))
        self.cKey.hBoxLayout.addStretch(20)
        self.cKey.hBoxLayout.addWidget(self.cKeyInput)
        self.cKey.hBoxLayout.addStretch(1)
        self.cKeyInput.textChanged.connect(lambda :cfg.set(cfg.chooseKey,self.cKeyInput.text()))
        self.lock = PushSettingCard(
            icon=FluentIcon.CLOSE,
            title="锁定功能",
            content="重新锁定已经解锁的功能",
            text="锁定"
        )
        self.lock.clicked.connect(self.relock)
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
        ),
        SwitchSettingCard(
            configItem=cfg.autoStartup,
            icon=FluentIcon.POWER_BUTTON,
            title="开机自启",
            content="开机时自动启动（对于非Windows系统无效）"
        ),
        self.cKey,
        SubtitleLabel("安全设置"),
        HyperlinkCard(
            icon=FluentIcon.INFO,
            title="使用前必读",
            content="以下设置项在初次打开时会为您生成密钥，请妥善保管\n您需要凭密钥解锁限制，如果丢失请参照文档执行操作",
            url="https://namepicker-docs.netlify.app/guide/quickstart/lock.html",
            text="点击查看文档"
        ),
        self.lock,
        SwitchSettingCard(
            configItem=cfg.lockNameEdit,
            icon= FluentIcon.HIDE,
            title="禁用名单编辑",
            content="启用后，将无法进行软件内名单编辑，重启生效"
        ),
        SwitchSettingCard(
         configItem=cfg.lockConfigEdit,
         icon=FluentIcon.HIDE,
         title="禁用设置编辑",
         content="启用后，将无法进行软件内设置编辑，重启生效"
        ),
        SubtitleLabel("调试（不要随意使用以下功能，除非您知道您在干什么）"),
        ComboBoxSettingCard(
            configItem=cfg.logLevel,
            icon=FluentIcon.DEVELOPER_TOOLS,
            title="日志记录级别",
            content="日志的详细程度（重启以应用更改）",
            texts=["DEBUG", "INFO", "WARNING","ERROR"]
        ),
        self.tlog,
        self.rlog,
        self.tcrash,
        SubtitleLabel("欢愉（太有乐子了）"),
        SwitchSettingCard(
            configItem=cfg.eco,
            icon=FluentIcon.LEAF,
            title="环保模式",
            content="NamePicker致力于减少碳排放"
        ),SwitchSettingCard(
            configItem=cfg.justice,
            icon=FluentIcon.SPEED_MEDIUM,
            title="绝对公平模式",
            content="启用后，将在主页显示一条提示"
        )]
        for i in self.sets:
            self.opts.addWidget(i)
        self.scrollArea.setStyleSheet("QScrollArea{background: transparent; border: none}")
        self.scrollArea.setWidget(self.optv)
        self.optv.setStyleSheet("QWidget{background: transparent}")
        QScroller.grabGesture(self.scrollArea.viewport(), QScroller.LeftMouseButtonGesture)
        self.df.addWidget(self.pivot)
        self.addSubInterface(self.scrollArea,"Settings","本体设置")
        for i in plugin_settings.keys():
            self.addSubInterface(plugin_settings[i], "%s"%i, "插件设置 - %s"%plugin_info[i]["name"])
        self.pivot.setCurrentItem("Settings")
        self.df.addWidget(self.stack)
        cfg.autoStartup.valueChanged.connect(self.startupChange)
        cfg.lockNameEdit.valueChanged.connect(self.checkLock)
        cfg.lockConfigEdit.valueChanged.connect(self.checkLock)
        logger.info("设置界面初始化完成")

    def addSubInterface(self, widget: QLabel, objectName: str, text: str):
        self.stack.addWidget(widget)
        self.pivot.addItem(
            routeKey=objectName,
            text=text,
            onClick=lambda: self.stack.setCurrentWidget(widget)
        )

    def startupChange(self):
        if cfg.get(cfg.autoStartup):
            self.setStartup()
        else:
            self.removeStartup()

    def setStartup(self):
        if os.name != 'nt':
            return
        file_path='%s/main.exe'%os.path.dirname(os.path.abspath(__file__))
        icon_path = 'assets/favicon.ico'
        startup_folder = os.path.join(os.getenv('APPDATA'), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
        name = os.path.splitext(os.path.basename(file_path))[0]  # 使用文件名作为快捷方式名称
        shortcut_path = os.path.join(startup_folder, f'{name}.lnk')
        shell = Dispatch('WScript.Shell')
        shortcut = shell.CreateShortCut(shortcut_path)
        shortcut.Targetpath = file_path
        shortcut.WorkingDirectory = os.path.dirname(file_path)
        shortcut.IconLocation = icon_path  # 设置图标路径
        shortcut.save()

    def removeStartup(self):
        file_path = '%s/main.exe' % os.path.dirname(os.path.abspath(__file__))
        name = os.path.splitext(os.path.basename(file_path))[0]
        startup_folder = os.path.join(os.getenv('APPDATA'), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
        shortcut_path = os.path.join(startup_folder, f'{name}.lnk')
        if os.path.exists(shortcut_path):
            os.remove(shortcut_path)

    def testLog(self):
        logger.debug("这是Debug日志")
        logger.info("这是Info日志")
        logger.warning("这是Warning日志")
        logger.error("这是Error日志")

    def reloadLog(self):
        w = MessageBox("危险操作", "重载日志系统会清空此前日志并可能引发问题，请不要！不要！不要！使用该功能！除非您真的清楚您在干什么！", self)
        w.yesButton.setText("我真的很清楚我在干什么！")
        w.cancelButton.setText("算了")
        if w.exec():
            logger.remove(1)
            if os.path.exists("out.log"):
                os.remove("out.log")
            logger.add("out.log")
            logger.add(sys.stderr, level=cfg.get(cfg.logLevel))
            logger.success("日志系统重载完成")

    def testCrash(self):
        raise Exception("NamePicker实际上没有任何问题，是你自己手贱引发的崩溃")

    def checkLock(self):
        global unlocked
        if cfg.get(cfg.keyChecksum) == "0" and (cfg.get(cfg.lockNameEdit) or cfg.get(cfg.lockConfigEdit)):
            kd = str(time.time())
            key = bytes(kd.encode("utf-8"))
            keymd5 = hashlib.md5(key).hexdigest()
            cfg.set(cfg.keyChecksum,keymd5)
            logger.info("生成密钥md5")
            with open("KEY","w",encoding="utf-8") as f:
                f.write(kd)
            w = Dialog("生成完成", "由于您是初次启用安全设置，已为您在软件目录生成密钥文件（文件名：KEY），请妥善保管该文件，您将来会需要凭该文件解锁限制", self)
            w.exec()
            if cfg.get(cfg.lockNameEdit):
                unlocked[0] = True
            elif cfg.get(cfg.lockConfigEdit):
                unlocked[1] = True

    def relock(self):
        global unlocked
        unlocked = [False, False]

class About(QFrame):
    def __init__(self, text: str, parent=None):
        global cfg
        super().__init__(parent=parent)
        self.setObjectName(text.replace(' ', 'About'))
        self.df = QVBoxLayout(self)
        self.about = TitleLabel("关于")
        self.image = ImageLabel(QPixmap("assets/NamePickerCircle.png"))
        # self.image.resize(100,100)
        # self.image.setScaledContents(True)
        self.ver = SubtitleLabel("NamePicker %s - Codename %s"%(VERSION,CODENAME))
        self.author = BodyLabel("By 灵魂歌手er（Github @LHGS-github）")
        self.cpleft = BodyLabel("本软件基于GNU GPLv3获得授权")

        self.linkv = QWidget()
        self.links = QHBoxLayout(self.linkv)
        self.ghrepo = HyperlinkButton(FluentIcon.GITHUB, "https://github.com/NamePickerOrg/NamePicker", 'GitHub Repo')
        self.docsite = HyperlinkButton(FluentIcon.DOCUMENT,"https://namepicker-docs.netlify.app/","官方文档")
        self.links.addWidget(self.ghrepo)
        self.links.addWidget(self.docsite)

        self.df.addWidget(self.about)
        self.df.addWidget(self.image)
        self.df.addWidget(self.ver)
        self.df.addWidget(self.author)
        self.df.addWidget(self.cpleft)
        self.df.addWidget(self.linkv)
        logger.info("关于界面初始化")

class KeyMsg(MessageBoxBase):
    def __init__(self, parent=None,check="NameEdit"):
        super().__init__(parent)
        self.check = check
        self.titleLabel = SubtitleLabel('选择KEY文件')
        self.explain = BodyLabel("选择KEY文件以解锁该功能")
        self.selectButton = PrimaryPushButton("点击选择文件")
        self.selectButton.clicked.connect(self.checkFile)
        self.viewLayout.addWidget(self.titleLabel)
        self.viewLayout.addWidget(self.explain)
        self.viewLayout.addWidget(self.selectButton)

    def checkFile(self):
        global unlocked
        options = QFileDialog.Options()
        options |= QFileDialog.DontUseNativeDialog
        file_filter = "All Files (*)"
        fn = QFileDialog.getOpenFileNames(self, "选择KEY文件", "", file_filter, options=options)
        logger.debug(fn)
        if fn[0]:
            with open(fn[0][0],"r",encoding="utf-8") as f:
                key = str(f.read()).encode("utf-8")
                logger.debug(key)
                keymd5 = hashlib.md5(key).hexdigest()
                logger.debug(keymd5)
                if keymd5 == cfg.get(cfg.keyChecksum):
                    if self.check == "NameEdit":
                        unlocked[0] = True
                    else:
                        unlocked[1] = True
                    InfoBar.success(
                        title='校验成功',
                        content="您已完成校验，现在应该可以使用对应功能",
                        orient=Qt.Horizontal,
                        isClosable=True,
                        position=InfoBarPosition.BOTTOM,
                        duration=3000,
                        parent=self
                    )
                else:
                    InfoBar.error(
                        title='校验失败',
                        content="未能成功验证，请确认是否选择了正确的文件",
                        orient=Qt.Horizontal,
                        isClosable=True,
                        position=InfoBarPosition.BOTTOM,
                        duration=3000,
                        parent=self
                    )
        else:
            InfoBar.error(
                title='校验失败',
                content="请选择文件",
                orient=Qt.Horizontal,
                isClosable=True,
                position=InfoBarPosition.BOTTOM,
                duration=3000,
                parent=self
            )

class App(FluentWindow):
    def __init__(self):
        super().__init__()
        qconfig.theme = Theme.AUTO
        setTheme(Theme.AUTO)
        self.Choose = Choose("随机抽选",self)
        self.NameEdit = NameEdit("名单编辑", self)
        self.Settings = Settings("设置",self)
        self.PluginSettings = PluginSettings("插件管理",self)
        self.About = About("关于", self)
        self.initNavigation()
        self.initWindow()
        self.stackedWidget.currentChanged.connect(self.checkLocker)
        logger.info("主界面初始化")

    def checkLocker(self):
        global unlocked
        current = self.stackedWidget.currentWidget()
        logger.debug(current)
        if current == self.NameEdit and cfg.get(cfg.lockNameEdit) and not unlocked[0]:
            w = KeyMsg(self,check="NameEdit")
            w.exec()
            if not unlocked[0]:
                self.switchTo(self.Choose)
        if current == self.Settings and cfg.get(cfg.lockConfigEdit) and not unlocked[1]:
            w = KeyMsg(self, "Settings")
            w.exec()
            if not unlocked[1]:
                self.switchTo(self.Choose)

    def initNavigation(self):
        self.addSubInterface(self.Choose, FluentIcon.HOME, "随机抽选")
        self.addSubInterface(self.NameEdit, FluentIcon.EDIT, "名单编辑")
        self.addSubInterface(self.Settings, FluentIcon.SETTING, '设置', NavigationItemPosition.BOTTOM)
        self.addSubInterface(self.PluginSettings, FluentIcon.APPLICATION, '插件管理', NavigationItemPosition.BOTTOM)
        self.addSubInterface(self.About, FluentIcon.INFO, '关于', NavigationItemPosition.BOTTOM)

    def initWindow(self):
        self.resize(700, 500)
        self.setWindowIcon(QIcon('assets/NamePickerCircle.png'))
        self.setWindowTitle('NamePicker')

    def closeEvent(self, event):
        if "noshortcut" in sys.argv:
            sys.exit(0)
        else:
            self.hide()
            event.ignore()

class SystemTrayIcon(QSystemTrayIcon):
    def __init__(self, parent):
        super().__init__(parent=parent)
        self.setIcon(parent.windowIcon())
        self.menu = SystemTrayMenu(parent=parent)
        self.menu.addActions([
            Action(icon=QIcon("assets/NamePickerCircle.png"),text="NamePicker"),
            Action(FluentIcon.HELP,"帮助",triggered=lambda: QDesktopServices.openUrl(QUrl(
                'https://namepicker-docs.netlify.app')))
        ])
        self.menu.addSeparator()
        self.menu.addActions([
            Action(FluentIcon.HOME,"打开主界面",triggered=parent.show_main_window),
            Action(FluentIcon.SYNC,"重启",triggered=self.restart),
            Action(FluentIcon.CLOSE,'退出', triggered=lambda:sys.exit(0))
        ])
        self.setContextMenu(self.menu)

    def restart(self):
        self.hide()
        os.execl(sys.executable, sys.executable, *sys.argv)

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
        self.main_window = App()
        self.main_window.hide()
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
                if not cfg.get(cfg.supportCS):
                    self.show_main_window()
                else:
                    self.main_window.Choose.pickcb()
            else:
                self.drag = False
            self.drag_start_pos = None
            event.accept()

    def show_main_window(self):
        self.main_window.show()
        self.main_window.activateWindow()

    def paintEvent(self, event):
        painter = QPainter(self)
        pixmap = QPixmap('assets/NamePickerCircle.png')
        painter.drawPixmap(self.rect(), pixmap)
        painter.setCompositionMode(QPainter.CompositionMode_SourceIn)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    load_plugins()
    if plugin_customkey:
        apply_customkey()
    for i in plugin.keys():
        plugin[i].onStartup()
    if "noshortcut" in sys.argv:
        main = App()
        main.show()
    else:
        tray = TrayWindow()
        tray.show()
    sys.exit(app.exec_())