import QtQuick 2.9
import QtQuick.Layouts 1.11
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kquickcontrolsaddons 2.0

import 'helpers'
import 'helpers/utils.js' as Utils

Item {
    id: plasmoidRoot

    property int panelViewSize: {
        if (!plasmoid.configuration.useZoneCount)
            return theme.mSize(theme.defaultFont).width * plasmoid.configuration.trayViewSize
        else {
            var m = mcws.zoneModel.count === 1 ? 2 : mcws.zoneModel.count
            return theme.mSize(theme.defaultFont).width * m * 15
        }
    }
    property bool vertical:         plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool panelZoneView:    plasmoid.configuration.advancedTrayView & !vertical

    property bool abbrevZoneView:   plasmoid.configuration.abbrevZoneView
    property bool abbrevTrackView:  plasmoid.configuration.abbrevTrackView
    property bool autoShuffle:      plasmoid.configuration.autoShuffle

    property int thumbSize:         plasmoid.configuration.thumbSize
    property int clickedZone: -1

    // Manage hidden zones for this session
    QtObject {
        id: hiddenZones
        // {host, zoneid}
        property var _list: []

        function add(zonendx) {
            _list.push( {host: mcws.host, zoneid: mcws.zoneModel.get(zonendx).zoneid} )
            mcws.zoneModel.remove(zonendx)
        }
        function apply(cb, delay) {
            delay = delay === undefined ? 0 : delay
            event.queueCall(delay, function() {
                _list.forEach(function(item) {
                    if (item.host === mcws.host) {
                        var i = mcws.zoneModel.findIndex(function(zone) {
                            return zone.zoneid === item.zoneid })
                        if (i !== -1) {
                            mcws.zoneModel.remove(i)
                        }
                    }
                })
                if (Utils.isFunction(cb))
                    cb()
            })
        }
        function isEmpty() {
            return _list.findIndex(function(item) { return item.host === mcws.host }) === -1
        }
        function clear() {
            _list = _list.filter(function(item) { return item.host !== mcws.host })
        }
    }

    signal hostListChanged(string currentHost)
    BaseListModel {
        id: hostModel

        function load() {

            clear()
            try {
                var arr = JSON.parse(plasmoid.configuration.hostConfig)
            }
            catch (err) {
                console.log(err)
            }
            finally {
                arr.forEach(function(h) {
                    if (h.enabled)
                        append(h)
                })
            }

            if (count === 0) {
                mcws.host = ''
            } else {
                // if the connected host is not in the list, reset connection to first in list
                if (!contains(function(i) { return i.host === mcws.host }))
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
        PlasmaCore.IconItem {
            source: "multimedia-player"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (plasmoid.expanded & !plasmoid.hideOnWindowDeactivate)
                        return

                    clickedZone = -1
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
        onHostConfigChanged: hostModel.load()
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
                                   , 'Currently Playing on ' + zone.zonename
                                   , zone.name
                                   , 'from ' + zone.album + '\nby ' + zone.artist])
                }
            }
        }
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

    Component.onCompleted: {

        if (plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            plasmoid.activationTogglesExpanded = true
        }
        plasmoid.setAction("kde", i18n("Configure Plasma5..."), "kde");
        plasmoid.setActionSeparator('1')
        plasmoid.setAction("reset", i18n("Refresh View"), "view-refresh");
        plasmoid.setAction("unhideZones", i18n("Show All Zones"), "password-show-on");
        plasmoid.setAction("close", i18n("Close Connection"), "window-close");
        plasmoid.setActionSeparator('2')

        hostModel.load()
    }
}
