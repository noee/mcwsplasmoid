import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import QtQuick.Window 2.11
import org.kde.kirigami 2.4 as Kirigami
import 'utils.js' as Utils

Item {
    id: root
    property var conn

    property var __win

    signal logMsg(var obj, var msg, var type)

    function init() {
        if (!__win) {
            __win = logWindow.createObject(root)
            __win.show()
            __win.closing.connect(__win.destroy)
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
    function log(obj, msg, type) {
        if (__win)
            event.queueCall(0, logMsg, [obj, msg, type === undefined ? LoggerType.Info : type])
    }

    SingleShot { id: event }

    Component {
        id: logWindow
        ApplicationWindow {
            title: 'Logger'
            height: 800
            width: 600
            x: screen.virtualX
            y: screen.virtualY

            background: Rectangle {
                gradient: Gradient {
                    GradientStop { position: 0; color: "#c1bbf9"  } //"#ffffff"
                    GradientStop { position: 1; color: theme.backgroundColor }// "#c1bbf9" }
                }
            }

            Connections {
                target: root.conn
                ignoreUnknownSignals: true

                onConnectionStart: {
                    msgModel.append({ type: LoggerType.Warning, title: 'ConnectionStart', message: host })
                }
                onConnectionStopped: {
                    msgModel.append({ type: LoggerType.Warning, title: 'ConnectionStop', message: '' })
                }

                onConnectionReady: {
                    msgModel.append({ type: LoggerType.Warning, title: 'ConnectionReady', message: '(%1)'.arg(zonendx) + host })
                }

                onConnectionError: {
                    msgModel.append({ type: LoggerType.Warning, title: 'ConnectionError:\n' + msg, message: cmd })
                }
                onCommandError: {
                    msgModel.append({ type: LoggerType.Warning, title: 'CommandError:\n' + msg, message: cmd })
                }
                onTrackKeyChanged: {
                    msgModel.append({ type: LoggerType.Info, title: zone.zonename + '\nTrackKeyChanged', message: zone.filekey.toString() })
                }
                onPnPositionChanged: {
                    msgModel.append({ type: LoggerType.Info, title: zName(zonendx) + '\nPnPositionChanged', message: pos.toString() })
                }
                onPnChangeCtrChanged: {
                    msgModel.append({ type: LoggerType.Info, title: zName(zonendx) + '\nPnChangeCtrChanged', message: ctr.toString() })
                }
                onPnStateChanged: {
                    msgModel.append({ type: LoggerType.Info, title: zName(zonendx) + '\nPnStateChanged', message: playerState.toString() })
                }
            }
            Connections {
                target: root
                onLogMsg: {
                    var item = { type: type
                        , title: obj.zonename !== undefined
                                 ? obj.zonename
                                 : Utils.stringifyObj(obj)
                        , message: msg }

                    if (type === LoggerType.HiFreq)
                        hifreqModel.append(item)
                    else
                        msgModel.append(item)
                }
            }

            function zName(ndx) {
                return ndx < 0 ? '(%1)No Zone'.arg(ndx) : conn.zoneModel.get(ndx).zonename
            }

            ListModel {
                id: msgModel
                onRowsInserted: event.queueCall(500, msgs.positionViewAtEnd)
            }
            ListModel {
                id: hifreqModel
                onRowsInserted: event.queueCall(500, hifreq.positionViewAtEnd)
            }

            ListView {
                id: msgs
                anchors.fill: parent
                model: msgModel
                clip: true
                delegate: RowLayout {
                    width: parent.width
                    Kirigami.BasicListItem {
                        text: title
                        textColor: type !== LoggerType.Info ? 'red' : 'green'
                        Label {
                            text: message
                            Layout.preferredWidth: parent.width/1.8
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }

            footer: ListView {
                id: hifreq
                model: hifreqModel
                clip: true
                height: parent.height/4
                delegate: RowLayout {
                    width: parent.width
                    Kirigami.BasicListItem {
                        text: title
                        textColor: 'grey'
                        separatorVisible: false
                        Label {
                            text: message
                            color: 'grey'
                            Layout.preferredWidth: parent.width/1.8
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }
                    }
                }
            }

        } // Window
    }
}
