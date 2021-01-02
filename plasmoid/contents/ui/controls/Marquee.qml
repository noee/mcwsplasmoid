import QtQuick 2.8
import org.kde.plasma.core 2.1 as PlasmaCore

Item {
    id: root
    implicitWidth: parent.implicitWidth
    implicitHeight: marqueeText.implicitHeight + padding
    clip: true

    signal scrollDone()

    property alias fade: marqueeText.animate
    readonly property alias truncated: marqueeText.truncated
    readonly property alias scrolling: timer.running
    property alias contentWidth: marqueeText.contentWidth

    property string text
    property int padding : 5
    property int fontSize : 12
    property int interval : 70
    property color textColor: PlasmaCore.ColorScope.textColor
    property int loop: 1

    property int elide: Text.ElideNone
    property int align: Text.AlignRight

    property int __offset: 2

    function move() {
        // Text fits
        if (marqueeText.paintedWidth < root.width) {
            stop()
            return
        }
        // Text has scrolled to the end
        if (marqueeText.x + marqueeText.paintedWidth < 0) {
            if (++timer.loopCtr === loop) {
                stop()
            }
            else {
                marqueeText.x = root.width
                marqueeText.width = __offset
            }
            return
        }

        marqueeText.x -= __offset;
        marqueeText.width += __offset
    }

    function stop() {
        if (timer.running) {
            timer.stop()

            marqueeText.x = root.x
            marqueeText.width = root.width
            marqueeText.elide = root.elide
            marqueeText.horizontalAlignment = root.align

            if (root.fade) {
                marqueeText.fade()
            }

            scrollDone()
        }
    }

    function start() {
        if (!timer.running) {
            timer.start()
            marqueeText.elide = Text.ElideNone
            marqueeText.horizontalAlignment = undefined
            marqueeText.x = root.width
            marqueeText.width = __offset
        }
    }

    function restart() {
        if (timer.running)
            stop()

        start()
    }

    Timer {
        id: timer
        interval: root.interval
        onTriggered: root.move()
        repeat: true
        onRunningChanged: {
            if (!running)
                loopCtr = 0
        }

        property int loopCtr: 0
    }

    FadeText {
        id: marqueeText
        color: textColor
        width: root.width
        font.pointSize: fontSize
        clip: root.clip
        aText: root.text
        elide: root.elide
        horizontalAlignment: align
        anchors.verticalCenter: root.verticalCenter
    }
}
