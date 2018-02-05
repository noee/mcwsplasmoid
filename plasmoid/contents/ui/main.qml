import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3 as QtControls

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
    property bool panelZoneView: advTrayView && !vertical
    property int clickedZone: -1

    // Auto-connect when host setup changes
    onHostModelChanged: {
        if (hostModel.length === 0) {
            if (mcws.isConnected)
                mcws.currentHost = ''
        } else {
            // if the connected host is not in the list, then open first in list
            if (hostModel.findIndex(function(host){ return mcws.currentHost.indexOf(host) !== -1 }) === -1)
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
                onClicked: plasmoid.expanded = !plasmoid.expanded
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

        // The Connections Item will not work inside of fullRep Item (known issue)
        Component.onCompleted: {

            mcws.connectionStart.connect(function (host)
            {
                lv.model = ''
                clickedZone = -1
            })

            mcws.connectionReady.connect(function (zonendx)
            {
                var list = mcws.zonesByState(mcws.statePlaying)
                lv.model = mcws.zoneModel
                lv.currentIndex = list.length>0 ? list[list.length-1] : zonendx
            })
        }

        // HACK:  mcws.model cannot be bound directly as there are some GUI/timing issues,
        // so check here when the expanded view shows.  Plasmoid.onExpandedChanged comes too late.
        onVisibleChanged: {
            if (mcws.isConnected)
            {
                if (visible)
                {
                    if (lv.model === undefined)
                        lv.model = mcws.zoneModel
                    // Recv'd click from compactView (see component above)
                    if (advTrayView) {
                        if (clickedZone != -1)
                            lv.currentIndex = clickedZone
                        else {
                            var list = mcws.zonesByState(mcws.statePlaying)
                            lv.currentIndex = list.length>0 ? list[list.length-1] : 0
                        }
                    }
                }

            } else {
                if (visible)
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

                onCurrentIndexChanged: {
                    if (mcws.isConnected && currentIndex === 0 && playlistView.count === 0)
                        mcws.playlists.filterType = "all"
                }

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
                        PlasmaComponents.TabBar {
                           Layout.fillWidth: true
                           Layout.bottomMargin: 5
                           PlasmaComponents.TabButton {
                                text: "All"
                                onClicked: mcws.playlists.filterType = text
                            }
                            PlasmaComponents.TabButton {
                                text: "Smartlists"
                                onClicked: mcws.playlists.filterType = text
                            }
                            PlasmaComponents.TabButton {
                                text: "Playlists"
                                onClicked: mcws.playlists.filterType = text
                            }
                            PlasmaComponents.TabButton {
                                text: "Groups"
                                onClicked: mcws.playlists.filterType = text
                            }
                        }
                    }

                    Viewer {
                        id: playlistView
                        model: mcws.playlists.model

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
                                onClicked: mcws.playlists.add(lv.currentIndex, id, autoShuffle)
                            }
                            PlasmaComponents.ToolButton {
                                iconSource: "search"
                                flat: false
                                onClicked: {
                                    playlistView.currentIndex = index
                                    mcws.playlists.currentIndex = index
                                    trackView.showPlaylist()
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
                            Layout.alignment: Qt.AlignBottom
                            implicitHeight: units.gridUnit*1.6
                            model: hostModel
                            contentItem: PlasmaExtras.Heading {
                                      text: hostList.displayText
                                      level: 4
                            }
                            onActivated: {
                                if (mcws.currentHost.indexOf(currentText) === -1) {
                                    mcws.tryConnect(currentText)
                                }
                            }
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
                                        Layout.fillWidth: true
                                        wrapMode: Text.NoWrap
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton | Qt.LeftButton
                                        onClicked: lv.currentIndex = index
                                        hoverEnabled: true
                                        // popup next track info
                                        QtControls.ToolTip.visible: containsMouse
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
                                        QtControls.ToolTip.text: track.stringify

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

                    Menu {
                        id: zoneMenu

                        function showAt(item) {
                            linkMenu.loadActions()
                            open(item)
                        }

                        MenuItem {
                            text: "Shuffle Playing Now"
                            iconName: "shuffle"
                            onTriggered: mcws.shuffle(lv.currentIndex)
                        }
                        MenuItem {
                            text: "Clear Playing Now"
                            iconName: "edit-clear"
                            onTriggered: mcws.clearPlayingNow(lv.currentIndex)
                        }
                        MenuSeparator{}

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
                        MenuItem {
                            text: "Clear All Zones"
                            iconName: "edit-clear"
                            onTriggered: mcws.forEachZone(function(zone, ndx) { mcws.clearPlayingNow(ndx) })
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
                                onClicked: {
                                    if (!checked && trackView.searchMode)
                                        trackView.reset()
                                }
                            }

                            PlasmaExtras.Title {
                                id: tvTitle
                                text: {
                                    if (trackView.showingPlaylist)
                                        '< Playlist "%1"'.arg(mcws.playlists.currentName)
                                    else (trackView.searchMode || searchButton.checked
                                         ? '< Searching All Tracks'
                                         : "Playing Now/" + (lv.currentIndex >= 0 ? lv.getObj().zonename : ""))
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
                            PlasmaComponents.TextField {
                                id: searchField
                                selectByMouse: true
                                clearButtonShown: true
                                placeholderText: trackView.showingPlaylist
                                                 ? 'Play or add "%1" >>'.arg(mcws.playlists.currentName)
                                                 : 'Enter search'
                                font.pointSize: theme.defaultFont.pointSize-1
                                Layout.fillWidth: true
                                enabled: !trackView.showingPlaylist
                                onVisibleChanged: {
                                    if (visible)
                                        forceActiveFocus()
                                }

                                onAccepted: {
                                    var fld = searchField.text
                                    // One char is a "starts with" search, ignore genre
                                    if (fld.length === 1)
                                        trackView.search({'[Name]': '[%1"'.arg(fld)
                                                          , '[Artist]': '[%1"'.arg(fld)
                                                          , '[Album]': '[%1"'.arg(fld)
                                                          }, false )
                                    // Otherwise, it's a "like" search
                                    else if (fld.length > 1)
                                        trackView.search({'[Name]': '"%1"'.arg(fld)
                                                          , '[Artist]': '"%1"'.arg(fld)
                                                          , '[Album]': '"%1"'.arg(fld)
                                                          , '[Genre]': '"%1"'.arg(fld)
                                                          }, false)
                                }
                            }
                            PlayButton {
                                enabled: trackView.searchMode & trackView.model.count > 0
                                onClicked: {
                                    if (trackView.showingPlaylist)
                                        mcws.playlists.play(lv.currentIndex, mcws.playlists.currentID, autoShuffle)
                                    else
                                        mcws.searchAndPlayNow(lv.currentIndex, trackView.mcwsQuery, autoShuffle)
                                }
                            }
                            AddButton {
                                enabled: trackView.searchMode & trackView.model.count > 0
                                onClicked: {
                                    if (trackView.showingPlaylist)
                                        mcws.playlists.add(lv.currentIndex, mcws.playlists.currentID, autoShuffle)
                                    else
                                        mcws.searchAndAdd(lv.currentIndex, trackView.mcwsQuery, true, autoShuffle)
                                }
                            }
                        }
                    }  //header

                    Viewer {
                        id: trackView

                        property string mcwsQuery: ''
                        property bool searchMode: mcwsQuery !== ''
                        property bool showingPlaylist: mcwsQuery ==='playlist'

                        TrackModel {
                            id: searchModel
                            hostUrl: mcws.hostUrl
                            queryCmd: 'Files/Search?query='
                        }

                        Component.onCompleted: {
                            mcws.pnPositionChanged.connect(function(zonendx, pos) {
                                if (!searchMode && zonendx === lv.currentIndex) {
                                    positionViewAtIndex(pos, ListView.Center)
                                    currentIndex = pos
                                }
                            })
                        }

                        function highlightPlayingTrack() {
                            if (trackView.model.count === 0)
                                return

                            if (trackView.searchMode) {
                                var fk = lv.getObj().filekey
                            // FIXME: this needs to understand which model
                                var ndx = lv.getObj().pnModel.findIndex(function(item){ return item.filekey === fk })
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
                                ndx = lv.getObj().playingnowposition
                                if (ndx !== undefined && (ndx >= 0 & ndx < trackView.model.count) ) {
                                    currentIndex = ndx
                                    event.singleShot(250, function() {trackView.positionViewAtIndex(ndx, ListView.Center)})
                                }
                            }
                        }

                        // Issue a search, contraints should be an object of mcws {field: value....}
                        function search(constraints, andTogether) {

                            searchModel.logicalJoin = (andTogether === true || andTogether === undefined ? 'and' : 'or')
                            searchModel.constraintList = constraints
                            mcwsQuery = searchModel.constraintString
                            trackView.model = searchModel

                            searchButton.checked = true
                            // show the first constraint value
                            for (var k in constraints) {
                                searchField.text = constraints[k].replace(/(\[|\]|\")/g, '')
                                break
                            }

                            if (mainView.currentIndex !== 2)
                                event.singleShot(700, function(){ mainView.currentIndex = 2 })
                        }

                        // Puts the view in search mode, sets the view model to the playlist tracks
                        function showPlaylist() {

                            searchButton.checked = true
                            searchField.text = ''

                            mcwsQuery = 'playlist'
                            trackView.model = mcws.playlists.trackModel

                            event.singleShot(500, function()
                            {
                                if (mainView.currentIndex !== 2)
                                    mainView.currentIndex = 2
                                trackView.currentIndex = -1
                            })
                        }

                        function formatDuration(dur) {
                            var num = dur.split('.')[0]
                            return "(%1:%2) ".arg(Math.floor(num / 60)).arg(String((num % 60) + '00').substring(0,2))
                        }

                        function reset() {
                            resetSearch()
                            // set model to the current zone's PN
                            trackView.model = lv.getObj().pnModel
                            event.singleShot(500, highlightPlayingTrack)
                        }
                        function resetSearch() {
                            mcwsQuery = ''
                            searchButton.checked = false
                            mcws.playlists.currentIndex = -1
                            searchModel.constraintList = {}
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
                                        mcws.getTrackDetails(filekey, function(ti){
                                            td = ti.stringify
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
                                    mcws.playTrackByKey(lv.currentIndex, detailMenu.currObj.filekey)
                                }
                                else
                                    mcws.playTrack(lv.currentIndex, trackView.currentIndex)
                            }
                        }
                        MenuItem {
                            text: "Add Track"
                            onTriggered: mcws.addTrack(lv.currentIndex, detailMenu.currObj.filekey)
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
                                        mcws.playlists.play(lv.currentIndex, mcws.playlists.currentID, autoShuffle)
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
                                onTriggered: mcws.searchAndAdd(lv.currentIndex, "artist=[%1]".arg(detailMenu.currObj.artist), false, autoShuffle)
                            }
                            MenuItem {
                                id: addGenre
                                onTriggered: mcws.searchAndAdd(lv.currentIndex, "genre=[%1]".arg(detailMenu.currObj.genre), false, autoShuffle)
                            }
                            MenuSeparator{}
                            MenuItem {
                                text: "Current List"
                                enabled: trackView.searchMode
                                onTriggered: {
                                    if (trackView.showingPlaylist)
                                        mcws.playlists.add(lv.currentIndex, mcws.playlists.currentID, autoShuffle)
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
                                onTriggered: trackView.search({'[album]': '[%1]'.arg(detailMenu.currObj.album)
                                                               , '[artist]': '[%1]'.arg(detailMenu.currObj.artist)})
                            }
                            MenuItem {
                                id: showArtist
                                onTriggered: trackView.search({'[artist]': '[%1]'.arg(detailMenu.currObj.artist)})
                            }
                            MenuItem {
                                id: showGenre
                                onTriggered: trackView.search({'[genre]': '[%1]'.arg(detailMenu.currObj.genre)})
                            }
                        }

                        MenuSeparator{}
                        MenuItem {
                            text: "Shuffle Playing Now"
                            enabled: !trackView.searchMode
                            onTriggered: mcws.shuffle(lv.currentIndex)
                        }
                        MenuItem {
                            text: "Clear Playing Now"
                            enabled: !trackView.searchMode
                            onTriggered: mcws.clearPlayingNow(lv.currentIndex)
                        }
                        MenuSeparator{}
                        MenuItem {
                            text: "Reset View"
                            onTriggered: trackView.reset()
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
                                    trackView.search(obj)
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
        thumbSize: plasmoid.configuration.highQualityThumbs ? 128 : 32
        pollerInterval: plasmoid.configuration.updateInterval *
                        (panelZoneView | plasmoid.expanded ? 1000 : 3000)

        function tryConnect(host) {
            currentHost = host.indexOf(':') === -1
                    ? '%1:%2'.arg(host).arg(plasmoid.configuration.defaultPort)
                    : host
        }

        // A failed connected could be not-timed-out yet, while a valid connection
        // is currently in use.  Make sure the connection error is for the correct host.
        onConnectionError: {
            if (cmd.indexOf(currentHost) !== -1)
                currentHost = ''
        }

        onTrackKeyChanged: {
            if (plasmoid.configuration.showTrackSplash)
                splasher.go(zoneModel.get(zonendx), imageUrl(trackKey))
        }
    }

    Process { id: shell }

    function action_screens() {
        shell.exec("kcmshell5 kcm_kscreen")
    }
    function action_pulse() {
        shell.exec("kcmshell5 kcm_pulseaudio")
    }
    function action_power() {
        shell.exec("kcmshell5 powerdevilprofilesconfig")
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
