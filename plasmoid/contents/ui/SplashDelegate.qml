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
    height: splashimg.implicitHeight
                    + PlasmaCore.Units.largeSpacing
    width: Math.round(splashimg.width * 4)

    property alias splashimg: splashimg

    property bool animate: false

    property int fadeInDuration: 1000
    property int fadeOutDuration: 1000
    property real opacityTo: 0.85

    signal fadeInDone()
    signal fadeOutDone()
    signal readyForData()

    BackgroundHue {
        source: splashimg
        anchors.fill: parent
    }

    function fadeIn() {
        fadeInAnimate.start()
    }

    function fadeOut() {
        fadeOutAnimate.start()
    }

    Component.onCompleted: {
        if (animate)
            moveAnimate.start()
        else
            fadeIn()
        logger.warn('splasher::create', splashers.get(index))
    }

    Component.onDestruction: {
        logger.warn('splasher::destroy')
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: fullscreen
                         ? PlasmaCore.Units.largeSpacing * 3
                         : PlasmaCore.Units.smallSpacing

        ShadowImage {
            id: splashimg
            animateLoad: false
            thumbnail: false
            shadow.size: PlasmaCore.Units.largeSpacing*2
            sourceKey: filekey
            sourceSize: Qt.size(
                Math.max(thumbSize, fullscreen
                         ? Math.round(win.height/1.5)
                         : (screenSaver ? 224 : 128))
              , Math.max(thumbSize, fullscreen
                         ? Math.round(win.height/1.5)
                         : (screenSaver ? 224 : 128))
            )
        }

        ColumnLayout {
            spacing: 0
            Layout.preferredHeight: splashimg.height + PlasmaCore.Units.largeSpacing

            Extras.DescriptiveLabel {
                text: title
                Layout.fillWidth: true
                enabled: false
                elide: Text.ElideRight
                font.pointSize: fullscreen | screenSaver
                                ? Math.round(PlasmaCore.Theme.defaultFont.pointSize * 2.8)
                                : PlasmaCore.Theme.defaultFont.pointSize + 4
            }

            Extras.DescriptiveLabel {
                text: info1
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                font.pointSize: fullscreen | screenSaver
                                ? Math.round(PlasmaCore.Theme.defaultFont.pointSize * 2.5)
                                : PlasmaCore.Theme.defaultFont.pointSize + 2
            }

            Extras.DescriptiveLabel {
                text: info2
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                font.pointSize: fullscreen | screenSaver
                                ? PlasmaCore.Theme.defaultFont.pointSize * 2
                                : PlasmaCore.Theme.defaultFont.pointSize - 1
            }
        }
    }

    property int dur: 10000
    property int xB: Screen.width - (root.width)
    property int yB: Screen.height - (root.height)

    property int xFrom: randW()
    property int xTo:   randW()
    property int yFrom: randH()
    property int yTo:   randH()

    function randW() {
        let ret = Math.floor(Math.random() * Math.floor(Screen.width))
        return ret > xB ? Screen.width - xB : ret
    }
    function randH(n) {
        let ret = Math.floor(Math.random() * Math.floor(Screen.height))
        return ret > yB ? Screen.height - yB : ret
    }

    SequentialAnimation {
        id: moveAnimate
        loops: 1

        ParallelAnimation {
            OpacityAnimator {
                target: root
                from: 0
                to: opacityTo
                duration: fadeInDuration
            }
            XAnimator {
                target: root
                from: xFrom
                to: xTo
                duration: dur
                easing.type: Easing.OutExpo
            }
            YAnimator {
                target: root
                from: yFrom
                to: yTo
                duration: dur
                easing.type: Easing.InOutQuad
            }
        }

        PauseAnimation { duration: 500 }

        OpacityAnimator {
            target: root
            from: opacityTo
            to: 0
            duration: fadeOutDuration
        }

        onStopped: {
            readyForData()
            event.queueCall(1000, () => {
               root.xFrom = randW()
               root.xTo = randW()
               root.yFrom = randH()
               root.yTo = randH()
               root.x = root.xFrom
               root.y = root.yFrom

               moveAnimate.start()
           })
        }
    }

    OpacityAnimator {
        id: fadeInAnimate
        target: root
        from: 0; to: opacityTo
        duration: fadeInDuration
        onStopped: root.fadeInDone()
    }

    OpacityAnimator {
        id: fadeOutAnimate
        target: root
        from: opacityTo; to: 0
        duration: fadeOutDuration
        onStopped: root.fadeOutDone()
    }
}
