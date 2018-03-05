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
            splash.splashDone.connect(splash.destroy)
            splash.start(player, imgstr, animate, duration)
        }
    }

    Component {
        id: splashRunner
        Window {
            id: trackSplash
            color: 'black'
            flags: Qt.Popup
            opacity: .75
            height: 120
            onWidthChanged:  {
                x = Screen.width - width
                y = Screen.height - height - 10
            }

            signal splashDone

            function start(player, img, animate, duration) {
                splashtitle.text = 'Now Playing on ' + player.zonename
                txt1.text = "'" + player.name + "'"
                txt2.text = 'from ' + player.album
                txt3.text = 'by ' + player.artist

                splashimg.statusChanged.connect(function()
                {
                    if (splashimg.status === Image.Error) {
                        splashimg.source = 'controls/default.png'
                    }
                    else {
                        trackSplash.width = splashimg.width + Math.max(splashtitle.width, txt1.width, txt2.width, txt3.width) + 25
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

                splashimg.source = img
            }

            GridLayout {
                anchors.fill: parent
                columns: 2
                columnSpacing: 1

                Item {
                    Layout.alignment: Qt.AlignVCenter
                    height: trackSplash.height * .9
                    width: height
                    Image {
                        id: splashimg
                        anchors.fill: parent
                        cache: false
                        fillMode: Image.PreserveAspectFit
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
                    anchors.top: parent.top
                    PlasmaExtras.Heading {
                        id: splashtitle
                        level: 4
                        font.italic: true
                        anchors.right: parent.right
                    }
                    PlasmaExtras.Heading {
                        id: txt1
                        level: 4
                        font.italic: true
                        font.bold: true
                        Layout.topMargin: 10
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
                   to: (Screen.width/2)-(trackSplash.width/2)
                   onStopped: timer.restart()
            }
            PropertyAnimation {
                id: opAnimation
                target: trackSplash
                property: "opacity"
                duration: 1000
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


