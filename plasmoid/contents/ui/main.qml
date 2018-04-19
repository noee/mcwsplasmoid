import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3 as QtControls

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.kquickcontrolsaddons 2.0

import Qt.labs.platform 1.0
import 'code/utils.js' as Utils

import 'libs'
import 'models'
import 'controls'

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
                mcws.host = hostModel[0]
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
                                ? theme.mSize(theme.defaultFont).width * (plasmoid.configuration.useZoneCount ? mcws.zoneModel.count*15 : trayViewSize)
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

        // The Connections Item will not work inside of fullRep Item (known issue)
        Component.onCompleted: {
            // initialize some vars when a connection starts
            mcws.connectionStart.connect(function (host)
            {
                zoneView.model = undefined
                clickedZone = -1
                mainView.currentIndex = 1
                searchButton.checked = false
                // clear dyn menus
                linkMenu.clear()
                devMenu.clear()
                playToZone.clear()
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
                    event.queueCall(0, function() { mcws.host = hostList.currentText })
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
                                    event.queueCall(500, function() { mainView.currentIndex = 1 } )
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
                                    mcws.host = currentText
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

                        function reset(zonendx) {
                            // HACK:  the connection model cannot be bound directly, there are paint issues with the ListView
                            if (model === undefined) {
                                model = mcws.zoneModel
                                var newConnect = true
                            }

                            var tmpIndex = -1
                            // Form factor constraints, vertical and model already set, do nothing
                            if (vertical) {
                                if (!newConnect)
                                    return

                                currentIndex = -1
                                tmpIndex = mcws.getPlayingZoneIndex()
                            }
                            // panelZoneView FF
                            else {
                                // model already set and no zone change, do nothing
                                if (!newConnect & (zonendx === currentIndex))
                                    return

                                currentIndex = -1
                                tmpIndex = zonendx !== -1 ? zonendx : mcws.getPlayingZoneIndex()
                            }

                            // This handles a painting issue when the model is just set
                            if (newConnect)
                                event.queueCall(1000, function() { currentIndex = tmpIndex })
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
                                        QtControls.ToolTip.text: Utils.stringifyObj(track)

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
                            property int devndx
                            checkable: true
                        }
                    }
                    Menu {
                        id: zoneMenu

                        MenuItem {
                            text: "Shuffle Playing Now"
                            iconName: "shuffle"
                            onTriggered: mcws.setShuffle(zoneView.currentIndex, 'Reshuffle')
                        }
                        MenuSeparator{}
                        Menu {
                            id: shuffleMenu
                            title: "Shuffle Mode"

                            property string currShuffle: ''

                            onAboutToShow: {
                                mcws.getShuffleMode(zoneView.currentIndex, function(shuffle) {
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
                                onTriggered: mcws.setShuffle(zoneView.currentIndex, item.text)
                            }
                        }
                        Menu {
                            id: repeatMenu
                            title: "Repeat Mode"

                            property string currRepeat: ''

                            onAboutToShow: {
                                mcws.getRepeatMode(zoneView.currentIndex, function(repeat) {
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
                                onTriggered: mcws.setRepeat(zoneView.currentIndex, item.text)
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

                                var z = zoneView.getObj()
                                var zonelist = z.linkedzones !== undefined ? z.linkedzones.split(';') : []

                                mcws.zoneModel.forEach(function(zone, ndx) {
                                    linkMenu.items[ndx].visible = z.zoneid !== zone.zoneid
                                    linkMenu.items[ndx].checked = zonelist.indexOf(zone.zoneid) !== -1
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
                            text: "Stop All Zones"
                            iconName: "edit-clear"
                            onTriggered: mcws.stopAllZones()
                        }
                        MenuItem {
                            text: "Clear All Zones"
                            iconName: "edit-clear"
                            onTriggered: mcws.zoneModel.forEach(function(zone, ndx) { mcws.clearPlayingNow(ndx) })
                        }
                        MenuSeparator{}
                        MenuItem {
                            text: "Clear Playing Now"
                            iconName: "edit-clear"
                            onTriggered: mcws.clearPlayingNow(zoneView.currentIndex)
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
                            spacing: 1
                            SearchButton {
                                id: searchButton
                                checkable: true
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
                                    if (mcws.isConnected && zoneView.getObj())
                                        return zoneView.getObj().trackList
                                    else
                                        return undefined
                                }
                                onSortDone: trackView.highlightPlayingTrack
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

                        Searcher {
                            id: searcher
                            comms: mcws.comms
                            autoShuffle: plasmoid.configuration.shuffleSearch
                            mcwsFields: mcws.defaultFields()
                            onSearchBegin: busyInd.visible = true
                            onSearchDone: {
                                busyInd.visible = false
                                if (count > 0) {
                                    trackView.highlightPlayingTrack()
                                    sorter.model = searcher
                                }
                            }
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
                            var z = zoneView.getObj()
                            if (!z) {
                                currentIndex = -1
                                return
                            }

                            if (!searchMode) {
                                currentIndex = -1
                                var ndx = trackView.model.mapRowFromSource(z.playingnowposition)
                                if (ndx !== undefined && (ndx >= 0 & ndx < trackView.count) ) {
                                    currentIndex = ndx
                                    event.queueCall(250, trackView.positionViewAtIndex, [ndx, ListView.Center])
                                }
                                return
                            }

                            if (plasmoid.configuration.showPlayingTrack) {
                                ndx = trackView.model.findIndex(function(item){ return item.key === z.filekey })
                                if (ndx !== -1) {
                                    currentIndex = ndx
                                    trackView.positionViewAtIndex(ndx, ListView.Center)
                                }
                                else {
                                    currentIndex = -1
                                    trackView.positionViewAtIndex(0, ListView.Beginning)
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
                            trackView.model = mcws.playlists.trackModel.items

                            if (mainView.currentIndex !== 2)
                                mainView.currentIndex = 2
                        }

                        function formatDuration(dur) {
                            if (dur === undefined) {
                                return ''
                            }

                            var num = dur.split('.')[0]
                            return "(%1:%2) ".arg(Math.floor(num / 60)).arg(String((num % 60) + '00').substring(0,2))
                        }

                        // Set the viewer to the current zone playing now
                        function reset() {
                            mcwsQuery = ''
                            searchButton.checked = false
                            mcws.playlists.currentIndex = -1
                            trackView.model = zoneView.getObj().trackList.items
                            sorter.model = zoneView.getObj().trackList
                            event.queueCall(500, highlightPlayingTrack)
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
                                    PlasmaComponents.Label {
                                        visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                                        Layout.leftMargin: 8
                                        font.italic: detDel.ListView.isCurrentItem
                                        text: {
                                            if (mediatype === 'Audio')
                                                return "from '%1' (tk. %3)\nby %2".arg(album).arg(artist).arg(track_)
                                            else if (mediatype === 'Video')
                                                return genre + '\n' + mediasubtype
                                            else return ''
                                        }
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
                                            td = Utils.stringifyObj(ti)
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

                            playMenu.visible = addMenu.visible = showMenu.visible = detailMenu.currObj.mediatype === 'Audio'
                        }

                        MenuItem {
                            text: "Play Track"
                            onTriggered: {
                                if (trackView.searchMode) {
                                    mcws.playTrackByKey(zoneView.currentIndex, detailMenu.currObj.key)
                                }
                                else
                                    mcws.playTrack(zoneView.currentIndex
                                                   , trackView.model.mapRowToSource(trackView.currentIndex))
                            }
                        }
                        MenuItem {
                            text: "Add Track"
                            onTriggered: mcws.addTrack(zoneView.currentIndex, detailMenu.currObj.key)
                        }

                        MenuItem {
                            text: "Remove Track"
                            enabled: !trackView.searchMode
                            onTriggered: mcws.removeTrack(zoneView.currentIndex
                                                          , trackView.model.mapRowToSource(trackView.currentIndex))
                        }
                        MenuSeparator{}
                        Menu {
                            id: playMenu
                            title: "Play"
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
                                                        ? trackView.showingPlaylist ? mcws.playlists.trackModel.items : searcher.items
                                                        : zoneView.getObj().trackList.items
                                                        , zoneView.currentIndex, item.devndx)
                                }
                            }
                        }
                        MenuSeparator{}
                        MenuItem {
                            text: "Shuffle Playing Now"
                            enabled: !trackView.searchMode
                            onTriggered: mcws.setShuffle(zoneView.currentIndex, 'reshuffle')
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
                                    event.queueCall(250, function() { mainView.currentIndex = 1 } )
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

            source: "media-default-album"
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

        onTrackKeyChanged: {
            if (plasmoid.configuration.showTrackSplash)
                splasher.go(zoneModel.get(zonendx), imageUrl(trackKey))
        }

        Connections {
            target: plasmoid.configuration
            onDefaultFieldsChanged: mcws.setDefaultFields(plasmoid.configuration.defaultFields)
        }

        Component.onCompleted: setDefaultFields(plasmoid.configuration.defaultFields)
    }

    function action_kde() {
        KCMShell.open(["kscreen", "kcm_pulseaudio", "powerdevilprofilesconfig"])
    }
    function action_reset() {
        mcws.reset()
    }
    function action_close() {
        mcws.host = ''
        plasmoid.expanded = false
    }

    Component.onCompleted: {

        if (plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            plasmoid.activationTogglesExpanded = true
        }
        plasmoid.setAction("kde", i18n("Configure Plasma5..."), "kde");
        plasmoid.setActionSeparator('1')
        plasmoid.setAction("reset", i18n("Reset View"), "view-refresh");
        plasmoid.setAction("close", i18n("Close Connection"), "window-close");
        plasmoid.setActionSeparator('2')

    }
}
