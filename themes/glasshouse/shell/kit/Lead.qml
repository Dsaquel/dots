import QtQuick
import qs.core

Metal {
    base: Theme.metalBase
    hi: Theme.metalHi
    low: Theme.metalLow
    sky: Theme.metalSky
    metal: Theme.dark ? 0.7 : 1.0
    shininess: Theme.dark ? 30 : 42
    depth: Theme.dark ? 4.2 : 5
}
