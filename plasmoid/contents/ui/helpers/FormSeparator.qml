import QtQuick 2.8
import org.kde.kirigami 2.8 as Kirigami

Kirigami.Separator {
    property string text: ''
    property bool isSection: true

    Kirigami.FormData.isSection: isSection
    Kirigami.FormData.label: text
}
