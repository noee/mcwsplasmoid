import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2

import QtGraphicalEffects 1.0
import "controls"

ColumnLayout {
    id: root

    property int txtMaxSize: (width / mcws.zoneModel.count) * multi
    property int pixSize: root.height * 0.25
    property real multi: (pixSize > theme.mSize(theme.defaultFont).width * 1.5)
                            ? (pixSize / theme.mSize(theme.defaultFont).width)
                            : 1

    function reset(zonendx) {
        lvCompact.model = null
        event.queueCall(500, function()
        {
            lvCompact.model = mcws.zoneModel
            if (zonendx === -1)
                zonendx = mcws.getPlayingZoneIndex()

            lvCompact.currentIndex = zonendx
            lvCompact.resetPosition(2000)
        })
    }

    signal zoneClicked(var zonendx)

    Connections {
        id: conn
        target: mcws
        enabled: false
        onConnectionReady: reset(zonendx)
        onTrackKeyChanged: lvCompact.resetPosition(1000)
        onPnStateChanged: lvCompact.resetPosition(1000)
    }

    Connections {
        target: plasmoid.configuration
        onUseZoneCountChanged: lvCompact.resetPosition(1000)
        onTrayViewSizeChanged: lvCompact.resetPosition(1000)
        onRightJustifyChanged: lvCompact.resetPosition(1000)
    }

    ListView {
        id: lvCompact
        Layout.fillHeight: true
        Layout.fillWidth: true
        orientation: ListView.Horizontal
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
        function itemHovered(ndx, pnTracks) {
            if (pnTracks === 0)
                return

            lvCompact.hoveredInto = ndx
            event.queueCall(700, function()
            {
                if (lvCompact.hoveredInto === ndx) {
                    lvCompact.currentIndex = ndx
                    lvCompact.resetPosition(1000)
                }
            })
        }

        function itemSize(len) {
            var base = multi * len * theme.mSize(theme.defaultFont).width * .6
            return len < 15
                    ? base
                    : Math.min(base, txtMaxSize * .8)
        }

        function resetPosition(delay) {
            if (plasmoid.configuration.rightJustify)
                event.queueCall(delay === undefined ? 0 : delay
                                , lvCompact.positionViewAtIndex
                                , [mcws.zoneModel.count - 1, ListView.End])
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
                animateLoad: true
                implicitHeight: root.height * .75
                implicitWidth: implicitHeight
                sourceKey: filekey
            }
        }

        delegate: RowLayout {
            id: compactDel
            // spacer
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: units.smallSpacing
                Layout.rightMargin: units.smallSpacing
                width: 1
                height: root.height
                color: "grey"
                opacity: index > 0
            }
            // playback indicator
            Loader {
                id: indLoader
                sourceComponent: (model.state === mcws.statePlaying || model.state === mcws.statePaused)
                                 ? (plasmoid.configuration.useImageIndicator ? imgComp : rectComp)
                                 : undefined

                // TrackImage (above) uses filekey, so propogate it to the component
                property string filekey: model.filekey

                visible: model.state === mcws.statePlaying || model.state === mcws.statePaused

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: lvCompact.itemHovered(index, +playingnowtracks)
                    onExited: lvCompact.hoveredInto = -1
                    onClicked: lvCompact.itemClicked(index, +playingnowtracks)
                }

                OpacityAnimator {
                    running: model.state === mcws.statePaused
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

                Marquee {
                    id: mq
                    text: +playingnowtracks > 0 ? name : zonename
                    fontSize: pixSize
                    Layout.maximumWidth: txtMaxSize
                    Layout.fillWidth: true
                    padding: 0
                    elide: Text.ElideRight

                    onTextChanged: {
                        implicitWidth = Math.min(contentWidth
                                                     , lvCompact.itemSize(text.length)
                                                     , txtMaxSize/2
                                                     )
                        if (plasmoid.configuration.scrollTrack)
                            event.queueCall(500, mq.restart)
                   }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: lvCompact.itemHovered(index, +playingnowtracks)
                        onExited: lvCompact.hoveredInto = -1
                        onClicked: lvCompact.itemClicked(index, +playingnowtracks)
                    }
                }
                Marquee {
                    id: t2
                    text: +playingnowtracks > 0 ? artist : trackdisplay
                    fontSize: pixSize * .9
                    Layout.fillWidth: true
                    Layout.maximumWidth: txtMaxSize
                    padding: 0
                    elide: Text.ElideRight

                    onTextChanged: implicitWidth = lvCompact.itemSize(text.length)

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: lvCompact.itemHovered(index, +playingnowtracks)
                        onExited: lvCompact.hoveredInto = -1
                        onClicked: lvCompact.itemClicked(index, +playingnowtracks)
                    }
                }
            }
            // playback controls
            RowLayout {
                implicitHeight: compactDel.height *.9
                Layout.alignment: Qt.AlignVCenter
                opacity: compactDel.ListView.isCurrentItem
                visible: opacity
                spacing: 0
                Behavior on opacity {
                    NumberAnimation { duration: 750 }
                }
                PrevButton {
                    Layout.preferredHeight: root.height * .9
                }
                PlayPauseButton {
                    Layout.preferredHeight: root.height
                }
                StopButton {
                    Layout.preferredHeight: root.height * .9
                }
                NextButton {
                    Layout.preferredHeight: root.height * .9
                }
            }
        }
    }

    Component.onCompleted: {
        if (mcws.isConnected) {
            reset(-1)
        }
        // bit of a hack to deal with the dynamic loader as form factor changes vs. plasmoid startup
        // event-queue the connection-enable on startup
        event.queueCall(500, function(){ conn.enabled = true })
    }
}
