import QtQuick 2.9
import QtQuick.Layouts 1.11
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kquickcontrolsaddons 2.0

import 'helpers'

Item {
    id: plasmoidRoot

    property int panelViewSize: {
        if (!plasmoid.configuration.useZoneCount)
            return Math.round(PlasmaCore.Theme.mSize(PlasmaCore.Theme.defaultFont).width
                    * plasmoid.configuration.trayViewSize)
        else {
            return Math.round(PlasmaCore.Theme.mSize(PlasmaCore.Theme.defaultFont).width
                    * (mcws.zoneModel.count <= 1 ? 2 : mcws.zoneModel.count)
                    * 12)
        }
    }
    property bool vertical:         plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool panelZoneView:    plasmoid.configuration.advancedTrayView & !vertical

    property bool abbrevTrackView:  plasmoid.configuration.abbrevTrackView
    property bool autoShuffle:      plasmoid.configuration.autoShuffle

    property int popupWidth:        plasmoid.configuration.bigPopup
                                        ? PlasmaCore.Units.gridUnit * 65
                                        : PlasmaCore.Units.gridUnit * 50
    property int popupHeight:       Math.round(popupWidth / 2)
    property int thumbSize:         plasmoid.configuration.thumbSize

    // Cover art/thumbnail helpers
    property var imageErrorKeys: ({'-1': true})
    readonly property string defaultImage: 'default.png'

    // Configured MCWS hosts (see ConfigMcws.qml)
    // { host, friendlyname, accesskey, zones, enabled }
    BaseListModel {
        id: hostModel

        function load() {
            clear()
            try {
                var arr = JSON.parse(plasmoid.configuration.hostConfig)
                arr.forEach((item) => {
                    if (item.enabled) {
                        // Because friendlyname is used in the host combo,
                        // make sure it's present, default to host name
                        if (!item.hasOwnProperty('friendlyname'))
                            item.friendlyname = ''

                        if (item.friendlyname === '')
                            item.friendlyname = item.host.split(':')[0]
                        append(item)
                    }
                })
            }
            catch (err) {
                var s = err.message + '\n' + plasmoid.configuration.hostConfig
                console.warn(s)
                logger.error('Host config parse error', s)
            }

            // model with no rows means config is not set up
            if (count === 0) {
                mcws.closeConnection()
            } else {
                // If the connected host is not in the list, reset connection to first in list
                // Also, this is essentially the auto-connect at plasmoid load (see Component.completed)
                // because at load time, mcws.host is null (mcws is not connected)
                if (!contains(item => item.host === mcws.host)) {
                    mcws.hostConfig = get(0)
                }
            }
            hostModelChanged(mcws.host)
        }

        Component.onCompleted: load()
    }

    // Use these signals to communicate to/from compact view and full view
    signal zoneSelected(int zonendx)
    signal tryConnection()
    signal hostModelChanged(string currentHost)

    Component {
        id: advComp
        CompactView {
            property int lastZone: -1

            onZoneClicked: {
                // if connected, keep the popup open
                // when clicked a different zone
                if (mcws.isConnected) {
                    zoneSelected(zonendx)
                    if (!plasmoid.expanded) {
                        lastZone = zonendx
                        plasmoid.expanded = true
                    }
                    else {
                        if (lastZone === zonendx)
                            plasmoid.expanded = false
                        else
                            lastZone = zonendx
                    }

                    return
                }
                // not connected
                if (!plasmoid.expanded) {
                    tryConnection()
                    plasmoid.expanded = true
                }
                else if (plasmoid.hideOnWindowDeactivate)
                    plasmoid.expanded = false
            }
        }
    }
    Component {
        id: iconComp
        PlasmaCore.IconItem {
            source: "multimedia-player"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (plasmoid.expanded & !plasmoid.hideOnWindowDeactivate)
                        return

                    plasmoid.expanded = !plasmoid.expanded

                    if (plasmoid.expanded & !mcws.isConnected) {
                        tryConnection()
                    }
                }
            }
        }
    }

    Plasmoid.switchWidth: PlasmaCore.Units.gridUnit * 25
    Plasmoid.switchHeight: PlasmaCore.Units.gridUnit * 25

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: Loader {

        Layout.preferredWidth: mcws.isConnected
                                ? panelZoneView ? panelViewSize : PlasmaCore.Units.iconSizeHints.panel
                                : PlasmaCore.Units.iconSizeHints.panel

        sourceComponent: mcws.isConnected
                        ? panelZoneView ? advComp : iconComp
                        : iconComp
    }

    Plasmoid.fullRepresentation: FullView {
            Layout.preferredWidth: popupWidth
            Layout.preferredHeight: popupHeight
    }

    Plasmoid.toolTipMainText: {
        mcws.isConnected ? qsTr('Current Connection') : plasmoid.title
    }
    Plasmoid.toolTipSubText: {
        mcws.isConnected ? mcws.serverInfo.friendlyname : qsTr('click to connect')
    }

    SingleShot { id: event }

    Connections {
        target: plasmoid.configuration

        onUseZoneCountChanged: mcws.reset()
        onTrayViewSizeChanged: if (!plasmoid.configuration.useZoneCount) mcws.reset()
        onHostConfigChanged: {
            mcws.closeConnection()
            event.queueCall(500, hostModel.load)
        }
        onAllowDebugChanged: {
            if (plasmoid.configuration.allowDebug)
                action_logger()
            else
                logger.close()
        }
    }

    McwsConnection {
        id: mcws
        videoFullScreen:    plasmoid.configuration.forceDisplayView
        checkForZoneChange: plasmoid.configuration.checkZoneChange
        thumbSize:          plasmoidRoot.thumbSize

        pollerInterval: (panelZoneView | plasmoid.expanded)
                        ? plasmoid.configuration.updateInterval/100 * 1000
                        : 10000

        defaultFields: plasmoid.configuration.defaultFields
    }

    // Screen saver and track splasher
    // screensaver options are per-plasmoid-session
    // track splash options are in config/playback
    SplashManager {
        id: ss

        fullscreenSplash: plasmoid.configuration.fullscreenTrackSplash
        animateSplash: plasmoid.configuration.animateTrackSplash
        splashDuration: plasmoid.configuration.splashDuration * 10

        useCoverArtBackground: plasmoid.configuration.useCoverArtBackground
        animateSS: plasmoid.configuration.animatePanels
        transparentSS: plasmoid.configuration.transparentPanels
        useMultiScreen: plasmoid.configuration.useMultiScreen

        Connections {
            target: mcws

            // (zonendx, filekey)
            // Only splash the track when it changes, when the
            // screenSaver mode is not enabled and when it's playing
            onTrackKeyChanged: {
                // splash mode
                if (plasmoid.configuration.showTrackSplash & !ss.screenSaverMode) {
                    // need to wait for state here, buffering etc.
                    event.queueCall(2000, () => {
                        // Starting the splash dismisses the popup
                        if (!plasmoid.expanded)
                            ss.showSplash(zonendx, filekey)
                    })
                    return
                }

                // screensaver
                if (ss.screenSaverMode)
                    event.queueCall(1000, ss.addItem, zonendx, filekey)

            }

            onConnectionStart: ss.screenSaverMode = false
            onConnectionStopped: ss.screenSaverMode = false
        }
    }

    // Debug/Logging connections
    Connections {
        target: mcws
        enabled: plasmoid.configuration.allowDebug & logger.enabled

        onDebugLogger: logger.log(title, msg, obj)

        onConnectionStart: {
            logger.warn('ConnectionStart', host, mcws.hostConfig)
        }
        onConnectionStopped: {
            logger.warn('ConnectionStopped')
        }
        onConnectionReady: {
            logger.warn('ConnectionReady', '(%1)'.arg(zonendx) + host, mcws.hostConfig)
        }
        onConnectionError: {
            logger.warn('ConnectionError', msg, cmd)
        }
        onCommandError: {
            logger.warn('CommandError:', msg, cmd)
        }
        onTrackKeyChanged: {
            logger.log(mcws.zoneModel.get(zonendx).zonename + ':  TrackKeyChanged'
                       , filekey.toString())
        }
        onPnPositionChanged: {
            logger.log(mcws.zoneModel.get(zonendx).zonename + ':  PnPositionChanged'
                       , pos.toString())
        }
        onPnChangeCtrChanged: {
            logger.log(mcws.zoneModel.get(zonendx).zonename + ':  PnChangeCtrChanged'
                       , ctr.toString())
        }
        onPnStateChanged: {
            logger.log(mcws.zoneModel.get(zonendx).zonename + ':  PnStateChanged'
                       , 'State: ' + playerState.toString())
        }
    }
    // Logger for "simple" debug items
    Logger {
        id: logger
        winTitle: 'MCWS Logger'
    }

    function action_kde() {
        KCMShell.open(["kscreen", "kcm_pulseaudio", "powerdevilprofilesconfig"])
    }

    function action_reset() {
        mcws.reset()
    }

    function action_close() {
        mcws.closeConnection()
        plasmoid.expanded = false
    }

    function action_logger() {
        logger.init()
    }

    function action_screensaver() {
        ss.screenSaverMode = !ss.screenSaverMode
    }

    Plasmoid.onContextualActionsAboutToShow: {
        plasmoid.action('reset').visible =
            plasmoid.action('screensaver').visible =
            plasmoid.action('close').visible = mcws.isConnected

        plasmoid.action('screensaver').text = (ss.screenSaverMode
                ? 'Stop' : 'Start') + ' Screensaver'
        plasmoid.action('logger').visible = plasmoid.configuration.allowDebug
    }

    Component.onCompleted: {
        if (KCMShell.authorize("powerdevilprofilesconfig.desktop").length > 0)
            plasmoid.setAction("kde", i18n("Configure Plasma5..."), "kde");

        plasmoid.setAction("logger", i18n("Logger Window"), "debug-step-into")
        if (plasmoid.configuration.allowDebug) {
            action_logger()
        }
        plasmoid.setActionSeparator('1')
        plasmoid.setAction("screensaver", '', "preferences-desktop-screensaver-symbolic")
        plasmoid.setAction("reset", i18n("Refresh View"), "view-refresh");
        plasmoid.setAction("close", i18n("Close Connection"), "network-disconnected");
        plasmoid.setActionSeparator('2')
    }
}
