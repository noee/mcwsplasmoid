import QtQuick 2.11
import QtQuick.Controls 2.9
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12
import QtQml.Models 2.15

import 'helpers/utils.js' as Utils
import 'controls'
import 'helpers'

// Splasher has a screensaver mode and a regular
// track splash mode.  The track splash can be fullscreen
// or centered and is just the ss with a fade in/fade out/finish.

// Start a track splash using showSplash()
// Start the screenSaver mode by setting screenSaverMode
Item {
    id: root
    enabled: false

    property Window background
    property bool useDefaultBackground: true
    property bool animateSS: true
    property bool fullscreenSplash: false

    onAnimateSSChanged: {
        if (enabled) {
            enabled = false
            event.queueCall(2000, () => enabled = true)
        }
    }

    onEnabledChanged: {
        if (!enabled) {
            stopAll()
        } else {
            event.queueCall(500,
                () => background = backgroundComp.createObject(root))
        }
    }

    BaseListModel {
        id: splashers
    }

    // Splash mode
    property bool splashMode: false
    onSplashModeChanged: {
        // clear the model so stop doesn't fade out
        // as they've already faded out
        if (!splashMode)
            splashers.clear()
        enabled = splashMode
    }

    function showSplash(info) {
        info.splashmode = splashMode = true
        info.animate = plasmoid.configuration.animateTrackSplash
        info.fullscreen = fullscreenSplash
        info.duration = plasmoid.configuration.splashDuration/100 * 1000
        info.thumbsize = thumbSize
        info.screensaver = false

        splashers.append(info)
    }

    // SS mode function
    property bool screenSaverMode: false
    onScreenSaverModeChanged: enabled = screenSaverMode

    function addPanel(info) {
        // Find the ndx for the splasher
        // index is info.key
        info = Object.assign({ key: -1
                           , filekey: '-1'
                           , title: '<no title>'
                           , info1: '<no track name>'
                           , info2: '<no album/artist>'
                           , animate: animateSS
                           , fullscreen: false
                           , screensaver: true
                           , splashmode: false
                           , thumbsize: thumbSize}, info)

        let ndx = splashers.findIndex(s => s.key === info.key)
        if (ndx !== -1) {
            // panel found
            background.panels.itemAt(ndx).setData(info)
        } else {
            // create panel if not found
            splashers.append(info)
        }

        if (background && !useDefaultBackground)
            event.queueCall(500, () => background.sourceKey = info.filekey)
    }

    function stopAll() {
        splashers.forEach((i,ndx) => background.panels.itemAt(ndx).fadeOut())
        event.queueCall(1000, () => {
                            screenSaverMode = false
                            splashers.clear()
                            background.destroy()
                        })
    }

    Component {
        id: backgroundComp

        Window {
            height: Screen.height
            width:  Screen.width
            color: 'transparent'
            flags: Qt.FramelessWindowHint
//                   | Qt.WindowStaysOnBottomHint
                   | Qt.BypassWindowManagerHint

            property alias sourceKey: ti.sourceKey
            property alias panels: panels


            TrackImage {
                id: ti
                sourceKey: '-1'
                thumbnail: false
                animateLoad: true
                fillMode: Image.PreserveAspectFit
                duration: 700
                anchors.fill: parent
                opacityTo: splashMode & !fullscreenSplash ? 0 : 0.25
            }

            Repeater {
                id: panels
                model: splashers

                SplashDelegate {
                    id: spl

                    property var xfer
                    property bool dataPending: false
                    function setData(info) {
                        xfer = info
                        dataPending = true
                    }

                    // While the animation is paused
                    // we can set data in the model for smooth
                    // transition of track data
                    onAnimationPaused: {
                        // always set background
                        background.sourceKey = useDefaultBackground
                                ? '-1'
                                : sourceKey

                        // update model if data changes pending
                        if (dataPending) {
                            dataPending = false
                            splashers.set(index, spl.xfer)
                            logger.warn('SPLASH DATA CHG: ' + xfer.title, xfer)
                        }
                    }

                    onSplashDone: splashMode = false
                }
            }

            MouseAreaEx {
                onClicked: {
                    if (splashMode)
                        splashMode = false
                }
            }

            Component.onCompleted: {
                visible = true
                logger.warn('BACKGROUND::create', sourceKey)
            }

            Component.onDestruction: {
                background = null
                logger.warn('BACKGROUND::destroy', sourceKey)
            }
        }
    }

}
