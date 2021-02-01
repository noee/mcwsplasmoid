import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.12
import QtQuick.Window 2.11
import org.kde.plasma.extras 2.0 as Extras
import 'utils.js' as Utils

ApplicationWindow {
    id: root
    title: windowTitle
    height: 800
    width: 600
    x: winPos.includes('e')
            ? screen.virtualX + (screen.width - width)
            : screen.virtualX
    y: winPos.includes('s')
            ? screen.virtualY + (screen.height - height)
            : screen.virtualY

    property var logger
    property string winPos: 'nw'
    property string windowTitle: ''

    header: ToolBar {
        implicitWidth: root.width
        RowLayout {
            width: parent.width
            CheckBox {
                id: autoScroll
                checked: true
                text: 'Auto Scroll'
            }
            ToolButton {
                icon.name: 'edit-clear'
                onClicked: msgModel.clear()
            }
            Item { Layout.fillWidth: true }
            ToolButton {
                icon.name: 'format-align-vertical-top'
                onClicked: msgs.positionViewAtBeginning()
            }
            ToolButton {
                icon.name: 'format-align-vertical-bottom'
                onClicked: msgs.positionViewAtEnd()
            }
        }
    }

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0; color: "#c1bbf9" }
            GradientStop { position: 1; color: "black" }
        }
    }

    Connections {
        target: logger

        function __log(type, title, msg, obj) {
            title = title ?? 'unknown'
            obj = obj === undefined ? '' : obj

            var iconString = 'dialog-positive'
            switch (type) {
                case Logger.Info:
                    iconString = 'dialog-information'
                    break
                case Logger.Error:
                    iconString = 'dialog-error'
                    break
                case Logger.Warning:
                    iconString = 'dialog-warning'
                    break
            }

            msgModel.append({ type: type
                            , title: title
                            , message: Utils.isObject(msg) ? Utils.stringifyObj(msg) : msg
                            , object: Utils.isObject(obj) ? Utils.stringifyObj(obj) : obj
                            , iconString: iconString
                            })
        }

        onLogMsg:       __log(Logger.Info, title, msg, obj)
        onLogWarning:   __log(Logger.Warning, title, msg, obj)
        onLogError:     __log(Logger.Error, title, msg, obj)
    }

    // def'n: {type, title, message, iconString, object}
    ListModel {
        id: msgModel
        onRowsInserted:
            if (autoScroll.checked)
                event.queueCall(250, msgs.positionViewAtEnd)
    }

    ListView {
        id: msgs
        anchors.fill: parent
        model: msgModel
        clip: true
        delegate: Extras.ExpandableListItem {
            title: model.title ?? ''
            subtitle: message ?? ''
            subtitleCanWrap: true
            icon: iconString

            customExpandedViewContent: Component {
                Extras.DescriptiveLabel {
                    text: model.object
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
            }

        }
    }
}
