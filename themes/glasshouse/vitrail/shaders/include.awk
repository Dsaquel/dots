/^#include "/ {
    path = "shaders/" substr($2, 2, length($2) - 2)
    while ((status = getline line < path) > 0)
        print line
    if (status < 0) {
        print "include.awk: cannot read " path > "/dev/stderr"
        exit 1
    }
    close(path)
    next
}
{ print }
