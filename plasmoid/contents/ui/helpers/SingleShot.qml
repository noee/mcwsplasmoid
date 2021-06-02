import QtQuick 2.0

Item {
    Component {
        id: compCaller
        Timer {}
    }

    function queueCall() {
        if (!arguments)
            return

        const len = arguments.length

        // check first param fn, run it with args if any
        if (typeof arguments[0] === 'function') {
            var delay = 0
            var fn = arguments[0]
            var copyargs = len > 1
                            ? [].splice.call(arguments,1)
                            : []

        // first arg delay, second fn, run with args if any
        } else if (len >= 2) {
            delay = arguments[0]
            fn = arguments[1]
            copyargs = len > 2
                        ? [].splice.call(arguments,2)
                        : []

        // NOP
        } else {
            console.warn('Invalid arg list: ' + arguments)
            return
        }

        var caller = compCaller.createObject(null, {interval: delay, running: true})
        caller.triggered.connect(() => {
            fn.apply(null, copyargs)
            caller.destroy()
        })
    }

}
