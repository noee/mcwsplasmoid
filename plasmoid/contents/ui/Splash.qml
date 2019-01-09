import QtQuick 2.12
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import QtQuick.Window 2.12
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.4 as Kirigami
import 'helpers'
import 'controls'

Item {
    id: root
    property bool animate: false
    property bool fancyAnimate: true
    property bool debug: false
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

            Component.onDestruction: {
                if (debug)
                    console.log('Splasher Destroyed: ' + strList[0])
            }

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

                            if (debug) {
                                console.log('DesktopW/H: %1/%2'.arg(Screen.desktopAvailableWidth).arg(Screen.desktopAvailableHeight))
                                var scrs = Qt.application.screens
                                for (var i=0, len=scrs.length; i<len; ++i) {
                                    console.log('Screen[%4] %1 is at X/Y: %2/%3'.arg(scrs[i].name)
                                                .arg(scrs[i].virtualX).arg(scrs[i].virtualY).arg(i))

                                }
                                console.log('Chosen Screen (%1) is at X/Y: %2/%3'.arg(Screen.name).arg(Screen.virtualX).arg(Screen.virtualY))
                                console.log("Constructed SPLASH WindowX/Y: %1/%2".arg(trackSplash.x).arg(trackSplash.y))
                                console.log("Starting SPLASH WindowX/Y at: %1/%2: DestX/Y: %3/%4"
                                            .arg(trackSplash.x).arg(trackSplash.y).arg(trackSplash.destX).arg(trackSplash.destY))
                            }

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
                    onFinished: event.queueCall(root.duration/2, fadeOut.start)
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
                    onFinished: event.queueCall(root.duration/2, fadeOut.start)
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
                    onFinished: event.queueCall(root.duration/2, fadeOut.start)
                }
            }

            PropertyAnimation {
                id: fadeOut
                target: trackSplash
                property: 'opacity'
                to: 0
                duration: root.fadeOut
                onFinished: done(trackSplash.strList[0])
            }
        }
    }
}


