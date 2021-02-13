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
    property bool useMultiScreen: false
    property bool animateSS: true
    property bool transparentSS: false
    property bool fullscreenSplash: false

    onUseDefaultBackgroundChanged: {
        if (screenSaverMode) {
            background.sourceKey = useDefaultBackground
                    ? '-1'
                    : background.panels.itemAt(splashers.count-1).splashimg.sourceKey
        }
    }

    onAnimateSSChanged: resetFlags()
    onTransparentSSChanged: resetFlags()

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

    // create a track panel model item
    function trackItem(zone, zonendx, filekey, flags) {
        return Object.assign(
                  { key: zonendx
                  , filekey: (filekey === undefined ? zone.filekey : filekey)
                  , title: '%1 [%2]'
                        .arg(zone.zonename)
                        .arg(mcws.serverInfo.friendlyname)
                  , info1: zone.name
                  , info2: zone.artist
                  , info3: zone.album
                  }
                  , flags)
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

    function showSplash(zonendx, filekey) {
        let zone = mcws.zoneModel.get(zonendx)
        // Only show playing, legit tracks
        if (zone.state !== PlayerState.Playing || filekey === '-1')
            return false

        splashMode = true
        splashers.append(trackItem(zone, zonendx, filekey,
                         { splashmode: true
                         , animate: plasmoid.configuration.animateTrackSplash
                         , fullscreen: fullscreenSplash
                         , duration: plasmoid.configuration.splashDuration/100 * 1000
                         , thumbsize: thumbSize
                         , screensaver: false
                         , transparent: false
                         }))
        return true
    }

    // SS mode function
    property bool screenSaverMode: false
    onScreenSaverModeChanged: enabled = screenSaverMode

    function resetFlags() {
        if (screenSaverMode) {
            for(let i=0, len=background.panels.count; i<len; ++i)
                background.panels.itemAt(i).reset({ animate: animateSS
                                                  , transparent: transparentSS
                                                  })
        }
    }

    function addPanel(zonendx, filekey) {
        // Find the ndx for the panel
        // index is info.key
        let info = trackItem(mcws.zoneModel.get(zonendx)
                             , zonendx
                             , filekey
                             , { animate: animateSS
                                 , fullscreen: false
                                 , screensaver: true
                                 , splashmode: false
                                 , transparent: transparentSS
                                 , thumbsize: thumbSize
                               })

        let ndx = splashers.findIndex(s => s.key === info.key)
        if (ndx !== -1) {
            // panel found
            background.panels.itemAt(ndx).setDataPending(info)
        } else {
            // create panel if not found
            splashers.append(info)
        }

        background.sourceKey = useDefaultBackground
            ? '-1'
            : info.filekey
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
            id: win
            height: screenSaverMode && useMultiScreen
                    ? Screen.desktopAvailableHeight
                    : Screen.height
            width: screenSaverMode && useMultiScreen
                   ? Screen.desktopAvailableWidth
                   : Screen.width

            color: 'transparent'
            flags: Qt.FramelessWindowHint | Qt.BypassWindowManagerHint

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

                    areaHeight: win.height
                    areaWidth: win.width

                    dataSetter: (data) => splashers.set(index, data)

                    onSplashDone: splashMode = false
                }
            }

            MouseAreaEx {
                onClicked: {
                    if (splashMode)
                        splashMode = false
                    if (screenSaverMode)
                        screenSaverMode = false
                }
            }

            Component.onCompleted: visible = true

            Component.onDestruction: background = null
        }
    }

}
