import QtQuick

Item {
    id: keys

    focus: enabled
    Keys.onPressed: event => {
        Slumber.key(event.key, event.text, event.modifiers);
        event.accepted = true;
    }
}
