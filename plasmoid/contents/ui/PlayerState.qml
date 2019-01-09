import QtQuick 2.11

QtObject {
    enum PlayerState {
        Stopped = 0,
        Paused,
        Playing,
        Aborting,
        Buffering
    }
}
