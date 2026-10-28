import QtQuick
import Quickshell.Io
import qs.core

Instantiator {
    id: sheets

    required property var her

    model: ["dark", "light"]
    delegate: FileView {
        required property string modelData
        path: Assets.root + "/sill/" + modelData + ".json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const a = Object.assign({}, sheets.her.arts);
                a[modelData] = JSON.parse(text());
                sheets.her.arts = a;
            } catch (e) {}
        }
    }
}
