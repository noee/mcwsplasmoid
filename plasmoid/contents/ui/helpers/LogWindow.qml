import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import QtQuick.Window 2.11
import org.kde.kirigami 2.4 as Kirigami
import 'utils.js' as Utils

ApplicationWindow {
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
    property string msgTitleRole: ''
    property string windowTitle: ''

    header: RowLayout {
        ToolButton {
            icon.name: 'format-align-vertical-top'
            Layout.preferredHeight: units.iconSizes.medium
            Layout.preferredWidth: units.iconSizes.medium
            onClicked: msgs.positionViewAtBeginning()
        }
        ToolButton {
            icon.name: 'format-align-vertical-bottom'
            Layout.preferredHeight: units.iconSizes.medium
            Layout.preferredWidth: units.iconSizes.medium
            onClicked: msgs.positionViewAtEnd()
        }
        Item {
            Layout.fillWidth: true
        }
        CheckBox {
            id: autoScroll
            checked: true
            text: 'Auto Scroll'
        }
        ToolButton {
            icon.name: 'edit-clear'
            Layout.preferredHeight: units.iconSizes.medium
            Layout.preferredWidth: units.iconSizes.medium
            onClicked: msgModel.clear()
        }
    }

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0; color: "#c1bbf9" }
            GradientStop { position: 1; color: "black" }
        }
    }

    function __log(type, obj, msg) {
        if (typeof obj === 'object')
            var t = msgTitleRole !== '' & obj[msgTitleRole] !== undefined
                    ? obj[msgTitleRole]
                    : Utils.stringifyObj(obj)
        else
            t = obj

        var m = typeof msg === 'object' ? Utils.stringifyObj(msg) : msg

        var iconString = ''
        switch (type) {
            case LoggerType.Info:
                iconString = 'dialog-information'
                break
            case LoggerType.Error:
                iconString = 'dialog-error'
                break
            case LoggerType.Warning:
                iconString = 'dialog-warning'
                break
            default:
                iconString = 'dialog-positive'
        }


        var item = { type: type
            , title: t
            , message: m
            , iconString: iconString}

        msgModel.append(item)
    }

    Connections {
        target: logger

        onLogMsg: __log(LoggerType.Info, obj, msg)
        onLogWarning: __log(LoggerType.Warning, obj, msg)
        onLogError: __log(LoggerType.Error, obj, msg)
    }

    ListModel {
        id: msgModel
        onRowsInserted: if (autoScroll.checked) event.queueCall(500, msgs.positionViewAtEnd)
    }

    ListView {
        id: msgs
        anchors.fill: parent
        model: msgModel
        clip: true
        delegate:
            ColumnLayout {
                width: parent.width
                Kirigami.BasicListItem {
                    text: title
                    separatorVisible: false
                    icon: iconString
                    textColor: type !== LoggerType.Info ? 'red' : 'green'
                    onClicked: msgs.currentIndex = index
                    Label {
                        text: message
                        Layout.preferredWidth: parent.width/1.6
                        wrapMode: Text.WrapAnywhere
                    }
                }
                Rectangle {
                    color: theme.highlightColor
                    Layout.fillWidth: true
                    height: 1
                }
            }
    }
}
