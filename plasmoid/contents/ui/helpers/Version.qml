import QtQuick 2.9
import QtQuick.Controls 2.4

Item {
	implicitWidth: label.implicitWidth
	implicitHeight: label.implicitHeight

	property string version: "?"
	property string metadataFilepath: plasmoid.file("", "../metadata.desktop")

    Process {
        id: ver
        onExited: {
            version = stdout.replace('\n', ' ').trim()
        }
    }

    Label {
        id: label
        text: i18n("v%1", version)
	}

	Component.onCompleted: {
        ver.exec('kreadconfig5 --file "'
                 + metadataFilepath
                 + '" --group "Desktop Entry" --key "X-KDE-PluginInfo-Version"')
	}

}
