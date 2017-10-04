import QtQuick 2.2
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
         name: i18n('Connections')
         icon: 'yast-instserver'
         source: 'config/ConfigMisc.qml'
    }
    ConfigCategory {
         name: i18n("Colors")
         icon: "preferences-desktop-color"
         source: "config/ConfigColors.qml"
    }
}
