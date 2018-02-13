import QtQuick 2.8

ListModel {

    function filter(compare) {
        if (typeof compare !== 'function')
            return []

        var list = []
        for (var i=0, len = count; i<len; ++i) {
            if (compare(get(i)))
                list.push(i)
        }
        return list
    }

    function findIndex(compare) {
        if (typeof compare !== 'function')
            return -1

        for (var i=0, len = count; i<len; ++i) {
            if (compare(get(i)))
                return i
        }
        return -1
    }
    function find(compare) {
        if (typeof compare !== 'function')
            return undefined

        for (var i=0, len = count; i<len; ++i) {
            if (compare(get(i)))
                return get(i)
        }
        return undefined
    }
    function forEach(fun) {
        if (typeof fun !== 'function')
            return

        for (var i=0, len = count; i<len; ++i) {
            fun(get(i), i)
        }
    }

}

