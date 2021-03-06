/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
%module cproton
%{
/* Includes the header in the wrapper code */
#if defined(_WIN32) && ! defined(__CYGWIN__)
#include <winsock2.h>
#endif
#include <proton/engine.h>
#include <proton/url.h>
#include <proton/message.h>
#include <proton/sasl.h>
#include <proton/messenger.h>
#include <proton/ssl.h>
#include <proton/reactor.h>
#include <proton/handlers.h>
%}

%include <cstring.i>

%cstring_output_withsize(char *OUTPUT, size_t *OUTPUT_SIZE)
%cstring_output_allocate_size(char **ALLOC_OUTPUT, size_t *ALLOC_SIZE, free(*$1));
%cstring_output_maxsize(char *OUTPUT, size_t MAX_OUTPUT_SIZE)

// These are not used/needed in the python binding
%ignore pn_message_get_id;
%ignore pn_message_set_id;
%ignore pn_message_get_correlation_id;
%ignore pn_message_set_correlation_id;

%typemap(in) pn_bytes_t {
  if ($input == Py_None) {
    $1.start = NULL;
    $1.size = 0;
  } else {
    $1.start = PyString_AsString($input);
    if (!$1.start) {
      return NULL;
    }
    $1.size = PyString_Size($input);
  }
}

%typemap(out) pn_bytes_t {
  $result = PyString_FromStringAndSize($1.start, $1.size);
}

%typemap(out) pn_delivery_tag_t {
  $result = PyString_FromStringAndSize($1.bytes, $1.size);
}

%typemap(in) pn_uuid_t {
  memset($1.bytes, 0, 16);
  if ($input == Py_None) {
    ; // Already zeroed out
  } else {
    const char* b = PyString_AsString($input);
    if (b) {
        memmove($1.bytes, b, (PyString_Size($input) < 16 ? PyString_Size($input) : 16));
    } else {
        return NULL;
    }
  }
}

%typemap(out) pn_uuid_t {
  $result = PyString_FromStringAndSize($1.bytes, 16);
}

%apply pn_uuid_t { pn_decimal128_t };

int pn_message_encode(pn_message_t *msg, char *OUTPUT, size_t *OUTPUT_SIZE);
%ignore pn_message_encode;

ssize_t pn_link_send(pn_link_t *transport, char *STRING, size_t LENGTH);
%ignore pn_link_send;

%rename(pn_link_recv) wrap_pn_link_recv;
%inline %{
  int wrap_pn_link_recv(pn_link_t *link, char *OUTPUT, size_t *OUTPUT_SIZE) {
    ssize_t sz = pn_link_recv(link, OUTPUT, *OUTPUT_SIZE);
    if (sz >= 0) {
      *OUTPUT_SIZE = sz;
    } else {
      *OUTPUT_SIZE = 0;
    }
    return sz;
  }
%}
%ignore pn_link_recv;

ssize_t pn_transport_push(pn_transport_t *transport, char *STRING, size_t LENGTH);
%ignore pn_transport_push;

%rename(pn_transport_peek) wrap_pn_transport_peek;
%inline %{
  int wrap_pn_transport_peek(pn_transport_t *transport, char *OUTPUT, size_t *OUTPUT_SIZE) {
    ssize_t sz = pn_transport_peek(transport, OUTPUT, *OUTPUT_SIZE);
    if (sz >= 0) {
      *OUTPUT_SIZE = sz;
    } else {
      *OUTPUT_SIZE = 0;
    }
    return sz;
  }
%}
%ignore pn_transport_peek;

%rename(pn_delivery) wrap_pn_delivery;
%inline %{
  pn_delivery_t *wrap_pn_delivery(pn_link_t *link, char *STRING, size_t LENGTH) {
    return pn_delivery(link, pn_dtag(STRING, LENGTH));
  }
%}
%ignore pn_delivery;

%rename(pn_delivery_tag) wrap_pn_delivery_tag;
%inline %{
  void wrap_pn_delivery_tag(pn_delivery_t *delivery, char **ALLOC_OUTPUT, size_t *ALLOC_SIZE) {
    pn_delivery_tag_t tag = pn_delivery_tag(delivery);
    *ALLOC_OUTPUT = (char *) malloc(tag.size);
    *ALLOC_SIZE = tag.size;
    memcpy(*ALLOC_OUTPUT, tag.start, tag.size);
  }
%}
%ignore pn_delivery_tag;

ssize_t pn_data_decode(pn_data_t *data, char *STRING, size_t LENGTH);
%ignore pn_data_decode;

%rename(pn_data_encode) wrap_pn_data_encode;
%inline %{
  int wrap_pn_data_encode(pn_data_t *data, char *OUTPUT, size_t *OUTPUT_SIZE) {
    ssize_t sz = pn_data_encode(data, OUTPUT, *OUTPUT_SIZE);
    if (sz >= 0) {
      *OUTPUT_SIZE = sz;
    } else {
      *OUTPUT_SIZE = 0;
    }
    return sz;
  }
%}
%ignore pn_data_encode;

%rename(pn_sasl_recv) wrap_pn_sasl_recv;
%inline %{
  int wrap_pn_sasl_recv(pn_sasl_t *sasl, char *OUTPUT, size_t *OUTPUT_SIZE) {
    ssize_t sz = pn_sasl_recv(sasl, OUTPUT, *OUTPUT_SIZE);
    if (sz >= 0) {
      *OUTPUT_SIZE = sz;
    } else {
      *OUTPUT_SIZE = 0;
    }
    return sz;
  }
%}
%ignore pn_sasl_recv;

int pn_data_format(pn_data_t *data, char *OUTPUT, size_t *OUTPUT_SIZE);
%ignore pn_data_format;

bool pn_ssl_get_cipher_name(pn_ssl_t *ssl, char *OUTPUT, size_t MAX_OUTPUT_SIZE);
%ignore pn_ssl_get_cipher_name;

bool pn_ssl_get_protocol_name(pn_ssl_t *ssl, char *OUTPUT, size_t MAX_OUTPUT_SIZE);
%ignore pn_ssl_get_protocol_name;

int pn_ssl_get_peer_hostname(pn_ssl_t *ssl, char *OUTPUT, size_t *OUTPUT_SIZE);
%ignore pn_ssl_get_peer_hostname;

%immutable PN_PYREF;
%inline %{
  extern const pn_class_t *PN_PYREF;

  #define CID_pn_pyref CID_pn_void
  #define pn_pyref_new NULL
  #define pn_pyref_initialize NULL
  #define pn_pyref_finalize NULL
  #define pn_pyref_free NULL
  #define pn_pyref_hashcode pn_void_hashcode
  #define pn_pyref_compare pn_void_compare
  #define pn_pyref_inspect pn_void_inspect

  static void pn_pyref_incref(void *object) {
    PyObject* p = (PyObject*) object;
    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
    Py_XINCREF(p);
    SWIG_PYTHON_THREAD_END_BLOCK;
  }

  static void pn_pyref_decref(void *object) {
    PyObject* p = (PyObject*) object;
    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
    Py_XDECREF(p);
    SWIG_PYTHON_THREAD_END_BLOCK;
  }

  static int pn_pyref_refcount(void *object) {
    return 1;
  }

  static const pn_class_t *pn_pyref_reify(void *object) {
    return PN_PYREF;
  }

  const pn_class_t PNI_PYREF = PN_METACLASS(pn_pyref);
  const pn_class_t *PN_PYREF = &PNI_PYREF;

  void *pn_py2void(PyObject *object) {
    return object;
  }

  PyObject *pn_void2py(void *object) {
    if (object) {
      PyObject* p = (PyObject*) object;
      SWIG_PYTHON_THREAD_BEGIN_BLOCK;
      Py_INCREF(p);
      SWIG_PYTHON_THREAD_END_BLOCK;
      return p;
    } else {
      Py_RETURN_NONE;
    }
  }

  PyObject *pn_cast_pn_void(void *object) {
    return pn_void2py(object);
  }

  typedef struct {
    PyObject *handler;
    PyObject *dispatch;
    PyObject *exception;
  } pni_pyh_t;

  static pni_pyh_t *pni_pyh(pn_handler_t *handler) {
    return (pni_pyh_t *) pn_handler_mem(handler);
  }

  static void pni_pyh_finalize(pn_handler_t *handler) {
    pni_pyh_t *pyh = pni_pyh(handler);
    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
    Py_DECREF(pyh->handler);
    Py_DECREF(pyh->dispatch);
    Py_DECREF(pyh->exception);
    SWIG_PYTHON_THREAD_END_BLOCK;
  }

  static void pni_pydispatch(pn_handler_t *handler, pn_event_t *event, pn_event_type_t type) {
    pni_pyh_t *pyh = pni_pyh(handler);
    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
    PyObject *arg = SWIG_NewPointerObj(event, SWIGTYPE_p_pn_event_t, 0);
    PyObject *pytype = PyInt_FromLong(type);
    PyObject *result = PyObject_CallMethodObjArgs(pyh->handler, pyh->dispatch, arg, pytype, NULL);
    if (!result) {
      PyObject *exc, *val, *tb;
      PyErr_Fetch(&exc, &val, &tb);
      PyErr_NormalizeException(&exc, &val, &tb);
      if (!val) {
        val = Py_None;
        Py_INCREF(val);
      }
      if (!tb) {
        tb = Py_None;
        Py_INCREF(tb);
      }
      PyObject *result2 = PyObject_CallMethodObjArgs(pyh->handler, pyh->exception, exc, val, tb, NULL);
      if (!result2) {
        PyErr_PrintEx(true);
      }
      Py_XDECREF(result2);
      Py_XDECREF(exc);
      Py_XDECREF(val);
      Py_XDECREF(tb);
    }
    Py_XDECREF(arg);
    Py_XDECREF(pytype);
    Py_XDECREF(result);
    SWIG_PYTHON_THREAD_END_BLOCK;
  }

  pn_handler_t *pn_pyhandler(PyObject *handler) {
    pn_handler_t *chandler = pn_handler_new(pni_pydispatch, sizeof(pni_pyh_t), pni_pyh_finalize);
    pni_pyh_t *phy = pni_pyh(chandler);
    phy->handler = handler;
    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
    phy->dispatch = PyString_FromString("dispatch");
    phy->exception = PyString_FromString("exception");
    Py_INCREF(phy->handler);
    SWIG_PYTHON_THREAD_END_BLOCK;
    return chandler;
  }
%}

%include "proton/cproton.i"
