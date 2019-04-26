import QtQuick 2.9
import QtQuick.Layouts 1.11
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kquickcontrolsaddons 2.0
import org.kde.kirigami 2.4 as Kirigami

import 'helpers'
import 'helpers/utils.js' as Utils

Item {
    id: plasmoidRoot

    property int panelViewSize: {
        if (!plasmoid.configuration.useZoneCount)
            return theme.mSize(theme.defaultFont).width
                    * plasmoid.configuration.trayViewSize
        else {
            return theme.mSize(theme.defaultFont).width
                    * (mcws.zoneModel.count <= 1 ? 2 : mcws.zoneModel.count)
                    * 12
        }
    }
    property bool vertical:         plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool panelZoneView:    plasmoid.configuration.advancedTrayView & !vertical

    property bool abbrevZoneView:   plasmoid.configuration.abbrevZoneView
    property bool abbrevTrackView:  plasmoid.configuration.abbrevTrackView
    property bool autoShuffle:      plasmoid.configuration.autoShuffle

    property int thumbSize:         plasmoid.configuration.thumbSize
    // used by compact view to tell full view which zone was clicked
    property int clickedZone: -1

    // Manage hidden zones for this session
    QtObject {
        id: hiddenZones
        // {host, zoneid}
        property var _list: []

        function add(zonendx) {
            _list.push( {host: mcws.host, zoneid: mcws.zoneModel.get(zonendx).zoneid} )
            mcws.removeZone(zonendx)
        }
        function isEmpty() {
            return _list.findIndex((item) => { return item.host === mcws.host }) === -1
        }
        function clear() {
            _list = _list.filter((item) => { return item.host !== mcws.host })
        }
        function get(h) {
            var ret = []
            _list.forEach((item) => {
                if (item.host === h)
                    ret.push(item.zoneid)
            })
            return ret
        }
    }

    // Configured MCWS hosts (see ConfigMcws.qml)
    // { host, friendlyname, accesskey, zones, enabled }
    signal hostListChanged(string currentHost)
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

            // model with no rows means config is not set up properly
            if (count === 0) {
                mcws.host = ''
                hostModel.append({ friendlyname: '!! Check MCWS hosts configuration !!' })
            } else {
                // If the connected host is not in the list, reset connection to first in list
                // Also, this is essentially the auto-connect at plasmoid load (see Component.completed)
                // because at load time, mcws.host is null (mcws is not connected)
                if (!contains((i) => { return i.host === mcws.host }))
                    mcws.host = get(0).host
            }
            hostListChanged(mcws.host)
        }
    }

    Component {
        id: advComp
        CompactView {
            onZoneClicked: {
                if (plasmoid.expanded & !plasmoid.hideOnWindowDeactivate)
                    return

                clickedZone = zonendx
                plasmoid.expanded = !plasmoid.expanded
            }
        }
    }
    Component {
        id: iconComp
        Kirigami.Icon {
            source: "multimedia-player"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (plasmoid.expanded & !plasmoid.hideOnWindowDeactivate)
                        return
                    plasmoid.expanded = !plasmoid.expanded
                }
            }
        }
    }

    Plasmoid.switchWidth: theme.mSize(theme.defaultFont).width * 28
    Plasmoid.switchHeight: theme.mSize(theme.defaultFont).height * 15

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: Loader {

        Layout.preferredWidth: mcws.isConnected
                                ? panelZoneView ? panelViewSize : units.iconSizes.medium
                                : units.iconSizes.medium

        sourceComponent: mcws.isConnected
                        ? panelZoneView ? advComp : iconComp
                        : iconComp
    }

    Plasmoid.fullRepresentation: FullView {
        width: units.gridUnit * 26
        height: units.gridUnit * 30
    }

    SingleShot { id: event }

    Connections {
        target: plasmoid.configuration

        onDefaultFieldsChanged: mcws.setDefaultFields(plasmoid.configuration.defaultFields)
        onUseZoneCountChanged: mcws.reset()
        onTrayViewSizeChanged: if (!plasmoid.configuration.useZoneCount) mcws.reset()
        onHostConfigChanged: hostModel.load()
        onAllowDebugChanged: {
            if (plasmoid.configuration.allowDebug)
                action_logger()
            else {
                logger.close()
            }
        }
    }

    McwsConnection {
        id: mcws
        videoFullScreen: plasmoid.configuration.forceDisplayView
        thumbSize: plasmoidRoot.thumbSize
        pollerInterval: plasmoid.configuration.updateInterval/100 *
                        (panelZoneView | plasmoid.expanded ? 1000 : 3000)

        Component.onCompleted: setDefaultFields(plasmoid.configuration.defaultFields)
    }

    Splash {
        id: splasher
        animate: plasmoid.configuration.animateTrackSplash

        Connections {
            target: mcws
            enabled: plasmoid.configuration.showTrackSplash && mcws.isConnected
            onTrackKeyChanged: {
                if (zone.state === PlayerState.Playing) {
                    splasher.show([zone.filekey
                                   , 'Now Playing on %1/%2'
                                        .arg(mcws.serverInfo.friendlyname).arg(zone.zonename)
                                   , zone.name
                                   , 'from ' + zone.album + '\nby ' + zone.artist])
                }
            }
        }
    }

    // Debug/Logging connections
    Connections {
        target: mcws
        enabled: plasmoid.configuration.allowDebug & logger.enabled

        onDebugLogger: logger.log(obj, msg)

        onConnectionStart: {
            logger.warn('ConnectionStart', host)
        }
        onConnectionStopped: {
            logger.warn('ConnectionStopped', host)
        }
        onConnectionReady: {
            logger.warn('ConnectionReady', '(%1)'.arg(zonendx) + host)
        }
        onConnectionError: {
            logger.warn('ConnectionError:\n' + msg, cmd)
        }
        onCommandError: {
            logger.warn('CommandError:\n' + msg, cmd)
        }
        onTrackKeyChanged: {
            logger.log(zone.zonename + '\nTrackKeyChanged', zone.filekey.toString())
        }
        onPnPositionChanged: {
            logger.log(mcws.zoneModel.get(zonendx).zonename + '\nPnPositionChanged', pos.toString())
        }
        onPnChangeCtrChanged: {
            logger.log(mcws.zoneModel.get(zonendx).zonename + '\nPnChangeCtrChanged', ctr.toString())
        }
        onPnStateChanged: {
            logger.log(mcws.zoneModel.get(zonendx).zonename + '\nPnStateChanged', playerState.toString())
        }
    }
    // Logger for "simple" debug items
    Logger {
        id: logger
        winTitle: 'MCWS Logger'
        messageTitleRole: 'zonename'
    }

    function action_kde() {
        KCMShell.open(["kscreen", "kcm_pulseaudio", "powerdevilprofilesconfig"])
    }
    function action_reset() {
        mcws.reset()
    }
    function action_unhideZones() {
        if (!hiddenZones.isEmpty()) {
            hiddenZones.clear()
            mcws.reset()
        }
    }
    function action_close() {
        mcws.host = ''
        plasmoid.expanded = false
    }
    function action_logger() {
        logger.init()
    }

    Component.onCompleted: {
        plasmoid.setAction("kde", i18n("Configure Plasma5..."), "kde");
        if (plasmoid.configuration.allowDebug) {
            plasmoid.setAction("logger", i18n("Logger Window"), "debug-step-into")
            action_logger()
        }
        plasmoid.setActionSeparator('1')
        plasmoid.setAction("reset", i18n("Refresh View"), "view-refresh");
        plasmoid.setAction("unhideZones", i18n("Show All Zones"), "password-show-on");
        plasmoid.setAction("close", i18n("Close Connection"), "window-close");
        plasmoid.setActionSeparator('2')

        hostModel.load()
    }
}
