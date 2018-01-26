import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

import Qt.labs.platform 1.0

import "models"
import "controls"

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
                                    trackView.populate()
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

                // Playlist View
                QtControls.Page {
                    background: Rectangle {
                        opacity: 0
                    }
                    header: ColumnLayout {
                        spacing: 1
                        PlasmaExtras.Title {
                            text: "Playlists/" + (lv.currentIndex >= 0 ? lv.getObj().zonename : "")
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

                    onFocusChanged: {
                        if (focus && mcws.isConnected) {
                            if (playlistView.count === 0)
                                mcws.playlists.filterType = "all"
                        }
                    }

                    Viewer {
                        id: playlistView
                        model: mcws.playlists.model

                        property string currID: model.get(currentIndex).id
                        property string currName: model.get(currentIndex).name

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
                                    event.singleShot(500, function() { mainView.currentIndex = 1 })
                                }
                            }
                            PlasmaComponents.ToolButton {
                                iconSource: "search"
                                flat: false
                                onClicked: {
                                    playlistView.currentIndex = index
                                    trackView.populatePlaylist(id)
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

                        onCurrentIndexChanged: if (!trackView.searchMode) trackView.reset()

                        delegate:
                            GridLayout {
                                id: lvDel
                                width: lv.width
                                columns: 3
                                rowSpacing: 1

                                // zone name/status
                                RowLayout {
                                    Layout.columnSpan: 2
                                    spacing: 1
                                    Layout.margins: 2
                                    TrackImage {
                                        animateLoad: true
                                        Layout.rightMargin: 5
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
                                        visible: model.state !== mcws.stateStopped
                                        NumberAnimation {
                                            running: model.state === mcws.statePaused
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
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton | Qt.LeftButton
                                        onClicked: lv.currentIndex = index
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
                                    aText: +playingnowtracks !== 0
                                           ? trackdisplay
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
                                checked: mcws.repeatMode(lv.currentIndex) === text
                            }
                            MenuItem {
                                checkable: true
                                text: "Track"
                                checked: mcws.repeatMode(lv.currentIndex) === text
                            }
                            MenuItem {
                                checkable: true
                                text: "Off"
                                checked: mcws.repeatMode(lv.currentIndex) === text
                            }
                            MenuItemGroup {
                                items: repeatMenu.items
                                exclusive: true
                                onTriggered: {
                                    mcws.setRepeat(lv.currentIndex, item.text)
                                }
                            }
                        }

                        MenuSeparator{}
                        Menu {
                            id: linkMenu
                            title: "Link to"

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
                                width: Math.round(units.gridUnit * .25)
                                height: width
                                checkable: true
                                iconSource: "search"
                                onCheckedChanged: {
                                    if (!checked & trackView.showingPlaylist)
                                        searchField.text = ''
                                    if (!checked & trackView.searchMode)
                                        trackView.populate()
                                }
                            }

                            PlasmaExtras.Title {
                                id: tvTitle
                                text: {
                                    if (trackView.showingPlaylist)
                                        '< Playlist "%1"'.arg(playlistView.currName)
                                    else (trackView.searchMode || searchButton.checked
                                         ? '< Searching All Tracks'
                                         : "Playing Now/" + (lv.currentIndex >= 0 ? lv.getObj().zonename : ""))
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        searchButton.checked = false
                                        if (trackView.searchMode)
                                            trackView.populate()
                                        else
                                            trackView.highlightPlayingTrack()
                                    }
                                }
                            }
                        }
                        RowLayout {
                            visible: searchButton.checked
                            PlasmaComponents.TextField {
                                id: searchField
                                selectByMouse: true
                                clearButtonShown: true
                                font.pointSize: theme.defaultFont.pointSize-1
                                Layout.fillWidth: true
                                enabled: !trackView.showingPlaylist
                                onVisibleChanged: {
                                    if (visible)
                                        forceActiveFocus()
                                }

                                onAccepted: {
                                    var fld = searchField.text //.toLowerCase()
                                    // One char is a "starts with" search, ignore genre
                                    if (fld.length === 1)
                                        trackView.populate({'[Name]': '[%1"'.arg(fld)
                                              , '[Artist]': '[%1"'.arg(fld)
                                              , '[Album]': '[%1"'.arg(fld)
                                              }, 'or' )
                                    // Otherwise, we'll "like" search
                                    else if (fld.length > 1)
                                        trackView.populate({'[Name]': '"%1"'.arg(fld)
                                              , '[Artist]': '"%1"'.arg(fld)
                                              , '[Album]': '"%1"'.arg(fld)
                                              , '[Genre]': '"%1"'.arg(fld)
                                              }, 'or')
                                }
                            }
                            PlayButton {
                                enabled: trackView.mcwsQuery !== '' & trackModel.count > 0
                                onClicked: {
                                    if (trackView.showingPlaylist)
                                        mcws.playlists.play(lv.currentIndex, playlistView.currID, autoShuffle)
                                    else
                                        mcws.searchAndPlayNow(lv.currentIndex, trackView.mcwsQuery, autoShuffle)
                                }
                            }
                            AddButton {
                                enabled: trackView.mcwsQuery !== '' & trackModel.count > 0
                                onClicked: {
                                    if (trackView.showingPlaylist)
                                        mcws.playlists.add(lv.currentIndex, playlistView.currID, autoShuffle)
                                    else
                                        mcws.searchAndAdd(lv.currentIndex, trackView.mcwsQuery, true, autoShuffle)
                                }
                            }
                        }
                    }  //header

                    onFocusChanged: {
                        if (focus && !trackView.searchMode &&
                                (trackView.needsRefresh | (lv.getObj().playingnowtracks > 0 & trackModel.count === 0)))
                            trackView.populate()
                    }

                    Viewer {
                        id: trackView

                        property string mcwsQuery: ''
                        property bool searchMode: mcwsQuery !== ''
                        property bool showingPlaylist: false
                        property bool needsRefresh: false

                        model: TrackModel {
                            id: trackModel
                            hostUrl: mcws.hostUrl
                            onResultsReady: Qt.callLater(function(){trackView.highlightPlayingTrack()})
                        }

                        Component.onCompleted: {
                            mcws.pnPositionChanged.connect(function(zonendx, pos) {
                                if (!searchMode && zonendx === lv.currentIndex) {
                                    positionViewAtIndex(pos, ListView.Center)
                                    currentIndex = pos
                                }
                            })

                            mcws.pnChangeCtrChanged.connect(function(zonendx, ctr){
                                if (!searchMode && zonendx === lv.currentIndex && !mcws.isPlaylistEmpty(zonendx)) {
                                    if (mainView.currentIndex === 2)
                                        populate()
                                    else
                                        needsRefresh = true
                                }
                            })
                        }

                        function highlightPlayingTrack() {
                            if (trackModel.count === 0)
                                return

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

                        /* Reset the view model, null search means reset to zone playing now.
                           Else search will be a mcws query cmd
                        */
                        function populate(search, boolStr) {

                            needsRefresh = showingPlaylist = false

                            if (search === undefined || search.count === 0) {
                                mcwsQuery = ''
                                trackModel.loadPlayingNow(lv.getObj().zoneid)
                            }
                            else {
                                // and/or only
                                var boolOp = boolStr === undefined || boolStr === '' ? 'and' : boolStr
                                var query = ''
                                for(var k in search) {
                                    if (query === '') {
                                        searchField.text = search[k].replace(/(\[|\]|\")/g, '')
                                        query = ('(' + k + '=' + search[k])
                                    } else
                                        query += (' ' + boolOp + ' ' + k + '=' + search[k])
                                }
                                query += ')'

                                mcwsQuery = query
                                trackModel.loadSearch(mcwsQuery)

                                searchButton.checked = true

                                if (mainView.currentIndex !== 2)
                                    event.singleShot(700, function(){ mainView.currentIndex = 2 })
                            }
                        }

                        // Show the playlist files
                        function populatePlaylist(plid) {
                            if (plid === undefined || plid === '')
                                return

                            showingPlaylist = searchButton.checked = true
                            needsRefresh = false
                            searchField.text = 'Play or add "%1" >>'.arg(playlistView.currName)

                            mcwsQuery = plid
                            trackModel.loadPlaylistFiles('playlist=' + mcwsQuery)

                            if (mainView.currentIndex !== 2)
                                event.singleShot(700, function(){ mainView.currentIndex = 2 })
                        }

                        function formatDuration(dur) {
                            var num = dur.split('.')[0]
                            return "(%1:%2) ".arg(Math.floor(num / 60)).arg(String((num % 60) + '00').substring(0,2))
                        }

                        function reset() {
                            trackModel.source = ''
                            mcwsQuery = ''
                            searchField.text = ''
                            showingPlaylist = false
                            searchButton.checked = false
                        }

                        delegate:
                            RowLayout {
                                id: detDel
                                Layout.margins: units.smallSpacing
                                width: trackView.width

                                TrackImage { }
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

                    Menu {
                        id: detailMenu

                        property var currObj

                        function show() {
                            loadActions()
                            trkDetailMenu.loadActions(currObj.filekey)
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
                                onTriggered: mcws.searchAndPlayNow(lv.currentIndex, "artist=[%1]".arg(detailMenu.currObj.artist), autoShuffle)
                            }
                            MenuItem {
                                id: playGenre
                                onTriggered: mcws.searchAndPlayNow(lv.currentIndex, "genre=[%1]".arg(detailMenu.currObj.genre), autoShuffle)
                            }
                            MenuSeparator{}
                            MenuItem {
                                text: "Current List"
                                enabled: trackView.searchMode
                                onTriggered: {
                                    if (trackView.showingPlaylist)
                                        mcws.playlists.play(lv.currentIndex, playlistView.currID, autoShuffle)
                                    else
                                        mcws.searchAndPlayNow(lv.currentIndex, trackView.mcwsQuery, autoShuffle)
                                }
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
                                onTriggered: {
                                    if (trackView.showingPlaylist)
                                        mcws.playlists.add(lv.currentIndex, playlistView.currID, autoShuffle)
                                    else
                                        mcws.searchAndAdd(lv.currentIndex, trackView.mcwsQuery, false, autoShuffle)
                                }
                            }
                        }
                        Menu {
                            id: showMenu
                            title: "Show"
                            MenuItem {
                                id: showAlbum
                                onTriggered: trackView.populate({'[album]': '[%1]'.arg(detailMenu.currObj.album)
                                                               , '[artist]': '[%1]'.arg(detailMenu.currObj.artist)})
                            }
                            MenuItem {
                                id: showArtist
                                onTriggered: trackView.populate({'[artist]': '[%1]'.arg(detailMenu.currObj.artist)})
                            }
                            MenuItem {
                                id: showGenre
                                onTriggered: trackView.populate({'[genre]': '[%1]'.arg(detailMenu.currObj.genre)})
                            }
                        }

                        MenuSeparator{}
                        MenuItem {
                            text: "Reset View"
                            onTriggered: { trackView.reset() ; trackView.populate() }
                        }
                        MenuItem {
                            text: "Clear Playing Now"
                            enabled: !trackView.searchMode
                            onTriggered: {
                                trackView.reset()
                                mcws.clearPlaylist(lv.currentIndex)
                            }
                        }
                        MenuSeparator{}
                        Menu {
                            id: trkDetailMenu
                            title: "Track Detail"

                            function loadActions(filekey) {
                                clear()
                                mcws.getTrackDetails(filekey, function(items) {
                                    for (var i in items)
                                    {
                                        var menuItem = Qt.createQmlObject("import Qt.labs.platform 1.0; MenuItem {  }", trkDetailMenu)
                                        menuItem.text = i + '=' + items[i];
                                        trkDetailMenu.addItem(menuItem);
                                    }
                                })
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
                        RowLayout {
                            PlasmaComponents.ToolButton {
                            iconSource: "audio-ready"
                            checkable: true
                            checked: true
                            width: Math.round(units.gridUnit * 1.25)
                            height: width
                            anchors.top: parent.top
                            anchors.left: parent.left
                            onCheckedChanged: lookupModel.mediaType = checked ? 'audio' : ''
                        }
                            PlasmaComponents.TabBar {
                                Layout.fillWidth: true

                                PlasmaComponents.TabButton {
                                    text: "Artists"
                                    onClicked: {
                                        lookupModel.queryField = "Artist"
                                    }
                                }
                                PlasmaComponents.TabButton {
                                    text: "Albums"
                                    onClicked: {
                                        lookupModel.queryField = "Album"
                                    }
                                }
                                PlasmaComponents.TabButton {
                                    text: "Genres"
                                    onClicked: {
                                        lookupModel.queryField = "Genre"
                                    }
                                }
                                PlasmaComponents.TabButton {
                                    text: "Tracks"
                                    onClicked: {
                                        lookupModel.queryField = "Name"
                                    }
                                }
                            }
                        }
                        SearchBar {
                            id: sb
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
                            onResultsReady: sb.scrollCurrent()
                        }

                        spacing: 1

                        delegate: RowLayout {
                            id: lkDel
                            width: parent.width
                            PlayButton {
                                onClicked: {
                                    lookups.currentIndex = index
                                    mcws.searchAndPlayNow(lv.currentIndex,
                                                          '[%1]="%2"'.arg(lookupModel.queryField).arg(value),
                                                          autoShuffle)
                                    event.singleShot(250, function() { mainView.currentIndex = 1 } )
                                }
                            }
                            AddButton {
                                onClicked: {
                                    lookups.currentIndex = index
                                    mcws.searchAndAdd(lv.currentIndex,
                                                      '[%1]="%2"'.arg(lookupModel.queryField).arg(value),
                                                      false, autoShuffle)
                                }
                            }
                            PlasmaComponents.ToolButton {
                                iconSource: "search"
                                flat: false
                                onClicked: {
                                    lookups.currentIndex = index
                                    var obj = {}
                                    obj[lookupModel.queryField] = '"%2"'.arg(value)
                                    trackView.populate(obj)
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
                id: pi
                count: mainView.count
                currentIndex: mainView.currentIndex
                Layout.alignment: Qt.AlignHCenter

                delegate: Rectangle {
                    implicitWidth: 8
                    implicitHeight: 8

                    radius: width / 2
                    color: theme.highlightColor

                    opacity: index === pi.currentIndex ? 0.95 : 0.4

                    Behavior on opacity {
                        OpacityAnimator {
                            duration: 500
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mainView.currentIndex = index
                    }
                }
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

        thumbSize: plasmoid.configuration.highQualityThumbs ? 128 : 32

        function tryConnect(host) {
            currentZone = -1
            connect(host.indexOf(':') === -1
                    ? '%1:%2'.arg(host).arg(plasmoid.configuration.defaultPort)
                    : host)
        }

        // Connection is asynch, there could be many in-flight,
        // so check host of the error and reset iff the error is for the current host.
        onConnectionError: {
            if (cmd.indexOf(hostUrl) !== -1)
                closeConnection()
        }

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
