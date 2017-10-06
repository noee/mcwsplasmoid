import QtQuick 2.8
import QtQuick.Layouts 1.0
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0

Window {
    id: trackSplash
    width: splashimg.width*4 + 100
    height: splashimg.height + 50
    color: "black"
    flags: Qt.Popup
    visible: true
    onWidthChanged:  {
        x = Screen.width - width
        y = Screen.height - height
    }

    signal splashDone

    property bool animate: false
    property int duration: 7000

    function start(player, imgstr)
    {
        splashtitle.text = "Now Playing on " + player.zonename

        splashimg.statusChanged.connect(function() {
                if (splashimg.status === Image.Error) {
                    splashimg.source = "default.png"
                }
            })
        splashimg.source = imgstr

        txt1.text = "\"" + player.name + "\""
        txt2.text = "by " + player.artist
        txt3.text = "from " + player.album

        timer.interval = duration/2

        if (animate) {
            xyAnimation.duration = duration
            xyAnimation.start()
        }
        else {
            timer.interval += 1000
            timer.restart()
        }
    }

    RowLayout {
            anchors.centerIn: parent
            Image {
                id: splashimg
                Layout.alignment: Qt.AlignVCenter
                Layout.margins: 3
                sourceSize.height: 85
                sourceSize.width: 85
                scale: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 2
                    verticalOffset: 2
                    color: "#80000000"
                }
            }
            Column {
                spacing: 1
                Text {
                    id: splashtitle
                    font.pointSize: 12
                    font.italic: true
                    color: "grey"
                    anchors.right: parent.right
                }
                Text { width: 10; height: 15 }
                Text {
                    id: txt1
//                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    font.pointSize: 12
                    font.italic: true
                    width: trackSplash.width-splashimg.width-25
                    color: "grey"
                }
                Text {
                    id: txt2
                    color: "grey"
                }
                Text {
                    id: txt3
                    color: "grey"
                }
            }
    }

    NumberAnimation {
           id: xyAnimation
           target: trackSplash
           properties: "x,y"
           easing.type: Easing.OutQuad
           to: (Screen.width/2)-splashtitle.width
           onStopped: timer.restart()
    }
    PropertyAnimation {
        id: opAnimation
        target: trackSplash
        property: "opacity"
        to: 0
        onStopped: splashDone()
    }
    Timer {
        id: timer
        onTriggered: opAnimation.start()
    }
}
