import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0

Item {
        anchors.fill: parent

        function reset(zonendx)
        {
            var list = mcws.zonesByState(mcws.statePlaying)
            var currZone = list.length>0 ? list[list.length-1] : zonendx

            if (currZone === undefined || currZone === -1)
                currZone = 0

            lvCompact.model = null
            event.singleShot(300, function()
            {
                lvCompact.model = mcws.model
                event.singleShot(800, function()
                {
                    lvCompact.positionViewAtIndex(currZone, ListView.End)
                    lvCompact.currentIndex = currZone
                })
            })
        }

        signal zoneClicked(var zonendx)

        Connections {
            id: conn
            target: mcws
            enabled: false
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

                Component {
                    id: rectComp
                    Rectangle {
                        id: stateInd
                        implicitHeight: units.gridUnit*.5
                        implicitWidth: implicitHeight
                        radius: 5
                        color: "light green"
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
                }
                Component {
                    id: imgComp
                    TrackImage {
                        key: filekey
                        animateLoad: true
                        implicitHeight: units.gridUnit * 1.75
                        implicitWidth: implicitHeight
                    }
                }

                Loader {
                    sourceComponent: model.state !== mcws.stateStopped
                                     ? (plasmoid.configuration.useImageIndicator ? imgComp : rectComp)
                                     : undefined
                    Layout.rightMargin: 3
                    width: units.gridUnit * plasmoid.configuration.useImageIndicator ? 1.75 : .5
                    height: width
                    visible: model.state !== mcws.stateStopped
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
                        onExited: lvCompact.hoveredInto = -1

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
            if (mcws.isConnected) {
                reset(currentZone)
            }
            // bit of a hack to deal with the dynamic loader as form factor changes vs. plasmoid startup
            // event-queue the connection-enable on startup
            Qt.callLater(function(){ conn.enabled = true })
        }

}
