import QtQuick 2.0
import QtQuick.Controls 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import '../libs'

Item {
	implicitWidth: label.implicitWidth
	implicitHeight: label.implicitHeight

	property string version: "?"
	property string metadataFilepath: plasmoid.file("", "../metadata.desktop")

    Process {
        id: ver
    }

	Connections {
        target: ver
		onExited: {
			version = stdout.replace('\n', ' ').trim()
		}
	}

    Label {
        id: label
        text: i18n("v%1", version)
	}

	Component.onCompleted: {
		var cmd = 'kreadconfig5 --file "' + metadataFilepath + '" --group "Desktop Entry" --key "X-KDE-PluginInfo-Version"'
        ver.exec(cmd)
	}

}
