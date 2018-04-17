.pragma library

function toRoleName(value) {
    return value.replace(/ /g,'').replace(/#/g,'_').toLowerCase();
}
function stringifyObj(obj) {
    return JSON.stringify(obj).replace(/,/g,'\n').replace(/":"/g,': ').replace(/("|}|{)/g,'')
}
function printObject(obj) {
    for (var p in obj) {
        console.log(typeof(obj[p]) + ': ' + p + ': ' + obj[p])
    }
}
function copy(o) {
  var output, v, key;
  output = Array.isArray(o) ? [] : {};
  for (key in o) {
    v = o[key];
    output[key] = (typeof v === "object" && v !== null) ? copy(v) : v;
  }
  return output
}

function isFunction(f) {
    return (f && typeof f === 'function')
}
