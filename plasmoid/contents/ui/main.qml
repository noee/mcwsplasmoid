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
    property bool abbrevZoneView: plasmoid.configuration.abbrevZoneView

    function tryConnect(host) {
        lv.model = ""
        mcws.connectionReady.connect(newConnection)
        mcws.init(host.indexOf(':') === -1 ? host + ":52199" : host)
    }
    function newConnection() {
        mcws.connectionReady.disconnect(newConnection)
        lv.model = mcws.model
        lv.currentIndex = -1

        event.singleShot(100, function()
        {
            var list = mcws.zonesByStatus("Playing")
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
        id: mcws
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
                if (currentIndex === 2)
                    if (trackModel.count === 0)
                        trackView.reset()
            }

            // Playlist View
            QtControls.Page {
                background: Rectangle {
                    opacity: 0
                }
                header: ColumnLayout {
                    PlasmaExtras.Title {
                        text: (lv.currentIndex >= 0 ? lv.getObj().zonename : "") + "/Playlists"

                    }
//                    SearchBar {
//                        list: playlistView
//                        modelItem: "name"
//                        Layout.alignment: Qt.AlignCenter
//                    }
                }

                Viewer {
                    id: playlistView
                    model: PlaylistModel {
                        id: playlistModel
                        hostUrl: mcws.hostUrl
                    }

                    spacing: 1
                    delegate: RowLayout {
                        id: plDel
                        width: parent.width
                        PlayButton {
                            onClicked: {
                                mcws.playPlaylist(id, lv.currentIndex)
                                event.singleShot(250, function() { mainView.currentIndex = 1 } )
                            }
                        }
                        AddButton {
                            onClicked: {
                                mcws.addPlaylist(id, lv.currentIndex)
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
                        onActivated: tryConnect(currentText)
                    }
                }

                Viewer {
                    id: lv

                    onCurrentItemChanged: trackModel.source = ""

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
                                trackImg.image.source = mcws.imageUrl(filekey, 'large')
                                if (plasmoid.configuration.showTrackSplash && model.status === "Playing")
                                    event.singleShot(500, function() { trackSplash.go(mcws.model.get(index), trackImg.image.source) })
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
                            onClicked: {
                                if (!checked & trackView.state === "searchMode")
                                    trackView.reset()
                            }
                        }
                        PlasmaExtras.Title {
                            text: {
                                if (searchButton.checked || (trackView.state === "searchMode"))
                                    "Search Media Center Tracks"
                                else
                                    (lv.currentIndex >= 0 ? lv.getObj().zonename : "") + "/Playing Now"
                            }
                        }
                    }
                    RowLayout {
                        PlasmaComponents.TextField {
                            id: search
                            visible: searchButton.checked
                            selectByMouse: true
                            clearButtonShown: true
                            font.pointSize: theme.defaultFont.pointSize-2
                            onVisibleChanged: {
                                if (visible) forceActiveFocus()
                            }

                            onAccepted: {
                                if (search.text !== "")
                                    trackView.reset("([Name]=\"%1\" \
                                                    or [Artist]=\"%1\" \
                                                    or [Album]=\"%1\" \
                                                    or [Genre]=\"%1\")".arg(search.text.toLowerCase()))
                                else {
                                    //FIXME: some weird painting issues occur if not setting null first
                                    trackView.model = null
                                    trackView.reset()
                                    trackView.model = trackModel
                                }
                            }
                        }
                        PlayButton {
                            visible: searchButton.checked
                            enabled: trackView.mcwsQuery !== ""
                            onClicked: mcws.searchAndPlayNow(trackView.mcwsQuery, true, lv.currentIndex)
                        }
                        AddButton {
                            visible: searchButton.checked
                            enabled: trackView.mcwsQuery !== ""
                            onClicked: mcws.searchAndAdd(trackView.mcwsQuery, false, lv.currentIndex)
                        }
                    }
                }  //header

                Viewer {
                    id: trackView

                    property string mcwsQuery

                    model: TrackModel {
                        id: trackModel
                        hostUrl: mcws.hostUrl
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
                            if (trackModel.count > 0 && zoneid === lv.getObj().zoneid)
                                trackView.reset()
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

                    function highlightPlayingTrack()
                    {
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
                    /* Reset the view model, pass a search sets state to searchMode, which will
                      disable the update/highlight signals.  If search is undefined/null, go back to default state.
                      */
                    function reset(search)
                    {
                        if (search === undefined || search === null) {
                            state = ""
                            mcwsQuery = ""
                            trackModel.loadPlayingNow(lv.getObj().zoneid)
                        }
                        else {
                            state = "searchMode"
                            mcwsQuery = search
                            trackModel.loadSearch(search)
                        }
                    }

                    delegate:
                        RowLayout {
                            id: detDel
                            Layout.margins: units.smallSpacing
                            width: trackView.width
                            TrackImage { image.source: mcws.imageUrl(filekey) }
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
                                onClicked: lookupModel.queryField = "Artist"
                            }
                            PlasmaComponents.TabButton {
                                text: "Albums"
                                onClicked: lookupModel.queryField = "Album"
                            }
                            PlasmaComponents.TabButton {
                                text: "Genres"
                                onClicked: lookupModel.queryField = "Genre"
                            }
                            PlasmaComponents.TabButton {
                                text: "Tracks"
                                onClicked: lookupModel.queryField = "Name"
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
                        hostUrl: mcws.hostUrl
                    }

                    spacing: 1

                    delegate: RowLayout {
                        id: lkDel
                        width: parent.width
                        PlayButton {
                            onClicked: {
                                mcws.searchAndPlayNow("[%1]=[%2]".arg(lookupModel.queryField).arg(value), true, lv.currentIndex)
                                event.singleShot(250, function() { mainView.currentIndex = 1 } )
                            }
                        }
                        AddButton {
                            onClicked: {
                                mcws.searchAndAdd("[%1]=\"%2\"".arg(lookupModel.queryField).arg(value), false, lv.currentIndex)
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
            open(x, y)
        }
        function showAt(item) {
            linkMenu.loadActions()
            open(item)
        }

        function newMenuItem(parent) {
            return Qt.createQmlObject("import Qt.labs.platform 1.0; MenuItem { property var id; property var index }", parent);
        }

        MenuItem {
            text: "Reshuffle"
            iconName: "shuffle"
            onTriggered: mcws.shuffle(lv.currentIndex)
        }
        Menu {
            id: repeatMenu
            title: "Repeat Mode"

            MenuItem {
                checkable: true
                text: "Playlist"
                checked: mcws.isConnected && (mcws.repeatMode(lv.currentIndex) === text)
                onTriggered: mcws.setRepeat(text, lv.currentIndex)
            }
            MenuItem {
                checkable: true
                text: "Track"
                checked: mcws.repeatMode(lv.currentIndex) === text
                onTriggered: mcws.setRepeat(text, lv.currentIndex)
            }
            MenuItem {
                checkable: true
                text: "Off"
                checked: mcws.repeatMode(lv.currentIndex) === text
                onTriggered: mcws.setRepeat(text, lv.currentIndex)
            }
        }

        MenuSeparator{}
        Menu {
            id: linkMenu
            title: "Link to"
            iconName: "link"

            function loadActions() {
                if (mcws.model.count < 2) {
                    linkMenu.visible = false
                    return
                }

                linkMenu.visible = true
                clear()

                var currId = lv.getObj().zoneid
                var zonelist = lv.getObj().linkedzones !== undefined ? lv.getObj().linkedzones.split(';') : []
                var zones = mcws.zoneModel

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
                items: linkMenu.items
                exclusive: false
                onTriggered: {
                    if (item.checked) {
                        mcws.unLinkZone(lv.currentIndex)
                    }
                    else {
                        mcws.linkZones(lv.getObj().zoneid, item.id)
                        // try to get a visual...there is a goodly pause when MC links/syncs zones
                        event.singleShot(mcws.timer.interval/2, function()
                        {
                            mcws.updateModelItem(lv.currentIndex)
                            mcws.updateModelItem(item.index)
                        })
                    }
                }
            }
        }
        MenuSeparator{}
        MenuItem {
            text: "Stop All Zones"
            iconName: "edit-clear"
            onTriggered: mcws.stopAllZones()
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
            // add menu
            addAlbum.text = i18n("Album\t\"%1\"".arg(currObj.album))
            addArtist.text = i18n("Artist\t\"%1\"".arg(currObj.artist))
            addGenre.text = i18n("Genre\t\"%1\"".arg(currObj.genre))
            // show menu
            showAlbum.text = i18n("Album\t\"%1\"".arg(currObj.album))
            showArtist.text = i18n("Artist\t\"%1\"".arg(currObj.artist))
            showGenre.text = i18n("Genre\t\"%1\"".arg(currObj.genre))
        }

        MenuItem {
            text: "Play Track"
            onTriggered: {
                if (trackView.state === "searchMode") {
                    mcws.playTrackByKey(trackView.getObj().filekey, lv.currentIndex)
                }
                else
                    mcws.playTrack(trackView.currentIndex, lv.currentIndex)
            }
        }
        MenuItem {
            text: "Remove Track"
            onTriggered: mcws.removeTrack(trackView.currentIndex, lv.currentIndex)
        }
        MenuSeparator{}
        Menu {
            id: playMenu
            title: "Play"
            MenuItem {
                id: playAlbum
                onTriggered: mcws.playAlbum(detailMenu.currObj.filekey, lv.currentIndex)
            }
            MenuItem {
                id: playArtist
                onTriggered: mcws.searchAndPlayNow("artist=" + detailMenu.currObj.artist, true, lv.currentIndex)
            }
            MenuItem {
                id: playGenre
                onTriggered: mcws.searchAndPlayNow("genre=" + detailMenu.currObj.genre, true, lv.currentIndex)
            }
            MenuSeparator{}
            MenuItem {
                text: "Current List"
                enabled: trackView.state === "searchMode"
                onTriggered: mcws.searchAndPlayNow(trackView.mcwsQuery, true, lv.currentIndex)
            }
        }
        Menu {
            id: addMenu
            title: "Add"
            MenuItem {
                id: addAlbum
                onTriggered: mcws.searchAndAdd("album=[%1] and artist=[%2]".arg(detailMenu.currObj.album).arg(detailMenu.currObj.artist)
                                             , false, lv.currentIndex)
            }
            MenuItem {
                id: addArtist
                onTriggered: mcws.searchAndAdd("artist=" + detailMenu.currObj.artist, false, lv.currentIndex)
            }
            MenuItem {
                id: addGenre
                onTriggered: mcws.searchAndAdd("genre=" + detailMenu.currObj.genre, false, lv.currentIndex)
            }
            MenuSeparator{}
            MenuItem {
                text: "Current List"
                enabled: trackView.state === "searchMode"
                onTriggered: mcws.searchAndAdd(trackView.mcwsQuery, false, lv.currentIndex)
            }
        }
        Menu {
            id: showMenu
            title: "Show"
            MenuItem {
                id: showAlbum
                onTriggered: trackView.reset("album=[%1] and artist=[%2]".arg(detailMenu.currObj.album).arg(detailMenu.currObj.artist))
            }
            MenuItem {
                id: showArtist
                onTriggered: trackView.reset("artist=" + detailMenu.currObj.artist)
            }
            MenuItem {
                id: showGenre
                onTriggered: trackView.reset("genre=" + detailMenu.currObj.genre)
            }
        }

        MenuSeparator{}
        MenuItem {
            text: "Reset"
            onTriggered: trackView.reset()
        }
        MenuItem {
            text: "Clear Playing Now"
            onTriggered: mcws.clearPlaylist(lv.currentIndex)
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
        if (mcws.isConnected) {
            if (plasmoid.expanded)
                mcws.timer.interval = 1000*plasmoid.configuration.updateInterval
            else
                mcws.timer.interval = 5000
            mcws.timer.restart()
        }
        else {
            // Startup and recovery from loss of connection
            if (plasmoid.expanded & plasmoid.configuration.autoConnect)
                event.singleShot(250, function() { tryConnect(hostList.currentText) })
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
