import json
import importlib
import time
import pyotp
import base64
import qrcode
import hashlib
import socket
import os
import sys
import tempfile
import random
import traceback
import network
from loguru import logger
from PySide6.QtCore import QObject, Slot,Property,Signal,QPoint,Qt,QThread, QWaitCondition, QMutex,QMutexLocker
from PySide6.QtWidgets import QApplication,QSystemTrayIcon, QMenu, QWidget
from PySide6.QtGui import QDesktopServices,QIcon,QGuiApplication, QPixmap, QPainter, QColor
from RinUI import RinUIWindow
if os.name == 'nt':
    from win32com.client import Dispatch

temp_dir = tempfile.gettempdir()
VERSION = "v2.1.3dev"
CODENAME = "Fugue"
VER_NO = 5
APIVER = 2
force = False

SEXFAVOR_ALL = NUMFAVOR_BOTH = -1
SEXFAVOR_BOY = NUMFAVOR_1 = 0
SEXFAVOR_GIRL = NUMFAVOR_2 = 1
SEXFAVOR_SPEC = 2

if not sys.stderr:
    class FakeStderr:
        def __init__(self):
            pass
        def write(self, message):
            pass
        def flush(self):
            pass
        def isatty(self):
            return True
    sys.stderr = FakeStderr()

def hookExceptions(exc_type, exc_value, exc_tb):
    error_details = ''.join(traceback.format_exception(exc_type, exc_value, exc_tb))
    if "TypeError: disconnect() of all signals failed" in error_details:
        return
    logger.error(error_details)
    # if not error_dialog:
    #     # w = ErrorDialog(error_details)
    #     # w.exec()
    #     pass
sys.excepthook = hookExceptions

def resource_path(relative_path:str)-> str:
    if hasattr(sys, '_MEIPASS'):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.abspath(relative_path)

class LifeCycle(QThread):
    def __init__(self, parent = None):
        super().__init__(parent)
        self.mutex = QMutex()  # 互斥锁，用于线程同步
        self.cond = QWaitCondition()
        self.stop = False

    def run(self):
        while True:
            with QMutexLocker(self.mutex):
                if self.stop:
                    return
                # 接插件lifecycle
                time.sleep(0.05)
            

class Choose:
    def __init__(self,path:str):
        self.names = []
        self.namel = []
        self.sex = [[],[],[]]
        self.num = [[],[],[]]
        self.chosen = []
        self.sexFavor = SEXFAVOR_ALL
        self.numFavor = NUMFAVOR_BOTH
        self.loadnames(path)

    def loadnames(self,path:str) -> None:
        try:
            self.names = []
            self.namel = []
            with open(path,"r",encoding="utf-8") as f:
                fl = f.readlines()
            head = fl[0].strip("\n").split(",")
            del fl[0]
            for i in range(len(fl)):
                l = fl[i].strip("\n").split(",")
                struct = {}
                for j in range(len(head)):
                    struct[head[j]] = l[j]
                self.names.append(struct)
                self.namel.append(i)
        except (UnicodeDecodeError,IndexError):
            logger.warning("名单文件无效")
            os.remove(path)
            if not os.path.exists("names"):
                os.makedirs("names")
            with open(path,"w",encoding="utf-8") as f:
                f.write("name,sex,no\n某人,0,1")
        except FileNotFoundError:
            logger.warning("没有找到指定文件")
            if not os.path.exists("names"):
                os.makedirs("names")
            with open(path,"w",encoding="utf-8") as f:
                f.write("name,sex,no\n某人,0,1")

    def loadFavor(self) -> None:
        logger.debug("loadFavor")
        self.namel = []
        for i in range(len(self.names)):
            self.namel.append(i)
        for i in range(len(self.namel)):
            if self.sexFavor == SEXFAVOR_ALL and self.numFavor == NUMFAVOR_BOTH:
                break
            else:
                if ((int(self.names[i]["sex"]) != self.sexFavor)
                or (int(self.names[i]["no"])%2 == 0 and self.numFavor==NUMFAVOR_1) 
                or (int(self.names[i]["no"])%2 == 1 and self.numFavor==NUMFAVOR_2)):
                    del self.namel[i]

    def setSexFavor(self,target:str) -> None:
        self.sexFavor = target
        self.loadFavor()

    def setNumFavor(self,target:str) -> None:
        self.numFavor = target
        self.loadFavor()

    def pick(self,num:int=1) -> list:
        resi = []
        res = []
        for i in range(num):
            if not cfg.get("General","allowRepeat") and not self.namel==[]:
                ans = random.choice(self.namel)
                resi.append(self.namel[self.namel.index(ans)])
                del self.namel[self.namel.index(ans)]
                logger.debug(self.namel)
                continue
            elif not cfg.get("General","allowRepeat") and self.namel==[]:
                self.loadFavor()
                ans = random.choice(self.namel)
            else:
                ans = random.choice(self.namel)
            resi.append(self.namel[self.namel.index(ans)])

        for i in resi:
            res.append(self.names[i])
        if res != []:
            return res
        else:
            return ["bydcnm"]

def setStartup() -> None:
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

def removeStartup() -> None:
    if os.name != 'nt':
        return
    file_path = '%s/main.exe' % os.path.dirname(os.path.abspath(__file__))
    name = os.path.splitext(os.path.basename(file_path))[0]
    startup_folder = os.path.join(os.getenv('APPDATA'), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
    shortcut_path = os.path.join(startup_folder, f'{name}.lnk')
    if os.path.exists(shortcut_path):
        os.remove(shortcut_path)

def macAddr() -> str:
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    mac_address = ':'.join(['{:02x}'.format((int(i, 16) & 0xff)) for i in hex(int(ip_address.split('.')[0])).split('0x')[1:]])
    return mac_address

class Config:
    def __init__(self,filename:str,rules:dict,default:dict):
        self.filename = filename
        try:
            with open(filename,"r",encoding="utf-8") as f:
                self.cfgf = f.read()
                self.cfg = json.loads(self.cfgf)
            for i in list(rules.keys()):
                if i not in self.cfg.keys():
                    self.cfg[i] = default[i]
                    continue
                for j in list(rules[i].keys()):
                    if j not in rules[i].keys():
                        self.cfg[i][j] = default[i][j]
                    elif j not in self.cfg[i].keys():
                        self.cfg[i][j] = default[i][j]
                    elif not self.val(i,j,self.cfg[i][j],rules):
                        self.cfg[i][j] = default[i][j]
        except FileNotFoundError:
            logger.warning("未找到配置文件，将创建默认配置")
            with open(filename,"w",encoding="utf-8") as f:
                f.write(json.dumps(default))
            self.cfg = default
        except json.JSONDecodeError:
            logger.warning("无效的配置文件")
            with open(filename,"w",encoding="utf-8") as f:
                f.write(json.dumps(default))
            self.cfg = default

    def val(self,i:str,j:str,chk:any,rules:dict) -> bool:
        try:
            if type(rules[i][j]) == list:
                if ((rules[i][j][0] == "range" and (rules[i][j][1] > chk or rules[i][j][2] < chk)) 
                    or (rules[i][j][0] == "option" and chk not in rules[i][j]) 
                    or (rules[i][j][0] == "list" and type(chk) != list)):
                    return False
            elif type(chk) != rules[i][j]:
                return False
            else:
                return True
        except KeyError:
            return False

    def get(self,cls:str,key:str) -> any:
        return self.cfg[cls][key]
    
    def set(self,cls:str,key:str,val) -> None:
        self.cfg[cls][key] = val
        with open(self.filename,"w",encoding="utf-8") as f:
            f.write(json.dumps(self.cfg))

CFGRULE = {
    "General": {"allowRepeat": bool,"autoStartup": bool,"chooseKey": str,"supportCS": bool,"floatingPos":str,"autoCheck":bool},
    "Secure": {"lock":bool,"password":str,"require2FA":bool,"2FAMethod":["option","otp"],"OTPnote":str},
    "Version": {"apiver": ["range",2,2],"channel":["option","rel","dev"]},
    "Huanyu": {"ecoMode": bool,"justice": bool},
    "Debug": {"logLevel": ["option","DEBUG","INFO","WARNING","ERROR"]}
}

CFGDEFAULT = {
    "General": {"allowRepeat": False,"autoStartup": False,"chooseKey": "ctrl+w","supportCS": False,"floatingPos":"auto","autoCheck":False},
    "Secure": {"lock":False,"password":"","require2FA":False,"2FAMethod":"otp","OTPnote":""},
    "Version": {"apiver": 2,"channel":"rel"},
    "Huanyu": {"ecoMode": False,"justice": False},
    "Debug": {"logLevel": "INFO"}
}

cfg = Config("config.json",CFGRULE,CFGDEFAULT)

if os.path.exists("out.log"):
    os.remove("out.log")
logger.add("out.log")
logger.add(sys.stderr, level=cfg.get("Debug","logLevel"))
logger.info("NamePicker %s - Codename %s (Inside version %d,Plugin API Version %d)"%(VERSION,CODENAME,VER_NO,APIVER))
logger.info("「历经生死、重获新生的忘归人，何时才能返乡？⌋")
core = Choose("names/%s"%os.listdir("names")[0])
th = network.Version()
upd = network.Update()
verified = False
mac = macAddr()
secretKey = base64.b32encode(mac.encode(encoding="utf-8"))
totp = pyotp.TOTP(secretKey)
totp_url = totp.provisioning_uri("NamePicker - %s"%cfg.get("Secure","OTPnote"), issuer_name="NamePicker 2FA")
x = 0
y = 0
ver = ""

class UI(RinUIWindow):
    def __init__(self):
        super().__init__(resource_path("pages/main.qml"))
        self.bridge = Bridge()
        self.engine.rootContext().setContextProperty("Bridge", self.bridge)

class Bridge(QObject):
    chgVer = Signal(str)
    chgProg = Signal(int)
    chgPhase = Signal(str)

    @Slot(str,result=list)
    def Pick(self,num:str) -> list:
        r = core.pick(int(num))
        re = []
        if r == ["bydcnm"]:
            return r
        else:
            for i in r:
                re.append("%s(%s)"%(i["name"],i["no"]))
            return re
        
    @Slot(str,str,result=list)
    def GetCfg(self,cls:str,key:str) -> list:
        return [cfg.get(cls,key)]
    
    @Slot(result=int)
    def GetNLen(self) -> int:
        return len(core.names.keys())
    
    @Slot(str,str,list)
    def SetCfg(self,cls:str,key:str,val:list) -> list:
        cfg.set(cls,key,val[0])

    @Slot(int,result=int)
    def GetDbg(self,cls:int) -> int:
        return ["DEBUG","INFO","WARNING","ERROR"].index(cfg.get("Debug","logLevel"))

    @Slot(bool)
    def Startup(self,stat:bool) -> None:
        if stat:
            setStartup()
        else:
            removeStartup()

    @Slot(str,result=bool)
    def VerifyPassword(self,password:str) -> bool:
        return hashlib.md5(password.encode(encoding='UTF-8')).hexdigest() == cfg.get("Secure","password")
    
    @Slot(bool,result=bool)
    def setVerified(self,vl:bool) -> None:
        global verified
        logger.debug("setVerified")
        verified = vl

    @Slot(result=bool)
    def getVerified(self) -> bool:
        global verified
        if verified:
            return True
        else:
            return not cfg.get("Secure","lock")
    
    @Slot(str,result=bool)
    def VerifyFile(self,path:str) -> bool:
        pass

    @Slot(str)
    def setPassword(self,password:str) -> None:
        cfg.set("Secure","password",hashlib.md5(password.encode(encoding='UTF-8')).hexdigest())

    @Slot(str,result=bool)
    def VerifyOTP(self,code:str) -> bool:
        global totp
        return totp.verify(code)
        
    @Slot(int,result=int)
    def Get2FA(self,cls:int) -> int:
        return ["otp"].index(cfg.get("Secure","2FAMethod"))
    
    @Property(str)
    def GetOTPSecret(self) -> str:
        logger.debug("GetOTPSecret")
        global secretKey
        return secretKey
    
    @Slot(str)
    def GenTOTPImg(self,note:str) -> None:
        global totp,totp_url
        logger.debug("TOTP Image")
        cfg.set("Secure","OTPnote",note)
        totp_url = totp.provisioning_uri("NamePicker/%s"%cfg.get("Secure","OTPnote"), issuer_name="NamePicker 2FA")
        qr = qrcode.make(totp_url)
        qr.save("qr.png")

    @Slot(bool)
    def chgStartup(self,stat:bool) -> None:
        cfg.set("General","autoStartup",stat)
        if stat:
            setStartup()
        else:
            removeStartup()

    @Property(str)
    def VerTxt(self) -> str:
        return "当前版本：%s - Codename %s"%(VERSION,CODENAME)
    
    @Slot(str)
    def setSexFavor(self,sexf:str) -> None:
        core.setSexFavor(["都抽", "只抽男", "只抽女", "只抽特殊性别"].index(sexf)-1)
    
    @Slot(str)
    def setNumFavor(self,numf:str) -> None:
        core.setNumFavor(["都抽", "只抽单数", "只抽双数"].index(numf)-1)

    @Slot(result=list)
    def getNameList(self) -> list:
        return os.listdir("names")
    
    @Slot(int)
    def changeNameList(self,path:int) -> None:
        logger.debug("names/%s"%os.listdir("names")[path])
        core.loadnames("names/%s"%os.listdir("names")[path])

    @Property(int)
    def getDwn(self) -> int:
        return 0
    
    @Property(str)
    def getStat(self) -> str:
        return 1
    
    @Slot()
    def checkNew(self) -> str:
        global force,th
        th.versionChange.connect(self.emitCg)
        th.local = VER_NO
        th.channel = cfg.get("Version","channel")
        th.force = force
        th.start()
        # return self.ver
        
    def emitCg(self,s):
        global ver
        logger.debug(s)
        ver = s
        self.chgVer.emit(s)

    # @Property(str)
    # def getVer(self):
    #     global ver
    #     logger.debug(ver)
    #     return ver
        
    @Slot(result=int)
    def getChannel(self):
        return ["rel","dev"].index(cfg.get("Version","channel"))
    
    @Slot(bool)
    def setForce(self,b:bool):
        global force
        force = b

    @Slot(result=bool)
    def getForce(self):
        global force
        return force
    
    @Slot()
    def update(self):
        global upd,ver
        upd.tag = ver
        upd.valueChange.connect(self.emitProg)
        upd.phaseChange.connect(self.emitPhase)
        upd.start()

    def emitProg(self,s):
        self.chgProg.emit(s)

    def emitPhase(self,s):
        self.chgPhase.emit(s)

class TrayIcon(QSystemTrayIcon):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setIcon(QIcon(resource_path("assets/NamePickerCircle.png")))
        self.menu = QMenu()
        self.product_name = self.menu.addAction("NamePicker")
        self.menu.addSeparator()
        self.show_action = self.menu.addAction("显示主界面")
        self.res_action = self.menu.addAction("重启")
        self.exit_action = self.menu.addAction("退出")
        self.show_action.triggered.connect(self.show_main_window)
        self.res_action.triggered.connect(self.restart)
        self.exit_action.triggered.connect(QApplication.quit)
        self.setContextMenu(self.menu)
        self.main_window = None
        if cfg.get("General","autoCheck"):
            th.channel = cfg.get("Version","channel")
            th.force = False
            th.local = VER_NO
            th.versionChange.connect(self.notify)
            th.start()
    
    def notify(self,s:str):
        if s == "latest":
            pass
        else:
            self.showMessage("NamePicker","检测到更新：%s -> %s"%(VERSION,s),QIcon("assets/NamePickerCircle.png"))
    def show_main_window(self) -> None:
        if self.main_window is None:
            self.main_window = UI()
            self.main_window.show()
        else:
            self.main_window.show()
            self.main_window.activateWindow()
    
    def restart(self) -> None:
        self.hide()
        os.execl(sys.executable, sys.executable, *sys.argv)

class FloatingWindow(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowFlags(
            Qt.FramelessWindowHint | 
            Qt.WindowStaysOnTopHint |
            Qt.Tool |
            Qt.X11BypassWindowManagerHint 
        )
        self.setFixedSize(100, 100)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.tray = TrayIcon(self)
        self.tray.show()
        self.icon = QPixmap(resource_path("assets/NamePickerCircle.png"))
        self.icon = self.icon.scaled(300, 300, Qt.KeepAspectRatio)
        if self.icon.isNull():
            logger.error("无法加载图标")
        screen_geometry = QGuiApplication.primaryScreen().availableGeometry()
        if cfg.get("General","floatingPos") == "auto":
            self.move(int(screen_geometry.width()*0.7), int(screen_geometry.height()*0.7))
        else:
            cur = cfg.get("General","floatingPos")
            self.move(int(cur.split(",")[0]), int(cur.split(",")[1]))
        self.main_window = None
        self.drag_start_pos = QPoint()
        self.drag_threshold = 0  # 拖动判定阈值（像素）
        self.is_dragging = False

    def paintEvent(self, event) -> None: # 真不是我不想写Type Hint，我真不知道event是什么类型
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        painter.drawPixmap(self.rect(), self.icon)

    def mousePressEvent(self, event) -> None: # 同理
        if event.button() == Qt.LeftButton:
            self.drag_start_pos = event.globalPosition().toPoint()
            self.mouse_press_pos = event.globalPosition().toPoint()
            self.is_dragging = False
            event.accept()

    def mouseMoveEvent(self, event) -> None: # 同理
        if event.buttons() == Qt.LeftButton:
            # 计算移动距离
            move_distance = (event.globalPosition().toPoint() - self.mouse_press_pos).manhattanLength()
            if move_distance > self.drag_threshold:
                self.is_dragging = True
            
            if self.is_dragging:
                # 更新窗口位置
                delta = event.globalPosition().toPoint() - self.drag_start_pos
                self.move(self.pos() + delta)
                self.drag_start_pos = event.globalPosition().toPoint()
            event.accept()

    def mouseReleaseEvent(self, event) -> None: # 同理
        if event.button() == Qt.LeftButton:
            if not self.is_dragging:
                # 点击逻辑
                if not cfg.get("General", "supportCS"):
                    self.show_main_window()
                else:
                    r = core.pick(1)
                    re = []
                    if r == ["bydcnm"]:
                        pass
                    else:
                        for i in r:
                            re.append("%s(%s)"%(i["name"],i["no"]))
                        with open("%s/unread"%temp_dir,"w",encoding="utf-8") as f:
                            f.write("91")
                        with open("%s/res.txt"%temp_dir,"w",encoding="utf-8") as f:
                            f.write(",".join(re))
            self.is_dragging = False
            x = self.pos().x()
            y = self.pos().y()
            cfg.set("General","floatingPos","%d,%d"%(x,y))
            event.accept()

    def show_main_window(self) -> None:
        self.main_window = UI()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setWindowIcon(QIcon(resource_path("assets/favicon.ico")))
    if "noshortcut" in sys.argv:
        main = UI()
    else:
        main = FloatingWindow()
        main.show()
    app.exec()