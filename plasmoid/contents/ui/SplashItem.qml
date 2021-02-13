import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

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
        if (screenSaverMode)
            setBackgroundImage()
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

    // track item list, indexed to mcws.zonemodel
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
    onScreenSaverModeChanged: {
        enabled = screenSaverMode
        if (screenSaverMode) {
            event.queueCall(1000, () => {
                mcws.zoneModel
                    .forEach((zone, ndx) => addPanel(ndx, zone.filekey))
                setBackgroundImage()
            })
        }
    }

    function setBackgroundImage(filekey) {
        if (background)
            background.sourceKey = useDefaultBackground
                ? '-1'
                : (filekey === undefined
                   ? mcws.zoneModel.get(mcws.getPlayingZoneIndex()).filekey
                   : filekey)
    }

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
        let zone = mcws.zoneModel.get(zonendx)
        let info = trackItem(zone
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
            setBackgroundImage(zone.state !== PlayerState.Stopped
                               ? info.filekey
                               : undefined)
        } else {
            // create panel if not found
            splashers.append(info)
        }
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

                    availableArea: Qt.size(win.width, win.height)

                    dataSetter: data => splashers.set(index, data)

                    onSplashDone: splashMode = false
                }
            }

            Menu {
                id: ssMenu
                MenuItem {
                    text: 'Use Default Background'
                    checkable: true
                    checked: useDefaultBackground
                    icon.name: 'emblem-music-symbolic'
                    onTriggered: useDefaultBackground = !useDefaultBackground
                }
                MenuItem {
                    text: 'Animate Panels'
                    checkable: true
                    checked: animateSS
                    icon.name: 'system-restart-panel'
                    onTriggered: animateSS = !animateSS
                }
                MenuItem {
                    text: 'Transparent Panels'
                    checkable: true
                    checked: transparentSS
                    icon.name: 'package-available'
                    onTriggered: transparentSS = !transparentSS
                }
                MenuItem {
                    text: 'Use Multiple Screens'
                    checkable: true
                    checked: useMultiScreen
                    icon.name: 'wine'
                    onTriggered: useMultiScreen = !useMultiScreen
                }

            }

            MouseAreaEx {
                acceptedButtons: Qt.RightButton | Qt.LeftButton
                onClicked: {
                    if (mouse.button === Qt.RightButton)
                        ssMenu.popup()
                    else {
                        if (splashMode)
                            splashMode = false
                        if (screenSaverMode)
                            screenSaverMode = false
                    }
                }
            }

            Component.onCompleted: visible = true

            Component.onDestruction: background = null
        }
    }

}
