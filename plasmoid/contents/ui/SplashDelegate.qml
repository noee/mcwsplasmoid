import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.12
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.extras 2.0 as Extras
import QtQuick.Window 2.12

import 'controls'

// Opacity graphical effects do not work on Windows
// so use a rectangle.  Allows for nice animations too.
Rectangle {
    id: root

    // init to zero for the fade in
    opacity: 0
    color: 'transparent'

    height: infoRow.height //splashimg.implicitHeight
//                    + PlasmaCore.Units.largeSpacing
    width: infoRow.width //Math.round(splashimg.width * 3.5)

    anchors.horizontalCenter: splashmode && !animate
                              ? parent.horizontalCenter
                              : undefined
    anchors.verticalCenter: splashmode && !animate
                            ? parent.verticalCenter
                            : undefined

    property alias splashimg: splashimg

    property int fadeInDuration: 1000
    property int fadeOutDuration: 1000
    property real opacityTo: 0.85

    signal splashDone()
    signal animationPaused()

    BackgroundHue {
        source: splashimg
        anchors.fill: parent
    }

    Component.onCompleted: {
        if (splashmode) {
            if (fullscreen || !animate)
                fadeOnly.start()
            else
                if (animate)
                    moveAnimate.start()
        }
        else {
            if (animate)
                moveAnimate.start()
            else {
                x = randW(); y = randH()
                fadeOnly.start()
            }
        }
    }

    RowLayout {
        id: infoRow

        ShadowImage {
            id: splashimg
            animateLoad: false
            thumbnail: false
            shadow.size: PlasmaCore.Units.largeSpacing*2
            sourceKey: filekey
            sourceSize: Qt.size(
                Math.max(thumbsize, fullscreen
                         ? Math.round(Screen.height/4)
                         : (screensaver ? 224 : 128))
              , Math.max(thumbsize, fullscreen
                         ? Math.round(Screen.height/4)
                         : (screensaver ? 224 : 128))
            )
        }

        ColumnLayout {
            id: infoColumn
            Layout.preferredHeight: splashimg.height + PlasmaCore.Units.largeSpacing
            Layout.preferredWidth: Math.round(splashimg.width * 3) + PlasmaCore.Units.largeSpacing

            Extras.DescriptiveLabel {
                text: title
                Layout.fillWidth: true
                enabled: false
                elide: Text.ElideRight
                font.pointSize: fullscreen | screensaver
                                ? Math.round(PlasmaCore.Theme.defaultFont.pointSize * 2.8)
                                : PlasmaCore.Theme.defaultFont.pointSize + 4
            }

            Extras.DescriptiveLabel {
                text: info1
                Layout.fillWidth: true
                Layout.fillHeight: true
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                Layout.maximumWidth: infoColumn.width
                font.pointSize: fullscreen | screensaver
                                ? Math.round(PlasmaCore.Theme.defaultFont.pointSize * 2.5)
                                : PlasmaCore.Theme.defaultFont.pointSize + 2
            }

            Extras.DescriptiveLabel {
                text: info2
                Layout.fillWidth: true
                Layout.maximumWidth: infoColumn.width
                elide: Text.ElideRight
                font.pointSize: fullscreen | screensaver
                                ? PlasmaCore.Theme.defaultFont.pointSize * 2
                                : PlasmaCore.Theme.defaultFont.pointSize
            }
        }
    }

    property int dur: 10000

    property int xFrom: randW()
    property int xTo:   randW()
    property int yFrom: randH()
    property int yTo:   randH()

    function randW(n) {
        n = n === undefined ? Screen.width - root.width: n
        return Math.floor(Math.random() * Math.floor(n))
    }

    function randH(n) {
        n = n === undefined ? Screen.height - root.height : n
        return Math.floor(Math.random() * Math.floor(n))
    }

    function fadeOut() {
        fadeOutAnimation.start()
    }

    SequentialAnimation {
        id: moveAnimate

        ParallelAnimation {
            OpacityAnimator {
                target: root
                from: 0
                to: opacityTo
                duration: fadeInDuration
            }
            XAnimator {
                id: xAnim
                target: root
                from: xFrom
                to: xTo
                duration: dur/2
                easing.type: Easing.OutExpo
            }
            YAnimator {
                id: yAnim
                target: root
                from: yFrom
                to: yTo
                duration: dur
                easing.type: Easing.InOutQuad
            }
        }

        PauseAnimation { duration: 200 }

        OpacityAnimator {
            target: root
            from: opacityTo
            to: 0
            duration: fadeOutDuration
        }

        property bool toggle: false
        onStopped: {
            if (splashmode) {
                root.splashDone()
            } else {
                animationPaused()
                event.queueCall(1000, () => {
                   toggle = !toggle
                   xAnim.duration = toggle ? dur : dur/2
                   yAnim.duration = toggle ? dur/2 : dur
                   xAnim.easing.type = toggle ? Easing.InOutQuad : Easing.OutExpo
                   yAnim.easing.type = toggle ? Easing.OutExpo : Easing.InOutQuad

                   root.xFrom = root.x
                   root.xTo = randW(xFrom > randW()
                                    ? Screen.width/2 : undefined)

                   root.yFrom = root.y
                   root.yTo = randH(yFrom > randH()
                                    ? Screen.height/2 : undefined)
                   moveAnimate.start()
                })
            }
        }
    }

    SequentialAnimation {
        id: fadeOnly

        OpacityAnimator {
            target: root
            from: 0; to: opacityTo
            duration: fadeInDuration
        }

        PauseAnimation {
            id: fadeOnlyPause
            duration: splashmode ? model.duration : dur
        }

        OpacityAnimator {
            target: root
            from: opacityTo; to: 0
            duration: fadeOutDuration*2
        }

        onStopped: {
            if (splashmode) {
                root.splashDone()
            } else {
                animationPaused()
                event.queueCall(1000, () => {
                    root.x = randW()
                    root.y = randH()
                    fadeOnly.start()
                })
            }
        }
    }

    OpacityAnimator {
        id: fadeOutAnimation
        target: root
        from: opacityTo; to: 0
        duration: fadeOutDuration
    }

}
