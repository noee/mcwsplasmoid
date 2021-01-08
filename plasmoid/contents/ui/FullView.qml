import QtQuick 2.9
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.4

import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.extras 2.0 as PE
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PComp

import 'helpers'
import 'models'
import 'controls'
import 'actions'

Item {
    // FullView is lazy-loaded, so the connections to the mcws item
    // will not catch the initial mcws connect on applet creation.
    // So, we need to (re)set the model for the zoneviewer when
    // the applet expands and it's not yet set.
    Plasmoid.onExpandedChanged: {
        if (plasmoid.expanded && mcws.isConnected && zoneView.count === 0) {
            event.queueCall(() => {
                                zoneView.model = ''
                                zoneView.model = mcws.zoneModel
                            })
        }
    }

    Connections {
        target: mcws

        // If the playing position changes for the current zone
        // (zonendx, pos)
        onPnPositionChanged: {
            if (mcws.isConnected
                    && zoneView.isCurrent(zonendx)
                    && !trackView.searchMode) {
                trackView.highlightPlayingTrack(pos)
            }
        }

        // update current zone current image for backgrounds
        onTrackKeyChanged: {
            if (mcws.isConnected
                    && zoneView.isCurrent(zonendx))
                event.queueCall(1000, () => currentTrackImage.sourceKey = filekey)
        }

        // Initialize some vars when a connection starts
        // (host)
        onConnectionStart: {
            zoneView.model = ''
            trackView.model = ''
            searchButton.checked = false
            trackView.mcwsQuery = ''
            searcher.init()
        }

        // Connection error or a host reset to null
        onConnectionStopped: {
            zoneView.model = ''
            trackView.model = ''
            mainView.currentIndex = 1
        }

        // Set current zone view when connection signals ready
        // (host, zonendx)
        onConnectionReady: {
            zoneView.model = mcws.zoneModel

            // For each zone tracklist, catch sort reset
            mcws.zoneModel.forEach(zone => {
                zone.trackList.sortReset.connect(trackView.highlightPlayingTrack)
            })

            mainView.currentIndex = 1
        }

        // On error, reset view to the zoneview page
        // (msg, cmd)
        onCommandError: {
            if (cmd.includes(mcws.host)) {
                mainView.currentIndex = 1
                hostTT.showServerStatus()
            }
        }
    }
    Connections {
        target: plasmoidRoot

        // The host model (config) changes
        // needed for config change, currentIndex not being set when model resets (BUG?)
        // (currentHost)
        onHostModelChanged: {
            hostSelector.currentIndex = mcws.host !== ''
                    ? hostModel.findIndex((item) => { return item.host === currentHost })
                    : 0
        }

        // When a zone is clicked in compact view
        onZoneSelected: { zoneView.set(zonendx) }

        // Compact view is asking for a connection attempt
        onTryConnection: {
            if (hostModel.count > 0 && hostSelector.currentIndex !== -1)
                mcws.hostConfig = hostModel.get(hostSelector.currentIndex)
        }
    }
    Connections {
        target: mcws.playlists.trackModel
        enabled: mcws.isConnected

        // Handle playlist track searching/display
        onSearchBegin: busyInd.visible = true
        onSearchDone: {
            busyInd.visible = false
            trackView.highlightPlayingTrack()
            sorter.target = mcws.playlists.trackModel
        }
        onSortReset: {
            trackView.highlightPlayingTrack()
        }
    }

    // keep an image for backgrounds,
    // current zone, current track image
    TrackImage {
        id: currentTrackImage
        visible: false
        animateLoad: false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        SwipeView {
            id: mainView
            Layout.fillHeight: true
            Layout.fillWidth: true
            interactive: mcws.isConnected
            spacing: PlasmaCore.Units.smallSpacing
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
                id: playlistView

                // Lazy load
                onViewEntered: {
                    if (viewer.count === 0) {
                        mcws.playlists.load()
                        viewer.model = mcws.playlists.items
                    }
                }

                background: BackgroundHue {
                    source: currentTrackImage
                    opacity: .3
                }

                header: RowLayout {
                    PE.Heading {
                        Layout.fillWidth: true
                        level: 2
                        text: "Playlists [%1]".arg((zoneView.currentZone
                                             ? zoneView.currentZone.zonename
                                             : ''))
                    }
                    Repeater {
                        id: plActions
                        model: mcws.playlists.searchActions
                        PComp.Button {
                            checkable: true
                            action: modelData
                            autoExclusive: true
                        }
                    }
                }

                viewer.useHighlight: false
                viewer.delegate: RowLayout {
                    width: ListView.view.width

                    Kirigami.BasicListItem {
                        icon: mcws.playlists.icon(type)
                        separatorVisible: false
                        text: name
                        subtitle: path
                        onClicked: mcws.playlists.currentIndex = index

                        PlayButton {
                            onClicked: mcws.playlists.currentIndex = index
                            action: PlayPlaylistAction {
                                text: ''
                                shuffle: autoShuffle
                            }
                        }
                        AddButton {
                            onClicked: mcws.playlists.currentIndex = index
                            action: AddPlaylistAction {
                                text: ''
                                shuffle: autoShuffle
                            }
                        }
                        SearchButton {
                            checkable: false
                            onClicked: {
                                mcws.playlists.currentIndex = index
                                trackView.showPlaylist()
                            }
                        }
                    }
                }

            }

            // Zones and Tracks list View
            GridLayout {
                id: grid
                columns: 2

                // virtual for swipe item interface
                signal viewEntered()

                // Zoneview header
                RowLayout {
                    PE.Heading {
                        level: 2
                        text: i18n("Playback Zones on: ")
                        MouseArea {
                            anchors.fill: parent
                            onClicked: hostTT.showServerStatus()
                        }
                    }

                    ComboBox {
                        id: hostSelector
                        Layout.fillWidth: true
                        model: hostModel
                        textRole: 'friendlyname'
                        onActivated: {
                            mcws.hostConfig = model.get(currentIndex)
                        }
                    }

                }
                // Trackview header
                RowLayout {
                    spacing: 1
                    opacity: mcws.isConnected ? 1 : 0

                    // Enter/exit search mode
                    SearchButton {
                        id: searchButton
                        icon.name: checked ? 'edit-undo' : 'search'
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
                                sorter.target = searcher
                                trackView.model = searcher.items
                                trackView.mcwsQuery = searcher.constraintString
                            }
                        }
                    }

                    // Sort the current tracklist
                    // Search list, playlist or playing now
                    SortButton { id: sorter }

                    // Page heading
                    PE.Heading {
                        Layout.fillWidth: true
                        horizontalAlignment: Qt.AlignRight
                        level: 3
                        visible: trackView.showingPlaylist | !searchButton.checked
                        text: {
                            if (trackView.showingPlaylist)
                                'Playlist: "%1"'.arg(mcws.playlists.currentName)
                            else
                                'Now Playing'
//                                "Playing Now" + (zoneView.currentZone
//                                                  ? ' [%1]'.arg(zoneView.currentZone.zonename)
//                                                  : "")
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (searchButton.checked)
                                    trackView.reset()
                                else
                                    trackView.highlightPlayingTrack()
                            }
                        }
                    }

                    // Search text entry
                    Kirigami.SearchField {
                        id: searchField
                        placeholderText: 'Enter search'
                        font.pointSize: PlasmaCore.Theme.defaultFont.pointSize-1
                        Layout.fillWidth: true
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
                            trackView.search(searchField.text.length === 1
                                                 ? '[%1"'.arg(searchField.text) // startsWith search
                                                 : '"%1"'.arg(searchField.text) // Like search
                                             , false)
                        }
                    }

                    // Playlist view or search view
                    // Play the current list
                    PlayButton {
                        action: PlaySearchListAction {
                            text: ''
                            shuffle: autoShuffle
                        }
                        visible: searchButton.checked & !trackView.showingPlaylist
                    }
                    PlayButton {
                        action: PlayPlaylistAction {
                            text: ''
                            shuffle: autoShuffle
                        }
                        visible: trackView.showingPlaylist
                    }

                    // Add the current list
                    AddButton {
                        action: AddSearchListAction {
                            text: ''
                            shuffle: autoShuffle
                        }
                        visible: searchButton.checked & !trackView.showingPlaylist
                    }
                    AddButton {
                        action: AddPlaylistAction {
                            text: ''
                            shuffle: autoShuffle
                        }
                        visible: trackView.showingPlaylist
                    }

                    // Button popup to select search fields
                    SearchFieldsButton {
                        visible: !trackView.showingPlaylist & searchButton.checked
                        target: searcher
                    }

                }

                // Zone Viewer
                Viewer {
                    id: zoneView
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth: Math.round(grid.width*.4)
                    spacing: 2
                    useHighlight: false

                    readonly property var currentZone: modelItem
                    readonly property var currentPlayer: modelItem
                                                         ? modelItem.player
                                                         : null

                    function set(zonendx) {
                        // Form factor constraints, vertical do nothing
                        if (vertical) {
                            if (zoneView.currentIndex === -1)
                                zoneView.currentIndex = mcws.getPlayingZoneIndex()
                        }
                        // Inside a panel...
                        else {
                            // no zone change, do nothing
                            if (zonendx === zoneView.currentIndex)
                                return

                            zoneView.currentIndex = zonendx !== -1
                                    ? zonendx
                                    : mcws.getPlayingZoneIndex()
                        }
                    }
                    function isCurrent(zonendx) {
                        return zonendx === zoneView.currentIndex
                    }

                    PE.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (PlasmaCore.Units.largeSpacing * 4)

                        visible: zoneView.count === 0

                        text: hostTT.text

                        helpfulAction: Kirigami.Action {
                            iconName: "configure"
                            text: "Check MCWS Config..."
                            onTriggered: {
                                plasmoid.action('configure').trigger()
                            }
                        }
                    }

                    delegate: ZoneDelegate {
                        onClicked: ListView.view.currentIndex = index
                        onZoneClicked: ListView.view.currentIndex = zonendx
                    }

                    onCurrentIndexChanged: {
                        event.queueCall(() => {
                            if (zoneView.currentZone) {
                                currentTrackImage.sourceKey = zoneView.currentZone.filekey
                                if (!trackView.searchMode)
                                    trackView.reset()

                                logger.log('GUI:ZoneChanged'
                                           , '=> %1, TrackList Cnt: %2'.arg(currentIndex).arg(trackView.model.count))
                            }
                        })
                    }

                }

                // Track Viewer
                Viewer {
                    id: trackView

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth: Math.round(grid.width*.45)

                    useHighlight: false

                    readonly property var currentTrack: modelItem

                    property string mcwsQuery: ''
                    property bool searchMode: mcwsQuery !== ''
                    property bool showingPlaylist: mcwsQuery === 'playlist'

                    function highlightPlayingTrack(pos) {
                        if (trackView.count === 0) {
                            return
                        }

                        // HACK: force delegate to reload duration (show pos display)
                        let swapDur = () => {
                            if (trackView.currentTrack) {
                                let tmp = trackView.currentTrack.duration
                                trackView.currentTrack.duration = ''
                                trackView.currentTrack.duration = tmp
                            }
                        }

                        if (pos !== undefined) {
                            currentIndex = zoneView.currentZone.trackList.items.mapRowFromSource(pos)
                            positionViewAtIndex(currentIndex, ListView.Center)
                            if (currentIndex !== 0)
                                event.queueCall(trackView.currentItem.animateTrack)
                            swapDur()
                            return
                        }

                        if (!searchMode | plasmoid.configuration.showPlayingTrack) {
                            let fk = +zoneView.currentZone.filekey
                            let ndx = model.findIndex(item => +item.key === fk)
                            currentIndex = ndx === -1 ? 0 : ndx
                            positionViewAtIndex(currentIndex, ListView.Center)
                            if (currentIndex !== 0)
                                event.queueCall(trackView.currentItem.animateTrack)
                            swapDur()
                        }
                    }

                    // contraints can be a string or obj. obj should be of form:
                    // { artist: value, album: value, genre: value, etc.... }
                    // if str is passed, then default search fields are used
                    function search(constraints, andTogether) {

                        searcher.logicalJoin = (andTogether === true || andTogether === undefined ? 'and' : 'or')

                        // Initiate search
                        if (typeof constraints === 'object') {
                            searcher.search(constraints)
                            searchField.text = constraints[Object.keys(constraints)[0]].replace(/(\[|\]|\")/g, '')
                        } else if (typeof constraints === 'string') {
                            searcher.search(constraints)
                            searchField.text = constraints.replace(/(\[|\]|\")/g, '')
                        } else {
                            console.warn('Search contraints should be object or string. Obj should be of form: { artist: value, album: value, genre: value, etc.... }')
                            return
                        }

                        mcwsQuery = searcher.constraintString
                        searchButton.checked = true
                        mainView.currentIndex = 1
                        // model delegate calling here is destroyed unless model set is "delayed"
                        event.queueCall(() => { model = searcher.items })
                    }

                    // Puts the view in search mode,
                    // sets the view model to the playlist tracks
                    // and loads the model
                    function showPlaylist() {
                        mainView.currentIndex = 1
                        mcwsQuery = 'playlist'
                        searchButton.checked = true
                        model = mcws.playlists.trackModel.items
                        mcws.playlists.trackModel.load()
                    }

                    // Set the viewer to the current zone playing now
                    function reset() {
                        mcwsQuery = ''
                        searchButton.checked = false
                        model = zoneView.currentZone.trackList.items
                        sorter.target = zoneView.currentZone.trackList
                        event.queueCall(750, highlightPlayingTrack)
                    }

                    PE.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (PlasmaCore.Units.largeSpacing * 4)

                        visible: trackView.count === 0 && !searchButton.checked

                        text: mcws.isConnected && zoneView.currentZone
                              ? (searchButton.checked
                                      ? "Searching...Please Wait..."
                                      : "No tracks in current playlist on\n"
                                        + zoneView.currentZone.zonename)
                              : 'Not connected'
                    }

                    delegate: TrackDelegate { }

                    Searcher {
                        id: searcher
                        comms: mcws.comms
                        autoShuffle: plasmoid.configuration.shuffleSearch
                        mcwsFields: mcws.mcwsFieldsModel

                        onSearchBegin: busyInd.visible = true
                        onSearchDone: {
                            busyInd.visible = false
                            trackView.highlightPlayingTrack()
                            sorter.target = searcher
                        }

                        onSortReset: {
                            trackView.highlightPlayingTrack()
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

                    Popup {
                        id: trkCmds
                        focus: true
                        padding: 2
                        spacing: 0

                        parent: Overlay.overlay

                        x: Math.round((parent.width - width) / 2)
                        y: Math.round((parent.height - height) / 2)

                        ColumnLayout {
                            spacing: 0

                            // album
                            ToolButton {
                                action: AlbumAction {
                                    useAText: true
                                    icon.name: 'enjoy-music-player'
                                    method: 'play'
                                }
                                ToolTip {
                                    text: 'Play Album'
                                }
                            }
                            RowLayout {
                                spacing: 0
                                ToolButton { action: AlbumAction { method: 'addNext' } }
                                ToolButton { action: AlbumAction { method: 'add' } }
                                ToolButton { action: AlbumAction { method: 'show' } }
                            }

                            GroupSeparator{}

                            // artist
                            ToolButton {
                                action: ArtistAction {
                                    shuffle: autoShuffle
                                    method: 'play'
                                    icon.name: 'enjoy-music-player'
                                    useAText: true
                                }
                                ToolTip {
                                    text: 'Play Artist'
                                }
                            }
                            RowLayout {
                                spacing: 0
                                ToolButton {
                                    action: ArtistAction {
                                        method: 'addNext'
                                        shuffle: autoShuffle
                                    }

                                }
                                ToolButton {
                                    action: ArtistAction {
                                        method: 'add'
                                        shuffle: autoShuffle
                                    }
                                }
                                ToolButton {
                                    action: ArtistAction {
                                        method: 'show'
                                        shuffle: autoShuffle
                                    }
                                }
                            }

                            GroupSeparator{}

                            // genre
                            ToolButton {
                                action: GenreAction {
                                    shuffle: autoShuffle
                                    method: 'play'
                                    icon.name: 'enjoy-music-player'
                                    useAText: true
                                }
                                ToolTip {
                                    text: 'Play Genre'
                                }
                            }
                            RowLayout {
                                spacing: 0
                                ToolButton {
                                    action: GenreAction {
                                        method: 'addNext'
                                        shuffle: autoShuffle
                                    }

                                }
                                ToolButton {
                                    action: GenreAction {
                                        method: 'add'
                                        shuffle: autoShuffle
                                    }
                                }
                                ToolButton {
                                    action: GenreAction {
                                        method: 'show'
                                        shuffle: autoShuffle
                                    }
                                }
                            }

                            GroupSeparator { visible: trackView.searchMode }

                            // Search results
                            ToolButton {
                                action: PlaySearchListAction { useAText: true }
                                icon.name: 'enjoy-music-player'
                                visible: trackView.searchMode & !trackView.showingPlaylist
                                ToolTip {
                                    text: 'Play Search Results'
                                }
                            }
                            RowLayout {
                                spacing: 0
                                visible: trackView.searchMode & !trackView.showingPlaylist

                                ToolButton {
                                    action: AddSearchListAction {
                                        method: 'addNext'
                                        shuffle: autoShuffle
                                    }
                                }
                                ToolButton {
                                    action: AddSearchListAction {
                                        shuffle: autoShuffle
                                    }
                                }
                            }

                            // Playlist
                            ToolButton {
                                action: PlayPlaylistAction { useAText: true }
                                icon.name: 'enjoy-music-player'
                                visible: trackView.showingPlaylist
                                ToolTip {
                                    text: 'Play Search Results'
                                }
                            }
                            RowLayout {
                                spacing: 0
                                visible: trackView.showingPlaylist

                                ToolButton {
                                    action: AddPlaylistAction {
                                        method: 'addNext'
                                        shuffle: autoShuffle
                                    }
                                }
                                ToolButton {
                                    action: AddPlaylistAction {
                                        shuffle: autoShuffle
                                    }
                                }
                            }

                        }
                    }

                }
            }

            // Quick search lookups
            ViewerPage {
                id: lookupPage

                onViewEntered: {
                    if (viewer.count === 0) {
                        // default to first search option
                        mcws.quickSearch.queryField = lookupButtons.itemAt(0).text
                        lookupButtons.itemAt(0).checked = true
                        lookupButtons.itemAt(0).clicked()
                    }
                }

                // QS returns a query type for field or filter
                // Catch the signal, set the scroll bar view
                Component.onCompleted: {
                    mcws.quickSearch
                        .resultsReady
                        .connect(type => {
                            if (type === 0) {
                                sb.scrollCurrent()
                                lSrch.clear()
                                sb.visible = true
                            } else {
                                sb.reset()
                                sb.visible = false
                            }
                    })
                }

                header: ColumnLayout {
                    RowLayout {
                        PE.Heading {
                            text: 'Library Search'
                            level: 2
                            Layout.fillWidth: true
                        }

                        Repeater {
                            id: lookupButtons
                            model: mcws.mcwsFieldsModel
                            delegate: PComp.Button {
                                checkable: true
                                text: field
                                visible: searchable
                                autoExclusive: true
                                checked: text === mcws.quickSearch.queryField
                                onClicked: mcws.quickSearch.queryField = text
                                icon.name: mcws.quickSearch.icon(text)
                            }
                        }

                        Kirigami.SearchField {
                            id: lSrch
                            onAccepted: mcws.quickSearch.queryFilter = text
                        }

                        CheckButton {
                            icon.name: checked ? 'music-note-16th' : 'media-optical-mixed-cd'
                            checked: mcws.quickSearch.mediaType === 'audio'
                            autoExclusive: false
                            onCheckedChanged: mcws.quickSearch.mediaType = checked ? 'audio' : ''
                            ToolTip.text: checked ? 'Showing Audio Only' : 'Showing All Media'
                            ToolTip.visible: hovered
                            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                        }

                    }

                    SearchBar {
                        id: sb
                        list: lookupPage.viewer
                        role: "value"
                        Layout.alignment: Qt.AlignCenter
                    }
                }

                background: BackgroundHue {
                    source: currentTrackImage
                    opacity: .3
                }

                viewer.model: mcws.quickSearch.items
                viewer.useHighlight: false

                viewer.delegate: RowLayout {
                    width: ListView.view.width

                    Kirigami.BasicListItem {
                        text: value
                        icon: mcws.quickSearch.icon(field === ''
                                                    ? mcws.quickSearch.queryField
                                                    : field, value)

                        separatorVisible: false

                        PlayButton {
                            visible: value.length > 1
                            onClicked: {
                                zoneView
                                .currentPlayer
                                .searchAndPlayNow(
                                  '[%1]="%2"'.arg(field !== '' ? field : mcws.quickSearch.queryField)
                                             .arg(value), autoShuffle)
                                event.queueCall(250, () => mainView.currentIndex = 1 )
                            }
                        }
                        AddButton {
                            visible: value.length > 1
                            onClicked: {
                                zoneView
                                .currentPlayer
                                .searchAndAdd(
                                    '[%1]="%2"'.arg(field !== '' ? field : mcws.quickSearch.queryField)
                                               .arg(value), false, autoShuffle)
                            }
                        }
                        SearchButton {
                            visible: value.length > 1
                            onClicked: {
                                let obj = {}
                                obj[field !== ''
                                    ? field
                                    : mcws.quickSearch.queryField] = '"%1"'.arg(value)
                                trackView.search(obj)
                            }
                        }
                    }

                }
            }

        }

        // Footer
        RowLayout {
            visible: mcws.isConnected
            spacing: PlasmaCore.Units.smallSpacing*2
            Layout.topMargin: PlasmaCore.Units.smallSpacing

            PlasmaCore.IconItem {
                source: 'player_playlist'
                Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
                Layout.preferredHeight: PlasmaCore.Units.iconSizes.small

                MouseAreaEx {
                    tipText: 'Global Optons'
                    onClicked: globalMenu.popup()
                }
            }

            Item {
                Layout.fillWidth: true
            }

            PageIndicator {
                id: pi
                count: mainView.count
                visible: mcws.isConnected
                currentIndex: mainView.currentIndex

                delegate: Rectangle {
                    implicitWidth: PlasmaCore.Units.iconSizes.small
                    implicitHeight: PlasmaCore.Units.iconSizes.small

                    radius: width / 2
                    color: PlasmaCore.Theme.highlightColor

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

            Item {
                Layout.fillWidth: true
            }

            PlasmaCore.IconItem {
                source: 'send-to'
                visible: mainView.currentIndex === 1 && trackView.count > 0
                Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
                Layout.preferredHeight: PlasmaCore.Units.iconSizes.small

                MouseAreaEx {
                    tipText: 'Send the Current Playlist'
                    onClicked: optionsMenu.popup()
                }
            }

            BottomIcon {
                onClicked: {
                    switch (mainView.currentIndex) {
                        case 0: playlistView.viewer.currentIndex = playlistView.viewer.count - 1; break;
                        case 1: trackView.currentIndex = trackView.count - 1; break;
                        case 2: lookupPage.viewer.currentIndex = lookupPage.viewer.count - 1; break;
                    }
                }
            }
            TopIcon {
                onClicked: {
                    switch (mainView.currentIndex) {
                        case 0: playlistView.viewer.currentIndex = 0; break;
                        case 1: trackView.currentIndex = 0; break;
                        case 2: lookupPage.viewer.currentIndex = 0; break;
                    }
                }
            }
        }

        Menu {
            id: globalMenu
            MenuItem { action: mcws.clearAllZones }
            MenuItem { action: mcws.stopAllZones }
            MenuSeparator {}
            MenuItem {
                text: 'Refresh View'
                icon.name: 'view-refresh'
                enabled: mcws.isConnected
                onTriggered: mcws.reset()
            }
            MenuItem {
                text: 'Close Connection'
                icon.name: 'network-disconnected'
                enabled: mcws.isConnected
                onTriggered: action_close()
            }
            MenuSeparator {}
            MenuItem {
                text: plasmoid.hideOnWindowDeactivate
                        ? 'Pin to Desktop'
                        : 'Unpin from Desktop'
                icon.name: plasmoid.hideOnWindowDeactivate
                            ? "window-pin"
                            : 'window-unpin'
                onTriggered: plasmoid.hideOnWindowDeactivate = !plasmoid.hideOnWindowDeactivate
            }
        }

        Menu {
            id: optionsMenu
            enabled: trackView.count > 0

            Repeater {
                model: mcws.zoneModel
                MenuItem {
                    text: zonename
                    visible: !zoneView.isCurrent(index)
                    icon.name: 'media-playback-start'
                    onTriggered: {
                        mcws.sendListToZone(trackView.searchMode
                                            ? trackView.showingPlaylist
                                              ? mcws.playlists.trackModel.items
                                              : searcher.items
                                            : zoneView.currentZone.trackList.items
                                            , index)
                    }
                }
            }
        }

    }
}
