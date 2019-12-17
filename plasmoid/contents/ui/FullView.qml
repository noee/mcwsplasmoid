import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4

import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.8 as Kirigami
import Qt.labs.platform 1.0

import 'helpers'
import 'models'
import 'controls'

Item {
    readonly property alias zoneView: zoneView
    readonly property alias hostSelector: hostSelector

    Connections {
        target: mcws

        // If the playing position changes for the zone we're viewing
        // (zonendx, pos)
        onPnPositionChanged: {
            if (zoneView.isCurrent(zonendx) && !trackView.searchMode) {
                trackView.highlightPlayingTrack(pos)
            }
        }

        // If track changes on current zone, update background image
        onTrackKeyChanged: {
            if (zoneView.isCurrent(zonendx))
                bkgdImg.sourceKey = filekey
        }

        // Initialize some vars when a connection starts
        // (host)
        onConnectionStart: {
            zoneView.viewer.model = ''
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
            zoneView.viewer.model = mcws.zoneModel
            hostSelector.popup.visible = false

            // For each zone tracklist, set up sort signals
            mcws.zoneModel.forEach(
                (zone) => {
                    zone.trackList.sortBegin.connect(() => { busyInd.visible = true })
                    zone.trackList.sortDone.connect(() =>
                                          {
                                               trackView.highlightPlayingTrack()
                                               busyInd.visible = false
                                          })
                    zone.trackList.sortReset.connect(() => { trackView.reset() })
                })
        }

        // On error, reset view to the zoneview page
        // (msg, cmd)
        onConnectionError: {
            if (cmd.includes(mcws.host)) {
                mainView.currentIndex = 1
                hostTT.showServerStatus()
                hostSelector.popup.visible = true
            }
        }
    }
    Connections {
        target: plasmoidRoot

        // get notified when the host model changes
        // needed for config change, currentIndex not being set when model resets (BUG?)
        // (currentHost)
        onHostModelChanged: {
            hostSelector.currentIndex = mcws.host !== ''
                    ? hostModel.findIndex((item) => { return item.host === currentHost })
                    : 0
        }
    }
    Connections {
        target: mcws.playlists.trackModel
        enabled: mcws.isConnected

        // Handle playlist track searching/display
        onSearchBegin: busyInd.visible = true
        onSearchDone: {
            sorter.sourceModel = mcws.playlists.trackModel
            trackView.highlightPlayingTrack()
            busyInd.visible = false
        }
        onSortBegin: busyInd.visible = true
        onSortDone: {
            trackView.highlightPlayingTrack()
            busyInd.visible = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        SwipeView {
            id: mainView
            Layout.fillHeight: true
            Layout.fillWidth: true
            interactive: mcws.isConnected
            spacing: Kirigami.Units.smallSpacing
            currentIndex: 1

            onCurrentIndexChanged: mainView.itemAt(currentIndex).viewEntered()

            ToolTip {
                id: hostTT
                text: mcws.isConnected
                      ? '%5 (v%3)\n%1 (%2), %4'
                        .arg(mcws.serverInfo.friendlyname)
                        .arg(mcws.host)
                        .arg(mcws.serverInfo.programversion)
                        .arg(mcws.serverInfo.platform)
                        .arg(mcws.serverInfo.programname)
                      : hostSelector.count > 0
                            ? 'Media Server "%1" is not available'.arg(hostSelector.currentText)
                            : 'Check MCWS host configuration'
                delay: 0

                function showServerStatus() {
                    show(text)
                }
            }

            // Playlist View
            ViewerPage {
                onViewEntered: {
                    if (viewer.count === 0) {
                        plActions.itemAt(0).checked = true
                        plActions.itemAt(0).action.triggered()
                    }
                }

                header: ColumnLayout {
                    spacing: 1
                    Kirigami.BasicListItem {
                        icon: 'view-media-playlist'
                        separatorVisible: false
                        backgroundColor: PlasmaCore.ColorScope.highlightColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
                        text: "Playlists/" + (zoneView.modelItem ? zoneView.modelItem.zonename : '')
                        onClicked: hostTT.showServerStatus()
                    }

                    RowLayout {
                        width: parent.width
                        Layout.bottomMargin: 3
                        Layout.alignment: Qt.AlignCenter
                        Repeater {
                            id: plActions
                            model: mcws.playlists.searchActions
                            ToolButton {
                                action: modelData
                                autoExclusive: true
                            }
                        }
                    }
                }

                viewer.useHighlight: false
                viewer.model: mcws.playlists.items
                viewer.delegate: RowLayout {
                    width: parent.width

                    Kirigami.BasicListItem {
                        reserveSpaceForIcon: false
                        separatorVisible: false
                        text: name + ' / ' + type
                        alternatingBackground: true

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
                                mcws.playlists.currentIndex = index
                                trackView.showPlaylist()
                            }
                        }
                    }
                }

            }

            // Zone View
            ViewerPage {
                id: zoneView
                readonly property var currentPlayer: viewer.modelItem ? viewer.modelItem.player : null
                readonly property var modelItem: viewer.modelItem

                function set(zonendx) {
                    // Form factor constraints, vertical do nothing
                    if (vertical) {
                        if (viewer.currentIndex === -1)
                            viewer.currentIndex = mcws.getPlayingZoneIndex()
                    }
                    // Inside a panel...
                    else {
                        // no zone change, do nothing
                        if (zonendx === viewer.currentIndex)
                            return

                        viewer.currentIndex = zonendx !== -1 ? zonendx : mcws.getPlayingZoneIndex()
                    }
                }
                function isCurrent(zonendx) {
                    return zonendx === viewer.currentIndex
                }

                header: Kirigami.BasicListItem {
                    icon: 'media-playback-start'
                    separatorVisible: false
                    backgroundColor: PlasmaCore.ColorScope.highlightColor
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
                    text: i18n("Playback Zones on: ")
                    onClicked: hostTT.showServerStatus()
                    ComboBox {
                        id: hostSelector
                        model: hostModel
                        textRole: 'friendlyname'
                        onActivated: {
                            let item = model.get(currentIndex)
                            if (mcws.host !== item.host) {
                                mcws.hostConfig = item
                            }
                        }
                    }
                    CheckButton {
                        icon.name: "window-pin"
                        flat: true
                        opacity: .75
                        onCheckedChanged: plasmoid.hideOnWindowDeactivate = !checked
                    }
                }

                viewer.spacing: 0
                viewer.model: mcws.zoneModel
                viewer.delegate: ZoneDelegate {
                    onClicked: zoneView.viewer.currentIndex = index
                    onZoneClicked: zoneView.viewer.currentIndex = zonendx
                }

                viewer.onCurrentIndexChanged: {
                    event.queueCall(100,
                                    () => {
                                        if (zoneView.modelItem) {
                                            bkgdImg.sourceKey = zoneView.modelItem.filekey

                                            if (!trackView.searchMode)
                                                trackView.reset()

                                            logger.log('GUI:ZoneChanged'
                                                       , '=> %1, TrackList Cnt: %2'.arg(viewer.currentIndex).arg(trackView.viewer.model.count))
                                        }
                                    })
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

                            var z = zoneView.modelItem
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
                            mcws.audioDevices.getDevice(zoneView.viewer.currentIndex, (ad) =>
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
                                    mcws.audioDevices.setDevice(zoneView.viewer.currentIndex, item.devndx)
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
            ViewerPage {
                id: trackView

                property string mcwsQuery: ''
                property bool searchMode: mcwsQuery !== ''
                property bool isSorted: zoneView.modelItem
                                        ? zoneView.modelItem.trackList.sortField !== ''
                                        : false
                property bool showingPlaylist: mcwsQuery === 'playlist'

                function highlightPlayingTrack(pos) {
                    if (!zoneView.modelItem) {
                        viewer.currentIndex = -1
                        return
                    }

                    if (pos !== undefined) {
                        if (!trackView.isSorted) {
                            viewer.currentIndex = pos
                            viewer.positionViewAtIndex(pos, ListView.Center)
                            return
                        }
                    }

                    if (!searchMode | plasmoid.configuration.showPlayingTrack) {
                        let fk = +zoneView.modelItem.filekey
                        viewer.currentIndex = viewer.model.findIndex((item) => {
                            return +item.key === fk
                        })
                        viewer.positionViewAtIndex(viewer.currentIndex, ListView.Center)
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
                    viewer.model = searcher.items
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
                    viewer.model = mcws.playlists.trackModel.items

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
                    viewer.model = zoneView.modelItem.trackList.items
                    event.queueCall(750, highlightPlayingTrack)
                }

                header: RowLayout {
                    spacing: 1
                    height: searchField.height + Kirigami.Units.largeSpacing*2
                    // Controls for current playing now list
                    SearchButton {
                        id: searchButton
                        icon.name: checked ? 'draw-arrow-back' : 'search'
                        ToolTip.text: checked
                                      ? trackView.showingPlaylist ? 'Back to Playlists' : 'Back to Playing Now'
                                      : 'Search'
                        onClicked: {
                            if (!checked) {
                                if (trackView.showingPlaylist)
                                    mainView.currentIndex = 0
                                trackView.reset()
                            }
                            else {
                                viewer.model = searcher.items
                                trackView.mcwsQuery = searcher.constraintString
                                event.queueCall(1000, () => { trackView.viewer.currentIndex = -1 })
                            }
                        }
                    }
                    SortButton {
                        visible: !searchButton.checked
                        sourceModel: zoneView.modelItem ? zoneView.modelItem.trackList : null
                    }
                    Kirigami.BasicListItem {
                        separatorVisible: false
                        backgroundColor: PlasmaCore.ColorScope.highlightColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
                        icon: trackView.showingPlaylist ? 'view-media-playlist' : 'media-playback-start'
                        visible: trackView.showingPlaylist | !searchButton.checked
                        text: {
                            if (trackView.showingPlaylist)
                                '"%1"'.arg(mcws.playlists.currentName)
                            else
                                "Playing Now" + (zoneView.modelItem
                                                  ? '/' + zoneView.modelItem.zonename
                                                  : "")
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

                    // Search Controls
                    TextEx {
                        id: searchField
                        placeholderText: trackView.showingPlaylist
                                         ? 'Play or add >>'
                                         : 'Enter search'
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize-1
                        Layout.fillWidth: true
                        horizontalAlignment: trackView.showingPlaylist ? Text.AlignRight : Text.AlignLeft
                        visible: !trackView.showingPlaylist & searchButton.checked
                        onVisibleChanged: {
                            if (visible)
                                forceActiveFocus()
                        }

                        onTextChanged: {
                            if (text === '')
                                searcher.clear()
                        }

                        onAccepted: {
                            if (searchField.text === '')
                                return
                            // One char is a "starts with" search
                            var obj = {}
                            var str = searchField.text.length === 1
                                    ? '[%1"'.arg(searchField.text) // startsWith search
                                    : '"%1"'.arg(searchField.text) // Like search

                            searcher.mcwsSearchFields.forEach((role) => { obj[role] = str })
                            trackView.search(obj, false)
                        }
                    }
                    PlayButton {
                        enabled: trackView.searchMode & trackView.viewer.count > 0
                        visible: searchButton.checked
                        onClicked: {
                            if (trackView.showingPlaylist)
                                zoneView.currentPlayer.playPlaylist(mcws.playlists.currentID, autoShuffle)
                            else
                                zoneView.currentPlayer.searchAndPlayNow(trackView.mcwsQuery, autoShuffle)
                        }
                    }
                    AddButton {
                        enabled: trackView.searchMode & trackView.viewer.count > 0
                        visible: searchButton.checked
                        onClicked: {
                            if (trackView.showingPlaylist)
                                zoneView.currentPlayer.addPlaylist(mcws.playlists.currentID, autoShuffle)
                            else
                                zoneView.currentPlayer.searchAndAdd(trackView.mcwsQuery, true, autoShuffle)
                        }
                    }
                    SortButton {
                        id: sorter
                        visible: searchButton.checked
                        enabled: trackView.searchMode & trackView.viewer.count > 0
                    }
                }

                viewer.delegate: TrackDelegate {
                    MouseAreaEx {
                        onPressAndHold: {
                            mcws.getTrackDetails(key, (ti) => {
                                logger.log(ti)
                            })
                        }

                        onClicked: {
                            trackView.viewer.currentIndex = index
                            if (mouse.button === Qt.RightButton)
                                detailMenu.open()
                        }
                        acceptedButtons: Qt.RightButton | Qt.LeftButton
                    }

                }

                Searcher {
                    id: searcher
                    comms: mcws.comms
                    autoShuffle: plasmoid.configuration.shuffleSearch
                    mcwsFields: mcws.defaultFields()
                    onSearchBegin: busyInd.visible = true
                    onSearchDone: {
                        busyInd.visible = false
                        if (count > 0) {
                            sorter.sourceModel = searcher
                            trackView.highlightPlayingTrack()
                        }
                    }
                    onSortBegin: busyInd.visible = true
                    onSortDone: {
                        trackView.highlightPlayingTrack()
                        busyInd.visible = false
                    }
                    onDebugLogger: logger.log(obj, msg)
                }

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
                        currObj = trackView.viewer.modelItem
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
                        enabled: !trackView.isSorted
                        onTriggered: {
                            if (trackView.searchMode)
                                zoneView.currentPlayer.playTrackByKey(detailMenu.currObj.key)
                            else
                                zoneView.currentPlayer.playTrack(trackView.viewer.currentIndex)
                        }
                    }
                    MenuItem {
                        text: "Add Track"
                        onTriggered: zoneView.currentPlayer.addTrack(detailMenu.currObj.key)
                    }

                    MenuItem {
                        text: "Remove Track"
                        enabled: !trackView.searchMode & !trackView.isSorted
                        onTriggered: {
                            zoneView.currentPlayer.removeTrack(trackView.viewer.currentIndex)
                        }
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
                                playToZone.items[ndx].visible = !zoneView.isCurrent(ndx)
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
                                                    : zoneView.modelItem.trackList.items
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
            ViewerPage {
                id: lookupPage

                onViewEntered: {
                             if (viewer.count === 0) {
                                 valueSearch.itemAt(0).checked = true
                                 valueSearch.itemAt(0).action.triggered()
                             }
                         }

                header: ColumnLayout {
                    spacing: 0
                    Kirigami.BasicListItem {
                        icon: 'search'
                        separatorVisible: false
                        backgroundColor: PlasmaCore.ColorScope.highlightColor
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
                        Repeater {
                            id: valueSearch
                            // use the zone model as the model reset flag here
                            model: zoneView.modelItem ? lookup.searchActions : ''
                            ToolButton {
                                action: modelData
                                autoExclusive: true
                            }
                        }
                    }

                    SearchBar {
                        id: sb
                        list: lookupPage.viewer
                        role: "value"
                        Layout.alignment: Qt.AlignCenter
                        Layout.bottomMargin: 3
                    }

                    LookupValues {
                        id: lookup
                        sourceModel: searcher.mcwsSearchFields
                        hostUrl: mcws.comms.hostUrl
                        items.onResultsReady: sb.scrollCurrent()
                    }
                }

                viewer.useHighlight: false
                viewer.model: lookup.items
                viewer.delegate: RowLayout {
                    width: parent.width

                    Kirigami.BasicListItem {
                        text: value
                        alternatingBackground: true
                        reserveSpaceForIcon: false
                        separatorVisible: false
                        onClicked: ListView.currentIndex = index

                        PlayButton {
                            onClicked: {
                                ListView.currentIndex = index
                                zoneView.currentPlayer.searchAndPlayNow(
                                                      '[%1]="%2"'.arg(lookup.queryField).arg(value)
                                                      , autoShuffle)
                                event.queueCall(250, () => { mainView.currentIndex = 1 } )
                            }
                        }
                        AddButton {
                            onClicked: {
                                ListView.currentIndex = index
                                zoneView.currentPlayer.searchAndAdd(
                                                  '[%1]="%2"'.arg(lookup.queryField).arg(value),
                                                  false, autoShuffle)
                            }
                        }
                        SearchButton {
                            onClicked: {
                                ListView.currentIndex = index
                                let obj = {}
                                obj[lookup.queryField] = '"%2"'.arg(value)
                                trackView.search(obj)
                            }
                        }
                    }

                }
            }

        }

        PageIndicator {
            id: pi
            count: mainView.count
            visible: mcws.isConnected
            currentIndex: mainView.currentIndex
            Layout.alignment: Qt.AlignHCenter

            delegate: Rectangle {
                implicitWidth: Kirigami.Units.largeSpacing
                implicitHeight: Kirigami.Units.largeSpacing

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
        id: bkgdImg
        anchors.fill: parent
        sourceSize.height: thumbSize * 2
        fillMode: Image.PreserveAspectCrop
        opacity: mainView.currentIndex === 1 || mainView.currentIndex === 2 ? opacityTo : 0
        opacityTo: 0.07
        z: Infinity

        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.longDuration * 2 }
        }
    }

}
