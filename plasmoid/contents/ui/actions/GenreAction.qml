import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    defaultIcon: 'view-media-genre'
    aText: genre ?? '<unknown>'
    onTriggered: {
        if (method !== '') {
            if (method === 'show')
                call[method]({ genre: '[%1]'.arg(genre) })
            else
                call[method]("genre=[%1]".arg(genre))
        }
    }
}
