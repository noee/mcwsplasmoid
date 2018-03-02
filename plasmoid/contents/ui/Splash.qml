import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    property bool animate: false
    property int duration: 7000

    function go(player, imgstr) {
        if (player.state === mcws.statePlaying) {
            var splash = splashRunner.createObject(null)
            splash.splashDone.connect(function(){ splash.destroy()})
            splash.start(player, imgstr, animate, duration)
        }
    }

    Component {
        id: splashRunner
        Window {
            id: trackSplash
            color: "black"
            flags: Qt.Popup
            opacity: .75
            height: 95
            onWidthChanged:  {
                x = Screen.width - width
                y = Screen.height - height
            }

            signal splashDone

            function start(player, img, animate, duration)
            {
                splashtitle.text = "Now Playing on " + player.zonename
                txt1.text = "\"" + player.name + "\""
                txt2.text = "by " + player.artist
                txt3.text = "from " + player.album

                splashimg.statusChanged.connect(function()
                {
                    if (splashimg.status === Image.Error) {
                        splashimg.source = "controls/default.png"
                    }
                    else {
                        trackSplash.width = splashimg.width + Math.max(splashtitle.width, txt1.width, txt2.width, txt3.width) + 20
                        visible = true

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
                })

                splashimg.source = img === undefined ? 'controls/default.png' : img
            }

            GridLayout {
                anchors.fill: parent
                columns: 2
                Item {
                    Layout.alignment: Qt.AlignVCenter
                    Image {
                        id: splashimg
                        Layout.alignment: Qt.AlignVCenter
                        cache: false
                        sourceSize.height: 85
                        sourceSize.width: 85
                        width: implicitWidth
                        height: implicitHeight
                        scale: Image.PreserveAspectFit
                        layer.enabled: true
                        layer.effect: DropShadow {
                            transparentBorder: true
                            horizontalOffset: 2
                            verticalOffset: 2
                            color: "#80000000"
                        }
                    }
                }
                ColumnLayout {
                    spacing: 1
                    anchors.right: parent.right
                    PlasmaExtras.Heading {
                        id: splashtitle
                        level: 4
                        font.italic: true
                    }
                    Text { width: 10; height: txt2.height }
                    PlasmaExtras.Heading {
                        id: txt1
                        level: 4
                        font.italic: true
                    }
                    PlasmaExtras.Paragraph {
                        id: txt2
                    }
                    PlasmaExtras.Paragraph {
                        id: txt3
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
    }
}


