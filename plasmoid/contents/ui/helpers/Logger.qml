import QtQuick 2.11

Item {
    id: root
    enabled: __win !== undefined

    property string winTitle: 'Logger'
    property string pos: 'nw'
    property var __win

    signal logMsg(var title, var msg, var obj)
    signal logWarning(var title, var msg, var obj)
    signal logError(var title, var msg, var obj)

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
    function log(title, msg, obj) {
        if (__win)
            event.queueCall(logMsg, title, msg, obj)
    }
    function warn(title, msg, obj) {
        if (__win)
            event.queueCall(logWarning, title, msg, obj)
    }
    function error(title, msg, obj) {
        if (__win)
            event.queueCall(logError, title, msg, obj)
    }

    SingleShot { id: event }

    Component {
        id: logWindow
        LogWindow {
            logger: root
            windowTitle: winTitle
            winPos: pos
            onClosing: { destroy(); __win = undefined}
        }
    }
}
