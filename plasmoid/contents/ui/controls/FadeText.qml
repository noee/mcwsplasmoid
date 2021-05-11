import QtQuick 2.8
import org.kde.plasma.components 3.0 as PComp
import '../helpers'

PComp.Label {
    id: txt
    property int duration: 750
    property alias animate: fb.enabled

    FadeBehavior on text {
        id: fb
        fadeDuration: txt.duration
    }

}
