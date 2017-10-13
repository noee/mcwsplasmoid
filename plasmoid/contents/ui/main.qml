import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

import Qt.labs.platform 1.0
import QtQuick.XmlListModel 2.0

import "models"

Item {

    Plasmoid.switchWidth: theme.mSize(theme.defaultFont).width * 10
    Plasmoid.switchHeight: theme.mSize(theme.defaultFont).height * 15

    Plasmoid.fullRepresentation: Item {

        id: fullView

        property bool abbrevZoneView: plasmoid.configuration.abbrevZoneView
        property bool autoShuffle: plasmoid.configuration.autoShuffle

        width: units.gridUnit * 28
        height: units.gridUnit * 23

        function tryConnect(host) {
            lv.model = ""
            mcws.connectionReady.connect(newConnection)
            mcws.connect(host.indexOf(':') === -1 ? host + ":52199" : host)
        }
        function newConnection(currZoneIndex) {
            mcws.connectionReady.disconnect(newConnection)
            var list = mcws.zonesByStatus("Playing")
            lv.model = mcws.model
            lv.currentIndex = list.length>0 ? list[list.length-1] : currZoneIndex
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
                if (plasmoid.expanded)
                    tryConnect(hostList.currentText)
            }
        }

        SingleShot {
            id: event
        }

        McwsConnection {
            id: mcws
            timer.interval: 1000*plasmoid.configuration.updateInterval
        }

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
                        spacing: 0
                        PlasmaExtras.Title {
                            text: (lv.currentIndex >= 0 ? lv.getObj().zonename : "") + "/Playlists"
                        }
                        PlasmaComponents.ButtonRow {
                            PlasmaComponents.Button {
                                id: first
                                text: "All"
                                checked: true
                                width: units.gridUnit * 5.5
                                onClicked: playlistModel.filterType = text
                            }
                            PlasmaComponents.Button {
                                text: "Smartlists"
                                width: first.width
                                onClicked: playlistModel.filterType = text
                            }
                            PlasmaComponents.Button {
                                text: "Playlists"
                                width: first.width
                                onClicked: playlistModel.filterType = text
                            }
                            PlasmaComponents.Button {
                                text: "Groups"
                                width: first.width
                                onClicked: playlistModel.filterType = text
                            }
                            Layout.bottomMargin: 5
                        }
                    }

                    PlaylistModel {
                        id: playlistModel
                        hostUrl: mcws.hostUrl
                    }

                    Viewer {
                        id: playlistView
                        model: playlistModel.model

                        spacing: 1
                        delegate: RowLayout {
                            id: plDel
                            width: parent.width
                            PlayButton {
                                onClicked: {
                                    mcws.playPlaylist(id, autoShuffle, lv.currentIndex)
                                    event.singleShot(500, function() { mainView.currentIndex = 1 } )
                                }
                            }
                            AddButton {
                                onClicked: {
                                    mcws.addPlaylist(id, autoShuffle, lv.currentIndex)
                                    event.singleShot(500, function()
                                    {
                                        mainView.currentIndex = 1
                                        event.singleShot(1000, function()
                                        {
                                            if (trackModel.count > 0)
                                                trackView.reset()
                                        })
                                    })
                                }
                            }

                            PlasmaExtras.Heading {
                                level: plDel.ListView.isCurrentItem ? 4 : 5
                                text: name + " / " + type
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
                            implicitHeight: units.gridUnit*1.75
                            model: plasmoid.configuration.hostList.split(';')
                            onActivated: fullView.tryConnect(currentText)
                        }
                    }

                    Viewer {
                        id: lv

                        onCurrentItemChanged: trackModel.source = ""

                        delegate:
                            GridLayout {
                                id: lvDel
                                width: lv.width
                                columns: 3
                                rowSpacing: 1

                                // For changes to playback playlist
                                property string trackKey: filekey
                                property string trackPosition: playingnowposition
                                property string pnChangeCtr: playingnowchangecounter

                                // A new track is now playing
                                onTrackKeyChanged: {
                                    trackImg.image.source = mcws.imageUrl(filekey, 'medium')
                                    // Splash if playing
                                    if (plasmoid.configuration.showTrackSplash && model.status === "Playing")
                                        event.singleShot(500, function() { trackSplash.go(mcws.model.get(index), trackImg.image.source) })
                                }
                                // We've moved onto another track in the playing now
                                onTrackPositionChanged: {
                                    if (!trackView.searchMode && trackModel.count > 0 && zoneid === lv.getObj().zoneid)
                                        trackView.highlightPlayingTrack()
                                }
                                // The playing now list has been changed
                                onPnChangeCtrChanged: {
                                    if (!trackView.searchMode && zoneid === lv.getObj().zoneid) {
                                        if (trackModel.count > 0)
                                            trackView.reset()
                                        else if (mainView.currentIndex === 2 )
                                            trackView.reset()
                                    }
                                }

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
                                    level: lvDel.ListView.isCurrentItem ? 4 : 5
                                    text: "(" + positiondisplay + ")"
                                }

                                // track info
                                PlasmaComponents.Label {
                                    visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
                                    Layout.columnSpan: 3
                                    Layout.topMargin: 2
                                    text: "'" + name + "'"
                                }
                                PlasmaComponents.Label {
                                    visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
                                    Layout.columnSpan: 3
                                    text: " from '" + album + "'"
                                }
                                // this crashes the viewer if it's anything but a Text, have no idea why
                                PlasmaComponents.Label {
                                    visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
                                    Layout.columnSpan: 3
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
                                    if (!checked & trackView.searchMode)
                                        trackView.reset()
                                }
                            }
                            PlasmaExtras.Title {
                                text: {
                                    if (searchButton.checked || trackView.searchMode)
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
                                font.pointSize: theme.defaultFont.pointSize-1
                                onVisibleChanged: {
                                    if (visible) forceActiveFocus()
                                }

                                onAccepted: {
                                    if (search.text !== "") {
                                        var startsWith = search.text.length === 1 ? "[" : "\""
                                        trackView.reset("([Name]=%2%1\" \
                                                        or [Artist]=%2%1\" \
                                                        or [Album]=%2%1\" \
                                                        or [Genre]=%2%1\")".arg(search.text.toLowerCase()).arg(startsWith))
                                        }
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
                                onClicked: mcws.searchAndPlayNow(trackView.mcwsQuery, autoShuffle, lv.currentIndex)
                            }
                            AddButton {
                                visible: searchButton.checked
                                enabled: trackView.mcwsQuery !== ""
                                onClicked: mcws.searchAndAdd(trackView.mcwsQuery, false, autoShuffle, lv.currentIndex)
                            }
                        }
                    }  //header

                    Viewer {
                        id: trackView

                        property string mcwsQuery
                        property bool searchMode: false

                        model: TrackModel {
                            id: trackModel
                            hostUrl: mcws.hostUrl
                            onStatusChanged: {
                                if (status === XmlListModel.Ready)
                                    trackView.highlightPlayingTrack()
                            }
                        }

                        function highlightPlayingTrack()
                        {
                            if (trackView.searchMode) {
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
                        /* Reset the view model, pass a search to set searchMode, which will
                          disable the track change/highlight signals.  If search is undefined/null, go back to default mode.
                          */
                        function reset(search)
                        {
                            if (search === undefined || search === null) {
                                trackView.searchMode = false
                                mcwsQuery = ""
                                trackModel.loadPlayingNow(lv.getObj().zoneid)
                            }
                            else {
                                trackView.searchMode = true
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
                                        level: detDel.ListView.isCurrentItem ? 4 : 5
                                        text: name + " / " + genre
                                     }
                                    PlasmaExtras.Heading {
                                        level: 5
                                        text: " from '" + album + "'"
                                    }
                                    PlasmaExtras.Heading {
                                        level: 5
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
                                    mcws.searchAndPlayNow("[%1]=[%2]".arg(lookupModel.queryField).arg(value), autoShuffle, lv.currentIndex)
                                    event.singleShot(250, function() { mainView.currentIndex = 1 } )
                                }
                            }
                            AddButton {
                                onClicked: {
                                    mcws.searchAndAdd("[%1]=\"%2\"".arg(lookupModel.queryField).arg(value), false, autoShuffle, lv.currentIndex)
                                }
                            }

                            PlasmaExtras.Heading {
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
                onTriggered: {
                    mcws.shuffle(lv.currentIndex)
                    trackModel.source = ""
                }
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
                    if (trackView.searchMode) {
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
                    onTriggered: mcws.searchAndPlayNow("artist=" + detailMenu.currObj.artist, autoShuffle, lv.currentIndex)
                }
                MenuItem {
                    id: playGenre
                    onTriggered: mcws.searchAndPlayNow("genre=" + detailMenu.currObj.genre, autoShuffle, lv.currentIndex)
                }
                MenuSeparator{}
                MenuItem {
                    text: "Current List"
                    enabled: trackView.searchMode
                    onTriggered: mcws.searchAndPlayNow(trackView.mcwsQuery, autoShuffle, lv.currentIndex)
                }
            }
            Menu {
                id: addMenu
                title: "Add"
                MenuItem {
                    id: addAlbum
                    onTriggered: mcws.searchAndAdd("album=[%1] and artist=[%2]".arg(detailMenu.currObj.album).arg(detailMenu.currObj.artist)
                                                 , false, autoShuffle, lv.currentIndex)
                }
                MenuItem {
                    id: addArtist
                    onTriggered: mcws.searchAndAdd("artist=" + detailMenu.currObj.artist, false, autoShuffle, lv.currentIndex)
                }
                MenuItem {
                    id: addGenre
                    onTriggered: mcws.searchAndAdd("genre=" + detailMenu.currObj.genre, false, autoShuffle, lv.currentIndex)
                }
                MenuSeparator{}
                MenuItem {
                    text: "Current List"
                    enabled: trackView.searchMode
                    onTriggered: mcws.searchAndAdd(trackView.mcwsQuery, false, autoShuffle, lv.currentIndex)
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

        Splash {
            id: trackSplash
            animate: plasmoid.configuration.animateTrackSplash
        }

        } //full rep

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
