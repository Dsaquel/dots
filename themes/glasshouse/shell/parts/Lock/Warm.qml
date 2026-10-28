import QtQuick
import QtMultimedia

MediaPlayer {
    id: warm

    signal warmed()

    onMediaStatusChanged: {
        if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.InvalidMedia || mediaStatus === MediaPlayer.NoMedia && source == "")
            warm.warmed();
    }
    onErrorOccurred: warm.warmed()
    Component.onDestruction: source = ""
}
