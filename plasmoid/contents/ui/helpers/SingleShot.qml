import QtQuick 2.0

Item {
    Component {
        id: compCaller
        Timer {}
    }

    function queueCall() {
        if (!arguments)
            return

        // first param fn, then just run it with args if any
        if (typeof arguments[0] === 'function') {
            var fn = arguments[0]
            var delay = 0
            if (arguments.length > 1)
                var copyargs = [].splice.call(arguments,1)
        }
        // NOP
        else if (arguments.length < 2)
            return
        // first arg delay, second fn, run with args if any
        else {
            delay = arguments[0]
            fn = arguments[1]
            if (arguments.length > 2)
                 copyargs = [].splice.call(arguments,2)
        }

        var caller = compCaller.createObject(null, { interval: delay, running: true })
        caller.triggered.connect(function()
        {
            fn.apply(null, copyargs || [])
            caller.destroy()
        })
    }

}
