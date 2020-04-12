import QtQuick 2.8
import QtQml.Models 2.3
import 'utils.js' as Utils

ListModel {

    function filter(compare) {
        if (!Utils.isFunction(compare))
            return []

        var list = []
        for (var i=0, len = count; i<len; ++i) {
            if (compare(get(i)))
                list.push(i)
        }
        return list
    }

    function findIndex(compare) {
        if (!Utils.isFunction(compare))
            return -1

        for (var i=0, len = count; i<len; ++i) {
            if (compare(get(i)))
                return i
        }
        return -1
    }
    function contains(compare) {
        return (findIndex(compare) !== -1)
    }
    function find(compare) {
        if (!Utils.isFunction(compare))
            return undefined

        for (var i=0, len = count; i<len; ++i) {
            if (compare(get(i)))
                return get(i)
        }
        return undefined
    }
    function forEach(fun) {
        if (!Utils.isFunction(fun))
            return

        for (var i=0, len = count; i<len; ++i) {
            fun(get(i), i)
        }
    }
    function toArray() {
        var arr = []
        for (var i=0, len = count; i<len; ++i) {
            arr.push(get(i))
        }
        return arr
    }

    function sort(sortRole, compareFunc) {
        if (!Utils.isFunction(compareFunc))
            compareFunc = (role, item1, item2) => {
                if (item1[role] < item2[role])
                   return -1
                if (item1[role] > item2[role])
                   return 1
                else
                   return 0
            }

        sortRole = Utils.toRoleName(sortRole)
        let indexes = [...Array(count)].map( (v,i) => i )
        indexes.sort( (a, b) => compareFunc(sortRole, get(a), get(b)) )

        let sorted = 0
        while (sorted < indexes.length && sorted === indexes[sorted]) sorted++

        if (sorted === indexes.length) return

        for (let i = sorted; i < indexes.length; i++) {
           move(indexes[i], count - 1, 1)
           insert(indexes[i], { } )
        }
        remove(sorted, indexes.length - sorted)
    }
}

