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

    property var listTextColor: plasmoid.configuration.listTextColor
    property var hdrTextFont: plasmoid.configuration.headerTextFont
    property var defaultFont: Qt.font({"family": "Roboto Light", "pointSize": 9})

    // Reset models, try to connect to the host
    function tryConnectHost(host) {
        detailModel.source = ""
        playlistModel.source = ""
        lv.model = ""
        pn.connectionReady.connect(newConnection)
        pn.init(host.indexOf(':') === -1 ? host + ":52199" : host)
    }
    // For new connection, set zone view model then select the playing zone
    function newConnection() {
        pn.connectionReady.disconnect(newConnection)
        lv.model = pn.model
        lv.currentIndex = -1
        event.singleShot(0, function()
        {
            var list = pn.zonesByStatus("Playing")
            lv.currentIndex = list.length>0 ? list[list.length-1] : 0
        })
    }

    SingleShot {
        id: event
    }

    Splash {
        id: trackSplash
        animate: plasmoid.configuration.animateTrackSplash
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
                            "Zones/MediaCenter: "
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
                        id: plDel
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
                            color: plDel.ListView.isCurrentItem ? "black" : listTextColor
                            font: plDel.ListView.isCurrentItem ? hdrTextFont : defaultFont
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

                    signal trackChange(var zoneid)
                    signal totalTracksChange(var zoneid)

                    delegate:
                        ColumnLayout {
                            id: lvDel
                            width: lv.width

                            // For changes to playback playlist
                            property var trackKey: filekey
                            property var pnPosition: playingnowposition
                            property var pnTotalTracks: playingnowtracks

                            onTrackKeyChanged: {
                                trackImg.image.source = pn.imageUrl(filekey, 'large')
                                if (plasmoid.configuration.showTrackSplash && model.status === "Playing")
                                    event.singleShot(500, function() { trackSplash.go(pn.model.get(index), pn.imageUrl(filekey, "large")) })
                            }
                            onPnPositionChanged: lv.trackChange(zoneid)
                            onPnTotalTracksChanged: lv.totalTracksChange(zoneid)

                            // zone/track display
                            RowLayout {
                                anchors.margins: units.smallSpacing
                                anchors.fill: parent
                                TrackImage {
                                    id: trackImg
                                    animateLoad: true
                                }
                                ColumnLayout {
                                    spacing: 0
                                    Layout.leftMargin: 5
                                    // zone name/status
                                    RowLayout {
                                        Layout.margins: 0
                                        // link icon
                                        PlasmaCore.IconItem {
                                            implicitHeight: 15
                                            implicitWidth: 8
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
                                            color: lvDel.ListView.isCurrentItem ? "black" : listTextColor
                                            font: lvDel.ListView.isCurrentItem ? hdrTextFont : defaultFont
                                            text: zonename
                                        }
                                        PlasmaComponents.Label{Layout.fillWidth: true}
                                        Text {
                                            color: lvDel.ListView.isCurrentItem ? "black" : listTextColor
                                            font: lvDel.ListView.isCurrentItem ? hdrTextFont : defaultFont
                                            text: "(" + positiondisplay + ")"
                                        }

                                    }
                                    // track info
                                    Text {
                                        color: lvDel.ListView.isCurrentItem ? "black" : listTextColor
                                        font.pointSize: lvDel.ListView.isCurrentItem ? defaultFont.pointSize+1 : defaultFont.pointSize
                                        font.weight: lvDel.ListView.isCurrentItem ? hdrTextFont.weight : defaultFont.weight
                                        font.family: lvDel.ListView.isCurrentItem ? hdrTextFont.family : defaultFont.family
                                        text: "'" + name + "'"
                                    }
                                    Text {
                                        Layout.topMargin: 0
                                        color: listTextColor
                                        font: defaultFont
                                        text: " from '" + album + "'"
                                    }
                                    Text {
                                        Layout.topMargin: 0
                                        font: defaultFont
                                        color: listTextColor
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

                    Connections {
                        id: zoneConn
                        target: lv
                        onTrackChange: {
                            if (detailModel.count > 0 && zoneid === lv.getObj().zoneid)
                               detailView.highlightPlayingTrack()
                        }
                        onTotalTracksChange: {
                            if (detailModel.count > 0 && zoneid === lv.getObj().zoneid) {
                                detailModel.source = ""
                                detailView.reset()
                            }
                        }
                    }

                    states: [
                         State {
                             name: "searchMode"
                             StateChangeScript {
                                 script: {
                                     zoneConn.target = null
                                 }
                             }
                         }
                     ]

                    /* Reset the query, pass a search for searchMode, which will
                      disable the signals.  If search is undefined/null, back to default state.
                      */
                    function reset(search) {
                        var query = ""
                        if (search === undefined || search === null) {
                            detailView.state = ""
                            query = "Playback/Playlist?Fields=name,artist,album,genre,media type&Zone=" + lv.getObj().zoneid
                        }
                        else {
                            detailView.state = "searchMode"
                            query = "Files/Search?Fields=name,artist,album,genre,media type&Shuffle=1&query=" + search
                        }

                        detailModel.source = pn.hostUrl + query
                    }
                    function highlightPlayingTrack() {
                          if (detailView.state === "searchMode") {
                            var fk = lv.getObj().filekey
                            var i = 0
                            while (i < detailModel.count) {
                                if (fk === detailModel.get(i).filekey) {
                                    break
                                }
                                ++i
                            }
                            currentIndex = i
                        }
                        else {
                            var ndx = lv.getObj().playingnowposition
                            if (ndx !== undefined && (ndx >= 0 & ndx < detailModel.count) )
                                currentIndex = ndx
                        }
                    }

                    delegate:
                        RowLayout {
                            id: detDel
                            anchors.margins: units.smallSpacing
                            TrackImage { image.source: pn.imageUrl(filekey) }
                            ColumnLayout {
                                spacing: 0
                                Layout.leftMargin: 5
                                Text {
                                    color: detDel.ListView.isCurrentItem ? "black" : listTextColor
                                    font: detDel.ListView.isCurrentItem ? hdrTextFont : defaultFont
                                    text: name + " / " + genre
                                 }
                                Text {
                                    Layout.topMargin: 1
                                    color: listTextColor
                                    font: defaultFont
                                    text: " from '" + album + "'"
                                }
                                RowLayout {
                                    Text {
                                        Layout.topMargin: 1
                                        color: listTextColor
                                        font: defaultFont
                                        text: " by " + artist
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    detailView.currentIndex = index
                                    if (mouse.button === Qt.RightButton)
                                        detailMenu.show()
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
            repeatMenu.loadActions()
            open(x, y)
        }
        function showAt(item) {
            linkMenu.loadActions()
            repeatMenu.loadActions()
            open(item)
        }

        function newMenuItem(parent) {
            return Qt.createQmlObject("import Qt.labs.platform 1.0; MenuItem { property var id; property var index }", parent);
        }

        MenuItem {
            text: "Reshuffle"
            iconName: "shuffle"
            onTriggered: pn.shuffle(lv.currentIndex)
        }
        Menu {
            id: repeatMenu
            title: "Repeat Mode"

            function loadActions() {
                repeatMenu.clear()

                var currRepeat = pn.repeatMode(lv.currentIndex)

                var menuItem = zoneMenu.newMenuItem(repeatMenu);
                menuItem.text = i18n("Playlist");
                menuItem.checkable = true;
                menuItem.checked = (currRepeat === menuItem.text)
                repeatMenu.addItem(menuItem);

                menuItem = zoneMenu.newMenuItem(repeatMenu);
                menuItem.text = i18n("Track");
                menuItem.checkable = true;
                menuItem.checked = currRepeat === menuItem.text
                repeatMenu.addItem(menuItem);

                menuItem = zoneMenu.newMenuItem(repeatMenu);
                menuItem.text = i18n("Off");
                menuItem.checkable = true;
                menuItem.checked = currRepeat === menuItem.text
                repeatMenu.addItem(menuItem);
            }

            MenuItemGroup {
                items: repeatMenu.items
                exclusive: false
                onTriggered: pn.setRepeat(item.text, lv.currentIndex)
            }
        }

        MenuSeparator{}
        Menu {
            id: linkMenu
            title: "Link to"
            iconName: "link"

            function loadActions() {
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
                        var menuItem = zoneMenu.newMenuItem(linkMenu);
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
        MenuSeparator{}
        MenuItem {
            text: "Stop All Zones"
            iconName: "edit-clear"
            onTriggered: pn.stopAllZones()
        }
    }

    Menu {
        id: detailMenu

        property var currObj

        function show() {
            loadActions()
            open()
        }

        function loadActions() {
            currObj = detailView.getObj()
            // play menu
            playAlbum.text = i18n("Album\t\"%1\"".arg(currObj.album))
            playArtist.text = i18n("Artist\t\"%1\"".arg(currObj.artist))
            playGenre.text = i18n("Genre\t\"%1\"".arg(currObj.genre))
            // show menu
            showAlbum.text = i18n("Album\t\"%1\"".arg(currObj.album))
            showArtist.text = i18n("Artist\t\"%1\"".arg(currObj.artist))
            showGenre.text = i18n("Genre\t\"%1\"".arg(currObj.genre))
        }

        MenuItem {
            text: "Play Track"
            onTriggered: {
                if (detailView.state === "searchMode") {
                    pn.playTrackByKey(detailView.getObj().filekey, lv.currentIndex)
                }
                else
                    pn.playTrack(detailView.currentIndex, lv.currentIndex)
            }
        }
        MenuItem {
            text: "Remove Track"
            onTriggered: pn.removeTrack(detailView.currentIndex, lv.currentIndex)
        }
        MenuSeparator{}
        Menu {
            id: playMenu
            title: "Play"
            MenuItem {
                id: playAlbum
                onTriggered: pn.playAlbum(detailMenu.currObj.filekey, lv.currentIndex)
            }
            MenuItem {
                id: playArtist
                onTriggered: pn.searchAndPlayNow("artist=" + detailMenu.currObj.artist, true, lv.currentIndex)
            }
            MenuItem {
                id: playGenre
                onTriggered: pn.searchAndPlayNow("genre=" + detailMenu.currObj.genre, true, lv.currentIndex)
            }
        }
        Menu {
            id: showMenu
            title: "Show"
            MenuItem {
                id: showAlbum
                onTriggered: detailView.reset("album=%1 and artist=%2".arg(detailMenu.currObj.album).arg(detailMenu.currObj.artist))
            }
            MenuItem {
                id: showArtist
                onTriggered: detailView.reset("artist=" + detailMenu.currObj.artist)
            }
            MenuItem {
                id: showGenre
                onTriggered: detailView.reset("genre=" + detailMenu.currObj.genre)
            }
        }

        MenuSeparator{}
        MenuItem {
            text: "Reset"
            onTriggered: detailView.reset()
        }
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
                pn.timer.interval = 1000*plasmoid.configuration.updateInterval
            else
                pn.timer.interval = 5000
            pn.timer.restart()
        }
        else {
            // Startup and recovery from loss of connection
            if (plasmoid.expanded & plasmoid.configuration.autoConnect)
                event.singleShot(250, function() { tryConnectHost(hostList.currentText) })
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
                detailView.highlightPlayingTrack()
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

    }
}
