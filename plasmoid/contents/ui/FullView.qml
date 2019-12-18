import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4

import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.8 as Kirigami

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
                                trackView.viewer.model = searcher.items
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

                    onAboutToShow:  {
                        playMenu.enabled = addMenu.enabled = addMenuEnd.enabled = showMenu.enabled
                                = trackView.viewer.modelItem.mediatype === 'Audio'
                    }

                    Action {
                        text: "Play Track"
                        enabled: !trackView.isSorted
                        icon.name: 'media-playback-start'
                        onTriggered: {
                            if (trackView.searchMode)
                                zoneView.currentPlayer.playTrackByKey(trackView.viewer.modelItem.key)
                            else
                                zoneView.currentPlayer.playTrack(trackView.viewer.currentIndex)
                        }
                    }
                    Action {
                        text: "Add Track"
                        icon.name: 'list-add'
                        onTriggered: zoneView.currentPlayer.addTrack(trackView.viewer.modelItem.key)
                    }
                    Action {
                        text: "Remove Track"
                        icon.name: 'list-remove'
                        enabled: !trackView.searchMode & !trackView.isSorted
                        onTriggered: {
                            zoneView.currentPlayer.removeTrack(trackView.viewer.currentIndex)
                        }
                    }
                    MenuSeparator{}
                    Menu {
                        id: playMenu
                        title: "Play"
                        AlbumAction {
                            track: trackView.viewer.modelItem
                            onTriggered: zoneView.currentPlayer.playAlbum(track.key)
                        }
                        ArtistAction {
                            track: trackView.viewer.modelItem
                            shuffle: autoShuffle
                            method: 'play'
                        }
                        GenreAction {
                            track: trackView.viewer.modelItem
                            shuffle: autoShuffle
                            method: 'play'
                        }
                        MenuSeparator{visible: trackView.searchMode}
                        ListAction {
                            visible: trackView.searchMode
                            shuffle: autoShuffle
                        }
                    }
                    Menu {
                        id: addMenu
                        title: "Add Next to Play"
                        AlbumAction {
                            track: trackView.viewer.modelItem
                            method: 'addNext'
                        }
                        ArtistAction {
                            track: trackView.viewer.modelItem
                            method: 'addNext'
                        }
                        GenreAction {
                            track: trackView.viewer.modelItem
                            method: 'addNext'
                        }
                        MenuSeparator{visible: trackView.searchMode}
                        ListAction {
                            visible: trackView.searchMode
                            shuffle: autoShuffle
                        }
                    }
                    Menu {
                        id: addMenuEnd
                        title: "Add to End of List"
                        AlbumAction {
                            track: trackView.viewer.modelItem
                            method: 'add'
                        }
                        ArtistAction {
                            track: trackView.viewer.modelItem
                            method: 'add'
                        }
                        GenreAction {
                            track: trackView.viewer.modelItem
                            method: 'add'
                        }
                        MenuSeparator{visible: trackView.searchMode}
                        ListAction {
                            visible: trackView.searchMode
                        }
                    }
                    Menu {
                        id: showMenu
                        title: "Show"
                        AlbumAction {
                            track: trackView.viewer.modelItem
                            method: 'show'
                        }
                        ArtistAction {
                            track: trackView.viewer.modelItem
                            method: 'show'
                        }
                        GenreAction {
                            track: trackView.viewer.modelItem
                            method: 'show'
                        }
                    }
                    MenuSeparator{}
                    Menu {
                        id: playToZone
                        title: "Send this list to Zone"
                        enabled: mcws.zoneModel.count > 1

                        Repeater {
                            model: mcws.zoneModel
                            MenuItem {
                                text: zonename

                                icon.name: 'media-playback-start'
                                onTriggered: {
                                    mcws.sendListToZone(trackView.searchMode
                                                        ? trackView.showingPlaylist
                                                          ? mcws.playlists.trackModel.items
                                                          : searcher.items
                                                        : zoneView.modelItem.trackList.items
                                                        , index)
                                }
                            }
                        }

                        onAboutToShow: {
                            mcws.zoneModel.forEach((zone, ndx) => {
                                playToZone.itemAt(ndx).visible = !zoneView.isCurrent(ndx)
                            })
                        }

                    }
                    MenuSeparator{}
                    MenuItem {
                        action: zoneView.modelItem ? zoneView.modelItem.player.shuffle : null
                        enabled: !trackView.searchMode
                    }
                    MenuItem {
                        action: zoneView.modelItem ? zoneView.modelItem.player.clearZone : null
                        enabled: !trackView.searchMode
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
