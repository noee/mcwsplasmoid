import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4

import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.8 as Kirigami

import 'helpers'
import 'models'
import 'controls'
import 'actions'

Item {

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
            mainView.currentIndex = 1
            searchButton.checked = false
            trackView.mcwsQuery = ''
        }

        // Set current zone view when connection signals ready
        // (host, zonendx)
        onConnectionReady: {
            zoneView.viewer.model = mcws.zoneModel
            hostSelector.popup.visible = false

            // For each zone tracklist, catch sort reset
            mcws.zoneModel.forEach(
                (zone) => {
                    zone.trackList.sortReset.connect(() =>
                                          {
                                               trackView.highlightPlayingTrack()
                                          })
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
            sorter.sourceModel = mcws.playlists.trackModel
            trackView.highlightPlayingTrack()
            busyInd.visible = false
        }
        onSortReset: {
            trackView.highlightPlayingTrack()
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
                        mcws.playlists.filterType = 'All'
                    }
                }

                header: ColumnLayout {
                    spacing: 1
                    Kirigami.BasicListItem {
                        icon: 'view-media-playlist'
                        separatorVisible: false
                        backgroundColor: PlasmaCore.ColorScope.highlightColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
                        text: "Playlists/" + (zoneView.currentZone ? zoneView.currentZone.zonename : '')
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
                    width: ListView.view.width

                    Kirigami.BasicListItem {
                        reserveSpaceForIcon: false
                        separatorVisible: false
                        text: name + ' / ' + type
                        onClicked: mcws.playlists.currentIndex = index

                        PlayButton {
                            onClicked: {
                                mcws.playlists.currentIndex = index
                                event.queueCall(750, () => { mainView.currentIndex = 1 } )
                            }
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
                            onClicked: mcws.playlists.currentIndex = index
                            action: ShowPlaylistAction {}
                        }
                    }
                }

            }

            // Zone View
            ViewerPage {
                id: zoneView
                readonly property var currentZone: viewer.modelItem
                readonly property var currentPlayer: viewer.modelItem ? viewer.modelItem.player : null

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
                    implicitWidth: parent.width
                    padding: 2
                    backgroundColor: PlasmaCore.ColorScope.highlightColor
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
                    text: i18n("Playback Zones on: ")
                    onClicked: hostTT.showServerStatus()
                    ComboBox {
                        id: hostSelector
                        implicitWidth: Math.round(zoneView.width * 0.35)
                        model: hostModel
                        textRole: 'friendlyname'
                        onActivated: {
                            var item = model.get(currentIndex)
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
                                        if (zoneView.currentZone) {
                                            bkgdImg.sourceKey = zoneView.currentZone.filekey

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
                readonly property var currentTrack: viewer.modelItem

                property string mcwsQuery: ''
                property bool searchMode: mcwsQuery !== ''
                property bool isSorted: zoneView.currentZone
                                        ? zoneView.currentZone.trackList.sortField !== ''
                                        : false
                property bool showingPlaylist: mcwsQuery === 'playlist'

                function highlightPlayingTrack(pos) {
                    if (!zoneView.currentZone) {
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
                        let fk = +zoneView.currentZone.filekey
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
                    // Setting constraints initiates the mcws search
                    searcher.constraintList = constraints
                    mcwsQuery = searcher.constraintString
                    searchButton.checked = true

                    // show the first constraint value
                    searchField.text = constraints[Object.keys(constraints)[0]].replace(/(\[|\]|\")/g, '')

                    mainView.currentIndex = 2
                    // model delegate calling here is destroyed unless model set is "delayed"
                    event.queueCall(() => { viewer.model = searcher.items })
                }

                // Puts the view in search mode, sets the view model to the playlist tracks
                function showPlaylist() {
                    mcwsQuery = 'playlist'
                    searchButton.checked = true
                    searchField.text = ''
                    viewer.model = mcws.playlists.trackModel.items

                    mainView.currentIndex = 2
                }

                // Set the viewer to the current zone playing now
                function reset() {
                    mcwsQuery = ''
                    searchButton.checked = false
                    viewer.model = zoneView.currentZone.trackList.items
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
                                event.queueCall(500, () => { trackView.viewer.currentIndex = -1 })
                            }
                        }
                    }
                    SortButton {
                        visible: !searchButton.checked
                        sourceModel: zoneView.currentZone ? zoneView.currentZone.trackList : null
                    }
                    Button {
                        icon.name: 'shuffle'
                        visible: !searchButton.checked
                        onClicked: optionsMenu.open()

                        hoverEnabled: true

                        ToolTip.text: 'Current Playlist Options'
                        ToolTip.visible: hovered
                        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval

                        Menu {
                            id: optionsMenu
                            MenuItem {
                                action: zoneView.currentZone ? zoneView.currentPlayer.shuffle : null
                                enabled: !trackView.searchMode
                            }
                            MenuItem {
                                action: zoneView.currentZone ? zoneView.currentPlayer.clearPlayingNow : null
                                enabled: !trackView.searchMode
                            }
                            MenuSeparator{}
                            Menu {
                                title: "Send this list to Zone"
                                enabled: mcws.zoneModel.count > 1

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
                                "Playing Now" + (zoneView.currentZone
                                                  ? '/' + zoneView.currentZone.zonename
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

                        Kirigami.Icon {
                            source: 'kt-set-max-download-speed'
                            Layout.preferredWidth: Math.round(parent.height/2)
                            Layout.preferredHeight: Math.round(parent.height/2)
                            MouseAreaEx {
                                tipText: 'Bottom'
                                onClicked: {
                                    trackView.viewer.positionViewAtEnd
                                    event.queueCall(500, trackView.viewer.currentIndex = trackView.viewer.count - 1)
                                }
                            }
                        }
                        Kirigami.Icon {
                            source: 'kt-set-max-upload-speed'
                            Layout.preferredWidth: Math.round(parent.height/2)
                            Layout.preferredHeight: Math.round(parent.height/2)
                            MouseAreaEx {
                                tipText: 'Top'
                                onClicked: {
                                    trackView.viewer.currentIndex = 0
                                    trackView.viewer.positionViewAtBeginning()
                                }
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

                    SortButton {
                        id: sorter
                        visible: searchButton.checked
                        enabled: trackView.searchMode & trackView.viewer.count > 0
                    }
                }

                viewer.delegate: TrackDelegate {}

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
                                method: 'play'
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
                                useAText: true
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
                                useAText: true
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
                            visible: trackView.searchMode & !trackView.showingPlaylist
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
                            visible: trackView.showingPlaylist
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
                            model: zoneView.currentZone ? lookup.searchActions : ''
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
                    width: ListView.view.width

                    Kirigami.BasicListItem {
                        text: value
                        reserveSpaceForIcon: false
                        separatorVisible: false

                        PlayButton {
                            visible: value.length > 1
                            onClicked: {
                                zoneView.currentPlayer.searchAndPlayNow(
                                                      '[%1]="%2"'.arg(lookup.queryField).arg(value)
                                                      , autoShuffle)
                                event.queueCall(250, () => { mainView.currentIndex = 1 } )
                            }
                        }
                        AddButton {
                            visible: value.length > 1
                            onClicked: {
                                zoneView.currentPlayer.searchAndAdd(
                                                  '[%1]="%2"'.arg(lookup.queryField).arg(value),
                                                  false, autoShuffle)
                            }
                        }
                        SearchButton {
                            visible: value.length > 1
                            onClicked: {
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
