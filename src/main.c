#define PY_SSIZE_T_CLEAN

#include "Python.h"

#include <emscripten.h>
#include <emscripten/threading.h>

static PyMethodDef PyQt5Methods[] = {
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef PyQt5 = {
    PyModuleDef_HEAD_INIT,
    "PyQt5",
    0,
    -1,
    PyQt5Methods
};

PyMODINIT_FUNC PyInit_PyQt5(void) {
    PyObject *mod = PyModule_Create(&PyQt5);
    PyModule_AddObject(mod, "__path__", Py_BuildValue("()"));
    return mod;
}

extern PyObject *PyInit_sip();
extern PyObject *PyInit_QtCore();
extern PyObject *PyInit_QtGui();
extern PyObject *PyInit_QtWidgets();
void execLastQApp();

static volatile int glue_error, glue_ready;
static uint8_t glue_response[32];

static PyObject * vialglue_write_device(PyObject *self, PyObject *args) {
    const uint8_t *data;
    Py_ssize_t size;

    if (!PyArg_ParseTuple(args, "y#", &data, &size))
        return NULL;

    if (size != 33)
        return NULL;

    // printf("request to send data of size %d starting with %02X %02X %02X %02X\n", size, data[0], data[1], data[2], data[3]);

    glue_ready = 0;

    EM_ASM({
        vialgluejs_write_device($0);
    }, data + 1);


    return PyLong_FromLong(33); // TODO: wait until successfully sent?
}

static PyObject * vialglue_read_device(PyObject *self, PyObject *args) {
    while (!glue_ready) {
        // usleep(5); // spinlock is way more responsive, esp. in matrix tester
    }

    size_t len = sizeof(glue_response);

    if (glue_error)
        len = 0;

    return PyBytes_FromStringAndSize(glue_response, len);
}

void vialglue_set_response(uint8_t *data) {
    memcpy(glue_response, data, sizeof(glue_response));

    glue_error = 0;
    glue_ready = 1;
}

void vialglue_set_response_error(uint8_t *data) {
    glue_error = 1;
    glue_ready = 1;
}

const char *g_device_desc;

void vialglue_set_device_desc(const char *s) {
    g_device_desc = s;
}

static PyObject * vialglue_unlock_start(PyObject *self, PyObject *args) {
    const uint8_t *data;
    Py_ssize_t size;
    unsigned long width, height;

    if (!PyArg_ParseTuple(args, "y#kk", &data, &size, &width, &height))
        return NULL;

    EM_ASM({
        vialgluejs_unlock_start($0, $1, $2, $3);
    }, data, size, width, height);

    return PyLong_FromLong(0);
}

static PyObject * vialglue_unlock_status(PyObject *self, PyObject *args) {
    unsigned long status;

    if (!PyArg_ParseTuple(args, "k", &status))
        return NULL;

    EM_ASM({
        postMessage({cmd: "unlock_status", data: $0});
    }, status);

    return PyLong_FromLong(0);
}

static PyObject * vialglue_unlock_done(PyObject *self, PyObject *args) {
    EM_ASM({
        postMessage({cmd: "unlock_done"});
    });

    return PyLong_FromLong(0);
}

static PyObject * vialglue_notify_ready(PyObject *self, PyObject *args) {
    EM_ASM({
        postMessage({cmd: "notify_ready"});
    });

    return PyLong_FromLong(0);
}

static PyObject* vialglue_get_device_desc(PyObject *self, PyObject *args) {
    return PyUnicode_FromString(g_device_desc);
}

static PyObject* vialglue_fatal_error(PyObject *self, PyObject *args) {
    const char *msg;

    if (!PyArg_ParseTuple(args, "s", &msg))
        return NULL;

    EM_ASM({
        postMessage({cmd: "fatal_error", msg: UTF8ToString($0)});
    }, msg);

    return PyLong_FromLong(0);
}

static PyMethodDef VialglueMethods[] = {
    {"write_device",  vialglue_write_device, METH_VARARGS, ""},
    {"read_device",  vialglue_read_device, METH_VARARGS, ""},
    {"unlock_start",  vialglue_unlock_start, METH_VARARGS, ""},
    {"unlock_status",  vialglue_unlock_status, METH_VARARGS, ""},
    {"unlock_done",  vialglue_unlock_done, METH_VARARGS, ""},
    {"notify_ready",  vialglue_notify_ready, METH_VARARGS, ""},
    {"get_device_desc",  vialglue_get_device_desc, METH_VARARGS, ""},
    {"fatal_error",  vialglue_fatal_error, METH_VARARGS, ""},
    {NULL, NULL, 0, NULL}
};


static struct PyModuleDef vialgluemodule = {
    PyModuleDef_HEAD_INIT,
    "vialglue",
    NULL,
    -1,
    VialglueMethods
};

PyMODINIT_FUNC PyInit_vialglue(void) {
    return PyModule_Create(&vialgluemodule);
}

int main(int argc, char **argv) {
    PyImport_AppendInittab("vialglue", PyInit_vialglue);
    PyImport_AppendInittab("PyQt5", PyInit_PyQt5);
    PyImport_AppendInittab("PyQt5.sip", PyInit_sip);
    PyImport_AppendInittab("PyQt5.Qt", PyInit_QtCore);
    PyImport_AppendInittab("PyQt5.QtCore", PyInit_QtCore);
    PyImport_AppendInittab("PyQt5.QtGui", PyInit_QtGui);
    PyImport_AppendInittab("PyQt5.QtWidgets", PyInit_QtWidgets);

    Py_Initialize();

    // Fix import system to accommodate the shallow PyQt5 mock module
    // Thanks to dgym @ https://stackoverflow.com/questions/39250524/programmatically-define-a-package-structure-in-embedded-python-3
    PyRun_SimpleString(
        "from importlib import abc, machinery \n" \
        "import sys\n" \
        "\n" \
        "class Finder(abc.MetaPathFinder):\n" \
        "    def find_spec(self, fullname, path, target=None):\n" \
        "        if fullname in sys.builtin_module_names:\n" \
        "            return machinery.ModuleSpec(fullname, machinery.BuiltinImporter)\n" \
        "\n" \
        "sys.meta_path.append(Finder())\n" \
    );

    PyRun_SimpleString("from PyQt5.QtWidgets import QApplication\nqtApp = QApplication([\"pyodide\"])\n");

    EM_ASM({
        postMessage({cmd: "notify_alive"});
    });
    execLastQApp();

    return 0;
}
