import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import QtQuick.Window 2.11
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.4 as Kirigami
import 'helpers/utils.js' as Utils
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

    signal start(string filekey)
    signal finished(string filekey)

    /* track = {filekey, title, info1, info2} */
    function show(track) {
        var defTrack = {filekey: '-1', title: '<no title>', info1: '<no track name>', info2: '<no album/artist>'}
        if (!Utils.isObject(track))
            track = Object.assign({}, defTrack)
        else
            track = Object.assign(defTrack, track)

        splashRunner.createObject(parent, { params: track })
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
            color: Kirigami.Theme.backgroundColor
            flags: Qt.Popup
            opacity: 0

            property var params
            property int destX
            property int destY

            Component.onCompleted: {
                // delay for image to load (sets height)
                event.queueCall(200,
                                () => {
                                    root.start(params.filekey)
                                    visible = true

                                    width = splashimg.implicitWidth
                                            + Math.max(splashtitle.width, txt1.width, txt2.width)
                                            + Kirigami.Units.largeSpacing
                                    height = splashimg.implicitHeight + Kirigami.Units.smallSpacing

                                    x = Screen.virtualX + Screen.width - width
                                    y = Screen.virtualY + Screen.height - height

                                    destX = Screen.virtualX + Screen.width/3
                                    destY = Screen.virtualY + Screen.height/2

                                    // show the splash
                                    return root.animate
                                              ? (root.fancyAnimate
                                                    ? fancyAnimate.createObject(root)
                                                    : simpleAnimate.createObject(root))
                                              : fadeAnimate.createObject(root)

                                })

            }
            Component.onDestruction: root.finished(params.filekey)

            SingleShot { id: event }

            RowLayout {
                width: parent.width
                height: parent.height
                Layout.alignment: Qt.AlignVCenter

                TrackImage {
                    id: splashimg
                    animateLoad: false
                    sourceKey: trackSplash.params.filekey
                    sourceSize.height: Math.max(thumbSize, 84)
                }

                ColumnLayout {
                    spacing: 0
                    Kirigami.Heading {
                        id: splashtitle
                        text: trackSplash.params.title
                        level: 2
                        font.italic: true
                        Layout.alignment: Qt.AlignRight
                        Layout.fillHeight: true
                    }
                    Kirigami.Heading {
                        id: txt1
                        text: trackSplash.params.info1
                        level: 3
                        font.italic: true
                        Layout.topMargin: 10
                    }
                    Label {
                        id: txt2
                        text: trackSplash.params.info2
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

            // the ending to all animations, destroy splasher
            PropertyAnimation {
                id: fadeOut
                target: trackSplash
                property: 'opacity'
                to: 0
                duration: root.fadeOut
                onRunningChanged: if (!running) trackSplash.destroy()
            }
        }
    }
}


