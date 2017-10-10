import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

//import org.kde.kquickcontrolsaddons 2.0 // KCMShell
import Qt.labs.platform 1.0
import QtQuick.XmlListModel 2.0

import "models"

Item {
    // Initial size of the window in gridUnits
    width: units.gridUnit * 28
    height: units.gridUnit * 23

    property var listTextColor: plasmoid.configuration.listTextColor
    property var defaultFont: Qt.font({"family": "Roboto Light", "pointSize": 9})
    property bool abbrevZoneView: plasmoid.configuration.abbrevZoneView

    // Reset models, try to connect to the host
    function tryConnectHost(host) {
        trackModel.source = ""
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

    McwsConnection {
        id: pn
        timer.interval: 1000*plasmoid.configuration.updateInterval
    }

    // GUI

    ColumnLayout {
        anchors {
            fill: parent
            margins: units.smallSpacing
        }


        QtControls.SwipeView {
            id: mainView
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: units.gridUnit

            currentIndex: 1

            onCurrentIndexChanged: {
                if (currentIndex === 0)
                    playlistModel.load()
                else if (currentIndex === 2)
                    if (trackModel.count === 0)
                        trackModel.load()
            }

            // Playlist View
            QtControls.Page {
                background: Rectangle {
                    opacity: 0
                }
                header: ColumnLayout {
                    PlasmaExtras.Title {
                        text: lv.getObj().zonename + "/Playlists"
                    }
                    SearchBar {
                        list: playlistView
                        modelItem: "name"
                        Layout.alignment: Qt.AlignCenter
                    }
                }

                Viewer {
                    id: playlistView
                    model: PlaylistModel {
                        id: playlistModel
                        hostUrl: pn.hostUrl
                    }

                    spacing: 1
                    delegate: RowLayout {
                        id: plDel
                        width: parent.width
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
                        PlasmaExtras.Heading {
                            level: plDel.ListView.isCurrentItem ? 4 : 5
                            color: plDel.ListView.isCurrentItem ? "black" : listTextColor
                            text: name + " @" + type
                            Layout.fillWidth: true
                            MouseArea {
                                anchors.fill: parent
                                onClicked: playlistView.currentIndex = index
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
                header: RowLayout {
                    PlasmaExtras.Title {
                        text: "Playback Zones on: "
                    }
                    QtControls.ComboBox {
                        id: hostList
                        Layout.fillWidth: true
                        Layout.rightMargin: 20
                        implicitHeight: 25
                        model: plasmoid.configuration.hostList.split(';')
                        onActivated: tryConnectHost(currentText)
                    }
                }

                Viewer {
                    id: lv

                    onCurrentItemChanged: {
                        if (trackModel.count > 0)
                            trackModel.source = ""
                    }

                    signal trackChange(var zoneid)
                    signal totalTracksChange(var zoneid)

                    delegate:
                        GridLayout {
                            id: lvDel
                            width: lv.width
                            columns: 3
                            rowSpacing: 1

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

                            // zone name/status
                            RowLayout {
                                Layout.columnSpan: 2
                                spacing: 1
                                Layout.margins: 2
                                TrackImage {
                                    id: trackImg
                                    animateLoad: true
                                    Layout.rightMargin: 5
                                }
                                // link icon
                                PlasmaCore.IconItem {
                                    visible: linked
                                    source: "link"
                                    Layout.margins: 0
                                }
                                // status icon
                                PlasmaCore.IconItem {
                                    implicitHeight: 20
                                    implicitWidth: 20
                                    Layout.margins: 0
                                    visible: model.status === "Playing"
                                    source: "yast-green-dot"
                                }
                                PlasmaExtras.Heading {
                                    level: lvDel.ListView.isCurrentItem ? 4 : 5
                                    color: lvDel.ListView.isCurrentItem ? "black" : listTextColor
                                    text: zonename
                                    Layout.fillWidth: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        lv.currentIndex = index
                                    }
                                    acceptedButtons: Qt.RightButton | Qt.LeftButton
                                }
                            }
                            // pos display
                            PlasmaExtras.Heading {
                                anchors.right: parent.right
                                color: lvDel.ListView.isCurrentItem ? "black" : listTextColor
                                level: lvDel.ListView.isCurrentItem ? 4 : 5
                                text: "(" + positiondisplay + ")"
                            }

                            // track info
                            PlasmaComponents.Label {
                                visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
                                Layout.columnSpan: 3
                                Layout.topMargin: 2
                                color: lvDel.ListView.isCurrentItem ? "black" : listTextColor
                                text: "'" + name + "'"
                            }
                            PlasmaComponents.Label {
                                visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
                                Layout.columnSpan: 3
                                color: listTextColor
                                text: " from '" + album + "'"
                            }
                            // this crashes the viewer if it's anything but a Text, have no idea why
                            PlasmaComponents.Label {
                                visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
                                Layout.columnSpan: 3
                                color: listTextColor
                                text: " by " + artist
                            }
                            // player controls
                            Player {
                                showTrackSlider: plasmoid.configuration.showTrackSlider
                                showVolumeSlider: plasmoid.configuration.showVolumeSlider
                                visible: lvDel.ListView.isCurrentItem
                            }

                    } // delegate
                }
            }
            // Track View
            QtControls.Page {
                background: Rectangle {
                    opacity: 0
                }
                header: ColumnLayout {
                    spacing: 1
                    RowLayout {
                        PlasmaComponents.ToolButton {
                            id: searchButton
                            anchors.top: parent.top
                            anchors.left: parent.left
                            width: Math.round(units.gridUnit * .25)
                            height: width
                            checkable: true
                            iconSource: "search"
                        }
                        PlasmaExtras.Title {
                            text: {
                                if (searchButton.checked || (trackView.state === "searchMode"))
                                    "Search Media Center Tracks"
                                else
                                    lv.getObj().zonename + "/Playing Now"
                            }
                        }
                    }
                    PlasmaComponents.TextField {
                        id: search
                        visible: searchButton.checked
                        selectByMouse: true
                        clearButtonShown: true
                        font.pointSize: defaultFont.pointSize-2
                        onVisibleChanged: {
                            if (visible) forceActiveFocus()
                        }

                        onAccepted: {
                            if (search.text !== "")
                                trackModel.load("([Artist]=[%1\" or [Album]=\"%1\" or [Genre]=\"%1\")".arg(search.text.toLowerCase()))
                            else {
                                trackView.model = null
                                trackModel.load()
                                trackView.model = trackModel
                            }
                        }
                    }
                }  //header

                Viewer {
                    id: trackView
                    model: TrackModel {
                        id: trackModel
                        hostUrl: pn.hostUrl

                        /* Reset the result set, pass a search for searchMode, which will
                          disable the detailView signals.  If search is undefined/null, go back to default state.
                          */
                        function load(search)
                        {
                            if (search === undefined || search === null) {
                                trackView.state = ""
                                loadPlayingNow(lv.getObj().zoneid)
                            }
                            else {
                                trackView.state = "searchMode"
                                loadSearch(search)
                            }
                        }

                        onStatusChanged: {
                            if (status === XmlListModel.Ready)
                                trackView.highlightPlayingTrack()
                        }
                    }

                    Connections {
                        id: zoneConn
                        target: lv
                        onTrackChange: {
                            if (trackModel.count > 0 && zoneid === lv.getObj().zoneid)
                               trackView.highlightPlayingTrack()
                        }
                        onTotalTracksChange: {
                            if (trackModel.count > 0 && zoneid === lv.getObj().zoneid) {
                                trackModel.load()
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

                    function highlightPlayingTrack() {
                        if (trackView.state === "searchMode") {
                            var fk = lv.getObj().filekey
                            var i = 0
                            while (i < trackModel.count) {
                                if (fk === trackModel.get(i).filekey) {
                                    break
                                }
                                ++i
                            }
                            currentIndex = i
                            trackView.positionViewAtIndex(i, ListView.Center)
                        }
                        else {
                            var ndx = lv.getObj().playingnowposition
                            if (ndx !== undefined && (ndx >= 0 & ndx < trackModel.count) ) {
                                currentIndex = ndx
                                trackView.positionViewAtIndex(ndx, ListView.Center)
                            }
                        }
                    }

                    delegate:
                        RowLayout {
                            id: detDel
                            Layout.margins: units.smallSpacing
                            width: trackView.width
                            TrackImage { image.source: pn.imageUrl(filekey) }
                            ColumnLayout {
                                spacing: 0
                                Layout.leftMargin: 5
                                PlasmaExtras.Heading {
                                    color: detDel.ListView.isCurrentItem ? "black" : listTextColor
                                    level: detDel.ListView.isCurrentItem ? 4 : 5
                                    text: name + " / " + genre
                                 }
                                PlasmaExtras.Paragraph {
                                    color: listTextColor
                                    text: " from '" + album + "'"
                                }
                                PlasmaExtras.Paragraph {
                                    color: listTextColor
                                    text: " by " + artist
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    trackView.currentIndex = index
                                    if (mouse.button === Qt.RightButton)
                                        detailMenu.show()
                                }
                                acceptedButtons: Qt.RightButton | Qt.LeftButton
                            }
                        }
                }

            }
            // Lookups
            QtControls.Page {
                background: Rectangle {
                    opacity: 0
                }

                header: ColumnLayout {
                        PlasmaComponents.TabBar {
                            Layout.fillWidth: true
                            PlasmaComponents.TabButton {
                                text: "Artists"
                                onClicked: lookups.currentField = "Artist"
                            }
                            PlasmaComponents.TabButton {
                                text: "Albums"
                                onClicked: lookups.currentField = "Album"
                            }
                            PlasmaComponents.TabButton {
                                text: "Genres"
                                onClicked: lookups.currentField = "Genre"
                            }
                            PlasmaComponents.TabButton {
                                text: "Tracks"
                                onClicked: lookups.currentField = "Name"
                            }
                        }
                        SearchBar {
                            list: lookups
                            modelItem: "value"
                            Layout.alignment: Qt.AlignCenter
                        }
                    }

                Viewer {
                    id: lookups
                    model: LookupModel {
                        id: lookupModel
                        hostUrl: pn.hostUrl
                    }

                    spacing: 1
                    property string currentField: ""
                    onCurrentFieldChanged: lookupModel.load(currentField)

                    delegate: RowLayout {
                        id: lkDel
                        width: parent.width
                        PlasmaComponents.ToolButton {
                            iconSource: "media-playback-start"
                            flat: false
                            onClicked: {
                                pn.searchAndPlayNow("[%1]=[%2]".arg(lookups.currentField).arg(value), true, lv.currentIndex)
                                event.singleShot(250, function() { mainView.currentIndex = 1 } )
                            }
                        }
                        PlasmaComponents.ToolButton {
                            iconSource: "list-add"
                            flat: false
                            onClicked: {
                                pn.searchAndAdd("[%1]=\"%2\"".arg(lookups.currentField).arg(value), false, lv.currentIndex)
                            }
                        }
                        PlasmaExtras.Heading {
                            color: lkDel.ListView.isCurrentItem ? "black" : listTextColor
                            level: lkDel.ListView.isCurrentItem ? 4 : 5
                            text: value
                            Layout.fillWidth: true
                            MouseArea {
                                anchors.fill: parent
                                onClicked: lookups.currentIndex = index
                            }
                        }
                    } // delegate
                } // viewer
            }
        }

        QtControls.PageIndicator {
            count: mainView.count
            currentIndex: mainView.currentIndex
            Layout.alignment: Qt.AlignHCenter
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
            currObj = trackView.getObj()
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
                if (trackView.state === "searchMode") {
                    pn.playTrackByKey(trackView.getObj().filekey, lv.currentIndex)
                }
                else
                    pn.playTrack(trackView.currentIndex, lv.currentIndex)
            }
        }
        MenuItem {
            text: "Remove Track"
            onTriggered: pn.removeTrack(trackView.currentIndex, lv.currentIndex)
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
                onTriggered: trackModel.load("album=%1 and artist=%2".arg(detailMenu.currObj.album).arg(detailMenu.currObj.artist))
            }
            MenuItem {
                id: showArtist
                onTriggered: trackModel.load("artist=" + detailMenu.currObj.artist)
            }
            MenuItem {
                id: showGenre
                onTriggered: trackModel.load("genre=" + detailMenu.currObj.genre)
            }
        }

        MenuSeparator{}
        MenuItem {
            text: "Reset"
            onTriggered: {
                trackModel.load()
            }
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

    Component.onCompleted: {
        if (plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            plasmoid.activationTogglesExpanded = true
        }

        plasmoid.setAction("power", i18n("Power Settings..."), "utilities-energy-monitor");
        plasmoid.setAction("screens", i18n("Configure Screens..."), "video-display");
        plasmoid.setAction("pulse", i18n("PulseAudio Settings..."), "audio-volume-medium");
        plasmoid.setAction("mpvconf", i18n("Configure MPV..."), "mpv");
        plasmoid.setActionSeparator("sep")

        plasmoid.icon = "multimedia-player"
    }
}
