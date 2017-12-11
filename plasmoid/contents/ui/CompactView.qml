import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0

import QtGraphicalEffects 1.0

Item {
    id: main
        anchors.fill: parent

        function reset(zonendx)
        {
            var list = mcws.zonesByState(mcws.statePlaying)
            var currZone = list.length>0 ? list[list.length-1] : zonendx

            if (currZone === undefined || currZone === -1)
                currZone = mcws.zoneModel.count-1

            lvCompact.model = null
            event.singleShot(300, function()
            {
                lvCompact.model = mcws.zoneModel
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

        DropShadow {
            anchors.fill: lvCompact
            radius: 3
            samples: 7
            visible: plasmoid.configuration.dropShadows
            color: theme.backgroundColor
            source: lvCompact
        }

        ListView {
            id: lvCompact
            anchors.fill: parent
            orientation: ListView.Horizontal

            property int hoveredInto: -1

            delegate: RowLayout {
                id: compactDel
                spacing: 1
                // spacer
                Rectangle {
                    Layout.rightMargin: 3
                    Layout.leftMargin: 3
                    Layout.alignment: Qt.AlignCenter
                    width: 1
                    height: main.height
                    color: "grey"
                    opacity: index > 0
                }
                // playback indicator
                Component {
                    id: rectComp
                    Rectangle {
                        id: stateInd
                        implicitHeight: units.gridUnit*.5
                        implicitWidth: implicitHeight
                        radius: 5
                        color: "light green"
                        NumberAnimation {
                            running: mcws.isPaused(index)
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
                        id: img
                        key: filekey
                        animateLoad: true
                        implicitHeight: units.gridUnit * 1.75
                        implicitWidth: implicitHeight
                        NumberAnimation {
                            running: mcws.isPaused(index)
                            target: img
                            properties: "opacity"
                            from: .8
                            to: 0
                            duration: 1500
                            loops: Animation.Infinite
                            onStopped: img.opacity = .8
                        }
                    }
                }
                Loader {
                    sourceComponent: !mcws.isStopped(index)
                                     ? (plasmoid.configuration.useImageIndicator ? imgComp : rectComp)
                                     : undefined
                    Layout.rightMargin: 3
                    width: units.gridUnit * (plasmoid.configuration.useImageIndicator ? 1.75 : .5)
                    height: width
                    visible: !mcws.isStopped(index)
                }
                // track text
                ColumnLayout {
                    spacing: 0
                    FadeText {
                        id: txtName
                        aText: !mcws.isPlaylistEmpty(index) ? name : zonename
                        font.pixelSize: main.height * .3
                        Layout.alignment: Qt.AlignRight
                        Layout.maximumWidth: theme.mSize(theme.defaultFont).width * 12
                        elide: Text.ElideRight
                    }
                    FadeText {
                        id: txtArtist
                        aText: !mcws.isPlaylistEmpty(index) ? artist : '<empty playlist>'
                        font.pixelSize: txtName.font.pixelSize
                        Layout.alignment: Qt.AlignRight
                        Layout.maximumWidth: theme.mSize(theme.defaultFont).width * 12
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            if (mcws.isPlaylistEmpty(index))
                                return

                            lvCompact.hoveredInto = index
                            event.singleShot(700, function()
                            {
                                if (lvCompact.hoveredInto === index)
                                    lvCompact.currentIndex = index
                            })
                        }
                        onClicked: {
                            if (!mcws.isPlaylistEmpty(index)) {
                                lvCompact.hoveredInto = -1
                                lvCompact.currentIndex = index
                            }
                            zoneClicked(index)
                        }
                    }
                }
                // playback controls
                PlasmaComponents.ToolButton {
                    iconSource: "media-skip-backward"
                    flat: false
                    Layout.leftMargin: 3
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
                        mcws.isConnected
                            ? mcws.isPlaying(index) ? "media-playback-pause" : "media-playback-start"
                            : "media-playback-start"
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
