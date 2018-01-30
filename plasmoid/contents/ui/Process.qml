import QtQuick 2.8
import org.kde.plasma.core 2.1 as PlasmaCore

PlasmaCore.DataSource {
    engine: "executable"
    connectedSources: []
    onNewData: {
        var exitCode = data["exit code"]
        var exitStatus = data["exit status"]
        var stdout = data["stdout"]
        var stderr = data["stderr"]
        exited(exitCode, exitStatus, stdout, stderr)
        disconnectSource(sourceName)
    }
    function exec(cmd) {
        connectSource(cmd)
    }
    signal exited(int exitCode, int exitStatus, string stdout, string stderr)
}
