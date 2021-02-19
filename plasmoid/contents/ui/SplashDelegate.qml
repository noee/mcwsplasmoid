import QtQuick 2.11
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as Comp

import 'controls'
import 'helpers/utils.js' as Utils

// Opacity graphical effects do not work on Windows
// so use a rectangle.  Allows for nice animations too.
Rectangle {
    id: root

    color: 'transparent'

    height: infoRow.height + PlasmaCore.Units.largeSpacing
    width: infoRow.width + PlasmaCore.Units.largeSpacing

    anchors.horizontalCenter: splashmode && !animate
                              ? parent.horizontalCenter
                              : undefined
    anchors.verticalCenter: splashmode && !animate
                            ? parent.verticalCenter
                            : undefined

    property alias splashimg: splashimg

    property int fadeInDuration: 1500
    property int fadeOutDuration: 1500
    property real opacityTo: 0.9

    property int dur: Math.min(fadeInDuration, fadeOutDuration) * 10

    // Available area for the panel to exist
    property size availableArea: Qt.size(parent.width, parent.height)

    property int xFrom: Math.round(availableArea.width/2)
    property int xTo:   d.randW()
    property int yFrom: Math.round(availableArea.height/2)
    property int yTo:   d.randH()

    // callback from viewer to update the model
    property var dataSetter
    function setDataPending(info) {
        d.modelItem = info
        if (animate)
            dataSetterAnimation.start()
    }

    function go() {
        if (splashmode) {
            if (fullscreen || !animate)
                fadeInOut.start()
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
                x = d.randW()
                y = d.randH()
                fadeInOut.start()
            }
        }
    }

    function stop() {
        fadeOutAnimation.start()
        d.exiting = true
    }

    function reset(info) {
        d.ssFlags = info
    }

    signal splashDone()

    Component.onCompleted: go()

    // private
    QtObject {
        id: d

        // object with values means "reset"
        property var ssFlags
        // object with values means "data pending"
        property var modelItem
        // exit pending for the splash
        property bool exiting: false

        function randW(n) {
            n = n === undefined
                    ? availableArea.width - Math.ceil(root.width/3)
                    : n
            return Math.floor(Math.random() * Math.floor(n))
        }

        function randH(n) {
            n = n === undefined
                    ? availableArea.height - Math.ceil(root.height/2)
                    : n
            return Math.floor(Math.random() * Math.floor(n))
        }

        function pendingDataUpdate() {
            if (modelItem && Utils.isFunction(dataSetter))
                dataSetter(modelItem)
            modelItem = undefined
        }

        function checkForReset(fade) {
            if (ssFlags) {
                let setter = () => {
                    dataSetter(ssFlags)
                    ssFlags = undefined
                    go()
                }
                if (fade) {
                    fadeOutAnimation.start()
                    event.queueCall(fadeOutDuration+1000, setter)
                } else {
                    setter()
                }
                return true
            }

            return false
        }
    }

    BackgroundHue {
        source: !transparent ? splashimg : null
        anchors.fill: !transparent ? parent : undefined
        opacity: !transparent ? 0.65 : 0
    }

    RowLayout {
        id: infoRow
        spacing: PlasmaCore.Units.smallSpacing*2
        anchors.horizontalCenter: root.horizontalCenter
        anchors.verticalCenter: root.verticalCenter

        ShadowImage {
            id: splashimg
            animateLoad: false
            thumbnail: false
            shadow.size: PlasmaCore.Units.largeSpacing*2
            sourceKey: filekey
            sourceSize: Qt.size(
                Math.max(thumbsize, fullscreen
                         ? Math.round(availableArea.height/4)
                         : (screensaver ? 224 : 128))
              , Math.max(thumbsize, fullscreen
                         ? Math.round(availableArea.height/4)
                         : (screensaver ? 224 : 128))
            )
        }

        ColumnLayout {
            id: infoColumn
            spacing: 0
            Layout.preferredHeight: splashimg.height + PlasmaCore.Units.largeSpacing
            Layout.preferredWidth: Math.round(splashimg.width * 2.5) + PlasmaCore.Units.largeSpacing

            Comp.Label {
                text: title
                Layout.fillWidth: true
                Layout.maximumWidth: infoColumn.width
                enabled: !transparent
                elide: Text.ElideRight
                font.pointSize: fullscreen | screensaver
                                ? Math.round(PlasmaCore.Theme.defaultFont.pointSize * 2)
                                : PlasmaCore.Theme.defaultFont.pointSize + 2
            }

            Comp.Label {
                text: info1
                Layout.fillWidth: true
                enabled: !transparent
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                Layout.maximumWidth: infoColumn.width
                font.pointSize: fullscreen | screensaver
                                ? Math.round(PlasmaCore.Theme.defaultFont.pointSize * 1.5)
                                : PlasmaCore.Theme.defaultFont.pointSize + 1
            }

            Comp.Label {
                text: info2
                Layout.fillWidth: true
                Layout.maximumWidth: infoColumn.width
                enabled: !transparent
                elide: Text.ElideRight
                font.pointSize: fullscreen | screensaver
                                ? Math.round(PlasmaCore.Theme.defaultFont.pointSize * 1.2)
                                : PlasmaCore.Theme.defaultFont.pointSize
            }

            Comp.Label {
                text: info3
                Layout.fillWidth: true
                Layout.maximumWidth: infoColumn.width
                enabled: !transparent
                elide: Text.ElideRight
                font.pointSize: PlasmaCore.Theme.defaultFont.pointSize
            }
        }
    }

    // Move the panels around randomly
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
                fadeOutAnimation.start()
                event.queueCall(fadeOutDuration+500, root.splashDone)
            } else {
                // SS is cancelled
                if (d.exiting) return

                // if ani flags have changed
                if (d.checkForReset(true)) return

                // reset the animation
                event.queueCall(100, () => {
                    let toggle = d.randW(availableArea.width) >= Math.floor(availableArea.width/2)
                    xAnim.duration = toggle ? dur : dur/2
                    yAnim.duration = toggle ? dur/2 : dur
                    xAnim.easing.type = toggle ? Easing.InOutQuad : Easing.OutExpo
                    yAnim.easing.type = toggle ? Easing.OutExpo : Easing.InOutQuad

                    // randomize x pos
                    xFrom = root.x
                    if (toggle) {
                        xTo = xFrom >= availableArea.width/2
                              ? d.randW(availableArea.width/2)
                              : d.randW() + Math.round(root.width/2)
                    } else {
                        xTo = d.randW()
                    }

                    // randomize y pos
                    yFrom = root.y
                    if (toggle) {
                        yTo = yFrom >= availableArea.height/2
                              ? d.randH(availableArea.height/2)
                              : d.randH() + Math.round(root.height/2)
                    } else {
                        yTo = d.randH()
                    }

                    moveAnimate.start()
                })
            }
        }
    }

    // Fade in/out only
    SequentialAnimation {
        id: fadeInOut

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
            duration: fadeOutDuration
        }

        onStopped: {
            if (splashmode) {
                root.splashDone()
            } else {
                // SS is cancelled
                if (d.exiting) return

                // if ani flags have changed
                if (d.checkForReset()) return

                // handle pending data
                d.pendingDataUpdate()

                // reset the pos, start again
                event.queueCall(1000, () => {
                    root.x = d.randW()
                    root.y = d.randH()
                    fadeInOut.start()
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

        PauseAnimation {
            duration: 500
        }

        ScriptAction { script: { d.pendingDataUpdate() } }

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
