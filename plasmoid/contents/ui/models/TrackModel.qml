import QtQuick 2.8
import QtQuick.XmlListModel 2.0

BaseXml {
    query: "/MPL/Item"
    mcwsFields: "name,artist,album,genre,duration"

    onHostUrlChanged: source = ""

    function loadPlayingNow(zoneid)
    {
        source = ""
        load("Playback/Playlist?Fields=" + mcwsFields + "&Zone=" + zoneid)
    }

    function loadSearch(search)
    {
        source = ""
        load("Files/Search?Fields=" + mcwsFields + "&Shuffle=1&query=" + search)
    }

    // Filekey (mcws: Key) will always be the first field returned
    XmlRole { name: "filekey";  query: "Field[1]/string()" }

}
