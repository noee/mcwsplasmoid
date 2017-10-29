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
                    event.singleShot(800, function()
                    {
                        lvCompact.positionViewAtIndex(zonendx, ListView.End)
                        lvCompact.currentIndex = zonendx
                    })
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

            property int hoveredInto: -1

            delegate: RowLayout {
                id: compactDel
                spacing: 1
                anchors.margins: 0

                Rectangle {
                    id: stateInd
                    implicitHeight: units.gridUnit*.5
                    implicitWidth: units.gridUnit*.5
                    Layout.margins: 2
                    radius: 5
                    color: "light green"
                    visible: model.state !== mcws.stateStopped
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

                ColumnLayout {
                    spacing: 1
                    FadeText {
                        id: txtName
                        aText: name
                        font.pointSize: theme.defaultFont.pointSize-1.2
                        Layout.alignment: Qt.AlignRight
                        Layout.maximumWidth: units.gridUnit * 20
                        elide: Text.ElideRight
                    }
                    FadeText {
                        id: txtArtist
                        aText: artist
                        font.pointSize: theme.defaultFont.pointSize-1.2
                        Layout.alignment: Qt.AlignRight
                        Layout.maximumWidth: units.gridUnit * 20
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            lvCompact.hoveredInto = index
                            event.singleShot(700, function()
                            {
                                if (lvCompact.hoveredInto === index)
                                    lvCompact.currentIndex = index
                            })
                        }

                        onClicked: zoneClicked(index)
                    }
                }

                PlasmaComponents.ToolButton {
                    iconSource: "media-skip-backward"
                    flat: false
                    opacity: compactDel.ListView.isCurrentItem
                    visible: opacity
                    enabled: playingnowposition !== "0"
                    onClicked: mcws.previous(index)
                    Behavior on opacity {
                        NumberAnimation { duration: 750 }
                    }
                }
                PlasmaComponents.ToolButton {
                    iconSource: {
                        if (mcws.isConnected)
                            model.state === mcws.statePlaying ? "media-playback-pause" : "media-playback-start"
                        else
                            "media-playback-start"
                    }
                    opacity: compactDel.ListView.isCurrentItem
                    visible: opacity
                    flat: false
                    onClicked: mcws.play(index)
                    Behavior on opacity {
                        NumberAnimation { duration: 750 }
                    }
                }
                PlasmaComponents.ToolButton {
                    iconSource: "media-playback-stop"
                    flat: false
                    opacity: compactDel.ListView.isCurrentItem
                    visible: plasmoid.configuration.showStopButton && opacity
                    onClicked: mcws.stop(index)
                    Behavior on opacity {
                        NumberAnimation { duration: 750 }
                    }
                }
                PlasmaComponents.ToolButton {
                    iconSource: "media-skip-forward"
                    flat: false
                    enabled: nextfilekey !== "-1"
                    opacity: compactDel.ListView.isCurrentItem
                    visible: opacity
                    onClicked: mcws.next(index)
                    Behavior on opacity {
                        NumberAnimation { duration: 750 }
                    }
                }
                Rectangle {
                    Layout.margins: 3
                    width: 1
                    color: "grey"
                    height: lvCompact.height*.75
                }
            }
        }

        Component.onCompleted: {
            if (advTrayView && mcws.isConnected)
                reset(currentZone)
        }
}
