import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0

Item {
        anchors.fill: parent

        function reset(zonendx) {
            lvCompact.model = null
            event.singleShot(300, function()
            {
                lvCompact.model = mcws.model
                if (zonendx !== undefined)
                    event.singleShot(800, function() {lvCompact.positionViewAtIndex(zonendx, ListView.End)})
            })
        }

        signal zoneClicked(var zonendx)

        Connections {
            target: mcws
            onConnectionReady: reset(zonendx)
        }

        ListView {
            id: lvCompact
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: 3
            delegate: RowLayout {
                spacing: 1
                Rectangle {
                    id: stateInd
                    implicitHeight: units.gridUnit*.5
                    implicitWidth: units.gridUnit*.5
                    Layout.margins: 2
                    radius: 5
                    color: model.state !== mcws.stateStopped ? "light green" : "grey"
                    NumberAnimation {
                        running: model.state === mcws.statePaused
                        target: stateInd
                        properties: "opacity"
                        from: 1
                        to: 0
                        duration: 1500
                        loops: Animation.Infinite
                        onStopped: stateInd.opacity = 1
                      }
                }
                FadeText {
                    aText: name + "\n" + artist
                    Layout.fillWidth: true
                    font.pointSize: theme.defaultFont.pointSize-1.5
                    MouseArea {
                        anchors.fill: parent
                        onClicked: zoneClicked(index)
                    }
                }
                PlasmaComponents.ToolButton {
                    iconSource: "media-skip-backward"
                    flat: false
                    visible: mcws.isConnected
                    enabled: playingnowposition !== "0"
                    onClicked: mcws.previous(index)
                }
                PlasmaComponents.ToolButton {
                    iconSource: {
                        if (mcws.isConnected)
                            model.state === mcws.statePlaying ? "media-playback-pause" : "media-playback-start"
                        else
                            "media-playback-start"
                    }
                    flat: false
                    visible: mcws.isConnected
                    onClicked: mcws.play(index)
                }
                PlasmaComponents.ToolButton {
                    iconSource: "media-skip-forward"
                    flat: false
                    visible: mcws.isConnected
                    enabled: nextfilekey !== "-1"
                    onClicked: mcws.next(index)
                }
                Rectangle {
                    Layout.margins: 3
                    width: 1
                    color: "grey"
                    height: lvCompact.height*.75
                }
            }
        }

        PlasmaComponents.Button {
            text: "MCWS Remote"
            visible: !mcws.isConnected
            onClicked: plasmoid.expanded = !plasmoid.expanded
        }

        Component.onCompleted: {
            if (advTrayView && mcws.isConnected)
                reset(currentZone)
        }
}
