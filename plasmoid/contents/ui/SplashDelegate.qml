import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.12
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.extras 2.0 as Extras
import QtQuick.Window 2.12

import 'controls'
import 'helpers/utils.js' as Utils

// Opacity graphical effects do not work on Windows
// so use a rectangle.  Allows for nice animations too.
Rectangle {
    id: root

    color: 'transparent'

    height: infoRow.height
    width: infoRow.width

    anchors.horizontalCenter: splashmode && !animate
                              ? parent.horizontalCenter
                              : undefined
    anchors.verticalCenter: splashmode && !animate
                            ? parent.verticalCenter
                            : undefined

    property alias splashimg: splashimg

    property int fadeInDuration: 1000
    property int fadeOutDuration: 1000
    property real opacityTo: 0.9

    property int dur: Math.min(fadeInDuration, fadeOutDuration) * 10

    property int areaWidth: Screen.width
    property int areaHeight: Screen.height

    property int xFrom: Math.round(areaWidth/2)
    property int xTo:   randW()
    property int yFrom: Math.round(areaHeight/2)
    property int yTo:   randH()

    // callback from viewer to update the model
    property var dataSetter
    function setDataPending(info) {
        d.modelItem = info
        d.dataPending = true
    }

    function randW(n) {
        n = n === undefined ? areaWidth - root.width: n
        return Math.floor(Math.random() * Math.floor(n))
    }

    function randH(n) {
        n = n === undefined ? areaHeight - root.height : n
        return Math.floor(Math.random() * Math.floor(n))
    }

    function fadeOut() {
        fadeOutAnimation.start()
    }

    function go() {
        if (splashmode) {
            if (fullscreen || !animate)
                fadeOnly.start()
            else
                if (animate)
                    moveAnimate.start()
        }
        else {
            if (animate) {
                root.opacity = root.opacityTo
                moveAnimate.start()
            }
            else {
                x = randW(areaWidth/2); y = randH(areaHeight/2)
                fadeOnly.start()
            }
        }
    }

    function reset(info) {
        d.resetting = true
        d.ssFlags = info
    }

    signal splashDone()
    signal animationPaused()

    Component.onCompleted: go()

    // d Ptr
    QtObject {
        id: d

        property var ssFlags
        property var modelItem
        property bool dataPending: false
        property bool resetting: false

        function checkForPendingData(useAni) {
            if (dataPending) {
                if (useAni === undefined ? false : useAni) {
                    dataSetterAnimation.start()
                } else {
                    dataUpdate()
                }
            }
        }

        function dataUpdate() {
            if (Utils.isFunction(dataSetter))
                dataSetter(modelItem)
            dataPending = false
        }

        function checkForReset(fade) {
            if (resetting) {
                if (fade) fadeOut()
                dataSetter(ssFlags)
                event.queueCall(fadeOutDuration+500, go)
                resetting = false
                return true
            }

            return false
        }
    }

    BackgroundHue {
        source: splashimg
        anchors.fill: parent
        opacity: 0.65
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
                         ? Math.round(areaHeight/4)
                         : (screensaver ? 224 : 128))
              , Math.max(thumbsize, fullscreen
                         ? Math.round(areaHeight/4)
                         : (screensaver ? 224 : 128))
            )
        }

        ColumnLayout {
            id: infoColumn
            spacing: 0
            Layout.preferredHeight: splashimg.height + PlasmaCore.Units.largeSpacing
            Layout.preferredWidth: Math.round(splashimg.width * 2.5) + PlasmaCore.Units.largeSpacing

            Extras.DescriptiveLabel {
                text: title
                Layout.fillWidth: true
                Layout.maximumWidth: infoColumn.width
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

            Extras.DescriptiveLabel {
                text: info3
                Layout.fillWidth: true
                Layout.maximumWidth: infoColumn.width
                elide: Text.ElideRight
                font.pointSize: fullscreen | screensaver
                                ? PlasmaCore.Theme.defaultFont.pointSize*2 -4
                                : PlasmaCore.Theme.defaultFont.pointSize -1
            }
        }
    }

    SequentialAnimation {
        id: moveAnimate

        ParallelAnimation {
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

        onStopped: {
            if (splashmode) {
                fadeOut()
                event.queueCall(fadeOutDuration, root.splashDone)
            } else {
                // if ani flags have changed
                if (d.checkForReset(true)) return

                // tell the view were at a pause state
                animationPaused()

                // handle pending data updates
                d.checkForPendingData(true)

                // reset the animation
                event.queueCall(d.dataPending
                                ? fadeInDuration+fadeOutDuration
                                : 100,
                   () => {
                       let toggle = randW(areaWidth) >= Math.floor(areaWidth/2)
                       xAnim.duration = toggle ? dur : dur/2
                       yAnim.duration = toggle ? dur/2 : dur
                       xAnim.easing.type = toggle ? Easing.InOutQuad : Easing.OutExpo
                       yAnim.easing.type = toggle ? Easing.OutExpo : Easing.InOutQuad

                       xFrom = root.x
                       xTo = randW(xFrom > randW()
                                        ? areaWidth/2 : undefined)

                       yFrom = root.y
                       yTo = randH(yFrom > randH()
                                        ? areaHeight/2 : undefined)

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
                // if ani flags have changed
                if (d.checkForReset()) return

                // notify the ani is paused
                animationPaused()

                // handle pending data
                d.checkForPendingData()

                // reset the pos, start again
                event.queueCall(1000, () => {
                    root.x = randW()
                    root.y = randH()
                    fadeOnly.start()
                })
            }
        }
    }

    // fade out/set data/fade in
    SequentialAnimation {
        id: dataSetterAnimation

        OpacityAnimator {
            target: root
            from: opacityTo; to: 0
            duration: fadeOutDuration
        }

        ScriptAction { script: { d.dataUpdate() } }

        OpacityAnimator {
            target: root
            from: 0; to: opacityTo
            duration: fadeInDuration
        }
    }

    OpacityAnimator {
        id: fadeOutAnimation
        target: root
        from: opacityTo; to: 0
        duration: fadeOutDuration
    }

}
