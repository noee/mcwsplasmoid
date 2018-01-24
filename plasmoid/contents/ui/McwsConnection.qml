import QtQuick 2.8
import QtQuick.XmlListModel 2.0
import "models"

Item {
    id: conn

    readonly property bool isConnected: (d.zoneCount > 0) && d.modelReady
    property ListModel zoneModel: ListModel{}
    readonly property var playlists: playlists
    readonly property alias hostUrl: reader.hostUrl
    property string lastError

    property alias pollerInterval: pnTimer.interval
    onPollerIntervalChanged: pnTimer.restart()

    // Player states
    readonly property string stateStopped:  "0"
    readonly property string statePaused:   "1"
    readonly property string statePlaying:  "2"
    readonly property string stateAborting: "3"
    readonly property string stateBuffering:"4"

    // private stuff
    QtObject{
        id: d

        property int zoneCount: 0
        property int currZoneIndex: 0
        property bool modelReady: false
        property int initCtr: 0

        function init(host) {
            pnTimer.stop()
            zoneModel.clear()
            playlists.clear()
            zoneCount = 0
            currZoneIndex = 0
            initCtr = 0
            modelReady = false
            reader.currentHost = host
        }

        function updateModelItem(zone, zonendx) {
            // check parms, get a zone item ref if it's not valid
            if (zonendx < 0 || zonendx >= zoneModel.count) {
                console.log('Invalid zone index: ' + zonendx + ', model count: ' + zoneModel.count)
                return
            }
            if (zone === undefined || zone === null)
                zone = zoneModel.get(zonendx)

            // reset MCWS transient fields
            zone.linkedzones = ''
            reader.getResponseObject("Playback/Info?zone=" + zone.zoneid, function(obj)
            {
                // Explicit track change signal
                if (obj.filekey !== zone.filekey) {
                    // HACK: typically, album defined means the other fields are there (Audio)
                    if (obj.album !== undefined)
                        zone.trackdisplay = "'%1'\n from '%2' \n by %3".arg(obj.name).arg(obj.album).arg(obj.artist)
                    else
                        zoneModel.set(zonendx, {'artist': ''
                                                ,'album': ''
                                                ,'trackdisplay': obj.name
                                              })

                    getTrackDetails(obj.filekey, function(ti) {
                        zone.track = ti
                    })

                    trackKeyChanged(zonendx, obj.filekey)
                }
                // Explicit playingnowposition signal
                if (obj.playingnowposition !== zone.playingnowposition) {
                    pnPositionChanged(zonendx, obj.playingnowposition)
                }
                // Explicit playingnowchangecounter signal
                if (obj.playingnowchangecounter !== zone.playingnowchangecounter) {
                    pnChangeCtrChanged(zonendx, obj.playingnowchangecounter)
                }

                zoneModel.set(zonendx, obj)

                zoneModel.set(zonendx, {'linked': obj.linkedzones === undefined ? false : true
                                       ,'mute': obj.volumedisplay === "Muted" ? true : false
                                       })

                // !Startup only! notify that the connection is ready
                if (!modelReady) {
                    initCtr++
                    if (zoneCount === initCtr) {
                        modelReady = true
                        connectionReady(currZoneIndex)
                    }
                }
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
    }

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

    function run(zonendx, cmd) {
        if (zonendx === undefined | zonendx === -1)
            reader.exec(cmd)
        else {
            var z = zoneModel.get(zonendx)
            reader.exec("%1%2Zone=%3".arg(cmd).arg(cmd.indexOf('?') === -1 ? '?' : '&').arg(z.zoneid))
            event.singleShot(300, function(){ d.updateModelItem(z, zonendx) })
        }
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
    function imageUrl(filekey, size) {
        var imgsize = (size === undefined | size === null) ? 'medium' : size
        return hostUrl + "File/GetImage?Thumbnailsize=" + imgsize + "&File=" + filekey
    }

    function updateModel(state, include) {
        // null params means update playing zones only
        var stateVal = state === undefined ? statePlaying : state
        var stateTest = (include === undefined || include === true || include === null)
                ? function(st) { return st === stateVal }
                : function(st) { return st !== stateVal }

        forEachZone(function(zone, zonendx) {
            if (stateTest(zone.state))
                d.updateModelItem(zone, zonendx)
        })
    }

    function connect(host) {
        // reset everything
        d.init(host)
        // Get Zones list, load model
        reader.getResponseObject("Playback/Zones", function(data)
        {
            // create the model, one row for each zone
            d.zoneCount = data.numberzones
            d.currZoneIndex = data.currentzoneindex
            for(var i = 0; i<d.zoneCount; ++i) {
                // setup defined props in the model for each zone
                zoneModel.append({"zoneid": data["zoneid"+i]
                               , "zonename": data["zonename"+i]
                               , "state": stateStopped
                               , "linked": false
                               , "mute": false
                               , 'trackdisplay': ''
                               })
                d.loadRepeatMode(i)
            }
            updateModel(statePlaying, false)
            pnTimer.start()
        })
    }
    function closeConnection() {
        d.init('')
    }

    function play(zonendx) {
        run(zonendx, "Playback/PlayPause")
    }
    function previous(zonendx) {
        run(zonendx, "Playback/Previous")
    }
    function next(zonendx) {
        run(zonendx, "Playback/Next")
    }
    function stop(zonendx) {
        run(zonendx, "Playback/Stop")
    }
    function stopAllZones() {
        run(-1, "Playback/StopAll")
    }

    function unLinkZone(zonendx) {
        run(zonendx, "Playback/UnlinkZones")
    }
    function linkZones(zone1id, zone2id) {
        run(-1, "Playback/LinkZones?Zone1=" + zone1id + "&Zone2=" + zone2id)
    }

    function isPlaylistEmpty(zonendx) {
        return zoneModel.get(zonendx).playingnowtracks === '0'
    }
    function isStopped(zonendx) {
        return zoneModel.get(zonendx).state === stateStopped
    }
    function isPlaying(zonendx) {
        return zoneModel.get(zonendx).state === statePlaying
    }
    function isPaused(zonendx) {
        return zoneModel.get(zonendx).state === statePaused
    }

    function isMuted(zonendx) {
        return zoneModel.get(zonendx).mute
    }
    function toggleMute(zonendx) {
        setMute(zonendx, !isMuted(zonendx))
    }
    function setMute(zonendx, mute) {
        var val = (mute === undefined)
                ? "0"
                : mute ? "1" : "0"

        run(zonendx, "Playback/Mute?Set=" + val)
    }
    function setVolume(zonendx, level) {
        run(zonendx, "Playback/Volume?Level=" + level)
    }

    function shuffle(zonendx) {
        run(zonendx, "Playback/Shuffle?Mode=reshuffle")
    }
    function setPlayingPosition(zonendx, pos) {
        run(zonendx, "Playback/Position?Position=" + pos)
    }
    function setRepeat(zonendx, mode) {
        run(zonendx, "Playback/Repeat?Mode=" + mode)
        event.singleShot(250, function() { d.loadRepeatMode(zonendx) })
    }
    function repeatMode(zonendx) {
        return zonendx >= 0 ? zoneModel.get(zonendx).repeat : ""
    }

    function removeTrack(zonendx, trackndx) {
        run(zonendx, "Playback/EditPlaylist?Action=Remove&Source=" + trackndx)
    }
    function clearPlaylist(zonendx) {
        run(zonendx, "Playback/ClearPlaylist")
    }
    function playTrack(zonendx, pos) {
        run(zonendx, "Playback/PlaybyIndex?Index=" + pos)
    }
    function playTrackByKey(zonendx, filekey) {
        var pos = +zoneModel.get(zonendx).playingnowposition + 1
        run(zonendx, "Playback/PlaybyKey?Key=%1&Location=%2".arg(filekey).arg(pos))
        event.singleShot(1200, function() { playTrack(zonendx, pos) })
    }
    function addTrack(zonendx, filekey, next) {
        searchAndAdd(zonendx, "[key]=" + filekey, next, false)
    }

    function queueAlbum(zonendx, filekey, next) {
        run(zonendx, "Playback/PlaybyKey?Key=%1&Album=1&Location=%2".arg(filekey).arg(next ? "Next" : "End"))
    }
    function playAlbum(zonendx, filekey) {
        run(zonendx, "Playback/PlaybyKey?Album=1&Key=" + filekey)
    }
    function searchAndPlayNow(zonendx, srch, shuffleMode) {
        run(zonendx, "Files/Search?Action=Play&query=" + srch + (shuffleMode ? "&Shuffle=1" : ""))
    }
    function searchAndAdd(zonendx, srch, next, shuffleMode) {
        run(zonendx, "Files/Search?Action=Play&query=%1&PlayMode=%2".arg(srch).arg(next ? "NextToPlay" : "Add"))
        if (shuffleMode)
            event.singleShot(1000, function() { shuffle(zonendx) })
    }

    function getTrackDetails(filekey, callback) {
        if (filekey === '-1')
            return

        // MPL query, returns a list of objects, key is filekey, so in this case, a list of one obj
        reader.getResponseObject('File/GetInfo?NoLocalFileNames=1&file=' + filekey, function(list)
        {
            callback(list[0])
        })
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
        // See Reader
        function handleError(msg) {
            console.log(msg)
        }
    }

    Playlists {
        id: playlists
        hostUrl: reader.hostUrl

        function play(zonendx, plid, shuffleMode) {
            run(zonendx, "Playlist/Files?Action=Play&Playlist=" + plid + (shuffleMode ? "&Shuffle=1" : ""))
        }
        function add(zonendx, plid, shuffleMode) {
            run(zonendx, "Playlist/Files?Action=Play&PlayMode=Add&Playlist=" + plid)
            if (shuffleMode)
                event.singleShot(500, function() { shuffle(zonendx) })
        }
    }

    Timer {
        id: pnTimer; repeat: true
        triggeredOnStart: true

        property int ctr: 0
        onTriggered: {
            ++ctr
            if (ctr === 3) {
                ctr = 0
                updateModel(statePlaying, false)
            }
            updateModel()
        }
    }
}
