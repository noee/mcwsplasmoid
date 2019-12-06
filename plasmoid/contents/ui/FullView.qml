import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4

import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.5 as Kirigami
import Qt.labs.platform 1.0

import 'helpers/utils.js' as Utils
import 'helpers'
import 'models'
import 'controls'

Item {
    width: Kirigami.Units.gridUnit * 26
    height: Kirigami.Units.gridUnit * 30

    Connections {
        target: mcws

        // Initialize some vars when a connection starts
        // (host)
        onConnectionStart: {
            zoneView.model = ''
            clickedZone = -1
            mainView.currentIndex = 1
            searchButton.checked = false
            trackView.mcwsQuery = ''
            // clear dyn menus
            linkMenu.clear()
            devMenu.clear()
            playToZone.clear()
        }

        // Set current zone view when connection signals ready
        // (host, zonendx)
        onConnectionReady: {
            zoneView.model = mcws.zoneModel
            zoneView.currentIndex = zonendx
            hostList.popup.visible = false
        }

        // On error, reset view to the zoneview page
        // (msg, cmd)
        onConnectionError: {
            if (cmd.includes(mcws.host)) {
                mainView.currentIndex = 1
                hostTT.showServerStatus()
                hostList.popup.visible = true
            }
        }
    }
    Connections {
        target: plasmoidRoot

        // get notified when the host model changes
        // needed for config change, currentIndex not being set when model resets (BUG?)
        // (currentHost)
        onHostModelChanged: {
            hostList.currentIndex = mcws.host !== ''
                    ? hostModel.findIndex((item) => { return item.host === currentHost })
                    : 0
        }
    }

    Plasmoid.onExpandedChanged: {
        logger.log('Connected: %1\nExpanded: %2\nVertical: %3'
                        .arg(mcws.isConnected).arg(expanded).arg(vertical)
                   , 'Clicked: %1, ZV: %2'.arg(clickedZone).arg(zoneView.currentIndex))
        if (expanded) {
            if (mcws.isConnected)
                zoneView.set(clickedZone)
            else
                event.queueCall(() => { mcws.hostConfig = Object.assign({}, hostModel.get(hostList.currentIndex)) })
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        SwipeView {
            id: mainView
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            currentIndex: 1
            interactive: mcws.isConnected

            onCurrentIndexChanged: {
                if (currentIndex === 0 && playlistView.count === 0) {
                    allButton.checked = true
                    allButton.clicked()
                } else if (currentIndex === 3 && lookupView.count === 0) {
                    lookupArtist.checked = true
                    lookupArtist.clicked()
                }
            }

            ToolTip {
                id: hostTT
                text: mcws.isConnected
                      ? '%5 (v%3)\n%1 (%2), %4'
                        .arg(mcws.serverInfo.friendlyname)
                        .arg(mcws.host)
                        .arg(mcws.serverInfo.programversion)
                        .arg(mcws.serverInfo.platform)
                        .arg(mcws.serverInfo.programname)
                      : 'Media Server "%1" is not available'.arg(hostList.currentText)
                delay: 0

                function showServerStatus() {
                    show(text)
                }
            }

            // Playlist View
            Page {
                header: ColumnLayout {
                    spacing: 1
                    Kirigami.BasicListItem {
                        icon: 'view-media-playlist'
                        separatorVisible: false
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
                        text: "Playlists/" + (zoneView.currentIndex >= 0 ? zoneView.modelItem().zonename : "")
                        onClicked: hostTT.showServerStatus()
                    }

                    RowLayout {
                        width: parent.width
                        Layout.bottomMargin: 3
                        Layout.alignment: Qt.AlignCenter
                        CheckButton {
                            id: allButton
                            autoExclusive: true
                            text: "All"
                            onClicked: mcws.playlists.filterType = text
                        }
                        CheckButton {
                            text: "Smartlists"
                            autoExclusive: true
                            onClicked: mcws.playlists.filterType = text
                        }
                        CheckButton {
                            text: "Playlists"
                            autoExclusive: true
                            onClicked: mcws.playlists.filterType = text
                        }
                        CheckButton {
                            text: "Groups"
                            autoExclusive: true
                            onClicked: mcws.playlists.filterType = text
                        }
                    }
                }

                Viewer {
                    id: playlistView
                    useHighlight: false
                    model: mcws.playlists.items
                    spacing: 1

                    delegate: RowLayout {
                        id: plDel
                        width: parent.width

                        Kirigami.BasicListItem {
                            reserveSpaceForIcon: false
                            separatorVisible: false
                            text: name + ' / ' + type
                            alternatingBackground: true
                            onClicked: playlistView.currentIndex = index

                            PlayButton {
                                onClicked: {
                                    zoneView.currentPlayer.playPlaylist(id, autoShuffle)
                                    event.queueCall(500, () => { mainView.currentIndex = 1 } )
                                }
                            }
                            AddButton {
                                onClicked: zoneView.currentPlayer.addPlaylist(id, autoShuffle)
                            }
                            SearchButton {
                                onClicked: {
                                    playlistView.currentIndex = index
                                    mcws.playlists.currentIndex = index
                                    trackView.showPlaylist()
                                }
                            }
                        }
                    }
                }
            }
            // Zone View
            Page {
                header: RowLayout {
                    spacing: 0
                    Kirigami.BasicListItem {
                        icon: 'media-playback-start'
                        separatorVisible: false
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
                        text: i18n("Playback Zones on: ")
                        onClicked: hostTT.showServerStatus()
                        ComboBox {
                            id: hostList
                            model: hostModel
                            textRole: 'friendlyname'
                            onActivated: {
                                let item = model.get(currentIndex)
                                if (mcws.host !== item.host) {
                                    mcws.hostConfig = item
                                }
                            }
                        }
                    }
                    CheckButton {
                        icon.name: "window-pin"
                        autoExclusive: false
                        opacity: .75
                        implicitHeight: Kirigami.Units.iconSizes.medium
                        implicitWidth: implicitHeight
                        onCheckedChanged: plasmoid.hideOnWindowDeactivate = !checked
                    }
                }

                Viewer {
                    id: zoneView
                    spacing: 0
                    model: mcws.zoneModel

                    property var currentPlayer: modelItem() ? modelItem().player : null

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && !trackView.searchMode) {
                            trackView.reset()
                            logger.log('GUI:ZoneChanged'
                                       , '=> %1, TrackList Cnt: %2'.arg(currentIndex).arg(trackView.model.count))
                        }
                    }

                    function set(zonendx) {
                        // Form factor constraints, vertical do nothing
                        if (vertical) {
                            if (currentIndex === -1)
                                currentIndex = mcws.getPlayingZoneIndex()
                        }
                        // Inside a panel...
                        else {
                            // no zone change, do nothing
                            if (zonendx === currentIndex)
                                return

                            currentIndex = zonendx !== -1 ? zonendx : mcws.getPlayingZoneIndex()
                        }
                    }

                    delegate: ZoneDelegate {
                        onClicked: zoneView.currentIndex = index
                        onZoneClicked: zoneView.currentIndex = zonendx
                    }
                }

                Component {
                    id: mi
                    MenuItem {
                        property string zoneid
                        property int devndx
                        checkable: true
                    }
                }
                Menu {
                    id: zoneMenu

                    MenuItem {
                        text: "Shuffle Playing Now"
                        iconName: "shuffle"
                        onTriggered: zoneView.currentPlayer.setShuffle('Reshuffle')
                    }
                    MenuSeparator{}
                    Menu {
                        id: shuffleMenu
                        title: "Shuffle Mode"

                        property string currShuffle: ''

                        onAboutToShow: {
                            zoneView.currentPlayer.getShuffleMode((shuffle) => {
                                currShuffle = shuffle.mode
                            })
                        }

                        MenuItem {
                            checkable: true
                            text: 'Off'
                            checked: shuffleMenu.currShuffle === text
                        }
                        MenuItem {
                            checkable: true
                            text: 'On'
                            checked: shuffleMenu.currShuffle === text
                        }
                        MenuItem {
                            checkable: true
                            text: 'Automatic'
                            checked: shuffleMenu.currShuffle === text
                        }
                        MenuItemGroup {
                            items: shuffleMenu.items
                            onTriggered: zoneView.currentPlayer.setShuffle(item.text)
                        }
                    }
                    Menu {
                        id: repeatMenu
                        title: "Repeat Mode"

                        property string currRepeat: ''

                        onAboutToShow: {
                            zoneView.currentPlayer.getRepeatMode((repeat) => {
                                currRepeat = repeat.mode
                            })
                        }

                        MenuItem {
                            checkable: true
                            text: "Playlist"
                            checked: repeatMenu.currRepeat === text
                        }
                        MenuItem {
                            checkable: true
                            text: "Track"
                            checked: repeatMenu.currRepeat === text
                        }
                        MenuItem {
                            checkable: true
                            text: "Off"
                            checked: repeatMenu.currRepeat === text
                        }
                        MenuItemGroup {
                            items: repeatMenu.items
                            onTriggered: zoneView.currentPlayer.setRepeat(item.text)
                        }
                    }
                    MenuSeparator{}
                    Menu {
                        id: linkMenu
                        title: "Link to"
                        visible: zoneView.count > 1

                        // Hide/Show menu items based on selected Zone
                        onAboutToShow: {
                            if (linkMenu.items.length === 0) {
                                mcws.zoneModel.forEach((zone) => {
                                    linkMenu.addItem(mi.createObject(linkMenu, { zoneid: zone.zoneid
                                                                               , text: i18n(zone.zonename)
                                                                               })
                                    )
                                })
                            }

                            var z = zoneView.modelItem()
                            var zonelist = z.linkedzones !== undefined ? z.linkedzones.split(';') : []

                            mcws.zoneModel.forEach((zone, ndx) => {
                                linkMenu.items[ndx].visible = z.zoneid !== zone.zoneid
                                linkMenu.items[ndx].checked = zonelist.indexOf(zone.zoneid.toString()) !== -1
                            })
                        }

                        MenuItemGroup {
                            items: linkMenu.items
                            exclusive: false
                            onTriggered: {
                                if (!item.checked)
                                    zoneView.currentPlayer.unLinkZone()
                                else
                                    zoneView.currentPlayer.linkZone(item.zoneid)
                            }
                        }
                    }
                    Menu {
                        id: devMenu
                        title: "Audio Device"

                        property int currDev: -1

                        onAboutToShow: {
                            mcws.audioDevices.getDevice(zoneView.currentIndex, (ad) =>
                            {
                                currDev = ad.deviceindex
                                if (devMenu.items.length === 0) {
                                    mcws.audioDevices.items.forEach((dev, ndx) =>
                                    {
                                        devMenu.addItem(mi.createObject(devMenu,
                                                                        { devndx: ndx
                                                                         , checked: currDev === ndx
                                                                         , group: ig
                                                                         , text: i18n(dev)
                                                                        }))
                                    })
                                }
                                else {
                                    devMenu.items[currDev].checked = true
                                }
                            })
                        }

                        MenuItemGroup {
                            id: ig
                            onTriggered: {
                                if (item.devndx !== devMenu.currDev) {
                                    mcws.audioDevices.setDevice(zoneView.currentIndex, item.devndx)
                                }
                                devMenu.currDev = -1
                            }
                        }
                    }
                    MenuSeparator{}
                    MenuItem {
                        text: "Equalizer On"
                        iconName: "edit-clear"
                        onTriggered: zoneView.currentPlayer.setEqualizer(true)
                    }
                    MenuItem {
                        text: "Clear Playing Now"
                        iconName: "edit-clear"
                        onTriggered: zoneView.currentPlayer.clearPlayingNow()
                    }
                    MenuSeparator{}
                    MenuItem {
                        text: "Clear All Zones"
                        iconName: "edit-clear"
                        onTriggered: mcws.zoneModel.forEach((zone) => {
                            zone.player.clearPlayingNow()
                        })
                    }
                    MenuItem {
                        text: "Stop All Zones"
                        iconName: "edit-clear"
                        onTriggered: mcws.stopAllZones()
                    }
                }
            }
            // Track View
            Page {
                header: ColumnLayout {
                    spacing: 1

                    RowLayout {
                        spacing: 0
                        Layout.bottomMargin: 3
                        SearchButton {
                            id: searchButton
                            icon.name: checked ? 'draw-arrow-back' : 'search'
                            ToolTip.text: checked ? 'Back to Playing Now' : 'Search'
                            onClicked: {
                                if (!checked)
                                    trackView.reset()
                                else {
                                    trackView.model = searcher.items
                                    trackView.mcwsQuery = searcher.constraintString
                                    event.queueCall(1000, () => { trackView.currentIndex = -1 })
                                }
                            }
                        }
                        SortButton {
                            visible: !searchButton.checked
                            model: {
                                if (mcws.isConnected && zoneView.modelItem())
                                    return zoneView.modelItem().trackList
                                else
                                    return undefined
                            }
                            onSortDone: trackView.highlightPlayingTrack
                        }
                        Kirigami.BasicListItem {
                            separatorVisible: false
                            reserveSpaceForIcon: false
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
                            text: {
                                if (trackView.showingPlaylist)
                                    'Playlist "%1"'.arg(mcws.playlists.currentName)
                                else (trackView.searchMode || searchButton.checked
                                     ? 'Searching All Tracks'
                                     : "Playing Now/" + (zoneView.currentIndex >= 0 ? zoneView.modelItem().zonename : ""))
                            }
                            onClicked: {
                                if (searchButton.checked)
                                    trackView.reset()
                                else {
                                    hostTT.showServerStatus()
                                    trackView.highlightPlayingTrack()
                                }
                            }

                        }
                    }
                    RowLayout {
                        visible: searchButton.checked
                        Layout.bottomMargin: 5
                        TextEx {
                            id: searchField
                            placeholderText: trackView.showingPlaylist
                                             ? 'Play or add >>'
                                             : 'Enter search'
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize-1
                            Layout.fillWidth: true
                            horizontalAlignment: trackView.showingPlaylist ? Text.AlignRight : Text.AlignLeft
                            visible: !trackView.showingPlaylist
                            onVisibleChanged: {
                                if (visible)
                                    forceActiveFocus()
                            }

                            onTextChanged: {
                                if (text === '')
                                    searcher.clear()
                            }

                            onAccepted: {
                                var fld = searchField.text
                                // One char is a "starts with" search, ignore genre
                                if (fld.length === 1)
                                    trackView.search({'name': '[%1"'.arg(fld)
                                                      , 'artist': '[%1"'.arg(fld)
                                                      , 'album': '[%1"'.arg(fld)
                                                      }, false )
                                // Otherwise, it's a "like" search
                                else if (fld.length > 1)
                                    trackView.search({'name': '"%1"'.arg(fld)
                                                      , 'artist': '"%1"'.arg(fld)
                                                      , 'album': '"%1"'.arg(fld)
                                                      , 'genre': '"%1"'.arg(fld)
                                                      }, false)
                            }
                        }
                        PlayButton {
                            enabled: trackView.searchMode & trackView.count > 0
                            onClicked: {
                                if (trackView.showingPlaylist)
                                    zoneView.currentPlayer.playPlaylist(mcws.playlists.currentID, autoShuffle)
                                else
                                    zoneView.currentPlayer.searchAndPlayNow(trackView.mcwsQuery, autoShuffle)
                            }
                        }
                        AddButton {
                            enabled: trackView.searchMode & trackView.count > 0
                            onClicked: {
                                if (trackView.showingPlaylist)
                                    zoneView.currentPlayer.addPlaylist(mcws.playlists.currentID, autoShuffle)
                                else
                                    zoneView.currentPlayer.searchAndAdd(trackView.mcwsQuery, true, autoShuffle)
                            }
                        }
                        SortButton {
                            id: sorter
                            enabled: trackView.searchMode & trackView.count > 0
                            onSortDone: trackView.highlightPlayingTrack
                        }
                    }
                }  //header

                Viewer {
                    id: trackView

                    property string mcwsQuery: ''
                    property bool searchMode: mcwsQuery !== ''
                    property bool showingPlaylist: mcwsQuery === 'playlist'
                    property string tempTT: ''

                    Searcher {
                        id: searcher
                        comms: mcws.comms
                        autoShuffle: plasmoid.configuration.shuffleSearch
                        mcwsFields: mcws.defaultFields()
                        onSearchBegin: busyInd.visible = true
                        onSearchDone: {
                            busyInd.visible = false
                            if (count > 0) {
                                sorter.model = searcher
                                trackView.highlightPlayingTrack()
                            }
                        }
                        onDebugLogger: logger.log(obj, msg)
                    }

                    Component.onCompleted: {
                        mcws.pnPositionChanged.connect((zonendx, pos) => {
                            if (!searchMode && zonendx === zoneView.currentIndex) {
                                pos = trackView.model.mapRowFromSource(pos)
                                positionViewAtIndex(pos, ListView.Center)
                                currentIndex = pos
                            }
                        })

                        mcws.playlists.loadTracksBegin.connect(() => {
                            busyInd.visible = true
                        })
                        mcws.playlists.loadTracksDone.connect(() => {
                            busyInd.visible = false
                            if (count > 0) {
                                highlightPlayingTrack()
                                sorter.model = mcws.playlists.trackModel
                            }
                        })
                    }

                    function highlightPlayingTrack() {
                        var z = zoneView.modelItem()
                        if (!z) {
                            currentIndex = -1
                            return
                        }

                        if (!searchMode) {
                            var ndx = trackView.model.mapRowFromSource(z.playingnowposition)
                            if (ndx !== undefined && (ndx >= 0 & ndx < trackView.count)) {
                                currentIndex = ndx
                            }
                            else
                                currentIndex = -1
                        } else {
                            if (plasmoid.configuration.showPlayingTrack) {
                                currentIndex = trackView.model.findIndex((item) => {
                                    return +item.key === +z.filekey
                                })
                            }
                        }
                    }

                    // contraints obj should be of form:
                    // { artist: value, album: value, genre: value, etc.... }
                    function search(constraints, andTogether) {

                        if (typeof constraints !== 'object') {
                            logger.error('search()'
                                       , 'contraints obj should be of form: { artist: value, album: value, genre: value, etc.... }')
                            return
                        }

                        searcher.logicalJoin = (andTogether === true || andTogether === undefined ? 'and' : 'or')
                        searcher.constraintList = constraints

                        mcwsQuery = searcher.constraintString
                        trackView.model = searcher.items
                        searchButton.checked = true

                        // show the first constraint value
                        for (var k in constraints) {
                            searchField.text = constraints[k].replace(/(\[|\]|\")/g, '')
                            break
                        }

                        mainView.currentIndex = 2
                    }

                    // Puts the view in search mode, sets the view model to the playlist tracks
                    function showPlaylist() {

                        mcwsQuery = 'playlist'
                        searchButton.checked = true
                        searchField.text = ''
                        trackView.model = mcws.playlists.trackModel.items

                        mainView.currentIndex = 2
                    }

                    function formatDuration(dur) {
                        if (dur === undefined) {
                            return ''
                        }

                        var num = dur.split('.')[0]
                        return "%1:%2".arg(Math.floor(num / 60)).arg(String((num % 60) + '00').substring(0,2))
                    }

                    // Set the viewer to the current zone playing now
                    function reset() {
                        mcwsQuery = ''
                        searchButton.checked = false
                        mcws.playlists.currentIndex = -1
                        trackView.model = zoneView.modelItem().trackList.items
                        sorter.model = zoneView.modelItem().trackList
                        event.queueCall(500, highlightPlayingTrack)
                    }

                    delegate: TrackDelegate {
                        MouseAreaEx {
                            tipShown: pressed
                            tipText: trackView.tempTT

                            onPressAndHold: {
                                mcws.getTrackDetails(key, (ti) => {
                                    trackView.tempTT = Utils.stringifyObj(ti)
                                })
                            }

                            onClicked: {
                                trackView.currentIndex = index
                                if (mouse.button === Qt.RightButton)
                                    detailMenu.open()
                            }
                            acceptedButtons: Qt.RightButton | Qt.LeftButton
                        }

                    }
                } //listview

                BusyIndicator {
                    id: busyInd
                    visible: false
                    anchors.centerIn: parent
                    implicitWidth: parent.width/4
                    implicitHeight: implicitWidth
                }

                Menu {
                    id: detailMenu

                    property var currObj

                    onAboutToShow:  {
                        currObj = trackView.modelItem()
                        playAlbum.text = addAlbum.text = addAlbumEnd.text = showAlbum.text
                                = i18n("Album: \"%1\"".arg(currObj.album))
                        playArtist.text = addArtist.text = addArtistEnd.text = showArtist.text
                                = i18n("Artist: \"%1\"".arg(currObj.artist))
                        playGenre.text = addGenre.text = addGenreEnd.text = showGenre.text
                                = i18n("Genre: \"%1\"".arg(currObj.genre))
                        playMenu.visible = addMenu.visible = showMenu.visible
                                = detailMenu.currObj.mediatype === 'Audio'
                    }

                    MenuItem {
                        text: "Play Track"
                        onTriggered: {
                            if (trackView.searchMode)
                                zoneView.currentPlayer.playTrackByKey(detailMenu.currObj.key)
                            else
                                zoneView.currentPlayer.playTrack(trackView.model.mapRowToSource(trackView.currentIndex))
                        }
                    }
                    MenuItem {
                        text: "Add Track"
                        onTriggered: zoneView.currentPlayer.addTrack(detailMenu.currObj.key)
                    }

                    MenuItem {
                        text: "Remove Track"
                        enabled: !trackView.searchMode
                        onTriggered: zoneView.currentPlayer.removeTrack(trackView.model.mapRowToSource(trackView.currentIndex))
                    }
                    MenuSeparator{}
                    Menu {
                        id: playMenu
                        title: "Play"
                        MenuItem {
                            id: playAlbum
                            onTriggered: zoneView.currentPlayer.playAlbum(detailMenu.currObj.key)
                        }
                        SearchAction {
                            id: playArtist
                            shuffle: autoShuffle
                            onTriggered: play("artist=[%1]".arg(detailMenu.currObj.artist))
                        }
                        SearchAction {
                            id: playGenre
                            shuffle: autoShuffle
                            onTriggered: play("genre=[%1]".arg(detailMenu.currObj.genre))
                        }

                        MenuSeparator{}
                        SearchAction {
                            text: "Current List"
                            visible: trackView.searchMode
                            shuffle: autoShuffle
                            onTriggered: {
                                if (trackView.showingPlaylist)
                                    zoneView.currentPlayer.playPlaylist(mcws.playlists.currentID, shuffle)
                                else
                                    play(trackView.mcwsQuery)
                            }
                        }
                    }
                    Menu {
                        id: addMenu
                        title: "Add Next to Play"
                        SearchAction {
                            id: addAlbum
                            next: true
                            onTriggered: add("album=[%1] and artist=[%2]"
                                                .arg(detailMenu.currObj.album)
                                                .arg(detailMenu.currObj.artist))
                        }

                        SearchAction {
                            id: addArtist
                            next: true
                            onTriggered: add("artist=[%1]".arg(detailMenu.currObj.artist))
                        }
                        SearchAction {
                            id: addGenre
                            next: true
                            onTriggered: add("genre=[%1]".arg(detailMenu.currObj.genre))
                        }
                        MenuSeparator{}
                        SearchAction {
                            text: "Current List"
                            next: true
                            visible: trackView.searchMode
                            onTriggered: {
                                if (trackView.showingPlaylist)
                                    zoneView.currentPlayer.addPlaylist(mcws.playlists.currentID, autoShuffle)
                                else
                                    add(trackView.mcwsQuery)
                            }
                        }
                    }
                    Menu {
                        id: addMenuEnd
                        title: "Add to End of List"
                        SearchAction {
                            id: addAlbumEnd
                            onTriggered: add("album=[%1] and artist=[%2]"
                                                .arg(detailMenu.currObj.album)
                                                .arg(detailMenu.currObj.artist))
                        }
                        SearchAction {
                            id: addArtistEnd
                            onTriggered: add("artist=[%1]".arg(detailMenu.currObj.artist))
                        }
                        SearchAction {
                            id: addGenreEnd
                            onTriggered: add("genre=[%1]".arg(detailMenu.currObj.genre))
                        }
                        MenuSeparator{}
                        SearchAction {
                            text: "Current List"
                            visible: trackView.searchMode
                            onTriggered: {
                                if (trackView.showingPlaylist)
                                    zoneView.currentPlayer.addPlaylist(mcws.playlists.currentID, false)
                                else
                                    add(trackView.mcwsQuery)
                            }
                        }
                    }
                    Menu {
                        id: showMenu
                        title: "Show"
                        MenuItem {
                            id: showAlbum
                            onTriggered: trackView.search({'album': '[%1]'.arg(detailMenu.currObj.album)
                                                           , 'artist': '[%1]'.arg(detailMenu.currObj.artist)})
                        }
                        MenuItem {
                            id: showArtist
                            onTriggered: trackView.search({'artist': '[%1]'.arg(detailMenu.currObj.artist)})
                        }
                        MenuItem {
                            id: showGenre
                            onTriggered: trackView.search({'genre': '[%1]'.arg(detailMenu.currObj.genre)})
                        }
                    }
                    MenuSeparator{}
                    Menu {
                        id: playToZone
                        title: "Send this list to Zone"
                        visible: zoneView.count > 1

                        onAboutToShow: {
                            if (playToZone.items.length === 0) {
                                mcws.zoneModel.forEach((zone, ndx) => {
                                    playToZone.addItem(mi.createObject(linkMenu, { zoneid: zone.zoneid
                                                                               , devndx: ndx
                                                                               , text: i18n(zone.zonename)
                                                                               , checkable: false })
                                    )
                                })
                            }
                            mcws.zoneModel.forEach((zone, ndx) => {
                                playToZone.items[ndx].visible = ndx !== zoneView.currentIndex
                            })
                        }

                        MenuItemGroup {
                            items: playToZone.items
                            exclusive: false
                            onTriggered: {
                                mcws.sendListToZone(trackView.searchMode
                                                    ? trackView.showingPlaylist
                                                      ? mcws.playlists.trackModel.items
                                                      : searcher.items
                                                    : zoneView.modelItem().trackList.items
                                                    , item.devndx)
                            }
                        }
                    }
                    MenuSeparator{}
                    MenuItem {
                        text: "Shuffle Playing Now"
                        enabled: !trackView.searchMode
                        onTriggered: zoneView.currentPlayer.setShuffle('reshuffle')
                    }
                    MenuItem {
                        text: "Clear Playing Now"
                        enabled: !trackView.searchMode
                        onTriggered: zoneView.currentPlayer.clearPlayingNow()
                    }
                }
            }
            // Lookups
            Page {
                header: ColumnLayout {
                    spacing: 0
                    Kirigami.BasicListItem {
                        icon: 'search'
                        separatorVisible: false
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
                        text: 'Search Media Library'
                        onClicked: hostTT.showServerStatus()
                        CheckButton {
                            icon.name: checked ? 'audio-on' : 'pattern-multimedia'
                            checked: true
                            autoExclusive: false
                            onCheckedChanged: lookup.mediaType = checked ? 'audio' : ''
                            text: 'Showing ' + (checked ? 'Audio Only' : 'All Media Types')
                        }
                    }

                    RowLayout {
                        spacing: 0
                        Layout.alignment: Qt.AlignCenter
                        CheckButton {
                            id: lookupArtist
                            text: 'Artists'
                            autoExclusive: true
                            onClicked: {
                                lookup.queryField = "artist"
                                lookupView.iconStr = 'view-media-artist'
                            }
                        }
                        CheckButton {
                            text: 'Albums'
                            autoExclusive: true
                            onClicked: {
                                lookup.queryField = "album"
                                lookupView.iconStr = 'media-default-album'
                            }
                        }
                        CheckButton {
                            text: 'Genre'
                            autoExclusive: true
                            onClicked: {
                                lookup.queryField = "genre"
                                lookupView.iconStr = 'view-media-genre'
                            }
                        }
                        CheckButton {
                            text: 'Tracks'
                            autoExclusive: true
                            onClicked: {
                                lookup.queryField = "name"
                                lookupView.iconStr = 'tools-rip-audio-cd'
                            }
                        }
                    }

                    SearchBar {
                        id: sb
                        list: lookupView
                        modelItem: "value"
                        Layout.alignment: Qt.AlignCenter
                        Layout.bottomMargin: 3
                    }
                }

                Viewer {
                    id: lookupView
                    spacing: 1
                    useHighlight: false
                    model: lookup.items

                    property string iconStr

                    LookupValues {
                        id: lookup
                        hostUrl: mcws.comms.hostUrl
                        onDataReady: sb.scrollCurrent()
                    }

                    delegate: RowLayout {
                        id: lkDel
                        width: parent.width
                        Kirigami.BasicListItem {
                            icon: lookupView.iconStr
                            text: value //+ (field === '' ? '' : ' / ' + field)
                            alternatingBackground: true
                            separatorVisible: false
                            onClicked: lookupView.currentIndex = index
                            PlayButton {
                                onClicked: {
                                    lookupView.currentIndex = index
                                    zoneView.currentPlayer.searchAndPlayNow(
                                                          '[%1]="%2"'.arg(lookup.queryField).arg(value)
                                                          , autoShuffle)
                                    event.queueCall(250, () => { mainView.currentIndex = 1 } )
                                }
                            }
                            AddButton {
                                onClicked: {
                                    lookupView.currentIndex = index
                                    zoneView.currentPlayer.searchAndAdd(
                                                      '[%1]="%2"'.arg(lookup.queryField).arg(value),
                                                      false, autoShuffle)
                                }
                            }
                            SearchButton {
                                onClicked: {
                                    lookupView.currentIndex = index
                                    var obj = {}
                                    obj[lookup.queryField] = '"%2"'.arg(value)
                                    trackView.search(obj)
                                }
                            }
                        }

                    } // delegate
                } // viewer
            }

        }

        PageIndicator {
            id: pi
            count: mainView.count
            visible: mcws.isConnected
            currentIndex: mainView.currentIndex
            Layout.alignment: Qt.AlignHCenter

            delegate: Rectangle {
                implicitWidth: 8
                implicitHeight: 8

                radius: width / 2
                color: Kirigami.Theme.highlightColor

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

    TrackImage {
        anchors.fill: parent
        sourceSize.height: thumbSize * 2
        fillMode: Image.PreserveAspectCrop
        opacity: mainView.currentIndex === 1 || mainView.currentIndex === 2 ? opacityTo : 0
        opacityTo: 0.07
        z: Infinity

        Binding on sourceKey {
            when: mcws.isConnected
            delayed: true
            value: zoneView.modelItem() ? zoneView.modelItem().filekey : ''
        }

        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.longDuration * 2 }
        }
    }

}
