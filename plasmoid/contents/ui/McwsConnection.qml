import QtQuick 2.15
import QtQuick.Controls 2.12

import 'helpers'
import 'models'
import 'helpers/utils.js' as Utils

Item {
    id: root

    readonly property bool isConnected: zoneModel.count > 0 && zonePoller.running

    // Each "zone" obj in the "zones" model is a "Playback/Info" object with
    // a track list (current playing list), a playback controller (player),
    // and a track object (current track)
    readonly property BaseListModel  zoneModel: BaseListModel {

        // Check if mcws host zone setup (count) has changed
        function checkZoneCount() {
            if (checkForZoneChange) {
                comms.loadObject("Playback/Zones", (zlist) => {
                    if (+zlist.numberzones !== zoneModel.count)
                        reset()
                })
            }
        }

        // Clear the model
        function clearModel() {
            forEach(zone => {
                zone.trackList.destroy()
                zone.player.destroy()
            })
            clear()
        }

        // Populate the model, each obj is a "Playback/Info" for the mcws zone
        function load() {
            var includedZones = hostConfig.zones.split(',')

            var checkInclude = ndx => {
                if (includedZones[0] === '*' || includedZones.length === 0)
                    return true
                else
                    return includedZones.includes(ndx.toString())
            }

            comms.loadObject("Playback/Zones", (data) => {
                debugLogger('BEGIN: zones::load()', 'Playback/Zones', data)
                var n = 0  // the actual index in the model
                for(var i=0; i<data.numberzones; ++i) {
                    if (checkInclude(i)) {
                        append({ zoneid: data["zoneid"+i]
                                   , zonename: data["zonename"+i]
                                   , name: ''
                                   , artist: ''
                                   , album: ''
                                   , status: 'Stopped'
                                   , state: PlayerState.Stopped
                                   , playingnowchangecounter: -1
                                   , playingnowposition: -1
                                   , playingnowtracks: 0
                                   , linked: false
                                   , linkedzones: ''
                                   , mute: false
                                   , trackdisplay: ''
                                   , nexttrackdisplay: ''
                                   , audiopath: ''
                                   , filekey: 0
                                   , nextfilekey: 0
                                   , trackList:
                                        tl.createObject(root, { searchCmd: 'Playback/Playlist?Zone=' + data["zoneid"+i] })
                                   , track: {}
                                   , player: zp.createObject(root, { zonendx: n })
                               })
                        ++n
                    }
                }
                // Start the update poller
                zonePoller.start()
                // Notify that the connection is ready
                // Wait a bit so the zones can update playing state/status
                event.queueCall(300, connectionReady, host, getPlayingZoneIndex())
                debugLogger('END: zones::load()'
                            , '%1, %2 zones loaded'.arg(host).arg(zoneModel.count)
                            , '')
            })
        }

    }

    readonly property Reader         comms: Reader {

        // the network is down?
        onConnectionError: {
            console.warn('CONNECTION', cmd, msg)
            root.connectionError(msg, cmd)
            // if the error occurs with the current host, close
            if (cmd.includes(currentHost)) {
                closeConnection()
            }
        }
        // MCWS is not available
        onCommandError: {
            console.warn('COMMAND', cmd, msg)
            root.commandError(msg, cmd)
            // if the error occurs with the current host, close
            if (cmd.includes(currentHost)) {
                closeConnection()
            }
        }
    }

    readonly property McwsImageUtils imageUtils: McwsImageUtils {
        hostUrl: root.comms.hostUrl
        thumbnailSize: highQualityThumbs ? 'Large' : 'Small'
    }

    readonly property Playlists      playlists: Playlists {
        comms: root.comms
        trackModel.mcwsFields: mcwsFieldsModel
        onDebugLogger: root.debugLogger(title, msg, obj)
    }

    readonly property LookupValues   quickSearch: LookupValues {
        hostUrl: comms.hostUrl
    }

    readonly property alias streamSources: streamingSources.streams
    readonly property alias stationSources: streamingSources.stations

    // Manage the host audiodevices list
    readonly property BaseListModel audioDevices: BaseListModel {
        // arr of { device, devicePlugin }
        // Audio device is a per zone seting, see zoneplayer item

        // list is in mcws "index" order
        function load() {
            comms.loadObject("Configuration/Audio/ListDevices", data => {
                for(var i=0, len=data.numberdevices; i<len; ++i) {
                    audioDevices.append({ index: i
                                        , device: data['devicename'+i]
                                        , devicePlugin: data['deviceplugin'+i]
                                        })
                }
            })
        }

    }

    // mcws "alive" info
    readonly property alias serverInfo: mcws.serverInfo

    property alias  pollerInterval      : zonePoller.interval
    property bool   videoFullScreen     : false
    property bool   highQualityThumbs   : true

    // host config object
    property var hostConfig         : ({})
    readonly property alias host    : root.comms.currentHost

    // Setting the hostConfig initiates a connection attempt
    // null means close/reset, otherwise, attempt connect
    onHostConfigChanged: {
        comms.currentHost = hostConfig ? hostConfig.host ?? '' : ''
    }
    onHostChanged: {
        zonePoller.stop()
        zoneModel.clearModel()
        audioDevices.clear()
        streamingSources.clear()

        if (host !== '') {
            connectionStart(host)
            comms.loadObject("Alive", obj => {
                mcws.serverInfo = obj
                zoneModel.load()
                audioDevices.load()
                streamingSources.load()
                debugLogger('Alive', 'Server Info', mcws.serverInfo)
            })
        }
        else {
            connectionStopped()
        }
    }

    // Model for mcws field setup
    // {field: string, sortable: bool, searchable: bool, mandatory: bool}
    readonly property BaseListModel mcwsFieldsModel: BaseListModel {}
    property string defaultFields: ''
    onDefaultFieldsChanged: {
        mcwsFieldsModel.clear()
        try {
            var arr = JSON.parse(defaultFields)
            if (Array.isArray(arr)) {
                arr.forEach(item => mcwsFieldsModel.append(item))
                reset()
            }
            else
                throw 'Invalid array parameter'
        }
        catch (err) {
            console.log(err)
            console.log('WARNING: MCWS default field setup NOT FOUND.  Search features may not work properly.')
        }
    }

    SingleShot { id: event }

    Timer {
        id: zonePoller
        repeat: true

        // non-playing tick ctr
        property int updateCtr: 0

        onTriggered: {
            // update non-playing zones every 5 ticks, playing zones, every tick
            if (++updateCtr === 5) {
                updateCtr = 0
            }

            zoneModel.forEach(zone => {
                if (zone.state !== PlayerState.Stopped
                    | updateCtr === 0) {
                    zone.player.update()
                }
            })
        }

        onIntervalChanged: {
            updateCtr = 0
        }
    }

    enum CmdType {
        Unused = 0,
        Playback,
        Search,
        Playlists,
        MCC,
        DSP,
        UserInterface
    }

    enum UiMode {
        Standard = 0,
        Mini,
        Display,
        Theater,
        Cover
    }

    // Streaming
    QtObject {
        id: streamingSources

        property var streams: []
        property var stations: []

        function load() {
            comms.loadObject("UserInterface/GetStreaming", data => {
                streams = data.streaming.split(';')
                stations = data.stations.split(';')
            })
        }

        function clear() {
            streams.length = 0
            stations.length = 0
        }
    }

    // Command helpers and host info
    QtObject {
        id: mcws

        property var serverInfo: ({})

        readonly property string cmd_MCC_SetZone:   '10011&Parameter='
        readonly property string cmd_MCC_UIMode:    '22009&Parameter='
        readonly property string cmd_MCC_Minimize:  '10014'
        readonly property string cmd_MCC_Maximize:  '10027'
        readonly property string cmd_MCC_Detach:    '10037'
        readonly property string cmd_MCC_OpenURL:   '20001'
        readonly property string cmd_MCC_OpenLive:  '20035'
        readonly property string str_EmptyPlaylist: '<empty playlist>'

        /* Command Obj Defaults

              { zonendx: -1
                , cmd: ''
                , delay: 0
                , cmdType: McwsConnection.CmdType.Playback
                , forceRefresh: true
              }
        */
        function execCmd(parms) {
            var obj = createCmd(parms)
            if (obj) {
                _run([obj])
                return true
            }
            return false
        }
        function createCmd(parms) {
            if (parms === undefined || parms === '') {
                debugLogger('createCmd()', 'Invalid parameter: requires string or object type')
                return undefined
            }

            var obj = { zonendx: -1
                        , cmd: ''
                        , delay: 0
                        , cmdType: McwsConnection.CmdType.Playback
                        , forceRefresh: true
                      }

            // single cmd string, assume a complete cmd with zone constraint
            if (typeof parms === 'string') {
                obj.cmd = parms
            // otherwise, set defaults, construct final cmd obj
            } else if (Utils.isObject(parms)) {

                Object.assign(obj, parms)

                switch (obj.cmdType) {
                    case McwsConnection.CmdType.Playback:
                        obj.cmd = 'Playback/' + obj.cmd
                        break
                    case McwsConnection.CmdType.Search:
                        obj.cmd = 'Files/Search?' + obj.cmd
                        break
                    case McwsConnection.CmdType.Playlists:
                        obj.cmd = 'Playlist/Files?' + obj.cmd
                        break
                    case McwsConnection.CmdType.MCC:
                        obj.cmd = 'Control/MCC?Command=' + obj.cmd
                        break
                    case McwsConnection.CmdType.DSP:
                        obj.cmd = 'DSP/' + obj.cmd
                        break
                    case McwsConnection.CmdType.UserInterface:
                        obj.cmd = 'UserInterface/' + obj.cmd

                }

                // Set zone constraint
                if (obj.zonendx >= 0 && obj.zonendx !== null) {

                    obj.cmd += (!obj.cmd.includes('?') ? '?' : '&')
                                + 'Zone=' + zoneModel.get(obj.zonendx).zoneid
                }
                if (serverInfo.hasOwnProperty('token'))
                    obj.cmd += '&token=' + serverInfo.token
            }

//            debugLogger(obj.zonendx !== -1 ? zones.get(obj.zonendx) : {zonename: 'Global'}
//                        , 'mcws::CreateCmd(): ' + Utils.stringifyObj(obj))

            return obj
        }

        function _exec(obj) {
            let xhr = new XMLHttpRequest()
            xhr.onerror = () => {
                connectionError('Connection failure', comms.hostUrl + obj.cmd)
            }

            xhr.open("POST", comms.hostUrl + obj.cmd)
            xhr.send()

            if (obj.forceRefresh && obj.zonendx >= 0)
                event.queueCall(500, zoneModel.get(obj.zonendx).player.update)

            debugLogger(obj.zonendx !== -1
                            ? zoneModel.get(obj.zonendx).zonename
                            : 'Global'
                        , '_exec(): ' + comms.hostUrl + obj.cmd
                        , obj)
        }
        function _run(cmdArray) {

            if (!Utils.isObject(cmdArray) || cmdArray.length === 0) {
                debugLogger('_run()', 'Invalid command list: requires array of objects')
                return false
            }

            cmdArray.forEach(function(cmd) {
                if (cmd.delay === undefined || cmd.delay <= 0) {
                    _exec(cmd)
                } else {
                    event.queueCall(cmd.delay, _exec, cmd )
                }

            })

            return true
        }

    }

    // TrackList searcher, one per zone
    Component {
        id: tl

        Searcher {
            comms: root.comms
            mcwsFields: mcwsFieldsModel
            onDebugLogger: root.debugLogger(title, msg, obj)
        }
    }

    // Zone player, one per zone
    Component {
        id: zp

        Item {
            property int zonendx

            Component.onCompleted: event.queueCall(update)

            // Props for the player, not part of zone info (GetInfo)
            property string currentShuffle: ''
            property string currentRepeat: ''
            property bool currentEq: false
            property bool currentLoudness: false
            property int audioDevice: -1

            // Player Actions
            property Action equalizer: Action {
                text: "Equalizer"
                icon.name: "adjustlevels"
                checkable: true
                checked: currentEq
                onTriggered: {
                    currentEq = !currentEq
                    setDSP('Equalizer', currentEq)
                    getAudioPath(2000)
                }
            }
            property Action loudness: Action {
                text: "Loudness"
                icon.name: "audio-volume-high"
                checkable: true
                checked: currentLoudness
                onTriggered: {
                    currentLoudness = !currentLoudness
                    setLoudness(currentLoudness)
                }
            }
            property Action clearPlayingNow: Action {
                text: "Clear Playing Now"
                icon.name: "edit-clear"
                onTriggered: {
                    mcws.execCmd({zonendx: zonendx, cmd: "ClearPlaylist"})
                    zoneModel.get(zonendx).trackList.clear()
                }
            }

            property Action play: Action {
                icon.name: "media-playback-start"
                onTriggered: {
                    if (zoneModel.get(zonendx).track.mediatype !== 'Audio') {
                        if (zoneModel.get(zonendx).state === PlayerState.Stopped) {
                            setCurrent()
                            if (videoFullScreen)
                                setUIMode(McwsConnection.UiMode.Display)
                        }
                    }
                    mcws.execCmd({zonendx: zonendx, cmd: 'PlayPause'})
                }
            }
            property Action previous: Action {
                icon.name: "media-skip-backward"
                onTriggered: mcws.execCmd({zonendx: zonendx, cmd: 'Previous'})
            }
            property Action next: Action {
                icon.name: "media-skip-forward"
                onTriggered: mcws.execCmd({zonendx: zonendx, cmd: 'Next'})
            }
            property Action stop: Action {
                icon.name: "media-playback-stop"
                onTriggered: {
                    mcws.execCmd({zonendx: zonendx, cmd: 'Stop'})
                    // Minimize if playing a video
                    if (zoneModel.get(zonendx).track.mediatype === 'Video') {
                        mcws.execCmd({delay: 500
                                      , cmdType: McwsConnection.CmdType.MCC
                                      , cmd: mcws.cmd_MCC_Minimize})
                    }
                }
            }

            // Shuffle/repeat playlist
            property Action shuffle: Action {
                text: 'Shuffle Playlist Now'
                icon.name: 'shuffle'
                onTriggered: setShuffle('Reshuffle')
            }
            property list<Action> shuffleModes: [
                Action {
                    text: 'On'
                    icon.name: 'shuffle'
                    checkable: true
                    checked: currentShuffle === text
                    onTriggered: setShuffle(text)
                },
                Action {
                    text: 'Off'
                    icon.name: 'process-stop'
                    checkable: true
                    checked: currentShuffle === text
                    onTriggered: setShuffle(text)
                },
                Action {
                    text: 'Automatic'
                    icon.name: 'shuffle'
                    checkable: true
                    checked: currentShuffle === text
                    onTriggered: setShuffle(text)
                }
            ]
            property list<Action> repeatModes: [
                Action {
                    text: 'Playlist'
                    icon.name: 'media-playlist-repeat'
                    checkable: true
                    checked: currentRepeat === text
                    onTriggered: setRepeat(text)
                },
                Action {
                    text: 'Track'
                    icon.name: 'media-repeat-track'
                    checkable: true
                    checked: currentRepeat === text
                    onTriggered: setRepeat(text)
                },
                Action {
                    text: 'Off'
                    icon.name: 'process-stop'
                    checkable: true
                    checked: currentRepeat === text
                    onTriggered: setRepeat(text)
                }
            ]

            function formatTrackDisplay(trk) {
                // 'null' playlist
                if (trk.playingnowtracks === 0 || trk.filekey === -1) {
                    trk.name = trk.artist = trk.album = mcws.str_EmptyPlaylist
                    return mcws.str_EmptyPlaylist
                }

                return !trk.mediatype || trk.mediatype === 'Audio'
                      ? '<b>%1</b><br>%2<br>%3'.arg(trk.name).arg(trk.artist).arg(trk.album)
                      : trk.name
            }

            // Update zoneModel item
            function update() {
                var zone = zoneModel.get(zonendx)
                comms.loadObject("Playback/Info?zone=" + zone.zoneid, obj =>
                {
                    let needAudioPath = false

                    // Work-around MCWS bug with zonename missing when connected to another connected server
                    if (!obj.zonename) obj.zonename = zone.zonename
                    // Artist and album can be missing
                    if (!obj.artist) obj.artist = ''
                    if (!obj.album)  obj.album  = ''
                    // Status is transient, if not present, the player is inactive
                    if (!obj.status) obj.status = 'Stopped'

//                    debugLogger(obj.zonename + ':  Playback/Info Tick'
//                                , 'State: %1 - %2'.arg(obj.state).arg(obj.status)
//                                , obj)

                    // This ctr changes every time the current playing now changes
                    // At connect on first update, this fires and loads the tracklist
                    if (obj.playingnowchangecounter !== zone.playingnowchangecounter) {
                        pnChangeCtrChanged(zonendx, obj.playingnowchangecounter)
                        zone.trackList.load()
                    }

                    // Explicit track change signal and track display update
                    // Web streams are checked every tick, unless there is a filekey change
                    if (obj.filekey !== zone.filekey) {
                        if (obj.filekey !== -1) {
                            getTrackDetails(obj.filekey, ti =>
                            {
                                zone.track = ti
                                zone.trackdisplay = formatTrackDisplay(ti)
                                debugLogger(zone.zonename + ': getTrackDetails() ' + obj.filekey, '', ti)
                            })

                            if (obj.state === PlayerState.Playing)
                                needAudioPath = true
                        } else {
                            zone.trackdisplay = mcws.str_EmptyPlaylist
                            zone.audiopath = ''
                            Utils.simpleClear(zone.track)
                        }
                        trackKeyChanged(zonendx, obj.filekey)
                    }
                    // Check for web media streaming
                    // Check every tick as MC track key will not change,
                    // but streaming track info will change
                    else if (zone.track.webmediaurl) {
                        // Use name/artist/album to determine trk change
                        if (obj.name !== zone.name
                            || obj.artist !== zone.artist
                            || obj.album  !== zone.album)
                        {
                            zone.trackdisplay = formatTrackDisplay(obj)
                            trackKeyChanged(zonendx, obj.filekey)
                            if (obj.state === PlayerState.Playing)
                                needAudioPath = true
                            debugLogger(zone.track.webmediaurl
                                        , 'Setting WebStream TrackDisplay(%1/%2)'
                                            .arg(zone.trackdisplay)
                                            .arg(obj.filekey)
                                        , '')
                        }
                    }

                    // Next file info
                    if (obj.nextfilekey !== zone.nextfilekey) {
                        if (obj.nextfilekey === -1)
                            zone.nexttrackdisplay = 'End of Playlist'
                        else {
                            // tracklist may be loading so wait a bit
                            event.queueCall(1500, () =>
                            {
                                if (zone.trackList.items.count !== 0) {
                                    var pos = obj.playingnowposition + 1
                                    if (pos !== obj.playingnowtracks) {
                                        var o = zone.trackList.items.get(pos)
                                        zone.nexttrackdisplay = 'Next up:<br>' + formatTrackDisplay(o)
                                    } else {
                                        zone.nexttrackdisplay = 'End of Playlist'
                                    }
                                } else {
                                    zone.nexttrackdisplay = 'Playlist Empty'
                                }
                                debugLogger(zone.zonename +
                                            ': NEXT track display (%1)'
                                                .arg(obj.nextfilekey)
                                            , zone.nexttrackdisplay, '')
                            })
                        }
                    }

                    // Explicit playingnowposition signal
                    if (obj.playingnowposition !== zone.playingnowposition) {
                        pnPositionChanged(zonendx, obj.playingnowposition)
                    }

                    // Explicit Playback state signal (update audio path)
                    // Don't trigger audiopath if not a "standard" state
                    if (obj.state !== zone.state) {
                        pnStateChanged(zonendx, obj.state)
                        needAudioPath = (obj.state === PlayerState.Playing
                                            || obj.state === PlayerState.Paused
                                            || obj.state === PlayerState.Stopped)
                                          ? true
                                          : needAudioPath
                    }

                    // linkedzones is a transient field
                    if (obj.linkedzones)
                        zone.linked = true
                    else {
                        zone.linked = false
                        zone.linkedzones = ''
                    }

                    zone.mute = obj.volumedisplay === "Muted"

                    zoneModel.set(zonendx, obj)

                    // Audio Path
                    if (needAudioPath)
                        getAudioPath()
                })
            }

            // General Track Playback
            function playTrack(pos) {
                mcws.execCmd({zonendx: zonendx
                                , cmd: "PlaybyIndex?Index="
                                       + zoneModel.get(zonendx).trackList.items.mapRowToSource(pos)})
            }
            function playTrackByKey(filekey) {
                mcws.execCmd({zonendx: zonendx
                                , cmd: 'PlaybyKey?Location=Next&Key=' + filekey})
                if (zoneModel.get(zonendx).state === PlayerState.Playing)
                    mcws.execCmd({zonendx: zonendx
                                    , cmd: 'Next'
                                    , delay: 1000})
            }
            function playAlbum(filekey) {
                mcws.execCmd({zonendx: zonendx, cmd: "PlaybyKey?Album=1&Key=" + filekey})
            }
            function queueAlbum(filekey, next) {
                mcws.execCmd({zonendx: zonendx
                                , cmd: 'PlaybyKey?Key=%1&Album=1&Location=%2'
                                        .arg(filekey)
                                        .arg(next === undefined || next ? "Next" : "End")
                                })
            }

            // Play Streams
            function playRadioStation(source, channel) {

                const chStr = source.includes('JRiver')
                            ? 'Station'
                            : 'Channel'
                mcws.execCmd({ zonendx: zonendx
                            , cmd: "Play%1?%2=%3".arg(source).arg(chStr).arg(channel)
                             })

            }

            // Search
            function searchAndPlayNow(srch, shuffleMode) {
                mcws.execCmd({zonendx: zonendx
                                  , cmdType: McwsConnection.CmdType.Search
                                  , cmd: "Action=Play&query=" + srch
                                    + (shuffleMode === undefined || shuffleMode ? "&Shuffle=1" : "")
                                })
            }

            function searchAndAdd(srch, next, shuffleMode) {
                mcws.execCmd({zonendx: zonendx
                                , cmdType: McwsConnection.CmdType.Search
                                , forceRefresh: false
                                , cmd: 'Action=Play&query=' + srch
                                       + '&PlayMode=' + (next === undefined || next ? "NextToPlay" : "Add")
                               })
                if (shuffleMode === undefined || shuffleMode)
                    mcws.execCmd({zonendx: zonendx
                                    , cmd: 'Shuffle?Mode=reshuffle'
                                    , delay: 750})
            }

            function addTrack(filekey, next) {
                searchAndAdd("[key]=" + filekey, next, false)
            }

            function removeTrack(trackndx) {
                let ndx = zoneModel.get(zonendx).trackList.removeItem(trackndx)
                if (ndx !== -1)
                    mcws.execCmd({forceRefresh: false
                                    , zonendx: zonendx
                                    , cmd: "EditPlaylist?Action=Remove&Source=" + ndx})
            }

            // Playlists
            function playPlaylist(id, shuffleMode) {
                mcws.execCmd({zonendx: zonendx,
                             cmdType: McwsConnection.CmdType.Playlists,
                             cmd: "Action=Play&Playlist=" + id
                                  + (shuffleMode === undefined || shuffleMode ? "&Shuffle=1" : "")
                            })
            }
            function addPlaylist(id, shuffleMode) {

                mcws.execCmd({zonendx: zonendx
                                , cmdType: McwsConnection.CmdType.Playlists
                                , forceRefresh: false
                                , cmd: 'Action=Play&PlayMode=Add&Playlist=' + id
                               })
                if (shuffleMode === undefined || shuffleMode)
                    mcws.execCmd({zonendx: zonendx
                                    , cmd: 'Shuffle?Mode=reshuffle'
                                    , delay: 750})
            }

            // Audio Specifics
            function getAudioDevice() {
                        comms.loadObject("Configuration/Audio/GetDevice?Zone=" + zoneModel.get(zonendx).zoneid
                                , dev => audioDevice = dev.deviceindex)
            }

            function setAudioDevice(devndx) {
                mcws.execCmd({ zonendx: zonendx
                             , cmdType: McwsConnection.CmdType.Unused
                             , cmd: 'Configuration/Audio/SetDevice?DeviceIndex=' + devndx
                             })
                audioDevice = devndx
            }

            function getAudioPath(delay, cb) {
                if (delay === undefined)
                    delay = 2000

                event.queueCall(delay, () => {
                    var zone = zoneModel.get(zonendx)
                    comms.loadObject("Playback/AudioPath?Zone=" + zone.zoneid, ap => {
                         zone.audiopath = ap.audiopath !== undefined
                                             ? ap.audiopath.replace(/;/g, '\n')
                                             : ''

                         currentEq = zone.audiopath.toLowerCase().includes('equalizer')

                         if (Utils.isFunction(cb))
                             cb(ap)

                         debugLogger(zone.zonename + ': getAudioPath(delay=%1)'.arg(delay)
                                     , '', ap)
                    })
                })
            }

            // Misc
            function setCurrent() {
                mcws.execCmd({cmdType: McwsConnection.CmdType.MCC
                                , forceRefresh: false
                                , cmd: mcws.cmd_MCC_SetZone + zonendx})
            }
            function setUIMode(mode) {
                mcws.execCmd({cmdType: McwsConnection.CmdType.MCC
                                   , delay: 500
                                   , forceRefresh: false
                                   , cmd: mcws.cmd_MCC_UIMode
                                          + (mode === undefined ? McwsConnection.UiMode.Standard : mode)})
            }
            function playURL(url) {
                setCurrent()
                mcws.execCmd({cmdType: McwsConnection.CmdType.MCC
                                   , delay: 500
                                   , forceRefresh: false
                                   , cmd: mcws.cmd_MCC_OpenURL})
            }

            // Zone Linking
            function unLinkZone() {
                mcws.execCmd({zonendx: zonendx, cmd: 'UnlinkZones'})
            }
            function linkZone(zone2id) {
                mcws.execCmd("Playback/LinkZones?Zone1="
                               + zoneModel.get(zonendx).zoneid + "&Zone2=" + zone2id)
            }

            // Volume
            function setMute( mute) {
                mcws.execCmd({zonendx: zonendx
                                , cmd: "Mute?Set="
                                       + (mute === undefined ? "1" : mute ? "1" : "0")})
            }
            function setVolume(level) {
                mcws.execCmd({forceRefresh: false
                             , zonendx: zonendx
                             , cmd: "Volume?Level=" + level})
            }
            function setPlayingPosition(pos) {
                mcws.execCmd({zonendx: zonendx
                             , cmd: "Position?Position=" + pos})
            }

            // Shuffle/Repeat
            function getRepeatMode(callback) {
                comms.loadObject("Playback/Repeat?Zone=" + zoneModel.get(zonendx).zoneid,
                                  (repeat) =>
                                  {
                                      currentRepeat = repeat.mode
                                      if (Utils.isFunction(callback))
                                        callback(currentRepeat)
                                  })
            }
            function setRepeat(mode) {
                mcws.execCmd({forceRefresh: false
                             , zonendx: zonendx
                             , cmd: "Repeat?Mode=" + mode})
            }
            function getShuffleMode(callback) {
                comms.loadObject("Playback/Shuffle?Zone=" + zoneModel.get(zonendx).zoneid,
                                  (shuffle) =>
                                  {
                                      currentShuffle = shuffle.mode
                                      if (Utils.isFunction(callback))
                                          callback(currentShuffle)
                                  })
            }
            function setShuffle(mode) {
                mcws.execCmd({zonendx: zonendx, cmd: "Shuffle?Mode=" + mode})
            }

            // DSP
            function setDSP(dsp, enabled) {
                mcws.execCmd({ zonendx: zonendx, cmd: 'Set?DSP=%1&On='.arg(dsp)
                                 + (enabled === undefined || enabled ? '1' : '0')
                                 , cmdType: McwsConnection.CmdType.DSP })
            }
            function loadDSPPreset(preset) {
                mcws.execCmd({ zonendx: zonendx, cmd: 'LoadDSPPreset&Name=' + preset })
            }
            function setLoudness(enabled) {
                mcws.execCmd({ zonendx: zonendx, cmd: 'Loudness?Set='
                                 + (enabled === undefined || enabled ? '1' : '0')
                                 , cmdType: McwsConnection.CmdType.DSP })
            }
            function getLoudness(callback) {
                comms.loadObject("DSP/Loudness?Zone=" + zoneModel.get(zonendx).zoneid,
                                  (result) =>
                                  {
                                      currentLoudness = result.current === 1
                                      if (Utils.isFunction(callback))
                                          callback(currentLoudness)
                                  })
            }
        }
    }

    signal debugLogger(var title, var msg, var obj)
    signal connectionStart(var host)
    signal connectionStopped()
    signal connectionReady(var host, var zonendx)
    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)
    signal trackKeyChanged(var zonendx, var filekey)
    signal pnPositionChanged(var zonendx, var pos)
    signal pnChangeCtrChanged(var zonendx, var ctr)
    signal pnStateChanged(var zonendx, var playerState)

    property Action clearAllZones: Action {
        text: "Clear All Zones"
        icon.name: "edit-clear-all"
        onTriggered: zoneModel
                    .forEach(zone => zone.player.clearPlayingNow.triggered())
    }
    property Action stopAllZones: Action {
        text: "Stop All Zones"
        icon.name: "media-playback-stop"
        onTriggered: mcws.execCmd('Playback/StopAll')
    }

    // Force close the connection, clear structs
    function closeConnection() {
        hostConfig = {}
    }

    // Reset (reload) the connection if connected
    function reset() {
        if (isConnected) {
            var h = comms.currentHost
            comms.currentHost = ''
            event.queueCall(500, () => comms.currentHost = h)
        }
    }

    // Set list of file keys from items (track list)
    // to the destination zone and optionally play
    function sendListToZone(items, destIndex, playNow) {
        var arr = []
        items.forEach((track) => { arr.push(track.key) })
        mcws.execCmd({ zonendx: destIndex
                         , cmd: 'SetPlaylist?Playlist=2;%1;0;%2'.arg(arr.length).arg(arr.join(';')) })

        if (playNow === undefined || playNow)
            event.queueCall(750, zoneModel.get(destIndex).player.play)
    }

    // Return playing zone index.  If there are no playing zones,
    // returns 0 (first zone index).  If there are multiple
    // playing zones, return the index of the last in the list.
    function getPlayingZoneIndex() {
        var list = zonesByState(PlayerState.Playing)
        return list.length>0 ? list[list.length-1] : 0
    }

    // Zone player state, return index list
    function zonesByState(state) {
        return zoneModel.filter(zone => zone.state === state)
    }

    // Misc
    function importPath(path) {
        mcws.execCmd({cmdType: McwsConnection.CmdType.Unused
                          , cmd: 'Library/Import?Block=0&Path=' + path})
    }

    // Get mcws track info (optional fieldlist) for a filekey
    function getTrackDetails(filekey, callback, fieldlist) {
        if (!Utils.isFunction(callback))
            return

        if (filekey === -1)
            callback({})
        else {
            fieldlist = fieldlist === undefined || fieldlist.length === 0
                    ? 'NoLocalFileNames=1'
                    : 'Fields=' + fieldlist.join(',')
            // LoadJSON returns a list of objects, we just want the first (only) one here
            comms.loadJSON('File/GetInfo?%1&action=JSON&file='.arg(fieldlist) + filekey
                              , list => callback(list[0]))
        }
    }

}
