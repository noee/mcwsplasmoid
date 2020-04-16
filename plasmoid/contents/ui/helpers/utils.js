.pragma library

function toRoleName(value) {
    return value.replace(/ /g,'').replace(/#/g,'_').toLowerCase();
}
function stringifyObj(obj) {
    return JSON.stringify(obj).replace(/,/g,'\n').replace(/":"/g,': ').replace(/("|}|{)/g,'')
}
function printObject(obj) {
    for (var p in obj) {
        console.log(typeof(obj[p]) + ': ' + p + '=' + obj[p])
    }
}
function simpleClear(obj) {
    for (var p in obj) delete obj[p]
}
function copy(o) {
  var output, v, key;
  output = Array.isArray(o) ? [] : {};
  for (key in o) {
    v = o[key];
    output[key] = isObject(v) ? copy(v) : v;
  }
  return output
}

function isFunction(f) {
    return (f && typeof f === 'function')
}
function isObject(o) {
    return (o && typeof o === 'object')
}

function jsonGet(cmdstr, cb) {
    if (!isFunction(cb)) {
        console.warn("Specify callback to get results", cmdstr)
        return
    }

    var xhr = new XMLHttpRequest()

    xhr.onerror = () => {
        console.warn("Unable to connect: ", cmdstr)
    }

    xhr.onreadystatechange = function()
    {
        if (xhr.readyState === XMLHttpRequest.DONE) {

            if (xhr.status === 0) {
                console.warn("Unable to connect: ", cmdstr)
                return
            }
            if (xhr.status !== 200) {
                console.warn('<status: %1:%2>'.arg(xhr.status).arg(xhr.statusText), cmdstr)
                return
            }
            cb(xhr.response)
        }
    }

    xhr.open("GET", cmdstr);
    xhr.responseType = 'json'
    xhr.send();
}
