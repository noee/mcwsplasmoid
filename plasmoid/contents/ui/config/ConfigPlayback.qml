import QtQuick 2.8
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

GridLayout {

    property alias cfg_autoShuffle: autoShuffle.checked

    PlasmaComponents.CheckBox {
        id: autoShuffle
        text: "Shuffle when adding or playing"
    }
}
