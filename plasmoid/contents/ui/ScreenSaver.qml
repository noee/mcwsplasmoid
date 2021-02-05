import QtQuick 2.11
import QtQuick.Controls 2.9
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12
import QtQml.Models 2.15

import 'helpers/utils.js' as Utils
import 'controls'
import 'helpers'

Item {
    id: root
    enabled: false

    property bool animate: true
    property bool screenSaver: true
    property bool fullscreen: false

    property Window background
    property bool useDefaultBackground: true

    onUseDefaultBackgroundChanged: {
        if (background)
            background.sourceKey = '-1'
    }

    onEnabledChanged: {
        if (!enabled) {
            stopAll()
            event.queueCall(2000, background.destroy)
        }
        else
            event.queueCall(500,
                () => background = backgroundComp.createObject(root))
    }

    BaseListModel {
        id: splashers
    }

    function addSplash(info) {
        // Find the ndx for the splasher
        // index is info.key
        let ndx = splashers.findIndex(s => s.key === info.key)
        if (ndx !== -1) {
            background.panels.itemAt(ndx).setData(info)
        } else {
            // create splash window if not there
            splashers.append(info)
        }

        if (background && !useDefaultBackground)
            event.queueCall(500, () => background.sourceKey = info.filekey)
    }

    function closeSplash(ndx) {
        if (splashers.count > 0)
            background.panels.itemAt(ndx).fadeOut()
    }

    function stopAll() {
        splashers.forEach((i,ndx) => closeSplash(ndx))
        event.queueCall(2000, splashers.clear)
    }

    Component {
        id: backgroundComp

        Window {
            id: win
            height: Screen.height
            width:  Screen.width
            color: 'transparent'
            flags: Qt.FramelessWindowHint
                   | Qt.WindowStaysOnBottomHint
                   | Qt.BypassWindowManagerHint

            property alias sourceKey: ti.sourceKey
            property alias panels: panels

            ShadowImage {
                id: ti
                sourceKey: '-1'
                thumbnail: false
                visible: false
                duration: 700
            }

            BackgroundHue {
                source: ti
                anchors.fill: parent
                opacity: .25
            }

            Repeater {
                id: panels
                model: splashers

                SplashDelegate {
                    id: spl

                    // "moving panel" mode
                    animate: root.animate

                    y: index === 0 ? 0 : height + 25
                    // Animate data changes
                    property var xfer
                    property bool dataPending: false
                    function setData(info) {
                        xfer = info
                        if (!animate) {
                            seq.start()
                        } else {
                            dataPending = true
                        }
                    }

                    // While the animation is paused
                    // we can set data in the model for smooth
                    // transition of track data
                    onReadyForData: {
                        if (dataPending) {
                            dataPending = false
                            splashers.set(index, spl.xfer)
                            logger.warn('SPLASH DATA CHG: ' + xfer.title, xfer)
                        }
                    }

                    // data change opacity animation when the ss is
                    // not moving the panels around
                    SequentialAnimation {
                            id: seq

                            OpacityAnimator {
                                target: spl
                                to: 0
                                duration: spl.fadeOutDuration
                            }

                            ScriptAction {
                                script: {
                                    splashers.set(index, spl.xfer)
                                    logger.warn('SPLASH DATA CHG: ' + xfer.title, xfer)
                                }
                            }

                            PauseAnimation { duration: spl.fadeInDuration/2 }

                            OpacityAnimator {
                                target: spl
                                to: spl.opacityTo
                                duration: spl.fadeInDuration
                            }

                        }

                    onFadeInDone: logger.warn('FADEIN DONE', splashers.get(index))
                    onFadeOutDone: logger.warn('FADEOUT DONE', splashers.get(index))
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
