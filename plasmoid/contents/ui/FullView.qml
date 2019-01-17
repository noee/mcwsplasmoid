import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4 as QtControls

import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PC
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.4 as Kirigami
import Qt.labs.platform 1.0

import 'helpers/utils.js' as Utils
import 'helpers'
import 'models'
import 'controls'

Item {

    // The Connections Item will not work inside of fullRep Item (known issue)
    Component.onCompleted: {
        // initialize some vars when a connection starts
        mcws.connectionStart.connect(function (host)
        {
            zoneView.model = ''
            clickedZone = -1
            mainView.currentIndex = 1
            searchButton.checked = false
            // clear dyn menus
            linkMenu.clear()
            devMenu.clear()
            playToZone.clear()
        })

        // Set current zone view when connection signals ready
        mcws.connectionReady.connect(function(host, zonendx)
        {
            zoneView.model = mcws.zoneModel
            // resetting view so hide any zones previously hidden
            // This could conflict as things are loading async
            // so wait a bit
            hiddenZones.apply(function() {
                zoneView.set(zonendx)
            }, 1000)
        })

        // On error, swipe to the zoneview page
        mcws.connectionError.connect(function (msg, cmd)
        {
            if (cmd.indexOf(mcws.currentHost) !== -1)
                mainView.currentIndex = 1
        })

        // get notified when the hostlist model changes
        // needed for config change, currentIndex not being set (BUG?)
        plasmoidRoot.hostListChanged.connect(function(h) {
            hostList.currentIndex = hostList.find(h)
        })
    }

    Plasmoid.onExpandedChanged: {
        logger.log('Connected: %1\nExpanded: %2\nVertical: %3'
                        .arg(mcws.isConnected).arg(expanded).arg(vertical)
                   , 'Clicked: %1, ZV: %2'.arg(clickedZone).arg(zoneView.currentIndex))
        if (expanded) {
            if (mcws.isConnected)
                zoneView.set(clickedZone)
            else
                event.queueCall(0, function() { mcws.host = hostList.currentText })
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        QtControls.SwipeView {
            id: mainView
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: units.smallSpacing
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
                header: ColumnLayout {
                    spacing: 1
                    Kirigami.Heading {
                        level: 2
                        text: "Playlists/" + (zoneView.currentIndex >= 0 ? zoneView.modelItem().zonename : "")
                        Layout.margins: units.smallSpacing
                        MouseAreaEx {
                            tipText: mcws.host
                        }
                    }
                    RowLayout {
                        width: parent.width
                        Layout.bottomMargin: 3
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
                    model: mcws.playlists.items
                    delegate: RowLayout {
                        id: plDel

                        PlayButton {
                            onClicked: {
                                zoneView.currentPlayer.playPlaylist(id, autoShuffle)
                                event.queueCall(500, function() { mainView.currentIndex = 1 } )
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
                        Kirigami.Heading {
                            level: plDel.ListView.isCurrentItem ? 4 : 5
                            text: name + ' / ' + type
                            MouseAreaEx {
                                tipText: id + '\n' + path
                                onClicked: playlistView.currentIndex = index
                            }
                        }
                    }
                }
            }
            // Zone View
            QtControls.Page {
                header: RowLayout {
                    spacing: 0
                    Kirigami.Heading {
                        text: qsTr("Playback Zones on: ")
                        Layout.leftMargin: units.smallSpacing
                        Layout.bottomMargin: 3
                        level: 2
                    }
                    QtControls.ComboBox {
                        id: hostList
                        Layout.fillWidth: true
                        model: hostModel
                        textRole: 'host'
                        onActivated: {
                            if (!mcws.host.includes(currentText)) {
                                mcws.host = currentText
                            }
                        }
                    }
                    CheckButton {
                        icon.name: "window-pin"
                        autoExclusive: false
                        opacity: .75
                        implicitHeight: units.iconSizes.medium
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
                            zoneView.currentPlayer.getShuffleMode(function(shuffle) {
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
                            zoneView.currentPlayer.getRepeatMode(function(repeat) {
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
                                mcws.zoneModel.forEach(function(zone) {
                                    linkMenu.addItem(mi.createObject(linkMenu, { zoneid: zone.zoneid
                                                                               , text: i18n(zone.zonename)
                                                                               })
                                    )
                                })
                            }

                            var z = zoneView.modelItem()
                            var zonelist = z.linkedzones !== undefined ? z.linkedzones.split(';') : []

                            mcws.zoneModel.forEach(function(zone, ndx) {
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
                            mcws.audioDevices.getDevice(zoneView.currentIndex, function(ad)
                            {
                                currDev = ad.deviceindex
                                if (devMenu.items.length === 0) {
                                    mcws.audioDevices.items.forEach(function(dev, ndx)
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
                        text: 'Hide'
                        onTriggered: {
                            hiddenZones.add(zoneView.currentIndex)
                            zoneView.currentIndex = 0
                        }
                    }
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
                        onTriggered: mcws.zoneModel.forEach(function(zone) {
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
            QtControls.Page {
                header: ColumnLayout {
                    spacing: 1

                    RowLayout {
                        spacing: 0
                        SearchButton {
                            id: searchButton
                            checkable: true
                            icon.name: checked ? 'edit-undo-symbolic' : 'search'
                            QtControls.ToolTip.visible: false
                            onClicked: {
                                if (!checked)
                                    trackView.reset()
                                else {
                                    trackView.model = searcher.items
                                    trackView.mcwsQuery = searcher.constraintString
                                    event.queueCall(1000, function() { trackView.currentIndex = -1 })
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

                        Kirigami.Heading {
                            id: tvTitle
                            level: 2
                            Layout.leftMargin: units.smallSpacing

                            text: {
                                if (trackView.showingPlaylist)
                                    'Playlist "%1"'.arg(mcws.playlists.currentName)
                                else (trackView.searchMode || searchButton.checked
                                     ? 'Searching All Tracks'
                                     : "Playing Now/" + (zoneView.currentIndex >= 0 ? zoneView.modelItem().zonename : ""))
                            }

                            MouseAreaEx {
                                tipText: mcws.host
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
                        TextEx {
                            id: searchField
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
                        mcws.pnPositionChanged.connect(function(zonendx, pos) {
                            if (!searchMode && zonendx === zoneView.currentIndex) {
                                pos = trackView.model.mapRowFromSource(pos)
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
                                currentIndex = trackView.model.findIndex(function(item) {
                                    return item.key === z.filekey
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
                                mcws.getTrackDetails(key, function(ti) {
                                    trackView.tempTT = Utils.stringifyObj(ti)
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
                } //listview

                PC.BusyIndicator {
                    id: busyInd
                    visible: false
                    anchors.centerIn: parent
                }

                Menu {
                    id: detailMenu

                    property var currObj

                    function show() {
                        currObj = trackView.modelItem()
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

                        playMenu.visible = addMenu.visible = showMenu.visible = detailMenu.currObj.mediatype === 'Audio'
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
                        MenuItem {
                            id: playArtist
                            onTriggered: zoneView.currentPlayer.searchAndPlayNow(
                                             "artist=[%1]".arg(detailMenu.currObj.artist), autoShuffle)
                        }
                        MenuItem {
                            id: playGenre
                            onTriggered: zoneView.currentPlayer.searchAndPlayNow(
                                             "genre=[%1]".arg(detailMenu.currObj.genre), autoShuffle)
                        }

                        MenuSeparator{}
                        MenuItem {
                            text: "Current List"
                            enabled: trackView.searchMode
                            onTriggered: {
                                if (trackView.showingPlaylist)
                                    zoneView.currentPlayer.playPlaylist(mcws.playlists.currentID, autoShuffle)
                                else
                                    zoneView.currentPlayer.searchAndPlayNow(trackView.mcwsQuery, autoShuffle)
                            }
                        }
                    }
                    Menu {
                        id: addMenu
                        title: "Add"
                        MenuItem {
                            id: addAlbum
                            onTriggered: zoneView.currentPlayer.searchAndAdd(
                                             "album=[%1] and artist=[%2]".arg(detailMenu.currObj.album).arg(detailMenu.currObj.artist)
                                             , false, autoShuffle)
                        }
                        MenuItem {
                            id: addArtist
                            onTriggered: zoneView.currentPlayer.searchAndAdd(
                                             "artist=[%1]".arg(detailMenu.currObj.artist)
                                             , false, autoShuffle)
                        }
                        MenuItem {
                            id: addGenre
                            onTriggered: zoneView.currentPlayer.searchAndAdd(
                                             "genre=[%1]".arg(detailMenu.currObj.genre)
                                             , false, autoShuffle)
                        }
                        MenuSeparator{}
                        MenuItem {
                            text: "Current List"
                            enabled: trackView.searchMode
                            onTriggered: {
                                if (trackView.showingPlaylist)
                                    zoneView.currentPlayer.addPlaylist(mcws.playlists.currentID, autoShuffle)
                                else
                                    zoneView.currentPlayer.searchAndAdd(trackView.mcwsQuery, false, autoShuffle)
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
                                mcws.zoneModel.forEach(function(zone, ndx) {
                                    playToZone.addItem(mi.createObject(linkMenu, { zoneid: zone.zoneid
                                                                               , devndx: ndx
                                                                               , text: i18n(zone.zonename)
                                                                               , checkable: false })
                                    )
                                })
                            }
                            mcws.zoneModel.forEach(function(zone, ndx) {
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
            QtControls.Page {
                header: ColumnLayout {
                    spacing: 1
                    RowLayout {
                        CheckButton {
                            id: tbAudioOnly
                            icon.name: "audio-ready"
                            checked: true
                            autoExclusive: false
                            width: Math.round(units.gridUnit * 1.25)
                            height: width
                            onCheckedChanged: lookup.mediaType = checked ? 'audio' : ''
                            QtControls.ToolTip.text: checked ? 'Audio Only' : 'All Media Types'
                        }
                        Item {
                            Layout.fillWidth: true
                        }

                        Kirigami.Heading {
                            level: 2
                            text: 'Show All:'
                        }

                        CheckButton {
                            id: lookupArtist
                            text: 'Artists'
                            autoExclusive: true
                            onClicked: {
                                lookup.queryField = "artist"
                            }
                        }
                        CheckButton {
                            text: 'Albums'
                            autoExclusive: true
                            onClicked: {
                                lookup.queryField = "album"
                            }
                        }
                        CheckButton {
                            text: 'Genre'
                            autoExclusive: true
                            onClicked: {
                                lookup.queryField = "genre"
                            }
                        }
                        CheckButton {
                            text: 'Tracks'
                            autoExclusive: true
                            onClicked: {
                                lookup.queryField = "name"
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
                                zoneView.currentPlayer.searchAndPlayNow(
                                                      '[%1]="%2"'.arg(lookup.queryField).arg(value)
                                                      , autoShuffle)
                                event.queueCall(250, function() { mainView.currentIndex = 1 } )
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

                        Kirigami.Heading {
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

        source: "media-default-album"
        opacity: 0.1
    }
}
