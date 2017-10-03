 
function removeQuotes(value) {
    return String(value).replace(/["']/g,'');
}
function readBody(xhr) {
    var data;
    if (!xhr.responseType || xhr.responseType === "text") {
        data = xhr.responseText;
    } else if (xhr.responseType === "document") {
        data = xhr.responseXML;
    } else {
        data = xhr.response;
    }
    return data;
}

function stringList(values) {
    var ret = ""
    for(var prop in values) {
        var s = values[prop]
        if (s !== undefined)
            ret += prop + ": " + s + "\n"
//            ret += "property string " + String(prop).toLowerCase() + "\n"
    }
    return ret
}
