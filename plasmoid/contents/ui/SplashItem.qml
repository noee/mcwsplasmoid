import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

import 'helpers/utils.js' as Utils
import 'controls'
import 'helpers'

// Splasher has a screensaver mode and a regular
// track splash mode (only one item in the model).
// The track splash can be fullscreen or centered or
// animated and is a single panel with a fade in/fade out/finish.

// Start a track splash using showSplash()
// Start the screenSaver mode by setting screenSaverMode

// Track splash and screenSaverMode are mutually exclusive
Item {
    id: root

    property Window background
    property bool useDefaultBackground: true
    property bool useMultiScreen: true
    property bool animateSS: true
    property bool transparentSS: true
    property bool fullscreenSplash: false

    onUseDefaultBackgroundChanged: {
        if (screenSaverMode)
            background.setImage()
    }

    onAnimateSSChanged: if (screenSaverMode) background.resetFlags()
    onTransparentSSChanged: if (screenSaverMode) background.resetFlags()

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
        if (splashMode) {
            if (!background)
                background = windowComp.createObject(root)
        } else {
            if (!screenSaverMode)
                background.destroy()
        }
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
        if (screenSaverMode) {
            if (!background)
                background = windowComp.createObject(root)
            event.queueCall(1000, () => {
                mcws.zoneModel.forEach((zone, ndx) => addItem(ndx, zone.filekey))
                background.setImage()
            })
        }
        else {
            background.stopAll()
            event.queueCall(1500, () => {
                splashers.clear()
                background.destroy()
            })
        }
    }

    function addItem(zonendx, filekey) {
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
            background.updatePanel(ndx, info)
            background.setImage(zone.state !== PlayerState.Stopped
                               ? info.filekey
                               : undefined)
        } else {
            // create panel if not found
            splashers.append(info)
        }
    }

    Component {
        id: windowComp

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

            function setImage(filekey) {
                if (useDefaultBackground)
                    ti.sourceKey = '-1'
                else {
                    if (filekey !== undefined && filekey !== '') {
                        ti.sourceKey = filekey
                    } else {
                        // Null filekey sent so find a playing zone
                        // If no zones playing, choose a random zone
                        let ndx = mcws.zonesByState(PlayerState.Playing).length === 0
                             ? Math.floor(Math.random() * mcws.zoneModel.count)
                             : mcws.getPlayingZoneIndex()
                        ti.sourceKey = mcws.zoneModel.get(ndx).filekey
                    }
                }
            }

            function resetFlags() {
                for(let i=0, len=panels.count; i<len; ++i)
                    panels.itemAt(i).reset({ animate: animateSS
                                          , transparent: transparentSS
                                          })
            }

            function stopAll() {
                for(let i=0, len=panels.count; i<len; ++i)
                    panels.itemAt(i).stop()
            }

            function updatePanel(ndx, info) {
                panels.itemAt(ndx).setDataPending(info)
            }

            TrackImage {
                id: ti
                sourceKey: '-1'
                thumbnail: false
                animateLoad: true
                fillMode: Image.PreserveAspectFit
                duration: 700
                anchors.centerIn: parent
                width: Math.round(parent.height*.8)
                height: Math.round(parent.height*.8)
                opacityTo: splashMode & !fullscreenSplash ? 0 : 0.25
            }

            Repeater {
                id: panels
                model: splashers

                // there could be multiple splashers so
                // when they're all done, stop splashMode
                onItemRemoved: {
                    if (splashMode && count === 0) {
                        splashMode = false
                    }
                }

                SplashDelegate {
                    availableArea: Qt.size(win.width, win.height)

                    dataSetter: data => splashers.set(index, data)

                    // splashMode
                    // track spashers remove themselves from the model
                    onSplashDone: splashers.remove(index)
                }
            }

            Menu {
                id: ssMenu
                // keep a var so we can react on click
                // after the menu disappears
                property bool on: false

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
                MenuSeparator {}
                MenuItem {
                    text: 'Stop Screensaver'
                    icon.name: 'stop'
                    onTriggered: screenSaverMode = false
                }
            }

            MouseAreaEx {
                acceptedButtons: Qt.RightButton | Qt.LeftButton
                onClicked: {
                    if (screenSaverMode && mouse.button === Qt.RightButton) {
                        ssMenu.popup()
                        ssMenu.on = true
                    } else {
                        if (ssMenu.on) {
                            ssMenu.on = false
                        }
                        else {
                            if (splashMode)
                                splashers.clear()
                            if (screenSaverMode)
                                screenSaverMode = false
                        }
                    }
                }
            }

            Component.onCompleted: visible = true

            Component.onDestruction: background = null
        }
    }

}
