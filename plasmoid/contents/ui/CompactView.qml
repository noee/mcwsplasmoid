import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2

import QtGraphicalEffects 1.0
import "controls"

ColumnLayout {
    id: root

    readonly property bool scrollText: plasmoid.configuration.scrollTrack
    readonly property bool hideControls: plasmoid.configuration.hideControls
    readonly property real btnSize: .8
    property int pixSize: root.height * 0.25
    property real zmAdj: mcws.zoneModel.count <= 1 ? 2 : mcws.zoneModel.count*1.5
    property real itemWidth: root.width / zmAdj

    function reset(zonendx) {
        lvCompact.model = null
        event.queueCall(500, () => {
            lvCompact.model = mcws.zoneModel
            lvCompact.currentIndex = zonendx
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
        Layout.fillHeight: true
        Layout.fillWidth: true
        orientation: ListView.Horizontal
        layoutDirection: plasmoid.configuration.rightJustify ? Qt.RightToLeft : Qt.LeftToRight
        Layout.alignment: Qt.AlignVCenter
        layer.enabled: plasmoid.configuration.dropShadows
        layer.effect: DropShadow {
                        radius: 3
                        samples: 7
                        color: theme.textColor
                        horizontalOffset: 1
                        verticalOffset: 1
                    }

        property int hoveredInto: -1

        function itemClicked(ndx, pnTracks) {
            if (pnTracks !== 0) {
                lvCompact.hoveredInto = -1
                lvCompact.currentIndex = ndx
            }
            zoneClicked(ndx)
        }
        function itemHovered(ndx, pnTracks, entered) {
            if (pnTracks === 0)
                return

            if (entered === undefined)
                entered = false

            if (entered) {
                lvCompact.hoveredInto = ndx
                event.queueCall(700, () =>
                {
                    if (lvCompact.hoveredInto === ndx) {
                        lvCompact.currentIndex = ndx
                    }
                })
            } else {
                lvCompact.hoveredInto = -1
            }
        }

        Component {
            id: rectComp
            Rectangle {
                implicitHeight: units.gridUnit*.5
                implicitWidth: implicitHeight
                radius: 5
                color: "light green"
            }
        }
        Component {
            id: imgComp
            TrackImage {
                sourceSize.height: root.height * .75
                sourceKey: filekey
            }
        }

        delegate: RowLayout {
            id: compactDel
            spacing: 2
            // spacer
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2 //units.smallSpacing
                Layout.rightMargin: 2 //units.smallSpacing
                width: 1
                height: root.height
                color: "grey"
                opacity: plasmoid.configuration.rightJustify ? index = model.count : index > 0
            }
            // playback indicator
            Loader {
                id: indLoader
                sourceComponent: (model.state === PlayerState.Playing || model.state === PlayerState.Paused)
                                 ? (plasmoid.configuration.useImageIndicator ? imgComp : rectComp)
                                 : undefined

                // TrackImage (above) uses filekey, so propogate it to the component
                property string filekey: model.filekey

                visible: model.state === PlayerState.Playing || model.state === PlayerState.Paused

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onHoveredChanged: lvCompact.itemHovered(index, playingnowtracks, containsMouse)
                    onClicked: lvCompact.itemClicked(index, playingnowtracks)
                }

                OpacityAnimator {
                    running: model.state === PlayerState.Paused
                    target: indLoader
                    from: 1
                    to: 0
                    duration: 1500
                    loops: Animation.Infinite
                    onStopped: indLoader.opacity = 1
                }
            }
            // track text
            ColumnLayout {
                id: trackCol
                spacing: 0
                Layout.alignment: Qt.AlignVCenter

                TextMetrics {
                    id: tm1
                    text: name
                    font.pointSize: pixSize
                    elide: Text.ElideRight
                }
                TextMetrics {
                    id: tm2
                    text: artist
                    font.pointSize: pixSize * .85
                    elide: Text.ElideRight
                }

                Marquee {
                    id: t1
                    text: tm1.text
                    fontSize: tm1.font.pointSize
                    Layout.fillWidth: true
                    padding: 0
                    elide: tm1.elide
                    onTextChanged: {
                        event.queueCall(500, () => {
                            if (t1.text.length >= 15 || t2.text.length >= 15) {
                                implicitWidth = Math.max(Math.min(tm1.width, itemWidth), t2.implicitWidth)
                            } else {
                                // For short artist/track, try to make both show
                                var w = Math.max(tm1.width, tm2.width)
                                implicitWidth = w + (itemWidth-w)/zmAdj
                            }

                            if (scrollText && playingnowtracks > 0)
                                restart()
                        })
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onHoveredChanged: lvCompact.itemHovered(index, playingnowtracks, containsMouse)
                        onClicked: lvCompact.itemClicked(index, playingnowtracks)
                    }
                }
                Marquee {
                    id: t2
                    text: tm2.text
                    fontSize: tm2.font.pointSize
                    implicitWidth: Math.min(tm2.width, itemWidth)
                    Layout.fillWidth: true
                    padding: 0
                    elide: tm2.elide

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onHoveredChanged: lvCompact.itemHovered(index, playingnowtracks, containsMouse)
                        onClicked: lvCompact.itemClicked(index, playingnowtracks)
                    }
                }
            }
            // playback controls
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                opacity: playingnowtracks > 0
                            && compactDel.ListView.isCurrentItem
                            && (hideControls ? lvCompact.hoveredInto === index : true)
                visible: opacity
                spacing: 0

                Behavior on opacity {
                    NumberAnimation { duration: 750 }
                }
                PrevButton {
                    Layout.preferredHeight: root.height * btnSize
                    Layout.preferredWidth: root.height * btnSize
                    hoverEnabled: true
                    onHoveredChanged: lvCompact.itemHovered(index, playingnowtracks, hovered)
                }
                PlayPauseButton {
                    Layout.preferredHeight: root.height * btnSize
                    Layout.preferredWidth: root.height * btnSize
                    onHoveredChanged: lvCompact.itemHovered(index, playingnowtracks, hovered)
                }
                StopButton {
                    Layout.preferredHeight: root.height * btnSize
                    Layout.preferredWidth: root.height * btnSize
                    onHoveredChanged: lvCompact.itemHovered(index, playingnowtracks, hovered)
                }
                NextButton {
                    Layout.preferredHeight: root.height * btnSize
                    Layout.preferredWidth: root.height * btnSize
                    onHoveredChanged: lvCompact.itemHovered(index, playingnowtracks, hovered)
                }
            }
        }
    }

    Component.onCompleted: {
        if (mcws.isConnected) {
            reset(mcws.getPlayingZoneIndex())
        }
        // bit of a hack to deal with the dynamic loader as form factor changes vs. plasmoid startup
        // event-queue the connection-enable on create
        event.queueCall(500, () => { conn.enabled = true })
    }
}
