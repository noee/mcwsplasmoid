import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.12
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.extras 2.0 as Extras

import 'controls'

Rectangle {
    id: root

    property int fadeInDuration: 1000
    property int fadeOutDuration: 1000
    property real opacityTo: 0.85

    property var params

    property alias splashimg: splashimg

    // init to zero for the fade in
    opacity: 0
    color: 'transparent'

    signal finished()

    function fadeIn() {
        fadeInAnimate.start()
    }

    function stop() {
        fadeOut.start()
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
            sourceKey: params.filekey
            sourceSize: Qt.size(
                Math.max(thumbSize, fullscreen
                         ? Math.round(parent.height/1.5)
                         : 128)
              , Math.max(thumbSize, fullscreen
                         ? Math.round(parent.height/1.5)
                         : 128)
            )
        }

        ColumnLayout {
            spacing: 0
            Layout.preferredHeight: splashimg.height + PlasmaCore.Units.largeSpacing

            Extras.DescriptiveLabel {
                text: params.title
                Layout.fillWidth: true
                enabled: false
                elide: Text.ElideRight
                font.pointSize: fullscreen
                                ? Math.round(PlasmaCore.Theme.defaultFont.pointSize * 2.8)
                                : PlasmaCore.Theme.defaultFont.pointSize + 4
            }

            Extras.DescriptiveLabel {
                text: params.info1
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                font.pointSize: fullscreen
                                ? Math.round(PlasmaCore.Theme.defaultFont.pointSize * 2.5)
                                : PlasmaCore.Theme.defaultFont.pointSize + 2
            }

            Extras.DescriptiveLabel {
                text: params.info2
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                font.pointSize: fullscreen
                                ? PlasmaCore.Theme.defaultFont.pointSize * 2
                                : PlasmaCore.Theme.defaultFont.pointSize - 1
            }
        }
    }

    // Fade in, then wait, then fade out and notify done
    OpacityAnimator {
        id: fadeInAnimate
        target: root
        to: opacityTo
        duration: fadeInDuration
        onStopped: event.queueCall(params.duration, fadeOut.start)
    }

    // fade out then notify splash is finished
    OpacityAnimator {
        id: fadeOut
        target: root
        from: opacityTo
        to: 0
        duration: fadeOutDuration
        onStopped: finished()
    }

}
