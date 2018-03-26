import QtQuick 2.8
import QtQuick.XmlListModel 2.0
import "models"

Item {
    id: conn

    readonly property bool isConnected: player.zoneCount > 0 & (player.zoneCount === zones.count)
    readonly property alias zoneModel: zones
    readonly property alias audioDevices: adevs
    readonly property alias playlists: playlists
    readonly property alias comms: reader

    property alias host: reader.currentHost
    property alias pollerInterval: connPoller.interval

    property bool videoFullScreen: false
    property int thumbSize: 32

    // Player states
    readonly property string stateStopped:      "0"
    readonly property string statePaused:       "1"
    readonly property string statePlaying:      "2"
    readonly property string stateAborting:     "3"
    readonly property string stateBuffering:    "4"

    // UI Modes
    readonly property string ui_MODE_STANDARD:  '0'
    readonly property string ui_MODE_MINI:      '1'
    readonly property string ui_MODE_DISPLAY:   '2'
    readonly property string ui_MODE_THEATER:   '3'
    readonly property string ui_MODE_COVER:     '4'

    // Setting the host initiates a connection attempt
    // null means close/reset, otherwise, attempt connect
    onHostChanged: {
        if (host !== '')
            connectionStart(host)

        connPoller.stop()
        zones.forEach(function(zone) { zone.trackList.clear(); zone.trackList.destroy() })
        zones.clear()
        playlists.currentIndex = -1
        player.zoneCount = 0
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
                             , cmdType: player.cmd_TYPE_Unknown
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

        property int zoneCount: 0
        property var imageErrorKeys: ({})
        property string thumbQuery: reader.hostUrl + 'File/GetImage?width=%1&height=%1&file='.arg(thumbSize < 32 ? 32 : thumbSize)

        readonly property string cmd_MCC:           'Control/MCC?Command='
        readonly property string cmd_MCC_SetZone:   '10011&Parameter='
        readonly property string cmd_MCC_UIMode:    '22009&Parameter='
        readonly property string cmd_MCC_Minimize:  '10014'
        readonly property string cmd_MCC_Maximize:  '10027'
        readonly property string cmd_MCC_Detach:    '10037'

        readonly property int cmd_TYPE_Unknown:     -1
        readonly property int cmd_TYPE_Playback:    0
        readonly property int cmd_TYPE_Search:      1
        readonly property int cmd_TYPE_Playlists:   2
        readonly property int cmd_TYPE_MCC:         3

        function createCmd(parms) {
            if (parms === undefined || parms === '') {
                console.log('Invalid parameter: requires string or object type')
                return null
            }
            var obj = { zonendx: -1
                        , cmd: ''
                        , delay: 0
                        , cmdType: cmd_TYPE_Playback
                        , immediate: true
                        , debug: false
                      }
            // single cmd string, assume a complete cmd with zone constraint
            if (typeof parms === 'string') {
                obj.cmd = parms
            }
            // otherwise, set defaults, construct final cmd obj
            else if (typeof parms === 'object') {

                obj = Object.assign({}, obj, parms)

                if (obj.cmdType === cmd_TYPE_Playback)
                    obj.cmd = 'Playback/' + obj.cmd
                else if (obj.cmdType === cmd_TYPE_Search)
                    obj.cmd = 'Files/Search?' + obj.cmd
                else if (obj.cmdType === cmd_TYPE_Playlists)
                    obj.cmd = 'Playlist/Files?' + obj.cmd
                else if (obj.cmdType === cmd_TYPE_MCC)
                    obj.cmd = cmd_MCC + obj.cmd

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

                var z = zones.get(obj.zonendx)
                console.log('')
                console.log('======>Target Zone: ' + z.zonename)
                for (i in z)
                    console.log(i + ': ' + z[i])
            }

            if (obj.immediate)
                run(obj)

            return obj
        }
        function run(cmdList) {

            if (typeof cmdList !== 'object') {
                console.log('Invalid command list: requires object or array of objects')
                return
            }

            var queueCmd = function(obj) {
                if (obj.delay <= 0)
                    reader.exec(obj.cmd)
                else
                    event.queueCall(obj.delay, reader.exec, [obj.cmd])
            }

            var zonendx = -1
            var cnt = 1
            // cmdList can be an array of cmdObjs or just one
            if (Array.isArray(cmdList)) {
                cnt = cmdList.length
                zonendx = cmdList[0].zonendx
                cmdList.forEach(queueCmd)
            } else {
                zonendx = cmdList.zonendx
                queueCmd(cmdList)
            }

            if (zonendx >= 0 && cnt === 1) {
                event.queueCall(250, player.updateZone, [zones.get(zonendx), zonendx])
            }
        }

        function formatTrackDisplay(mediatype, obj) {
            if (mediatype === 'Audio')
                return "'%1'\n from '%2'\n by %3".arg(obj.name).arg(obj.album).arg(obj.artist)
            else
                return obj.name
        }
        function loadAudioPath(zone) {
            reader.loadObject("Playback/AudioPath?Zone=" + zone.zoneid, function(ap)
            {
                zone.audiopath = ap.audiopath !== undefined ? ap.audiopath.replace(/;/g, '\n') : ''
            })
        }

        function checkZoneCount(callback) {
            reader.loadObject("Playback/Zones", function(zlist)
            {
                if (+zlist.numberzones !== zoneCount) {
                    callback(+zlist.numberzones)
                }
            })
        }

        // Populate the zones model, each obj is a "Playback/Info" for the mcws zone
        function load() {
            reader.loadObject("Playback/Zones", function(data)
            {
                zoneCount = data.numberzones
                for(var i = 0; i<player.zoneCount; ++i) {
                    zones.append({ zoneid: data["zoneid"+i]
                                       , zonename: data["zonename"+i]
                                       , name: data["zonename"+i]
                                       , artist: ''
                                       , album: ''
                                       , state: stateStopped
                                       , linked: false
                                       , mute: false
                                       , trackdisplay: ''
                                       , nexttrackdisplay: ''
                                       , audiopath: ''
                                       , trackList: tm.createObject(conn, { comms: reader
                                                                          , searchCmd: 'Playback/Playlist?Zone=' + data['zoneid'+i]
                                                                          })
                                       , track: {}
                                   })
                    updateZone(zones.get(i), i)
                }
                connPoller.start()
                event.queueCall(300, connectionReady, [-1])
            })
        }
        function updateZone(zone, zonendx) {
            // reset MCWS transient fields
            zone.linkedzones = ''
            // get the info obj
            reader.loadObject("Playback/Info?zone=" + zone.zoneid, function(obj)
            {
                // Empty playlist
                if (+obj.playingnowtracks === 0) {
                    zones.set(zonendx, { trackdisplay: '<empty playlist>'
                                           , artist: ''
                                           , album: ''
                                           , name: '' })
                }

                // Explicit playingnowchangecounter signal
                if (obj.playingnowchangecounter !== zone.playingnowchangecounter) {
                    pnChangeCtrChanged(zonendx, obj.playingnowchangecounter)
                    zone.trackList.load()
                }

                // Explicit track change signal and track display update
                if (obj.filekey !== zone.filekey) {
                    if (obj.filekey !== '-1')
                        getTrackDetails(obj.filekey, function(ti) {
                            if (ti.mediatype === 'Audio') {
                                var artist = obj.artist
                                var album = obj.album
                            }
                            else {
                                artist = album = ''
                            }
                            zones.set(zonendx, { trackdisplay: formatTrackDisplay(ti.mediatype, obj)
                                                   , artist: artist
                                                   , album: album
                                                   , track: ti })
                            trackKeyChanged(zonendx, obj.filekey)
                        })
                    else {
                        zone.track = {}
                        trackKeyChanged(zonendx, obj.filekey)
                    }
                    // Audio Path
                    if (obj.state === statePlaying)
                        event.queueCall(1000, loadAudioPath, [zone])
                }

                // Next file info
                if (obj.nextfilekey !== zone.nextfilekey) {
                    if (obj.nextfilekey === '-1')
                        zone.nexttrackdisplay = 'End of Playlist'
                    else {
                        event.queueCall(500, function()
                        {
                            if (zone.trackList.count !== 0) {
                                var pos = +obj.playingnowposition + 1
                                if (pos !== +obj.playingnowtracks) {
                                    var o = zone.trackList.items.get(pos)
                                    zone.nexttrackdisplay = 'Next up:\n' + formatTrackDisplay(o.mediatype, o)
                                }
                                else
                                    zone.nexttrackdisplay = 'End of Playlist'
                            } else {
                                getTrackDetails(obj.nextfilekey, function(o) {
                                    zone.nexttrackdisplay = 'Next up:\n' + formatTrackDisplay(o.mediatype, o)
                                }, zone.trackList.mcwsFields)
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
                    if (obj.state === statePlaying)
                        event.queueCall(1000, loadAudioPath, [zone])
                }

                zones.set(zonendx, obj)

                zones.set(zonendx, {'linked': obj.linkedzones === undefined ? false : true
                                       ,'mute': obj.volumedisplay === "Muted" ? true : false})
            })
        }

        Component {
            id: tm
            Searcher {}
        }

        BaseListModel {
            id: zones
        }
    }

    signal connectionStart(var host)
    signal connectionReady(var zonendx)
    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)
    signal trackKeyChanged(var zonendx, var trackKey)
    signal pnPositionChanged(var zonendx, var pos)
    signal pnChangeCtrChanged(var zonendx, var ctr)
    signal pnStateChanged(var zonendx, var playerState)

    function sendListToZone(items, srcIndex, destIndex, playNow) {
        var arr = []
        items.forEach(function(track) { arr.push(track.key) })
        player.createCmd({ zonendx: destIndex
                         , cmd: 'SetPlaylist?Playlist=2;%1;0;%2'.arg(arr.length).arg(arr.join(';')) })

        if (playNow === undefined || playNow)
            event.queueCall(500, play, [destIndex])
    }

    // Reset the connection, forces a re-load from MCWS.  Clear the host, then set it.
    function reset() {
        if (isConnected) {
            var h = host
            host = ''
            host = h
        }
    }

    // Return playing zone index.  If there are no playing zones,
    // returns 0 (first zone index).  If there are multiple
    // playing zones, return the index of the last in the list.
    function getPlayingZoneIndex() {
        var list = zonesByState(statePlaying)
        return list.length>0 ? list[list.length-1] : 0
    }
    // Zone player state, return index list
    function zonesByState(state) {
        return zones.filter(function(zone)
        {
            return zone.state === state
        })
    }

    function imageUrl(filekey) {
        return !player.imageErrorKeys[filekey]
                ? player.thumbQuery + filekey
                : 'default.png'
    }
    function setImageError(filekey) {
        player.imageErrorKeys[filekey] = 1
    }

    function play(zonendx) {
        if (zones.get(zonendx).track.mediatype !== 'Audio') {
            if (zones.get(zonendx).state === stateStopped) {
                if (videoFullScreen)
                    setUIMode(zonendx, ui_MODE_DISPLAY)
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
            player.createCmd({delay: 500, cmdType: player.cmd_TYPE_MCC, cmd: player.cmd_MCC_Minimize})
        }
        else
            player.createCmd({zonendx: zonendx, cmd: 'Stop'})
    }
    function stopAllZones() {
        player.createCmd('Playback/StopAll')
    }

    function setCurrentZone(zonendx) {
        player.createCmd({cmdType: player.cmd_TYPE_MCC
                   , cmd: player.cmd_MCC_SetZone + zonendx})
    }
    function setUIMode(zonendx, mode) {
        setCurrentZone(zonendx)
        player.createCmd({cmdType: player.cmd_TYPE_MCC
                   , delay: 500
                   , cmd: player.cmd_MCC_UIMode + (mode === undefined ? ui_MODE_STANDARD : mode)})
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

        var cmdList = [player.createCmd({zonendx: zonendx,
                                    immediate: false,
                                    cmd: 'PlaybyKey?Location=Next&Key=' + filekey
                                   })]
        if (zones.get(zonendx).state === statePlaying)
            cmdList.push(player.createCmd({zonendx: zonendx,
                                      cmd: 'Next',
                                      delay: 1000,
                                      immediate: false
                                     }))

        player.run(cmdList)
    }
    function addTrack(zonendx, filekey, next) {
        searchAndAdd(zonendx, "[key]=" + filekey, next, false)
    }

    function queueAlbum(zonendx, filekey, next) {
        player.createCmd({zonendx: zonendx,
                     cmd: 'PlaybyKey?Key=' + filekey
                        + '&Album=1&Location=' + (next === undefined || next === true ? "Next" : "End")
                    })
    }
    function playAlbum(zonendx, filekey) {
        player.createCmd({zonendx: zonendx, cmd: "PlaybyKey?Album=1&Key=" + filekey})
    }
    function searchAndPlayNow(zonendx, srch, shuffleMode) {
        player.createCmd({zonendx: zonendx,
                     cmdType: player.cmd_TYPE_Search,
                     cmd: "Action=Play&query=" + srch
                        + (shuffleMode === undefined || shuffleMode === true ? "&Shuffle=1" : "")
                    })
    }
    function searchAndAdd(zonendx, srch, next, shuffleMode) {

        var cmdlist = [player.createCmd({zonendx: zonendx,
                                    cmdType: player.cmd_TYPE_Search,
                                    immediate: false,
                                    cmd: 'Action=Play&query=' + srch
                                        + '&PlayMode=' + (next === undefined || next === true ? "NextToPlay" : "Add")
                                   })]
        if (shuffleMode === undefined || shuffleMode === true)
            cmdlist.push(player.createCmd({zonendx: zonendx,
                                      cmd: 'Shuffle?Mode=reshuffle',
                                      delay: 750,
                                      immediate: false
                                     }))
        player.run(cmdlist)
    }

    function getTrackDetails(filekey, callback, fieldlist) {
        if (typeof callback !== 'function')
            return

        if (filekey === '-1')
            callback({})

        fieldlist = fieldlist === undefined || fieldlist === '' ? 'NoLocalFileNames=1' : 'Fields=' + fieldlist
        // MPL query, returns a list of objects, so in this case, a list of one obj
        reader.loadObject('File/GetInfo?%1&file='.arg(fieldlist) + filekey, function(list)
        {
            callback(list[0])
        })
    }

    SingleShot { id: event }

    Reader {
        id: reader

        onConnectionError: {
            console.log('<Connection Error> ' + msg + ' ' + cmd)
            conn.connectionError(msg, cmd)
            // if the error occurs with the current host, close/reset
            if (cmd.indexOf(currentHost) !== -1)
                currentHost = ''

        }
        onCommandError: {
            console.log('<Command Error> ' + msg + ' ' + cmd)
            conn.commandError(msg, cmd)
        }
    }

    Playlists {
        id: playlists
        comms: reader

        function play(zonendx, plid, shuffleMode) {
            player.createCmd({zonendx: zonendx,
                         cmdType: player.cmd_TYPE_Playlists,
                         cmd: "Action=Play&Playlist=" + plid
                              + (shuffleMode === undefined || shuffleMode === true ? "&Shuffle=1" : "")
                        })
        }
        function add(zonendx, plid, shuffleMode) {

            var cmdList = [player.createCmd(
                               {zonendx: zonendx,
                                cmdType: player.cmd_TYPE_Playlists,
                                cmd: 'Action=Play&PlayMode=Add&Playlist=' + plid,
                                immediate: false
                                })]
            if (shuffleMode === undefined || shuffleMode === true)
                cmdList.push(player.createCmd({zonendx: zonendx,
                                          cmd: 'Shuffle?Mode=reshuffle',
                                          immediate: false,
                                          delay: 750}))

            player.run(cmdList)
        }
    }

    Timer {
        id: connPoller; repeat: true

        // non-playing tick ctr
        property int updateCtr: 0
        property int zoneCheckCtr: 0

        onTriggered: {
            // update non-playing zones every 3 ticks, playing zones, every tick
            if (++updateCtr === 3) {
                updateCtr = 0
            }
            zones.forEach(function(zone, ndx)
            {
                if (zone.state === statePlaying | updateCtr === 0) {
                    player.updateZone(zone, ndx)
                }
            })
            // check to see if the playback zones have changed
            if (++zoneCheckCtr === 30) {
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
