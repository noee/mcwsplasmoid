import QtQuick 2.8
import QtQuick.Controls 2.12

import 'helpers'
import 'models'
import 'helpers/utils.js' as Utils

Item {
    id: root

    readonly property bool isConnected: zones.count > 0 & connPoller.running
    readonly property alias zoneModel: zones
    readonly property var audioDevices: []
    readonly property alias playlists: playlists
    readonly property alias quickSearch: lookup
    readonly property alias comms: reader
    readonly property alias serverInfo: player.serverInfo
    // host config object
    property var hostConfig: ({})
    property alias host: reader.currentHost

    property alias pollerInterval: connPoller.interval
    property bool videoFullScreen: false
    property bool checkForZoneChange: false
    property int thumbSize: 32
    // Model for mcws field setup
    // {field: string, sortable: bool, searchable: bool, mandatory: bool}
    readonly property BaseListModel mcwsFieldsModel: BaseListModel{}
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

    signal debugLogger(var obj, var msg)

    enum CmdType {
        Unused = 0,
        Playback,
        Search,
        Playlists,
        MCC,
        DSP
    }

    enum UiMode {
        Standard = 0,
        Mini,
        Display,
        Theater,
        Cover
    }

    // Setting the hostConfig initiates a connection attempt
    // null means close/reset, otherwise, attempt connect
    onHostConfigChanged: {
        host = hostConfig.host ? hostConfig.host : ''
    }
    onHostChanged: {
        connPoller.stop()
        playlists.clear()
        lookup.clear()
        zones.forEach((zone) => {
            zone.trackList.destroy()
            zone.player.destroy()
        })
        zones.clear()
        audioDevices.length = 0

        if (host !== '') {
            connectionStart(host)
            reader.loadObject("Alive", (obj) => {
                player.serverInfo = obj
                player.load()
                player.loadAudioDevices()
                debugLogger('Alive', player.serverInfo)
            })
        }
        else {
            connectionStopped()
        }
    }

    // Player, controls/manages all playback zones
    // each "zone" obj in "zones" list model is a "Playback/Info" object with
    // a track list and a playback object for each zone,
    // (current playing list) and a track object (current track)
    Item {
        id: player

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
            } else if (typeof parms === 'object') {

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
                }

                // Set zone constraint
                if (obj.zonendx >= 0 && obj.zonendx !== null) {

                    obj.cmd += (!obj.cmd.includes('?') ? '?' : '&')
                                + 'Zone=' + zones.get(obj.zonendx).zoneid
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
                connectionError('Connection failure', reader.hostUrl + obj.cmd)
            }

            xhr.open("POST", reader.hostUrl + obj.cmd)
            xhr.send()

            if (obj.forceRefresh && obj.zonendx >= 0)
                event.queueCall(500, zones.get(obj.zonendx).player.update)

            debugLogger(obj.zonendx !== -1 ? zones.get(obj.zonendx) : 'Global'
                        , '_exec(): ' + reader.hostUrl + obj.cmd)
        }
        function _run(cmdArray) {

            if (typeof cmdArray !== 'object' || cmdArray.length === 0) {
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

        function checkZoneCount(callback) {
            if (checkForZoneChange) {
                reader.loadObject("Playback/Zones", (zlist) => {
                    if (+zlist.numberzones !== zones.count)
                        callback(+zlist.numberzones)
                })
            }
        }

        // Load Audio devices
        function loadAudioDevices(callback) {
            audioDevices.length = 0
            reader.loadObject("Configuration/Audio/ListDevices", (data) => {
                for(var i = 0; i<data.numberdevices; ++i) {
                    audioDevices.push('%1 (%2)'.arg(data['devicename'+i]).arg(data['deviceplugin'+i]))
                }
                if (Utils.isFunction(callback))
                    callback()
            })
        }

        // Populate the zones model, each obj is a "Playback/Info" for the mcws zone
        function load() {
            var includedZones = hostConfig.zones.split(',')
            var checkInclude = (ndx) => {
                if (includedZones[0] === '*' || includedZones.length === 0)
                    return true
                else
                    return includedZones.includes(ndx.toString())
            }

            reader.loadObject("Playback/Zones", (data) => {
                debugLogger('Playback/Zones', data)
                var n = 0
                for(var i=0; i<data.numberzones; ++i) {
                    if (checkInclude(i)) {
                        var zid = data["zoneid"+i]
                        var z = { zoneid: zid
                                   , zonename: data["zonename"+i]
                                   , name: data["zonename"+i]
                                   , artist: ''
                                   , album: ''
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
                                   , filekey: -1
                                   , nextfilekey: -1
                                   , trackList:
                                        tl.createObject(root, { searchCmd: 'Playback/Playlist?Zone=' + zid })
                                   , track: {}
                                   , player: zp.createObject(root, { zonendx: n })
                               }
                        zones.append(z)
                        z.player.update()
                        debugLogger('Zone Added, Index=' + n, z.zoneid + ' ' + z.zonename)
                        ++n
                    }
                }
                /* Notify that the connection is ready.
                 * Wait a bit so the zones can update playing status */
                event.queueCall(300, () => {
                    /* Start the connection status poller */
                    connPoller.start()
                    connectionReady(reader.hostUrl, getPlayingZoneIndex())
                })
                debugLogger('MCWS::load', '%1, %2 zones loaded'.arg(host).arg(zones.count))
            })
        }

        // TrackList searcher, one per zone
        Component {
            id: tl
            Searcher {
                comms: reader
                mcwsFields: mcwsFieldsModel
                onDebugLogger: root.debugLogger(obj, msg)
            }
        }
        // Zone player, one per zone
        Component {
            id: zp
            Item {
                property var zonendx

                // Props for the player, not part of zone info (GetInfo)
                property string currentShuffle: ''
                property string currentRepeat: ''
                property int currentAudioDevice: -1
                property bool currentEq: false
                property bool currentLoudness: false

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
                        player.execCmd({zonendx: zonendx, cmd: "ClearPlaylist"})
                        zones.get(zonendx).trackList.clear()
                    }
                }

                property Action play: Action {
                    icon.name: "media-playback-start"
                    onTriggered: {
                        if (zones.get(zonendx).track.mediatype !== 'Audio') {
                            if (zones.get(zonendx).state === PlayerState.Stopped) {
                                setCurrent()
                                if (videoFullScreen)
                                    setUIMode(McwsConnection.UiMode.Display)
                            }
                        }
                        player.execCmd({zonendx: zonendx, cmd: 'PlayPause'})
                    }
                }
                property Action previous: Action {
                    icon.name: "media-skip-backward"
                    onTriggered: player.execCmd({zonendx: zonendx, cmd: 'Previous'})
                }
                property Action next: Action {
                    icon.name: "media-skip-forward"
                    onTriggered: player.execCmd({zonendx: zonendx, cmd: 'Next'})
                }
                property Action stop: Action {
                    icon.name: "media-playback-stop"
                    onTriggered: {
                        player.execCmd({zonendx: zonendx, cmd: 'Stop'})
                        // Minimize if playing a video
                        if (zones.get(zonendx).track.mediatype === 'Video') {
                            player.execCmd({delay: 500
                                          , cmdType: McwsConnection.CmdType.MCC
                                          , cmd: player.cmd_MCC_Minimize})
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
                        icon.name: 'media-repeat-single'
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

                // Update
                function formatTrackDisplay(mediatype, obj) {
                    if (obj.playingnowtracks === 0 || obj.filekey === -1) {
                        obj.name = obj.zonename
                        obj.artist = obj.album = player.str_EmptyPlaylist
                        return player.str_EmptyPlaylist
                    }

                    return mediatype === undefined || mediatype === 'Audio'
                            ? '<b>%1</b><br>%2<br>%3'.arg(obj.name).arg(obj.artist).arg(obj.album)
                            : obj.name
                }
                function update() {
                    var needAudioPath = false
                    var zone = zones.get(zonendx)
                    // get the info obj
                    reader.loadObject("Playback/Info?zone=" + zone.zoneid, (obj) => {
                        // FIXME:
                        // Work-around MCWS bug with zonename missing when connected to another connected server
                        if (!obj.hasOwnProperty('zonename'))
                            obj.zonename = zone.zonename
                        // Artist and album can be missing
                        if (!obj.hasOwnProperty('artist'))
                            obj.artist = '<unknown>'
                        if (!obj.hasOwnProperty('album'))
                            obj.album = '<unknown>'

                        // Explicit playingnowchangecounter signal
                        if (obj.playingnowchangecounter !== zone.playingnowchangecounter) {
                            pnChangeCtrChanged(zonendx, obj.playingnowchangecounter)
                            zone.trackList.load()
                        }

                        // Explicit track change signal and track display update
                        // Web streams are checked every tick, unless there is a filekey change
                        if (obj.filekey !== zone.filekey) {
                            zone.filekey = obj.filekey
                            if (obj.filekey !== -1) {
                                getTrackDetails(obj.filekey, (ti) => {
                                    zone.track = ti
                                    zone.trackdisplay = formatTrackDisplay(ti.mediatype, obj)
                                    debugLogger(zone, 'getTrackDetails(%1)'.arg(obj.filekey))

                                    if (ti.hasOwnProperty('webmediainfo'))
                                        debugLogger(obj, 'Switching to WebStream: ' + ti.name)
                                })

                                if (obj.state === PlayerState.Playing)
                                    needAudioPath = true
                            } else {
                                zone.trackdisplay = formatTrackDisplay('', obj)
                                zone.audiopath = ''
                                Utils.simpleClear(zone.track)
                            }
                            trackKeyChanged(zonendx, zone.filekey)
                        } else {
                            // HACK: web media streaming, explicit trackKeyChanged()
                            // Check every tick as MC track will not change, but streaming
                            // track might change
                            if (zone.track.hasOwnProperty('webmediainfo')) {
                                // SomaFM does not send album
                                if (zone.track.webmediainfo.includes('soma'))
                                    obj.album = zone.track.name

                                // With Playback/Info, filekey does not change for stream source
                                // when track changes.  Use trackdisplay to determine if changed.
                                var tmp = formatTrackDisplay(zone.track.mediatype, obj)
                                if (tmp !== zone.trackdisplay) {
                                    zone.trackdisplay = tmp
                                    trackKeyChanged(zonendx, obj.filekey)
                                    if (obj.state === PlayerState.Playing)
                                        needAudioPath = true
                                    debugLogger(obj, 'Setting WebStream TrackDisplay(%1/%2)'
                                                .arg(zone.trackdisplay)
                                                .arg(obj.filekey))
                                }
                            } else {
                                // No track change and not web stream
                                // MC can be slow between songs for various reasons (links, format, etc.)
                                // Set the track display
                                zone.trackdisplay = formatTrackDisplay(zone.track.mediatype, obj)
                            }
                        }

                        // Next file info
                        if (obj.nextfilekey !== zone.nextfilekey) {
                            if (obj.nextfilekey === -1)
                                zone.nexttrackdisplay = 'End of Playlist'
                            else {
                                // wait a bit for the tracklist to load
                                event.queueCall(1000, () =>
                                {
                                    if (zone.trackList.items.count !== 0) {
                                        var pos = obj.playingnowposition + 1
                                        if (pos !== obj.playingnowtracks) {
                                            var o = zone.trackList.items.get(pos)
                                            zone.nexttrackdisplay = 'Next up:<br>' + formatTrackDisplay(o.mediatype, o)
                                            debugLogger(zone, 'Setting next track display(%1)'.arg(obj.nextfilekey))
                                        }
                                        else
                                            zone.nexttrackdisplay = 'End of Playlist'
                                    } else {
                                        zone.nexttrackdisplay = 'Playlist Empty'
                                    }
                                })
                            }
                        }

                        // Explicit playingnowposition signal
                        if (obj.playingnowposition !== zone.playingnowposition) {
                            pnPositionChanged(zonendx, obj.playingnowposition)
                        }

                        // Explicit Playback state signal (update audio path)
                        if (obj.state !== zone.state) {
                            pnStateChanged(zonendx, obj.state)
                            if (obj.state === PlayerState.Playing)
                                needAudioPath = true
                        }

                        // linkedzones is a transient field
                        if (obj.hasOwnProperty('linkedzones'))
                            zone.linked = true
                        else {
                            zone.linked = false
                            zone.linkedzones = ''
                        }

                        zone.mute = obj.volumedisplay === "Muted" ? true : false
                        if (typeof obj.name === 'number')
                            zone.name = obj.name.toString()
                        zones.set(zonendx, obj)

                        // Audio Path
                        if (needAudioPath) {
                            getAudioPath()
                        }
                    })
                }

                function playTrack(pos) {
                    player.execCmd({zonendx: zonendx
                                    , cmd: "PlaybyIndex?Index="
                                           + zones.get(zonendx).trackList.items.mapRowToSource(pos)})
                }
                function playTrackByKey(filekey) {
                    player.execCmd({zonendx: zonendx
                                    , cmd: 'PlaybyKey?Location=Next&Key=' + filekey})
                    if (zones.get(zonendx).state === PlayerState.Playing)
                        player.execCmd({zonendx: zonendx
                                        , cmd: 'Next'
                                        , delay: 1000})
                }
                function playAlbum(filekey) {
                    player.execCmd({zonendx: zonendx, cmd: "PlaybyKey?Album=1&Key=" + filekey})
                }
                function queueAlbum(filekey, next) {
                    player.execCmd({zonendx: zonendx
                                    , cmd: 'PlaybyKey?Key=%1&Album=1&Location=%2'
                                            .arg(filekey)
                                            .arg(next === undefined || next ? "Next" : "End")
                                    })
                }

                // Search
                function searchAndPlayNow(srch, shuffleMode) {
                    player.execCmd({zonendx: zonendx
                                      , cmdType: McwsConnection.CmdType.Search
                                      , cmd: "Action=Play&query=" + srch
                                        + (shuffleMode === undefined || shuffleMode ? "&Shuffle=1" : "")
                                    })
                }
                function searchAndAdd(srch, next, shuffleMode) {
                    player.execCmd({zonendx: zonendx
                                    , cmdType: McwsConnection.CmdType.Search
                                    , forceRefresh: false
                                    , cmd: 'Action=Play&query=' + srch
                                           + '&PlayMode=' + (next === undefined || next ? "NextToPlay" : "Add")
                                   })
                    if (shuffleMode === undefined || shuffleMode)
                        player.execCmd({zonendx: zonendx
                                        , cmd: 'Shuffle?Mode=reshuffle'
                                        , delay: 750})
                }
                function addTrack(filekey, next) {
                    searchAndAdd("[key]=" + filekey, next, false)
                }
                function removeTrack(trackndx) {
                    let ndx = zones.get(zonendx).trackList.removeItem(trackndx)
                    if (ndx !== -1)
                        player.execCmd({forceRefresh: false
                                        , zonendx: zonendx
                                        , cmd: "EditPlaylist?Action=Remove&Source=" + ndx})
                }

                // Playlists
                function playPlaylist(id, shuffleMode) {
                    player.execCmd({zonendx: zonendx,
                                 cmdType: McwsConnection.CmdType.Playlists,
                                 cmd: "Action=Play&Playlist=" + id
                                      + (shuffleMode === undefined || shuffleMode ? "&Shuffle=1" : "")
                                })
                }
                function addPlaylist(id, shuffleMode) {

                    player.execCmd({zonendx: zonendx
                                    , cmdType: McwsConnection.CmdType.Playlists
                                    , forceRefresh: false
                                    , cmd: 'Action=Play&PlayMode=Add&Playlist=' + id
                                   })
                    if (shuffleMode === undefined || shuffleMode)
                        player.execCmd({zonendx: zonendx
                                        , cmd: 'Shuffle?Mode=reshuffle'
                                        , delay: 750})
                }

                // Audio Devices
                function getAudioDevice(callback) {
                    reader.loadObject("Configuration/Audio/GetDevice?Zone=" + zones.get(zonendx).zoneid
                                    , (dev) => {
                                      currentAudioDevice = dev.deviceindex
                                      if (Utils.isFunction(callback))
                                            callback(currentAudioDevice)
                                    })
                }
                function setAudioDevice(devndx) {
                    player.execCmd({ zonendx: zonendx
                                     , cmdType: McwsConnection.CmdType.Unused
                                     , cmd: 'Configuration/Audio/SetDevice?DeviceIndex=' + devndx
                                     })
                    currentAudioDevice = devndx
                }
                function getAudioPath(delay, cb) {
                    if (delay === undefined)
                        delay = 1000

                    event.queueCall(delay,
                                    () => {
                                        var zone = zoneModel.get(zonendx)
                                        reader.loadObject( "Playback/AudioPath?Zone=" + zone.zoneid
                                         , (ap) => {
                                             zone.audiopath = ap.audiopath !== undefined
                                                                 ? ap.audiopath.replace(/;/g, '\n')
                                                                 : ''

                                             currentEq = zone.audiopath.toLowerCase().includes('equalizer')

                                             if (Utils.isFunction(cb))
                                                 cb(ap)

                                             debugLogger(zone, 'getAudioPath(delay=%1):\n'.arg(delay) + zone.audiopath)
                                        })
                                    })
                }

                // Misc
                function setCurrent() {
                    player.execCmd({cmdType: McwsConnection.CmdType.MCC
                                    , forceRefresh: false
                                    , cmd: player.cmd_MCC_SetZone + zonendx})
                }
                function setUIMode(mode) {
                    player.execCmd({cmdType: McwsConnection.CmdType.MCC
                                       , delay: 500
                                       , forceRefresh: false
                                       , cmd: player.cmd_MCC_UIMode
                                              + (mode === undefined ? McwsConnection.UiMode.Standard : mode)})
                }
                function playURL(url) {
                    setCurrent()
                    player.execCmd({cmdType: McwsConnection.CmdType.MCC
                                       , delay: 500
                                       , forceRefresh: false
                                       , cmd: player.cmd_MCC_OpenURL})
                }

                // Zone Linking
                function unLinkZone() {
                    player.execCmd({zonendx: zonendx, cmd: 'UnlinkZones'})
                }
                function linkZone(zone2id) {
                    player.execCmd("Playback/LinkZones?Zone1="
                                   + zones.get(zonendx).zoneid + "&Zone2=" + zone2id)
                }

                // Volume
                function setMute( mute) {
                    player.execCmd({zonendx: zonendx
                                    , cmd: "Mute?Set="
                                           + (mute === undefined ? "1" : mute ? "1" : "0")})
                }
                function setVolume(level) {
                    player.execCmd({zonendx: zonendx, cmd: "Volume?Level=" + level})
                }
                function setPlayingPosition(pos) {
                    player.execCmd({zonendx: zonendx, cmd: "Position?Position=" + pos})
                }

                // Shuffle/Repeat
                function getRepeatMode(callback) {
                    reader.loadObject("Playback/Repeat?Zone=" + zones.get(zonendx).zoneid,
                                      (repeat) =>
                                      {
                                          currentRepeat = repeat.mode
                                          if (Utils.isFunction(callback))
                                            callback(currentRepeat)
                                      })
                }
                function setRepeat(mode) {
                    player.execCmd({zonendx: zonendx, cmd: "Repeat?Mode=" + mode})
                }
                function getShuffleMode(callback) {
                    reader.loadObject("Playback/Shuffle?Zone=" + zones.get(zonendx).zoneid,
                                      (shuffle) =>
                                      {
                                          currentShuffle = shuffle.mode
                                          if (Utils.isFunction(callback))
                                              callback(currentShuffle)
                                      })
                }
                function setShuffle(mode) {
                    player.execCmd({zonendx: zonendx, cmd: "Shuffle?Mode=" + mode})
                }

                // DSP
                function setDSP(dsp, enabled) {
                    player.execCmd({ zonendx: zonendx, cmd: 'Set?DSP=%1&On='.arg(dsp)
                                     + (enabled === undefined || enabled ? '1' : '0')
                                     , cmdType: McwsConnection.CmdType.DSP })
                }
                function loadDSPPreset(preset) {
                    player.execCmd({ zonendx: zonendx, cmd: 'LoadDSPPreset&Name=' + preset })
                }
                function setLoudness(enabled) {
                    player.execCmd({ zonendx: zonendx, cmd: 'Loudness?Set='
                                     + (enabled === undefined || enabled ? '1' : '0')
                                     , cmdType: McwsConnection.CmdType.DSP })
                }
                function getLoudness(callback) {
                    reader.loadObject("DSP/Loudness?Zone=" + zones.get(zonendx).zoneid,
                                      (result) =>
                                      {
                                          currentLoudness = result.current === 1
                                          if (Utils.isFunction(callback))
                                              callback(currentLoudness)
                                      })
                }
            }
        }
        // Zones model for the connection
        BaseListModel { id: zones }
    } // player

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
        onTriggered: player.execCmd('Playback/StopAll')
    }

    // Force close the connection, clear structs
    function closeConnection() {
        hostConfig = {}
    }

    // Reset (reload) the connection if connected
    function reset() {
        if (isConnected) {
            var h = host
            host = ''
            event.queueCall(500, () => { host = h })
        }
    }

    // Set list of file keys from items (track list)
    // to the destination zone and optionally play
    function sendListToZone(items, destIndex, playNow) {
        var arr = []
        items.forEach((track) => { arr.push(track.key) })
        player.execCmd({ zonendx: destIndex
                         , cmd: 'SetPlaylist?Playlist=2;%1;0;%2'.arg(arr.length).arg(arr.join(';')) })

        if (playNow === undefined || playNow)
            event.queueCall(750, zones.get(destIndex).player.play)
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
        return zones.filter((zone) => { return zone.state === state })
    }

    // Misc
    function importPath(path) {
        player.execCmd({cmdType: McwsConnection.CmdType.Unused
                          , cmd: 'Library/Import?Block=0&Path=' + path})
    }
    function getTrackDetails(filekey, cb, fieldlist) {
        if (!Utils.isFunction(cb))
            return

        if (filekey === -1)
            cb({})
        else {
            fieldlist = fieldlist === undefined || fieldlist.length === 0
                    ? 'NoLocalFileNames=1'
                    : 'Fields=' + fieldlist.join(',')
            // LoadJSON returns a list of objects, we just want the first (only) one here
            reader.loadJSON('File/GetInfo?%1&action=JSON&file='.arg(fieldlist) + filekey
                              , (list) => { cb(list[0]) })
        }
    }

    SingleShot { id: event }

    Reader {
        id: reader

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

    Playlists {
        id: playlists
        comms: reader
        trackModel.mcwsFields: mcwsFieldsModel
    }

    LookupValues {
        id: lookup
        hostUrl: reader.hostUrl
    }

    Timer {
        id: connPoller
        repeat: true
        triggeredOnStart: true

        // non-playing tick ctr
        property int updateCtr: 0
        property int zoneCheckCtr: 0

        onTriggered: {
            // update non-playing zones every 5 ticks, playing zones, every tick
            if (++updateCtr === 5) {
                updateCtr = 0
            }
            zones.forEach((zone) =>
            {
                if (zone.state === PlayerState.Playing || zone.state === PlayerState.Paused) {
                    zone.player.update()
                }
                else if (updateCtr === 0) {
                    event.queueCall(zone.player.update)
                }
            })
            // check to see if the playback zones have changed
            if (++zoneCheckCtr === 100) {
                zoneCheckCtr = 0
                player.checkZoneCount(reset)
            }
        }

        onIntervalChanged: {
            updateCtr = 0
            zoneCheckCtr = 0
            restart()
        }
    }
}
