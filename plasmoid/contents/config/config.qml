import QtQuick 2.2
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
         name: i18n('Connections')
         icon: 'yast-instserver'
         source: 'config/ConfigMisc.qml'
    }
    ConfigCategory {
         name: i18n("Appearance")
         icon: "preferences-desktop-color"
         source: "config/ConfigAppearance.qml"
    }
    ConfigCategory {
         name: i18n("Playback Options")
         icon: "multimedia-player"
         source: "config/ConfigPlayback.qml"
    }
}
