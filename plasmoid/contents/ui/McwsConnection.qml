import QtQuick 2.8
import QtQuick.XmlListModel 2.0
import "models"

Item {
    id: conn

    readonly property bool isConnected: d.zoneCount > 0 & (d.zoneCount === zoneModel.count)
    property ListModel zoneModel: ListModel{}
    readonly property var playlists: playlists
    readonly property alias hostUrl: reader.hostUrl
    property string currentHost: ''
    property string lastError

    property bool videoFullScreen: false
    property int thumbSize: 32
    property alias pollerInterval: pnTimer.interval

    onCurrentHostChanged: {
        connectionStart(currentHost)
        pnTimer.stop()
        forEachZone(function(zone) { zone.pnModel.source = '' })
        zoneModel.clear()
        playlists.clear()
        d.zoneCount = 0
        d.imageErrorKeys = {'-1': 1}
        reader.currentHost = currentHost

        if (currentHost !== '')
            d.loadZoneModel()
    }

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

    // private stuff
    QtObject{
        id: d

        property int zoneCount: 0
        property var imageErrorKeys: ({})
        property string thumbQuery: reader.hostUrl + 'File/GetImage?width=%1&height=%1&file='.arg(thumbSize < 32 ? 32 : thumbSize)

        readonly property var playingZones:      function(zone) { return zone.state === statePlaying }
        readonly property var notPlayingZones:   function(zone) { return zone.state !== statePlaying }

        readonly property string cmd_MCC:           'Control/MCC?Command='
        readonly property string cmd_MCC_SetZone:   '10011&Parameter='
        readonly property string cmd_MCC_UIMode:    '22009&Parameter='
        readonly property string cmd_MCC_Minimize:  '10014'
        readonly property string cmd_MCC_Maximize:  '10027'
        readonly property string cmd_MCC_Detach:    '10037'

        readonly property int cmd_TYPE_Playback:    0
        readonly property int cmd_TYPE_Search:      1
        readonly property int cmd_TYPE_Playlists:   2
        readonly property int cmd_TYPE_MCC:         3

        function loadZoneModel() {
            reader.getResponseObject("Playback/Zones", function(data)
            {
                // create the model, one row for each zone
                zoneCount = data.numberzones
                for(var i = 0; i<zoneCount; ++i) {
                    // setup defined props in the model for each zone
                    zoneModel.append({"zoneid": data["zoneid"+i]
                                   , "zonename": data["zonename"+i]
                                   , "state": stateStopped
                                   , "linked": false
                                   , "mute": false
                                   , 'trackdisplay': ''
                                   , 'nexttrackdisplay': ''
                                   , 'pnModel': tm.createObject(conn, { 'hostUrl': reader.hostUrl
                                                                        ,'queryCmd': 'Playback/Playlist?Zone=' + data['zoneid'+i] })
                                   , 'track': {}
                                   })
                    loadRepeatMode(i)
                    updateModelItem(zoneModel.get(i), i)
                }
                pnTimer.start()
                event.singleShot(300, function(){
                    connectionReady(data.currentzoneindex)
                })
            })
        }

        function formatTrackDisplay(mediatype, obj) {
            if (mediatype === 'Audio')
                return "'%1'\n from '%2'\n by %3".arg(obj.name).arg(obj.album).arg(obj.artist)
            else
                return obj.name
        }

        function updateModelItem(zone, zonendx) {
            // reset MCWS transient fields
            zone.linkedzones = ''
            // get the info obj
            reader.getResponseObject("Playback/Info?zone=" + zone.zoneid, function(obj)
            {
                // Empty playlist
                if (+obj.playingnowtracks === 0) {
                    zoneModel.set(zonendx, { 'trackdisplay': '<empty playlist>', 'artist': '', 'album': '', 'name': '' })
                }

                // Explicit playingnowchangecounter signal
                if (obj.playingnowchangecounter !== zone.playingnowchangecounter) {
                    pnChangeCtrChanged(zonendx, obj.playingnowchangecounter)
                    zone.pnModel.reload()
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
                            zoneModel.set(zonendx, {'trackdisplay': formatTrackDisplay(ti.mediatype, obj)
                                                    ,'artist': artist
                                                    ,'album': album
                                                    ,'track': ti
                                                   })
                        })
                    else
                        zone.track = {}

                    trackKeyChanged(zonendx, obj.filekey)
                }

                // Next file info
                if (obj.nextfilekey !== zone.nextfilekey) {
                    if (obj.nextfilekey === '-1')
                        zone.nexttrackdisplay = 'End of Playlist'
                    else {
                        event.singleShot(500, function()
                        {
                            if (zone.pnModel.count !== 0) {
                                var pos = +obj.playingnowposition + 1
                                if (pos !== +obj.playingnowtracks) {
                                    var o = zone.pnModel.get(pos)
                                    zone.nexttrackdisplay = 'Next up:\n' + formatTrackDisplay(o.mediatype, o)
                                }
                                else
                                    zone.nexttrackdisplay = 'End of Playlist'
                            } else {
                                getTrackDetails(obj.nextfilekey, function(o) {
                                    zone.nexttrackdisplay = 'Next up:\n' + formatTrackDisplay(o.mediatype, o)
                                }, zone.pnModel.mcwsFields)
                            }
                        })
                    }
                }

                // Explicit playingnowposition signal and next track up
                if (obj.playingnowposition !== zone.playingnowposition) {
                    pnPositionChanged(zonendx, obj.playingnowposition)
                }

                zoneModel.set(zonendx, obj)

                zoneModel.set(zonendx, {'linked': obj.linkedzones === undefined ? false : true
                                       ,'mute': obj.volumedisplay === "Muted" ? true : false})
            })
        }

        function loadRepeatMode(zonendx) {
            reader.getResponseObject("Playback/Repeat?ZoneType=Index&Zone=" + zonendx, function(data)
            {
                zoneModel.setProperty(zonendx, "repeat", data.mode)
            })
        }
        function loadShuffleMode(zonendx) {
            reader.getResponseObject("Playback/Shuffle?ZoneType=Index&Zone=" + zonendx, function(data)
            {
                zoneModel.setProperty(zonendx, "shuffle", data.mode)
            })
        }

        function createCmd(parms) {
            if (parms === undefined || parms === '') {
                console.log('Invalid parameter: requires string or object type')
                return null
            }

            var defObj = { zonendx: -1
                            , cmd: ''
                            , delay: 0
                            , cmdType: cmd_TYPE_Playback
                            , immediate: true
//                            , debug: true
                         }

            var obj = {}
            // single cmd string, assume a complete cmd with zone constraint
            if (typeof parms === 'string') {
                defObj.cmd = parms
                obj = defObj
            }
            // otherwise, set defaults, construct final cmd obj
            else if (typeof parms === 'object') {

                obj = Object.assign({}, defObj, parms)

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
                                + 'Zone=' + zoneModel.get(obj.zonendx).zoneid
                }
            }

//            if (obj.debug)
//                for (var i in obj)
//                    console.log(i + ': ' + obj[i])

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
                    event.singleShot(obj.delay, function() { reader.exec(obj.cmd) })
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
                event.singleShot(250, function(){ d.updateModelItem(zoneModel.get(zonendx), zonendx) })
            }
        }
    }

    signal connectionStart(var host)
    signal connectionReady(var zonendx)
    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)
    signal trackKeyChanged(var zonendx, var trackKey)
    signal pnPositionChanged(var zonendx, var pos)
    signal pnChangeCtrChanged(var zonendx, var ctr)

    function forEachZone(func) {
        if (func === undefined | typeof(func) !== 'function')
            return

        for (var i=0, len = zoneModel.count; i < len; ++i)
            func(mcws.zoneModel.get(i), i)
    }

    function zonesByState(state) {
        var list = []
        forEachZone(function(zone, zonendx)
        {
            if (zone.state === state)
                list.push(zonendx)
        })

        return list
    }

    function imageUrl(filekey) {
        return !d.imageErrorKeys[filekey]
                ? d.thumbQuery + filekey
                : 'default.png'
    }
    function setImageError(filekey) {
        d.imageErrorKeys[filekey] = 1
    }

    function updateModel(func) {
        if (typeof func !== 'function')
            func = d.playingZones

        forEachZone(function(zone, zonendx) {
            if (func(zone))
                d.updateModelItem(zone, zonendx)
        })
    }

    function play(zonendx) {
        if (zoneModel.get(zonendx).track.mediatype !== 'Audio') {
            if (zoneModel.get(zonendx).state === stateStopped) {
                if (videoFullScreen)
                    setUIMode(zonendx, ui_MODE_DISPLAY)
                else
                    setCurrentZone(zonendx)
            }
        }

        d.createCmd({zonendx: zonendx, cmd: 'PlayPause'})
    }

    function previous(zonendx) {
        d.createCmd({zonendx: zonendx, cmd: 'Previous'})
    }
    function next(zonendx) {
        d.createCmd({zonendx: zonendx, cmd: 'Next'})
    }
    function stop(zonendx) {
        if (zoneModel.get(zonendx).track.mediatype !== 'Audio') {
            d.createCmd({zonendx: zonendx, cmd: 'Stop'})
            d.createCmd({delay: 500, cmdType: d.cmd_TYPE_MCC, cmd: d.cmd_MCC_Minimize})
        }
        else
            d.createCmd({zonendx: zonendx, cmd: 'Stop'})
    }
    function stopAllZones() {
        d.createCmd('Playback/StopAll')
    }

    function setCurrentZone(zonendx) {
        d.createCmd({cmdType: d.cmd_TYPE_MCC
                   , cmd: d.cmd_MCC_SetZone + zonendx})
    }
    function setUIMode(zonendx, mode) {
        setCurrentZone(zonendx)
        d.createCmd({cmdType: d.cmd_TYPE_MCC
                   , delay: 500
                   , cmd: d.cmd_MCC_UIMode + (mode === undefined ? ui_MODE_STANDARD : mode)})
    }

    function unLinkZone(zonendx) {
        d.createCmd({zonendx: zonendx, cmd: 'UnlinkZones'})
    }
    function linkZones(zone1id, zone2id) {
        d.createCmd("Playback/LinkZones?Zone1=" + zone1id + "&Zone2=" + zone2id)
    }

    function isPlaylistEmpty(zonendx) {
        return zoneModel.get(zonendx).playingnowtracks === '0'
    }

    function setMute(zonendx, mute) {
        d.createCmd({zonendx: zonendx, cmd: "Mute?Set=" + (mute === undefined ? "1" : mute ? "1" : "0")})
    }
    function setVolume(zonendx, level) {
        d.createCmd({zonendx: zonendx, cmd: "Volume?Level=" + level})
    }

    function shuffle(zonendx) {
        d.createCmd({zonendx: zonendx, cmd: "Shuffle?Mode=reshuffle"})
    }
    function setPlayingPosition(zonendx, pos) {
        d.createCmd({zonendx: zonendx, cmd: "Position?Position=" + pos})
    }
    function setRepeat(zonendx, mode) {
        d.createCmd({zonendx: zonendx, cmd: "Repeat?Mode=" + mode})
        event.singleShot(500, function() { d.loadRepeatMode(zonendx) })
    }
    function repeatMode(zonendx) {
        return zonendx >= 0 ? zoneModel.get(zonendx).repeat : ""
    }

    function removeTrack(zonendx, trackndx) {
        d.createCmd({zonendx: zonendx, cmd: "EditPlaylist?Action=Remove&Source=" + trackndx})
    }
    function clearPlayingNow(zonendx) {
        d.createCmd({zonendx: zonendx, cmd: "ClearPlaylist"})
    }
    function playTrack(zonendx, pos) {
        d.createCmd({zonendx: zonendx, cmd: "PlaybyIndex?Index=" + pos})
    }
    function playTrackByKey(zonendx, filekey) {

        var cmdList = [d.createCmd({zonendx: zonendx,
                                    immediate: false,
                                    cmd: 'PlaybyKey?Location=Next&Key=' + filekey
                                   })]
        if (zoneModel.get(zonendx).state === statePlaying)
            cmdList.push(d.createCmd({zonendx: zonendx,
                                      cmd: 'Next',
                                      delay: 1000,
                                      immediate: false
                                     }))

        d.run(cmdList)
    }
    function addTrack(zonendx, filekey, next) {
        searchAndAdd(zonendx, "[key]=" + filekey, next, false)
    }

    function queueAlbum(zonendx, filekey, next) {
        d.createCmd({zonendx: zonendx,
                     cmd: 'PlaybyKey?Key=' + filekey
                        + '&Album=1&Location=' + (next === undefined || next === true ? "Next" : "End")
                    })
    }
    function playAlbum(zonendx, filekey) {
        d.createCmd({zonendx: zonendx, cmd: "PlaybyKey?Album=1&Key=" + filekey})
    }
    function searchAndPlayNow(zonendx, srch, shuffleMode) {
        d.createCmd({zonendx: zonendx,
                     cmdType: d.cmd_TYPE_Search,
                     cmd: "Action=Play&query=" + srch
                        + (shuffleMode === undefined || shuffleMode === true ? "&Shuffle=1" : "")
                    })
    }
    function searchAndAdd(zonendx, srch, next, shuffleMode) {

        var cmdlist = [d.createCmd({zonendx: zonendx,
                                    cmdType: d.cmd_TYPE_Search,
                                    immediate: false,
                                    cmd: 'Action=Play&query=' + srch
                                        + '&PlayMode=' + (next === undefined || next === true ? "NextToPlay" : "Add")
                                   })]
        if (shuffleMode === undefined || shuffleMode === true)
            cmdlist.push(d.createCmd({zonendx: zonendx,
                                      cmd: 'Shuffle?Mode=reshuffle',
                                      delay: 750,
                                      immediate: false
                                     }))
        d.run(cmdlist)
    }

    function getTrackDetails(filekey, callback, fieldlist) {
        if (typeof callback !== 'function')
            return

        if (filekey === '-1')
            callback({})

        fieldlist = fieldlist === undefined || fieldlist === '' ? 'NoLocalFileNames=1' : 'Fields=' + fieldlist
        // MPL query, returns a list of objects, so in this case, a list of one obj
        reader.getResponseObject('File/GetInfo?%1&file='.arg(fieldlist) + filekey, function(list)
        {
            callback(list[0])
        })
    }

    Component {
        id: tm
        TrackModel { }
    }

    SingleShot { id: event }

    Reader {
        id: reader

        onConnectionError: {
            lastError = '<Connection Error> ' + msg + ': ' + cmd
            handleError(lastError)
            conn.connectionError(msg, cmd)
        }
        onCommandError: {
            lastError = '<Command Error> ' + msg + ': ' + cmd
            handleError(lastError)
            conn.commandError(msg, cmd)
        }

        // default error handling, just log the error.
        function handleError(msg) {
            console.log(msg)
        }
    }

    Playlists {
        id: playlists
        hostUrl: reader.hostUrl

        function play(zonendx, plid, shuffleMode) {
            d.createCmd({zonendx: zonendx,
                         cmdType: d.cmd_TYPE_Playlists,
                         cmd: "Action=Play&Playlist=" + plid
                              + (shuffleMode === undefined || shuffleMode === true ? "&Shuffle=1" : "")
                        })
        }
        function add(zonendx, plid, shuffleMode) {

            var cmdList = [d.createCmd(
                               {zonendx: zonendx,
                                cmdType: d.cmd_TYPE_Playlists,
                                cmd: 'Action=Play&PlayMode=Add&Playlist=' + plid,
                                immediate: false
                                })]
            if (shuffleMode === undefined || shuffleMode === true)
                cmdList.push(d.createCmd({zonendx: zonendx,
                                          cmd: 'Shuffle?Mode=reshuffle',
                                          immediate: false,
                                          delay: 750}))

            d.run(cmdList)
        }
    }

    Timer {
        id: pnTimer; repeat: true

        property int ctr: 0
        onTriggered: {
            if (++ctr === 3) {
                ctr = 0
                updateModel(d.notPlayingZones)
            }
            updateModel()
        }
        onIntervalChanged: {
            ctr = 0
            restart()
        }
    }
}
