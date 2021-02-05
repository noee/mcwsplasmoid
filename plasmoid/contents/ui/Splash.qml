import QtQuick 2.11
import QtQuick.Controls 2.9
import QtQuick.Window 2.12
import org.kde.plasma.core 2.1 as PlasmaCore

import 'helpers/utils.js' as Utils
import 'helpers'

// We have to use a window to stay independent of
// the plasmoid.
Item {
    id: root

    property bool animate: false
    property bool fullscreen: false
    property int duration: 5000

    // show() creates the window object which
    // displays the track coverart/info.
    // There is a fade in animation, a pause
    // and then the fade out animation
    /* info = {key, filekey, title, info1, info2} */
    function show(info) {
        let defInfo = {key: -1
                        , filekey: '-1'
                        , title: '<no title>'
                        , info1: '<no track name>'
                        , info2: '<no album/artist>'
                        , animate: animate
                        , fullscreen: fullscreen
                        , duration: duration }

        return splashComp.createObject(root,
                                  { params: Utils.isObject(info)
                                            ? Object.assign(defInfo, info)
                                            : defInfo
                                  })
    }

    Component {
        id: splashComp

        /*
          Setting visible or pos (x/y) causes QT to set screen too early.

          See Component completed.

          Don't set visible true until ready for animation, forces QT to pick proper
          screen.  Window pos and animation does not work reliably on Wayland.

          Qt graphicals cannot adust opacity of Window items, so use the
          RowLayout instead.  See splashRow.
        */
        Window {
            id: trackSplash
            color: 'transparent'
            flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
//                   ( | Qt.CustomizeWindowHint)
//                   & ~Qt.WindowTitleHint
//                    & ~Qt.WindowSystemMenuHint
            width: root.width
            height: root.height

            property alias params: splashLayout.params

            // After the window creates, set visible, size and
            // position, then begin the animate
            Component.onCompleted: {
                // delay for image to load (sets size)
                event.queueCall(250, () => {

                    if (fullscreen) {
                        root.height = Screen.height
                        root.width = Screen.width

                    } else {
                        root.height = splashLayout.splashimg.implicitHeight
                                        + PlasmaCore.Units.largeSpacing
                        root.width = Math.round(splashLayout.splashimg.width * 4)
                    }

                    // if animate, start from bottom/right
                    if (!fullscreen) {
                        root.x = Math.round(Screen.width - width)
                        root.y = Math.round(Screen.height - height - 50)
                        x = root.x; y = root.y
                    }

                    // show the splash
                    visible = true

                    splashLayout.fadeIn()

                })
            }

            Component.onDestruction: {
                logger.warn('splasher::destroy', params)
            }

            SingleShot { id: event }

            // opacity follows the SplashLayout animation
            BackgroundHue {
                source: splashLayout.splashimg
                anchors.fill: parent
                lightness: -0.5
            }

            // Plugins don't handle window opacity
            // so use a rect
            SplashLayout {
                id: splashLayout

                width: fullscreen
                       ? Math.round(parent.width/1.7)
                       : parent.width
                height: fullscreen
                        ? Math.round(parent.height/1.5)
                        : parent.height

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                onFinished: trackSplash.destroy()
            }

        }
    }
}


