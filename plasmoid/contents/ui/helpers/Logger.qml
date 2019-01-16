import QtQuick 2.11

Item {
    id: root
    enabled: __win !== undefined

    property string winTitle: 'Logger'
    property string messageTitleRole: ''
    property string pos: 'nw'
    property var __win

    signal logMsg(var obj, var msg)
    signal logWarning(var obj, var msg)
    signal logError(var obj, var msg)

    function init() {
        if (!__win) {
            __win = logWindow.createObject(root)
            __win.show()
        }
        else {
            __win.showNormal()
            __win.raise()
        }
    }
    function close() {
        if (__win)
            __win.destroy()
    }
    function log(obj, msg) {
        if (__win)
            event.queueCall(0, logMsg, [obj, msg])
    }
    function warn(obj, msg) {
        if (__win)
            event.queueCall(0, logWarning, [obj, msg])
    }
    function error(obj, msg) {
        if (__win)
            event.queueCall(0, logError, [obj, msg])
    }

    SingleShot { id: event }

    Component {
        id: logWindow
        LogWindow {
            logger: root
            windowTitle: winTitle
            msgTitleRole: messageTitleRole
            winPos: pos
            onClosing: { destroy(); __win = undefined}
        }
    }
}
