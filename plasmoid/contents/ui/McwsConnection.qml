import QtQuick 2.8

import 'helpers'
import 'models'
import 'helpers/utils.js' as Utils

Item {
    id: root

    readonly property bool isConnected: zones.count > 0 & connPoller.running
    readonly property alias zoneModel: zones
    readonly property alias audioDevices: adevs
    readonly property alias playlists: playlists
    readonly property alias comms: reader
    readonly property alias serverInfo: player.serverInfo

    property alias host: reader.currentHost
    property alias pollerInterval: connPoller.interval

    property bool videoFullScreen: false
    property int thumbSize: 32

    signal debugLogger(var obj, var msg)
    signal updateLogger(var obj, var msg)

    // Setting the host initiates a connection attempt
    // null means close/reset, otherwise, attempt connect
    onHostChanged: {
        connPoller.stop()

        // wait for any in-flight refreshing
        event.queueCall(100, function() {
            if (host !== '')
                connectionStart(host)
            else
                connectionStopped()

            zones.forEach(function(zone) {
                zone.trackList.clear()
                zone.trackList.destroy()
                zone.player.destroy()
            })
            zones.clear()
            playlists.currentIndex = -1
            player.imageErrorKeys = {'-1': 1}

            if (host !== '')
                getConnectionInfo(player.load)
        })
    }

    // Audio Devices
    // Will load the list of audio devices on first access to a device
    QtObject {
        id: adevs

        property var items: []

        function load() {
            reader.loadObject("Configuration/Audio/ListDevices", function(data)
            {
                items.length = 0
                for(var i = 0; i<data.numberdevices; ++i) {
                    items.push('%1 (%2)'.arg(data['devicename'+i]).arg(data['deviceplugin'+i]))
                }
            })
        }
        function getDevice(zonendx, callback) {
            var delay = 0
            if (items.length === 0) {
                load()
                delay = 150
            }
            event.queueCall(delay
                            , reader.loadObject
                            , ["Configuration/Audio/GetDevice?Zone=" + zones.get(zonendx).zoneid, callback])
        }
        function setDevice(zonendx, devndx) {
            player.execCmd({ zonendx: zonendx
                             , cmdType: CmdType.Unused
                             , cmd: 'Configuration/Audio/SetDevice?DeviceIndex=' + devndx
                             })
        }
    }

    // Player, controls/manages all playback zones
    // each mcws zone is an object in the "zones" list model
    // each "zone" obj is a "Playback/Info" object with a track list
    // and a playback object for each zone,
    // (current playing list) and a track object (current track)
    Item {
        id: player

        property bool checkForZoneChange: plasmoid.configuration.checkZoneChange

        property var imageErrorKeys: ({})
        property var defaultFields: []
        property var serverInfo: ({})

        readonly property string thumbQuery: reader.hostUrl + 'File/GetImage?width=%1&height=%1&file='
        readonly property string cmd_MCC_SetZone:   '10011&Parameter='
        readonly property string cmd_MCC_UIMode:    '22009&Parameter='
        readonly property string cmd_MCC_Minimize:  '10014'
        readonly property string cmd_MCC_Maximize:  '10027'
        readonly property string cmd_MCC_Detach:    '10037'
        readonly property string cmd_MCC_OpenURL:   '20001'
        readonly property string cmd_MCC_OpenLive:  '20035'
        readonly property string str_EmptyPlaylist: '<empty playlist>'

        property var xhr

        /* Command Obj Defaults

              { zonendx: -1
                , cmd: ''
                , delay: 0
                , cmdType: CmdType.Playback
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
                        , cmdType: CmdType.Playback
                        , forceRefresh: true
                      }

            // single cmd string, assume a complete cmd with zone constraint
            if (typeof parms === 'string') {
                obj.cmd = parms
            // otherwise, set defaults, construct final cmd obj
            } else if (typeof parms === 'object') {

                Object.assign(obj, parms)

                switch (obj.cmdType) {
                    case CmdType.Playback:
                        obj.cmd = 'Playback/' + obj.cmd
                        break
                    case CmdType.Search:
                        obj.cmd = 'Files/Search?' + obj.cmd
                        break
                    case CmdType.Playlists:
                        obj.cmd = 'Playlist/Files?' + obj.cmd
                        break
                    case CmdType.MCC:
                        obj.cmd = 'Control/MCC?Command=' + obj.cmd
                        break
                    case CmdType.DSP:
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
            xhr.open("GET", reader.hostUrl + obj.cmd)
            xhr.send()
            if (obj.forceRefresh && obj.zonendx >= 0)
                event.queueCall(200, zones.get(obj.zonendx).player.update)

            debugLogger(obj.zonendx !== -1 ? zones.get(obj.zonendx) : 'Global'
                        , '_exec(): ' + reader.hostUrl + obj.cmd)
        }
        function _run(cmdArray) {

            if (typeof cmdArray !== 'object' || cmdArray.length === 0) {
                debugLogger('_run()', 'Invalid command list: requires array of objects')
                return false
            }
            if (xhr === undefined) {
                xhr = new XMLHttpRequest()
            }

            cmdArray.forEach(function(cmd) {
                if (cmd.delay <= 0) {
                    _exec(cmd)
                } else {
                    event.queueCall(cmd.delay, function() {
                        _exec(cmd)
                    })
                }

            })

            return true
        }

        function checkZoneCount(callback) {
            if (checkForZoneChange) {
                reader.loadObject("Playback/Zones", function(zlist)
                {
                    if (+zlist.numberzones !== zones.count)
                        callback(+zlist.numberzones)
                })
            }
        }

        // Populate the zones model, each obj is a "Playback/Info" for the mcws zone
        function load() {
            reader.loadObject("Playback/Zones", function(data)
            {
                for(var i=0; i<data.numberzones; ++i) {
                    var z = { zoneid: data["zoneid"+i]
                                   , zonename: data["zonename"+i]
                                   , name: data["zonename"+i]
                                   , artist: ''
                                   , album: ''
                                   , state: PlayerState.Stopped
                                   , playingnowchangecounter: -1
                                   , playingnowposition: -1
                                   , linked: false
                                   , linkedzones: ''
                                   , mute: false
                                   , trackdisplay: ''
                                   , nexttrackdisplay: ''
                                   , audiopath: ''
                                   , filekey: -1
                                   , nextfilekey: -1
                                   , trackList:
                                        tl.createObject(root, { searchCmd: 'Playback/Playlist?Zone=' + data['zoneid'+i] })
                                   , track: {}
                                   , player: zp.createObject(root, { zonendx: i })
                                   }
                    zones.append(z)
                    z.player.update()
                }
                connPoller.start()
                event.queueCall(300, connectionReady, [reader.hostUrl, -1])
                debugLogger('load()', '%1 %2 zones loaded'.arg(host).arg(zones.count))
            })
        }

        // TrackList searcher, one per zone
        Component {
            id: tl
            Searcher {
                comms: reader
                mcwsFields: defaultFields()
                onDebugLogger: root.debugLogger(obj, msg)
            }
        }
        // Zone player, one per zone
        Component {
            id: zp
            QtObject {
                property var zonendx

                function formatTrackDisplay(mediatype, obj) {
                    if (obj.playingnowtracks === 0 ) {
                        obj.name = obj.zonename
                        obj.artist = obj.album = player.str_EmptyPlaylist
                        return player.str_EmptyPlaylist
                    }

                    return mediatype === 'Audio' || mediatype === undefined
                            ? "'%1'\n from '%2'\n by %3".arg(obj.name).arg(obj.album).arg(obj.artist)
                            : obj.name
                }
                // Update
                function update() {
                    var needAudioPath = false
                    var zone = zones.get(zonendx)
                    // get the info obj
                    reader.loadObject("Playback/Info?zone=" + zone.zoneid, function(obj) {
                        // FIXME:
                        // Work-around MCWS bug with zonename missing when connected to another connected server
                        if (!obj.hasOwnProperty('zonename'))
                            obj.zonename = zone.zonename

                        updateLogger(zone, obj)
                        // Explicit playingnowchangecounter signal
                        if (obj.playingnowchangecounter !== zone.playingnowchangecounter) {
                            pnChangeCtrChanged(zonendx, obj.playingnowchangecounter)
                            zone.trackList.load()
                        }

                        // Explicit track change signal and track display update
                        if (obj.filekey !== zone.filekey) {
                            if (obj.filekey !== -1) {
                                getTrackDetails(obj.filekey, function(ti) {
                                    zone.track = ti
                                    debugLogger(zone, 'getTrackDetails(%1)'.arg(obj.filekey))
                                })
                                if (obj.state === PlayerState.Playing)
                                    needAudioPath = true
                            } else {
                                zone.track = {}
                            }
                            trackKeyChanged(obj)
                            if (obj.zonename !== zone.zonename)
                                debugLogger('Zone during trackChange', 'Obj: %1, Zone: %2'
                                            .arg(obj.zonename).arg(zone.zonename))
                        }

                        // Next file info
                        if (obj.nextfilekey !== zone.nextfilekey) {
                            if (obj.nextfilekey === -1)
                                zone.nexttrackdisplay = 'End of Playlist'
                            else {
                                // wait a bit for the tracklist to load
                                event.queueCall(1000, function()
                                {
                                    if (zone.trackList.items.count !== 0) {
                                        var pos = obj.playingnowposition + 1
                                        if (pos !== obj.playingnowtracks) {
                                            var o = zone.trackList.items.get(pos)
                                            zone.nexttrackdisplay = 'Next up:\n' + formatTrackDisplay(o.mediatype, o)
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

                        // Some cases where there are no artist/album fields
                        if (!obj.hasOwnProperty('artist'))
                            obj.artist = ''
                        if (!obj.hasOwnProperty('album'))
                            obj.album = ''

                        // HACK: web media streaming
                        if (zone.track.hasOwnProperty('webmediainfo')) {
                            // SomaFM does not send album
                            if (zone.track.webmediainfo.includes('soma'))
                                obj.album = zone.track.name

                            // With Playback/Info, filekey does not change for stream source when track changes
                            var tmp = formatTrackDisplay(zone.track.mediatype, obj)
                            if (tmp !== zone.trackdisplay) {
                                zone.trackdisplay = tmp
                                trackKeyChanged(obj)
                                if (obj.state === PlayerState.Playing)
                                    needAudioPath = true
                                debugLogger(obj, 'Web source track changed(%1/%2)'
                                            .arg(zone.track.webmediainfo)
                                            .arg(obj.filekey))
                            }
                        } else {
                            zone.trackdisplay = formatTrackDisplay(zone.track.mediatype, obj)
                        }

                        // linkedzones is a transient field
                        if (obj.hasOwnProperty('linkedzones'))
                            zone.linked = true
                        else {
                            zone.linked = false
                            zone.linkedzones = ''
                        }

                        zone.mute = obj.volumedisplay === "Muted" ? true : false
                        zones.set(zonendx, obj)

                        // Audio Path
                        if (needAudioPath) {
                            getAudioPath(zone)
                        }
                    })
                }
                // Playback
                function play() {
                    if (zones.get(zonendx).track.mediatype !== 'Audio') {
                        if (zones.get(zonendx).state === PlayerState.Stopped) {
                            setCurrent()
                            if (videoFullScreen)
                                setUIMode(UiMode.Display)
                        }
                    }

                    player.execCmd({zonendx: zonendx, cmd: 'PlayPause'})
                }
                function previous() {
                    player.execCmd({zonendx: zonendx, cmd: 'Previous'})
                }
                function next() {
                    player.execCmd({zonendx: zonendx, cmd: 'Next'})
                }
                function stop() {
                    player.execCmd({zonendx: zonendx, cmd: 'Stop'})
                    // Minimize if playing a video
                    if (zones.get(zonendx).track.mediatype === 'Video') {
                        player.execCmd({delay: 500
                                      , cmdType: CmdType.MCC
                                      , cmd: player.cmd_MCC_Minimize})
                    }
                }

                function playTrack(pos) {
                    player.execCmd({zonendx: zonendx, cmd: "PlaybyIndex?Index=" + pos})
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
                                      , cmdType: CmdType.Search
                                      , cmd: "Action=Play&query=" + srch
                                        + (shuffleMode === undefined || shuffleMode ? "&Shuffle=1" : "")
                                    })
                }
                function searchAndAdd(srch, next, shuffleMode) {
                    player.execCmd({zonendx: zonendx
                                    , cmdType: CmdType.Search
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
                // Playlists
                function playPlaylist(plid, shuffleMode) {
                    player.execCmd({zonendx: zonendx,
                                 cmdType: CmdType.Playlists,
                                 cmd: "Action=Play&Playlist=" + plid
                                      + (shuffleMode === undefined || shuffleMode ? "&Shuffle=1" : "")
                                })
                }
                function addPlaylist(plid, shuffleMode) {

                    player.execCmd({zonendx: zonendx
                                    , cmdType: CmdType.Playlists
                                    , forceRefresh: false
                                    , cmd: 'Action=Play&PlayMode=Add&Playlist=' + plid
                                   })
                    if (shuffleMode === undefined || shuffleMode)
                        player.execCmd({zonendx: zonendx
                                        , cmd: 'Shuffle?Mode=reshuffle'
                                        , delay: 750})
                }
                // Misc
                function setCurrent() {
                    player.execCmd({cmdType: CmdType.MCC
                                    , forceRefresh: false
                                    , cmd: player.cmd_MCC_SetZone + zonendx})
                }
                function setUIMode(mode) {
                    player.execCmd({cmdType: CmdType.MCC
                                       , delay: 500
                                       , forceRefresh: false
                                       , cmd: player.cmd_MCC_UIMode
                                              + (mode === undefined ? UiMode.Standard : mode)})
                }

                function playURL(url) {
                    setCurrent()
                    player.execCmd({cmdType: CmdType.MCC
                                       , delay: 500
                                       , forceRefresh: false
                                       , cmd: player.cmd_MCC_OpenURL})
                }
                function getAudioPath(zone, delay, cb) {
                    if (delay === undefined)
                        delay = 1000

                    event.queueCall(delay, reader.loadObject,
                                    ["Playback/AudioPath?Zone=" + zone.zoneid
                                     , function(ap) {
                                         zone.audiopath = ap.audiopath !== undefined
                                                             ? ap.audiopath.replace(/;/g, '\n')
                                                             : ''
                                         if (Utils.isFunction(cb))
                                             cb(ap)

                                         debugLogger(zone, 'getAudioPath(delay=%1):\n'.arg(delay) + zone.audiopath)
                                     }])
                }

                function unLinkZone() {
                    player.execCmd({zonendx: zonendx, cmd: 'UnlinkZones'})
                }
                function linkZone(zone2id) {
                    player.execCmd("Playback/LinkZones?Zone1="
                                   + zones.get(zonendx).zoneid + "&Zone2=" + zone2id)
                }

                function isPlaylistEmpty() {
                    return zones.get(zonendx).playingnowtracks === 0
                }
                function removeTrack(trackndx) {
                    player.execCmd({zonendx: zonendx, cmd: "EditPlaylist?Action=Remove&Source=" + trackndx})
                }
                function clearPlayingNow() {
                    player.execCmd({zonendx: zonendx, cmd: "ClearPlaylist"})
                    zones.get(zonendx).trackList.clear()
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
                    reader.loadObject("Playback/Repeat?Zone=" + zones.get(zonendx).zoneid, callback)
                }
                function setRepeat(mode) {
                    player.execCmd({zonendx: zonendx, cmd: "Repeat?Mode=" + mode})
                }
                function getShuffleMode( callback) {
                    reader.loadObject("Playback/Shuffle?Zone=" + zones.get(zonendx).zoneid, callback)
                }
                function setShuffle(mode) {
                    player.execCmd({zonendx: zonendx, cmd: "Shuffle?Mode=" + mode})
                }
                // DSP
                function setEqualizer(enabled) {
                    setDSP('Equalizer', enabled)
                }
                function setDSP(dsp, enabled) {
                    player.execCmd({ zonendx: zonendx, cmd: 'Set?DSP=%1&On='.arg(dsp)
                                     + (enabled === undefined || enabled ? '1' : '0')
                                     , cmdType: CmdType.DSP })
                }
                function loadDSPPreset(preset) {
                    player.execCmd({ zonendx: zonendx, cmd: 'LoadDSPPreset&Name=' + preset })
                }
            }
        }
        // Zones model for the connection
        BaseListModel {
            id: zones
            // Each zone.player stores it's model index,
            // so when removed, the indicies are updated based on the model
            onRowsRemoved: {
                zones.forEach(function(zone, ndx) {
                    zone.player.zonendx = ndx
                })
            }
        }
    } // player

    signal connectionStart(var host)
    signal connectionStopped()
    signal connectionReady(var host, var zonendx)
    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)
    signal trackKeyChanged(var zone)
    signal pnPositionChanged(var zonendx, var pos)
    signal pnChangeCtrChanged(var zonendx, var ctr)
    signal pnStateChanged(var zonendx, var playerState)

    function getConnectionInfo(cb) {
        reader.loadObject("Alive", function(obj1) {
            player.serverInfo = obj1
//            reader.loadObject("Authenticate", function(obj2) {
//                Object.assign(player.serverInfo, obj1, obj2)
                if (Utils.isFunction(cb))
                    cb(serverInfo)
//            })
        })
    }

    function setDefaultFields(objStr) {
        try {
            var arr = JSON.parse(objStr)
            if (Array.isArray(arr)) {
                player.defaultFields = arr
                if (isConnected) {
                    reset()
                }
            }
            else
                throw 'Invalid array parameter'
        }
        catch (err) {
            console.log(err)
            console.log('WARNING: MCWS default field setup NOT FOUND.  Search features may not work properly.')
        }
    }

    function defaultFields() {
        return Utils.copy(player.defaultFields)
    }

    function sendListToZone(items, destIndex, playNow) {
        var arr = []
        items.forEach(function(track) { arr.push(track.key) })
        player.execCmd({ zonendx: destIndex
                         , cmd: 'SetPlaylist?Playlist=2;%1;0;%2'.arg(arr.length).arg(arr.join(';')) })

        if (playNow === undefined || playNow)
            event.queueCall(750, zones.get(destIndex).player.play)
    }

    // Reset the connection, forces a re-load from MCWS.
    function reset() {
        if (isConnected) {
            var h = host
            host = ''
            event.queueCall(500, function() { host = h })
        }
    }
    // Remove a zone from the model
    function removeZone(zonendx) {
        var zone = zones.get(zonendx)
        if (zone) {
            zone.trackList.clear()
            zone.trackList.destroy()
            zone.player.destroy()
            zones.remove(zonendx)
            return true
        }
        return false
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
        return zones.filter(function(zone) { return zone.state === state })
    }
    // Track images
    function imageUrl(filekey, size) {
        return !player.imageErrorKeys[filekey]
                ? player.thumbQuery.arg((size === undefined || size === 0 || size === null)
                                            ? thumbSize
                                            : size) + filekey
                : 'default.png'
    }
    function setImageError(filekey) {
        player.imageErrorKeys[filekey] = 1
    }

    function stopAllZones() {
        player.execCmd('Playback/StopAll')
    }

    function importPath(path) {
        player.execCmd({cmdType: CmdType.Unused
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
            // LoadObject returns a list of objects, for MPL, a list of one obj
            reader.loadObject('File/GetInfo?%1&file='.arg(fieldlist) + filekey, function(list)
            {
                cb(list[0])
            })
        }
    }

    SingleShot { id: event }

    Reader {
        id: reader
        onConnectionError: {
            console.log('<Connection Error> ' + msg + ' ' + cmd)
            root.connectionError(msg, cmd)
            // if the error occurs with the current host, close/reset
            if (cmd.includes(currentHost))
                currentHost = ''

        }
        onCommandError: {
            console.log('<Command Error> ' + msg + ' ' + cmd)
            root.commandError(msg, cmd)
        }
    }

    Playlists {
        id: playlists
        comms: reader
        trackModel.mcwsFields: defaultFields()
    }

    Timer {
        id: connPoller; repeat: true

        // non-playing tick ctr
        property int updateCtr: 0
        property int zoneCheckCtr: 0

        onTriggered: {
            // update non-playing zones every 5 ticks, playing zones, every tick
            if (++updateCtr === 5) {
                updateCtr = 0
            }
            zones.forEach(function(zone)
            {
                if (zone.state === PlayerState.Playing || zone.state === PlayerState.Paused) {
                    zone.player.update()
                }
                else if (updateCtr === 0) {
                    event.queueCall(0, zone.player.update)
                }
            })
            // check to see if the playback zones have changed
            if (++zoneCheckCtr === 60) {
                zoneCheckCtr = 0
                player.checkZoneCount(function(num) {
                    reset()
                })
            }
        }

        onIntervalChanged: {
            updateCtr = 0
            zoneCheckCtr = 0
            restart()
        }
    }
}
