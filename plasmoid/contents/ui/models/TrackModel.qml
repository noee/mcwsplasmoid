import QtQuick 2.8
import QtQuick.XmlListModel 2.0

BaseXml {
    query: "/MPL/Item"
    mcwsFields: "name,artist,album,genre,duration,media type"

    onHostUrlChanged: source = ""

    function loadPlayingNow(zoneid)
    {
        source = ""
        load("Playback/Playlist?Zone=" + zoneid)
    }

    function loadSearch(search)
    {
        source = ""
        load("Files/Search?Shuffle=1&query=" + search)
    }

    function loadPlaylistFiles(search)
    {
        source = ""
        load("Playlist/Files?" + search)
    }

    // Filekey (mcws: Key) will always be the first field returned
    XmlRole { name: "filekey";  query: "Field[1]/string()" }

}
