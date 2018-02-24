import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3 as QtControls

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.kquickcontrolsaddons 2.0

import Qt.labs.platform 1.0

import "models"
import "controls"

Item {

    id: root

    property var hostModel:         plasmoid.configuration.hostList
    property int trayViewSize:      plasmoid.configuration.trayViewSize
    property bool vertical:         plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool panelZoneView:    plasmoid.configuration.advancedTrayView & !vertical

    property int thumbSize: theme.mSize(theme.defaultFont).width * 4
    property int clickedZone: -1

    // Auto-connect when host setup changes
    onHostModelChanged: {
        if (hostModel.length === 0) {
            if (mcws.isConnected)
                mcws.host = ''
        } else {
            // if the connected host is not in the list, then open first in list
            if (hostModel.findIndex(function(host){ return mcws.host.indexOf(host) !== -1 }) === -1)
                mcws.tryConnect(hostModel[0])
        }
    }

    Component {
        id: advComp
        CompactView {
            onZoneClicked: {
                clickedZone = zonendx
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
                onClicked: {
                    clickedZone = -1
                    plasmoid.expanded = !plasmoid.expanded
                }
            }
        }
    }

    Plasmoid.switchWidth: theme.mSize(theme.defaultFont).width * 28
    Plasmoid.switchHeight: theme.mSize(theme.defaultFont).height * 15

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: Loader {

        Layout.preferredWidth: panelZoneView
                                ? theme.mSize(theme.defaultFont).width * trayViewSize
                                : units.iconSizes.small

        sourceComponent: mcws.isConnected
                        ? panelZoneView ? advComp : iconComp
                        : iconComp
    }

    Plasmoid.fullRepresentation: Item {

        property bool abbrevZoneView: plasmoid.configuration.abbrevZoneView
        property bool abbrevTrackView: plasmoid.configuration.abbrevTrackView
        property bool autoShuffle: plasmoid.configuration.autoShuffle

        width: units.gridUnit * 28
        height: units.gridUnit * 23

        function stringifyObj(obj) {
            return JSON.stringify(obj).replace(/,/g,'\n').replace(/":"/g,': ').replace(/("|}|{)/g,'')
        }

        // The Connections Item will not work inside of fullRep Item (known issue)
        Component.onCompleted: {
            // initialize some vars when a connection starts
            mcws.connectionStart.connect(function (host)
            {
                zoneView.model = undefined
                clickedZone = -1
            })
            // reset view when connection signals ready
            mcws.connectionReady.connect(zoneView.reset)
            // put the view back to the zoneview page
            mcws.connectionError.connect(function (msg, cmd)
            {
                if (cmd.indexOf(mcws.currentHost) !== -1)
                    mainView.currentIndex = 1
            })
        }

        Plasmoid.onExpandedChanged: {
            if (expanded) {
                if (mcws.isConnected)
                    zoneView.reset(clickedZone)
                else
                    Qt.callLater(mcws.tryConnect, hostList.currentText)
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

                // Playlist View
                QtControls.Page {
                    background: Rectangle {
                        opacity: 0
                    }
                    header: ColumnLayout {
                        spacing: 1
                        PlasmaExtras.Title {
                            text: "Playlists/" + (zoneView.currentIndex >= 0 ? zoneView.getObj().zonename : "")
                        }
                        PlasmaComponents.ButtonRow {
                            Layout.bottomMargin: 3
                            Layout.fillWidth: true
                            spacing: 1
                            PlasmaComponents.ToolButton {
                                id: allButton
                                text: "All"
                                implicitWidth: parent.width*.2
                                onClicked: mcws.playlists.filterType = text
                            }
                            PlasmaComponents.ToolButton {
                                text: "Smartlists"
                                implicitWidth: allButton.width
                                onClicked: mcws.playlists.filterType = text
                            }
                            PlasmaComponents.ToolButton {
                                text: "Playlists"
                                implicitWidth: allButton.width
                                onClicked: mcws.playlists.filterType = text
                            }
                            PlasmaComponents.ToolButton {
                                text: "Groups"
                                implicitWidth: allButton.width
                                onClicked: mcws.playlists.filterType = text
                            }
                        }
                    }

                    Viewer {
                        id: playlistView
                        model: mcws.playlists.items

                        delegate: RowLayout {
                            id: plDel

                            PlayButton {
                                onClicked: {
                                    mcws.playlists.play(zoneView.currentIndex, id, autoShuffle)
                                    event.singleShot(500, function() { mainView.currentIndex = 1 } )
                                }
                            }
                            AddButton {
                                onClicked: mcws.playlists.add(zoneView.currentIndex, id, autoShuffle)
                            }
                            SearchButton {
                                onClicked: {
                                    playlistView.currentIndex = index
                                    mcws.playlists.currentIndex = index
                                    trackView.showPlaylist()
                                }
                            }
                            PlasmaExtras.Heading {
                                level: plDel.ListView.isCurrentItem ? 4 : 5
                                text: name + ' / ' + type
                                MouseArea {
                                    QtControls.ToolTip.text: 'id: ' + id + '\npath: ' + path
                                    QtControls.ToolTip.visible: containsMouse
                                    QtControls.ToolTip.delay: 1500
                                    hoverEnabled: true
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
                            Layout.alignment: Qt.AlignBottom
                            implicitHeight: units.gridUnit*1.6
                            model: hostModel
                            contentItem: PlasmaExtras.Heading {
                                      text: hostList.displayText
                                      level: 4
                            }
                            onActivated: {
                                if (mcws.host.indexOf(currentText) === -1) {
                                    mcws.tryConnect(currentText)
                                }
                            }
                        }
                    }

                    Viewer {
                        id: zoneView

                        onCurrentIndexChanged: {
                            if (currentIndex !== -1)
                                if (!trackView.searchMode)
                                    trackView.reset()
                        }

                        function playingNdx() {
                            var list = mcws.zonesByState(mcws.statePlaying)
                            return list.length>0 ? list[list.length-1] : 0
                        }

                        // HACK:  the connection model cannot be bound directly, there are paint issues with the ListView
                        // send zonendx = -1 to set select to playing zone or first if none playing
                        // handles vertical form factor restrictions
                        function reset(zonendx) {
                            if (model === undefined) {
                                model = mcws.zoneModel
                                var newConnect = true
                            }
                            // Nothing to set
                            if (vertical) {
                                if (newConnect) {
                                    currentIndex = -1
                                    var tmpIndex = playingNdx()
                                }
                            }
                            else {
                                currentIndex = -1
                                tmpIndex = zonendx !== -1 ? zonendx : playingNdx()
                            }
                            // This handles a painting issue when the model is just set
                            if (newConnect)
                                event.singleShot(1000, function() { currentIndex = tmpIndex })
                            else
                                currentIndex = tmpIndex
                        }

                        delegate:
                            GridLayout {
                                id: lvDel
                                width: zoneView.width
                                columns: 3
                                rowSpacing: 1

                                // zone name/status
                                RowLayout {
                                    Layout.columnSpan: 2
                                    spacing: 1
                                    Layout.margins: 2
                                    TrackImage {
                                        animateLoad: true
                                        height: thumbSize
                                        visible: +playingnowtracks !== 0
                                        Layout.rightMargin: 5
                                        sourceKey: filekey
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
                                        Layout.fillWidth: true
                                        wrapMode: Text.NoWrap
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton | Qt.LeftButton
                                        onClicked: zoneView.currentIndex = index
                                        hoverEnabled: true
                                        // popup next track info
                                        QtControls.ToolTip.visible: containsMouse && +playingnowtracks !== 0
                                        QtControls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                                        QtControls.ToolTip.text: nexttrackdisplay
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
                                    aText: trackdisplay
                                    MouseArea {
                                        anchors.fill: parent
                                        // popup track detail
                                        QtControls.ToolTip.visible: pressed && filekey !== '-1'
                                        QtControls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                                        QtControls.ToolTip.text: stringifyObj(track)

                                    }
                                }
                                // player controls
                                Player {
                                    showTrackSlider: plasmoid.configuration.showTrackSlider
                                    showVolumeSlider: plasmoid.configuration.showVolumeSlider
                                    visible: lvDel.ListView.isCurrentItem
                                }

                        } // delegate
                    }

                    Component {
                        id: mi
                        MenuItem {
                            property string zoneid
                            checkable: true
                        }
                    }

                    Menu {
                        id: zoneMenu

                        function showAt(item) {
                            linkMenu.loadActions()
                            open(item)
                        }

                        MenuItem {
                            text: "Shuffle Playing Now"
                            iconName: "shuffle"
                            onTriggered: mcws.shuffle(zoneView.currentIndex)
                        }
                        MenuItem {
                            text: "Clear Playing Now"
                            iconName: "edit-clear"
                            onTriggered: mcws.clearPlayingNow(zoneView.currentIndex)
                        }
                        MenuSeparator{}

                        Menu {
                            id: repeatMenu
                            title: "Repeat Mode"

                            MenuItem {
                                checkable: true
                                text: "Playlist"
                                checked: mcws.repeatMode(zoneView.currentIndex) === text
                            }
                            MenuItem {
                                checkable: true
                                text: "Track"
                                checked: mcws.repeatMode(zoneView.currentIndex) === text
                            }
                            MenuItem {
                                checkable: true
                                text: "Off"
                                checked: mcws.repeatMode(zoneView.currentIndex) === text
                            }
                            MenuItemGroup {
                                items: repeatMenu.items
                                exclusive: true
                                onTriggered: {
                                    mcws.setRepeat(zoneView.currentIndex, item.text)
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

                                var z = zoneView.getObj()
                                var zonelist = z.linkedzones !== undefined ? z.linkedzones.split(';') : []

                                mcws.zoneModel.forEach(function(zone) {
                                    if (z.zoneid !== zone.zoneid) {
                                        linkMenu.addItem(mi.createObject(linkMenu, { zoneid: zone.zoneid
                                                                                    , text: i18n(zone.zonename)
                                                                                    , checked: zonelist.indexOf(zone.zoneid) !== -1
                                                                                 })
                                        )
                                    }
                                })
                            }

                            MenuItemGroup {
                                items: linkMenu.items
                                exclusive: false
                                onTriggered: {
                                    if (item.checked)
                                        mcws.unLinkZone(zoneView.currentIndex)
                                    else
                                        mcws.linkZones(zoneView.getObj().zoneid, item.zoneid)
                                }
                            }
                        }
                        MenuSeparator{}
                        MenuItem {
                            text: "Stop All Zones"
                            iconName: "edit-clear"
                            onTriggered: mcws.stopAllZones()
                        }
                        MenuItem {
                            text: "Clear All Zones"
                            iconName: "edit-clear"
                            onTriggered: mcws.zoneModel.forEach(function(zone, ndx) { mcws.clearPlayingNow(ndx) })
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
                            SearchButton {
                                id: searchButton
                                width: Math.round(units.gridUnit * .25)
                                height: width
                                checkable: true
                                QtControls.ToolTip.visible: false
                                Layout.alignment: Qt.AlignTop
                                onClicked: {
                                    if (!checked)
                                        trackView.reset()
                                    else {
                                        trackView.model = searcher.items
                                        trackView.mcwsQuery = searcher.constraintString
                                        event.singleShot(1000, function() { trackView.currentIndex = -1 })
                                    }
                                }
                            }

                            PlasmaExtras.Title {
                                id: tvTitle
                                text: {
                                    if (trackView.showingPlaylist)
                                        '< Playlist "%1"'.arg(mcws.playlists.currentName)
                                    else (trackView.searchMode || searchButton.checked
                                         ? '< Searching All Tracks'
                                         : "Playing Now/" + (zoneView.currentIndex >= 0 ? zoneView.getObj().zonename : ""))
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
                        }
                        RowLayout {
                            visible: searchButton.checked
                            Layout.bottomMargin: 3
                            PlasmaComponents.TextField {
                                id: searchField
                                selectByMouse: true
                                clearButtonShown: true
                                placeholderText: trackView.showingPlaylist
                                                 ? 'Play or add >>'
                                                 : 'Enter search'
                                font.pointSize: theme.defaultFont.pointSize-1
                                Layout.fillWidth: true
                                horizontalAlignment: trackView.showingPlaylist ? Text.AlignRight : Text.AlignLeft
                                visible: !trackView.showingPlaylist
                                onVisibleChanged: {
                                    if (visible)
                                        forceActiveFocus()
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
                                        mcws.playlists.play(zoneView.currentIndex, mcws.playlists.currentID, autoShuffle)
                                    else
                                        mcws.searchAndPlayNow(zoneView.currentIndex, trackView.mcwsQuery, autoShuffle)
                                }
                            }
                            AddButton {
                                enabled: trackView.searchMode & trackView.count > 0
                                onClicked: {
                                    if (trackView.showingPlaylist)
                                        mcws.playlists.add(zoneView.currentIndex, mcws.playlists.currentID, autoShuffle)
                                    else
                                        mcws.searchAndAdd(zoneView.currentIndex, trackView.mcwsQuery, true, autoShuffle)
                                }
                            }
                        }
                    }  //header

                    Viewer {
                        id: trackView

                        property string mcwsQuery: ''
                        property bool searchMode: mcwsQuery !== ''
                        property bool showingPlaylist: mcwsQuery ==='playlist'

                        Searcher {
                            id: searcher
                            comms: mcws.comms
                            autoShuffle: plasmoid.configuration.shuffleSearch

                            onSearchBegin: busyInd.visible = true
                            onSearchDone: {
                                busyInd.visible = false
                                trackView.highlightPlayingTrack()
                            }
                        }

                        Component.onCompleted: {
                            mcws.pnPositionChanged.connect(function(zonendx, pos) {
                                if (!searchMode && zonendx === zoneView.currentIndex) {
                                    positionViewAtIndex(pos, ListView.Center)
                                    currentIndex = pos
                                }
                            })

                            mcws.playlists.loadTracksBegin.connect(function()
                            {
                                busyInd.visible = true
                            })
                            mcws.playlists.loadTracksDone.connect(function()
                            {
                                busyInd.visible = false
                                highlightPlayingTrack()
                            })
                        }

                        function highlightPlayingTrack() {
                            if (trackView.count === 0
                                    || (searchMode & !plasmoid.configuration.showPlayingTrack))
                                return

                            if (searchMode) {

                                var fk = zoneView.getObj().filekey
                                var m = showingPlaylist ? mcws.playlists.tracks : searcher.items
                                var ndx = m.findIndex(function(item){ return item.key === fk })

                                if (ndx !== -1) {
                                    currentIndex = ndx
                                    trackView.positionViewAtIndex(ndx, ListView.Center)
                                }
                                else {
                                    currentIndex = -1
                                    trackView.positionViewAtIndex(0, ListView.Beginning)
                                }
                            }
                            else {
                                currentIndex = -1
                                ndx = zoneView.getObj().playingnowposition
                                if (ndx !== undefined && (ndx >= 0 & ndx < trackView.count) ) {
                                    currentIndex = ndx
                                    event.singleShot(250, function() {trackView.positionViewAtIndex(ndx, ListView.Center)})
                                }
                            }
                        }

                        // Issue a search, contraints should be an object of mcws {field: value....}
                        function search(constraints, andTogether) {

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
                            if (mainView.currentIndex !== 2)
                                mainView.currentIndex = 2
                        }

                        // Puts the view in search mode, sets the view model to the playlist tracks
                        function showPlaylist() {

                            mcwsQuery = 'playlist'
                            searchButton.checked = true
                            searchField.text = ''
                            trackView.model = mcws.playlists.tracks

                            if (mainView.currentIndex !== 2)
                                mainView.currentIndex = 2
                        }

                        function formatDuration(dur) {
                            var num = dur.split('.')[0]
                            return "(%1:%2) ".arg(Math.floor(num / 60)).arg(String((num % 60) + '00').substring(0,2))
                        }

                        // Set the viewer to the current zone playing now
                        function reset() {
                            mcwsQuery = ''
                            searchButton.checked = false
                            mcws.playlists.currentIndex = -1
                            trackView.model = zoneView.getObj().trackList.items
                            event.singleShot(500, highlightPlayingTrack)
                        }

                        delegate:
                            RowLayout {
                                id: detDel
                                Layout.margins: units.smallSpacing
                                width: trackView.width

                                TrackImage {
                                    sourceKey: key
                                    height: thumbSize
                                }
                                ColumnLayout {
                                    spacing: 0
                                    PlasmaExtras.Heading {
                                        level: detDel.ListView.isCurrentItem ? 4 : 5
                                        text: "%1%2 / %3".arg(detDel.ListView.isCurrentItem
                                                              ? trackView.formatDuration(duration)
                                                              : "").arg(name).arg(mediatype === 'Audio' ? genre : mediatype)
                                        font.italic: detDel.ListView.isCurrentItem
                                     }
                                    PlasmaExtras.Heading {
                                        visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                                        level: 5
                                        text: mediatype === 'Audio'
                                                ? " from '%1'\n by %2".arg(album).arg(artist)
                                                : '%1\n%2'.arg(genre).arg(mediasubtype)
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    property string td: ''

                                    QtControls.ToolTip.visible: pressed
                                    QtControls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                                    QtControls.ToolTip.text: td

                                    onPressAndHold: {
                                        mcws.getTrackDetails(key, function(ti){
                                            td = stringifyObj(ti)
                                        })
                                    }

                                    onClicked: {
                                        trackView.currentIndex = index
                                        if (mouse.button === Qt.RightButton)
                                            detailMenu.show()
                                    }
                                    acceptedButtons: Qt.RightButton | Qt.LeftButton
                                }
                            }
                    }

                    PlasmaComponents.BusyIndicator {
                        id: busyInd
                        visible: false
                        anchors.centerIn: parent
                    }

                    Menu {
                        id: detailMenu

                        property var currObj

                        function show() {
                            currObj = trackView.getObj()
                            loadActions()
                            open()
                        }

                        function loadActions() {
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
                                    mcws.playTrackByKey(zoneView.currentIndex, detailMenu.currObj.key)
                                }
                                else
                                    mcws.playTrack(zoneView.currentIndex, trackView.currentIndex)
                            }
                        }
                        MenuItem {
                            text: "Add Track"
                            onTriggered: mcws.addTrack(zoneView.currentIndex, detailMenu.currObj.key)
                        }

                        MenuItem {
                            text: "Remove Track"
                            enabled: !trackView.searchMode
                            onTriggered: mcws.removeTrack(zoneView.currentIndex, trackView.currentIndex)
                        }
                        MenuSeparator{}
                        Menu {
                            id: playMenu
                            title: "Play"
                            visible: detailMenu.currObj.mediatype === 'Audio'
                            MenuItem {
                                id: playAlbum
                                onTriggered: mcws.playAlbum(zoneView.currentIndex, detailMenu.currObj.key)
                            }
                            MenuItem {
                                id: playArtist
                                onTriggered: mcws.searchAndPlayNow(zoneView.currentIndex, "artist=[%1]".arg(detailMenu.currObj.artist), autoShuffle)
                            }
                            MenuItem {
                                id: playGenre
                                onTriggered: mcws.searchAndPlayNow(zoneView.currentIndex, "genre=[%1]".arg(detailMenu.currObj.genre), autoShuffle)
                            }
                            MenuSeparator{}
                            MenuItem {
                                text: "Current List"
                                enabled: trackView.searchMode
                                onTriggered: {
                                    if (trackView.showingPlaylist)
                                        mcws.playlists.play(zoneView.currentIndex, mcws.playlists.currentID, autoShuffle)
                                    else
                                        mcws.searchAndPlayNow(zoneView.currentIndex, trackView.mcwsQuery, autoShuffle)
                                }
                            }
                        }
                        Menu {
                            id: addMenu
                            title: "Add"
                            visible: detailMenu.currObj.mediatype === 'Audio'
                            MenuItem {
                                id: addAlbum
                                onTriggered: mcws.searchAndAdd(zoneView.currentIndex, "album=[%1] and artist=[%2]".arg(detailMenu.currObj.album).arg(detailMenu.currObj.artist)
                                                             , false, autoShuffle)
                            }
                            MenuItem {
                                id: addArtist
                                onTriggered: mcws.searchAndAdd(zoneView.currentIndex, "artist=[%1]".arg(detailMenu.currObj.artist), false, autoShuffle)
                            }
                            MenuItem {
                                id: addGenre
                                onTriggered: mcws.searchAndAdd(zoneView.currentIndex, "genre=[%1]".arg(detailMenu.currObj.genre), false, autoShuffle)
                            }
                            MenuSeparator{}
                            MenuItem {
                                text: "Current List"
                                enabled: trackView.searchMode
                                onTriggered: {
                                    if (trackView.showingPlaylist)
                                        mcws.playlists.add(zoneView.currentIndex, mcws.playlists.currentID, autoShuffle)
                                    else
                                        mcws.searchAndAdd(zoneView.currentIndex, trackView.mcwsQuery, false, autoShuffle)
                                }
                            }
                        }
                        Menu {
                            id: showMenu
                            title: "Show"
                            visible: detailMenu.currObj.mediatype === 'Audio'
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
                        MenuItem {
                            text: "Shuffle Playing Now"
                            enabled: !trackView.searchMode
                            onTriggered: mcws.shuffle(zoneView.currentIndex)
                        }
                        MenuItem {
                            text: "Clear Playing Now"
                            enabled: !trackView.searchMode
                            onTriggered: mcws.clearPlayingNow(zoneView.currentIndex)
                        }
                    }
                }
                // Lookups
                QtControls.Page {
                    background: Rectangle {
                        opacity: 0
                    }
                    header: ColumnLayout {
                        spacing: 1
                        RowLayout {
                            PlasmaComponents.ToolButton {
                                iconSource: "audio-ready"
                                checkable: true
                                checked: true
                                width: Math.round(units.gridUnit * 1.25)
                                height: width
                                onCheckedChanged: lookup.mediaType = checked ? 'audio' : ''

                                QtControls.ToolTip.text: checked ? 'Audio Only' : 'All Media Types'
                                QtControls.ToolTip.visible: hovered
                                QtControls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                            }

                            PlasmaComponents.ButtonRow {
                                Layout.fillWidth: true
                                spacing: 1
                                PlasmaComponents.ToolButton {
                                    id: lookupArtist
                                    text: 'Artists'
                                    implicitWidth: parent.width*.2
                                    onClicked: {
                                        lookup.queryField = "artist"
                                    }
                                }
                                PlasmaComponents.ToolButton {
                                    text: 'Albums'
                                    implicitWidth: lookupArtist.width
                                    onClicked: {
                                        lookup.queryField = "album"
                                    }
                                }
                                PlasmaComponents.ToolButton {
                                    text: 'Genre'
                                    implicitWidth: lookupArtist.width
                                    onClicked: {
                                        lookup.queryField = "genre"
                                    }
                                }
                                PlasmaComponents.ToolButton {
                                    text: 'Tracks'
                                    implicitWidth: lookupArtist.width
                                    onClicked: {
                                        lookup.queryField = "name"
                                    }
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
                        model: lookup.items

                        LookupValues {
                            id: lookup
                            hostUrl: mcws.comms.hostUrl
                            onDataReady: sb.scrollCurrent()
                        }

                        delegate: RowLayout {
                            id: lkDel
                            width: parent.width
                            PlayButton {
                                onClicked: {
                                    lookupView.currentIndex = index
                                    mcws.searchAndPlayNow(zoneView.currentIndex,
                                                          '[%1]="%2"'.arg(lookup.queryField).arg(value),
                                                          autoShuffle)
                                    event.singleShot(250, function() { mainView.currentIndex = 1 } )
                                }
                            }
                            AddButton {
                                onClicked: {
                                    lookupView.currentIndex = index
                                    mcws.searchAndAdd(zoneView.currentIndex,
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

                            PlasmaExtras.Heading {
                                level: lkDel.ListView.isCurrentItem ? 4 : 5
                                text: value //+ (field === '' ? '' : ' / ' + field)
                                Layout.fillWidth: true
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: lookupView.currentIndex = index
                                }
                            }
                        } // delegate
                    } // viewer
                }
            }

            QtControls.PageIndicator {
                id: pi
                count: mainView.count
                visible: mcws.isConnected
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
        videoFullScreen: plasmoid.configuration.forceDisplayView
        thumbSize: plasmoid.configuration.highQualityThumbs ? 128 : 32
        pollerInterval: plasmoid.configuration.updateInterval *
                        (panelZoneView | plasmoid.expanded ? 1000 : 3000)

        function tryConnect(hostname) {
            host = hostname.indexOf(':') === -1
                    ? '%1:%2'.arg(hostname).arg(plasmoid.configuration.defaultPort)
                    : hostname
        }

        onTrackKeyChanged: {
            if (plasmoid.configuration.showTrackSplash)
                splasher.go(zoneModel.get(zonendx), imageUrl(trackKey))
        }
    }

    Process { id: shell }

    function action_screens() {
        KCMShell.open(["kscreen"])
    }
    function action_pulse() {
        KCMShell.open(["kcm_pulseaudio"])
    }
    function action_power() {
        KCMShell.open(["powerdevilprofilesconfig"])
    }
    function action_mpvconf() {
        shell.exec("xdg-open ~/.mpv/config")
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
