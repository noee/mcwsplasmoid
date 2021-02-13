import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.13

import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.extras 2.0 as PE
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PComp
import QtGraphicalEffects 1.12

import 'helpers'
import 'models'
import 'controls'
import 'actions'

Item {
    property bool useTheme:       plasmoid.configuration.useTheme
    property bool radialTheme:    plasmoid.configuration.themeRadial

    property bool useCoverArt:    useTheme
                                  && plasmoid.configuration.themeName === 'Cover Art'
    property bool useDefaultBkgd: useTheme
                                  && plasmoid.configuration.themeName === 'Default'

    property Component bkgdComp: useDefaultBkgd | useCoverArt
                                   ? hueComp
                                   : useTheme
                                     ? (radialTheme ? radComp : gradComp)
                                     : null

    Connections {
        target: mcws

        // If the playing position changes for the current zone
        // (zonendx, pos)
        onPnPositionChanged: {
            if (mcws.isConnected
                    && zoneView.isCurrent(zonendx)
                    && !trackView.searchMode) {
                event.queueCall(500, trackView.highlightPlayingTrack)
            }
        }

        // update current zone current image for backgrounds
        // (zonendx, filekey)
        onTrackKeyChanged: {
            if (mcws.isConnected
                    && zoneView.isCurrent(zonendx))
                event.queueCall(1000, currentTrackImage.setSourceKey, filekey)
        }

        // Initialize some vars when a connection starts
        // (host)
        onConnectionStart: {
            zoneView.model = ''
            trackView.model = ''
            imageErrorKeys = {'-1': true}  // fallback image key
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
            event.queueCall(500, trackView.highlightPlayingTrack)
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
                    ? hostModel.findIndex(item => item.host === currentHost)
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
        onSortReset: trackView.highlightPlayingTrack()
    }

    /* Background color theming
    *   If on, checks for "Default" option
    *   and uses the default image.
    *   Cover art option use per track cover art
    */
    // theme list (defined in config)
    QtObject {
        id: themes

        // {name, c1, c2}
        property var list: []
        property string color1
        property string color2

        function setColors() {
            list.forEach(t => {
                 if (t.name === plasmoid.configuration.themeName) {
                    if (plasmoid.configuration.themeDark) {
                         color1 = Qt.darker(t.c1)
                         color2 = Qt.darker(t.c2)
                    } else {
                         color1 = Qt.lighter(t.c1)
                         color2 = Qt.lighter(t.c2)
                    }
                    return
                  }
             })
        }

        Component.onCompleted: {
            JSON.parse(plasmoid.configuration.themes)
                .forEach(t => list.push(t))
            setColors()
        }
    }

    Connections {
        target: plasmoid.configuration

        onUseThemeChanged: { themes.setColors(); currentTrackImage.setSourceKey() }
        onThemeNameChanged: { themes.setColors(); currentTrackImage.setSourceKey() }
        onThemeDarkChanged: themes.setColors()
    }

    // current zone/track image used for background hue
    TrackImage {
        id: currentTrackImage
        visible: false
        animateLoad: false

        function setSourceKey(key) {
            sourceKey = useDefaultBkgd | key === undefined
                    ? '-1'
                    : key
        }
    }

    Component {
        id: hueComp
        BackgroundHue {
            source: currentTrackImage
            opacity: useDefaultBkgd | useCoverArt
                        ? plasmoid.configuration.themeDark ? .5 : 1
                        : 1
            lightness: useDefaultBkgd | useCoverArt
                        ? plasmoid.configuration.themeDark ? -0.5 : 0.0
                        : -0.4
        }
    }

    Component {
        id: radComp
        RadialGradient {
            opacity: .75
            gradient: Gradient {
                GradientStop { position: 0.0; color: themes.color1 }
                GradientStop { position: 0.5; color: 'black' }
            }
        }
    }

    Component {
        id: gradComp
        Rectangle {
            opacity: .75
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: themes.color1 }
                GradientStop { position: 0.45; color: themes.color2 }
                GradientStop { position: 1.0; color: "black" }
            }
        }
    }
    // End theming components

    ColumnLayout {
        anchors.fill: parent

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

                background: Loader {
                    sourceComponent: bkgdComp
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
                            delegate: PComp.Button {
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
                            action: PlayPlaylistAction {
                                text: ''
                                shuffle: autoShuffle
                                onTriggered: mcws.playlists.currentIndex = index
                            }
                        }
                        AddButton {
                            action: AddPlaylistAction {
                                text: ''
                                shuffle: autoShuffle
                                onTriggered: mcws.playlists.currentIndex = index
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

            // Zones and Tracks View, 2 columns
            // first is zone view, second is track view
            SplitView {
                // virtual for swipe item interface
                signal viewEntered()

                handle: Rectangle {
                    implicitWidth: PlasmaCore.Units.smallSpacing
                    implicitHeight: PlasmaCore.Units.smallSpacing
                    color: SplitHandle.pressed
                           ? "#81e889"
                           : (SplitHandle.hovered
                                ? Qt.lighter(PlasmaCore.Theme.disabledTextColor, 1.3)
                                : PlasmaCore.Theme.disabledTextColor)
                }

                ColumnLayout {
                    SplitView.preferredWidth: Math.round(mainView.width/2)
                    SplitView.minimumWidth: Math.round(mainView.width/4)

                    // Zoneview header
                    RowLayout {

                        ToolButton {
                            icon.name: 'configure'
                            onClicked: globalMenu.popup()
                            ToolTip {
                                text: 'General Options'
                            }
                        }

                        PE.Heading {
                            level: 2
                            text: i18n("Playback Zones on: ")
                            MouseAreaEx {
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

                    // Zone Viewer
                    Viewer {
                        id: zoneView
                        model: mcws.zoneModel
                        Layout.fillHeight: true
                        Layout.fillWidth: true
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
                                if (isCurrent(zonendx))
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
                            if (currentIndex === -1)
                                return

                            let z = zoneView.model.get(currentIndex)
                            currentTrackImage.setSourceKey(z.filekey)
                            if (!trackView.searchMode)
                                trackView.reset(z)

                            logger.log('GUI:ZoneChanged'
                                       , '%3, index: %1, TrackList Cnt: %2'
                                           .arg(currentIndex)
                                           .arg(trackView.model.count)
                                           .arg(z.zonename))
                        }

                    }
                }

                ColumnLayout {
                    SplitView.minimumWidth: Math.round(mainView.width/4)

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

                        // play/add Playlist
                        PlayButton {
                            action: PlayPlaylistAction {
                                text: ''
                                shuffle: autoShuffle
                            }
                            visible: trackView.showingPlaylist
                        }
                        AddButton {
                            action: AddPlaylistAction {
                                text: ''
                                shuffle: autoShuffle
                            }
                            visible: trackView.showingPlaylist
                        }

                        // Page heading
                        PE.Heading {
                            Layout.fillWidth: true
                            horizontalAlignment: Qt.AlignRight
                            level: 2
                            visible: trackView.showingPlaylist | !searchButton.checked
                            text: trackView.showingPlaylist
                                    ? '"%1"'.arg(mcws.playlists.currentName)
                                    : 'Now Playing'

                            MouseAreaEx {
                                tipText: trackView.showingPlaylist
                                            ? 'Library Playlist'
                                            : zoneView.currentZone
                                                 ? zoneView.currentZone.zonename
                                                 : ''
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

                        // Play/add the current list
                        PlayButton {
                            action: PlaySearchListAction {
                                text: ''
                                shuffle: autoShuffle
                            }
                            visible: searchButton.checked & !trackView.showingPlaylist
                        }
                        AddButton {
                            action: AddSearchListAction {
                                text: ''
                                shuffle: autoShuffle
                            }
                            visible: searchButton.checked & !trackView.showingPlaylist
                        }

                    }

                    // Track Viewer
                    Viewer {
                        id: trackView

                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        useHighlight: false

                        readonly property var currentTrack: modelItem

                        property string mcwsQuery: ''
                        property bool searchMode: mcwsQuery !== ''
                        property bool showingPlaylist: mcwsQuery === 'playlist'

                        function highlightPlayingTrack() {
                            if (trackView.count === 0) return
                            if (searchMode
                                    & !plasmoid.configuration.showPlayingTrack)
                                return


                            let fk = +zoneView.currentZone.filekey
                            let ndx = model.findIndex(item => +item.key === fk)
                            currentIndex = ndx === -1 ? 0 : ndx
                            positionViewAtIndex(currentIndex, ListView.Center)
                            if (currentIndex !== 0)
                                event.queueCall(trackView.currentItem.animateTrack)

                            // HACK: force delegate to reload duration (show pos display)
                            if (trackView.currentTrack) {
                                let tmp = trackView.currentTrack.duration
                                trackView.currentTrack.duration = ''
                                trackView.currentTrack.duration = tmp
                            }
                        }

                        // contraints can be a string or obj. obj should be of form:
                        // { artist: value, album: value, genre: value, etc.... }
                        // if str is passed, then default search fields are used
                        function search(constraints, andTogether) {
                            model = searcher.items
                            searcher.logicalJoin = (andTogether === true || andTogether === undefined
                                                    ? 'and' : 'or')
                            searcher.search(constraints)

                            searchField.text = (typeof constraints === 'object')
                                ? constraints[Object.keys(constraints)[0]].replace(/(\[|\]|\")/g, '')
                                : constraints.replace(/(\[|\]|\")/g, '')

                            mcwsQuery = searcher.constraintString
                            searchButton.checked = true
                            mainView.currentIndex = 1
                        }

                        // Puts the view in search mode,
                        // sets the view model to the playlist tracks
                        // and loads the model
                        function showPlaylist() {
                            mcwsQuery = 'playlist'
                            searchButton.checked = true
                            mainView.currentIndex = 1
                            model = mcws.playlists.trackModel.items
                            mcws.playlists.trackModel.load()
                        }

                        // Set the viewer to the zone playing now
                        // and exit search mode
                        function reset(zone) {
                            zone = zone === undefined ? zoneView.currentZone : zone
                            mcwsQuery = ''
                            searchButton.checked = false
                            model = zone.trackList.items
                            sorter.target = zone.trackList
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

                        BusyIndicator {
                            id: busyInd
                            visible: false
                            anchors.centerIn: parent
                            implicitWidth: parent.width/4
                            implicitHeight: implicitWidth
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

                background: Loader {
                    sourceComponent: bkgdComp
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

        // Library searcher
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

            onSortReset: trackView.highlightPlayingTrack()

            onDebugLogger: logger.log(title, msg, obj)
        }

        // Footer
        RowLayout {
            visible: mcws.isConnected
        
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
                        PropertyAnimation { duration: 500 }
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

            ToolButton {
                icon.name: 'send-to'
                visible: mainView.currentIndex === 1 && trackView.count > 0
                ToolTip {
                    text: 'Send the Current Playlist'
                }
                onClicked: optionsMenu.popup()
            }

            ListBottom {
                onClicked: {
                    switch (mainView.currentIndex) {
                        case 0: playlistView.viewer.currentIndex = playlistView.viewer.count - 1; break;
                        case 1: trackView.currentIndex = trackView.count - 1; break;
                        case 2: lookupPage.viewer.currentIndex = lookupPage.viewer.count - 1; break;
                    }
                }
            }
            ListTop {
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
            MenuItem {
                text: 'Set Search Fields...'
                icon.name: "search"
                enabled: mcws.isConnected
                onTriggered: {
                    fldsPopup.target = searcher
                    fldsPopup.open(globalMenu)
                }
            }
            MenuSeparator {}
            MenuItem { action: mcws.clearAllZones; enabled: mcws.isConnected }
            MenuItem { action: mcws.stopAllZones; enabled: mcws.isConnected }
            MenuSeparator {}
            MenuItem {
                enabled: mcws.isConnected
                text: (ss.screenSaverMode ? 'Stop' : 'Start') + ' Screensaver'
                icon.name: ss.screenSaverMode ? 'stop' : 'preferences-desktop-screensaver-symbolic'
                onTriggered: action_screensaver()
            }
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

        // Search fields popup
        Popup {
            id: fldsPopup
            focus: true
            padding: 2
            spacing: 0

            property Searcher target

            parent: Overlay.overlay

            width: Math.round(parent.width/3)
            height: parent.height

            // force model reset
            onAboutToShow: {
                fields.model = ''
                fields.model = fldsPopup.target.mcwsFields
            }

            ColumnLayout {
                anchors.fill: parent
                GroupSeparator{
                    text: 'Select Search Fields'
                }

                ListView {
                    id: fields
                    clip: true
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    delegate: ToolButton {
                        text: field
                        implicitWidth: fields.width
                        checkable: true
                        checked: fldsPopup.target.searchFields.hasOwnProperty(field)
                        onClicked: {
                            if (checked)
                                fldsPopup.target.searchFields[field] = ''
                            else
                                delete fldsPopup.target.searchFields[field]
                        }
                    }
                }
            }
        }

    }
}
