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

    property alias host: reader.currentHost
    property alias pollerInterval: connPoller.interval

    property bool videoFullScreen: false
    property int thumbSize: 32

    // Setting the host initiates a connection attempt
    // null means close/reset, otherwise, attempt connect
    onHostChanged: {
        if (host !== '')
            connectionStart(host)
        else
            connectionStopped()

        connPoller.stop()
        zones.forEach(function(zone) {
            zone.trackList.clear()
            zone.trackList.destroy()
        })
        zones.clear()
        playlists.currentIndex = -1
        player.imageErrorKeys = {'-1': 1}

        if (host !== '')
            player.load()
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
            player.createCmd({ zonendx: zonendx
                             , cmdType: CmdType.Unused
                             , cmd: 'Configuration/Audio/SetDevice?DeviceIndex=' + devndx
                             })
        }
    }

    // Player, controls/manages all playback zones
    // each mcws zone is an object in the "zones" list model
    // each "zone" obj is a "Playback/Info" object with a track list
    // (current playing list) and a track object (current track)
    Item {
        id: player

        property bool checkForZoneChange: plasmoid.configuration.checkZoneChange

        property var imageErrorKeys: ({})
        property var defaultFields: []

        readonly property string thumbQuery: reader.hostUrl + 'File/GetImage?width=%1&height=%1&file='
        readonly property string cmd_MCC:           'Control/MCC?Command='
        readonly property string cmd_MCC_SetZone:   '10011&Parameter='
        readonly property string cmd_MCC_UIMode:    '22009&Parameter='
        readonly property string cmd_MCC_Minimize:  '10014'
        readonly property string cmd_MCC_Maximize:  '10027'
        readonly property string cmd_MCC_Detach:    '10037'
        readonly property string cmd_MCC_OpenURL:   '20001'
        readonly property string cmd_MCC_OpenLive:  '20035'

        readonly property string str_EmptyPlaylist: '<empty playlist>'

        property var xhr

        function createCmd(parms, immediate) {
            if (parms === undefined || parms === '') {
                console.log('Invalid parameter: requires string or object type')
                return null
            }
            var obj = { zonendx: -1
                        , cmd: ''
                        , delay: 0
                        , cmdType: CmdType.Playback
                        , debug: false
                      }
            // single cmd string, assume a complete cmd with zone constraint
            if (typeof parms === 'string') {
                obj.cmd = parms
            }
            // otherwise, set defaults, construct final cmd obj
            else if (typeof parms === 'object') {

                obj = Object.assign({}, obj, parms)

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
                        obj.cmd = cmd_MCC + obj.cmd
                        break
                    case CmdType.DSP:
                        obj.cmd = 'DSP/' + obj.cmd
                }

                // Set zone constraint
                if (obj.zonendx >= 0 && obj.zonendx !== null) {

                    obj.cmd += (obj.cmd.indexOf('?') === -1 ? '?' : '&')
                                + 'Zone=' + zones.get(obj.zonendx).zoneid
                }
            }

            if (obj.debug) {
                console.log('')
                for (var i in obj)
                    console.log(i + ': ' + obj[i])

                if (obj.zonendx !== -1) {
                    var z = zones.get(obj.zonendx)
                    console.log('')
                    console.log('======>Target Zone: ' + z.zonename)
                    for (i in z)
                        console.log(i + ': ' + z[i])
                }
                else
                    console.log('GLOBAL ZONE')

            }

            if (immediate === undefined || immediate)
                run([obj])

            return obj
        }
        function run(cmdArray) {

            if (typeof cmdArray !== 'object' || cmdArray.length === 0) {
                console.log('Invalid command list: requires array of objects')
                return
            }
            if (xhr === undefined) {
                xhr = new XMLHttpRequest()
            }

            cmdArray.forEach(function(obj) {
                event.queueCall(obj.delay, function() {
                    xhr.open("GET", reader.hostUrl + obj.cmd);
                    xhr.send();
                })
            })

            var zonendx = cmdArray[0].zonendx
            if (zonendx >= 0 && cmdArray.length === 1) {
                event.queueCall(cmdArray[0].delay + 250, player.updateZone, [zonendx])
            }
        }

        function formatTrackDisplay(mediatype, obj) {
            if (obj.playingnowtracks === 0 ) {
                obj.name = obj.zonename
                obj.artist = obj.album = str_EmptyPlaylist
                return str_EmptyPlaylist
            }

            return mediatype === 'Audio'
                    ? "'%1'\n from '%2'\n by %3".arg(obj.name).arg(obj.album).arg(obj.artist)
                    : obj.name
        }
        function loadAudioPath(zone) {
            reader.loadObject("Playback/AudioPath?Zone=" + zone.zoneid, function(ap)
            {
                zone.audiopath = ap.audiopath !== undefined
                                    ? ap.audiopath.replace(/;/g, '\n')
                                    : ''
            })
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
                    zones.append({ zoneid: data["zoneid"+i]
                                   , zonename: data["zonename"+i]
                                   , name: data["zonename"+i]
                                   , artist: ''
                                   , album: ''
                                   , state: PlayerState.Stopped
                                   , linked: false
                                   , mute: false
                                   , trackdisplay: ''
                                   , nexttrackdisplay: ''
                                   , audiopath: ''
                                   , nextfilekey: -1
                                   , trackList:
                                        tl.createObject(root, { searchCmd: 'Playback/Playlist?Zone=' + data['zoneid'+i] })
                                   , track: {}
                                   })
                    updateZone(i)
                }
                connPoller.start()
                event.queueCall(300, connectionReady, [-1])
            })
        }

        function updateZone(zonendx) {
            var zone = zones.get(zonendx)
            // reset MCWS transient fields
            zone.linkedzones = ''
            // get the info obj
            reader.loadObject("Playback/Info?zone=" + zone.zoneid, function(obj)
            {
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
                            trackKeyChanged(obj)
                        })
                    } else {
                        zone.track = {}
                        trackKeyChanged(obj)
                    }
                    // Audio Path
                    if (obj.state === PlayerState.Playing) {
                        event.queueCall(1000, loadAudioPath, [zone])
                    }
                }

                // Next file info
                if (obj.nextfilekey !== zone.nextfilekey) {
                    if (obj.nextfilekey === -1)
                        zone.nexttrackdisplay = 'End of Playlist'
                    else {
                        event.queueCall(1000, function()
                        {
//                            console.log(zone.trackList.items.count + ', Pos: ' + obj.playingnowposition
//                                        + ' NFK: ' + zone.zoneid + zone.zonename + ', ' + obj.nextfilekey)
                            if (zone.trackList.items.count !== 0) {
                                var pos = obj.playingnowposition + 1
                                if (pos !== obj.playingnowtracks) {
                                    var o = zone.trackList.items.get(pos)
                                    zone.nexttrackdisplay = 'Next up:\n' + formatTrackDisplay(o.mediatype, o)
                                }
                                else
                                    zone.nexttrackdisplay = 'End of Playlist'
                            } else {
                                zone.nexttrackdisplay = 'Playlist Empty'
//                                getTrackDetails(obj.nextfilekey, function(o) {
//                                    zone.nexttrackdisplay = 'Next up:\n' + formatTrackDisplay(o.mediatype, o)
//                                }, zone.trackList.mcwsFieldList)
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
                        event.queueCall(1000, loadAudioPath, [zone])
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

                    // On GetInfo changes, filekey does not change for stream source
                    var tmp = formatTrackDisplay(zone.track.mediatype, obj)
                    if (tmp !== zone.trackdisplay) {
                        zone.trackdisplay = tmp
                        trackKeyChanged(obj)
                    }
                } else {
                    zone.trackdisplay = formatTrackDisplay(zone.track.mediatype, obj)
                }


                zone.linked = obj.hasOwnProperty('linkedzones') ? true : false
                zone.mute   = obj.volumedisplay === "Muted" ? true : false
                zones.set(zonendx, obj)
            })
        }

        Component {
            id: tl
            Searcher {
                comms: reader
                mcwsFields: defaultFields()
            }
        }

        BaseListModel { id: zones }
    }

    signal connectionStart(var host)
    signal connectionStopped()
    signal connectionReady(var zonendx)
    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)
    signal trackKeyChanged(var zone)
    signal pnPositionChanged(var zonendx, var pos)
    signal pnChangeCtrChanged(var zonendx, var ctr)
    signal pnStateChanged(var zonendx, var playerState)

    function getInfo(callback) {
        reader.loadObject("Alive", callback)
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

    function sendListToZone(items, srcIndex, destIndex, playNow) {
        var arr = []
        items.forEach(function(track) { arr.push(track.key) })
        player.createCmd({ zonendx: destIndex
                         , cmd: 'SetPlaylist?Playlist=2;%1;0;%2'.arg(arr.length).arg(arr.join(';')) })

        if (playNow === undefined || playNow)
            event.queueCall(500, play, [destIndex])
    }

    // Reset the connection, forces a re-load from MCWS.
    function reset() {
        if (isConnected) {
            var h = host
            host = ''
            event.queueCall(500, function() { host = h })
        }
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
        return zones.filter(function(zone)
        {
            return zone.state === state
        })
    }

    function imageUrl(filekey, size) {
        return !player.imageErrorKeys[filekey]
                ? player.thumbQuery.arg((size === undefined || size === 0 ||  size === null) ? thumbSize : size) + filekey
                : 'default.png'
    }
    function setImageError(filekey) {
        player.imageErrorKeys[filekey] = 1
    }

    function play(zonendx) {
        if (zones.get(zonendx).track.mediatype !== 'Audio') {
            if (zones.get(zonendx).state === PlayerState.Stopped) {
                if (videoFullScreen)
                    setUIMode(zonendx, UiMode.Display)
                else
                    setCurrentZone(zonendx)
            }
        }

        player.createCmd({zonendx: zonendx, cmd: 'PlayPause'})
    }

    function previous(zonendx) {
        player.createCmd({zonendx: zonendx, cmd: 'Previous'})
    }
    function next(zonendx) {
        player.createCmd({zonendx: zonendx, cmd: 'Next'})
    }
    function stop(zonendx) {
        if (zones.get(zonendx).track.mediatype !== 'Audio') {
            player.createCmd({zonendx: zonendx, cmd: 'Stop'})
            player.createCmd({delay: 500, cmdType: CmdType.MCC, cmd: player.cmd_MCC_Minimize})
        }
        else
            player.createCmd({zonendx: zonendx, cmd: 'Stop'})
    }
    function stopAllZones() {
        player.createCmd('Playback/StopAll')
    }

    function setCurrentZone(zonendx) {
        player.createCmd({cmdType: CmdType.MCC
                            , cmd: player.cmd_MCC_SetZone + zonendx})
    }
    function setUIMode(zonendx, mode) {
        setCurrentZone(zonendx)
        player.createCmd({cmdType: CmdType.MCC
                           , delay: 500
                           , cmd: player.cmd_MCC_UIMode + (mode === undefined ? UiMode.Standard : mode)})
    }

    function playURL(zonendx, url) {
        setCurrentZone(zonendx)
        player.createCmd({cmdType: CmdType.MCC
                           , delay: 500
                           , cmd: player.cmd_MCC_OpenURL})
    }
    function importPath(path) {
        player.createCmd({cmdType: CmdType.Unused
                          , cmd: 'Library/Import?Block=0&Path=' + path})
    }

    function unLinkZone(zonendx) {
        player.createCmd({zonendx: zonendx, cmd: 'UnlinkZones'})
    }
    function linkZones(zone1id, zone2id) {
        player.createCmd("Playback/LinkZones?Zone1=" + zone1id + "&Zone2=" + zone2id)
    }

    function isPlaylistEmpty(zonendx) {
        return zones.get(zonendx).playingnowtracks === '0'
    }

    function setMute(zonendx, mute) {
        player.createCmd({zonendx: zonendx, cmd: "Mute?Set=" + (mute === undefined ? "1" : mute ? "1" : "0")})
    }
    function setVolume(zonendx, level) {
        player.createCmd({zonendx: zonendx, cmd: "Volume?Level=" + level})
    }

    function setPlayingPosition(zonendx, pos) {
        player.createCmd({zonendx: zonendx, cmd: "Position?Position=" + pos})
    }

    // Shuffle/Repeat
    function getRepeatMode(zonendx, callback) {
        reader.loadObject("Playback/Repeat?Zone=" + zones.get(zonendx).zoneid, callback)
    }
    function setRepeat(zonendx, mode) {
        player.createCmd({zonendx: zonendx, cmd: "Repeat?Mode=" + mode})
    }
    function getShuffleMode(zonendx, callback) {
        reader.loadObject("Playback/Shuffle?Zone=" + zones.get(zonendx).zoneid, callback)
    }
    function setShuffle(zonendx, mode) {
        player.createCmd({zonendx: zonendx, cmd: "Shuffle?Mode=" + mode})
    }

    function removeTrack(zonendx, trackndx) {
        player.createCmd({zonendx: zonendx, cmd: "EditPlaylist?Action=Remove&Source=" + trackndx})
    }
    function clearPlayingNow(zonendx) {
        player.createCmd({zonendx: zonendx, cmd: "ClearPlaylist"})
    }
    function playTrack(zonendx, pos) {
        player.createCmd({zonendx: zonendx, cmd: "PlaybyIndex?Index=" + pos})
    }
    function playTrackByKey(zonendx, filekey) {

        var cmdList = [player.createCmd({zonendx: zonendx, cmd: 'PlaybyKey?Location=Next&Key=' + filekey}, false)]
        if (zones.get(zonendx).state === PlayerState.Playing)
            cmdList.push(player.createCmd({zonendx: zonendx, cmd: 'Next', delay: 1000}, false))

        player.run(cmdList)
    }
    function addTrack(zonendx, filekey, next) {
        searchAndAdd(zonendx, "[key]=" + filekey, next, false)
    }

    function queueAlbum(zonendx, filekey, next) {
        player.createCmd({zonendx: zonendx,
                              cmd: 'PlaybyKey?Key=' + filekey
                                  + '&Album=1&Location=' + (next === undefined || next ? "Next" : "End")
                        })
    }
    function playAlbum(zonendx, filekey) {
        player.createCmd({zonendx: zonendx, cmd: "PlaybyKey?Album=1&Key=" + filekey})
    }
    function searchAndPlayNow(zonendx, srch, shuffleMode) {
        player.createCmd({zonendx: zonendx,
                         cmdType: CmdType.Search,
                         cmd: "Action=Play&query=" + srch
                            + (shuffleMode === undefined || shuffleMode ? "&Shuffle=1" : "")
                        })
    }
    function searchAndAdd(zonendx, srch, next, shuffleMode) {

        var cmdlist = [player.createCmd({zonendx: zonendx,
                                    cmdType: CmdType.Search,
                                    cmd: 'Action=Play&query=' + srch
                                        + '&PlayMode=' + (next === undefined || next ? "NextToPlay" : "Add")
                                   })]
        if (shuffleMode === undefined || shuffleMode)
            cmdlist.push(player.createCmd({zonendx: zonendx, cmd: 'Shuffle?Mode=reshuffle', delay: 750}))

        player.run([cmdlist])
    }

    function getTrackDetails(filekey, cb, fieldlist) {
        if (!Utils.isFunction(cb))
            return

        if (filekey === -1)
            cb({})
        else {
            var fieldstr = fieldlist === undefined || fieldlist.length === 0 ? 'NoLocalFileNames=1' : 'Fields=' + fieldlist.join(',')
            // For MPL query, loadObject returns a list of objects, so in this case, a list of one obj
            reader.loadObject('File/GetInfo?%1&file='.arg(fieldstr) + filekey, function(list)
            {
                cb(list[0])
            })
        }

    }

    function setEqualizer(zonendx, enabled) {
        setDSP(zonendx, 'Equalizer', enabled)
    }
    function setDSP(zonendx, dsp, enabled) {
        player.createCmd({ zonendx: zonendx, cmd: 'Set?DSP=%1&On='.arg(dsp)
                         + (enabled === true || enabled === undefined ? '1' : '0')
                         , cmdType: CmdType.DSP })
    }
    function loadDSPPreset(zonendx, preset) {
        player.createCmd({ zonendx: zonendx, cmd: 'LoadDSPPreset&Name=' + preset })
    }

    SingleShot { id: event }

    Reader {
        id: reader
        onConnectionError: {
            console.log('<Connection Error> ' + msg + ' ' + cmd)
            root.connectionError(msg, cmd)
            // if the error occurs with the current host, close/reset
            if (cmd.indexOf(currentHost) !== -1)
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

        function play(zonendx, plid, shuffleMode) {
            player.createCmd({zonendx: zonendx,
                         cmdType: CmdType.Playlists,
                         cmd: "Action=Play&Playlist=" + plid
                              + (shuffleMode === undefined || shuffleMode ? "&Shuffle=1" : "")
                        })
        }
        function add(zonendx, plid, shuffleMode) {

            var cmdList = [player.createCmd(
                               {zonendx: zonendx,
                                cmdType: CmdType.Playlists,
                                cmd: 'Action=Play&PlayMode=Add&Playlist=' + plid,
                                })]
            if (shuffleMode === undefined || shuffleMode)
                cmdList.push(player.createCmd({zonendx: zonendx, cmd: 'Shuffle?Mode=reshuffle', delay: 750}))

            player.run([cmdList])
        }
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
            zones.forEach(function(zone, ndx)
            {
                if (zone.state === PlayerState.Playing)
                    player.updateZone(ndx)
                else if (updateCtr === 0) {
                    event.queueCall(0, player.updateZone, [ndx])
                }
            })
            // check to see if the playback zones have changed
            if (++zoneCheckCtr === 60) {
                zoneCheckCtr = 0
                player.checkZoneCount(function(num) {
                    console.log('Zonecount has changed(%1)...resetting... '.arg(num))
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
