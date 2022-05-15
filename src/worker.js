var old_msg = self.onmessage;

self.onmessage = function(e) {
    if (e.data.cmd == "py") {
        _PyRun_SimpleString(allocateUTF8(e.data.payload));
    } else {
        old_msg(e);
    }
}

function vialgluejs_write_device(data) {
    var buf = [];
    for (var i = 0; i < 32; ++i) {
        buf.push(getValue(data + i, "i8"));
    }
    postMessage({cmd: "write_device", data: buf});
}

function vialgluejs_unlock_start(data, size, width, height) {
    var buf = []
    for (var i = 0; i < size; ++i) {
        buf.push(getValue(data + i, "i8"));
    }
    postMessage({cmd: "unlock_start", data: buf, width: width, height: height});
}

var window = {};
window.open = function() {};
