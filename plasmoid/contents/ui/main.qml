import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

//import org.kde.kquickcontrolsaddons 2.0 // KCMShell
import QtQuick.XmlListModel 2.0
import Qt.labs.platform 1.0

Item {

    // Initial size of the window in gridUnits
    width: units.gridUnit * 30
    height: units.gridUnit * 22

    // try to connect to the host, set models/views
    function tryConnectHost(host) {
        detailModel.source = ""
        playlistModel.source = ""

        pn.init(host.indexOf(':') === -1 ? host + ":52199" : host)
    }

    SingleShot {
        id: event
    }

    Connections {
        target: pn
        // on new connection ready, set zone view model
        // then select the playing zone
        onConnectionReady: {
            lv.model = pn.model
            lv.currentIndex = -1
            event.singleShot(0, function()
            {
                var list = pn.zonesByStatus("Playing")
                lv.currentIndex = list.length>0 ? list[list.length-1] : 0
            })
        }
        onTrackChange: {
            if (detailModel.count > 0 && zoneid === lv.getObj().zoneid)
               detailView.setPlayingTrack()
        }
        onTotalTracksChange: {
            if (detailModel.count > 0 && zoneid === lv.getObj().zoneid) {
                detailModel.source = ""
                detailView.reset()
            }
        }
    }
    PlayingNow {
        id: pn
        timer.interval: 1000*plasmoid.configuration.updateInterval
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: units.smallSpacing
        }
        // Header
        RowLayout {
            PlasmaExtras.Title {
                text: {
                    switch (mainView.currentIndex) {
                        case 0:
                            lv.getObj().zonename + "/Playlists"
                            break
                        case 1:
                            "Zones for MC host: "
                            break
                        case 2:
                            lv.getObj().zonename + "/Playing Now"
                    }
                }
            }

            // host list
            QtControls.ComboBox {
                id: hostList
                visible: mainView.currentIndex === 1
                Layout.fillWidth: true
                Layout.rightMargin: 20
                implicitHeight: 25
                model: plasmoid.configuration.hostList.split(';')
                onActivated: tryConnectHost(currentText)
            }
        }

        QtControls.SwipeView {
            id: mainView
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: units.gridUnit
            currentIndex: 1

            onCurrentIndexChanged: {
                if (currentIndex === 0)
                    plView.reset()
                else if (currentIndex === 2)
                    detailView.reset()
            }

            // PL View
            QtControls.Page {
                background: Rectangle {
                    opacity: 0
                }

                Viewer {
                    id: plView

                    function reset() {
                        playlistModel.source = pn.hostUrl + "Playlists/List"
                    }

                    model: playlistModel
                    delegate: RowLayout {
                        anchors.margins: units.smallSpacing
                        PlasmaComponents.ToolButton {
                            iconSource: "media-playback-start"
                            flat: false
                            onClicked: {
                                pn.playPlaylist(id, lv.currentIndex)
                                event.singleShot(250, function() { mainView.currentIndex = 1 } )
                            }
                        }
                        PlasmaComponents.ToolButton {
                            iconSource: "list-add"
                            flat: false
                            onClicked: {
                                pn.addPlaylist(id, lv.currentIndex)
                                event.singleShot(250, function() { mainView.currentIndex = 1 } )
                            }
                        }
                        Text {
                            color: "light grey"
                            text: name + " @" + path
                            MouseArea {
                                anchors.fill: parent
                                onClicked: plView.currentIndex = index
                            }
                        }
                    }
                }
            }
            // Zone View
            QtControls.Page {
                background: Rectangle {
                    opacity: 0
                }

                Viewer {
                    id: lv
                    delegate:
                        ColumnLayout {
                            // zone/track display
                            RowLayout {
                                anchors.margins: units.smallSpacing
                                anchors.fill: parent
                                TrackImage {
                                    animateLoad: true
                                    image.source: (pn.isConnected && filekey !== undefined)
                                                  ? pn.imageUrl(filekey, 'large')
                                                  : ""
                                }
                                ColumnLayout {
                                    spacing: 0
                                    Layout.leftMargin: 5
                                    RowLayout {
                                        Layout.margins: 0
                                        // link icon
                                        PlasmaCore.IconItem {
                                            implicitHeight: 15
                                            implicitWidth: 8
                                            anchors {
                                                left: parent.left
                                                top: parent.top
                                            }
                                            visible: linked
                                            source: "link"
                                            Layout.margins: 0
                                        }
                                        // status icon
                                        PlasmaCore.IconItem {
                                            implicitHeight: 15
                                            implicitWidth: 8
                                            Layout.margins: 0
                                            visible: model.status === "Playing"
                                            source: "yast-green-dot"
                                        }
                                        Text {
                                            color: "light grey"
                                            text: zonename + ": '" + name + "' (" + positiondisplay + ")"
                                        }
                                    }

                                Text {
                                        Layout.topMargin: 0
                                        color: "green"
                                        text: " from '" + album + "'"
                                    }
                                    Text {
                                        Layout.topMargin: 0
                                        color: "green"
                                        text: " by " + artist
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        lv.currentIndex = index
                                    }
                                    acceptedButtons: Qt.RightButton | Qt.LeftButton
                                }
                            }
                            // player controls
                            Player {
                                showTrackSlider: plasmoid.configuration.showTrackSlider
                                showVolumeSlider: plasmoid.configuration.showVolumeSlider
                                visible: pn.isConnected & lv.currentIndex === index
                            }
                    }
                }
            }
            // Detail View
            QtControls.Page {
                background: Rectangle {
                    opacity: 0
                }

                Viewer {
                    id: detailView
                    model: detailModel

                    function reset() {
                        detailModel.source = pn.hostUrl
                                + "Playback/Playlist?Fields=name,artist,album,genre,media type&Zone="
                                + lv.getObj().zoneid
                    }

                    function setPlayingTrack() {
                        var ndx = lv.getObj().playingnowposition
                        if (ndx !== undefined && (ndx >= 0 & ndx < detailModel.count) )
                            currentIndex = ndx
                    }

                    delegate:
                        RowLayout {
                            anchors.margins: units.smallSpacing
                            TrackImage {
                                image.source: (pn.isConnected && filekey !== undefined)
                                              ? pn.imageUrl(filekey)
                                              : ""
                            }
                            ColumnLayout {
                                spacing: 0
                                Layout.leftMargin: 5
                                Text {
                                    color: "light grey"
                                    text: name + " / " + genre
                                 }
                                Text {
                                    Layout.topMargin: 1
                                    color: "green"
                                    text: " from '" + album + "'"
                                }
                                RowLayout {
                                    Text {
                                        Layout.topMargin: 1
                                        color: "green"
                                        text: " by " + artist
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    detailView.currentIndex = index
                                    if (mouse.button === Qt.RightButton)
                                        detailMenu.open()
                                }
                                acceptedButtons: Qt.RightButton | Qt.LeftButton
                            }
                        }
                }
            }
        }
    }

    Menu {
        id: zoneMenu

        function show(x, y) {
            linkMenu.loadActions()
            open(x, y)
        }
        function showBelow(item) {
            linkMenu.loadActions()

            open(item)
        }

        MenuItem {
            text: "Reshuffle"
            iconName: "shuffle"
            onTriggered: pn.shuffle(lv.currentIndex)
        }

        MenuSeparator{}

        Menu {
            id: linkMenu
            title: "Link to"
            iconName: "link"

            function newMenuItem() {
                return Qt.createQmlObject("import Qt.labs.platform 1.0; MenuItem { property var id; property var index }", linkMenu);
            }

            function loadActions()
            {
                if (lv.model.count < 2) {
                    linkMenu.visible = false
                    return
                }

                linkMenu.visible = true
                clear()

                var currId = lv.getObj().zoneid
                var zonelist = lv.getObj().linkedzones !== undefined ? lv.getObj().linkedzones.split(';') : []
                var zones = pn.zoneModel

                for(var i=0; i<zones.length; ++i) {
                    var zid = zones[i].zoneid
                    if (currId !== zid) {
                        var menuItem = newMenuItem();
                        menuItem.id = zid
                        menuItem.index = i
                        menuItem.text = i18n(zones[i].zonename);
                        menuItem.checkable = true;
                        menuItem.checked = zonelist.indexOf(zid) !== -1
                        linkMenu.addItem(menuItem);
                    }
                }
            }


            MenuItemGroup {
                id: zoneGroup
                items: linkMenu.items
                exclusive: false
                onTriggered: {
                    if (item.checked) {
                        pn.unLinkZone(lv.currentIndex)
                    }
                    else {
                        pn.linkZones(lv.getObj().zoneid, item.id)
                        event.singleShot(pn.timer.interval/2, function()
                        {
                            pn.updateModelItem(lv.currentIndex)
                            pn.updateModelItem(item.index)
                        })
                    }

                }
            }
        }
    }

    Menu {
        id: detailMenu

        MenuItem {
            text: "Play Now"
            onTriggered: pn.playTrack(detailView.currentIndex, lv.currentIndex)
        }
        MenuItem {
            text: "Remove Track"
            onTriggered: pn.removeTrack(detailView.currentIndex, lv.currentIndex)
        }
        MenuSeparator{}
        MenuItem {
            text: "Clear Playing Now"
            onTriggered: pn.clearPlaylist(lv.currentIndex)
        }
    }

    PlasmaCore.IconItem {
        width: units.iconSizes.large * 4
        height: width
        anchors {
            left: parent.left
            bottom: parent.bottom
        }

        source: "media-album-cover"
        opacity: 0.1
    }

    PlasmaComponents.ToolButton {
        id: pinButton
        anchors.top: parent.top
        anchors.right: parent.right
        width: Math.round(units.gridUnit * 1.25)
        height: width
        checkable: true
        iconSource: "window-pin"
        onCheckedChanged: plasmoid.hideOnWindowDeactivate = !checked
    }

    Plasmoid.onExpandedChanged: {
        if (pn.isConnected) {
            if (plasmoid.expanded)
                pn.timer.start()
            else
                pn.timer.stop()
        }
    }

    Plasmoid.compactRepresentation: PlasmaCore.IconItem {
        source: "multimedia-player"
        colorGroup: PlasmaCore.ColorScope.colorGroup
        MouseArea {
            anchors.fill: parent
            onClicked: plasmoid.expanded = !plasmoid.expanded
        }
    }
    
    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        onNewData: disconnectSource(sourceName)
        function exec(cmd) {
            connectSource(cmd)
        }
    }
    function action_screens() {
        executable.exec("kcmshell5 kcm_kscreen")
    }
    function action_pulse() {
        executable.exec("kcmshell5 kcm_pulseaudio")
    }

    function action_power() {
        executable.exec("kcmshell5 powerdevilprofilesconfig")
    }
    function action_mpvconf() {
        executable.exec("xdg-open ~/.mpv/config")
    }

    XmlListModel {
        id: playlistModel
        query: "/Response/Item"

        XmlRole { name: "id"; query: "Field[1]/string()" }
        XmlRole { name: "name"; query: "Field[2]/string()" }
        XmlRole { name: "path"; query: "Field[3]/string()" }
        XmlRole { name: "type"; query: "Field[4]/string()" }
    }
    XmlListModel {
        id: detailModel
        query: "/MPL/Item"

        XmlRole { name: "filekey"; query: "Field[1]/string()" }
        XmlRole { name: "name"; query: "Field[2]/string()" }
        XmlRole { name: "artist"; query: "Field[3]/string()" }
        XmlRole { name: "album"; query: "Field[4]/string()" }
        XmlRole { name: "genre"; query: "Field[5]/string()" }
        XmlRole { name: "mediatype"; query: "Field[6]/string()" }

        onStatusChanged: {
            if (status === XmlListModel.Ready)
                detailView.setPlayingTrack()
        }
    }

    Component.onCompleted: {
        if (plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            plasmoid.activationTogglesExpanded = true
        }

        plasmoid.setAction("power", i18n("Power Settings..."), "utilities-energy-monitor");
        plasmoid.setAction("screens", i18n("Configure Screens..."), "video-display");
        plasmoid.setAction("pulse", i18n("PulseAudio Settings..."), "audio-volume-medium");
        plasmoid.setAction("mpvconf", i18n("Configure MPV..."), "mpv");
        
        event.singleShot(0, function() { tryConnectHost(hostList.currentText) })
    }
}
