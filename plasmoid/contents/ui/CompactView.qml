import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.12
import org.kde.plasma.core 2.1 as PlasmaCore

import QtGraphicalEffects 1.15
import 'controls'
import 'helpers'

ColumnLayout {
    id: root

    readonly property bool imageIndicator: plasmoid.configuration.useImageIndicator

    readonly property bool scrollText: plasmoid.configuration.scrollTrack
    readonly property bool hideControls: plasmoid.configuration.hideControls
    property real pointSize: Math.floor(root.height * 0.25)
    property real zmAdj: mcws.zoneModel.count <= 1 ? 2 : Math.round(mcws.zoneModel.count*1.5)
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
        layoutDirection: plasmoid.configuration.rightJustify
                         ? Qt.RightToLeft
                         : Qt.LeftToRight
        layer.enabled: plasmoid.configuration.dropShadows
        layer.effect: DropShadow {
                        radius: 3
                        samples: 7
                        color: PlasmaCore.Theme.textColor
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

            lvCompact.hoveredInto = entered ? ndx : -1
            if (entered)
                event.queueCall(700, () => {
                    // force the item selection and bring it
                    // into view
                    if (lvCompact.hoveredInto === ndx)
                        lvCompact.currentIndex = ndx
                })
        }

        delegate: RowLayout {
            id: compactDel
            height: lvCompact.height
            spacing: 0

            // spacer
            Rectangle {
                width: 1
                Layout.fillHeight: true
                Layout.margins: Math.floor(PlasmaCore.Units.smallSpacing/3)
                color: PlasmaCore.Theme.disabledTextColor
                opacity: !plasmoid.configuration.rightJustify && index > 0
            }

            // playback indicator
            Item {
                implicitHeight: Math.round(root.height * .8)
                implicitWidth: Math.round(root.height * .8)
                visible: model.state !== PlayerState.Stopped

                PlasmaCore.IconItem {
                    anchors.fill: parent
                    source: 'enjoy-music-player'
                    visible: !imageIndicator
                }

                ShadowImage {
                    visible: imageIndicator
                    anchors.fill: parent
                    sourceKey: filekey
                    imageUtils: mcws.imageUtils
                    thumbnail: true
                    shadow.size: PlasmaCore.Units.smallSpacing
                }

                MouseAreaEx {
                    onHoveredChanged: lvCompact.itemHovered(index, containsMouse)
                    onClicked: lvCompact.itemClicked(index)
                }

                VisibleBehavior on visible {}
            }

            // track text
            ColumnLayout {
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
                    textColor: Qt.lighter(PlasmaCore.ColorScope.textColor, 1.5)
                    fontSize: tm1.font.pointSize
                    Layout.fillWidth: true
                    padding: 0
                    elide: tm1.elide
                    fade: false
                    onTextChanged: {
                        event.queueCall(() => {
                            if (t1.text.length >= 15 || t2.text.length >= 15) {
                                implicitWidth = Math.max(Math.min(tm1.width, itemWidth), t2.implicitWidth)
                            } else {
                                // For short artist/track, try to make both show
                                const w = Math.max(tm1.width, tm2.width)
                                implicitWidth = w + (itemWidth-w)/zmAdj
                            }

                            if (scrollText && playingnowtracks > 0)
                                restart()
                        })
                    }

                    MouseAreaEx {
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

                    MouseAreaEx {
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
                    NumberAnimation { duration: PlasmaCore.Units.longDuration * 4 }
                }
                PrevButton {
                    onHoveredChanged: lvCompact.itemHovered(index, hovered)
                }
                PlayPauseButton {
                    onHoveredChanged: lvCompact.itemHovered(index, hovered)
                }
                StopButton {
                    visible: plasmoid.configuration.showStopButton
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
                color: PlasmaCore.Theme.disabledTextColor
                Layout.margins: Math.floor(PlasmaCore.Units.smallSpacing/3)
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
        event.queueCall(500, () => conn.enabled = true)
    }
}
