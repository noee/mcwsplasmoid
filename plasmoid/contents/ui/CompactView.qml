import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import QtGraphicalEffects 1.0
import "controls"

Item {
    id: root
    anchors.fill: parent

    property int txtMaxSize: (width / mcws.zoneModel.count) * multi
    property int pixSize: root.height * 0.2
    property real multi: (pixSize > theme.mSize(theme.defaultFont).width * 1.5)
                            ? (pixSize / theme.mSize(theme.defaultFont).width)
                            : 1

    function reset(zonendx) {
        lvCompact.model = null
        event.queueCall(300, function()
        {
            lvCompact.model = mcws.zoneModel
            if (zonendx === -1)
                zonendx = mcws.getPlayingZoneIndex()
            lvCompact.positionViewAtIndex(zonendx, ListView.End)
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
        layoutDirection: Qt.RightToLeft

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
                if (lvCompact.hoveredInto === ndx)
                    lvCompact.currentIndex = ndx
            })
        }

        function itemSize(len) {
            var base = .65 * multi * len * theme.mSize(theme.defaultFont).width
            return len < 15
                    ? base
                    : Math.min(base, txtMaxSize * .8)

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
            spacing: 1
            Layout.alignment: Qt.AlignVCenter
            // spacer
            Rectangle {
                Layout.rightMargin: 3
                Layout.leftMargin: 3
                Layout.alignment: Qt.AlignCenter
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

                Layout.rightMargin: 3
                width: units.gridUnit * (plasmoid.configuration.useImageIndicator ? 1.75 : .5)
                height: width
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
                spacing: 0

                Marquee {
                    id: mq
                    text: +playingnowtracks > 0 ? name : zonename
                    fontSize: pixSize
                    Layout.maximumWidth: txtMaxSize
                    Layout.fillWidth: true
                    padding: 0
                    elide: Text.ElideRight

                    onTextChanged: {
                        event.queueCall(750, function(){
                            implicitWidth = Math.max(contentWidth
                                                     , lvCompact.itemSize(text.length)
                                                     , t2.implicitWidth)

                            if (model.state === mcws.statePlaying) {
                                mq.restart()
                            }
                        })
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
                    fontSize: pixSize * .8
                    Layout.fillWidth: true
                    Layout.maximumWidth: txtMaxSize
                    padding: 0
                    elide: Text.ElideRight

                    onTextChanged: {
                        implicitWidth = contentWidth > 0 ? contentWidth : lvCompact.itemSize(text.length)
                    }

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
            PrevButton {
                Layout.leftMargin: 3
                opacity: compactDel.ListView.isCurrentItem
                visible: opacity
                Layout.fillHeight: true
                Layout.maximumHeight: parent.height
                Behavior on opacity {
                    NumberAnimation { duration: 750 }
                }
            }
            PlayPauseButton {
                opacity: compactDel.ListView.isCurrentItem
                visible: opacity
                Layout.fillHeight: true
                Layout.maximumHeight: parent.height
                Behavior on opacity {
                    NumberAnimation { duration: 750 }
                }
            }
            StopButton {
                opacity: compactDel.ListView.isCurrentItem
                visible: plasmoid.configuration.showStopButton && opacity
                Layout.fillHeight: true
                Layout.maximumHeight: parent.height
                Behavior on opacity {
                    NumberAnimation { duration: 750 }
                }
            }
            NextButton {
                opacity: compactDel.ListView.isCurrentItem
                visible: opacity
                Layout.fillHeight: true
                Layout.maximumHeight: parent.height
                Behavior on opacity {
                    NumberAnimation { duration: 750 }
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
