import Quickshell.Io
import qs.core

FileView {
    property alias seats: store.seats

    path: Settings.dir + "/sill.json"
    printErrors: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
        if (error === FileViewError.FileNotFound)
            writeAdapter();
    }
    JsonAdapter {
        id: store
        property var seats: ({})
    }
}
