import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import org.kde.kirigami 2.5 as Kirigami

import QtGraphicalEffects 1.0
import "controls"

ColumnLayout {
    id: root

    readonly property bool scrollText: plasmoid.configuration.scrollTrack
    readonly property bool hideControls: plasmoid.configuration.hideControls
    property real pointSize: Math.floor(root.height * 0.25)
    property real zmAdj: mcws.zoneModel.count <= 1 ? 2 : mcws.zoneModel.count*1.5
    property real itemWidth: Math.floor(root.width / zmAdj)

    function reset(zonendx) {
        event.queueCall(() => {
            lvCompact.model = mcws.zoneModel
            lvCompact.currentIndex = zonendx
        })
    }

    signal zoneClicked(var zonendx)

    Connections {
        id: conn
        target: mcws
        enabled: false
        onConnectionStart: lvCompact.model = ''
        onConnectionReady: reset(zonendx)
    }

    ListView {
        id: lvCompact
        Layout.fillHeight: true
        Layout.fillWidth: true
        orientation: ListView.Horizontal
        layoutDirection: plasmoid.configuration.rightJustify ? Qt.RightToLeft : Qt.LeftToRight
        layer.enabled: plasmoid.configuration.dropShadows
        layer.effect: DropShadow {
                        radius: 3
                        samples: 7
                        color: Kirigami.Theme.textColor
                        horizontalOffset: 1
                        verticalOffset: 1
                    }

        property int hoveredInto: -1

        function itemClicked(ndx) {
            if (model.playingnowtracks !== 0) {
                lvCompact.hoveredInto = -1
                lvCompact.currentIndex = ndx
            }
            zoneClicked(ndx)
        }
        function itemHovered(ndx, entered) {
            if (model.playingnowtracks === 0)
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
                implicitHeight: Math.round(Kirigami.Units.largeSpacing * 1.5)
                implicitWidth: Math.round(Kirigami.Units.largeSpacing * 1.5)
                radius: 5
                color: "light green"
            }
        }
        Component {
            id: imgComp
            ShadowImage {
                sourceSize.height: Math.round(root.height * .75)
                sourceSize.width: Math.round(root.height * .75)
                sourceKey: filekey
            }
        }

        delegate: RowLayout {
            id: compactDel
            height: parent.height
            spacing: 3
            // spacer
            Rectangle {
                width: 1
                Layout.fillHeight: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.disabledTextColor
                opacity: !plasmoid.configuration.rightJustify && index > 0
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
                    onHoveredChanged: lvCompact.itemHovered(index, containsMouse)
                    onClicked: lvCompact.itemClicked(index)
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

                TextMetrics {
                    id: tm1
                    text: name
                    font.pointSize: pointSize
                    elide: Text.ElideRight
                }
                TextMetrics {
                    id: tm2
                    text: artist
                    font.pointSize: Math.floor(pointSize * .85)
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
                        event.queueCall(200, () => {
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
                        onHoveredChanged: lvCompact.itemHovered(index, containsMouse)
                        onClicked: lvCompact.itemClicked(index)
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
                        onHoveredChanged: lvCompact.itemHovered(index, containsMouse)
                        onClicked: lvCompact.itemClicked(index)
                    }
                }
            }
            // playback controls
            RowLayout {
                opacity: playingnowtracks > 0
                            && compactDel.ListView.isCurrentItem
                            && (hideControls ? lvCompact.hoveredInto === index : true)
                visible: opacity
                spacing: 0

                Behavior on opacity {
                    NumberAnimation { duration: Kirigami.Units.longDuration * 4 }
                }
                PrevButton {
                    onHoveredChanged: lvCompact.itemHovered(index, hovered)
                }
                PlayPauseButton {
                    onHoveredChanged: lvCompact.itemHovered(index, hovered)
                }
                StopButton {
                    onHoveredChanged: lvCompact.itemHovered(index, hovered)
                }
                NextButton {
                    onHoveredChanged: lvCompact.itemHovered(index, hovered)
                }
            }
            // spacer
            Rectangle {
                width: 1
                Layout.fillHeight: true
                color: Kirigami.Theme.disabledTextColor
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                opacity: plasmoid.configuration.rightJustify && index > 0
            }

        }
    }

    Component.onCompleted: {
        // At plasmoid start, if connected, we will have already missed connection signals
        // as the Loader is dynamic, so reset explicitly on create...
        if (mcws.isConnected) {
            reset(mcws.getPlayingZoneIndex())
        }
        // ...and wait before enabling the signals from mcws
        event.queueCall(500, () => { conn.enabled = true })
    }
}
