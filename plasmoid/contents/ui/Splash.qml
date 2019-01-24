import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import QtQuick.Window 2.11
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.4 as Kirigami
import 'helpers'
import 'controls'

Item {
    id: root
    property bool animate: false
    property bool fancyAnimate: true
    property int duration: 6000
    property int fadeIn: 1000
    property int fadeOut: 1000
    property int speed: 150

    opacity: .85

    signal finished(string filekey)

    /* strList = [key, title, trackinfo1, trackinfo2] */
    function show(strList) {
        if (typeof strList !== 'object')
            strList = ['-1', '<no title>', '<no track name>', '<no album/artist>']

        var l = 4 - strList.length
        while (l) {
            strList.push('<no string>')
            --l
        }

        var splash = splashRunner.createObject(parent, { strList: strList })
        splash.done.connect(function(filekey) {
            splash.destroy()
            finished(filekey)
        })
        return splash
    }

    Component {
        id: splashRunner
        /*
          Setting visible or pos (x/y) causes QT to set screen too early.

          Don't set visible true until ready for animation, forces QT to pick proper
          screen.  Does not work reliably on Wayland.
          */
        Window {
            id: trackSplash
            color: theme.backgroundColor
            flags: Qt.Popup
            opacity: 0
            height: splashimg.implicitHeight
            width: 250

            property var strList
            property int destX
            property int destY

            signal done(string filekey)

            SingleShot { id: event }

            RowLayout {
                width: parent.width
                height: parent.height
                Layout.alignment: Qt.AlignVCenter

                TrackImage {
                    id: splashimg
                    animateLoad: false
                    layer.enabled: false
                    sourceKey: trackSplash.strList[0]
                    sourceSize.height: Math.max(thumbSize, 84)
                    onStatusChanged: {
                        if (splashimg.status === Image.Ready)
                        {
                            trackSplash.visible = true

                            trackSplash.width = splashimg.implicitWidth
                                    + Math.max(splashtitle.width, txt1.width, txt2.width)
                                    + 10
                            trackSplash.x = Screen.virtualX + Screen.width - trackSplash.width
                            trackSplash.y = Screen.virtualY + Screen.height - trackSplash.height

                            trackSplash.destX = Screen.virtualX + Screen.width/3
                            trackSplash.destY = Screen.virtualY + Screen.height/2

                            // show the splash
                            return root.animate
                                      ? (root.fancyAnimate
                                            ? fancyAnimate.createObject(root)
                                            : simpleAnimate.createObject(root))
                                      : fadeAnimate.createObject(root)

                        }
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Kirigami.Heading {
                        id: splashtitle
                        text: trackSplash.strList[1]
                        level: 2
                        color: theme.highlightColor
                        font.italic: true
                        Layout.alignment: Qt.AlignRight
                        Layout.fillHeight: true
                    }
                    Kirigami.Heading {
                        id: txt1
                        text: trackSplash.strList[2]
                        level: 3
                        font.italic: true
                        Layout.topMargin: 10
                    }
                    Label {
                        id: txt2
                        text: trackSplash.strList[3]
                    }
                }
            }

            Component {
                id: simpleAnimate
                ParallelAnimation {
                    running: true
                    PropertyAnimation {
                        target: trackSplash
                        property: 'opacity'
                        duration: root.fadeIn
                        to: root.opacity
                    }
                    SmoothedAnimation {
                        easing.type: Easing.InOutQuad
                        target: trackSplash
                        property: 'x'
                        to: trackSplash.destX
                        velocity: root.speed
                    }
                    onRunningChanged: if (!running) event.queueCall(root.duration/2, fadeOut.start)
                }
            }

            Component {
                id: fancyAnimate
                ParallelAnimation {
                    running: true
                    PropertyAnimation {
                        target: trackSplash
                        property: 'opacity'
                        duration: root.fadeIn
                        to: root.opacity
                    }
                    SmoothedAnimation {
                        id: xAn
                        easing.type: Easing.InOutQuad
                        target: trackSplash
                        property: 'x'
                        to: trackSplash.destX
                        velocity: root.speed
                    }
                    SmoothedAnimation {
                        id: yAn
                        easing.type: Easing.InOutQuad
                        target: trackSplash
                        property: 'y'
                        to: trackSplash.destY
                        velocity: root.speed
                    }
                    onRunningChanged: if (!running) event.queueCall(root.duration/2, fadeOut.start)
                }
            }

            Component {
                id: fadeAnimate
                PropertyAnimation {
                    running: true
                    target: trackSplash
                    property: 'opacity'
                    to: root.opacity
                    duration: root.fadeIn
                    onRunningChanged: if (!running) event.queueCall(root.duration/2, fadeOut.start)
                }
            }

            PropertyAnimation {
                id: fadeOut
                target: trackSplash
                property: 'opacity'
                to: 0
                duration: root.fadeOut
                onRunningChanged: if (!running) done(trackSplash.strList[0])
            }
        }
    }
}


