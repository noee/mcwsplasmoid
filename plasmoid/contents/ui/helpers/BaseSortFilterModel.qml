import QtQuick 2.8
import org.kde.kitemmodels 1.0
import 'utils.js' as Utils

KSortFilterProxyModel {

    function mapRowToSource(row) {
        let mi = mapToSource(index(row, 0))
        return mi.row
    }

    function mapRowFromSource(row) {
        let mi = mapFromSource(sourceModel.index(row, 0))
        return mi.row
    }

    function get(row) {
        if (row < 0 || row >= sourceModel.rowCount()) {
            console.log('SFM row:', row)
            return null
        }
        return sourceModel.get(mapRowToSource(row))
    }

    function filter(compare) {
        if (!Utils.isFunction(compare))
            return []

        var list = []
        for (var i=0, len = sourceModel.rowCount(); i<len; ++i) {
            if (compare(get(i)))
                list.push(i)
        }
        return list
    }

    function findIndex(compare) {
        if (!Utils.isFunction(compare))
            return -1

        for (var i=0, len = sourceModel.rowCount(); i<len; ++i) {
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

        for (var i=0, len = sourceModel.rowCount(); i<len; ++i) {
            if (compare(get(i)))
                return get(i)
        }
        return undefined
    }
    function forEach(fun) {
        if (!Utils.isFunction(fun))
            return

        for (var i=0, len = sourceModel.rowCount(); i<len; ++i) {
            fun(get(i), i)
        }
    }
    function toArray() {
        var arr = []
        for (var i=0, len = sourceModel.rowCount(); i<len; ++i) {
            arr.push(get(i))
        }
        return arr
    }

}

