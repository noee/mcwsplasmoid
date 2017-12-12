import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

import Qt.labs.platform 1.0

import "models"

Item {

    id: root

    property var hostModel: plasmoid.configuration.hostList
    property bool advTrayView: plasmoid.configuration.advancedTrayView
    property int trayViewSize: plasmoid.configuration.trayViewSize

    property bool vertical: (plasmoid.formFactor === PlasmaCore.Types.Vertical)
    property int currentZone: -1

    // Triggered at startup when the config sets the hostModel,
    // so is basically an auto-connect, regardless of view mode.
    // Additionally, catches changes to the host setup configuration.
    onHostModelChanged: {
        if (hostModel.length === 0) {
            if (mcws.isConnected)
                mcws.closeConnection()
        } else {
            mcws.tryConnect(hostModel[0])
        }
    }

    Component {
        id: advComp
        CompactView {
            onZoneClicked: {
                currentZone = zonendx
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
                onClicked: plasmoid.expanded = !plasmoid.expanded
            }
        }
    }

    Plasmoid.switchWidth: theme.mSize(theme.defaultFont).width * 28
    Plasmoid.switchHeight: theme.mSize(theme.defaultFont).height * 15

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: Loader {

        Layout.preferredWidth: (advTrayView && !vertical)
                                ? theme.mSize(theme.defaultFont).width * trayViewSize
                                : units.iconSizes.small

        sourceComponent: {
            if (mcws.isConnected)
                return (advTrayView && !vertical) ? advComp : iconComp
            else
                return iconComp
        }
    }

    Plasmoid.fullRepresentation: Item {

        property bool abbrevZoneView: plasmoid.configuration.abbrevZoneView
        property bool abbrevTrackView: plasmoid.configuration.abbrevTrackView
        property bool autoShuffle: plasmoid.configuration.autoShuffle

        width: units.gridUnit * 28
        height: units.gridUnit * 23

        // For some reason, the Connections Item will not work inside of fullRep Item,
        // so do it manually.
        function connect() {
            lv.model = ""
            mcws.tryConnect(hostList.currentText)
        }
        function handleConnection(zonendx) {
            var list = mcws.zonesByState(mcws.statePlaying)
            lv.model = mcws.zoneModel
            lv.currentIndex = list.length>0 ? list[list.length-1] : zonendx
        }
        Component.onCompleted: mcws.connectionReady.connect(handleConnection)

        // HACK:  mcws.model cannot be bound directly as there are some GUI/timing issues,
        // so we set and unset (with connect) onto the event loop and catch the full view
        // visible.  Plasmoid.onExpandedChanged comes too late.
        onVisibleChanged: {
            if (mcws.isConnected)
            {
                if (visible)
                {
                    if (lv.model === undefined)
                        lv.model = mcws.zoneModel

                    // This means we've gotten a click from CV (see component above)
                    if (advTrayView) {
                        Qt.callLater(function()
                        {
                            if (currentZone != -1)
                                lv.currentIndex = currentZone
                            else {
                                var list = mcws.zonesByState(mcws.statePlaying)
                                lv.currentIndex = list.length>0 ? list[list.length-1] : 0
                            }

                            // if popup to the track view, show tracks
                            Qt.callLater(function() {
                                if (mainView.currentIndex === 2 && trackModel.count === 0)
                                    trackView.reset()
                            })
                        })
                    }
                }

                mcws.pollerInterval = visible ? (1000 * plasmoid.configuration.updateInterval) : 3000

            } else {
                if (visible)
                    Qt.callLater(connect)
            }
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
                    if (mcws.isConnected) {
                        if (currentIndex === 0 & playlistView.count === 0)
                            mcws.playlists.filterType = "all"
                        else if (currentIndex === 2)
                            if (trackModel.count === 0)
                                trackView.reset()
                    }
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
                                onClicked: mcws.playlists.filterType = text
                            }
                            PlasmaComponents.Button {
                                text: "Smartlists"
                                width: first.width
                                onClicked: mcws.playlists.filterType = text
                            }
                            PlasmaComponents.Button {
                                text: "Playlists"
                                width: first.width
                                onClicked: mcws.playlists.filterType = text
                            }
                            PlasmaComponents.Button {
                                text: "Groups"
                                width: first.width
                                onClicked: mcws.playlists.filterType = text
                            }
                            Layout.bottomMargin: 5
                        }
                    }

                    Viewer {
                        id: playlistView
                        model: mcws.playlists.model
                        spacing: 1
                        delegate: RowLayout {
                            id: plDel
                            width: parent.width
                            PlayButton {
                                onClicked: {
                                    mcws.playlists.play(lv.currentIndex, id, autoShuffle)
                                    event.singleShot(500, function() { mainView.currentIndex = 1 } )
                                }
                            }
                            AddButton {
                                onClicked: {
                                    mcws.playlists.add(lv.currentIndex, id, autoShuffle)
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
                            model: hostModel
                            onActivated: connect()
                        }
                    }

                    Viewer {
                        id: lv

                        onCurrentIndexChanged: trackView.clear()

                        delegate:
                            GridLayout {
                                id: lvDel
                                width: lv.width
                                columns: 3
                                rowSpacing: 1

                                // For changes to playback playlist
                                property string trackPosition: playingnowposition
                                property string pnChangeCtr: playingnowchangecounter

                                // We've moved onto another track in the playing now
                                onTrackPositionChanged: {
                                    if (!trackView.searchMode && trackModel.count > 0 && index === lv.currentIndex)
                                        trackView.highlightPlayingTrack()
                                }
                                // The playing now list has been changed
                                onPnChangeCtrChanged: {
                                    if (!trackView.searchMode && index === lv.currentIndex) {
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
                                        animateLoad: true
                                        Layout.rightMargin: 5
                                        key: filekey
                                    }
                                    // link icon
                                    PlasmaCore.IconItem {
                                        visible: linked
                                        source: "link"
                                        Layout.margins: 0
                                    }
                                    // state ind
                                    Rectangle {
                                        id: stateInd
                                        implicitHeight: units.gridUnit*.7
                                        implicitWidth: units.gridUnit*.7
                                        Layout.rightMargin: 3
                                        radius: 5
                                        color: "light green"
                                        visible: !mcws.isStopped(index)
                                        NumberAnimation {
                                            running: mcws.isPaused(index)
                                            target: stateInd
                                            properties: "opacity"
                                            from: 1
                                            to: 0
                                            duration: 1500
                                            loops: Animation.Infinite
                                            onStopped: stateInd.opacity = 1
                                          }
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
                                FadeText {
                                    visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
                                    Layout.columnSpan: 3
                                    Layout.topMargin: 2
                                    Layout.leftMargin: 3
                                    aText: !mcws.isPlaylistEmpty(index)
                                           ? "'%1'\n from '%2' \n by %3".arg(name).arg(album).arg(artist)
                                           : '<empty playlist>'
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
                                    if (visible)
                                        forceActiveFocus()
                                }

                                onAccepted: {
                                    var sstr = ''
                                    // One char will be a "starts with" search, ignore genre
                                    if (search.text.length === 1)
                                        sstr = '([Name]=[%1" or [Artist]=[%1" or [Album]=[%1")'.arg(search.text.toLowerCase())
                                    else if (search.text.length > 1)
                                        sstr = '([Name]="%1" or [Artist]="%1" or [Album]="%1" or [Genre]="%1")'.arg(search.text.toLowerCase())

                                    trackView.reset(sstr)
                                }
                            }
                            PlayButton {
                                visible: searchButton.checked
                                enabled: trackView.mcwsQuery !== '' & trackModel.count > 0
                                onClicked: mcws.searchAndPlayNow(lv.currentIndex, trackView.mcwsQuery, autoShuffle)
                            }
                            AddButton {
                                visible: searchButton.checked
                                enabled: trackView.mcwsQuery !== '' & trackModel.count > 0
                                onClicked: mcws.searchAndAdd(lv.currentIndex, trackView.mcwsQuery, false, autoShuffle)
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
                            onResultsReady: trackView.highlightPlayingTrack()
                        }

                        function highlightPlayingTrack()
                        {
                            if (trackView.searchMode) {
                                var fk = lv.getObj().filekey
                                for (var i=0, len = trackModel.count; i<len; ++i) {
                                    if (fk === trackModel.get(i).filekey) {
                                        currentIndex = i
                                        trackView.positionViewAtIndex(i, ListView.Center)
                                        return
                                    }
                                }
                                currentIndex = 0
                                trackView.positionViewAtIndex(0, ListView.Beginning)
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
                                mcwsQuery = ''
                                trackModel.loadPlayingNow(lv.getObj().zoneid)
                            }
                            else {
                                trackView.searchMode = true
                                mcwsQuery = search
                                trackModel.loadSearch(search)
                            }
                        }

                        function formatDuration(dur) {
                            var num = dur.split('.')[0]
                            return "(%1:%2) ".arg(Math.floor(num / 60)).arg(String((num % 60) + '00').substring(0,2))
                        }

                        function clear() {
                            trackModel.source = ''
                        }

                        delegate:
                            RowLayout {
                                id: detDel
                                Layout.margins: units.smallSpacing
                                width: trackView.width

                                TrackImage { key: filekey }
                                ColumnLayout {
                                    spacing: 0
                                    PlasmaExtras.Heading {
                                        level: detDel.ListView.isCurrentItem ? 4 : 5
                                        text: "%1%2 / %3".arg(detDel.ListView.isCurrentItem
                                                              ? trackView.formatDuration(duration)
                                                              : "").arg(name).arg(genre)
                                        font.italic: detDel.ListView.isCurrentItem
                                     }
                                    PlasmaExtras.Heading {
                                        visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                                        level: 5
                                        text: " from '%1'\n by %2".arg(album).arg(artist)
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
                                    mcws.searchAndPlayNow(lv.currentIndex, "[%1]=[%2]".arg(lookupModel.queryField).arg(value), autoShuffle)
                                    event.singleShot(250, function() { mainView.currentIndex = 1 } )
                                }
                            }
                            AddButton {
                                onClicked: {
                                    mcws.searchAndAdd(lv.currentIndex,"[%1]=\"%2\"".arg(lookupModel.queryField).arg(value), false, autoShuffle)
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

            function showAt(item) {
                linkMenu.loadActions()
                open(item)
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
                    onTriggered: mcws.setRepeat(lv.currentIndex, text)
                }
                MenuItem {
                    checkable: true
                    text: "Track"
                    checked: mcws.repeatMode(lv.currentIndex) === text
                    onTriggered: mcws.setRepeat(lv.currentIndex, text)
                }
                MenuItem {
                    checkable: true
                    text: "Off"
                    checked: mcws.repeatMode(lv.currentIndex) === text
                    onTriggered: mcws.setRepeat(lv.currentIndex, text)
                }
            }

            MenuSeparator{}
            Menu {
                id: linkMenu
                title: "Link to"
                iconName: "link"

                function loadActions() {
                    if (mcws.zoneModel.count < 2) {
                        linkMenu.visible = false
                        return
                    }

                    linkMenu.visible = true
                    clear()

                    var z = lv.getObj()
                    var zonelist = z.linkedzones !== undefined ? z.linkedzones.split(';') : []

                    mcws.forEachZone(function(zone)
                    {
                        if (z.zoneid !== zone.zoneid)
                        {
                            var menuItem = Qt.createQmlObject("import Qt.labs.platform 1.0; MenuItem { property var id; checkable: true }", linkMenu)
                            menuItem.id = zone.zoneid
                            menuItem.text = i18n(zone.zonename);
                            menuItem.checked = zonelist.indexOf(zone.zoneid) !== -1
                            linkMenu.addItem(menuItem);
                        }
                    })
                }

                MenuItemGroup {
                    items: linkMenu.items
                    exclusive: false
                    onTriggered: {
                        if (item.checked)
                            mcws.unLinkZone(lv.currentIndex)
                        else
                            mcws.linkZones(lv.getObj().zoneid, item.id)
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
                        mcws.playTrackByKey(lv.currentIndex, trackView.getObj().filekey)
                    }
                    else
                        mcws.playTrack(lv.currentIndex, trackView.currentIndex)
                }
            }
            MenuItem {
                text: "Add Track"
                onTriggered: mcws.addTrack(lv.currentIndex, trackView.getObj().filekey, false)
            }

            MenuItem {
                text: "Remove Track"
                enabled: !trackView.searchMode
                onTriggered: mcws.removeTrack(lv.currentIndex, trackView.currentIndex)
            }
            MenuSeparator{}
            Menu {
                id: playMenu
                title: "Play"
                MenuItem {
                    id: playAlbum
                    onTriggered: mcws.playAlbum(lv.currentIndex, detailMenu.currObj.filekey)
                }
                MenuItem {
                    id: playArtist
                    onTriggered: mcws.searchAndPlayNow(lv.currentIndex, "artist=" + detailMenu.currObj.artist, autoShuffle)
                }
                MenuItem {
                    id: playGenre
                    onTriggered: mcws.searchAndPlayNow(lv.currentIndex, "genre=" + detailMenu.currObj.genre, autoShuffle)
                }
                MenuSeparator{}
                MenuItem {
                    text: "Current List"
                    enabled: trackView.searchMode
                    onTriggered: mcws.searchAndPlayNow(lv.currentIndex, trackView.mcwsQuery, autoShuffle)
                }
            }
            Menu {
                id: addMenu
                title: "Add"
                MenuItem {
                    id: addAlbum
                    onTriggered: mcws.searchAndAdd(lv.currentIndex, "album=[%1] and artist=[%2]".arg(detailMenu.currObj.album).arg(detailMenu.currObj.artist)
                                                 , false, autoShuffle)
                }
                MenuItem {
                    id: addArtist
                    onTriggered: mcws.searchAndAdd(lv.currentIndex, "artist=" + detailMenu.currObj.artist, false, autoShuffle)
                }
                MenuItem {
                    id: addGenre
                    onTriggered: mcws.searchAndAdd(lv.currentIndex, "genre=" + detailMenu.currObj.genre, false, autoShuffle)
                }
                MenuSeparator{}
                MenuItem {
                    text: "Current List"
                    enabled: trackView.searchMode
                    onTriggered: mcws.searchAndAdd(lv.currentIndex, trackView.mcwsQuery, false, autoShuffle)
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

    } //full rep

    Splash {
        id: splasher
        animate: plasmoid.configuration.animateTrackSplash
    }

    SingleShot { id: event }

    McwsConnection {
        id: mcws
        pollerInterval: 1000*plasmoid.configuration.updateInterval

        function tryConnect(host) {
            currentZone = -1
            connect(host.indexOf(':') === -1
                    ? '%1:%2'.arg(host).arg(plasmoid.configuration.defaultPort)
                    : host)
        }

        onConnectionError: closeConnection()
        onTrackKeyChanged: {
            if (plasmoid.configuration.showTrackSplash)
                splasher.go(zoneModel.get(zonendx), imageUrl(trackKey, 'medium'))
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
    }
}
