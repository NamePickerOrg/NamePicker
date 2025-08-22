import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI

FluentPage {
    title: "设置"
    Dialog {
        id: askPswd
        title: qsTr("输入密码")
        modal: true
        width: 500
        Text {
            Layout.fillWidth: true
            text: qsTr("由于管理员的的设置，您需要密码才能使用此页面")
        }
        InfoBar {
            Layout.fillWidth: true
            severity: Severity.Info
            title: qsTr("忘记密码了怎么办？")
            text: qsTr("如果您是管理员，请参阅NamePicker文档以重置密码；如果您是普通用户，那么您不应该记住密码，也不存在“忘记密码”一说")
            closable: false
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("输入密码")
            }
            TextField {
                id: pswdInput
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                placeholderText: qsTr("输入密码")
            }
        }
        onAccepted: {
            var accPswd = Bridge.VerifyPassword(pswdInput.text)
            if(accPswd&Bridge.GetCfg("Secure","require2FA")[0]){
                pswdInput.text=""
                ask2FA.open()
            }
            else if(accPswd&!Bridge.GetCfg("Secure","require2FA")[0]){
                Bridge.setVerified(true)
                floatLayer.createInfoBar({
                        severity: Severity.Success,
                        title: qsTr("成功"),
                        text: qsTr("您现在应该可以正常访问功能，如果还不能，请切换界面再切换回来.")
                    })
                pswdInput.text=""
            }
            else{
                floatLayer.createInfoBar({
                        severity: Severity.Error,
                        title: qsTr("错误"),
                        text: qsTr("密码错误，请再试一次.")
                    })
                pswdInput.text=""
            }
        }
        standardButtons: Dialog.Ok | Dialog.Cancel
    }
    Dialog {
        id: setPswd
        title: qsTr("设置密码")
        modal: true
        width: 500
        Text {
            Layout.fillWidth: true
            text: qsTr("请设置一个安全的密码")
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("输入密码")
            }
            TextField {
                id: pswdSet
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                placeholderText: qsTr("输入密码")
            }
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("再次输入密码")
            }
            TextField {
                id: pswdSet2nd
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                placeholderText: qsTr("再次输入密码")
            }
        }
        onAccepted: {
            if(pswdSet.text==pswdSet2nd.text){
                Bridge.setPassword(pswdSet.text)
                floatLayer.createInfoBar({
                        severity: Severity.Success,
                        title: qsTr("成功"),
                        text: qsTr("密码设置成功.")
                    })
                pswdSet.text=""
                pswdSet2nd.text=""
            }
            else{
                floatLayer.createInfoBar({
                        severity: Severity.Error,
                        title: qsTr("失败"),
                        text: qsTr("两次密码输入不一致.")
                    })
                pswdSet.text=""
                pswdSet2nd.text=""
                pswdSw.checked = false
            }
        }
        onRejected: {
            pswdSet.text=""
            pswdSet2nd.text=""
            pswdSw.checked = false
            Bridge.SetCfg("Secure","lock",[false])
        }
        standardButtons: Dialog.Ok | Dialog.Cancel
    }
    Dialog {
        id: resetPswd
        title: qsTr("重新设置密码")
        modal: true
        width: 500
        Text {
            Layout.fillWidth: true
            text: qsTr("请设置一个安全的密码")
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("输入原密码")
            }
            TextField {
                id: pswdOld
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                placeholderText: qsTr("输入原密码")
            }
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("输入新密码")
            }
            TextField {
                id: pswdReset
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                placeholderText: qsTr("输入新密码")
            }
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("再次输入密码")
            }
            TextField {
                id: pswdReset2nd
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                placeholderText: qsTr("再次输入密码")
            }
        }
        onAccepted: {
            if(pswdReset.text==pswdReset2nd.text&Bridge.VerifyPassword(pswdOld.text)){
                Bridge.setPassword(pswdReset.text)
                floatLayer.createInfoBar({
                        severity: Severity.Success,
                        title: qsTr("成功"),
                        text: qsTr("密码重置成功.")
                    })
                pswdOld.text=""
                pswdReset.text=""
                pswdReset2nd.text=""
            }
            else{
                floatLayer.createInfoBar({
                        severity: Severity.Error,
                        title: qsTr("错误"),
                        text: qsTr("两次密码输入不匹配，或者原密码错误.")
                    })
                pswdOld.text=""
                pswdReset.text=""
                pswdReset2nd.text=""
            }
        }
        standardButtons: Dialog.Ok | Dialog.Cancel
    }
    Dialog {
        id: ask2FA
        title: qsTr("选择一种二步验证方式")
        modal: true
        width: 500
        Text {
            Layout.fillWidth: true
            text: qsTr("按照管理员的设置，您需要额外步骤才能解锁功能")
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("选择一种二步验证方式")
            }
            ComboBox{
                id: choose2FA
                property var data: Bridge.get2FA[0]
                model: Bridge.get2FA[1]
                currentIndex: 0
            }
        }
        onAccepted: {
            console.log(Bridge.get2FA[0])
            if(choose2FA.data[choose2FA.currentIndex]=="otp"){
                askOTP.open()
            }
        }
        standardButtons: Dialog.Ok | Dialog.Cancel
    }
    Dialog {
        id: askOTP
        title: qsTr("使用您的TOTP APP进行认证")
        modal: true
        width: 500
        Text {
            Layout.fillWidth: true
            text: qsTr("按照管理员的设置，您需要额外步骤才能解锁功能")
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("输入TOTP APP中显示的代码")
            }
            TextField {
                id: otpInput
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                placeholderText: qsTr("输入代码")
            }
        }
        onAccepted: {
            if(Bridge.VerifyOTP(otpInput.text)){
                Bridge.setVerified(true)
                floatLayer.createInfoBar({
                        severity: Severity.Success,
                        title: qsTr("成功"),
                        text: qsTr("您现在应该可以正常访问功能，如果还不能，请切换界面再切换回来.")
                    })
                otpInput.text=""
            }
            else{
                floatLayer.createInfoBar({
                        severity: Severity.Error,
                        title: qsTr("错误"),
                        text: qsTr("代码错误，请再试一遍.")
                    })
                otpInput.text=""
            }
        }
        standardButtons: Dialog.Ok | Dialog.Cancel
    }
    Dialog {
        id: oTPSetup
        title: qsTr("设置您的TOTP APP")
        modal: true
        width: 500
        Text {
            Layout.fillWidth: true
            text: qsTr("使用您的TOTP APP扫码以设置TOTP")
        }
        InfoBar {
            Layout.fillWidth: true
            severity: Severity.Info
            title: qsTr("如果您无法扫码，请在您的TOTP APP中输入以下代码以设置")
            text: Bridge.GetOTPSecret
            closable: false
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("输入设备备注")
            }
            TextField {
                id: note
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                placeholderText: qsTr("输入备注")
                text: qsTr("测试机")
            }
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("生成二维码")
            }
            Button{
                text: qsTr("点击生成")
                onClicked: {
                    Bridge.GenTOTPImg(note.text)
                    flyoutQR.open()
                }
            }
            Flyout {
                id: flyoutQR
                // image: Qt.resolvedUrl("../qr.png")
                text: qsTr("请在软件根目录下找到qr.png进行扫描")
            }
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("输入TOTP APP中显示的代码")
            }
            TextField {
                id: otpVal
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                placeholderText: qsTr("输入代码")
            }
        }
        RowLayout {
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: qsTr("输入您的密码")
            }
            TextField {
                id: passVal
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                placeholderText: qsTr("输入密码")
            }
        }
        onAccepted: {
            if(Bridge.VerifyOTP(otpVal.text)&Bridge.VerifyPassword(passVal.text)){
                floatLayer.createInfoBar({
                        severity: Severity.Success,
                        title: qsTr("成功"),
                        text: qsTr("TOTP APP设置成功.")
                    })
            }
            else{
                floatLayer.createInfoBar({
                        severity: Severity.Error,
                        title: qsTr("错误"),
                        text: qsTr("代码或密码错误.")
                    })
                otpSwitch.checked = false
            }
        }
        standardButtons: Dialog.Ok | Dialog.Cancel
    }
    Column {
        Layout.fillWidth: true
        spacing: 3
        Text {
            typography: Typography.BodyStrong
            text: "如果您的管理员设置了密码"
        }
        SettingCard {
            width: parent.width
            title: qsTr("解锁")
            description: qsTr("点击右侧按钮解锁")
            icon: "ic_fluent_lock_open_20_regular"
            content: Button{
                text: qsTr("点击解锁")
                onClicked: askPswd.open()
            }
            enabled: Bridge.GetCfg("Secure","lock")[0]
        }
        SettingCard {
            width: parent.width
            title: qsTr("锁定")
            description: qsTr("点击右侧按钮锁定，如果没有生效请切换页面")
            icon: "ic_fluent_lock_closed_20_regular"
            content: Button{
                text: qsTr("点击锁定")
                onClicked: {
                    Bridge.setVerified(false)
                    floatLayer.createInfoBar({
                        severity: Severity.Success,
                        title: qsTr("成功"),
                        text: qsTr("切换界面使设置生效.")
                    })
                }
            }
            enabled: Bridge.GetCfg("Secure","lock")[0]
        }
    }
    Column {
        Layout.fillWidth: true
        spacing: 3
        Text {
            typography: Typography.BodyStrong
            text: "常规"
        }
        SettingCard {
            width: parent.width
            title: qsTr("允许重复点名")
            description: qsTr("是否允许抽到重复的名字")
            icon: "ic_fluent_arrow_repeat_all_20_regular"
            content: Switch{
                id: arpSwitch
                checked: Bridge.GetCfg("General","allowRepeat")[0]
                onClicked: Bridge.SetCfg("General","allowRepeat",[arpSwitch.checked])
            }
            enabled: Bridge.getVerified()
        }
        SettingCard {
            width: parent.width
            title: qsTr("开机自启")
            description: qsTr("是否开机自动启动，对于非Windows系统无效")
            icon: "ic_fluent_power_20_regular"
            content: Switch{
                checked: Bridge.GetCfg("General","autoStartup")[0]
                onClicked: chgStartup(checked)
            }
            enabled: Bridge.getVerified()
        }
        SettingCard {
            width: parent.width
            title: qsTr("抽选快捷键")
            description: qsTr("拿来占位的")
            icon: "ic_fluent_bin_recycle_20_regular"
            enabled: Bridge.getVerified()
        }
        SettingCard {
            width: parent.width
            title: qsTr("注册URL协议")
            description: qsTr("注册成功后，即可通过namepicker://调起没有浮窗的NamePicker\n什么你问怎么取消注册？抱歉我没做，自行删除对应的注册表条目即可")
            icon: "ic_fluent_key_reset_20_regular"
            content: Button{
                text: qsTr("点击注册")
                onClicked: {
                    Bridge.registerURL()
                    floatLayer.createInfoBar({
                        severity: Severity.Success,
                        title: qsTr("成功"),
                        text: qsTr("导入软件目录下的file.reg即可注册")
                    })
                }
            }
            enabled: Bridge.getVerified()
        }
        SettingCard {
            width: parent.width
            title: qsTr("课表软件联动")
            description: qsTr("启用后将在ClassIsland/Class Widgets上（而非主界面）显示抽选结果，需要安装对应插件")
            icon: "ic_fluent_arrow_repeat_all_20_regular"
            content: Switch{
                id: scsSwitch
                checked: Bridge.GetCfg("General","supportCS")[0]
                onClicked: Bridge.SetCfg("General","supportCS",[scsSwitch.checked])
            }
            enabled: Bridge.getVerified()
        }
        SettingCard {
            width: parent.width
            title: qsTr("自动检查更新")
            description: qsTr("是否在启动时检查更新")
            icon: "ic_fluent_arrow_sync_checkmark_20_regular"
            content: Switch{
                checked: Bridge.GetCfg("General","autoCheck")[0]
                onClicked: Bridge.SetCfg("General","autoCheck",[checked])
            }
            enabled: Bridge.getVerified()
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 3
        Text {
            typography: Typography.BodyStrong
            text: "安全"
        }
        SettingCard {
            width: parent.width
            title: qsTr("启用加锁")
            description: qsTr("启用后，将会对设置页面进行加锁，需要密码才能访问")
            icon: "ic_fluent_lock_closed_20_regular"
            content: Switch{
                id: pswdSw
                checked: Bridge.GetCfg("Secure","lock")[0]
                onClicked: {
                    if(Bridge.GetCfg("Secure","password")[0]==""&checked){
                        setPswd.open()
                    }
                    Bridge.SetCfg("Secure","lock",[checked])
                }
            }
            enabled: Bridge.getVerified()
        }
        SettingCard {
            width: parent.width
            title: qsTr("重设密码")
            description: qsTr("重新设置密码")
            icon: "ic_fluent_key_reset_20_regular"
            content: Button{
                text: qsTr("点击重设")
                onClicked: resetPswd.open()
            }
            enabled: Bridge.GetCfg("Secure","lock")[0]&Bridge.getVerified()
        }
        SettingCard {
            width: parent.width
            title: qsTr("启用二步验证")
            description: qsTr("启用后，打开受保护的界面时需要额外步骤才能完成授权")
            icon: "ic_fluent_lock_multiple_20_regular"
            enabled: Bridge.GetCfg("Secure","lock")[0] & Bridge.getVerified()
            content: Switch{
                checked: Bridge.GetCfg("Secure","require2FA")[0]
                onClicked: {
                    Bridge.SetCfg("Secure","require2FA",[checked])
                }
            }
        }
        SettingExpander {
            width: parent.width
            title: qsTr("二步验证方法")
            description: qsTr("进行二步验证的方式")
            icon: "ic_fluent_lock_shield_20_regular"
            enabled: Bridge.GetCfg("Secure","lock")[0]&Bridge.GetCfg("Secure","require2FA")[0] & Bridge.getVerified()
            SettingItem {
                title: qsTr("TOTP APP")
                description: qsTr("使用您的手机APP完成设置")
                Switch {
                    id: otpSwitch
                    checked: Bridge.have2FA("otp")
                    onClicked: {
                        if(checked){
                            Bridge.add2FA("otp")
                            oTPSetup.open()
                        }
                        else{
                            Bridge.rem2FA("otp")
                        }
                    }
                }
            }
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 3
        Text {
            typography: Typography.BodyStrong
            text: "外观"
        }
        SettingCard {
            width: parent.width
            title: qsTr("明暗主题")
            description: qsTr("选择界面主题")
            icon: "ic_fluent_paint_brush_20_regular"
            content: ComboBox {
                property var data: ["Light", "Dark", "Auto"]
                model: ["亮色", "暗色", "跟随系统设定"]
                currentIndex: data.indexOf(Theme.getTheme())
                onCurrentIndexChanged: {
                    Theme.setTheme(data[currentIndex])
                }
            }
            enabled: Bridge.getVerified()
        }
        SettingCard {
            width: parent.width
            title: qsTr("窗口特效")
            description: qsTr("调整窗口背景的效果，仅在Windows上工作，部分特效仅在Windows 11上工作")
            icon: "ic_fluent_rectangle_landscape_sparkle_20_regular"
            content: ComboBox {
                property var data: ["mica", "acrylic", "tabbed", "none"]
                model: ["Mica", "亚克力", "Tabbed", "无"]
                currentIndex: data.indexOf(Theme.getBackdropEffect())
                onCurrentIndexChanged: {
                    Theme.setBackdropEffect(data[currentIndex])
                }
            }
            enabled: Bridge.getVerified()
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 3
        Text {
            typography: Typography.BodyStrong
            text: "调试（不要乱动，除非您知道您在干什么）"
        }
        SettingCard {
            width: parent.width
            title: qsTr("日志等级")
            description: qsTr("日志的详细程度，重启生效")
            icon: "ic_fluent_document_20_regular"
            content: ComboBox {
                property var data: ["DEBUG","INFO","WARNING","ERROR"]
                model: ["DEBUG","INFO","WARNING","ERROR"]
                currentIndex: Bridge.GetDbg(1)[0]
                onCurrentIndexChanged: {
                    Bridge.SetCfg("Debug","logLevel",[data[currentIndex]])
                }
            }
            enabled: Bridge.getVerified()
        }
        SettingCard {
            width: parent.width
            title: qsTr("抛出错误")
            description: qsTr("日")
            icon: "ic_fluent_document_20_regular"
            content: Button{
                text: qsTr("1234")
                onClicked:Bridge.error()
            }
            enabled: Bridge.getVerified()
        }
    }
}