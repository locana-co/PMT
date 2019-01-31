(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
'use strict';

// lightweight Buffer shim for pbf browser build
// based on code from github.com/feross/buffer (MIT-licensed)

module.exports = Buffer;

var ieee754 = require('ieee754');

var BufferMethods;

function Buffer(length) {
    var arr;
    if (length && length.length) {
        arr = length;
        length = arr.length;
    }
    var buf = new Uint8Array(length || 0);
    if (arr) buf.set(arr);

    buf.readUInt32LE = BufferMethods.readUInt32LE;
    buf.writeUInt32LE = BufferMethods.writeUInt32LE;
    buf.readInt32LE = BufferMethods.readInt32LE;
    buf.writeInt32LE = BufferMethods.writeInt32LE;
    buf.readFloatLE = BufferMethods.readFloatLE;
    buf.writeFloatLE = BufferMethods.writeFloatLE;
    buf.readDoubleLE = BufferMethods.readDoubleLE;
    buf.writeDoubleLE = BufferMethods.writeDoubleLE;
    buf.toString = BufferMethods.toString;
    buf.write = BufferMethods.write;
    buf.slice = BufferMethods.slice;
    buf.copy = BufferMethods.copy;

    buf._isBuffer = true;
    return buf;
}

var lastStr, lastStrEncoded;

BufferMethods = {
    readUInt32LE: function(pos) {
        return ((this[pos]) |
            (this[pos + 1] << 8) |
            (this[pos + 2] << 16)) +
            (this[pos + 3] * 0x1000000);
    },

    writeUInt32LE: function(val, pos) {
        this[pos] = val;
        this[pos + 1] = (val >>> 8);
        this[pos + 2] = (val >>> 16);
        this[pos + 3] = (val >>> 24);
    },

    readInt32LE: function(pos) {
        return ((this[pos]) |
            (this[pos + 1] << 8) |
            (this[pos + 2] << 16)) +
            (this[pos + 3] << 24);
    },

    readFloatLE:  function(pos) { return ieee754.read(this, pos, true, 23, 4); },
    readDoubleLE: function(pos) { return ieee754.read(this, pos, true, 52, 8); },

    writeFloatLE:  function(val, pos) { return ieee754.write(this, val, pos, true, 23, 4); },
    writeDoubleLE: function(val, pos) { return ieee754.write(this, val, pos, true, 52, 8); },

    toString: function(encoding, start, end) {
        var str = '',
            tmp = '';

        start = start || 0;
        end = Math.min(this.length, end || this.length);

        for (var i = start; i < end; i++) {
            var ch = this[i];
            if (ch <= 0x7F) {
                str += decodeURIComponent(tmp) + String.fromCharCode(ch);
                tmp = '';
            } else {
                tmp += '%' + ch.toString(16);
            }
        }

        str += decodeURIComponent(tmp);

        return str;
    },

    write: function(str, pos) {
        var bytes = str === lastStr ? lastStrEncoded : encodeString(str);
        for (var i = 0; i < bytes.length; i++) {
            this[pos + i] = bytes[i];
        }
    },

    slice: function(start, end) {
        return this.subarray(start, end);
    },

    copy: function(buf, pos) {
        pos = pos || 0;
        for (var i = 0; i < this.length; i++) {
            buf[pos + i] = this[i];
        }
    }
};

BufferMethods.writeInt32LE = BufferMethods.writeUInt32LE;

Buffer.byteLength = function(str) {
    lastStr = str;
    lastStrEncoded = encodeString(str);
    return lastStrEncoded.length;
};

Buffer.isBuffer = function(buf) {
    return !!(buf && buf._isBuffer);
};

function encodeString(str) {
    var length = str.length,
        bytes = [];

    for (var i = 0, c, lead; i < length; i++) {
        c = str.charCodeAt(i); // code point

        if (c > 0xD7FF && c < 0xE000) {

            if (lead) {
                if (c < 0xDC00) {
                    bytes.push(0xEF, 0xBF, 0xBD);
                    lead = c;
                    continue;

                } else {
                    c = lead - 0xD800 << 10 | c - 0xDC00 | 0x10000;
                    lead = null;
                }

            } else {
                if (c > 0xDBFF || (i + 1 === length)) bytes.push(0xEF, 0xBF, 0xBD);
                else lead = c;

                continue;
            }

        } else if (lead) {
            bytes.push(0xEF, 0xBF, 0xBD);
            lead = null;
        }

        if (c < 0x80) bytes.push(c);
        else if (c < 0x800) bytes.push(c >> 0x6 | 0xC0, c & 0x3F | 0x80);
        else if (c < 0x10000) bytes.push(c >> 0xC | 0xE0, c >> 0x6 & 0x3F | 0x80, c & 0x3F | 0x80);
        else bytes.push(c >> 0x12 | 0xF0, c >> 0xC & 0x3F | 0x80, c >> 0x6 & 0x3F | 0x80, c & 0x3F | 0x80);
    }
    return bytes;
}

},{"ieee754":3}],2:[function(require,module,exports){
(function (global){
'use strict';

module.exports = Pbf;

var Buffer = global.Buffer || require('./buffer');

function Pbf(buf) {
    this.buf = !Buffer.isBuffer(buf) ? new Buffer(buf || 0) : buf;
    this.pos = 0;
    this.length = this.buf.length;
}

Pbf.Varint  = 0; // varint: int32, int64, uint32, uint64, sint32, sint64, bool, enum
Pbf.Fixed64 = 1; // 64-bit: double, fixed64, sfixed64
Pbf.Bytes   = 2; // length-delimited: string, bytes, embedded messages, packed repeated fields
Pbf.Fixed32 = 5; // 32-bit: float, fixed32, sfixed32

var SHIFT_LEFT_32 = (1 << 16) * (1 << 16),
    SHIFT_RIGHT_32 = 1 / SHIFT_LEFT_32,
    POW_2_63 = Math.pow(2, 63);

Pbf.prototype = {

    destroy: function() {
        this.buf = null;
    },

    // === READING =================================================================

    readFields: function(readField, result, end) {
        end = end || this.length;

        while (this.pos < end) {
            var val = this.readVarint(),
                tag = val >> 3,
                startPos = this.pos;

            readField(tag, result, this);

            if (this.pos === startPos) this.skip(val);
        }
        return result;
    },

    readMessage: function(readField, result) {
        return this.readFields(readField, result, this.readVarint() + this.pos);
    },

    readFixed32: function() {
        var val = this.buf.readUInt32LE(this.pos);
        this.pos += 4;
        return val;
    },

    readSFixed32: function() {
        var val = this.buf.readInt32LE(this.pos);
        this.pos += 4;
        return val;
    },

    // 64-bit int handling is based on github.com/dpw/node-buffer-more-ints (MIT-licensed)

    readFixed64: function() {
        var val = this.buf.readUInt32LE(this.pos) + this.buf.readUInt32LE(this.pos + 4) * SHIFT_LEFT_32;
        this.pos += 8;
        return val;
    },

    readSFixed64: function() {
        var val = this.buf.readUInt32LE(this.pos) + this.buf.readInt32LE(this.pos + 4) * SHIFT_LEFT_32;
        this.pos += 8;
        return val;
    },

    readFloat: function() {
        var val = this.buf.readFloatLE(this.pos);
        this.pos += 4;
        return val;
    },

    readDouble: function() {
        var val = this.buf.readDoubleLE(this.pos);
        this.pos += 8;
        return val;
    },

    readVarint: function() {
        var buf = this.buf,
            val, b, b0, b1, b2, b3;

        b0 = buf[this.pos++]; if (b0 < 0x80) return b0;                 b0 = b0 & 0x7f;
        b1 = buf[this.pos++]; if (b1 < 0x80) return b0 | b1 << 7;       b1 = (b1 & 0x7f) << 7;
        b2 = buf[this.pos++]; if (b2 < 0x80) return b0 | b1 | b2 << 14; b2 = (b2 & 0x7f) << 14;
        b3 = buf[this.pos++]; if (b3 < 0x80) return b0 | b1 | b2 | b3 << 21;

        val = b0 | b1 | b2 | (b3 & 0x7f) << 21;

        b = buf[this.pos++]; val += (b & 0x7f) * 0x10000000;         if (b < 0x80) return val;
        b = buf[this.pos++]; val += (b & 0x7f) * 0x800000000;        if (b < 0x80) return val;
        b = buf[this.pos++]; val += (b & 0x7f) * 0x40000000000;      if (b < 0x80) return val;
        b = buf[this.pos++]; val += (b & 0x7f) * 0x2000000000000;    if (b < 0x80) return val;
        b = buf[this.pos++]; val += (b & 0x7f) * 0x100000000000000;  if (b < 0x80) return val;
        b = buf[this.pos++]; val += (b & 0x7f) * 0x8000000000000000; if (b < 0x80) return val;

        throw new Error('Expected varint not more than 10 bytes');
    },

    readVarint64: function() {
        var startPos = this.pos,
            val = this.readVarint();

        if (val < POW_2_63) return val;

        var pos = this.pos - 2;
        while (this.buf[pos] === 0xff) pos--;
        if (pos < startPos) pos = startPos;

        val = 0;
        for (var i = 0; i < pos - startPos + 1; i++) {
            var b = ~this.buf[startPos + i] & 0x7f;
            val += i < 4 ? b << i * 7 : b * Math.pow(2, i * 7);
        }

        return -val - 1;
    },

    readSVarint: function() {
        var num = this.readVarint();
        return num % 2 === 1 ? (num + 1) / -2 : num / 2; // zigzag encoding
    },

    readBoolean: function() {
        return Boolean(this.readVarint());
    },

    readString: function() {
        var end = this.readVarint() + this.pos,
            str = this.buf.toString('utf8', this.pos, end);
        this.pos = end;
        return str;
    },

    readBytes: function() {
        var end = this.readVarint() + this.pos,
            buffer = this.buf.slice(this.pos, end);
        this.pos = end;
        return buffer;
    },

    // verbose for performance reasons; doesn't affect gzipped size

    readPackedVarint: function() {
        var end = this.readVarint() + this.pos, arr = [];
        while (this.pos < end) arr.push(this.readVarint());
        return arr;
    },
    readPackedSVarint: function() {
        var end = this.readVarint() + this.pos, arr = [];
        while (this.pos < end) arr.push(this.readSVarint());
        return arr;
    },
    readPackedBoolean: function() {
        var end = this.readVarint() + this.pos, arr = [];
        while (this.pos < end) arr.push(this.readBoolean());
        return arr;
    },
    readPackedFloat: function() {
        var end = this.readVarint() + this.pos, arr = [];
        while (this.pos < end) arr.push(this.readFloat());
        return arr;
    },
    readPackedDouble: function() {
        var end = this.readVarint() + this.pos, arr = [];
        while (this.pos < end) arr.push(this.readDouble());
        return arr;
    },
    readPackedFixed32: function() {
        var end = this.readVarint() + this.pos, arr = [];
        while (this.pos < end) arr.push(this.readFixed32());
        return arr;
    },
    readPackedSFixed32: function() {
        var end = this.readVarint() + this.pos, arr = [];
        while (this.pos < end) arr.push(this.readSFixed32());
        return arr;
    },
    readPackedFixed64: function() {
        var end = this.readVarint() + this.pos, arr = [];
        while (this.pos < end) arr.push(this.readFixed64());
        return arr;
    },
    readPackedSFixed64: function() {
        var end = this.readVarint() + this.pos, arr = [];
        while (this.pos < end) arr.push(this.readSFixed64());
        return arr;
    },

    skip: function(val) {
        var type = val & 0x7;
        if (type === Pbf.Varint) while (this.buf[this.pos++] > 0x7f) {}
        else if (type === Pbf.Bytes) this.pos = this.readVarint() + this.pos;
        else if (type === Pbf.Fixed32) this.pos += 4;
        else if (type === Pbf.Fixed64) this.pos += 8;
        else throw new Error('Unimplemented type: ' + type);
    },

    // === WRITING =================================================================

    writeTag: function(tag, type) {
        this.writeVarint((tag << 3) | type);
    },

    realloc: function(min) {
        var length = this.length || 16;

        while (length < this.pos + min) length *= 2;

        if (length !== this.length) {
            var buf = new Buffer(length);
            this.buf.copy(buf);
            this.buf = buf;
            this.length = length;
        }
    },

    finish: function() {
        this.length = this.pos;
        this.pos = 0;
        return this.buf.slice(0, this.length);
    },

    writeFixed32: function(val) {
        this.realloc(4);
        this.buf.writeUInt32LE(val, this.pos);
        this.pos += 4;
    },

    writeSFixed32: function(val) {
        this.realloc(4);
        this.buf.writeInt32LE(val, this.pos);
        this.pos += 4;
    },

    writeFixed64: function(val) {
        this.realloc(8);
        this.buf.writeInt32LE(val & -1, this.pos);
        this.buf.writeUInt32LE(Math.floor(val * SHIFT_RIGHT_32), this.pos + 4);
        this.pos += 8;
    },

    writeSFixed64: function(val) {
        this.realloc(8);
        this.buf.writeInt32LE(val & -1, this.pos);
        this.buf.writeInt32LE(Math.floor(val * SHIFT_RIGHT_32), this.pos + 4);
        this.pos += 8;
    },

    writeVarint: function(val) {
        val = +val;

        if (val <= 0x7f) {
            this.realloc(1);
            this.buf[this.pos++] = val;

        } else if (val <= 0x3fff) {
            this.realloc(2);
            this.buf[this.pos++] = ((val >>> 0) & 0x7f) | 0x80;
            this.buf[this.pos++] = ((val >>> 7) & 0x7f);

        } else if (val <= 0x1fffff) {
            this.realloc(3);
            this.buf[this.pos++] = ((val >>> 0) & 0x7f) | 0x80;
            this.buf[this.pos++] = ((val >>> 7) & 0x7f) | 0x80;
            this.buf[this.pos++] = ((val >>> 14) & 0x7f);

        } else if (val <= 0xfffffff) {
            this.realloc(4);
            this.buf[this.pos++] = ((val >>> 0) & 0x7f) | 0x80;
            this.buf[this.pos++] = ((val >>> 7) & 0x7f) | 0x80;
            this.buf[this.pos++] = ((val >>> 14) & 0x7f) | 0x80;
            this.buf[this.pos++] = ((val >>> 21) & 0x7f);

        } else {
            var pos = this.pos;
            while (val >= 0x80) {
                this.realloc(1);
                this.buf[this.pos++] = (val & 0xff) | 0x80;
                val /= 0x80;
            }
            this.realloc(1);
            this.buf[this.pos++] = val | 0;
            if (this.pos - pos > 10) throw new Error('Given varint doesn\'t fit into 10 bytes');
        }
    },

    writeSVarint: function(val) {
        this.writeVarint(val < 0 ? -val * 2 - 1 : val * 2);
    },

    writeBoolean: function(val) {
        this.writeVarint(Boolean(val));
    },

    writeString: function(str) {
        str = String(str);
        var bytes = Buffer.byteLength(str);
        this.writeVarint(bytes);
        this.realloc(bytes);
        this.buf.write(str, this.pos);
        this.pos += bytes;
    },

    writeFloat: function(val) {
        this.realloc(4);
        this.buf.writeFloatLE(val, this.pos);
        this.pos += 4;
    },

    writeDouble: function(val) {
        this.realloc(8);
        this.buf.writeDoubleLE(val, this.pos);
        this.pos += 8;
    },

    writeBytes: function(buffer) {
        var len = buffer.length;
        this.writeVarint(len);
        this.realloc(len);
        for (var i = 0; i < len; i++) this.buf[this.pos++] = buffer[i];
    },

    writeRawMessage: function(fn, obj) {
        this.pos++; // reserve 1 byte for short message length

        // write the message directly to the buffer and see how much was written
        var startPos = this.pos;
        fn(obj, this);
        var len = this.pos - startPos;

        var varintLen =
            len <= 0x7f ? 1 :
            len <= 0x3fff ? 2 :
            len <= 0x1fffff ? 3 :
            len <= 0xfffffff ? 4 : Math.ceil(Math.log(len) / (Math.LN2 * 7));

        // if 1 byte isn't enough for encoding message length, shift the data to the right
        if (varintLen > 1) {
            this.realloc(varintLen - 1);
            for (var i = this.pos - 1; i >= startPos; i--) this.buf[i + varintLen - 1] = this.buf[i];
        }

        // finally, write the message length in the reserved place and restore the position
        this.pos = startPos - 1;
        this.writeVarint(len);
        this.pos += len;
    },

    writeMessage: function(tag, fn, obj) {
        this.writeTag(tag, Pbf.Bytes);
        this.writeRawMessage(fn, obj);
    },

    writePackedVarint:   function(tag, arr) { this.writeMessage(tag, writePackedVarint, arr);   },
    writePackedSVarint:  function(tag, arr) { this.writeMessage(tag, writePackedSVarint, arr);  },
    writePackedBoolean:  function(tag, arr) { this.writeMessage(tag, writePackedBoolean, arr);  },
    writePackedFloat:    function(tag, arr) { this.writeMessage(tag, writePackedFloat, arr);    },
    writePackedDouble:   function(tag, arr) { this.writeMessage(tag, writePackedDouble, arr);   },
    writePackedFixed32:  function(tag, arr) { this.writeMessage(tag, writePackedFixed32, arr);  },
    writePackedSFixed32: function(tag, arr) { this.writeMessage(tag, writePackedSFixed32, arr); },
    writePackedFixed64:  function(tag, arr) { this.writeMessage(tag, writePackedFixed64, arr);  },
    writePackedSFixed64: function(tag, arr) { this.writeMessage(tag, writePackedSFixed64, arr); },

    writeBytesField: function(tag, buffer) {
        this.writeTag(tag, Pbf.Bytes);
        this.writeBytes(buffer);
    },
    writeFixed32Field: function(tag, val) {
        this.writeTag(tag, Pbf.Fixed32);
        this.writeFixed32(val);
    },
    writeSFixed32Field: function(tag, val) {
        this.writeTag(tag, Pbf.Fixed32);
        this.writeSFixed32(val);
    },
    writeFixed64Field: function(tag, val) {
        this.writeTag(tag, Pbf.Fixed64);
        this.writeFixed64(val);
    },
    writeSFixed64Field: function(tag, val) {
        this.writeTag(tag, Pbf.Fixed64);
        this.writeSFixed64(val);
    },
    writeVarintField: function(tag, val) {
        this.writeTag(tag, Pbf.Varint);
        this.writeVarint(val);
    },
    writeSVarintField: function(tag, val) {
        this.writeTag(tag, Pbf.Varint);
        this.writeSVarint(val);
    },
    writeStringField: function(tag, str) {
        this.writeTag(tag, Pbf.Bytes);
        this.writeString(str);
    },
    writeFloatField: function(tag, val) {
        this.writeTag(tag, Pbf.Fixed32);
        this.writeFloat(val);
    },
    writeDoubleField: function(tag, val) {
        this.writeTag(tag, Pbf.Fixed64);
        this.writeDouble(val);
    },
    writeBooleanField: function(tag, val) {
        this.writeVarintField(tag, Boolean(val));
    }
};

function writePackedVarint(arr, pbf)   { for (var i = 0; i < arr.length; i++) pbf.writeVarint(arr[i]);   }
function writePackedSVarint(arr, pbf)  { for (var i = 0; i < arr.length; i++) pbf.writeSVarint(arr[i]);  }
function writePackedFloat(arr, pbf)    { for (var i = 0; i < arr.length; i++) pbf.writeFloat(arr[i]);    }
function writePackedDouble(arr, pbf)   { for (var i = 0; i < arr.length; i++) pbf.writeDouble(arr[i]);   }
function writePackedBoolean(arr, pbf)  { for (var i = 0; i < arr.length; i++) pbf.writeBoolean(arr[i]);  }
function writePackedFixed32(arr, pbf)  { for (var i = 0; i < arr.length; i++) pbf.writeFixed32(arr[i]);  }
function writePackedSFixed32(arr, pbf) { for (var i = 0; i < arr.length; i++) pbf.writeSFixed32(arr[i]); }
function writePackedFixed64(arr, pbf)  { for (var i = 0; i < arr.length; i++) pbf.writeFixed64(arr[i]);  }
function writePackedSFixed64(arr, pbf) { for (var i = 0; i < arr.length; i++) pbf.writeSFixed64(arr[i]); }

}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})

},{"./buffer":1}],3:[function(require,module,exports){
exports.read = function (buffer, offset, isLE, mLen, nBytes) {
  var e, m
  var eLen = nBytes * 8 - mLen - 1
  var eMax = (1 << eLen) - 1
  var eBias = eMax >> 1
  var nBits = -7
  var i = isLE ? (nBytes - 1) : 0
  var d = isLE ? -1 : 1
  var s = buffer[offset + i]

  i += d

  e = s & ((1 << (-nBits)) - 1)
  s >>= (-nBits)
  nBits += eLen
  for (; nBits > 0; e = e * 256 + buffer[offset + i], i += d, nBits -= 8) {}

  m = e & ((1 << (-nBits)) - 1)
  e >>= (-nBits)
  nBits += mLen
  for (; nBits > 0; m = m * 256 + buffer[offset + i], i += d, nBits -= 8) {}

  if (e === 0) {
    e = 1 - eBias
  } else if (e === eMax) {
    return m ? NaN : ((s ? -1 : 1) * Infinity)
  } else {
    m = m + Math.pow(2, mLen)
    e = e - eBias
  }
  return (s ? -1 : 1) * m * Math.pow(2, e - mLen)
}

exports.write = function (buffer, value, offset, isLE, mLen, nBytes) {
  var e, m, c
  var eLen = nBytes * 8 - mLen - 1
  var eMax = (1 << eLen) - 1
  var eBias = eMax >> 1
  var rt = (mLen === 23 ? Math.pow(2, -24) - Math.pow(2, -77) : 0)
  var i = isLE ? 0 : (nBytes - 1)
  var d = isLE ? 1 : -1
  var s = value < 0 || (value === 0 && 1 / value < 0) ? 1 : 0

  value = Math.abs(value)

  if (isNaN(value) || value === Infinity) {
    m = isNaN(value) ? 1 : 0
    e = eMax
  } else {
    e = Math.floor(Math.log(value) / Math.LN2)
    if (value * (c = Math.pow(2, -e)) < 1) {
      e--
      c *= 2
    }
    if (e + eBias >= 1) {
      value += rt / c
    } else {
      value += rt * Math.pow(2, 1 - eBias)
    }
    if (value * c >= 2) {
      e++
      c /= 2
    }

    if (e + eBias >= eMax) {
      m = 0
      e = eMax
    } else if (e + eBias >= 1) {
      m = (value * c - 1) * Math.pow(2, mLen)
      e = e + eBias
    } else {
      m = value * Math.pow(2, eBias - 1) * Math.pow(2, mLen)
      e = 0
    }
  }

  for (; mLen >= 8; buffer[offset + i] = m & 0xff, i += d, m /= 256, mLen -= 8) {}

  e = (e << mLen) | m
  eLen += mLen
  for (; eLen > 0; buffer[offset + i] = e & 0xff, i += d, e /= 256, eLen -= 8) {}

  buffer[offset + i - d] |= s * 128
}

},{}],4:[function(require,module,exports){
'use strict';

module.exports = Point;

function Point(x, y) {
    this.x = x;
    this.y = y;
}

Point.prototype = {
    clone: function() { return new Point(this.x, this.y); },

    add:     function(p) { return this.clone()._add(p);     },
    sub:     function(p) { return this.clone()._sub(p);     },
    mult:    function(k) { return this.clone()._mult(k);    },
    div:     function(k) { return this.clone()._div(k);     },
    rotate:  function(a) { return this.clone()._rotate(a);  },
    matMult: function(m) { return this.clone()._matMult(m); },
    unit:    function() { return this.clone()._unit(); },
    perp:    function() { return this.clone()._perp(); },
    round:   function() { return this.clone()._round(); },

    mag: function() {
        return Math.sqrt(this.x * this.x + this.y * this.y);
    },

    equals: function(p) {
        return this.x === p.x &&
               this.y === p.y;
    },

    dist: function(p) {
        return Math.sqrt(this.distSqr(p));
    },

    distSqr: function(p) {
        var dx = p.x - this.x,
            dy = p.y - this.y;
        return dx * dx + dy * dy;
    },

    angle: function() {
        return Math.atan2(this.y, this.x);
    },

    angleTo: function(b) {
        return Math.atan2(this.y - b.y, this.x - b.x);
    },

    angleWith: function(b) {
        return this.angleWithSep(b.x, b.y);
    },

    // Find the angle of the two vectors, solving the formula for the cross product a x b = |a||b|sin(θ) for θ.
    angleWithSep: function(x, y) {
        return Math.atan2(
            this.x * y - this.y * x,
            this.x * x + this.y * y);
    },

    _matMult: function(m) {
        var x = m[0] * this.x + m[1] * this.y,
            y = m[2] * this.x + m[3] * this.y;
        this.x = x;
        this.y = y;
        return this;
    },

    _add: function(p) {
        this.x += p.x;
        this.y += p.y;
        return this;
    },

    _sub: function(p) {
        this.x -= p.x;
        this.y -= p.y;
        return this;
    },

    _mult: function(k) {
        this.x *= k;
        this.y *= k;
        return this;
    },

    _div: function(k) {
        this.x /= k;
        this.y /= k;
        return this;
    },

    _unit: function() {
        this._div(this.mag());
        return this;
    },

    _perp: function() {
        var y = this.y;
        this.y = this.x;
        this.x = -y;
        return this;
    },

    _rotate: function(angle) {
        var cos = Math.cos(angle),
            sin = Math.sin(angle),
            x = cos * this.x - sin * this.y,
            y = sin * this.x + cos * this.y;
        this.x = x;
        this.y = y;
        return this;
    },

    _round: function() {
        this.x = Math.round(this.x);
        this.y = Math.round(this.y);
        return this;
    }
};

// constructs Point from an array if necessary
Point.convert = function (a) {
    if (a instanceof Point) {
        return a;
    }
    if (Array.isArray(a)) {
        return new Point(a[0], a[1]);
    }
    return a;
};

},{}],5:[function(require,module,exports){
module.exports.VectorTile = require('./lib/vectortile.js');
module.exports.VectorTileFeature = require('./lib/vectortilefeature.js');
module.exports.VectorTileLayer = require('./lib/vectortilelayer.js');

},{"./lib/vectortile.js":6,"./lib/vectortilefeature.js":7,"./lib/vectortilelayer.js":8}],6:[function(require,module,exports){
'use strict';

var VectorTileLayer = require('./vectortilelayer');

module.exports = VectorTile;

function VectorTile(pbf, end) {
    this.layers = pbf.readFields(readTile, {}, end);
}

function readTile(tag, layers, pbf) {
    if (tag === 3) {
        var layer = new VectorTileLayer(pbf, pbf.readVarint() + pbf.pos);
        if (layer.length) layers[layer.name] = layer;
    }
}


},{"./vectortilelayer":8}],7:[function(require,module,exports){
'use strict';

var Point = require('point-geometry');

module.exports = VectorTileFeature;

function VectorTileFeature(pbf, end, extent, keys, values) {
    // Public
    this.properties = {};
    this.extent = extent;
    this.type = 0;

    // Private
    this._pbf = pbf;
    this._geometry = -1;
    this._keys = keys;
    this._values = values;

    pbf.readFields(readFeature, this, end);
}

function readFeature(tag, feature, pbf) {
    if (tag == 1) feature._id = pbf.readVarint();
    else if (tag == 2) readTag(pbf, feature);
    else if (tag == 3) feature.type = pbf.readVarint();
    else if (tag == 4) feature._geometry = pbf.pos;
}

function readTag(pbf, feature) {
    var end = pbf.readVarint() + pbf.pos;

    while (pbf.pos < end) {
        var key = feature._keys[pbf.readVarint()],
            value = feature._values[pbf.readVarint()];
        feature.properties[key] = value;
    }
}

VectorTileFeature.types = ['Unknown', 'Point', 'LineString', 'Polygon'];

VectorTileFeature.prototype.loadGeometry = function() {
    var pbf = this._pbf;
    pbf.pos = this._geometry;

    var end = pbf.readVarint() + pbf.pos,
        cmd = 1,
        length = 0,
        x = 0,
        y = 0,
        lines = [],
        line;

    while (pbf.pos < end) {
        if (!length) {
            var cmdLen = pbf.readVarint();
            cmd = cmdLen & 0x7;
            length = cmdLen >> 3;
        }

        length--;

        if (cmd === 1 || cmd === 2) {
            x += pbf.readSVarint();
            y += pbf.readSVarint();

            if (cmd === 1) { // moveTo
                if (line) lines.push(line);
                line = [];
            }

            line.push(new Point(x, y));

        } else if (cmd === 7) {

            // Workaround for https://github.com/mapbox/mapnik-vector-tile/issues/90
            if (line) {
                line.push(line[0].clone()); // closePolygon
            }

        } else {
            throw new Error('unknown command ' + cmd);
        }
    }

    if (line) lines.push(line);

    return lines;
};

VectorTileFeature.prototype.bbox = function() {
    var pbf = this._pbf;
    pbf.pos = this._geometry;

    var end = pbf.readVarint() + pbf.pos,
        cmd = 1,
        length = 0,
        x = 0,
        y = 0,
        x1 = Infinity,
        x2 = -Infinity,
        y1 = Infinity,
        y2 = -Infinity;

    while (pbf.pos < end) {
        if (!length) {
            var cmdLen = pbf.readVarint();
            cmd = cmdLen & 0x7;
            length = cmdLen >> 3;
        }

        length--;

        if (cmd === 1 || cmd === 2) {
            x += pbf.readSVarint();
            y += pbf.readSVarint();
            if (x < x1) x1 = x;
            if (x > x2) x2 = x;
            if (y < y1) y1 = y;
            if (y > y2) y2 = y;

        } else if (cmd !== 7) {
            throw new Error('unknown command ' + cmd);
        }
    }

    return [x1, y1, x2, y2];
};

VectorTileFeature.prototype.toGeoJSON = function(x, y, z) {
    var size = this.extent * Math.pow(2, z),
        x0 = this.extent * x,
        y0 = this.extent * y,
        coords = this.loadGeometry(),
        type = VectorTileFeature.types[this.type];

    for (var i = 0; i < coords.length; i++) {
        var line = coords[i];
        for (var j = 0; j < line.length; j++) {
            var p = line[j], y2 = 180 - (p.y + y0) * 360 / size;
            line[j] = [
                (p.x + x0) * 360 / size - 180,
                360 / Math.PI * Math.atan(Math.exp(y2 * Math.PI / 180)) - 90
            ];
        }
    }

    if (type === 'Point' && coords.length === 1) {
        coords = coords[0][0];
    } else if (type === 'Point') {
        coords = coords[0];
        type = 'MultiPoint';
    } else if (type === 'LineString' && coords.length === 1) {
        coords = coords[0];
    } else if (type === 'LineString') {
        type = 'MultiLineString';
    }

    return {
        type: "Feature",
        geometry: {
            type: type,
            coordinates: coords
        },
        properties: this.properties
    };
};

},{"point-geometry":4}],8:[function(require,module,exports){
'use strict';

var VectorTileFeature = require('./vectortilefeature.js');

module.exports = VectorTileLayer;

function VectorTileLayer(pbf, end) {
    // Public
    this.version = 1;
    this.name = null;
    this.extent = 4096;
    this.length = 0;

    // Private
    this._pbf = pbf;
    this._keys = [];
    this._values = [];
    this._features = [];

    pbf.readFields(readLayer, this, end);

    this.length = this._features.length;
}

function readLayer(tag, layer, pbf) {
    if (tag === 15) layer.version = pbf.readVarint();
    else if (tag === 1) layer.name = pbf.readString();
    else if (tag === 5) layer.extent = pbf.readVarint();
    else if (tag === 2) layer._features.push(pbf.pos);
    else if (tag === 3) layer._keys.push(pbf.readString());
    else if (tag === 4) layer._values.push(readValueMessage(pbf));
}

function readValueMessage(pbf) {
    var value = null,
        end = pbf.readVarint() + pbf.pos;

    while (pbf.pos < end) {
        var tag = pbf.readVarint() >> 3;

        value = tag === 1 ? pbf.readString() :
            tag === 2 ? pbf.readFloat() :
            tag === 3 ? pbf.readDouble() :
            tag === 4 ? pbf.readVarint64() :
            tag === 5 ? pbf.readVarint() :
            tag === 6 ? pbf.readSVarint() :
            tag === 7 ? pbf.readBoolean() : null;
    }

    return value;
}

// return feature `i` from this layer as a `VectorTileFeature`
VectorTileLayer.prototype.feature = function(i) {
    if (i < 0 || i >= this._features.length) throw new Error('feature index out of bounds');

    this._pbf.pos = this._features[i];

    var end = this._pbf.readVarint() + this._pbf.pos;
    return new VectorTileFeature(this._pbf, end, this.extent, this._keys, this._values);
};

},{"./vectortilefeature.js":7}],9:[function(require,module,exports){
/**
 * Created by Ryan Whitley, Daniel Duarte, and Nicholas Hallahan
 *    on 6/03/14.
 */
var Util = require('./MVTUtil');
var StaticLabel = require('./StaticLabel/StaticLabel.js');

module.exports = MVTFeature;

function MVTFeature(mvtLayer, vtf, ctx, id, style) {
  if (!vtf) return null;

  // Apply all of the properties of vtf to this object.
  for (var key in vtf) {
    this[key] = vtf[key];
  }

  this.mvtLayer = mvtLayer;
  this.mvtSource = mvtLayer.mvtSource;
  this.map = mvtLayer.mvtSource.map;

  this.id = id;

  this.layerLink = this.mvtSource.layerLink;
  this.toggleEnabled = true;
  this.selected = false;

  // how much we divide the coordinate from the vector tile
  this.divisor = vtf.extent / ctx.tileSize;
  this.extent = vtf.extent;
  this.tileSize = ctx.tileSize;

  //An object to store the paths and contexts for this feature
  this.tiles = {};

  this.style = style;

  //Add to the collection
  this.addTileFeature(vtf, ctx);

  var self = this;
  this.map.on('zoomend', function() {
    self.staticLabel = null;
  });

  if (style && style.dynamicLabel && typeof style.dynamicLabel === 'function') {
    this.dynamicLabel = this.mvtSource.dynamicLabel.createFeature(this);
  }

  ajax(self);
}


function ajax(self) {
  var style = self.style;
  if (style && style.ajaxSource && typeof style.ajaxSource === 'function') {
    var ajaxEndpoint = style.ajaxSource(self);
    if (ajaxEndpoint) {
      Util.getJSON(ajaxEndpoint, function(error, response, body) {
        if (error) {
          throw ['ajaxSource AJAX Error', error];
        } else {
          ajaxCallback(self, response);
          return true;
        }
      });
    }
  }
  return false;
}

function ajaxCallback(self, response) {
  self.ajaxData = response;

  /**
   * You can attach a callback function to a feature in your app
   * that will get called whenever new ajaxData comes in. This
   * can be used to update UI that looks at data from within a feature.
   *
   * setStyle may possibly have a style with a different ajaxData source,
   * and you would potentially get new contextual data for your feature.
   *
   * TODO: This needs to be documented.
   */
  if (typeof self.ajaxDataReceived === 'function') {
    self.ajaxDataReceived(self, response);
  }

  self._setStyle(self.mvtLayer.style);
  redrawTiles(self);
}

MVTFeature.prototype._setStyle = function(styleFn) {
  this.style = styleFn(this, this.ajaxData);

  // The label gets removed, and the (re)draw,
  // that is initiated by the MVTLayer creates a new label.
  this.removeLabel();
};

MVTFeature.prototype.setStyle = function(styleFn) {
  this.ajaxData = null;
  this.style = styleFn(this, null);
  var hasAjaxSource = ajax(this);
  if (!hasAjaxSource) {
    // The label gets removed, and the (re)draw,
    // that is initiated by the MVTLayer creates a new label.
    this.removeLabel();
  }
};

MVTFeature.prototype.draw = function(canvasID) {
  //Get the info from the tiles list
  var tileInfo =  this.tiles[canvasID];

  var vtf = tileInfo.vtf;
  var ctx = tileInfo.ctx;

  //Get the actual canvas from the parent layer's _tiles object.
  var xy = canvasID.split(":").slice(1, 3).join(":");
  ctx.canvas = this.mvtLayer._tiles[xy];

//  This could be used to directly compute the style function from the layer on every draw.
//  This is much less efficient...
//  this.style = this.mvtLayer.style(this);

  if (this.selected) {
    var style = this.style.selected || this.style;
  } else {
    var style = this.style;
  }

  switch (vtf.type) {
    case 1: //Point
      this._drawPoint(ctx, vtf.coordinates, style);
      if (!this.staticLabel && typeof this.style.staticLabel === 'function') {
        if (this.style.ajaxSource && !this.ajaxData) {
          break;
        }
        this._drawStaticLabel(ctx, vtf.coordinates, style);
      }
      break;

    case 2: //LineString
      this._drawLineString(ctx, vtf.coordinates, style);
      break;

    case 3: //Polygon
      this._drawPolygon(ctx, vtf.coordinates, style);
      break;

    default:
      throw new Error('Unmanaged type: ' + vtf.type);
  }

};

MVTFeature.prototype.getPathsForTile = function(canvasID) {
  //Get the info from the parts list
  return this.tiles[canvasID].paths;
};

MVTFeature.prototype.addTileFeature = function(vtf, ctx) {
  //Store the important items in the tiles list

  //We only want to store info for tiles for the current map zoom.  If it is tile info for another zoom level, ignore it
  //Also, if there are existing tiles in the list for other zoom levels, expunge them.
  var zoom = this.map.getZoom();

  if(ctx.zoom != zoom) return;

  this.clearTileFeatures(zoom); //TODO: This iterates thru all tiles every time a new tile is added.  Figure out a better way to do this.

  this.tiles[ctx.id] = {
    ctx: ctx,
    vtf: vtf,
    paths: []
  };

};


/**
 * Clear the inner list of tile features if they don't match the given zoom.
 *
 * @param zoom
 */
MVTFeature.prototype.clearTileFeatures = function(zoom) {
  //If stored tiles exist for other zoom levels, expunge them from the list.
  for (var key in this.tiles) {
     if(key.split(":")[0] != zoom) delete this.tiles[key];
  }
};

/**
 * Redraws all of the tiles associated with a feature. Useful for
 * style change and toggling.
 *
 * @param self
 */
function redrawTiles(self) {
  //Redraw the whole tile, not just this vtf
  var tiles = self.tiles;
  var mvtLayer = self.mvtLayer;

  for (var id in tiles) {
    var tileZoom = parseInt(id.split(':')[0]);
    var mapZoom = self.map.getZoom();
    if (tileZoom === mapZoom) {
      //Redraw the tile
      mvtLayer.redrawTile(id);
    }
  }
}

MVTFeature.prototype.toggle = function() {
  if (this.selected) {
    this.deselect();
  } else {
    this.select();
  }
};

MVTFeature.prototype.select = function () {
  this.selected = true;
  this.mvtSource.featureSelected(this);
  redrawTiles(this);
  var linkedFeature = this.linkedFeature();
  if (linkedFeature && linkedFeature.staticLabel && !linkedFeature.staticLabel.selected) {
    linkedFeature.staticLabel.select();
  }
};

MVTFeature.prototype.deselect = function() {
  this.selected = false;
  this.mvtSource.featureDeselected(this);
  redrawTiles(this);
  var linkedFeature = this.linkedFeature();
  if (linkedFeature && linkedFeature.staticLabel && linkedFeature.staticLabel.selected) {
    linkedFeature.staticLabel.deselect();
  }
};

MVTFeature.prototype.on = function(eventType, callback) {
  this._eventHandlers[eventType] = callback;
};

MVTFeature.prototype._drawPoint = function(ctx, coordsArray, style) {
  if (!style) return;
  if (!ctx || !ctx.canvas) return;

  var tile = this.tiles[ctx.id];

  //Get radius
  var radius = 1;
  if (typeof style.radius === 'function') {
    radius = style.radius(ctx.zoom); //Allows for scale dependent rednering
  }
  else{
    radius = style.radius;
  }

  var p = this._tilePoint(coordsArray[0][0]);
  var c = ctx.canvas;
  var ctx2d;
  try{
    ctx2d = c.getContext('2d');
  }
  catch(e){
    console.log("_drawPoint error: " + e);
    return;
  }

  ctx2d.beginPath();
  ctx2d.fillStyle = style.color;
  ctx2d.arc(p.x, p.y, radius, 0, Math.PI * 2);
  ctx2d.closePath();
  ctx2d.fill();

  if(style.lineWidth && style.strokeStyle){
    ctx2d.lineWidth = style.lineWidth;
    ctx2d.strokeStyle = style.strokeStyle;
    ctx2d.stroke();
  }

  ctx2d.restore();
  tile.paths.push([p]);
};

MVTFeature.prototype._drawLineString = function(ctx, coordsArray, style) {
  if (!style) return;
  if (!ctx || !ctx.canvas) return;

  var ctx2d = ctx.canvas.getContext('2d');
  ctx2d.strokeStyle = style.color;
  ctx2d.lineWidth = style.size;
  ctx2d.beginPath();

  var projCoords = [];
  var tile = this.tiles[ctx.id];

  for (var gidx in coordsArray) {
    var coords = coordsArray[gidx];

    for (i = 0; i < coords.length; i++) {
      var method = (i === 0 ? 'move' : 'line') + 'To';
      var proj = this._tilePoint(coords[i]);
      projCoords.push(proj);
      ctx2d[method](proj.x, proj.y);
    }
  }

  ctx2d.stroke();
  ctx2d.restore();

  tile.paths.push(projCoords);
};

MVTFeature.prototype._drawPolygon = function(ctx, coordsArray, style) {
  if (!style) return;
  if (!ctx || !ctx.canvas) return;

  var ctx2d = ctx.canvas.getContext('2d');
  var outline = style.outline;

  // color may be defined via function to make choropleth work right
  if (typeof style.color === 'function') {
    ctx2d.fillStyle = style.color(ctx2d);
  } else {
    ctx2d.fillStyle = style.color;
  }

  if (outline) {
    ctx2d.strokeStyle = outline.color;
    ctx2d.lineWidth = outline.size;
  }
  ctx2d.beginPath();

  var projCoords = [];
  var tile = this.tiles[ctx.id];

  var featureLabel = this.dynamicLabel;
  if (featureLabel) {
    featureLabel.addTilePolys(ctx, coordsArray);
  }

  for (var gidx = 0, len = coordsArray.length; gidx < len; gidx++) {
    var coords = coordsArray[gidx];

    for (var i = 0; i < coords.length; i++) {
      var coord = coords[i];
      var method = (i === 0 ? 'move' : 'line') + 'To';
      var proj = this._tilePoint(coords[i]);
      projCoords.push(proj);
      ctx2d[method](proj.x, proj.y);
    }
  }

  ctx2d.closePath();
  ctx2d.fill();
  if (outline) {
    ctx2d.stroke();
  }

  tile.paths.push(projCoords);

};

MVTFeature.prototype._drawStaticLabel = function(ctx, coordsArray, style) {
  if (!style) return;
  if (!ctx) return;

  // If the corresponding layer is not on the map, 
  // we dont want to put on a label.
  if (!this.mvtLayer._map) return;

  var vecPt = this._tilePoint(coordsArray[0][0]);

  // We're making a standard Leaflet Marker for this label.
  var p = this._project(vecPt, ctx.tile.x, ctx.tile.y, this.extent, this.tileSize); //vectile pt to merc pt
  var mercPt = L.point(p.x, p.y); // make into leaflet obj
  var latLng = this.map.unproject(mercPt); // merc pt to latlng

  this.staticLabel = new StaticLabel(this, ctx, latLng, style);
  this.mvtLayer.featureWithLabelAdded(this);
};

MVTFeature.prototype.removeLabel = function() {
  if (!this.staticLabel) return;
  this.staticLabel.remove();
  this.staticLabel = null;
};

/**
 * Projects a vector tile point to the Spherical Mercator pixel space for a given zoom level.
 *
 * @param vecPt
 * @param tileX
 * @param tileY
 * @param extent
 * @param tileSize
 */
MVTFeature.prototype._project = function(vecPt, tileX, tileY, extent, tileSize) {
  var xOffset = tileX * tileSize;
  var yOffset = tileY * tileSize;
  return {
    x: Math.floor(vecPt.x + xOffset),
    y: Math.floor(vecPt.y + yOffset)
  };
};

/**
 * Takes a coordinate from a vector tile and turns it into a Leaflet Point.
 *
 * @param ctx
 * @param coords
 * @returns {eGeomType.Point}
 * @private
 */
MVTFeature.prototype._tilePoint = function(coords) {
  return new L.Point(coords.x / this.divisor, coords.y / this.divisor);
};

MVTFeature.prototype.linkedFeature = function() {
  var linkedLayer = this.mvtLayer.linkedLayer();
  if(linkedLayer){
    var linkedFeature = linkedLayer.features[this.id];
    return linkedFeature;
  }else{
    return null;
  }
};


},{"./MVTUtil":12,"./StaticLabel/StaticLabel.js":13}],10:[function(require,module,exports){
/**
 * Created by Ryan Whitley on 5/17/14.
 */
/** Forked from https://gist.github.com/DGuidi/1716010 **/
var MVTFeature = require('./MVTFeature');
var Util = require('./MVTUtil');

module.exports = L.TileLayer.Canvas.extend({

    options: {
        debug: false,
        isHiddenLayer: false,
        getIDForLayerFeature: function () { },
        tileSize: 256,
        lineClickTolerance: 2
    },

    _featureIsClicked: {},

    _isPointInPoly: function (pt, poly) {
        if (poly && poly.length) {
            for (var c = false, i = -1, l = poly.length, j = l - 1; ++i < l; j = i)
                ((poly[i].y <= pt.y && pt.y < poly[j].y) || (poly[j].y <= pt.y && pt.y < poly[i].y))
                && (pt.x < (poly[j].x - poly[i].x) * (pt.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x)
                && (c = !c);
            return c;
        }
    },

    _getDistanceFromLine: function (pt, pts) {
        var min = Number.POSITIVE_INFINITY;
        if (pts && pts.length > 1) {
            pt = L.point(pt.x, pt.y);
            for (var i = 0, l = pts.length - 1; i < l; i++) {
                var test = this._projectPointOnLineSegment(pt, pts[i], pts[i + 1]);
                if (test.distance <= min) {
                    min = test.distance;
                }
            }
        }
        return min;
    },

    _projectPointOnLineSegment: function (p, r0, r1) {
        var lineLength = r0.distanceTo(r1);
        if (lineLength < 1) {
            return { distance: p.distanceTo(r0), coordinate: r0 };
        }
        var u = ((p.x - r0.x) * (r1.x - r0.x) + (p.y - r0.y) * (r1.y - r0.y)) / Math.pow(lineLength, 2);
        if (u < 0.0000001) {
            return { distance: p.distanceTo(r0), coordinate: r0 };
        }
        if (u > 0.9999999) {
            return { distance: p.distanceTo(r1), coordinate: r1 };
        }
        var a = L.point(r0.x + u * (r1.x - r0.x), r0.y + u * (r1.y - r0.y));
        return { distance: p.distanceTo(a), point: a };
    },

    initialize: function (mvtSource, options) {
        var self = this;
        self.mvtSource = mvtSource;
        L.Util.setOptions(this, options);

        this.style = options.style;
        this.name = options.name;
        this._canvasIDToFeatures = {};
        this.features = {};
        this.featuresWithLabels = [];
        this._highestCount = 0;
    },

    onAdd: function (map) {
        var self = this;
        self.map = map;
        L.TileLayer.Canvas.prototype.onAdd.call(this, map);
        map.on('layerremove', function (e) {
            // we only want to do stuff when the layerremove event is on this layer
            if (e.layer._leaflet_id === self._leaflet_id) {
                removeLabels(self);
            }
        });
    },

    drawTile: function (canvas, tilePoint, zoom) {

        var ctx = {
            canvas: canvas,
            tile: tilePoint,
            zoom: zoom,
            tileSize: this.options.tileSize
        };

        ctx.id = Util.getContextID(ctx);

        if (!this._canvasIDToFeatures[ctx.id]) {
            this._initializeFeaturesHash(ctx);
        }
        if (!this.features) {
            this.features = {};
        }

    },

    _initializeFeaturesHash: function (ctx) {
        this._canvasIDToFeatures[ctx.id] = {};
        this._canvasIDToFeatures[ctx.id].features = [];
        this._canvasIDToFeatures[ctx.id].canvas = ctx.canvas;
    },

    _draw: function (ctx) {
        //Draw is handled by the parent MVTSource object
    },
    getCanvas: function (parentCtx) {
        //This gets called if a vector tile feature has already been parsed.
        //We've already got the geom, just get on with the drawing.
        //Need a way to pluck a canvas element from this layer given the parent layer's id.
        //Wait for it to get loaded before proceeding.
        var tilePoint = parentCtx.tile;
        var ctx = this._tiles[tilePoint.x + ":" + tilePoint.y];

        if (ctx) {
            parentCtx.canvas = ctx;
            this.redrawTile(parentCtx.id);
            return;
        }

        var self = this;

        //This is a timer that will wait for a criterion to return true.
        //If not true within the timeout duration, it will move on.
        waitFor(function () {
            ctx = self._tiles[tilePoint.x + ":" + tilePoint.y];
            if (ctx) {
                return true;
            }
        },
          function () {
              //When it finishes, do this.
              ctx = self._tiles[tilePoint.x + ":" + tilePoint.y];
              parentCtx.canvas = ctx;
              self.redrawTile(parentCtx.id);

          }, //when done, go to next flow
          2000); //The Timeout milliseconds.  After this, give up and move on

    },

    parseVectorTileLayer: function (vtl, ctx) {
        var self = this;
        var tilePoint = ctx.tile;
        var layerCtx = { canvas: null, id: ctx.id, tile: ctx.tile, zoom: ctx.zoom, tileSize: ctx.tileSize };

        //See if we can pluck the child tile from this PBF tile layer based on the master layer's tile id.
        layerCtx.canvas = self._tiles[tilePoint.x + ":" + tilePoint.y];



        //Initialize this tile's feature storage hash, if it hasn't already been created.  Used for when filters are updated, and features are cleared to prepare for a fresh redraw.
        if (!this._canvasIDToFeatures[layerCtx.id]) {
            this._initializeFeaturesHash(layerCtx);
        } else {
            //Clear this tile's previously saved features.
            this.clearTileFeatureHash(layerCtx.id);
        }

        var features = vtl.parsedFeatures;
        for (var i = 0, len = features.length; i < len; i++) {
            var vtf = features[i]; //vector tile feature
            vtf.layer = vtl;

            /**
             * Apply filter on feature if there is one. Defined in the options object
             * of TileLayer.MVTSource.js
             */
            var filter = self.options.filter;
            if (typeof filter === 'function') {
                if (filter(vtf, layerCtx) === false) continue;
            }

            var getIDForLayerFeature = Util.getIDForLayerFeature;
            var uniqueID = getIDForLayerFeature(vtf) || i;
            var mvtFeature = self.features[uniqueID];

            /**
             * Use layerOrdering function to apply a zIndex property to each vtf.  This is defined in
             * TileLayer.MVTSource.js.  Used below to sort features.npm
             */
            var layerOrdering = self.options.layerOrdering;
            if (typeof layerOrdering === 'function') {
                layerOrdering(vtf, layerCtx); //Applies a custom property to the feature, which is used after we're thru iterating to sort
            }

            //Create a new MVTFeature if one doesn't already exist for this feature.
            if (!mvtFeature) {
                //Get a style for the feature - set it just once for each new MVTFeature
                var style = self.style(vtf);

                //create a new feature
                self.features[uniqueID] = mvtFeature = new MVTFeature(self, vtf, layerCtx, uniqueID, style);
                if (style && style.dynamicLabel && typeof style.dynamicLabel === 'function') {
                    self.featuresWithLabels.push(mvtFeature);
                }
            } else {
                //Add the new part to the existing feature
                mvtFeature.addTileFeature(vtf, layerCtx);
            }

            //Associate & Save this feature with this tile for later
            if (layerCtx && layerCtx.id) self._canvasIDToFeatures[layerCtx.id]['features'].push(mvtFeature);

        }

        /**
         * Apply sorting (zIndex) on feature if there is a function defined in the options object
         * of TileLayer.MVTSource.js
         */
        var layerOrdering = self.options.layerOrdering;
        if (layerOrdering) {
            //We've assigned the custom zIndex property when iterating above.  Now just sort.
            self._canvasIDToFeatures[layerCtx.id].features = self._canvasIDToFeatures[layerCtx.id].features.sort(function (a, b) {
                return -(b.properties.zIndex - a.properties.zIndex)
            });
        }

        self.redrawTile(layerCtx.id);
    },

    setStyle: function (styleFn) {
        // refresh the number for the highest count value
        // this is used only for choropleth
        this._highestCount = 0;

        // lowest count should not be 0, since we want to figure out the lowest
        this._lowestCount = null;

        this.style = styleFn;
        for (var key in this.features) {
            var feat = this.features[key];
            feat.setStyle(styleFn);
        }
        var z = this.map.getZoom();
        for (var key in this._tiles) {
            var id = z + ':' + key;
            this.redrawTile(id);
        }
    },

    /**
     * As counts for choropleths come in with the ajax data,
     * we want to keep track of which value is the highest
     * to create the color ramp for the fills of polygons.
     * @param count
     */
    setHighestCount: function (count) {
        if (count > this._highestCount) {
            this._highestCount = count;
        }
    },

    /**
     * Returns the highest number of all of the counts that have come in
     * from setHighestCount. This is assumed to be set via ajax callbacks.
     * @returns {number}
     */
    getHighestCount: function () {
        return this._highestCount;
    },

    setLowestCount: function (count) {
        if (!this._lowestCount || count < this._lowestCount) {
            this._lowestCount = count;
        }
    },

    getLowestCount: function () {
        return this._lowestCount;
    },

    setCountRange: function (count) {
        this.setHighestCount(count);
        this.setLowestCount(count);
    },

    //This is the old way.  It works, but is slow for mouseover events.  Fine for click events.
    handleClickEvent: function (evt, cb) {
        //Click happened on the GroupLayer (Manager) and passed it here
        var tileIDs = evt.tileID.split(":");
        var tileID = evt.tileID.split(":").slice(1, 3).join(":");
        var zoom = evt.tileID.split(":")[0];
        var canvas = this._tiles[tileID];
        if (!canvas) (cb(evt)); //break out
        var x = evt.layerPoint.x - canvas._leaflet_pos.x;
        var y = evt.layerPoint.y - canvas._leaflet_pos.y;

        var tilePoint = { x: x, y: y };
        var features = this._canvasIDToFeatures[evt.tileID].features;

        var minDistance = Number.POSITIVE_INFINITY;
        var nearest = null;
        var j, paths, distance;

        for (var i = 0; i < features.length; i++) {
            var feature = features[i];
            switch (feature.type) {

                case 1: //Point - currently rendered as circular paths.  Intersect with that.

                    //Find the radius of the point.
                    var radius = 3;
                    if (typeof feature.style.radius === 'function') {
                        radius = feature.style.radius(zoom); //Allows for scale dependent rednering
                    }
                    else {
                        radius = feature.style.radius;
                    }

                    paths = feature.getPathsForTile(evt.tileID);
                    for (j = 0; j < paths.length; j++) {
                        //Builds a circle of radius feature.style.radius (assuming circular point symbology).
                        if (in_circle(paths[j][0].x, paths[j][0].y, radius, x, y)) {
                            nearest = feature;
                            minDistance = 0;
                        }
                    }
                    break;

                case 2: //LineString
                    paths = feature.getPathsForTile(evt.tileID);
                    for (j = 0; j < paths.length; j++) {
                        if (feature.style) {
                            var distance = this._getDistanceFromLine(tilePoint, paths[j]);
                            var thickness = (feature.selected && feature.style.selected ? feature.style.selected.size : feature.style.size);
                            if (distance < thickness / 2 + this.options.lineClickTolerance && distance < minDistance) {
                                nearest = feature;
                                minDistance = distance;
                            }
                        }
                    }
                    break;

                case 3: //Polygon
                    paths = feature.getPathsForTile(evt.tileID);
                    for (j = 0; j < paths.length; j++) {
                        if (this._isPointInPoly(tilePoint, paths[j])) {
                            nearest = feature;
                            minDistance = 0; // point is inside the polygon, so distance is zero
                        }
                    }
                    break;
            }
            if (minDistance == 0) break;
        }

        if (nearest && nearest.toggleEnabled) {
            nearest.toggle();
        }
        evt.feature = nearest;
        cb(evt);
    },

    clearTile: function (id) {
        //id is the entire zoom:x:y.  we just want x:y.
        var ca = id.split(":");
        var canvasId = ca[1] + ":" + ca[2];
        if (typeof this._tiles[canvasId] === 'undefined') {
            console.error("typeof this._tiles[canvasId] === 'undefined'");
            return;
        }
        var canvas = this._tiles[canvasId];

        var context = canvas.getContext('2d');
        context.clearRect(0, 0, canvas.width, canvas.height);
    },

    clearTileFeatureHash: function (canvasID) {
        this._canvasIDToFeatures[canvasID] = { features: [] }; //Get rid of all saved features
    },

    clearLayerFeatureHash: function () {
        this.features = {};
    },

    redrawTile: function (canvasID) {
        //First, clear the canvas
        this.clearTile(canvasID);

        // If the features are not in the tile, then there is nothing to redraw.
        // This may happen if you call redraw before features have loaded and initially
        // drawn the tile.
        var featfeats = this._canvasIDToFeatures[canvasID];
        if (!featfeats) {
            return;
        }

        //Get the features for this tile, and redraw them.
        var features = featfeats.features;

        // we want to skip drawing the selected features and draw them last
        var selectedFeatures = [];

        // drawing all of the non-selected features
        for (var i = 0; i < features.length; i++) {
            var feature = features[i];
            if (feature.selected) {
                selectedFeatures.push(feature);
                // console.log("selected feature on draw:", feature);
            } else {
                feature.draw(canvasID);
            }
        }

        // drawing the selected features last
        for (var j = 0, len2 = selectedFeatures.length; j < len2; j++) {
            var selFeat = selectedFeatures[j];
            selFeat.draw(canvasID);
        }
    },

    _resetCanvasIDToFeatures: function (canvasID, canvas) {

        this._canvasIDToFeatures[canvasID] = {};
        this._canvasIDToFeatures[canvasID].features = [];
        this._canvasIDToFeatures[canvasID].canvas = canvas;

    },

    linkedLayer: function () {
        if (this.mvtSource.layerLink) {
            var linkName = this.mvtSource.layerLink(this.name);
            return this.mvtSource.layers[linkName];
        }
        else {
            return null;
        }
    },

    featureWithLabelAdded: function (feature) {
        this.featuresWithLabels.push(feature);
    }

});


function removeLabels(self) {
    var features = self.featuresWithLabels;
    for (var i = 0, len = features.length; i < len; i++) {
        var feat = features[i];
        feat.removeLabel();
    }
    self.featuresWithLabels = [];
}

function in_circle(center_x, center_y, radius, x, y) {
    var square_dist = Math.pow((center_x - x), 2) + Math.pow((center_y - y), 2);
    return square_dist <= Math.pow(radius, 2);
}
/**
 * See https://github.com/ariya/phantomjs/blob/master/examples/waitfor.js
 *
 * Wait until the test condition is true or a timeout occurs. Useful for waiting
 * on a server response or for a ui change (fadeIn, etc.) to occur.
 *
 * @param testFx javascript condition that evaluates to a boolean,
 * it can be passed in as a string (e.g.: "1 == 1" or "$('#bar').is(':visible')" or
 * as a callback function.
 * @param onReady what to do when testFx condition is fulfilled,
 * it can be passed in as a string (e.g.: "1 == 1" or "$('#bar').is(':visible')" or
 * as a callback function.
 * @param timeOutMillis the max amount of time to wait. If not specified, 3 sec is used.
 */
function waitFor(testFx, onReady, timeOutMillis) {
    var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 3000, //< Default Max Timout is 3s
      start = new Date().getTime(),
      condition = (typeof (testFx) === "string" ? eval(testFx) : testFx()), //< defensive code
      interval = setInterval(function () {
          if ((new Date().getTime() - start < maxtimeOutMillis) && !condition) {
              // If not time-out yet and condition not yet fulfilled
              condition = (typeof (testFx) === "string" ? eval(testFx) : testFx()); //< defensive code
          } else {
              if (!condition) {
                  // If condition still not fulfilled (timeout but condition is 'false')
                  console.log("'waitFor()' timeout");
                  clearInterval(interval); //< Stop this interval
                  typeof (onReady) === "string" ? eval(onReady) : onReady('timeout'); //< Do what it's supposed to do once the condition is fulfilled
              } else {
                  // Condition fulfilled (timeout and/or condition is 'true')
                  console.log("'waitFor()' finished in " + (new Date().getTime() - start) + "ms.");
                  clearInterval(interval); //< Stop this interval
                  typeof (onReady) === "string" ? eval(onReady) : onReady('success'); //< Do what it's supposed to do once the condition is fulfilled
              }
          }
      }, 50); //< repeat check every 50ms
};
},{"./MVTFeature":9,"./MVTUtil":12}],11:[function(require,module,exports){
var VectorTile = require('vector-tile').VectorTile;
var Protobuf = require('pbf');
var Point = require('point-geometry');
var Util = require('./MVTUtil');
var MVTLayer = require('./MVTLayer');


module.exports = L.TileLayer.MVTSource = L.TileLayer.Canvas.extend({

  options: {
    debug: false,
    url: "", //URL TO Vector Tile Source,
    getIDForLayerFeature: function () { },
    tileSize: 256,
    visibleLayers: [],
    xhrHeaders: {}
  },
  layers: {}, //Keep a list of the layers contained in the PBFs
  processedTiles: {}, //Keep a list of tiles that have been processed already
  _eventHandlers: {},
  _triggerOnTilesLoadedEvent: true, //whether or not to fire the onTilesLoaded event when all of the tiles finish loading.
  _url: "", //internal URL property

  style: function (feature) {
    var style = {};

    var type = feature.type;
    switch (type) {
      case 1: //'Point'
        style.color = 'rgba(49,79,79,1)';
        style.radius = 5;
        style.selected = {
          color: 'rgba(255,255,0,0.5)',
          radius: 6
        };
        break;
      case 2: //'LineString'
        style.color = 'rgba(161,217,155,0.8)';
        style.size = 3;
        style.selected = {
          color: 'rgba(255,25,0,0.5)',
          size: 4
        };
        break;
      case 3: //'Polygon'
        style.color = 'rgba(49,79,79,1)';
        style.outline = {
          color: 'rgba(161,217,155,0.8)',
          size: 1
        };
        style.selected = {
          color: 'rgba(255,140,0,0.3)',
          outline: {
            color: 'rgba(255,140,0,1)',
            size: 2
          }
        };
        break;
    }
    return style;
  },


  initialize: function (options) {
    L.Util.setOptions(this, options);

    //a list of the layers contained in the PBFs
    this.layers = {};

    // tiles currently in the viewport
    this.activeTiles = {};

    // thats that have been loaded and drawn
    this.loadedTiles = {};

    this._url = this.options.url;

    /**
     * For some reason, Leaflet has some code that resets the
     * z index in the options object. I'm having trouble tracking
     * down exactly what does this and why, so for now, we should
     * just copy the value to this.zIndex so we can have the right
     * number when we make the subsequent MVTLayers.
     */
    this.zIndex = options.zIndex;

    if (typeof options.style === 'function') {
      this.style = options.style;
    }

    if (typeof options.ajaxSource === 'function') {
      this.ajaxSource = options.ajaxSource;
    }

    this.layerLink = options.layerLink;

    this._eventHandlers = {};

    this._tilesToProcess = 0; //store the max number of tiles to be loaded.  Later, we can use this count to count down PBF loading.
  },

  redraw: function (triggerOnTilesLoadedEvent) {
    //Only set to false if it actually is passed in as 'false'
    if (triggerOnTilesLoadedEvent === false) {
      this._triggerOnTilesLoadedEvent = false;
    }

    L.TileLayer.Canvas.prototype.redraw.call(this);
  },

  onAdd: function (map) {
    var self = this;
    self.map = map;
    L.TileLayer.Canvas.prototype.onAdd.call(this, map);

    var mapOnClickCallback = function (e) {
      self._onClick(e);
    };

    map.on('click', mapOnClickCallback);

    map.on("layerremove", function (e) {
      // check to see if the layer removed is this one
      // call a method to remove the child layers (the ones that actually have something drawn on them).
      if (e.layer._leaflet_id === self._leaflet_id && e.layer.removeChildLayers) {
        e.layer.removeChildLayers(map);
        map.off('click', mapOnClickCallback);
      }
    });

    self.addChildLayers(map);

    if (typeof DynamicLabel === 'function') {
      this.dynamicLabel = new DynamicLabel(map, this, {});
    }

  },

  drawTile: function (canvas, tilePoint, zoom) {
    var ctx = {
      id: [zoom, tilePoint.x, tilePoint.y].join(":"),
      canvas: canvas,
      tile: tilePoint,
      zoom: zoom,
      tileSize: this.options.tileSize
    };

    //Capture the max number of the tiles to load here. this._tilesToProcess is an internal number we use to know when we've finished requesting PBFs.
    if (this._tilesToProcess < this._tilesToLoad) this._tilesToProcess = this._tilesToLoad;

    var id = ctx.id = Util.getContextID(ctx);
    this.activeTiles[id] = ctx;

    if (!this.processedTiles[ctx.zoom]) this.processedTiles[ctx.zoom] = {};

    if (this.options.debug) {
      this._drawDebugInfo(ctx);
    }
    this._draw(ctx);
  },

  setOpacity: function (opacity) {
    this._setVisibleLayersStyle('opacity', opacity);
  },

  setZIndex: function (zIndex) {
    this._setVisibleLayersStyle('zIndex', zIndex);
  },

  _setVisibleLayersStyle: function (style, value) {
    for (var key in this.layers) {
      this.layers[key]._tileContainer.style[style] = value;
    }
  },

  _drawDebugInfo: function (ctx) {
    var max = this.options.tileSize;
    var g = ctx.canvas.getContext('2d');
    g.strokeStyle = '#000000';
    g.fillStyle = '#FFFF00';
    g.strokeRect(0, 0, max, max);
    g.font = "12px Arial";
    g.fillRect(0, 0, 5, 5);
    g.fillRect(0, max - 5, 5, 5);
    g.fillRect(max - 5, 0, 5, 5);
    g.fillRect(max - 5, max - 5, 5, 5);
    g.fillRect(max / 2 - 5, max / 2 - 5, 10, 10);
    g.strokeText(ctx.zoom + ' ' + ctx.tile.x + ' ' + ctx.tile.y, max / 2 - 30, max / 2 - 10);
  },

  _draw: function (ctx) {
    var self = this;

    //    //This works to skip fetching and processing tiles if they've already been processed.
    //    var vectorTile = this.processedTiles[ctx.zoom][ctx.id];
    //    //if we've already parsed it, don't get it again.
    //    if(vectorTile){
    //      console.log("Skipping fetching " + ctx.id);
    //      self.checkVectorTileLayers(parseVT(vectorTile), ctx, true);
    //      self.reduceTilesToProcessCount();
    //      return;
    //    }

    if (!this._url) return;
    var src = this.getTileUrl({ x: ctx.tile.x, y: ctx.tile.y, z: ctx.zoom });

    var xhr = new XMLHttpRequest();
    xhr.onload = function () {
      if (xhr.status == "200") {

        if (!xhr.response) return;

        var arrayBuffer = new Uint8Array(xhr.response);
        var buf = new Protobuf(arrayBuffer);
        var vt = new VectorTile(buf);
        //Check the current map layer zoom.  If fast zooming is occurring, then short circuit tiles that are for a different zoom level than we're currently on.
        if (self.map && self.map.getZoom() != ctx.zoom) {
          console.log("Fetched tile for zoom level " + ctx.zoom + ". Map is at zoom level " + self._map.getZoom());
          return;
        }
        self.checkVectorTileLayers(parseVT(vt), ctx);
        tileLoaded(self, ctx);
      }

      //either way, reduce the count of tilesToProcess tiles here
      self.reduceTilesToProcessCount();
    };

    xhr.onerror = function () {
      console.log("xhr error: " + xhr.status)
    };
    try {
      xhr.open('GET', src, true); //async is true
      var headers = self.options.xhrHeaders;
      for (var header in headers) {
        xhr.setRequestHeader(header, headers[header])
      }
      xhr.responseType = 'arraybuffer';
      xhr.send();
      } catch (ex) {
      // there was a GET error on the tile
     }

  },

  reduceTilesToProcessCount: function () {
    this._tilesToProcess--;
    if (!this._tilesToProcess) {
      //Trigger event letting us know that all PBFs have been loaded and processed (or 404'd).
      if (this._eventHandlers["PBFLoad"]) this._eventHandlers["PBFLoad"]();
      this._pbfLoaded();
    }
  },

  checkVectorTileLayers: function (vt, ctx, parsed) {
    var self = this;

    //Check if there are specified visible layers
    if (self.options.visibleLayers && self.options.visibleLayers.length > 0) {
      //only let thru the layers listed in the visibleLayers array
      for (var i = 0; i < self.options.visibleLayers.length; i++) {
        var layerName = self.options.visibleLayers[i];
        if (vt.layers[layerName]) {
          //Proceed with parsing
          self.prepareMVTLayers(vt.layers[layerName], layerName, ctx, parsed);
        }
      }
    } else {
      //Parse all vt.layers
      for (var key in vt.layers) {
        self.prepareMVTLayers(vt.layers[key], key, ctx, parsed);
      }
    }
  },

  prepareMVTLayers: function (lyr, key, ctx, parsed) {
    var self = this;

    if (!self.layers[key]) {
      //Create MVTLayer or MVTPointLayer for user
      self.layers[key] = self.createMVTLayer(key, lyr.parsedFeatures[0].type || null);
    }

    if (parsed) {
      //We've already parsed it.  Go get canvas and draw.
      self.layers[key].getCanvas(ctx, lyr);
    } else {
      self.layers[key].parseVectorTileLayer(lyr, ctx);
    }

  },

  createMVTLayer: function (key, type) {
    var self = this;

    var getIDForLayerFeature = Util.getIDForLayerFeature;

    var options = {
      getIDForLayerFeature: getIDForLayerFeature,
      filter: self.options.filter,
      layerOrdering: self.options.layerOrdering,
      style: self.style,
      name: key,
      asynch: true
    };

    if (self.options.zIndex) {
      options.zIndex = self.zIndex;
    }

    //Take the layer and create a new MVTLayer or MVTPointLayer if one doesn't exist.
    var layer = new MVTLayer(self, options).addTo(self.map);

    return layer;
  },

  getLayers: function () {
    return this.layers;
  },

  hideLayer: function (id) {
    if (this.layers[id]) {
      this._map.removeLayer(this.layers[id]);
      if (this.options.visibleLayers.indexOf("id") > -1) {
        this.visibleLayers.splice(this.options.visibleLayers.indexOf("id"), 1);
      }
    }
  },

  showLayer: function (id) {
    if (this.layers[id]) {
      this._map.addLayer(this.layers[id]);
      if (this.options.visibleLayers.indexOf("id") == -1) {
        this.visibleLayers.push(id);
      }
    }
    //Make sure manager layer is always in front
    this.bringToFront();
  },

  removeChildLayers: function (map) {
    //Remove child layers of this group layer
    for (var key in this.layers) {
      var layer = this.layers[key];
      map.removeLayer(layer);
    }
  },

  addChildLayers: function (map) {
    var self = this;
    if (self.options.visibleLayers.length > 0) {
      //only let thru the layers listed in the visibleLayers array
      for (var i = 0; i < self.options.visibleLayers.length; i++) {
        var layerName = self.options.visibleLayers[i];
        var layer = this.layers[layerName];
        if (layer) {
          //Proceed with parsing
          map.addLayer(layer);
        }
      }
    } else {
      //Add all layers
      for (var key in this.layers) {
        var layer = this.layers[key];
        // layer is set to visible and is not already on map
        if (!layer._map) {
          map.addLayer(layer);
        }
      }
    }
  },

  bind: function (eventType, callback) {
    this._eventHandlers[eventType] = callback;
  },

  _onClick: function (evt) {
    //Here, pass the event on to the child MVTLayer and have it do the hit test and handle the result.
    var self = this;
    var onClick = self.options.onClick;
    var clickableLayers = self.options.clickableLayers;
    var layers = self.layers;

    evt.tileID = getTileURL(evt.latlng.lat, evt.latlng.lng, this.map.getZoom());

    // We must have an array of clickable layers, otherwise, we just pass
    // the event to the public onClick callback in options.

    if (!clickableLayers) {
      clickableLayers = Object.keys(self.layers);
    }

    if (clickableLayers && clickableLayers.length > 0) {
      for (var i = 0, len = clickableLayers.length; i < len; i++) {
        var key = clickableLayers[i];
        var layer = layers[key];
        if (layer) {
          layer.handleClickEvent(evt, function (evt) {
            if (typeof onClick === 'function') {
              onClick(evt);
            }
          });
        }
      }
    } else {
      if (typeof onClick === 'function') {
        onClick(evt);
      }
    }

  },

  setFilter: function (filterFunction, layerName) {
    //take in a new filter function.
    //Propagate to child layers.

    //Add filter to all child layers if no layer is specified.
    for (var key in this.layers) {
      var layer = this.layers[key];

      if (layerName) {
        if (key.toLowerCase() == layerName.toLowerCase()) {
          layer.options.filter = filterFunction; //Assign filter to child layer, only if name matches
          //After filter is set, the old feature hashes are invalid.  Clear them for next draw.
          layer.clearLayerFeatureHash();
          //layer.clearTileFeatureHash();
        }
      }
      else {
        layer.options.filter = filterFunction; //Assign filter to child layer
        //After filter is set, the old feature hashes are invalid.  Clear them for next draw.
        layer.clearLayerFeatureHash();
        //layer.clearTileFeatureHash();
      }
    }
  },

  /**
   * Take in a new style function and propogate to child layers.
   * If you do not set a layer name, it resets the style for all of the layers.
   * @param styleFunction
   * @param layerName
   */
  setStyle: function (styleFn, layerName) {
    for (var key in this.layers) {
      var layer = this.layers[key];
      if (layerName) {
        if (key.toLowerCase() == layerName.toLowerCase()) {
          layer.setStyle(styleFn);
        }
      } else {
        layer.setStyle(styleFn);
      }
    }
  },

  featureSelected: function (mvtFeature) {
    if (this.options.mutexToggle) {
      if (this._selectedFeature) {
        this._selectedFeature.deselect();
      }
      this._selectedFeature = mvtFeature;
    }
    if (this.options.onSelect) {
      this.options.onSelect(mvtFeature);
    }
  },

  featureDeselected: function (mvtFeature) {
    if (this.options.mutexToggle && this._selectedFeature) {
      this._selectedFeature = null;
    }
    if (this.options.onDeselect) {
      this.options.onDeselect(mvtFeature);
    }
  },

  _pbfLoaded: function () {
    //Fires when all tiles from this layer have been loaded and drawn (or 404'd).

    //Make sure manager layer is always in front
    this.bringToFront();

    //See if there is an event to execute
    var self = this;
    var onTilesLoaded = self.options.onTilesLoaded;

    if (onTilesLoaded && typeof onTilesLoaded === 'function' && this._triggerOnTilesLoadedEvent === true) {
      onTilesLoaded(this);
    }
    self._triggerOnTilesLoadedEvent = true; //reset - if redraw() is called with the optinal 'false' parameter to temporarily disable the onTilesLoaded event from firing.  This resets it back to true after a single time of firing as 'false'.
  }

});


if (typeof (Number.prototype.toRad) === "undefined") {
  Number.prototype.toRad = function () {
    return this * Math.PI / 180;
  }
}

function getTileURL(lat, lon, zoom) {
  var xtile = parseInt(Math.floor((lon + 180) / 360 * (1 << zoom)));
  var ytile = parseInt(Math.floor((1 - Math.log(Math.tan(lat.toRad()) + 1 / Math.cos(lat.toRad())) / Math.PI) / 2 * (1 << zoom)));
  return "" + zoom + ":" + xtile + ":" + ytile;
}

function tileLoaded(pbfSource, ctx) {
  pbfSource.loadedTiles[ctx.id] = ctx;
}

function parseVT(vt) {
  for (var key in vt.layers) {
    var lyr = vt.layers[key];
    parseVTFeatures(lyr);
  }
  return vt;
}

function parseVTFeatures(vtl) {
  vtl.parsedFeatures = [];
  var features = vtl._features;
  for (var i = 0, len = features.length; i < len; i++) {
    var vtf = vtl.feature(i);
    vtf.coordinates = vtf.loadGeometry();
    vtl.parsedFeatures.push(vtf);
  }
  return vtl;
}

},{"./MVTLayer":10,"./MVTUtil":12,"pbf":2,"point-geometry":4,"vector-tile":5}],12:[function(require,module,exports){
/**
 * Created by Nicholas Hallahan <nhallahan@spatialdev.com>
 *       on 8/15/14.
 */
var Util = module.exports = {};

Util.getContextID = function(ctx) {
  return [ctx.zoom, ctx.tile.x, ctx.tile.y].join(":");
};

/**
 * Default function that gets the id for a layer feature.
 * Sometimes this needs to be done in a different way and
 * can be specified by the user in the options for L.TileLayer.MVTSource.
 *
 * @param feature
 * @returns {ctx.id|*|id|string|jsts.index.chain.MonotoneChain.id|number}
 */
Util.getIDForLayerFeature = function (feature) {
  return feature.properties.id;
};

Util.getJSON = function(url, callback) {
  var xmlhttp = typeof XMLHttpRequest !== 'undefined' ? new XMLHttpRequest() : new ActiveXObject('Microsoft.XMLHTTP');
  xmlhttp.onreadystatechange = function() {
    var status = xmlhttp.status;
    if (xmlhttp.readyState === 4 && status >= 200 && status < 300) {
      var json = JSON.parse(xmlhttp.responseText);
      callback(null, json);
    } else {
      callback( { error: true, status: status } );
    }
  };
  xmlhttp.open("GET", url, true);
  xmlhttp.send();
};

},{}],13:[function(require,module,exports){
/**
 * Created by Nicholas Hallahan <nhallahan@spatialdev.com>
 *       on 7/31/14.
 */
var Util = require('../MVTUtil');
module.exports = StaticLabel;

function StaticLabel(mvtFeature, ctx, latLng, style) {
  var self = this;
  this.mvtFeature = mvtFeature;
  this.map = mvtFeature.map;
  this.zoom = ctx.zoom;
  this.latLng = latLng;
  this.selected = false;

  if (mvtFeature.linkedFeature) {
    var linkedFeature = mvtFeature.linkedFeature();
    if (linkedFeature && linkedFeature.selected) {
      self.selected = true;
    }
  }

  init(self, mvtFeature, ctx, latLng, style)
}

function init(self, mvtFeature, ctx, latLng, style) {
  var ajaxData = mvtFeature.ajaxData;
  var sty = self.style = style.staticLabel(mvtFeature, ajaxData);
  var icon = self.icon = L.divIcon({
    className: sty.cssClass || 'label-icon-text',
    html: sty.html,
    iconSize: sty.iconSize || [50,50]
  });

  self.marker = L.marker(latLng, {icon: icon}).addTo(self.map);

  if (self.selected) {
    self.marker._icon.classList.add(self.style.cssSelectedClass || 'label-icon-text-selected');
  }

  self.marker.on('click', function(e) {
    self.toggle();
  });

  self.map.on('zoomend', function(e) {
    var newZoom = e.target.getZoom();
    if (self.zoom !== newZoom) {
      self.map.removeLayer(self.marker);
    }
  });
}


StaticLabel.prototype.toggle = function() {
  if (this.selected) {
    this.deselect();
  } else {
    this.select();
  }
};

StaticLabel.prototype.select = function() {
  this.selected = true;
  this.marker._icon.classList.add(this.style.cssSelectedClass || 'label-icon-text-selected');
  var linkedFeature = this.mvtFeature.linkedFeature();
  if (!linkedFeature.selected) linkedFeature.select();
};

StaticLabel.prototype.deselect = function() {
  this.selected = false;
  this.marker._icon.classList.remove(this.style.cssSelectedClass || 'label-icon-text-selected');
  var linkedFeature = this.mvtFeature.linkedFeature();
  if (linkedFeature.selected) linkedFeature.deselect();
};

StaticLabel.prototype.remove = function() {
  if (!this.map || !this.marker) return;
  this.map.removeLayer(this.marker);
};

},{"../MVTUtil":12}],14:[function(require,module,exports){
/**
 * Copyright (c) 2014, Spatial Development International
 * All rights reserved.
 *
 * Source code can be found at:
 * https://github.com/SpatialServer/Leaflet.MapboxVectorTile
 *
 * @license ISC
 */

module.exports = require('./MVTSource');

},{"./MVTSource":11}]},{},[14])
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uLy4uL0FwcERhdGEvUm9hbWluZy9ucG0vbm9kZV9tb2R1bGVzL3dhdGNoaWZ5L25vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCJub2RlX21vZHVsZXMvcGJmL2J1ZmZlci5qcyIsIm5vZGVfbW9kdWxlcy9wYmYvaW5kZXguanMiLCJub2RlX21vZHVsZXMvcGJmL25vZGVfbW9kdWxlcy9pZWVlNzU0L2luZGV4LmpzIiwibm9kZV9tb2R1bGVzL3BvaW50LWdlb21ldHJ5L2luZGV4LmpzIiwibm9kZV9tb2R1bGVzL3ZlY3Rvci10aWxlL2luZGV4LmpzIiwibm9kZV9tb2R1bGVzL3ZlY3Rvci10aWxlL2xpYi92ZWN0b3J0aWxlLmpzIiwibm9kZV9tb2R1bGVzL3ZlY3Rvci10aWxlL2xpYi92ZWN0b3J0aWxlZmVhdHVyZS5qcyIsIm5vZGVfbW9kdWxlcy92ZWN0b3ItdGlsZS9saWIvdmVjdG9ydGlsZWxheWVyLmpzIiwic3JjL01WVEZlYXR1cmUuanMiLCJzcmMvTVZUTGF5ZXIuanMiLCJzcmMvTVZUU291cmNlLmpzIiwic3JjL01WVFV0aWwuanMiLCJzcmMvU3RhdGljTGFiZWwvU3RhdGljTGFiZWwuanMiLCJzcmMvaW5kZXguanMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7QUNBQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7O0FDL0pBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7O0FDMWFBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ3BGQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDbklBO0FBQ0E7QUFDQTtBQUNBOztBQ0hBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNqQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUN0S0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUM3REE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNqYkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUM3ZUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ2xoQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDcENBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDL0VBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSIsImZpbGUiOiJnZW5lcmF0ZWQuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlc0NvbnRlbnQiOlsiKGZ1bmN0aW9uIGUodCxuLHIpe2Z1bmN0aW9uIHMobyx1KXtpZighbltvXSl7aWYoIXRbb10pe3ZhciBhPXR5cGVvZiByZXF1aXJlPT1cImZ1bmN0aW9uXCImJnJlcXVpcmU7aWYoIXUmJmEpcmV0dXJuIGEobywhMCk7aWYoaSlyZXR1cm4gaShvLCEwKTt2YXIgZj1uZXcgRXJyb3IoXCJDYW5ub3QgZmluZCBtb2R1bGUgJ1wiK28rXCInXCIpO3Rocm93IGYuY29kZT1cIk1PRFVMRV9OT1RfRk9VTkRcIixmfXZhciBsPW5bb109e2V4cG9ydHM6e319O3Rbb11bMF0uY2FsbChsLmV4cG9ydHMsZnVuY3Rpb24oZSl7dmFyIG49dFtvXVsxXVtlXTtyZXR1cm4gcyhuP246ZSl9LGwsbC5leHBvcnRzLGUsdCxuLHIpfXJldHVybiBuW29dLmV4cG9ydHN9dmFyIGk9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtmb3IodmFyIG89MDtvPHIubGVuZ3RoO28rKylzKHJbb10pO3JldHVybiBzfSkiLCIndXNlIHN0cmljdCc7XG5cbi8vIGxpZ2h0d2VpZ2h0IEJ1ZmZlciBzaGltIGZvciBwYmYgYnJvd3NlciBidWlsZFxuLy8gYmFzZWQgb24gY29kZSBmcm9tIGdpdGh1Yi5jb20vZmVyb3NzL2J1ZmZlciAoTUlULWxpY2Vuc2VkKVxuXG5tb2R1bGUuZXhwb3J0cyA9IEJ1ZmZlcjtcblxudmFyIGllZWU3NTQgPSByZXF1aXJlKCdpZWVlNzU0Jyk7XG5cbnZhciBCdWZmZXJNZXRob2RzO1xuXG5mdW5jdGlvbiBCdWZmZXIobGVuZ3RoKSB7XG4gICAgdmFyIGFycjtcbiAgICBpZiAobGVuZ3RoICYmIGxlbmd0aC5sZW5ndGgpIHtcbiAgICAgICAgYXJyID0gbGVuZ3RoO1xuICAgICAgICBsZW5ndGggPSBhcnIubGVuZ3RoO1xuICAgIH1cbiAgICB2YXIgYnVmID0gbmV3IFVpbnQ4QXJyYXkobGVuZ3RoIHx8IDApO1xuICAgIGlmIChhcnIpIGJ1Zi5zZXQoYXJyKTtcblxuICAgIGJ1Zi5yZWFkVUludDMyTEUgPSBCdWZmZXJNZXRob2RzLnJlYWRVSW50MzJMRTtcbiAgICBidWYud3JpdGVVSW50MzJMRSA9IEJ1ZmZlck1ldGhvZHMud3JpdGVVSW50MzJMRTtcbiAgICBidWYucmVhZEludDMyTEUgPSBCdWZmZXJNZXRob2RzLnJlYWRJbnQzMkxFO1xuICAgIGJ1Zi53cml0ZUludDMyTEUgPSBCdWZmZXJNZXRob2RzLndyaXRlSW50MzJMRTtcbiAgICBidWYucmVhZEZsb2F0TEUgPSBCdWZmZXJNZXRob2RzLnJlYWRGbG9hdExFO1xuICAgIGJ1Zi53cml0ZUZsb2F0TEUgPSBCdWZmZXJNZXRob2RzLndyaXRlRmxvYXRMRTtcbiAgICBidWYucmVhZERvdWJsZUxFID0gQnVmZmVyTWV0aG9kcy5yZWFkRG91YmxlTEU7XG4gICAgYnVmLndyaXRlRG91YmxlTEUgPSBCdWZmZXJNZXRob2RzLndyaXRlRG91YmxlTEU7XG4gICAgYnVmLnRvU3RyaW5nID0gQnVmZmVyTWV0aG9kcy50b1N0cmluZztcbiAgICBidWYud3JpdGUgPSBCdWZmZXJNZXRob2RzLndyaXRlO1xuICAgIGJ1Zi5zbGljZSA9IEJ1ZmZlck1ldGhvZHMuc2xpY2U7XG4gICAgYnVmLmNvcHkgPSBCdWZmZXJNZXRob2RzLmNvcHk7XG5cbiAgICBidWYuX2lzQnVmZmVyID0gdHJ1ZTtcbiAgICByZXR1cm4gYnVmO1xufVxuXG52YXIgbGFzdFN0ciwgbGFzdFN0ckVuY29kZWQ7XG5cbkJ1ZmZlck1ldGhvZHMgPSB7XG4gICAgcmVhZFVJbnQzMkxFOiBmdW5jdGlvbihwb3MpIHtcbiAgICAgICAgcmV0dXJuICgodGhpc1twb3NdKSB8XG4gICAgICAgICAgICAodGhpc1twb3MgKyAxXSA8PCA4KSB8XG4gICAgICAgICAgICAodGhpc1twb3MgKyAyXSA8PCAxNikpICtcbiAgICAgICAgICAgICh0aGlzW3BvcyArIDNdICogMHgxMDAwMDAwKTtcbiAgICB9LFxuXG4gICAgd3JpdGVVSW50MzJMRTogZnVuY3Rpb24odmFsLCBwb3MpIHtcbiAgICAgICAgdGhpc1twb3NdID0gdmFsO1xuICAgICAgICB0aGlzW3BvcyArIDFdID0gKHZhbCA+Pj4gOCk7XG4gICAgICAgIHRoaXNbcG9zICsgMl0gPSAodmFsID4+PiAxNik7XG4gICAgICAgIHRoaXNbcG9zICsgM10gPSAodmFsID4+PiAyNCk7XG4gICAgfSxcblxuICAgIHJlYWRJbnQzMkxFOiBmdW5jdGlvbihwb3MpIHtcbiAgICAgICAgcmV0dXJuICgodGhpc1twb3NdKSB8XG4gICAgICAgICAgICAodGhpc1twb3MgKyAxXSA8PCA4KSB8XG4gICAgICAgICAgICAodGhpc1twb3MgKyAyXSA8PCAxNikpICtcbiAgICAgICAgICAgICh0aGlzW3BvcyArIDNdIDw8IDI0KTtcbiAgICB9LFxuXG4gICAgcmVhZEZsb2F0TEU6ICBmdW5jdGlvbihwb3MpIHsgcmV0dXJuIGllZWU3NTQucmVhZCh0aGlzLCBwb3MsIHRydWUsIDIzLCA0KTsgfSxcbiAgICByZWFkRG91YmxlTEU6IGZ1bmN0aW9uKHBvcykgeyByZXR1cm4gaWVlZTc1NC5yZWFkKHRoaXMsIHBvcywgdHJ1ZSwgNTIsIDgpOyB9LFxuXG4gICAgd3JpdGVGbG9hdExFOiAgZnVuY3Rpb24odmFsLCBwb3MpIHsgcmV0dXJuIGllZWU3NTQud3JpdGUodGhpcywgdmFsLCBwb3MsIHRydWUsIDIzLCA0KTsgfSxcbiAgICB3cml0ZURvdWJsZUxFOiBmdW5jdGlvbih2YWwsIHBvcykgeyByZXR1cm4gaWVlZTc1NC53cml0ZSh0aGlzLCB2YWwsIHBvcywgdHJ1ZSwgNTIsIDgpOyB9LFxuXG4gICAgdG9TdHJpbmc6IGZ1bmN0aW9uKGVuY29kaW5nLCBzdGFydCwgZW5kKSB7XG4gICAgICAgIHZhciBzdHIgPSAnJyxcbiAgICAgICAgICAgIHRtcCA9ICcnO1xuXG4gICAgICAgIHN0YXJ0ID0gc3RhcnQgfHwgMDtcbiAgICAgICAgZW5kID0gTWF0aC5taW4odGhpcy5sZW5ndGgsIGVuZCB8fCB0aGlzLmxlbmd0aCk7XG5cbiAgICAgICAgZm9yICh2YXIgaSA9IHN0YXJ0OyBpIDwgZW5kOyBpKyspIHtcbiAgICAgICAgICAgIHZhciBjaCA9IHRoaXNbaV07XG4gICAgICAgICAgICBpZiAoY2ggPD0gMHg3Rikge1xuICAgICAgICAgICAgICAgIHN0ciArPSBkZWNvZGVVUklDb21wb25lbnQodG1wKSArIFN0cmluZy5mcm9tQ2hhckNvZGUoY2gpO1xuICAgICAgICAgICAgICAgIHRtcCA9ICcnO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICB0bXAgKz0gJyUnICsgY2gudG9TdHJpbmcoMTYpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgc3RyICs9IGRlY29kZVVSSUNvbXBvbmVudCh0bXApO1xuXG4gICAgICAgIHJldHVybiBzdHI7XG4gICAgfSxcblxuICAgIHdyaXRlOiBmdW5jdGlvbihzdHIsIHBvcykge1xuICAgICAgICB2YXIgYnl0ZXMgPSBzdHIgPT09IGxhc3RTdHIgPyBsYXN0U3RyRW5jb2RlZCA6IGVuY29kZVN0cmluZyhzdHIpO1xuICAgICAgICBmb3IgKHZhciBpID0gMDsgaSA8IGJ5dGVzLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgICB0aGlzW3BvcyArIGldID0gYnl0ZXNbaV07XG4gICAgICAgIH1cbiAgICB9LFxuXG4gICAgc2xpY2U6IGZ1bmN0aW9uKHN0YXJ0LCBlbmQpIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuc3ViYXJyYXkoc3RhcnQsIGVuZCk7XG4gICAgfSxcblxuICAgIGNvcHk6IGZ1bmN0aW9uKGJ1ZiwgcG9zKSB7XG4gICAgICAgIHBvcyA9IHBvcyB8fCAwO1xuICAgICAgICBmb3IgKHZhciBpID0gMDsgaSA8IHRoaXMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICAgIGJ1Zltwb3MgKyBpXSA9IHRoaXNbaV07XG4gICAgICAgIH1cbiAgICB9XG59O1xuXG5CdWZmZXJNZXRob2RzLndyaXRlSW50MzJMRSA9IEJ1ZmZlck1ldGhvZHMud3JpdGVVSW50MzJMRTtcblxuQnVmZmVyLmJ5dGVMZW5ndGggPSBmdW5jdGlvbihzdHIpIHtcbiAgICBsYXN0U3RyID0gc3RyO1xuICAgIGxhc3RTdHJFbmNvZGVkID0gZW5jb2RlU3RyaW5nKHN0cik7XG4gICAgcmV0dXJuIGxhc3RTdHJFbmNvZGVkLmxlbmd0aDtcbn07XG5cbkJ1ZmZlci5pc0J1ZmZlciA9IGZ1bmN0aW9uKGJ1Zikge1xuICAgIHJldHVybiAhIShidWYgJiYgYnVmLl9pc0J1ZmZlcik7XG59O1xuXG5mdW5jdGlvbiBlbmNvZGVTdHJpbmcoc3RyKSB7XG4gICAgdmFyIGxlbmd0aCA9IHN0ci5sZW5ndGgsXG4gICAgICAgIGJ5dGVzID0gW107XG5cbiAgICBmb3IgKHZhciBpID0gMCwgYywgbGVhZDsgaSA8IGxlbmd0aDsgaSsrKSB7XG4gICAgICAgIGMgPSBzdHIuY2hhckNvZGVBdChpKTsgLy8gY29kZSBwb2ludFxuXG4gICAgICAgIGlmIChjID4gMHhEN0ZGICYmIGMgPCAweEUwMDApIHtcblxuICAgICAgICAgICAgaWYgKGxlYWQpIHtcbiAgICAgICAgICAgICAgICBpZiAoYyA8IDB4REMwMCkge1xuICAgICAgICAgICAgICAgICAgICBieXRlcy5wdXNoKDB4RUYsIDB4QkYsIDB4QkQpO1xuICAgICAgICAgICAgICAgICAgICBsZWFkID0gYztcbiAgICAgICAgICAgICAgICAgICAgY29udGludWU7XG5cbiAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICBjID0gbGVhZCAtIDB4RDgwMCA8PCAxMCB8IGMgLSAweERDMDAgfCAweDEwMDAwO1xuICAgICAgICAgICAgICAgICAgICBsZWFkID0gbnVsbDtcbiAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgaWYgKGMgPiAweERCRkYgfHwgKGkgKyAxID09PSBsZW5ndGgpKSBieXRlcy5wdXNoKDB4RUYsIDB4QkYsIDB4QkQpO1xuICAgICAgICAgICAgICAgIGVsc2UgbGVhZCA9IGM7XG5cbiAgICAgICAgICAgICAgICBjb250aW51ZTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICB9IGVsc2UgaWYgKGxlYWQpIHtcbiAgICAgICAgICAgIGJ5dGVzLnB1c2goMHhFRiwgMHhCRiwgMHhCRCk7XG4gICAgICAgICAgICBsZWFkID0gbnVsbDtcbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChjIDwgMHg4MCkgYnl0ZXMucHVzaChjKTtcbiAgICAgICAgZWxzZSBpZiAoYyA8IDB4ODAwKSBieXRlcy5wdXNoKGMgPj4gMHg2IHwgMHhDMCwgYyAmIDB4M0YgfCAweDgwKTtcbiAgICAgICAgZWxzZSBpZiAoYyA8IDB4MTAwMDApIGJ5dGVzLnB1c2goYyA+PiAweEMgfCAweEUwLCBjID4+IDB4NiAmIDB4M0YgfCAweDgwLCBjICYgMHgzRiB8IDB4ODApO1xuICAgICAgICBlbHNlIGJ5dGVzLnB1c2goYyA+PiAweDEyIHwgMHhGMCwgYyA+PiAweEMgJiAweDNGIHwgMHg4MCwgYyA+PiAweDYgJiAweDNGIHwgMHg4MCwgYyAmIDB4M0YgfCAweDgwKTtcbiAgICB9XG4gICAgcmV0dXJuIGJ5dGVzO1xufVxuIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IFBiZjtcblxudmFyIEJ1ZmZlciA9IGdsb2JhbC5CdWZmZXIgfHwgcmVxdWlyZSgnLi9idWZmZXInKTtcblxuZnVuY3Rpb24gUGJmKGJ1Zikge1xuICAgIHRoaXMuYnVmID0gIUJ1ZmZlci5pc0J1ZmZlcihidWYpID8gbmV3IEJ1ZmZlcihidWYgfHwgMCkgOiBidWY7XG4gICAgdGhpcy5wb3MgPSAwO1xuICAgIHRoaXMubGVuZ3RoID0gdGhpcy5idWYubGVuZ3RoO1xufVxuXG5QYmYuVmFyaW50ICA9IDA7IC8vIHZhcmludDogaW50MzIsIGludDY0LCB1aW50MzIsIHVpbnQ2NCwgc2ludDMyLCBzaW50NjQsIGJvb2wsIGVudW1cblBiZi5GaXhlZDY0ID0gMTsgLy8gNjQtYml0OiBkb3VibGUsIGZpeGVkNjQsIHNmaXhlZDY0XG5QYmYuQnl0ZXMgICA9IDI7IC8vIGxlbmd0aC1kZWxpbWl0ZWQ6IHN0cmluZywgYnl0ZXMsIGVtYmVkZGVkIG1lc3NhZ2VzLCBwYWNrZWQgcmVwZWF0ZWQgZmllbGRzXG5QYmYuRml4ZWQzMiA9IDU7IC8vIDMyLWJpdDogZmxvYXQsIGZpeGVkMzIsIHNmaXhlZDMyXG5cbnZhciBTSElGVF9MRUZUXzMyID0gKDEgPDwgMTYpICogKDEgPDwgMTYpLFxuICAgIFNISUZUX1JJR0hUXzMyID0gMSAvIFNISUZUX0xFRlRfMzIsXG4gICAgUE9XXzJfNjMgPSBNYXRoLnBvdygyLCA2Myk7XG5cblBiZi5wcm90b3R5cGUgPSB7XG5cbiAgICBkZXN0cm95OiBmdW5jdGlvbigpIHtcbiAgICAgICAgdGhpcy5idWYgPSBudWxsO1xuICAgIH0sXG5cbiAgICAvLyA9PT0gUkVBRElORyA9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PVxuXG4gICAgcmVhZEZpZWxkczogZnVuY3Rpb24ocmVhZEZpZWxkLCByZXN1bHQsIGVuZCkge1xuICAgICAgICBlbmQgPSBlbmQgfHwgdGhpcy5sZW5ndGg7XG5cbiAgICAgICAgd2hpbGUgKHRoaXMucG9zIDwgZW5kKSB7XG4gICAgICAgICAgICB2YXIgdmFsID0gdGhpcy5yZWFkVmFyaW50KCksXG4gICAgICAgICAgICAgICAgdGFnID0gdmFsID4+IDMsXG4gICAgICAgICAgICAgICAgc3RhcnRQb3MgPSB0aGlzLnBvcztcblxuICAgICAgICAgICAgcmVhZEZpZWxkKHRhZywgcmVzdWx0LCB0aGlzKTtcblxuICAgICAgICAgICAgaWYgKHRoaXMucG9zID09PSBzdGFydFBvcykgdGhpcy5za2lwKHZhbCk7XG4gICAgICAgIH1cbiAgICAgICAgcmV0dXJuIHJlc3VsdDtcbiAgICB9LFxuXG4gICAgcmVhZE1lc3NhZ2U6IGZ1bmN0aW9uKHJlYWRGaWVsZCwgcmVzdWx0KSB7XG4gICAgICAgIHJldHVybiB0aGlzLnJlYWRGaWVsZHMocmVhZEZpZWxkLCByZXN1bHQsIHRoaXMucmVhZFZhcmludCgpICsgdGhpcy5wb3MpO1xuICAgIH0sXG5cbiAgICByZWFkRml4ZWQzMjogZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciB2YWwgPSB0aGlzLmJ1Zi5yZWFkVUludDMyTEUodGhpcy5wb3MpO1xuICAgICAgICB0aGlzLnBvcyArPSA0O1xuICAgICAgICByZXR1cm4gdmFsO1xuICAgIH0sXG5cbiAgICByZWFkU0ZpeGVkMzI6IGZ1bmN0aW9uKCkge1xuICAgICAgICB2YXIgdmFsID0gdGhpcy5idWYucmVhZEludDMyTEUodGhpcy5wb3MpO1xuICAgICAgICB0aGlzLnBvcyArPSA0O1xuICAgICAgICByZXR1cm4gdmFsO1xuICAgIH0sXG5cbiAgICAvLyA2NC1iaXQgaW50IGhhbmRsaW5nIGlzIGJhc2VkIG9uIGdpdGh1Yi5jb20vZHB3L25vZGUtYnVmZmVyLW1vcmUtaW50cyAoTUlULWxpY2Vuc2VkKVxuXG4gICAgcmVhZEZpeGVkNjQ6IGZ1bmN0aW9uKCkge1xuICAgICAgICB2YXIgdmFsID0gdGhpcy5idWYucmVhZFVJbnQzMkxFKHRoaXMucG9zKSArIHRoaXMuYnVmLnJlYWRVSW50MzJMRSh0aGlzLnBvcyArIDQpICogU0hJRlRfTEVGVF8zMjtcbiAgICAgICAgdGhpcy5wb3MgKz0gODtcbiAgICAgICAgcmV0dXJuIHZhbDtcbiAgICB9LFxuXG4gICAgcmVhZFNGaXhlZDY0OiBmdW5jdGlvbigpIHtcbiAgICAgICAgdmFyIHZhbCA9IHRoaXMuYnVmLnJlYWRVSW50MzJMRSh0aGlzLnBvcykgKyB0aGlzLmJ1Zi5yZWFkSW50MzJMRSh0aGlzLnBvcyArIDQpICogU0hJRlRfTEVGVF8zMjtcbiAgICAgICAgdGhpcy5wb3MgKz0gODtcbiAgICAgICAgcmV0dXJuIHZhbDtcbiAgICB9LFxuXG4gICAgcmVhZEZsb2F0OiBmdW5jdGlvbigpIHtcbiAgICAgICAgdmFyIHZhbCA9IHRoaXMuYnVmLnJlYWRGbG9hdExFKHRoaXMucG9zKTtcbiAgICAgICAgdGhpcy5wb3MgKz0gNDtcbiAgICAgICAgcmV0dXJuIHZhbDtcbiAgICB9LFxuXG4gICAgcmVhZERvdWJsZTogZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciB2YWwgPSB0aGlzLmJ1Zi5yZWFkRG91YmxlTEUodGhpcy5wb3MpO1xuICAgICAgICB0aGlzLnBvcyArPSA4O1xuICAgICAgICByZXR1cm4gdmFsO1xuICAgIH0sXG5cbiAgICByZWFkVmFyaW50OiBmdW5jdGlvbigpIHtcbiAgICAgICAgdmFyIGJ1ZiA9IHRoaXMuYnVmLFxuICAgICAgICAgICAgdmFsLCBiLCBiMCwgYjEsIGIyLCBiMztcblxuICAgICAgICBiMCA9IGJ1Zlt0aGlzLnBvcysrXTsgaWYgKGIwIDwgMHg4MCkgcmV0dXJuIGIwOyAgICAgICAgICAgICAgICAgYjAgPSBiMCAmIDB4N2Y7XG4gICAgICAgIGIxID0gYnVmW3RoaXMucG9zKytdOyBpZiAoYjEgPCAweDgwKSByZXR1cm4gYjAgfCBiMSA8PCA3OyAgICAgICBiMSA9IChiMSAmIDB4N2YpIDw8IDc7XG4gICAgICAgIGIyID0gYnVmW3RoaXMucG9zKytdOyBpZiAoYjIgPCAweDgwKSByZXR1cm4gYjAgfCBiMSB8IGIyIDw8IDE0OyBiMiA9IChiMiAmIDB4N2YpIDw8IDE0O1xuICAgICAgICBiMyA9IGJ1Zlt0aGlzLnBvcysrXTsgaWYgKGIzIDwgMHg4MCkgcmV0dXJuIGIwIHwgYjEgfCBiMiB8IGIzIDw8IDIxO1xuXG4gICAgICAgIHZhbCA9IGIwIHwgYjEgfCBiMiB8IChiMyAmIDB4N2YpIDw8IDIxO1xuXG4gICAgICAgIGIgPSBidWZbdGhpcy5wb3MrK107IHZhbCArPSAoYiAmIDB4N2YpICogMHgxMDAwMDAwMDsgICAgICAgICBpZiAoYiA8IDB4ODApIHJldHVybiB2YWw7XG4gICAgICAgIGIgPSBidWZbdGhpcy5wb3MrK107IHZhbCArPSAoYiAmIDB4N2YpICogMHg4MDAwMDAwMDA7ICAgICAgICBpZiAoYiA8IDB4ODApIHJldHVybiB2YWw7XG4gICAgICAgIGIgPSBidWZbdGhpcy5wb3MrK107IHZhbCArPSAoYiAmIDB4N2YpICogMHg0MDAwMDAwMDAwMDsgICAgICBpZiAoYiA8IDB4ODApIHJldHVybiB2YWw7XG4gICAgICAgIGIgPSBidWZbdGhpcy5wb3MrK107IHZhbCArPSAoYiAmIDB4N2YpICogMHgyMDAwMDAwMDAwMDAwOyAgICBpZiAoYiA8IDB4ODApIHJldHVybiB2YWw7XG4gICAgICAgIGIgPSBidWZbdGhpcy5wb3MrK107IHZhbCArPSAoYiAmIDB4N2YpICogMHgxMDAwMDAwMDAwMDAwMDA7ICBpZiAoYiA8IDB4ODApIHJldHVybiB2YWw7XG4gICAgICAgIGIgPSBidWZbdGhpcy5wb3MrK107IHZhbCArPSAoYiAmIDB4N2YpICogMHg4MDAwMDAwMDAwMDAwMDAwOyBpZiAoYiA8IDB4ODApIHJldHVybiB2YWw7XG5cbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdFeHBlY3RlZCB2YXJpbnQgbm90IG1vcmUgdGhhbiAxMCBieXRlcycpO1xuICAgIH0sXG5cbiAgICByZWFkVmFyaW50NjQ6IGZ1bmN0aW9uKCkge1xuICAgICAgICB2YXIgc3RhcnRQb3MgPSB0aGlzLnBvcyxcbiAgICAgICAgICAgIHZhbCA9IHRoaXMucmVhZFZhcmludCgpO1xuXG4gICAgICAgIGlmICh2YWwgPCBQT1dfMl82MykgcmV0dXJuIHZhbDtcblxuICAgICAgICB2YXIgcG9zID0gdGhpcy5wb3MgLSAyO1xuICAgICAgICB3aGlsZSAodGhpcy5idWZbcG9zXSA9PT0gMHhmZikgcG9zLS07XG4gICAgICAgIGlmIChwb3MgPCBzdGFydFBvcykgcG9zID0gc3RhcnRQb3M7XG5cbiAgICAgICAgdmFsID0gMDtcbiAgICAgICAgZm9yICh2YXIgaSA9IDA7IGkgPCBwb3MgLSBzdGFydFBvcyArIDE7IGkrKykge1xuICAgICAgICAgICAgdmFyIGIgPSB+dGhpcy5idWZbc3RhcnRQb3MgKyBpXSAmIDB4N2Y7XG4gICAgICAgICAgICB2YWwgKz0gaSA8IDQgPyBiIDw8IGkgKiA3IDogYiAqIE1hdGgucG93KDIsIGkgKiA3KTtcbiAgICAgICAgfVxuXG4gICAgICAgIHJldHVybiAtdmFsIC0gMTtcbiAgICB9LFxuXG4gICAgcmVhZFNWYXJpbnQ6IGZ1bmN0aW9uKCkge1xuICAgICAgICB2YXIgbnVtID0gdGhpcy5yZWFkVmFyaW50KCk7XG4gICAgICAgIHJldHVybiBudW0gJSAyID09PSAxID8gKG51bSArIDEpIC8gLTIgOiBudW0gLyAyOyAvLyB6aWd6YWcgZW5jb2RpbmdcbiAgICB9LFxuXG4gICAgcmVhZEJvb2xlYW46IGZ1bmN0aW9uKCkge1xuICAgICAgICByZXR1cm4gQm9vbGVhbih0aGlzLnJlYWRWYXJpbnQoKSk7XG4gICAgfSxcblxuICAgIHJlYWRTdHJpbmc6IGZ1bmN0aW9uKCkge1xuICAgICAgICB2YXIgZW5kID0gdGhpcy5yZWFkVmFyaW50KCkgKyB0aGlzLnBvcyxcbiAgICAgICAgICAgIHN0ciA9IHRoaXMuYnVmLnRvU3RyaW5nKCd1dGY4JywgdGhpcy5wb3MsIGVuZCk7XG4gICAgICAgIHRoaXMucG9zID0gZW5kO1xuICAgICAgICByZXR1cm4gc3RyO1xuICAgIH0sXG5cbiAgICByZWFkQnl0ZXM6IGZ1bmN0aW9uKCkge1xuICAgICAgICB2YXIgZW5kID0gdGhpcy5yZWFkVmFyaW50KCkgKyB0aGlzLnBvcyxcbiAgICAgICAgICAgIGJ1ZmZlciA9IHRoaXMuYnVmLnNsaWNlKHRoaXMucG9zLCBlbmQpO1xuICAgICAgICB0aGlzLnBvcyA9IGVuZDtcbiAgICAgICAgcmV0dXJuIGJ1ZmZlcjtcbiAgICB9LFxuXG4gICAgLy8gdmVyYm9zZSBmb3IgcGVyZm9ybWFuY2UgcmVhc29uczsgZG9lc24ndCBhZmZlY3QgZ3ppcHBlZCBzaXplXG5cbiAgICByZWFkUGFja2VkVmFyaW50OiBmdW5jdGlvbigpIHtcbiAgICAgICAgdmFyIGVuZCA9IHRoaXMucmVhZFZhcmludCgpICsgdGhpcy5wb3MsIGFyciA9IFtdO1xuICAgICAgICB3aGlsZSAodGhpcy5wb3MgPCBlbmQpIGFyci5wdXNoKHRoaXMucmVhZFZhcmludCgpKTtcbiAgICAgICAgcmV0dXJuIGFycjtcbiAgICB9LFxuICAgIHJlYWRQYWNrZWRTVmFyaW50OiBmdW5jdGlvbigpIHtcbiAgICAgICAgdmFyIGVuZCA9IHRoaXMucmVhZFZhcmludCgpICsgdGhpcy5wb3MsIGFyciA9IFtdO1xuICAgICAgICB3aGlsZSAodGhpcy5wb3MgPCBlbmQpIGFyci5wdXNoKHRoaXMucmVhZFNWYXJpbnQoKSk7XG4gICAgICAgIHJldHVybiBhcnI7XG4gICAgfSxcbiAgICByZWFkUGFja2VkQm9vbGVhbjogZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciBlbmQgPSB0aGlzLnJlYWRWYXJpbnQoKSArIHRoaXMucG9zLCBhcnIgPSBbXTtcbiAgICAgICAgd2hpbGUgKHRoaXMucG9zIDwgZW5kKSBhcnIucHVzaCh0aGlzLnJlYWRCb29sZWFuKCkpO1xuICAgICAgICByZXR1cm4gYXJyO1xuICAgIH0sXG4gICAgcmVhZFBhY2tlZEZsb2F0OiBmdW5jdGlvbigpIHtcbiAgICAgICAgdmFyIGVuZCA9IHRoaXMucmVhZFZhcmludCgpICsgdGhpcy5wb3MsIGFyciA9IFtdO1xuICAgICAgICB3aGlsZSAodGhpcy5wb3MgPCBlbmQpIGFyci5wdXNoKHRoaXMucmVhZEZsb2F0KCkpO1xuICAgICAgICByZXR1cm4gYXJyO1xuICAgIH0sXG4gICAgcmVhZFBhY2tlZERvdWJsZTogZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciBlbmQgPSB0aGlzLnJlYWRWYXJpbnQoKSArIHRoaXMucG9zLCBhcnIgPSBbXTtcbiAgICAgICAgd2hpbGUgKHRoaXMucG9zIDwgZW5kKSBhcnIucHVzaCh0aGlzLnJlYWREb3VibGUoKSk7XG4gICAgICAgIHJldHVybiBhcnI7XG4gICAgfSxcbiAgICByZWFkUGFja2VkRml4ZWQzMjogZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciBlbmQgPSB0aGlzLnJlYWRWYXJpbnQoKSArIHRoaXMucG9zLCBhcnIgPSBbXTtcbiAgICAgICAgd2hpbGUgKHRoaXMucG9zIDwgZW5kKSBhcnIucHVzaCh0aGlzLnJlYWRGaXhlZDMyKCkpO1xuICAgICAgICByZXR1cm4gYXJyO1xuICAgIH0sXG4gICAgcmVhZFBhY2tlZFNGaXhlZDMyOiBmdW5jdGlvbigpIHtcbiAgICAgICAgdmFyIGVuZCA9IHRoaXMucmVhZFZhcmludCgpICsgdGhpcy5wb3MsIGFyciA9IFtdO1xuICAgICAgICB3aGlsZSAodGhpcy5wb3MgPCBlbmQpIGFyci5wdXNoKHRoaXMucmVhZFNGaXhlZDMyKCkpO1xuICAgICAgICByZXR1cm4gYXJyO1xuICAgIH0sXG4gICAgcmVhZFBhY2tlZEZpeGVkNjQ6IGZ1bmN0aW9uKCkge1xuICAgICAgICB2YXIgZW5kID0gdGhpcy5yZWFkVmFyaW50KCkgKyB0aGlzLnBvcywgYXJyID0gW107XG4gICAgICAgIHdoaWxlICh0aGlzLnBvcyA8IGVuZCkgYXJyLnB1c2godGhpcy5yZWFkRml4ZWQ2NCgpKTtcbiAgICAgICAgcmV0dXJuIGFycjtcbiAgICB9LFxuICAgIHJlYWRQYWNrZWRTRml4ZWQ2NDogZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciBlbmQgPSB0aGlzLnJlYWRWYXJpbnQoKSArIHRoaXMucG9zLCBhcnIgPSBbXTtcbiAgICAgICAgd2hpbGUgKHRoaXMucG9zIDwgZW5kKSBhcnIucHVzaCh0aGlzLnJlYWRTRml4ZWQ2NCgpKTtcbiAgICAgICAgcmV0dXJuIGFycjtcbiAgICB9LFxuXG4gICAgc2tpcDogZnVuY3Rpb24odmFsKSB7XG4gICAgICAgIHZhciB0eXBlID0gdmFsICYgMHg3O1xuICAgICAgICBpZiAodHlwZSA9PT0gUGJmLlZhcmludCkgd2hpbGUgKHRoaXMuYnVmW3RoaXMucG9zKytdID4gMHg3Zikge31cbiAgICAgICAgZWxzZSBpZiAodHlwZSA9PT0gUGJmLkJ5dGVzKSB0aGlzLnBvcyA9IHRoaXMucmVhZFZhcmludCgpICsgdGhpcy5wb3M7XG4gICAgICAgIGVsc2UgaWYgKHR5cGUgPT09IFBiZi5GaXhlZDMyKSB0aGlzLnBvcyArPSA0O1xuICAgICAgICBlbHNlIGlmICh0eXBlID09PSBQYmYuRml4ZWQ2NCkgdGhpcy5wb3MgKz0gODtcbiAgICAgICAgZWxzZSB0aHJvdyBuZXcgRXJyb3IoJ1VuaW1wbGVtZW50ZWQgdHlwZTogJyArIHR5cGUpO1xuICAgIH0sXG5cbiAgICAvLyA9PT0gV1JJVElORyA9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PVxuXG4gICAgd3JpdGVUYWc6IGZ1bmN0aW9uKHRhZywgdHlwZSkge1xuICAgICAgICB0aGlzLndyaXRlVmFyaW50KCh0YWcgPDwgMykgfCB0eXBlKTtcbiAgICB9LFxuXG4gICAgcmVhbGxvYzogZnVuY3Rpb24obWluKSB7XG4gICAgICAgIHZhciBsZW5ndGggPSB0aGlzLmxlbmd0aCB8fCAxNjtcblxuICAgICAgICB3aGlsZSAobGVuZ3RoIDwgdGhpcy5wb3MgKyBtaW4pIGxlbmd0aCAqPSAyO1xuXG4gICAgICAgIGlmIChsZW5ndGggIT09IHRoaXMubGVuZ3RoKSB7XG4gICAgICAgICAgICB2YXIgYnVmID0gbmV3IEJ1ZmZlcihsZW5ndGgpO1xuICAgICAgICAgICAgdGhpcy5idWYuY29weShidWYpO1xuICAgICAgICAgICAgdGhpcy5idWYgPSBidWY7XG4gICAgICAgICAgICB0aGlzLmxlbmd0aCA9IGxlbmd0aDtcbiAgICAgICAgfVxuICAgIH0sXG5cbiAgICBmaW5pc2g6IGZ1bmN0aW9uKCkge1xuICAgICAgICB0aGlzLmxlbmd0aCA9IHRoaXMucG9zO1xuICAgICAgICB0aGlzLnBvcyA9IDA7XG4gICAgICAgIHJldHVybiB0aGlzLmJ1Zi5zbGljZSgwLCB0aGlzLmxlbmd0aCk7XG4gICAgfSxcblxuICAgIHdyaXRlRml4ZWQzMjogZnVuY3Rpb24odmFsKSB7XG4gICAgICAgIHRoaXMucmVhbGxvYyg0KTtcbiAgICAgICAgdGhpcy5idWYud3JpdGVVSW50MzJMRSh2YWwsIHRoaXMucG9zKTtcbiAgICAgICAgdGhpcy5wb3MgKz0gNDtcbiAgICB9LFxuXG4gICAgd3JpdGVTRml4ZWQzMjogZnVuY3Rpb24odmFsKSB7XG4gICAgICAgIHRoaXMucmVhbGxvYyg0KTtcbiAgICAgICAgdGhpcy5idWYud3JpdGVJbnQzMkxFKHZhbCwgdGhpcy5wb3MpO1xuICAgICAgICB0aGlzLnBvcyArPSA0O1xuICAgIH0sXG5cbiAgICB3cml0ZUZpeGVkNjQ6IGZ1bmN0aW9uKHZhbCkge1xuICAgICAgICB0aGlzLnJlYWxsb2MoOCk7XG4gICAgICAgIHRoaXMuYnVmLndyaXRlSW50MzJMRSh2YWwgJiAtMSwgdGhpcy5wb3MpO1xuICAgICAgICB0aGlzLmJ1Zi53cml0ZVVJbnQzMkxFKE1hdGguZmxvb3IodmFsICogU0hJRlRfUklHSFRfMzIpLCB0aGlzLnBvcyArIDQpO1xuICAgICAgICB0aGlzLnBvcyArPSA4O1xuICAgIH0sXG5cbiAgICB3cml0ZVNGaXhlZDY0OiBmdW5jdGlvbih2YWwpIHtcbiAgICAgICAgdGhpcy5yZWFsbG9jKDgpO1xuICAgICAgICB0aGlzLmJ1Zi53cml0ZUludDMyTEUodmFsICYgLTEsIHRoaXMucG9zKTtcbiAgICAgICAgdGhpcy5idWYud3JpdGVJbnQzMkxFKE1hdGguZmxvb3IodmFsICogU0hJRlRfUklHSFRfMzIpLCB0aGlzLnBvcyArIDQpO1xuICAgICAgICB0aGlzLnBvcyArPSA4O1xuICAgIH0sXG5cbiAgICB3cml0ZVZhcmludDogZnVuY3Rpb24odmFsKSB7XG4gICAgICAgIHZhbCA9ICt2YWw7XG5cbiAgICAgICAgaWYgKHZhbCA8PSAweDdmKSB7XG4gICAgICAgICAgICB0aGlzLnJlYWxsb2MoMSk7XG4gICAgICAgICAgICB0aGlzLmJ1Zlt0aGlzLnBvcysrXSA9IHZhbDtcblxuICAgICAgICB9IGVsc2UgaWYgKHZhbCA8PSAweDNmZmYpIHtcbiAgICAgICAgICAgIHRoaXMucmVhbGxvYygyKTtcbiAgICAgICAgICAgIHRoaXMuYnVmW3RoaXMucG9zKytdID0gKCh2YWwgPj4+IDApICYgMHg3ZikgfCAweDgwO1xuICAgICAgICAgICAgdGhpcy5idWZbdGhpcy5wb3MrK10gPSAoKHZhbCA+Pj4gNykgJiAweDdmKTtcblxuICAgICAgICB9IGVsc2UgaWYgKHZhbCA8PSAweDFmZmZmZikge1xuICAgICAgICAgICAgdGhpcy5yZWFsbG9jKDMpO1xuICAgICAgICAgICAgdGhpcy5idWZbdGhpcy5wb3MrK10gPSAoKHZhbCA+Pj4gMCkgJiAweDdmKSB8IDB4ODA7XG4gICAgICAgICAgICB0aGlzLmJ1Zlt0aGlzLnBvcysrXSA9ICgodmFsID4+PiA3KSAmIDB4N2YpIHwgMHg4MDtcbiAgICAgICAgICAgIHRoaXMuYnVmW3RoaXMucG9zKytdID0gKCh2YWwgPj4+IDE0KSAmIDB4N2YpO1xuXG4gICAgICAgIH0gZWxzZSBpZiAodmFsIDw9IDB4ZmZmZmZmZikge1xuICAgICAgICAgICAgdGhpcy5yZWFsbG9jKDQpO1xuICAgICAgICAgICAgdGhpcy5idWZbdGhpcy5wb3MrK10gPSAoKHZhbCA+Pj4gMCkgJiAweDdmKSB8IDB4ODA7XG4gICAgICAgICAgICB0aGlzLmJ1Zlt0aGlzLnBvcysrXSA9ICgodmFsID4+PiA3KSAmIDB4N2YpIHwgMHg4MDtcbiAgICAgICAgICAgIHRoaXMuYnVmW3RoaXMucG9zKytdID0gKCh2YWwgPj4+IDE0KSAmIDB4N2YpIHwgMHg4MDtcbiAgICAgICAgICAgIHRoaXMuYnVmW3RoaXMucG9zKytdID0gKCh2YWwgPj4+IDIxKSAmIDB4N2YpO1xuXG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICB2YXIgcG9zID0gdGhpcy5wb3M7XG4gICAgICAgICAgICB3aGlsZSAodmFsID49IDB4ODApIHtcbiAgICAgICAgICAgICAgICB0aGlzLnJlYWxsb2MoMSk7XG4gICAgICAgICAgICAgICAgdGhpcy5idWZbdGhpcy5wb3MrK10gPSAodmFsICYgMHhmZikgfCAweDgwO1xuICAgICAgICAgICAgICAgIHZhbCAvPSAweDgwO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgdGhpcy5yZWFsbG9jKDEpO1xuICAgICAgICAgICAgdGhpcy5idWZbdGhpcy5wb3MrK10gPSB2YWwgfCAwO1xuICAgICAgICAgICAgaWYgKHRoaXMucG9zIC0gcG9zID4gMTApIHRocm93IG5ldyBFcnJvcignR2l2ZW4gdmFyaW50IGRvZXNuXFwndCBmaXQgaW50byAxMCBieXRlcycpO1xuICAgICAgICB9XG4gICAgfSxcblxuICAgIHdyaXRlU1ZhcmludDogZnVuY3Rpb24odmFsKSB7XG4gICAgICAgIHRoaXMud3JpdGVWYXJpbnQodmFsIDwgMCA/IC12YWwgKiAyIC0gMSA6IHZhbCAqIDIpO1xuICAgIH0sXG5cbiAgICB3cml0ZUJvb2xlYW46IGZ1bmN0aW9uKHZhbCkge1xuICAgICAgICB0aGlzLndyaXRlVmFyaW50KEJvb2xlYW4odmFsKSk7XG4gICAgfSxcblxuICAgIHdyaXRlU3RyaW5nOiBmdW5jdGlvbihzdHIpIHtcbiAgICAgICAgc3RyID0gU3RyaW5nKHN0cik7XG4gICAgICAgIHZhciBieXRlcyA9IEJ1ZmZlci5ieXRlTGVuZ3RoKHN0cik7XG4gICAgICAgIHRoaXMud3JpdGVWYXJpbnQoYnl0ZXMpO1xuICAgICAgICB0aGlzLnJlYWxsb2MoYnl0ZXMpO1xuICAgICAgICB0aGlzLmJ1Zi53cml0ZShzdHIsIHRoaXMucG9zKTtcbiAgICAgICAgdGhpcy5wb3MgKz0gYnl0ZXM7XG4gICAgfSxcblxuICAgIHdyaXRlRmxvYXQ6IGZ1bmN0aW9uKHZhbCkge1xuICAgICAgICB0aGlzLnJlYWxsb2MoNCk7XG4gICAgICAgIHRoaXMuYnVmLndyaXRlRmxvYXRMRSh2YWwsIHRoaXMucG9zKTtcbiAgICAgICAgdGhpcy5wb3MgKz0gNDtcbiAgICB9LFxuXG4gICAgd3JpdGVEb3VibGU6IGZ1bmN0aW9uKHZhbCkge1xuICAgICAgICB0aGlzLnJlYWxsb2MoOCk7XG4gICAgICAgIHRoaXMuYnVmLndyaXRlRG91YmxlTEUodmFsLCB0aGlzLnBvcyk7XG4gICAgICAgIHRoaXMucG9zICs9IDg7XG4gICAgfSxcblxuICAgIHdyaXRlQnl0ZXM6IGZ1bmN0aW9uKGJ1ZmZlcikge1xuICAgICAgICB2YXIgbGVuID0gYnVmZmVyLmxlbmd0aDtcbiAgICAgICAgdGhpcy53cml0ZVZhcmludChsZW4pO1xuICAgICAgICB0aGlzLnJlYWxsb2MobGVuKTtcbiAgICAgICAgZm9yICh2YXIgaSA9IDA7IGkgPCBsZW47IGkrKykgdGhpcy5idWZbdGhpcy5wb3MrK10gPSBidWZmZXJbaV07XG4gICAgfSxcblxuICAgIHdyaXRlUmF3TWVzc2FnZTogZnVuY3Rpb24oZm4sIG9iaikge1xuICAgICAgICB0aGlzLnBvcysrOyAvLyByZXNlcnZlIDEgYnl0ZSBmb3Igc2hvcnQgbWVzc2FnZSBsZW5ndGhcblxuICAgICAgICAvLyB3cml0ZSB0aGUgbWVzc2FnZSBkaXJlY3RseSB0byB0aGUgYnVmZmVyIGFuZCBzZWUgaG93IG11Y2ggd2FzIHdyaXR0ZW5cbiAgICAgICAgdmFyIHN0YXJ0UG9zID0gdGhpcy5wb3M7XG4gICAgICAgIGZuKG9iaiwgdGhpcyk7XG4gICAgICAgIHZhciBsZW4gPSB0aGlzLnBvcyAtIHN0YXJ0UG9zO1xuXG4gICAgICAgIHZhciB2YXJpbnRMZW4gPVxuICAgICAgICAgICAgbGVuIDw9IDB4N2YgPyAxIDpcbiAgICAgICAgICAgIGxlbiA8PSAweDNmZmYgPyAyIDpcbiAgICAgICAgICAgIGxlbiA8PSAweDFmZmZmZiA/IDMgOlxuICAgICAgICAgICAgbGVuIDw9IDB4ZmZmZmZmZiA/IDQgOiBNYXRoLmNlaWwoTWF0aC5sb2cobGVuKSAvIChNYXRoLkxOMiAqIDcpKTtcblxuICAgICAgICAvLyBpZiAxIGJ5dGUgaXNuJ3QgZW5vdWdoIGZvciBlbmNvZGluZyBtZXNzYWdlIGxlbmd0aCwgc2hpZnQgdGhlIGRhdGEgdG8gdGhlIHJpZ2h0XG4gICAgICAgIGlmICh2YXJpbnRMZW4gPiAxKSB7XG4gICAgICAgICAgICB0aGlzLnJlYWxsb2ModmFyaW50TGVuIC0gMSk7XG4gICAgICAgICAgICBmb3IgKHZhciBpID0gdGhpcy5wb3MgLSAxOyBpID49IHN0YXJ0UG9zOyBpLS0pIHRoaXMuYnVmW2kgKyB2YXJpbnRMZW4gLSAxXSA9IHRoaXMuYnVmW2ldO1xuICAgICAgICB9XG5cbiAgICAgICAgLy8gZmluYWxseSwgd3JpdGUgdGhlIG1lc3NhZ2UgbGVuZ3RoIGluIHRoZSByZXNlcnZlZCBwbGFjZSBhbmQgcmVzdG9yZSB0aGUgcG9zaXRpb25cbiAgICAgICAgdGhpcy5wb3MgPSBzdGFydFBvcyAtIDE7XG4gICAgICAgIHRoaXMud3JpdGVWYXJpbnQobGVuKTtcbiAgICAgICAgdGhpcy5wb3MgKz0gbGVuO1xuICAgIH0sXG5cbiAgICB3cml0ZU1lc3NhZ2U6IGZ1bmN0aW9uKHRhZywgZm4sIG9iaikge1xuICAgICAgICB0aGlzLndyaXRlVGFnKHRhZywgUGJmLkJ5dGVzKTtcbiAgICAgICAgdGhpcy53cml0ZVJhd01lc3NhZ2UoZm4sIG9iaik7XG4gICAgfSxcblxuICAgIHdyaXRlUGFja2VkVmFyaW50OiAgIGZ1bmN0aW9uKHRhZywgYXJyKSB7IHRoaXMud3JpdGVNZXNzYWdlKHRhZywgd3JpdGVQYWNrZWRWYXJpbnQsIGFycik7ICAgfSxcbiAgICB3cml0ZVBhY2tlZFNWYXJpbnQ6ICBmdW5jdGlvbih0YWcsIGFycikgeyB0aGlzLndyaXRlTWVzc2FnZSh0YWcsIHdyaXRlUGFja2VkU1ZhcmludCwgYXJyKTsgIH0sXG4gICAgd3JpdGVQYWNrZWRCb29sZWFuOiAgZnVuY3Rpb24odGFnLCBhcnIpIHsgdGhpcy53cml0ZU1lc3NhZ2UodGFnLCB3cml0ZVBhY2tlZEJvb2xlYW4sIGFycik7ICB9LFxuICAgIHdyaXRlUGFja2VkRmxvYXQ6ICAgIGZ1bmN0aW9uKHRhZywgYXJyKSB7IHRoaXMud3JpdGVNZXNzYWdlKHRhZywgd3JpdGVQYWNrZWRGbG9hdCwgYXJyKTsgICAgfSxcbiAgICB3cml0ZVBhY2tlZERvdWJsZTogICBmdW5jdGlvbih0YWcsIGFycikgeyB0aGlzLndyaXRlTWVzc2FnZSh0YWcsIHdyaXRlUGFja2VkRG91YmxlLCBhcnIpOyAgIH0sXG4gICAgd3JpdGVQYWNrZWRGaXhlZDMyOiAgZnVuY3Rpb24odGFnLCBhcnIpIHsgdGhpcy53cml0ZU1lc3NhZ2UodGFnLCB3cml0ZVBhY2tlZEZpeGVkMzIsIGFycik7ICB9LFxuICAgIHdyaXRlUGFja2VkU0ZpeGVkMzI6IGZ1bmN0aW9uKHRhZywgYXJyKSB7IHRoaXMud3JpdGVNZXNzYWdlKHRhZywgd3JpdGVQYWNrZWRTRml4ZWQzMiwgYXJyKTsgfSxcbiAgICB3cml0ZVBhY2tlZEZpeGVkNjQ6ICBmdW5jdGlvbih0YWcsIGFycikgeyB0aGlzLndyaXRlTWVzc2FnZSh0YWcsIHdyaXRlUGFja2VkRml4ZWQ2NCwgYXJyKTsgIH0sXG4gICAgd3JpdGVQYWNrZWRTRml4ZWQ2NDogZnVuY3Rpb24odGFnLCBhcnIpIHsgdGhpcy53cml0ZU1lc3NhZ2UodGFnLCB3cml0ZVBhY2tlZFNGaXhlZDY0LCBhcnIpOyB9LFxuXG4gICAgd3JpdGVCeXRlc0ZpZWxkOiBmdW5jdGlvbih0YWcsIGJ1ZmZlcikge1xuICAgICAgICB0aGlzLndyaXRlVGFnKHRhZywgUGJmLkJ5dGVzKTtcbiAgICAgICAgdGhpcy53cml0ZUJ5dGVzKGJ1ZmZlcik7XG4gICAgfSxcbiAgICB3cml0ZUZpeGVkMzJGaWVsZDogZnVuY3Rpb24odGFnLCB2YWwpIHtcbiAgICAgICAgdGhpcy53cml0ZVRhZyh0YWcsIFBiZi5GaXhlZDMyKTtcbiAgICAgICAgdGhpcy53cml0ZUZpeGVkMzIodmFsKTtcbiAgICB9LFxuICAgIHdyaXRlU0ZpeGVkMzJGaWVsZDogZnVuY3Rpb24odGFnLCB2YWwpIHtcbiAgICAgICAgdGhpcy53cml0ZVRhZyh0YWcsIFBiZi5GaXhlZDMyKTtcbiAgICAgICAgdGhpcy53cml0ZVNGaXhlZDMyKHZhbCk7XG4gICAgfSxcbiAgICB3cml0ZUZpeGVkNjRGaWVsZDogZnVuY3Rpb24odGFnLCB2YWwpIHtcbiAgICAgICAgdGhpcy53cml0ZVRhZyh0YWcsIFBiZi5GaXhlZDY0KTtcbiAgICAgICAgdGhpcy53cml0ZUZpeGVkNjQodmFsKTtcbiAgICB9LFxuICAgIHdyaXRlU0ZpeGVkNjRGaWVsZDogZnVuY3Rpb24odGFnLCB2YWwpIHtcbiAgICAgICAgdGhpcy53cml0ZVRhZyh0YWcsIFBiZi5GaXhlZDY0KTtcbiAgICAgICAgdGhpcy53cml0ZVNGaXhlZDY0KHZhbCk7XG4gICAgfSxcbiAgICB3cml0ZVZhcmludEZpZWxkOiBmdW5jdGlvbih0YWcsIHZhbCkge1xuICAgICAgICB0aGlzLndyaXRlVGFnKHRhZywgUGJmLlZhcmludCk7XG4gICAgICAgIHRoaXMud3JpdGVWYXJpbnQodmFsKTtcbiAgICB9LFxuICAgIHdyaXRlU1ZhcmludEZpZWxkOiBmdW5jdGlvbih0YWcsIHZhbCkge1xuICAgICAgICB0aGlzLndyaXRlVGFnKHRhZywgUGJmLlZhcmludCk7XG4gICAgICAgIHRoaXMud3JpdGVTVmFyaW50KHZhbCk7XG4gICAgfSxcbiAgICB3cml0ZVN0cmluZ0ZpZWxkOiBmdW5jdGlvbih0YWcsIHN0cikge1xuICAgICAgICB0aGlzLndyaXRlVGFnKHRhZywgUGJmLkJ5dGVzKTtcbiAgICAgICAgdGhpcy53cml0ZVN0cmluZyhzdHIpO1xuICAgIH0sXG4gICAgd3JpdGVGbG9hdEZpZWxkOiBmdW5jdGlvbih0YWcsIHZhbCkge1xuICAgICAgICB0aGlzLndyaXRlVGFnKHRhZywgUGJmLkZpeGVkMzIpO1xuICAgICAgICB0aGlzLndyaXRlRmxvYXQodmFsKTtcbiAgICB9LFxuICAgIHdyaXRlRG91YmxlRmllbGQ6IGZ1bmN0aW9uKHRhZywgdmFsKSB7XG4gICAgICAgIHRoaXMud3JpdGVUYWcodGFnLCBQYmYuRml4ZWQ2NCk7XG4gICAgICAgIHRoaXMud3JpdGVEb3VibGUodmFsKTtcbiAgICB9LFxuICAgIHdyaXRlQm9vbGVhbkZpZWxkOiBmdW5jdGlvbih0YWcsIHZhbCkge1xuICAgICAgICB0aGlzLndyaXRlVmFyaW50RmllbGQodGFnLCBCb29sZWFuKHZhbCkpO1xuICAgIH1cbn07XG5cbmZ1bmN0aW9uIHdyaXRlUGFja2VkVmFyaW50KGFyciwgcGJmKSAgIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBhcnIubGVuZ3RoOyBpKyspIHBiZi53cml0ZVZhcmludChhcnJbaV0pOyAgIH1cbmZ1bmN0aW9uIHdyaXRlUGFja2VkU1ZhcmludChhcnIsIHBiZikgIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBhcnIubGVuZ3RoOyBpKyspIHBiZi53cml0ZVNWYXJpbnQoYXJyW2ldKTsgIH1cbmZ1bmN0aW9uIHdyaXRlUGFja2VkRmxvYXQoYXJyLCBwYmYpICAgIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBhcnIubGVuZ3RoOyBpKyspIHBiZi53cml0ZUZsb2F0KGFycltpXSk7ICAgIH1cbmZ1bmN0aW9uIHdyaXRlUGFja2VkRG91YmxlKGFyciwgcGJmKSAgIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBhcnIubGVuZ3RoOyBpKyspIHBiZi53cml0ZURvdWJsZShhcnJbaV0pOyAgIH1cbmZ1bmN0aW9uIHdyaXRlUGFja2VkQm9vbGVhbihhcnIsIHBiZikgIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBhcnIubGVuZ3RoOyBpKyspIHBiZi53cml0ZUJvb2xlYW4oYXJyW2ldKTsgIH1cbmZ1bmN0aW9uIHdyaXRlUGFja2VkRml4ZWQzMihhcnIsIHBiZikgIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBhcnIubGVuZ3RoOyBpKyspIHBiZi53cml0ZUZpeGVkMzIoYXJyW2ldKTsgIH1cbmZ1bmN0aW9uIHdyaXRlUGFja2VkU0ZpeGVkMzIoYXJyLCBwYmYpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBhcnIubGVuZ3RoOyBpKyspIHBiZi53cml0ZVNGaXhlZDMyKGFycltpXSk7IH1cbmZ1bmN0aW9uIHdyaXRlUGFja2VkRml4ZWQ2NChhcnIsIHBiZikgIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBhcnIubGVuZ3RoOyBpKyspIHBiZi53cml0ZUZpeGVkNjQoYXJyW2ldKTsgIH1cbmZ1bmN0aW9uIHdyaXRlUGFja2VkU0ZpeGVkNjQoYXJyLCBwYmYpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBhcnIubGVuZ3RoOyBpKyspIHBiZi53cml0ZVNGaXhlZDY0KGFycltpXSk7IH1cbiIsImV4cG9ydHMucmVhZCA9IGZ1bmN0aW9uIChidWZmZXIsIG9mZnNldCwgaXNMRSwgbUxlbiwgbkJ5dGVzKSB7XG4gIHZhciBlLCBtXG4gIHZhciBlTGVuID0gbkJ5dGVzICogOCAtIG1MZW4gLSAxXG4gIHZhciBlTWF4ID0gKDEgPDwgZUxlbikgLSAxXG4gIHZhciBlQmlhcyA9IGVNYXggPj4gMVxuICB2YXIgbkJpdHMgPSAtN1xuICB2YXIgaSA9IGlzTEUgPyAobkJ5dGVzIC0gMSkgOiAwXG4gIHZhciBkID0gaXNMRSA/IC0xIDogMVxuICB2YXIgcyA9IGJ1ZmZlcltvZmZzZXQgKyBpXVxuXG4gIGkgKz0gZFxuXG4gIGUgPSBzICYgKCgxIDw8ICgtbkJpdHMpKSAtIDEpXG4gIHMgPj49ICgtbkJpdHMpXG4gIG5CaXRzICs9IGVMZW5cbiAgZm9yICg7IG5CaXRzID4gMDsgZSA9IGUgKiAyNTYgKyBidWZmZXJbb2Zmc2V0ICsgaV0sIGkgKz0gZCwgbkJpdHMgLT0gOCkge31cblxuICBtID0gZSAmICgoMSA8PCAoLW5CaXRzKSkgLSAxKVxuICBlID4+PSAoLW5CaXRzKVxuICBuQml0cyArPSBtTGVuXG4gIGZvciAoOyBuQml0cyA+IDA7IG0gPSBtICogMjU2ICsgYnVmZmVyW29mZnNldCArIGldLCBpICs9IGQsIG5CaXRzIC09IDgpIHt9XG5cbiAgaWYgKGUgPT09IDApIHtcbiAgICBlID0gMSAtIGVCaWFzXG4gIH0gZWxzZSBpZiAoZSA9PT0gZU1heCkge1xuICAgIHJldHVybiBtID8gTmFOIDogKChzID8gLTEgOiAxKSAqIEluZmluaXR5KVxuICB9IGVsc2Uge1xuICAgIG0gPSBtICsgTWF0aC5wb3coMiwgbUxlbilcbiAgICBlID0gZSAtIGVCaWFzXG4gIH1cbiAgcmV0dXJuIChzID8gLTEgOiAxKSAqIG0gKiBNYXRoLnBvdygyLCBlIC0gbUxlbilcbn1cblxuZXhwb3J0cy53cml0ZSA9IGZ1bmN0aW9uIChidWZmZXIsIHZhbHVlLCBvZmZzZXQsIGlzTEUsIG1MZW4sIG5CeXRlcykge1xuICB2YXIgZSwgbSwgY1xuICB2YXIgZUxlbiA9IG5CeXRlcyAqIDggLSBtTGVuIC0gMVxuICB2YXIgZU1heCA9ICgxIDw8IGVMZW4pIC0gMVxuICB2YXIgZUJpYXMgPSBlTWF4ID4+IDFcbiAgdmFyIHJ0ID0gKG1MZW4gPT09IDIzID8gTWF0aC5wb3coMiwgLTI0KSAtIE1hdGgucG93KDIsIC03NykgOiAwKVxuICB2YXIgaSA9IGlzTEUgPyAwIDogKG5CeXRlcyAtIDEpXG4gIHZhciBkID0gaXNMRSA/IDEgOiAtMVxuICB2YXIgcyA9IHZhbHVlIDwgMCB8fCAodmFsdWUgPT09IDAgJiYgMSAvIHZhbHVlIDwgMCkgPyAxIDogMFxuXG4gIHZhbHVlID0gTWF0aC5hYnModmFsdWUpXG5cbiAgaWYgKGlzTmFOKHZhbHVlKSB8fCB2YWx1ZSA9PT0gSW5maW5pdHkpIHtcbiAgICBtID0gaXNOYU4odmFsdWUpID8gMSA6IDBcbiAgICBlID0gZU1heFxuICB9IGVsc2Uge1xuICAgIGUgPSBNYXRoLmZsb29yKE1hdGgubG9nKHZhbHVlKSAvIE1hdGguTE4yKVxuICAgIGlmICh2YWx1ZSAqIChjID0gTWF0aC5wb3coMiwgLWUpKSA8IDEpIHtcbiAgICAgIGUtLVxuICAgICAgYyAqPSAyXG4gICAgfVxuICAgIGlmIChlICsgZUJpYXMgPj0gMSkge1xuICAgICAgdmFsdWUgKz0gcnQgLyBjXG4gICAgfSBlbHNlIHtcbiAgICAgIHZhbHVlICs9IHJ0ICogTWF0aC5wb3coMiwgMSAtIGVCaWFzKVxuICAgIH1cbiAgICBpZiAodmFsdWUgKiBjID49IDIpIHtcbiAgICAgIGUrK1xuICAgICAgYyAvPSAyXG4gICAgfVxuXG4gICAgaWYgKGUgKyBlQmlhcyA+PSBlTWF4KSB7XG4gICAgICBtID0gMFxuICAgICAgZSA9IGVNYXhcbiAgICB9IGVsc2UgaWYgKGUgKyBlQmlhcyA+PSAxKSB7XG4gICAgICBtID0gKHZhbHVlICogYyAtIDEpICogTWF0aC5wb3coMiwgbUxlbilcbiAgICAgIGUgPSBlICsgZUJpYXNcbiAgICB9IGVsc2Uge1xuICAgICAgbSA9IHZhbHVlICogTWF0aC5wb3coMiwgZUJpYXMgLSAxKSAqIE1hdGgucG93KDIsIG1MZW4pXG4gICAgICBlID0gMFxuICAgIH1cbiAgfVxuXG4gIGZvciAoOyBtTGVuID49IDg7IGJ1ZmZlcltvZmZzZXQgKyBpXSA9IG0gJiAweGZmLCBpICs9IGQsIG0gLz0gMjU2LCBtTGVuIC09IDgpIHt9XG5cbiAgZSA9IChlIDw8IG1MZW4pIHwgbVxuICBlTGVuICs9IG1MZW5cbiAgZm9yICg7IGVMZW4gPiAwOyBidWZmZXJbb2Zmc2V0ICsgaV0gPSBlICYgMHhmZiwgaSArPSBkLCBlIC89IDI1NiwgZUxlbiAtPSA4KSB7fVxuXG4gIGJ1ZmZlcltvZmZzZXQgKyBpIC0gZF0gfD0gcyAqIDEyOFxufVxuIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IFBvaW50O1xuXG5mdW5jdGlvbiBQb2ludCh4LCB5KSB7XG4gICAgdGhpcy54ID0geDtcbiAgICB0aGlzLnkgPSB5O1xufVxuXG5Qb2ludC5wcm90b3R5cGUgPSB7XG4gICAgY2xvbmU6IGZ1bmN0aW9uKCkgeyByZXR1cm4gbmV3IFBvaW50KHRoaXMueCwgdGhpcy55KTsgfSxcblxuICAgIGFkZDogICAgIGZ1bmN0aW9uKHApIHsgcmV0dXJuIHRoaXMuY2xvbmUoKS5fYWRkKHApOyAgICAgfSxcbiAgICBzdWI6ICAgICBmdW5jdGlvbihwKSB7IHJldHVybiB0aGlzLmNsb25lKCkuX3N1YihwKTsgICAgIH0sXG4gICAgbXVsdDogICAgZnVuY3Rpb24oaykgeyByZXR1cm4gdGhpcy5jbG9uZSgpLl9tdWx0KGspOyAgICB9LFxuICAgIGRpdjogICAgIGZ1bmN0aW9uKGspIHsgcmV0dXJuIHRoaXMuY2xvbmUoKS5fZGl2KGspOyAgICAgfSxcbiAgICByb3RhdGU6ICBmdW5jdGlvbihhKSB7IHJldHVybiB0aGlzLmNsb25lKCkuX3JvdGF0ZShhKTsgIH0sXG4gICAgbWF0TXVsdDogZnVuY3Rpb24obSkgeyByZXR1cm4gdGhpcy5jbG9uZSgpLl9tYXRNdWx0KG0pOyB9LFxuICAgIHVuaXQ6ICAgIGZ1bmN0aW9uKCkgeyByZXR1cm4gdGhpcy5jbG9uZSgpLl91bml0KCk7IH0sXG4gICAgcGVycDogICAgZnVuY3Rpb24oKSB7IHJldHVybiB0aGlzLmNsb25lKCkuX3BlcnAoKTsgfSxcbiAgICByb3VuZDogICBmdW5jdGlvbigpIHsgcmV0dXJuIHRoaXMuY2xvbmUoKS5fcm91bmQoKTsgfSxcblxuICAgIG1hZzogZnVuY3Rpb24oKSB7XG4gICAgICAgIHJldHVybiBNYXRoLnNxcnQodGhpcy54ICogdGhpcy54ICsgdGhpcy55ICogdGhpcy55KTtcbiAgICB9LFxuXG4gICAgZXF1YWxzOiBmdW5jdGlvbihwKSB7XG4gICAgICAgIHJldHVybiB0aGlzLnggPT09IHAueCAmJlxuICAgICAgICAgICAgICAgdGhpcy55ID09PSBwLnk7XG4gICAgfSxcblxuICAgIGRpc3Q6IGZ1bmN0aW9uKHApIHtcbiAgICAgICAgcmV0dXJuIE1hdGguc3FydCh0aGlzLmRpc3RTcXIocCkpO1xuICAgIH0sXG5cbiAgICBkaXN0U3FyOiBmdW5jdGlvbihwKSB7XG4gICAgICAgIHZhciBkeCA9IHAueCAtIHRoaXMueCxcbiAgICAgICAgICAgIGR5ID0gcC55IC0gdGhpcy55O1xuICAgICAgICByZXR1cm4gZHggKiBkeCArIGR5ICogZHk7XG4gICAgfSxcblxuICAgIGFuZ2xlOiBmdW5jdGlvbigpIHtcbiAgICAgICAgcmV0dXJuIE1hdGguYXRhbjIodGhpcy55LCB0aGlzLngpO1xuICAgIH0sXG5cbiAgICBhbmdsZVRvOiBmdW5jdGlvbihiKSB7XG4gICAgICAgIHJldHVybiBNYXRoLmF0YW4yKHRoaXMueSAtIGIueSwgdGhpcy54IC0gYi54KTtcbiAgICB9LFxuXG4gICAgYW5nbGVXaXRoOiBmdW5jdGlvbihiKSB7XG4gICAgICAgIHJldHVybiB0aGlzLmFuZ2xlV2l0aFNlcChiLngsIGIueSk7XG4gICAgfSxcblxuICAgIC8vIEZpbmQgdGhlIGFuZ2xlIG9mIHRoZSB0d28gdmVjdG9ycywgc29sdmluZyB0aGUgZm9ybXVsYSBmb3IgdGhlIGNyb3NzIHByb2R1Y3QgYSB4IGIgPSB8YXx8YnxzaW4ozrgpIGZvciDOuC5cbiAgICBhbmdsZVdpdGhTZXA6IGZ1bmN0aW9uKHgsIHkpIHtcbiAgICAgICAgcmV0dXJuIE1hdGguYXRhbjIoXG4gICAgICAgICAgICB0aGlzLnggKiB5IC0gdGhpcy55ICogeCxcbiAgICAgICAgICAgIHRoaXMueCAqIHggKyB0aGlzLnkgKiB5KTtcbiAgICB9LFxuXG4gICAgX21hdE11bHQ6IGZ1bmN0aW9uKG0pIHtcbiAgICAgICAgdmFyIHggPSBtWzBdICogdGhpcy54ICsgbVsxXSAqIHRoaXMueSxcbiAgICAgICAgICAgIHkgPSBtWzJdICogdGhpcy54ICsgbVszXSAqIHRoaXMueTtcbiAgICAgICAgdGhpcy54ID0geDtcbiAgICAgICAgdGhpcy55ID0geTtcbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcblxuICAgIF9hZGQ6IGZ1bmN0aW9uKHApIHtcbiAgICAgICAgdGhpcy54ICs9IHAueDtcbiAgICAgICAgdGhpcy55ICs9IHAueTtcbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcblxuICAgIF9zdWI6IGZ1bmN0aW9uKHApIHtcbiAgICAgICAgdGhpcy54IC09IHAueDtcbiAgICAgICAgdGhpcy55IC09IHAueTtcbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcblxuICAgIF9tdWx0OiBmdW5jdGlvbihrKSB7XG4gICAgICAgIHRoaXMueCAqPSBrO1xuICAgICAgICB0aGlzLnkgKj0gaztcbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcblxuICAgIF9kaXY6IGZ1bmN0aW9uKGspIHtcbiAgICAgICAgdGhpcy54IC89IGs7XG4gICAgICAgIHRoaXMueSAvPSBrO1xuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9LFxuXG4gICAgX3VuaXQ6IGZ1bmN0aW9uKCkge1xuICAgICAgICB0aGlzLl9kaXYodGhpcy5tYWcoKSk7XG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH0sXG5cbiAgICBfcGVycDogZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciB5ID0gdGhpcy55O1xuICAgICAgICB0aGlzLnkgPSB0aGlzLng7XG4gICAgICAgIHRoaXMueCA9IC15O1xuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9LFxuXG4gICAgX3JvdGF0ZTogZnVuY3Rpb24oYW5nbGUpIHtcbiAgICAgICAgdmFyIGNvcyA9IE1hdGguY29zKGFuZ2xlKSxcbiAgICAgICAgICAgIHNpbiA9IE1hdGguc2luKGFuZ2xlKSxcbiAgICAgICAgICAgIHggPSBjb3MgKiB0aGlzLnggLSBzaW4gKiB0aGlzLnksXG4gICAgICAgICAgICB5ID0gc2luICogdGhpcy54ICsgY29zICogdGhpcy55O1xuICAgICAgICB0aGlzLnggPSB4O1xuICAgICAgICB0aGlzLnkgPSB5O1xuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9LFxuXG4gICAgX3JvdW5kOiBmdW5jdGlvbigpIHtcbiAgICAgICAgdGhpcy54ID0gTWF0aC5yb3VuZCh0aGlzLngpO1xuICAgICAgICB0aGlzLnkgPSBNYXRoLnJvdW5kKHRoaXMueSk7XG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cbn07XG5cbi8vIGNvbnN0cnVjdHMgUG9pbnQgZnJvbSBhbiBhcnJheSBpZiBuZWNlc3NhcnlcblBvaW50LmNvbnZlcnQgPSBmdW5jdGlvbiAoYSkge1xuICAgIGlmIChhIGluc3RhbmNlb2YgUG9pbnQpIHtcbiAgICAgICAgcmV0dXJuIGE7XG4gICAgfVxuICAgIGlmIChBcnJheS5pc0FycmF5KGEpKSB7XG4gICAgICAgIHJldHVybiBuZXcgUG9pbnQoYVswXSwgYVsxXSk7XG4gICAgfVxuICAgIHJldHVybiBhO1xufTtcbiIsIm1vZHVsZS5leHBvcnRzLlZlY3RvclRpbGUgPSByZXF1aXJlKCcuL2xpYi92ZWN0b3J0aWxlLmpzJyk7XG5tb2R1bGUuZXhwb3J0cy5WZWN0b3JUaWxlRmVhdHVyZSA9IHJlcXVpcmUoJy4vbGliL3ZlY3RvcnRpbGVmZWF0dXJlLmpzJyk7XG5tb2R1bGUuZXhwb3J0cy5WZWN0b3JUaWxlTGF5ZXIgPSByZXF1aXJlKCcuL2xpYi92ZWN0b3J0aWxlbGF5ZXIuanMnKTtcbiIsIid1c2Ugc3RyaWN0JztcblxudmFyIFZlY3RvclRpbGVMYXllciA9IHJlcXVpcmUoJy4vdmVjdG9ydGlsZWxheWVyJyk7XG5cbm1vZHVsZS5leHBvcnRzID0gVmVjdG9yVGlsZTtcblxuZnVuY3Rpb24gVmVjdG9yVGlsZShwYmYsIGVuZCkge1xuICAgIHRoaXMubGF5ZXJzID0gcGJmLnJlYWRGaWVsZHMocmVhZFRpbGUsIHt9LCBlbmQpO1xufVxuXG5mdW5jdGlvbiByZWFkVGlsZSh0YWcsIGxheWVycywgcGJmKSB7XG4gICAgaWYgKHRhZyA9PT0gMykge1xuICAgICAgICB2YXIgbGF5ZXIgPSBuZXcgVmVjdG9yVGlsZUxheWVyKHBiZiwgcGJmLnJlYWRWYXJpbnQoKSArIHBiZi5wb3MpO1xuICAgICAgICBpZiAobGF5ZXIubGVuZ3RoKSBsYXllcnNbbGF5ZXIubmFtZV0gPSBsYXllcjtcbiAgICB9XG59XG5cbiIsIid1c2Ugc3RyaWN0JztcblxudmFyIFBvaW50ID0gcmVxdWlyZSgncG9pbnQtZ2VvbWV0cnknKTtcblxubW9kdWxlLmV4cG9ydHMgPSBWZWN0b3JUaWxlRmVhdHVyZTtcblxuZnVuY3Rpb24gVmVjdG9yVGlsZUZlYXR1cmUocGJmLCBlbmQsIGV4dGVudCwga2V5cywgdmFsdWVzKSB7XG4gICAgLy8gUHVibGljXG4gICAgdGhpcy5wcm9wZXJ0aWVzID0ge307XG4gICAgdGhpcy5leHRlbnQgPSBleHRlbnQ7XG4gICAgdGhpcy50eXBlID0gMDtcblxuICAgIC8vIFByaXZhdGVcbiAgICB0aGlzLl9wYmYgPSBwYmY7XG4gICAgdGhpcy5fZ2VvbWV0cnkgPSAtMTtcbiAgICB0aGlzLl9rZXlzID0ga2V5cztcbiAgICB0aGlzLl92YWx1ZXMgPSB2YWx1ZXM7XG5cbiAgICBwYmYucmVhZEZpZWxkcyhyZWFkRmVhdHVyZSwgdGhpcywgZW5kKTtcbn1cblxuZnVuY3Rpb24gcmVhZEZlYXR1cmUodGFnLCBmZWF0dXJlLCBwYmYpIHtcbiAgICBpZiAodGFnID09IDEpIGZlYXR1cmUuX2lkID0gcGJmLnJlYWRWYXJpbnQoKTtcbiAgICBlbHNlIGlmICh0YWcgPT0gMikgcmVhZFRhZyhwYmYsIGZlYXR1cmUpO1xuICAgIGVsc2UgaWYgKHRhZyA9PSAzKSBmZWF0dXJlLnR5cGUgPSBwYmYucmVhZFZhcmludCgpO1xuICAgIGVsc2UgaWYgKHRhZyA9PSA0KSBmZWF0dXJlLl9nZW9tZXRyeSA9IHBiZi5wb3M7XG59XG5cbmZ1bmN0aW9uIHJlYWRUYWcocGJmLCBmZWF0dXJlKSB7XG4gICAgdmFyIGVuZCA9IHBiZi5yZWFkVmFyaW50KCkgKyBwYmYucG9zO1xuXG4gICAgd2hpbGUgKHBiZi5wb3MgPCBlbmQpIHtcbiAgICAgICAgdmFyIGtleSA9IGZlYXR1cmUuX2tleXNbcGJmLnJlYWRWYXJpbnQoKV0sXG4gICAgICAgICAgICB2YWx1ZSA9IGZlYXR1cmUuX3ZhbHVlc1twYmYucmVhZFZhcmludCgpXTtcbiAgICAgICAgZmVhdHVyZS5wcm9wZXJ0aWVzW2tleV0gPSB2YWx1ZTtcbiAgICB9XG59XG5cblZlY3RvclRpbGVGZWF0dXJlLnR5cGVzID0gWydVbmtub3duJywgJ1BvaW50JywgJ0xpbmVTdHJpbmcnLCAnUG9seWdvbiddO1xuXG5WZWN0b3JUaWxlRmVhdHVyZS5wcm90b3R5cGUubG9hZEdlb21ldHJ5ID0gZnVuY3Rpb24oKSB7XG4gICAgdmFyIHBiZiA9IHRoaXMuX3BiZjtcbiAgICBwYmYucG9zID0gdGhpcy5fZ2VvbWV0cnk7XG5cbiAgICB2YXIgZW5kID0gcGJmLnJlYWRWYXJpbnQoKSArIHBiZi5wb3MsXG4gICAgICAgIGNtZCA9IDEsXG4gICAgICAgIGxlbmd0aCA9IDAsXG4gICAgICAgIHggPSAwLFxuICAgICAgICB5ID0gMCxcbiAgICAgICAgbGluZXMgPSBbXSxcbiAgICAgICAgbGluZTtcblxuICAgIHdoaWxlIChwYmYucG9zIDwgZW5kKSB7XG4gICAgICAgIGlmICghbGVuZ3RoKSB7XG4gICAgICAgICAgICB2YXIgY21kTGVuID0gcGJmLnJlYWRWYXJpbnQoKTtcbiAgICAgICAgICAgIGNtZCA9IGNtZExlbiAmIDB4NztcbiAgICAgICAgICAgIGxlbmd0aCA9IGNtZExlbiA+PiAzO1xuICAgICAgICB9XG5cbiAgICAgICAgbGVuZ3RoLS07XG5cbiAgICAgICAgaWYgKGNtZCA9PT0gMSB8fCBjbWQgPT09IDIpIHtcbiAgICAgICAgICAgIHggKz0gcGJmLnJlYWRTVmFyaW50KCk7XG4gICAgICAgICAgICB5ICs9IHBiZi5yZWFkU1ZhcmludCgpO1xuXG4gICAgICAgICAgICBpZiAoY21kID09PSAxKSB7IC8vIG1vdmVUb1xuICAgICAgICAgICAgICAgIGlmIChsaW5lKSBsaW5lcy5wdXNoKGxpbmUpO1xuICAgICAgICAgICAgICAgIGxpbmUgPSBbXTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgbGluZS5wdXNoKG5ldyBQb2ludCh4LCB5KSk7XG5cbiAgICAgICAgfSBlbHNlIGlmIChjbWQgPT09IDcpIHtcblxuICAgICAgICAgICAgLy8gV29ya2Fyb3VuZCBmb3IgaHR0cHM6Ly9naXRodWIuY29tL21hcGJveC9tYXBuaWstdmVjdG9yLXRpbGUvaXNzdWVzLzkwXG4gICAgICAgICAgICBpZiAobGluZSkge1xuICAgICAgICAgICAgICAgIGxpbmUucHVzaChsaW5lWzBdLmNsb25lKCkpOyAvLyBjbG9zZVBvbHlnb25cbiAgICAgICAgICAgIH1cblxuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKCd1bmtub3duIGNvbW1hbmQgJyArIGNtZCk7XG4gICAgICAgIH1cbiAgICB9XG5cbiAgICBpZiAobGluZSkgbGluZXMucHVzaChsaW5lKTtcblxuICAgIHJldHVybiBsaW5lcztcbn07XG5cblZlY3RvclRpbGVGZWF0dXJlLnByb3RvdHlwZS5iYm94ID0gZnVuY3Rpb24oKSB7XG4gICAgdmFyIHBiZiA9IHRoaXMuX3BiZjtcbiAgICBwYmYucG9zID0gdGhpcy5fZ2VvbWV0cnk7XG5cbiAgICB2YXIgZW5kID0gcGJmLnJlYWRWYXJpbnQoKSArIHBiZi5wb3MsXG4gICAgICAgIGNtZCA9IDEsXG4gICAgICAgIGxlbmd0aCA9IDAsXG4gICAgICAgIHggPSAwLFxuICAgICAgICB5ID0gMCxcbiAgICAgICAgeDEgPSBJbmZpbml0eSxcbiAgICAgICAgeDIgPSAtSW5maW5pdHksXG4gICAgICAgIHkxID0gSW5maW5pdHksXG4gICAgICAgIHkyID0gLUluZmluaXR5O1xuXG4gICAgd2hpbGUgKHBiZi5wb3MgPCBlbmQpIHtcbiAgICAgICAgaWYgKCFsZW5ndGgpIHtcbiAgICAgICAgICAgIHZhciBjbWRMZW4gPSBwYmYucmVhZFZhcmludCgpO1xuICAgICAgICAgICAgY21kID0gY21kTGVuICYgMHg3O1xuICAgICAgICAgICAgbGVuZ3RoID0gY21kTGVuID4+IDM7XG4gICAgICAgIH1cblxuICAgICAgICBsZW5ndGgtLTtcblxuICAgICAgICBpZiAoY21kID09PSAxIHx8IGNtZCA9PT0gMikge1xuICAgICAgICAgICAgeCArPSBwYmYucmVhZFNWYXJpbnQoKTtcbiAgICAgICAgICAgIHkgKz0gcGJmLnJlYWRTVmFyaW50KCk7XG4gICAgICAgICAgICBpZiAoeCA8IHgxKSB4MSA9IHg7XG4gICAgICAgICAgICBpZiAoeCA+IHgyKSB4MiA9IHg7XG4gICAgICAgICAgICBpZiAoeSA8IHkxKSB5MSA9IHk7XG4gICAgICAgICAgICBpZiAoeSA+IHkyKSB5MiA9IHk7XG5cbiAgICAgICAgfSBlbHNlIGlmIChjbWQgIT09IDcpIHtcbiAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcigndW5rbm93biBjb21tYW5kICcgKyBjbWQpO1xuICAgICAgICB9XG4gICAgfVxuXG4gICAgcmV0dXJuIFt4MSwgeTEsIHgyLCB5Ml07XG59O1xuXG5WZWN0b3JUaWxlRmVhdHVyZS5wcm90b3R5cGUudG9HZW9KU09OID0gZnVuY3Rpb24oeCwgeSwgeikge1xuICAgIHZhciBzaXplID0gdGhpcy5leHRlbnQgKiBNYXRoLnBvdygyLCB6KSxcbiAgICAgICAgeDAgPSB0aGlzLmV4dGVudCAqIHgsXG4gICAgICAgIHkwID0gdGhpcy5leHRlbnQgKiB5LFxuICAgICAgICBjb29yZHMgPSB0aGlzLmxvYWRHZW9tZXRyeSgpLFxuICAgICAgICB0eXBlID0gVmVjdG9yVGlsZUZlYXR1cmUudHlwZXNbdGhpcy50eXBlXTtcblxuICAgIGZvciAodmFyIGkgPSAwOyBpIDwgY29vcmRzLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgIHZhciBsaW5lID0gY29vcmRzW2ldO1xuICAgICAgICBmb3IgKHZhciBqID0gMDsgaiA8IGxpbmUubGVuZ3RoOyBqKyspIHtcbiAgICAgICAgICAgIHZhciBwID0gbGluZVtqXSwgeTIgPSAxODAgLSAocC55ICsgeTApICogMzYwIC8gc2l6ZTtcbiAgICAgICAgICAgIGxpbmVbal0gPSBbXG4gICAgICAgICAgICAgICAgKHAueCArIHgwKSAqIDM2MCAvIHNpemUgLSAxODAsXG4gICAgICAgICAgICAgICAgMzYwIC8gTWF0aC5QSSAqIE1hdGguYXRhbihNYXRoLmV4cCh5MiAqIE1hdGguUEkgLyAxODApKSAtIDkwXG4gICAgICAgICAgICBdO1xuICAgICAgICB9XG4gICAgfVxuXG4gICAgaWYgKHR5cGUgPT09ICdQb2ludCcgJiYgY29vcmRzLmxlbmd0aCA9PT0gMSkge1xuICAgICAgICBjb29yZHMgPSBjb29yZHNbMF1bMF07XG4gICAgfSBlbHNlIGlmICh0eXBlID09PSAnUG9pbnQnKSB7XG4gICAgICAgIGNvb3JkcyA9IGNvb3Jkc1swXTtcbiAgICAgICAgdHlwZSA9ICdNdWx0aVBvaW50JztcbiAgICB9IGVsc2UgaWYgKHR5cGUgPT09ICdMaW5lU3RyaW5nJyAmJiBjb29yZHMubGVuZ3RoID09PSAxKSB7XG4gICAgICAgIGNvb3JkcyA9IGNvb3Jkc1swXTtcbiAgICB9IGVsc2UgaWYgKHR5cGUgPT09ICdMaW5lU3RyaW5nJykge1xuICAgICAgICB0eXBlID0gJ011bHRpTGluZVN0cmluZyc7XG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgICAgdHlwZTogXCJGZWF0dXJlXCIsXG4gICAgICAgIGdlb21ldHJ5OiB7XG4gICAgICAgICAgICB0eXBlOiB0eXBlLFxuICAgICAgICAgICAgY29vcmRpbmF0ZXM6IGNvb3Jkc1xuICAgICAgICB9LFxuICAgICAgICBwcm9wZXJ0aWVzOiB0aGlzLnByb3BlcnRpZXNcbiAgICB9O1xufTtcbiIsIid1c2Ugc3RyaWN0JztcblxudmFyIFZlY3RvclRpbGVGZWF0dXJlID0gcmVxdWlyZSgnLi92ZWN0b3J0aWxlZmVhdHVyZS5qcycpO1xuXG5tb2R1bGUuZXhwb3J0cyA9IFZlY3RvclRpbGVMYXllcjtcblxuZnVuY3Rpb24gVmVjdG9yVGlsZUxheWVyKHBiZiwgZW5kKSB7XG4gICAgLy8gUHVibGljXG4gICAgdGhpcy52ZXJzaW9uID0gMTtcbiAgICB0aGlzLm5hbWUgPSBudWxsO1xuICAgIHRoaXMuZXh0ZW50ID0gNDA5NjtcbiAgICB0aGlzLmxlbmd0aCA9IDA7XG5cbiAgICAvLyBQcml2YXRlXG4gICAgdGhpcy5fcGJmID0gcGJmO1xuICAgIHRoaXMuX2tleXMgPSBbXTtcbiAgICB0aGlzLl92YWx1ZXMgPSBbXTtcbiAgICB0aGlzLl9mZWF0dXJlcyA9IFtdO1xuXG4gICAgcGJmLnJlYWRGaWVsZHMocmVhZExheWVyLCB0aGlzLCBlbmQpO1xuXG4gICAgdGhpcy5sZW5ndGggPSB0aGlzLl9mZWF0dXJlcy5sZW5ndGg7XG59XG5cbmZ1bmN0aW9uIHJlYWRMYXllcih0YWcsIGxheWVyLCBwYmYpIHtcbiAgICBpZiAodGFnID09PSAxNSkgbGF5ZXIudmVyc2lvbiA9IHBiZi5yZWFkVmFyaW50KCk7XG4gICAgZWxzZSBpZiAodGFnID09PSAxKSBsYXllci5uYW1lID0gcGJmLnJlYWRTdHJpbmcoKTtcbiAgICBlbHNlIGlmICh0YWcgPT09IDUpIGxheWVyLmV4dGVudCA9IHBiZi5yZWFkVmFyaW50KCk7XG4gICAgZWxzZSBpZiAodGFnID09PSAyKSBsYXllci5fZmVhdHVyZXMucHVzaChwYmYucG9zKTtcbiAgICBlbHNlIGlmICh0YWcgPT09IDMpIGxheWVyLl9rZXlzLnB1c2gocGJmLnJlYWRTdHJpbmcoKSk7XG4gICAgZWxzZSBpZiAodGFnID09PSA0KSBsYXllci5fdmFsdWVzLnB1c2gocmVhZFZhbHVlTWVzc2FnZShwYmYpKTtcbn1cblxuZnVuY3Rpb24gcmVhZFZhbHVlTWVzc2FnZShwYmYpIHtcbiAgICB2YXIgdmFsdWUgPSBudWxsLFxuICAgICAgICBlbmQgPSBwYmYucmVhZFZhcmludCgpICsgcGJmLnBvcztcblxuICAgIHdoaWxlIChwYmYucG9zIDwgZW5kKSB7XG4gICAgICAgIHZhciB0YWcgPSBwYmYucmVhZFZhcmludCgpID4+IDM7XG5cbiAgICAgICAgdmFsdWUgPSB0YWcgPT09IDEgPyBwYmYucmVhZFN0cmluZygpIDpcbiAgICAgICAgICAgIHRhZyA9PT0gMiA/IHBiZi5yZWFkRmxvYXQoKSA6XG4gICAgICAgICAgICB0YWcgPT09IDMgPyBwYmYucmVhZERvdWJsZSgpIDpcbiAgICAgICAgICAgIHRhZyA9PT0gNCA/IHBiZi5yZWFkVmFyaW50NjQoKSA6XG4gICAgICAgICAgICB0YWcgPT09IDUgPyBwYmYucmVhZFZhcmludCgpIDpcbiAgICAgICAgICAgIHRhZyA9PT0gNiA/IHBiZi5yZWFkU1ZhcmludCgpIDpcbiAgICAgICAgICAgIHRhZyA9PT0gNyA/IHBiZi5yZWFkQm9vbGVhbigpIDogbnVsbDtcbiAgICB9XG5cbiAgICByZXR1cm4gdmFsdWU7XG59XG5cbi8vIHJldHVybiBmZWF0dXJlIGBpYCBmcm9tIHRoaXMgbGF5ZXIgYXMgYSBgVmVjdG9yVGlsZUZlYXR1cmVgXG5WZWN0b3JUaWxlTGF5ZXIucHJvdG90eXBlLmZlYXR1cmUgPSBmdW5jdGlvbihpKSB7XG4gICAgaWYgKGkgPCAwIHx8IGkgPj0gdGhpcy5fZmVhdHVyZXMubGVuZ3RoKSB0aHJvdyBuZXcgRXJyb3IoJ2ZlYXR1cmUgaW5kZXggb3V0IG9mIGJvdW5kcycpO1xuXG4gICAgdGhpcy5fcGJmLnBvcyA9IHRoaXMuX2ZlYXR1cmVzW2ldO1xuXG4gICAgdmFyIGVuZCA9IHRoaXMuX3BiZi5yZWFkVmFyaW50KCkgKyB0aGlzLl9wYmYucG9zO1xuICAgIHJldHVybiBuZXcgVmVjdG9yVGlsZUZlYXR1cmUodGhpcy5fcGJmLCBlbmQsIHRoaXMuZXh0ZW50LCB0aGlzLl9rZXlzLCB0aGlzLl92YWx1ZXMpO1xufTtcbiIsIi8qKlxyXG4gKiBDcmVhdGVkIGJ5IFJ5YW4gV2hpdGxleSwgRGFuaWVsIER1YXJ0ZSwgYW5kIE5pY2hvbGFzIEhhbGxhaGFuXHJcbiAqICAgIG9uIDYvMDMvMTQuXHJcbiAqL1xyXG52YXIgVXRpbCA9IHJlcXVpcmUoJy4vTVZUVXRpbCcpO1xyXG52YXIgU3RhdGljTGFiZWwgPSByZXF1aXJlKCcuL1N0YXRpY0xhYmVsL1N0YXRpY0xhYmVsLmpzJyk7XHJcblxyXG5tb2R1bGUuZXhwb3J0cyA9IE1WVEZlYXR1cmU7XHJcblxyXG5mdW5jdGlvbiBNVlRGZWF0dXJlKG12dExheWVyLCB2dGYsIGN0eCwgaWQsIHN0eWxlKSB7XHJcbiAgaWYgKCF2dGYpIHJldHVybiBudWxsO1xyXG5cclxuICAvLyBBcHBseSBhbGwgb2YgdGhlIHByb3BlcnRpZXMgb2YgdnRmIHRvIHRoaXMgb2JqZWN0LlxyXG4gIGZvciAodmFyIGtleSBpbiB2dGYpIHtcclxuICAgIHRoaXNba2V5XSA9IHZ0ZltrZXldO1xyXG4gIH1cclxuXHJcbiAgdGhpcy5tdnRMYXllciA9IG12dExheWVyO1xyXG4gIHRoaXMubXZ0U291cmNlID0gbXZ0TGF5ZXIubXZ0U291cmNlO1xyXG4gIHRoaXMubWFwID0gbXZ0TGF5ZXIubXZ0U291cmNlLm1hcDtcclxuXHJcbiAgdGhpcy5pZCA9IGlkO1xyXG5cclxuICB0aGlzLmxheWVyTGluayA9IHRoaXMubXZ0U291cmNlLmxheWVyTGluaztcclxuICB0aGlzLnRvZ2dsZUVuYWJsZWQgPSB0cnVlO1xyXG4gIHRoaXMuc2VsZWN0ZWQgPSBmYWxzZTtcclxuXHJcbiAgLy8gaG93IG11Y2ggd2UgZGl2aWRlIHRoZSBjb29yZGluYXRlIGZyb20gdGhlIHZlY3RvciB0aWxlXHJcbiAgdGhpcy5kaXZpc29yID0gdnRmLmV4dGVudCAvIGN0eC50aWxlU2l6ZTtcclxuICB0aGlzLmV4dGVudCA9IHZ0Zi5leHRlbnQ7XHJcbiAgdGhpcy50aWxlU2l6ZSA9IGN0eC50aWxlU2l6ZTtcclxuXHJcbiAgLy9BbiBvYmplY3QgdG8gc3RvcmUgdGhlIHBhdGhzIGFuZCBjb250ZXh0cyBmb3IgdGhpcyBmZWF0dXJlXHJcbiAgdGhpcy50aWxlcyA9IHt9O1xyXG5cclxuICB0aGlzLnN0eWxlID0gc3R5bGU7XHJcblxyXG4gIC8vQWRkIHRvIHRoZSBjb2xsZWN0aW9uXHJcbiAgdGhpcy5hZGRUaWxlRmVhdHVyZSh2dGYsIGN0eCk7XHJcblxyXG4gIHZhciBzZWxmID0gdGhpcztcclxuICB0aGlzLm1hcC5vbignem9vbWVuZCcsIGZ1bmN0aW9uKCkge1xyXG4gICAgc2VsZi5zdGF0aWNMYWJlbCA9IG51bGw7XHJcbiAgfSk7XHJcblxyXG4gIGlmIChzdHlsZSAmJiBzdHlsZS5keW5hbWljTGFiZWwgJiYgdHlwZW9mIHN0eWxlLmR5bmFtaWNMYWJlbCA9PT0gJ2Z1bmN0aW9uJykge1xyXG4gICAgdGhpcy5keW5hbWljTGFiZWwgPSB0aGlzLm12dFNvdXJjZS5keW5hbWljTGFiZWwuY3JlYXRlRmVhdHVyZSh0aGlzKTtcclxuICB9XHJcblxyXG4gIGFqYXgoc2VsZik7XHJcbn1cclxuXHJcblxyXG5mdW5jdGlvbiBhamF4KHNlbGYpIHtcclxuICB2YXIgc3R5bGUgPSBzZWxmLnN0eWxlO1xyXG4gIGlmIChzdHlsZSAmJiBzdHlsZS5hamF4U291cmNlICYmIHR5cGVvZiBzdHlsZS5hamF4U291cmNlID09PSAnZnVuY3Rpb24nKSB7XHJcbiAgICB2YXIgYWpheEVuZHBvaW50ID0gc3R5bGUuYWpheFNvdXJjZShzZWxmKTtcclxuICAgIGlmIChhamF4RW5kcG9pbnQpIHtcclxuICAgICAgVXRpbC5nZXRKU09OKGFqYXhFbmRwb2ludCwgZnVuY3Rpb24oZXJyb3IsIHJlc3BvbnNlLCBib2R5KSB7XHJcbiAgICAgICAgaWYgKGVycm9yKSB7XHJcbiAgICAgICAgICB0aHJvdyBbJ2FqYXhTb3VyY2UgQUpBWCBFcnJvcicsIGVycm9yXTtcclxuICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgYWpheENhbGxiYWNrKHNlbGYsIHJlc3BvbnNlKTtcclxuICAgICAgICAgIHJldHVybiB0cnVlO1xyXG4gICAgICAgIH1cclxuICAgICAgfSk7XHJcbiAgICB9XHJcbiAgfVxyXG4gIHJldHVybiBmYWxzZTtcclxufVxyXG5cclxuZnVuY3Rpb24gYWpheENhbGxiYWNrKHNlbGYsIHJlc3BvbnNlKSB7XHJcbiAgc2VsZi5hamF4RGF0YSA9IHJlc3BvbnNlO1xyXG5cclxuICAvKipcclxuICAgKiBZb3UgY2FuIGF0dGFjaCBhIGNhbGxiYWNrIGZ1bmN0aW9uIHRvIGEgZmVhdHVyZSBpbiB5b3VyIGFwcFxyXG4gICAqIHRoYXQgd2lsbCBnZXQgY2FsbGVkIHdoZW5ldmVyIG5ldyBhamF4RGF0YSBjb21lcyBpbi4gVGhpc1xyXG4gICAqIGNhbiBiZSB1c2VkIHRvIHVwZGF0ZSBVSSB0aGF0IGxvb2tzIGF0IGRhdGEgZnJvbSB3aXRoaW4gYSBmZWF0dXJlLlxyXG4gICAqXHJcbiAgICogc2V0U3R5bGUgbWF5IHBvc3NpYmx5IGhhdmUgYSBzdHlsZSB3aXRoIGEgZGlmZmVyZW50IGFqYXhEYXRhIHNvdXJjZSxcclxuICAgKiBhbmQgeW91IHdvdWxkIHBvdGVudGlhbGx5IGdldCBuZXcgY29udGV4dHVhbCBkYXRhIGZvciB5b3VyIGZlYXR1cmUuXHJcbiAgICpcclxuICAgKiBUT0RPOiBUaGlzIG5lZWRzIHRvIGJlIGRvY3VtZW50ZWQuXHJcbiAgICovXHJcbiAgaWYgKHR5cGVvZiBzZWxmLmFqYXhEYXRhUmVjZWl2ZWQgPT09ICdmdW5jdGlvbicpIHtcclxuICAgIHNlbGYuYWpheERhdGFSZWNlaXZlZChzZWxmLCByZXNwb25zZSk7XHJcbiAgfVxyXG5cclxuICBzZWxmLl9zZXRTdHlsZShzZWxmLm12dExheWVyLnN0eWxlKTtcclxuICByZWRyYXdUaWxlcyhzZWxmKTtcclxufVxyXG5cclxuTVZURmVhdHVyZS5wcm90b3R5cGUuX3NldFN0eWxlID0gZnVuY3Rpb24oc3R5bGVGbikge1xyXG4gIHRoaXMuc3R5bGUgPSBzdHlsZUZuKHRoaXMsIHRoaXMuYWpheERhdGEpO1xyXG5cclxuICAvLyBUaGUgbGFiZWwgZ2V0cyByZW1vdmVkLCBhbmQgdGhlIChyZSlkcmF3LFxyXG4gIC8vIHRoYXQgaXMgaW5pdGlhdGVkIGJ5IHRoZSBNVlRMYXllciBjcmVhdGVzIGEgbmV3IGxhYmVsLlxyXG4gIHRoaXMucmVtb3ZlTGFiZWwoKTtcclxufTtcclxuXHJcbk1WVEZlYXR1cmUucHJvdG90eXBlLnNldFN0eWxlID0gZnVuY3Rpb24oc3R5bGVGbikge1xyXG4gIHRoaXMuYWpheERhdGEgPSBudWxsO1xyXG4gIHRoaXMuc3R5bGUgPSBzdHlsZUZuKHRoaXMsIG51bGwpO1xyXG4gIHZhciBoYXNBamF4U291cmNlID0gYWpheCh0aGlzKTtcclxuICBpZiAoIWhhc0FqYXhTb3VyY2UpIHtcclxuICAgIC8vIFRoZSBsYWJlbCBnZXRzIHJlbW92ZWQsIGFuZCB0aGUgKHJlKWRyYXcsXHJcbiAgICAvLyB0aGF0IGlzIGluaXRpYXRlZCBieSB0aGUgTVZUTGF5ZXIgY3JlYXRlcyBhIG5ldyBsYWJlbC5cclxuICAgIHRoaXMucmVtb3ZlTGFiZWwoKTtcclxuICB9XHJcbn07XHJcblxyXG5NVlRGZWF0dXJlLnByb3RvdHlwZS5kcmF3ID0gZnVuY3Rpb24oY2FudmFzSUQpIHtcclxuICAvL0dldCB0aGUgaW5mbyBmcm9tIHRoZSB0aWxlcyBsaXN0XHJcbiAgdmFyIHRpbGVJbmZvID0gIHRoaXMudGlsZXNbY2FudmFzSURdO1xyXG5cclxuICB2YXIgdnRmID0gdGlsZUluZm8udnRmO1xyXG4gIHZhciBjdHggPSB0aWxlSW5mby5jdHg7XHJcblxyXG4gIC8vR2V0IHRoZSBhY3R1YWwgY2FudmFzIGZyb20gdGhlIHBhcmVudCBsYXllcidzIF90aWxlcyBvYmplY3QuXHJcbiAgdmFyIHh5ID0gY2FudmFzSUQuc3BsaXQoXCI6XCIpLnNsaWNlKDEsIDMpLmpvaW4oXCI6XCIpO1xyXG4gIGN0eC5jYW52YXMgPSB0aGlzLm12dExheWVyLl90aWxlc1t4eV07XHJcblxyXG4vLyAgVGhpcyBjb3VsZCBiZSB1c2VkIHRvIGRpcmVjdGx5IGNvbXB1dGUgdGhlIHN0eWxlIGZ1bmN0aW9uIGZyb20gdGhlIGxheWVyIG9uIGV2ZXJ5IGRyYXcuXHJcbi8vICBUaGlzIGlzIG11Y2ggbGVzcyBlZmZpY2llbnQuLi5cclxuLy8gIHRoaXMuc3R5bGUgPSB0aGlzLm12dExheWVyLnN0eWxlKHRoaXMpO1xyXG5cclxuICBpZiAodGhpcy5zZWxlY3RlZCkge1xyXG4gICAgdmFyIHN0eWxlID0gdGhpcy5zdHlsZS5zZWxlY3RlZCB8fCB0aGlzLnN0eWxlO1xyXG4gIH0gZWxzZSB7XHJcbiAgICB2YXIgc3R5bGUgPSB0aGlzLnN0eWxlO1xyXG4gIH1cclxuXHJcbiAgc3dpdGNoICh2dGYudHlwZSkge1xyXG4gICAgY2FzZSAxOiAvL1BvaW50XHJcbiAgICAgIHRoaXMuX2RyYXdQb2ludChjdHgsIHZ0Zi5jb29yZGluYXRlcywgc3R5bGUpO1xyXG4gICAgICBpZiAoIXRoaXMuc3RhdGljTGFiZWwgJiYgdHlwZW9mIHRoaXMuc3R5bGUuc3RhdGljTGFiZWwgPT09ICdmdW5jdGlvbicpIHtcclxuICAgICAgICBpZiAodGhpcy5zdHlsZS5hamF4U291cmNlICYmICF0aGlzLmFqYXhEYXRhKSB7XHJcbiAgICAgICAgICBicmVhaztcclxuICAgICAgICB9XHJcbiAgICAgICAgdGhpcy5fZHJhd1N0YXRpY0xhYmVsKGN0eCwgdnRmLmNvb3JkaW5hdGVzLCBzdHlsZSk7XHJcbiAgICAgIH1cclxuICAgICAgYnJlYWs7XHJcblxyXG4gICAgY2FzZSAyOiAvL0xpbmVTdHJpbmdcclxuICAgICAgdGhpcy5fZHJhd0xpbmVTdHJpbmcoY3R4LCB2dGYuY29vcmRpbmF0ZXMsIHN0eWxlKTtcclxuICAgICAgYnJlYWs7XHJcblxyXG4gICAgY2FzZSAzOiAvL1BvbHlnb25cclxuICAgICAgdGhpcy5fZHJhd1BvbHlnb24oY3R4LCB2dGYuY29vcmRpbmF0ZXMsIHN0eWxlKTtcclxuICAgICAgYnJlYWs7XHJcblxyXG4gICAgZGVmYXVsdDpcclxuICAgICAgdGhyb3cgbmV3IEVycm9yKCdVbm1hbmFnZWQgdHlwZTogJyArIHZ0Zi50eXBlKTtcclxuICB9XHJcblxyXG59O1xyXG5cclxuTVZURmVhdHVyZS5wcm90b3R5cGUuZ2V0UGF0aHNGb3JUaWxlID0gZnVuY3Rpb24oY2FudmFzSUQpIHtcclxuICAvL0dldCB0aGUgaW5mbyBmcm9tIHRoZSBwYXJ0cyBsaXN0XHJcbiAgcmV0dXJuIHRoaXMudGlsZXNbY2FudmFzSURdLnBhdGhzO1xyXG59O1xyXG5cclxuTVZURmVhdHVyZS5wcm90b3R5cGUuYWRkVGlsZUZlYXR1cmUgPSBmdW5jdGlvbih2dGYsIGN0eCkge1xyXG4gIC8vU3RvcmUgdGhlIGltcG9ydGFudCBpdGVtcyBpbiB0aGUgdGlsZXMgbGlzdFxyXG5cclxuICAvL1dlIG9ubHkgd2FudCB0byBzdG9yZSBpbmZvIGZvciB0aWxlcyBmb3IgdGhlIGN1cnJlbnQgbWFwIHpvb20uICBJZiBpdCBpcyB0aWxlIGluZm8gZm9yIGFub3RoZXIgem9vbSBsZXZlbCwgaWdub3JlIGl0XHJcbiAgLy9BbHNvLCBpZiB0aGVyZSBhcmUgZXhpc3RpbmcgdGlsZXMgaW4gdGhlIGxpc3QgZm9yIG90aGVyIHpvb20gbGV2ZWxzLCBleHB1bmdlIHRoZW0uXHJcbiAgdmFyIHpvb20gPSB0aGlzLm1hcC5nZXRab29tKCk7XHJcblxyXG4gIGlmKGN0eC56b29tICE9IHpvb20pIHJldHVybjtcclxuXHJcbiAgdGhpcy5jbGVhclRpbGVGZWF0dXJlcyh6b29tKTsgLy9UT0RPOiBUaGlzIGl0ZXJhdGVzIHRocnUgYWxsIHRpbGVzIGV2ZXJ5IHRpbWUgYSBuZXcgdGlsZSBpcyBhZGRlZC4gIEZpZ3VyZSBvdXQgYSBiZXR0ZXIgd2F5IHRvIGRvIHRoaXMuXHJcblxyXG4gIHRoaXMudGlsZXNbY3R4LmlkXSA9IHtcclxuICAgIGN0eDogY3R4LFxyXG4gICAgdnRmOiB2dGYsXHJcbiAgICBwYXRoczogW11cclxuICB9O1xyXG5cclxufTtcclxuXHJcblxyXG4vKipcclxuICogQ2xlYXIgdGhlIGlubmVyIGxpc3Qgb2YgdGlsZSBmZWF0dXJlcyBpZiB0aGV5IGRvbid0IG1hdGNoIHRoZSBnaXZlbiB6b29tLlxyXG4gKlxyXG4gKiBAcGFyYW0gem9vbVxyXG4gKi9cclxuTVZURmVhdHVyZS5wcm90b3R5cGUuY2xlYXJUaWxlRmVhdHVyZXMgPSBmdW5jdGlvbih6b29tKSB7XHJcbiAgLy9JZiBzdG9yZWQgdGlsZXMgZXhpc3QgZm9yIG90aGVyIHpvb20gbGV2ZWxzLCBleHB1bmdlIHRoZW0gZnJvbSB0aGUgbGlzdC5cclxuICBmb3IgKHZhciBrZXkgaW4gdGhpcy50aWxlcykge1xyXG4gICAgIGlmKGtleS5zcGxpdChcIjpcIilbMF0gIT0gem9vbSkgZGVsZXRlIHRoaXMudGlsZXNba2V5XTtcclxuICB9XHJcbn07XHJcblxyXG4vKipcclxuICogUmVkcmF3cyBhbGwgb2YgdGhlIHRpbGVzIGFzc29jaWF0ZWQgd2l0aCBhIGZlYXR1cmUuIFVzZWZ1bCBmb3JcclxuICogc3R5bGUgY2hhbmdlIGFuZCB0b2dnbGluZy5cclxuICpcclxuICogQHBhcmFtIHNlbGZcclxuICovXHJcbmZ1bmN0aW9uIHJlZHJhd1RpbGVzKHNlbGYpIHtcclxuICAvL1JlZHJhdyB0aGUgd2hvbGUgdGlsZSwgbm90IGp1c3QgdGhpcyB2dGZcclxuICB2YXIgdGlsZXMgPSBzZWxmLnRpbGVzO1xyXG4gIHZhciBtdnRMYXllciA9IHNlbGYubXZ0TGF5ZXI7XHJcblxyXG4gIGZvciAodmFyIGlkIGluIHRpbGVzKSB7XHJcbiAgICB2YXIgdGlsZVpvb20gPSBwYXJzZUludChpZC5zcGxpdCgnOicpWzBdKTtcclxuICAgIHZhciBtYXBab29tID0gc2VsZi5tYXAuZ2V0Wm9vbSgpO1xyXG4gICAgaWYgKHRpbGVab29tID09PSBtYXBab29tKSB7XHJcbiAgICAgIC8vUmVkcmF3IHRoZSB0aWxlXHJcbiAgICAgIG12dExheWVyLnJlZHJhd1RpbGUoaWQpO1xyXG4gICAgfVxyXG4gIH1cclxufVxyXG5cclxuTVZURmVhdHVyZS5wcm90b3R5cGUudG9nZ2xlID0gZnVuY3Rpb24oKSB7XHJcbiAgaWYgKHRoaXMuc2VsZWN0ZWQpIHtcclxuICAgIHRoaXMuZGVzZWxlY3QoKTtcclxuICB9IGVsc2Uge1xyXG4gICAgdGhpcy5zZWxlY3QoKTtcclxuICB9XHJcbn07XHJcblxyXG5NVlRGZWF0dXJlLnByb3RvdHlwZS5zZWxlY3QgPSBmdW5jdGlvbiAoKSB7XHJcbiAgdGhpcy5zZWxlY3RlZCA9IHRydWU7XHJcbiAgdGhpcy5tdnRTb3VyY2UuZmVhdHVyZVNlbGVjdGVkKHRoaXMpO1xyXG4gIHJlZHJhd1RpbGVzKHRoaXMpO1xyXG4gIHZhciBsaW5rZWRGZWF0dXJlID0gdGhpcy5saW5rZWRGZWF0dXJlKCk7XHJcbiAgaWYgKGxpbmtlZEZlYXR1cmUgJiYgbGlua2VkRmVhdHVyZS5zdGF0aWNMYWJlbCAmJiAhbGlua2VkRmVhdHVyZS5zdGF0aWNMYWJlbC5zZWxlY3RlZCkge1xyXG4gICAgbGlua2VkRmVhdHVyZS5zdGF0aWNMYWJlbC5zZWxlY3QoKTtcclxuICB9XHJcbn07XHJcblxyXG5NVlRGZWF0dXJlLnByb3RvdHlwZS5kZXNlbGVjdCA9IGZ1bmN0aW9uKCkge1xyXG4gIHRoaXMuc2VsZWN0ZWQgPSBmYWxzZTtcclxuICB0aGlzLm12dFNvdXJjZS5mZWF0dXJlRGVzZWxlY3RlZCh0aGlzKTtcclxuICByZWRyYXdUaWxlcyh0aGlzKTtcclxuICB2YXIgbGlua2VkRmVhdHVyZSA9IHRoaXMubGlua2VkRmVhdHVyZSgpO1xyXG4gIGlmIChsaW5rZWRGZWF0dXJlICYmIGxpbmtlZEZlYXR1cmUuc3RhdGljTGFiZWwgJiYgbGlua2VkRmVhdHVyZS5zdGF0aWNMYWJlbC5zZWxlY3RlZCkge1xyXG4gICAgbGlua2VkRmVhdHVyZS5zdGF0aWNMYWJlbC5kZXNlbGVjdCgpO1xyXG4gIH1cclxufTtcclxuXHJcbk1WVEZlYXR1cmUucHJvdG90eXBlLm9uID0gZnVuY3Rpb24oZXZlbnRUeXBlLCBjYWxsYmFjaykge1xyXG4gIHRoaXMuX2V2ZW50SGFuZGxlcnNbZXZlbnRUeXBlXSA9IGNhbGxiYWNrO1xyXG59O1xyXG5cclxuTVZURmVhdHVyZS5wcm90b3R5cGUuX2RyYXdQb2ludCA9IGZ1bmN0aW9uKGN0eCwgY29vcmRzQXJyYXksIHN0eWxlKSB7XHJcbiAgaWYgKCFzdHlsZSkgcmV0dXJuO1xyXG4gIGlmICghY3R4IHx8ICFjdHguY2FudmFzKSByZXR1cm47XHJcblxyXG4gIHZhciB0aWxlID0gdGhpcy50aWxlc1tjdHguaWRdO1xyXG5cclxuICAvL0dldCByYWRpdXNcclxuICB2YXIgcmFkaXVzID0gMTtcclxuICBpZiAodHlwZW9mIHN0eWxlLnJhZGl1cyA9PT0gJ2Z1bmN0aW9uJykge1xyXG4gICAgcmFkaXVzID0gc3R5bGUucmFkaXVzKGN0eC56b29tKTsgLy9BbGxvd3MgZm9yIHNjYWxlIGRlcGVuZGVudCByZWRuZXJpbmdcclxuICB9XHJcbiAgZWxzZXtcclxuICAgIHJhZGl1cyA9IHN0eWxlLnJhZGl1cztcclxuICB9XHJcblxyXG4gIHZhciBwID0gdGhpcy5fdGlsZVBvaW50KGNvb3Jkc0FycmF5WzBdWzBdKTtcclxuICB2YXIgYyA9IGN0eC5jYW52YXM7XHJcbiAgdmFyIGN0eDJkO1xyXG4gIHRyeXtcclxuICAgIGN0eDJkID0gYy5nZXRDb250ZXh0KCcyZCcpO1xyXG4gIH1cclxuICBjYXRjaChlKXtcclxuICAgIGNvbnNvbGUubG9nKFwiX2RyYXdQb2ludCBlcnJvcjogXCIgKyBlKTtcclxuICAgIHJldHVybjtcclxuICB9XHJcblxyXG4gIGN0eDJkLmJlZ2luUGF0aCgpO1xyXG4gIGN0eDJkLmZpbGxTdHlsZSA9IHN0eWxlLmNvbG9yO1xyXG4gIGN0eDJkLmFyYyhwLngsIHAueSwgcmFkaXVzLCAwLCBNYXRoLlBJICogMik7XHJcbiAgY3R4MmQuY2xvc2VQYXRoKCk7XHJcbiAgY3R4MmQuZmlsbCgpO1xyXG5cclxuICBpZihzdHlsZS5saW5lV2lkdGggJiYgc3R5bGUuc3Ryb2tlU3R5bGUpe1xyXG4gICAgY3R4MmQubGluZVdpZHRoID0gc3R5bGUubGluZVdpZHRoO1xyXG4gICAgY3R4MmQuc3Ryb2tlU3R5bGUgPSBzdHlsZS5zdHJva2VTdHlsZTtcclxuICAgIGN0eDJkLnN0cm9rZSgpO1xyXG4gIH1cclxuXHJcbiAgY3R4MmQucmVzdG9yZSgpO1xyXG4gIHRpbGUucGF0aHMucHVzaChbcF0pO1xyXG59O1xyXG5cclxuTVZURmVhdHVyZS5wcm90b3R5cGUuX2RyYXdMaW5lU3RyaW5nID0gZnVuY3Rpb24oY3R4LCBjb29yZHNBcnJheSwgc3R5bGUpIHtcclxuICBpZiAoIXN0eWxlKSByZXR1cm47XHJcbiAgaWYgKCFjdHggfHwgIWN0eC5jYW52YXMpIHJldHVybjtcclxuXHJcbiAgdmFyIGN0eDJkID0gY3R4LmNhbnZhcy5nZXRDb250ZXh0KCcyZCcpO1xyXG4gIGN0eDJkLnN0cm9rZVN0eWxlID0gc3R5bGUuY29sb3I7XHJcbiAgY3R4MmQubGluZVdpZHRoID0gc3R5bGUuc2l6ZTtcclxuICBjdHgyZC5iZWdpblBhdGgoKTtcclxuXHJcbiAgdmFyIHByb2pDb29yZHMgPSBbXTtcclxuICB2YXIgdGlsZSA9IHRoaXMudGlsZXNbY3R4LmlkXTtcclxuXHJcbiAgZm9yICh2YXIgZ2lkeCBpbiBjb29yZHNBcnJheSkge1xyXG4gICAgdmFyIGNvb3JkcyA9IGNvb3Jkc0FycmF5W2dpZHhdO1xyXG5cclxuICAgIGZvciAoaSA9IDA7IGkgPCBjb29yZHMubGVuZ3RoOyBpKyspIHtcclxuICAgICAgdmFyIG1ldGhvZCA9IChpID09PSAwID8gJ21vdmUnIDogJ2xpbmUnKSArICdUbyc7XHJcbiAgICAgIHZhciBwcm9qID0gdGhpcy5fdGlsZVBvaW50KGNvb3Jkc1tpXSk7XHJcbiAgICAgIHByb2pDb29yZHMucHVzaChwcm9qKTtcclxuICAgICAgY3R4MmRbbWV0aG9kXShwcm9qLngsIHByb2oueSk7XHJcbiAgICB9XHJcbiAgfVxyXG5cclxuICBjdHgyZC5zdHJva2UoKTtcclxuICBjdHgyZC5yZXN0b3JlKCk7XHJcblxyXG4gIHRpbGUucGF0aHMucHVzaChwcm9qQ29vcmRzKTtcclxufTtcclxuXHJcbk1WVEZlYXR1cmUucHJvdG90eXBlLl9kcmF3UG9seWdvbiA9IGZ1bmN0aW9uKGN0eCwgY29vcmRzQXJyYXksIHN0eWxlKSB7XHJcbiAgaWYgKCFzdHlsZSkgcmV0dXJuO1xyXG4gIGlmICghY3R4IHx8ICFjdHguY2FudmFzKSByZXR1cm47XHJcblxyXG4gIHZhciBjdHgyZCA9IGN0eC5jYW52YXMuZ2V0Q29udGV4dCgnMmQnKTtcclxuICB2YXIgb3V0bGluZSA9IHN0eWxlLm91dGxpbmU7XHJcblxyXG4gIC8vIGNvbG9yIG1heSBiZSBkZWZpbmVkIHZpYSBmdW5jdGlvbiB0byBtYWtlIGNob3JvcGxldGggd29yayByaWdodFxyXG4gIGlmICh0eXBlb2Ygc3R5bGUuY29sb3IgPT09ICdmdW5jdGlvbicpIHtcclxuICAgIGN0eDJkLmZpbGxTdHlsZSA9IHN0eWxlLmNvbG9yKGN0eDJkKTtcclxuICB9IGVsc2Uge1xyXG4gICAgY3R4MmQuZmlsbFN0eWxlID0gc3R5bGUuY29sb3I7XHJcbiAgfVxyXG5cclxuICBpZiAob3V0bGluZSkge1xyXG4gICAgY3R4MmQuc3Ryb2tlU3R5bGUgPSBvdXRsaW5lLmNvbG9yO1xyXG4gICAgY3R4MmQubGluZVdpZHRoID0gb3V0bGluZS5zaXplO1xyXG4gIH1cclxuICBjdHgyZC5iZWdpblBhdGgoKTtcclxuXHJcbiAgdmFyIHByb2pDb29yZHMgPSBbXTtcclxuICB2YXIgdGlsZSA9IHRoaXMudGlsZXNbY3R4LmlkXTtcclxuXHJcbiAgdmFyIGZlYXR1cmVMYWJlbCA9IHRoaXMuZHluYW1pY0xhYmVsO1xyXG4gIGlmIChmZWF0dXJlTGFiZWwpIHtcclxuICAgIGZlYXR1cmVMYWJlbC5hZGRUaWxlUG9seXMoY3R4LCBjb29yZHNBcnJheSk7XHJcbiAgfVxyXG5cclxuICBmb3IgKHZhciBnaWR4ID0gMCwgbGVuID0gY29vcmRzQXJyYXkubGVuZ3RoOyBnaWR4IDwgbGVuOyBnaWR4KyspIHtcclxuICAgIHZhciBjb29yZHMgPSBjb29yZHNBcnJheVtnaWR4XTtcclxuXHJcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IGNvb3Jkcy5sZW5ndGg7IGkrKykge1xyXG4gICAgICB2YXIgY29vcmQgPSBjb29yZHNbaV07XHJcbiAgICAgIHZhciBtZXRob2QgPSAoaSA9PT0gMCA/ICdtb3ZlJyA6ICdsaW5lJykgKyAnVG8nO1xyXG4gICAgICB2YXIgcHJvaiA9IHRoaXMuX3RpbGVQb2ludChjb29yZHNbaV0pO1xyXG4gICAgICBwcm9qQ29vcmRzLnB1c2gocHJvaik7XHJcbiAgICAgIGN0eDJkW21ldGhvZF0ocHJvai54LCBwcm9qLnkpO1xyXG4gICAgfVxyXG4gIH1cclxuXHJcbiAgY3R4MmQuY2xvc2VQYXRoKCk7XHJcbiAgY3R4MmQuZmlsbCgpO1xyXG4gIGlmIChvdXRsaW5lKSB7XHJcbiAgICBjdHgyZC5zdHJva2UoKTtcclxuICB9XHJcblxyXG4gIHRpbGUucGF0aHMucHVzaChwcm9qQ29vcmRzKTtcclxuXHJcbn07XHJcblxyXG5NVlRGZWF0dXJlLnByb3RvdHlwZS5fZHJhd1N0YXRpY0xhYmVsID0gZnVuY3Rpb24oY3R4LCBjb29yZHNBcnJheSwgc3R5bGUpIHtcclxuICBpZiAoIXN0eWxlKSByZXR1cm47XHJcbiAgaWYgKCFjdHgpIHJldHVybjtcclxuXHJcbiAgLy8gSWYgdGhlIGNvcnJlc3BvbmRpbmcgbGF5ZXIgaXMgbm90IG9uIHRoZSBtYXAsIFxyXG4gIC8vIHdlIGRvbnQgd2FudCB0byBwdXQgb24gYSBsYWJlbC5cclxuICBpZiAoIXRoaXMubXZ0TGF5ZXIuX21hcCkgcmV0dXJuO1xyXG5cclxuICB2YXIgdmVjUHQgPSB0aGlzLl90aWxlUG9pbnQoY29vcmRzQXJyYXlbMF1bMF0pO1xyXG5cclxuICAvLyBXZSdyZSBtYWtpbmcgYSBzdGFuZGFyZCBMZWFmbGV0IE1hcmtlciBmb3IgdGhpcyBsYWJlbC5cclxuICB2YXIgcCA9IHRoaXMuX3Byb2plY3QodmVjUHQsIGN0eC50aWxlLngsIGN0eC50aWxlLnksIHRoaXMuZXh0ZW50LCB0aGlzLnRpbGVTaXplKTsgLy92ZWN0aWxlIHB0IHRvIG1lcmMgcHRcclxuICB2YXIgbWVyY1B0ID0gTC5wb2ludChwLngsIHAueSk7IC8vIG1ha2UgaW50byBsZWFmbGV0IG9ialxyXG4gIHZhciBsYXRMbmcgPSB0aGlzLm1hcC51bnByb2plY3QobWVyY1B0KTsgLy8gbWVyYyBwdCB0byBsYXRsbmdcclxuXHJcbiAgdGhpcy5zdGF0aWNMYWJlbCA9IG5ldyBTdGF0aWNMYWJlbCh0aGlzLCBjdHgsIGxhdExuZywgc3R5bGUpO1xyXG4gIHRoaXMubXZ0TGF5ZXIuZmVhdHVyZVdpdGhMYWJlbEFkZGVkKHRoaXMpO1xyXG59O1xyXG5cclxuTVZURmVhdHVyZS5wcm90b3R5cGUucmVtb3ZlTGFiZWwgPSBmdW5jdGlvbigpIHtcclxuICBpZiAoIXRoaXMuc3RhdGljTGFiZWwpIHJldHVybjtcclxuICB0aGlzLnN0YXRpY0xhYmVsLnJlbW92ZSgpO1xyXG4gIHRoaXMuc3RhdGljTGFiZWwgPSBudWxsO1xyXG59O1xyXG5cclxuLyoqXHJcbiAqIFByb2plY3RzIGEgdmVjdG9yIHRpbGUgcG9pbnQgdG8gdGhlIFNwaGVyaWNhbCBNZXJjYXRvciBwaXhlbCBzcGFjZSBmb3IgYSBnaXZlbiB6b29tIGxldmVsLlxyXG4gKlxyXG4gKiBAcGFyYW0gdmVjUHRcclxuICogQHBhcmFtIHRpbGVYXHJcbiAqIEBwYXJhbSB0aWxlWVxyXG4gKiBAcGFyYW0gZXh0ZW50XHJcbiAqIEBwYXJhbSB0aWxlU2l6ZVxyXG4gKi9cclxuTVZURmVhdHVyZS5wcm90b3R5cGUuX3Byb2plY3QgPSBmdW5jdGlvbih2ZWNQdCwgdGlsZVgsIHRpbGVZLCBleHRlbnQsIHRpbGVTaXplKSB7XHJcbiAgdmFyIHhPZmZzZXQgPSB0aWxlWCAqIHRpbGVTaXplO1xyXG4gIHZhciB5T2Zmc2V0ID0gdGlsZVkgKiB0aWxlU2l6ZTtcclxuICByZXR1cm4ge1xyXG4gICAgeDogTWF0aC5mbG9vcih2ZWNQdC54ICsgeE9mZnNldCksXHJcbiAgICB5OiBNYXRoLmZsb29yKHZlY1B0LnkgKyB5T2Zmc2V0KVxyXG4gIH07XHJcbn07XHJcblxyXG4vKipcclxuICogVGFrZXMgYSBjb29yZGluYXRlIGZyb20gYSB2ZWN0b3IgdGlsZSBhbmQgdHVybnMgaXQgaW50byBhIExlYWZsZXQgUG9pbnQuXHJcbiAqXHJcbiAqIEBwYXJhbSBjdHhcclxuICogQHBhcmFtIGNvb3Jkc1xyXG4gKiBAcmV0dXJucyB7ZUdlb21UeXBlLlBvaW50fVxyXG4gKiBAcHJpdmF0ZVxyXG4gKi9cclxuTVZURmVhdHVyZS5wcm90b3R5cGUuX3RpbGVQb2ludCA9IGZ1bmN0aW9uKGNvb3Jkcykge1xyXG4gIHJldHVybiBuZXcgTC5Qb2ludChjb29yZHMueCAvIHRoaXMuZGl2aXNvciwgY29vcmRzLnkgLyB0aGlzLmRpdmlzb3IpO1xyXG59O1xyXG5cclxuTVZURmVhdHVyZS5wcm90b3R5cGUubGlua2VkRmVhdHVyZSA9IGZ1bmN0aW9uKCkge1xyXG4gIHZhciBsaW5rZWRMYXllciA9IHRoaXMubXZ0TGF5ZXIubGlua2VkTGF5ZXIoKTtcclxuICBpZihsaW5rZWRMYXllcil7XHJcbiAgICB2YXIgbGlua2VkRmVhdHVyZSA9IGxpbmtlZExheWVyLmZlYXR1cmVzW3RoaXMuaWRdO1xyXG4gICAgcmV0dXJuIGxpbmtlZEZlYXR1cmU7XHJcbiAgfWVsc2V7XHJcbiAgICByZXR1cm4gbnVsbDtcclxuICB9XHJcbn07XHJcblxyXG4iLCIvKipcclxuICogQ3JlYXRlZCBieSBSeWFuIFdoaXRsZXkgb24gNS8xNy8xNC5cclxuICovXHJcbi8qKiBGb3JrZWQgZnJvbSBodHRwczovL2dpc3QuZ2l0aHViLmNvbS9ER3VpZGkvMTcxNjAxMCAqKi9cclxudmFyIE1WVEZlYXR1cmUgPSByZXF1aXJlKCcuL01WVEZlYXR1cmUnKTtcclxudmFyIFV0aWwgPSByZXF1aXJlKCcuL01WVFV0aWwnKTtcclxuXHJcbm1vZHVsZS5leHBvcnRzID0gTC5UaWxlTGF5ZXIuQ2FudmFzLmV4dGVuZCh7XHJcblxyXG4gICAgb3B0aW9uczoge1xyXG4gICAgICAgIGRlYnVnOiBmYWxzZSxcclxuICAgICAgICBpc0hpZGRlbkxheWVyOiBmYWxzZSxcclxuICAgICAgICBnZXRJREZvckxheWVyRmVhdHVyZTogZnVuY3Rpb24gKCkgeyB9LFxyXG4gICAgICAgIHRpbGVTaXplOiAyNTYsXHJcbiAgICAgICAgbGluZUNsaWNrVG9sZXJhbmNlOiAyXHJcbiAgICB9LFxyXG5cclxuICAgIF9mZWF0dXJlSXNDbGlja2VkOiB7fSxcclxuXHJcbiAgICBfaXNQb2ludEluUG9seTogZnVuY3Rpb24gKHB0LCBwb2x5KSB7XHJcbiAgICAgICAgaWYgKHBvbHkgJiYgcG9seS5sZW5ndGgpIHtcclxuICAgICAgICAgICAgZm9yICh2YXIgYyA9IGZhbHNlLCBpID0gLTEsIGwgPSBwb2x5Lmxlbmd0aCwgaiA9IGwgLSAxOyArK2kgPCBsOyBqID0gaSlcclxuICAgICAgICAgICAgICAgICgocG9seVtpXS55IDw9IHB0LnkgJiYgcHQueSA8IHBvbHlbal0ueSkgfHwgKHBvbHlbal0ueSA8PSBwdC55ICYmIHB0LnkgPCBwb2x5W2ldLnkpKVxyXG4gICAgICAgICAgICAgICAgJiYgKHB0LnggPCAocG9seVtqXS54IC0gcG9seVtpXS54KSAqIChwdC55IC0gcG9seVtpXS55KSAvIChwb2x5W2pdLnkgLSBwb2x5W2ldLnkpICsgcG9seVtpXS54KVxyXG4gICAgICAgICAgICAgICAgJiYgKGMgPSAhYyk7XHJcbiAgICAgICAgICAgIHJldHVybiBjO1xyXG4gICAgICAgIH1cclxuICAgIH0sXHJcblxyXG4gICAgX2dldERpc3RhbmNlRnJvbUxpbmU6IGZ1bmN0aW9uIChwdCwgcHRzKSB7XHJcbiAgICAgICAgdmFyIG1pbiA9IE51bWJlci5QT1NJVElWRV9JTkZJTklUWTtcclxuICAgICAgICBpZiAocHRzICYmIHB0cy5sZW5ndGggPiAxKSB7XHJcbiAgICAgICAgICAgIHB0ID0gTC5wb2ludChwdC54LCBwdC55KTtcclxuICAgICAgICAgICAgZm9yICh2YXIgaSA9IDAsIGwgPSBwdHMubGVuZ3RoIC0gMTsgaSA8IGw7IGkrKykge1xyXG4gICAgICAgICAgICAgICAgdmFyIHRlc3QgPSB0aGlzLl9wcm9qZWN0UG9pbnRPbkxpbmVTZWdtZW50KHB0LCBwdHNbaV0sIHB0c1tpICsgMV0pO1xyXG4gICAgICAgICAgICAgICAgaWYgKHRlc3QuZGlzdGFuY2UgPD0gbWluKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgbWluID0gdGVzdC5kaXN0YW5jZTtcclxuICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuICAgICAgICByZXR1cm4gbWluO1xyXG4gICAgfSxcclxuXHJcbiAgICBfcHJvamVjdFBvaW50T25MaW5lU2VnbWVudDogZnVuY3Rpb24gKHAsIHIwLCByMSkge1xyXG4gICAgICAgIHZhciBsaW5lTGVuZ3RoID0gcjAuZGlzdGFuY2VUbyhyMSk7XHJcbiAgICAgICAgaWYgKGxpbmVMZW5ndGggPCAxKSB7XHJcbiAgICAgICAgICAgIHJldHVybiB7IGRpc3RhbmNlOiBwLmRpc3RhbmNlVG8ocjApLCBjb29yZGluYXRlOiByMCB9O1xyXG4gICAgICAgIH1cclxuICAgICAgICB2YXIgdSA9ICgocC54IC0gcjAueCkgKiAocjEueCAtIHIwLngpICsgKHAueSAtIHIwLnkpICogKHIxLnkgLSByMC55KSkgLyBNYXRoLnBvdyhsaW5lTGVuZ3RoLCAyKTtcclxuICAgICAgICBpZiAodSA8IDAuMDAwMDAwMSkge1xyXG4gICAgICAgICAgICByZXR1cm4geyBkaXN0YW5jZTogcC5kaXN0YW5jZVRvKHIwKSwgY29vcmRpbmF0ZTogcjAgfTtcclxuICAgICAgICB9XHJcbiAgICAgICAgaWYgKHUgPiAwLjk5OTk5OTkpIHtcclxuICAgICAgICAgICAgcmV0dXJuIHsgZGlzdGFuY2U6IHAuZGlzdGFuY2VUbyhyMSksIGNvb3JkaW5hdGU6IHIxIH07XHJcbiAgICAgICAgfVxyXG4gICAgICAgIHZhciBhID0gTC5wb2ludChyMC54ICsgdSAqIChyMS54IC0gcjAueCksIHIwLnkgKyB1ICogKHIxLnkgLSByMC55KSk7XHJcbiAgICAgICAgcmV0dXJuIHsgZGlzdGFuY2U6IHAuZGlzdGFuY2VUbyhhKSwgcG9pbnQ6IGEgfTtcclxuICAgIH0sXHJcblxyXG4gICAgaW5pdGlhbGl6ZTogZnVuY3Rpb24gKG12dFNvdXJjZSwgb3B0aW9ucykge1xyXG4gICAgICAgIHZhciBzZWxmID0gdGhpcztcclxuICAgICAgICBzZWxmLm12dFNvdXJjZSA9IG12dFNvdXJjZTtcclxuICAgICAgICBMLlV0aWwuc2V0T3B0aW9ucyh0aGlzLCBvcHRpb25zKTtcclxuXHJcbiAgICAgICAgdGhpcy5zdHlsZSA9IG9wdGlvbnMuc3R5bGU7XHJcbiAgICAgICAgdGhpcy5uYW1lID0gb3B0aW9ucy5uYW1lO1xyXG4gICAgICAgIHRoaXMuX2NhbnZhc0lEVG9GZWF0dXJlcyA9IHt9O1xyXG4gICAgICAgIHRoaXMuZmVhdHVyZXMgPSB7fTtcclxuICAgICAgICB0aGlzLmZlYXR1cmVzV2l0aExhYmVscyA9IFtdO1xyXG4gICAgICAgIHRoaXMuX2hpZ2hlc3RDb3VudCA9IDA7XHJcbiAgICB9LFxyXG5cclxuICAgIG9uQWRkOiBmdW5jdGlvbiAobWFwKSB7XHJcbiAgICAgICAgdmFyIHNlbGYgPSB0aGlzO1xyXG4gICAgICAgIHNlbGYubWFwID0gbWFwO1xyXG4gICAgICAgIEwuVGlsZUxheWVyLkNhbnZhcy5wcm90b3R5cGUub25BZGQuY2FsbCh0aGlzLCBtYXApO1xyXG4gICAgICAgIG1hcC5vbignbGF5ZXJyZW1vdmUnLCBmdW5jdGlvbiAoZSkge1xyXG4gICAgICAgICAgICAvLyB3ZSBvbmx5IHdhbnQgdG8gZG8gc3R1ZmYgd2hlbiB0aGUgbGF5ZXJyZW1vdmUgZXZlbnQgaXMgb24gdGhpcyBsYXllclxyXG4gICAgICAgICAgICBpZiAoZS5sYXllci5fbGVhZmxldF9pZCA9PT0gc2VsZi5fbGVhZmxldF9pZCkge1xyXG4gICAgICAgICAgICAgICAgcmVtb3ZlTGFiZWxzKHNlbGYpO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfSk7XHJcbiAgICB9LFxyXG5cclxuICAgIGRyYXdUaWxlOiBmdW5jdGlvbiAoY2FudmFzLCB0aWxlUG9pbnQsIHpvb20pIHtcclxuXHJcbiAgICAgICAgdmFyIGN0eCA9IHtcclxuICAgICAgICAgICAgY2FudmFzOiBjYW52YXMsXHJcbiAgICAgICAgICAgIHRpbGU6IHRpbGVQb2ludCxcclxuICAgICAgICAgICAgem9vbTogem9vbSxcclxuICAgICAgICAgICAgdGlsZVNpemU6IHRoaXMub3B0aW9ucy50aWxlU2l6ZVxyXG4gICAgICAgIH07XHJcblxyXG4gICAgICAgIGN0eC5pZCA9IFV0aWwuZ2V0Q29udGV4dElEKGN0eCk7XHJcblxyXG4gICAgICAgIGlmICghdGhpcy5fY2FudmFzSURUb0ZlYXR1cmVzW2N0eC5pZF0pIHtcclxuICAgICAgICAgICAgdGhpcy5faW5pdGlhbGl6ZUZlYXR1cmVzSGFzaChjdHgpO1xyXG4gICAgICAgIH1cclxuICAgICAgICBpZiAoIXRoaXMuZmVhdHVyZXMpIHtcclxuICAgICAgICAgICAgdGhpcy5mZWF0dXJlcyA9IHt9O1xyXG4gICAgICAgIH1cclxuXHJcbiAgICB9LFxyXG5cclxuICAgIF9pbml0aWFsaXplRmVhdHVyZXNIYXNoOiBmdW5jdGlvbiAoY3R4KSB7XHJcbiAgICAgICAgdGhpcy5fY2FudmFzSURUb0ZlYXR1cmVzW2N0eC5pZF0gPSB7fTtcclxuICAgICAgICB0aGlzLl9jYW52YXNJRFRvRmVhdHVyZXNbY3R4LmlkXS5mZWF0dXJlcyA9IFtdO1xyXG4gICAgICAgIHRoaXMuX2NhbnZhc0lEVG9GZWF0dXJlc1tjdHguaWRdLmNhbnZhcyA9IGN0eC5jYW52YXM7XHJcbiAgICB9LFxyXG5cclxuICAgIF9kcmF3OiBmdW5jdGlvbiAoY3R4KSB7XHJcbiAgICAgICAgLy9EcmF3IGlzIGhhbmRsZWQgYnkgdGhlIHBhcmVudCBNVlRTb3VyY2Ugb2JqZWN0XHJcbiAgICB9LFxyXG4gICAgZ2V0Q2FudmFzOiBmdW5jdGlvbiAocGFyZW50Q3R4KSB7XHJcbiAgICAgICAgLy9UaGlzIGdldHMgY2FsbGVkIGlmIGEgdmVjdG9yIHRpbGUgZmVhdHVyZSBoYXMgYWxyZWFkeSBiZWVuIHBhcnNlZC5cclxuICAgICAgICAvL1dlJ3ZlIGFscmVhZHkgZ290IHRoZSBnZW9tLCBqdXN0IGdldCBvbiB3aXRoIHRoZSBkcmF3aW5nLlxyXG4gICAgICAgIC8vTmVlZCBhIHdheSB0byBwbHVjayBhIGNhbnZhcyBlbGVtZW50IGZyb20gdGhpcyBsYXllciBnaXZlbiB0aGUgcGFyZW50IGxheWVyJ3MgaWQuXHJcbiAgICAgICAgLy9XYWl0IGZvciBpdCB0byBnZXQgbG9hZGVkIGJlZm9yZSBwcm9jZWVkaW5nLlxyXG4gICAgICAgIHZhciB0aWxlUG9pbnQgPSBwYXJlbnRDdHgudGlsZTtcclxuICAgICAgICB2YXIgY3R4ID0gdGhpcy5fdGlsZXNbdGlsZVBvaW50LnggKyBcIjpcIiArIHRpbGVQb2ludC55XTtcclxuXHJcbiAgICAgICAgaWYgKGN0eCkge1xyXG4gICAgICAgICAgICBwYXJlbnRDdHguY2FudmFzID0gY3R4O1xyXG4gICAgICAgICAgICB0aGlzLnJlZHJhd1RpbGUocGFyZW50Q3R4LmlkKTtcclxuICAgICAgICAgICAgcmV0dXJuO1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgdmFyIHNlbGYgPSB0aGlzO1xyXG5cclxuICAgICAgICAvL1RoaXMgaXMgYSB0aW1lciB0aGF0IHdpbGwgd2FpdCBmb3IgYSBjcml0ZXJpb24gdG8gcmV0dXJuIHRydWUuXHJcbiAgICAgICAgLy9JZiBub3QgdHJ1ZSB3aXRoaW4gdGhlIHRpbWVvdXQgZHVyYXRpb24sIGl0IHdpbGwgbW92ZSBvbi5cclxuICAgICAgICB3YWl0Rm9yKGZ1bmN0aW9uICgpIHtcclxuICAgICAgICAgICAgY3R4ID0gc2VsZi5fdGlsZXNbdGlsZVBvaW50LnggKyBcIjpcIiArIHRpbGVQb2ludC55XTtcclxuICAgICAgICAgICAgaWYgKGN0eCkge1xyXG4gICAgICAgICAgICAgICAgcmV0dXJuIHRydWU7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9LFxyXG4gICAgICAgICAgZnVuY3Rpb24gKCkge1xyXG4gICAgICAgICAgICAgIC8vV2hlbiBpdCBmaW5pc2hlcywgZG8gdGhpcy5cclxuICAgICAgICAgICAgICBjdHggPSBzZWxmLl90aWxlc1t0aWxlUG9pbnQueCArIFwiOlwiICsgdGlsZVBvaW50LnldO1xyXG4gICAgICAgICAgICAgIHBhcmVudEN0eC5jYW52YXMgPSBjdHg7XHJcbiAgICAgICAgICAgICAgc2VsZi5yZWRyYXdUaWxlKHBhcmVudEN0eC5pZCk7XHJcblxyXG4gICAgICAgICAgfSwgLy93aGVuIGRvbmUsIGdvIHRvIG5leHQgZmxvd1xyXG4gICAgICAgICAgMjAwMCk7IC8vVGhlIFRpbWVvdXQgbWlsbGlzZWNvbmRzLiAgQWZ0ZXIgdGhpcywgZ2l2ZSB1cCBhbmQgbW92ZSBvblxyXG5cclxuICAgIH0sXHJcblxyXG4gICAgcGFyc2VWZWN0b3JUaWxlTGF5ZXI6IGZ1bmN0aW9uICh2dGwsIGN0eCkge1xyXG4gICAgICAgIHZhciBzZWxmID0gdGhpcztcclxuICAgICAgICB2YXIgdGlsZVBvaW50ID0gY3R4LnRpbGU7XHJcbiAgICAgICAgdmFyIGxheWVyQ3R4ID0geyBjYW52YXM6IG51bGwsIGlkOiBjdHguaWQsIHRpbGU6IGN0eC50aWxlLCB6b29tOiBjdHguem9vbSwgdGlsZVNpemU6IGN0eC50aWxlU2l6ZSB9O1xyXG5cclxuICAgICAgICAvL1NlZSBpZiB3ZSBjYW4gcGx1Y2sgdGhlIGNoaWxkIHRpbGUgZnJvbSB0aGlzIFBCRiB0aWxlIGxheWVyIGJhc2VkIG9uIHRoZSBtYXN0ZXIgbGF5ZXIncyB0aWxlIGlkLlxyXG4gICAgICAgIGxheWVyQ3R4LmNhbnZhcyA9IHNlbGYuX3RpbGVzW3RpbGVQb2ludC54ICsgXCI6XCIgKyB0aWxlUG9pbnQueV07XHJcblxyXG5cclxuXHJcbiAgICAgICAgLy9Jbml0aWFsaXplIHRoaXMgdGlsZSdzIGZlYXR1cmUgc3RvcmFnZSBoYXNoLCBpZiBpdCBoYXNuJ3QgYWxyZWFkeSBiZWVuIGNyZWF0ZWQuICBVc2VkIGZvciB3aGVuIGZpbHRlcnMgYXJlIHVwZGF0ZWQsIGFuZCBmZWF0dXJlcyBhcmUgY2xlYXJlZCB0byBwcmVwYXJlIGZvciBhIGZyZXNoIHJlZHJhdy5cclxuICAgICAgICBpZiAoIXRoaXMuX2NhbnZhc0lEVG9GZWF0dXJlc1tsYXllckN0eC5pZF0pIHtcclxuICAgICAgICAgICAgdGhpcy5faW5pdGlhbGl6ZUZlYXR1cmVzSGFzaChsYXllckN0eCk7XHJcbiAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgLy9DbGVhciB0aGlzIHRpbGUncyBwcmV2aW91c2x5IHNhdmVkIGZlYXR1cmVzLlxyXG4gICAgICAgICAgICB0aGlzLmNsZWFyVGlsZUZlYXR1cmVIYXNoKGxheWVyQ3R4LmlkKTtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIHZhciBmZWF0dXJlcyA9IHZ0bC5wYXJzZWRGZWF0dXJlcztcclxuICAgICAgICBmb3IgKHZhciBpID0gMCwgbGVuID0gZmVhdHVyZXMubGVuZ3RoOyBpIDwgbGVuOyBpKyspIHtcclxuICAgICAgICAgICAgdmFyIHZ0ZiA9IGZlYXR1cmVzW2ldOyAvL3ZlY3RvciB0aWxlIGZlYXR1cmVcclxuICAgICAgICAgICAgdnRmLmxheWVyID0gdnRsO1xyXG5cclxuICAgICAgICAgICAgLyoqXHJcbiAgICAgICAgICAgICAqIEFwcGx5IGZpbHRlciBvbiBmZWF0dXJlIGlmIHRoZXJlIGlzIG9uZS4gRGVmaW5lZCBpbiB0aGUgb3B0aW9ucyBvYmplY3RcclxuICAgICAgICAgICAgICogb2YgVGlsZUxheWVyLk1WVFNvdXJjZS5qc1xyXG4gICAgICAgICAgICAgKi9cclxuICAgICAgICAgICAgdmFyIGZpbHRlciA9IHNlbGYub3B0aW9ucy5maWx0ZXI7XHJcbiAgICAgICAgICAgIGlmICh0eXBlb2YgZmlsdGVyID09PSAnZnVuY3Rpb24nKSB7XHJcbiAgICAgICAgICAgICAgICBpZiAoZmlsdGVyKHZ0ZiwgbGF5ZXJDdHgpID09PSBmYWxzZSkgY29udGludWU7XHJcbiAgICAgICAgICAgIH1cclxuXHJcbiAgICAgICAgICAgIHZhciBnZXRJREZvckxheWVyRmVhdHVyZSA9IFV0aWwuZ2V0SURGb3JMYXllckZlYXR1cmU7XHJcbiAgICAgICAgICAgIHZhciB1bmlxdWVJRCA9IGdldElERm9yTGF5ZXJGZWF0dXJlKHZ0ZikgfHwgaTtcclxuICAgICAgICAgICAgdmFyIG12dEZlYXR1cmUgPSBzZWxmLmZlYXR1cmVzW3VuaXF1ZUlEXTtcclxuXHJcbiAgICAgICAgICAgIC8qKlxyXG4gICAgICAgICAgICAgKiBVc2UgbGF5ZXJPcmRlcmluZyBmdW5jdGlvbiB0byBhcHBseSBhIHpJbmRleCBwcm9wZXJ0eSB0byBlYWNoIHZ0Zi4gIFRoaXMgaXMgZGVmaW5lZCBpblxyXG4gICAgICAgICAgICAgKiBUaWxlTGF5ZXIuTVZUU291cmNlLmpzLiAgVXNlZCBiZWxvdyB0byBzb3J0IGZlYXR1cmVzLm5wbVxyXG4gICAgICAgICAgICAgKi9cclxuICAgICAgICAgICAgdmFyIGxheWVyT3JkZXJpbmcgPSBzZWxmLm9wdGlvbnMubGF5ZXJPcmRlcmluZztcclxuICAgICAgICAgICAgaWYgKHR5cGVvZiBsYXllck9yZGVyaW5nID09PSAnZnVuY3Rpb24nKSB7XHJcbiAgICAgICAgICAgICAgICBsYXllck9yZGVyaW5nKHZ0ZiwgbGF5ZXJDdHgpOyAvL0FwcGxpZXMgYSBjdXN0b20gcHJvcGVydHkgdG8gdGhlIGZlYXR1cmUsIHdoaWNoIGlzIHVzZWQgYWZ0ZXIgd2UncmUgdGhydSBpdGVyYXRpbmcgdG8gc29ydFxyXG4gICAgICAgICAgICB9XHJcblxyXG4gICAgICAgICAgICAvL0NyZWF0ZSBhIG5ldyBNVlRGZWF0dXJlIGlmIG9uZSBkb2Vzbid0IGFscmVhZHkgZXhpc3QgZm9yIHRoaXMgZmVhdHVyZS5cclxuICAgICAgICAgICAgaWYgKCFtdnRGZWF0dXJlKSB7XHJcbiAgICAgICAgICAgICAgICAvL0dldCBhIHN0eWxlIGZvciB0aGUgZmVhdHVyZSAtIHNldCBpdCBqdXN0IG9uY2UgZm9yIGVhY2ggbmV3IE1WVEZlYXR1cmVcclxuICAgICAgICAgICAgICAgIHZhciBzdHlsZSA9IHNlbGYuc3R5bGUodnRmKTtcclxuXHJcbiAgICAgICAgICAgICAgICAvL2NyZWF0ZSBhIG5ldyBmZWF0dXJlXHJcbiAgICAgICAgICAgICAgICBzZWxmLmZlYXR1cmVzW3VuaXF1ZUlEXSA9IG12dEZlYXR1cmUgPSBuZXcgTVZURmVhdHVyZShzZWxmLCB2dGYsIGxheWVyQ3R4LCB1bmlxdWVJRCwgc3R5bGUpO1xyXG4gICAgICAgICAgICAgICAgaWYgKHN0eWxlICYmIHN0eWxlLmR5bmFtaWNMYWJlbCAmJiB0eXBlb2Ygc3R5bGUuZHluYW1pY0xhYmVsID09PSAnZnVuY3Rpb24nKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgc2VsZi5mZWF0dXJlc1dpdGhMYWJlbHMucHVzaChtdnRGZWF0dXJlKTtcclxuICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgICAgIC8vQWRkIHRoZSBuZXcgcGFydCB0byB0aGUgZXhpc3RpbmcgZmVhdHVyZVxyXG4gICAgICAgICAgICAgICAgbXZ0RmVhdHVyZS5hZGRUaWxlRmVhdHVyZSh2dGYsIGxheWVyQ3R4KTtcclxuICAgICAgICAgICAgfVxyXG5cclxuICAgICAgICAgICAgLy9Bc3NvY2lhdGUgJiBTYXZlIHRoaXMgZmVhdHVyZSB3aXRoIHRoaXMgdGlsZSBmb3IgbGF0ZXJcclxuICAgICAgICAgICAgaWYgKGxheWVyQ3R4ICYmIGxheWVyQ3R4LmlkKSBzZWxmLl9jYW52YXNJRFRvRmVhdHVyZXNbbGF5ZXJDdHguaWRdWydmZWF0dXJlcyddLnB1c2gobXZ0RmVhdHVyZSk7XHJcblxyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgLyoqXHJcbiAgICAgICAgICogQXBwbHkgc29ydGluZyAoekluZGV4KSBvbiBmZWF0dXJlIGlmIHRoZXJlIGlzIGEgZnVuY3Rpb24gZGVmaW5lZCBpbiB0aGUgb3B0aW9ucyBvYmplY3RcclxuICAgICAgICAgKiBvZiBUaWxlTGF5ZXIuTVZUU291cmNlLmpzXHJcbiAgICAgICAgICovXHJcbiAgICAgICAgdmFyIGxheWVyT3JkZXJpbmcgPSBzZWxmLm9wdGlvbnMubGF5ZXJPcmRlcmluZztcclxuICAgICAgICBpZiAobGF5ZXJPcmRlcmluZykge1xyXG4gICAgICAgICAgICAvL1dlJ3ZlIGFzc2lnbmVkIHRoZSBjdXN0b20gekluZGV4IHByb3BlcnR5IHdoZW4gaXRlcmF0aW5nIGFib3ZlLiAgTm93IGp1c3Qgc29ydC5cclxuICAgICAgICAgICAgc2VsZi5fY2FudmFzSURUb0ZlYXR1cmVzW2xheWVyQ3R4LmlkXS5mZWF0dXJlcyA9IHNlbGYuX2NhbnZhc0lEVG9GZWF0dXJlc1tsYXllckN0eC5pZF0uZmVhdHVyZXMuc29ydChmdW5jdGlvbiAoYSwgYikge1xyXG4gICAgICAgICAgICAgICAgcmV0dXJuIC0oYi5wcm9wZXJ0aWVzLnpJbmRleCAtIGEucHJvcGVydGllcy56SW5kZXgpXHJcbiAgICAgICAgICAgIH0pO1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgc2VsZi5yZWRyYXdUaWxlKGxheWVyQ3R4LmlkKTtcclxuICAgIH0sXHJcblxyXG4gICAgc2V0U3R5bGU6IGZ1bmN0aW9uIChzdHlsZUZuKSB7XHJcbiAgICAgICAgLy8gcmVmcmVzaCB0aGUgbnVtYmVyIGZvciB0aGUgaGlnaGVzdCBjb3VudCB2YWx1ZVxyXG4gICAgICAgIC8vIHRoaXMgaXMgdXNlZCBvbmx5IGZvciBjaG9yb3BsZXRoXHJcbiAgICAgICAgdGhpcy5faGlnaGVzdENvdW50ID0gMDtcclxuXHJcbiAgICAgICAgLy8gbG93ZXN0IGNvdW50IHNob3VsZCBub3QgYmUgMCwgc2luY2Ugd2Ugd2FudCB0byBmaWd1cmUgb3V0IHRoZSBsb3dlc3RcclxuICAgICAgICB0aGlzLl9sb3dlc3RDb3VudCA9IG51bGw7XHJcblxyXG4gICAgICAgIHRoaXMuc3R5bGUgPSBzdHlsZUZuO1xyXG4gICAgICAgIGZvciAodmFyIGtleSBpbiB0aGlzLmZlYXR1cmVzKSB7XHJcbiAgICAgICAgICAgIHZhciBmZWF0ID0gdGhpcy5mZWF0dXJlc1trZXldO1xyXG4gICAgICAgICAgICBmZWF0LnNldFN0eWxlKHN0eWxlRm4pO1xyXG4gICAgICAgIH1cclxuICAgICAgICB2YXIgeiA9IHRoaXMubWFwLmdldFpvb20oKTtcclxuICAgICAgICBmb3IgKHZhciBrZXkgaW4gdGhpcy5fdGlsZXMpIHtcclxuICAgICAgICAgICAgdmFyIGlkID0geiArICc6JyArIGtleTtcclxuICAgICAgICAgICAgdGhpcy5yZWRyYXdUaWxlKGlkKTtcclxuICAgICAgICB9XHJcbiAgICB9LFxyXG5cclxuICAgIC8qKlxyXG4gICAgICogQXMgY291bnRzIGZvciBjaG9yb3BsZXRocyBjb21lIGluIHdpdGggdGhlIGFqYXggZGF0YSxcclxuICAgICAqIHdlIHdhbnQgdG8ga2VlcCB0cmFjayBvZiB3aGljaCB2YWx1ZSBpcyB0aGUgaGlnaGVzdFxyXG4gICAgICogdG8gY3JlYXRlIHRoZSBjb2xvciByYW1wIGZvciB0aGUgZmlsbHMgb2YgcG9seWdvbnMuXHJcbiAgICAgKiBAcGFyYW0gY291bnRcclxuICAgICAqL1xyXG4gICAgc2V0SGlnaGVzdENvdW50OiBmdW5jdGlvbiAoY291bnQpIHtcclxuICAgICAgICBpZiAoY291bnQgPiB0aGlzLl9oaWdoZXN0Q291bnQpIHtcclxuICAgICAgICAgICAgdGhpcy5faGlnaGVzdENvdW50ID0gY291bnQ7XHJcbiAgICAgICAgfVxyXG4gICAgfSxcclxuXHJcbiAgICAvKipcclxuICAgICAqIFJldHVybnMgdGhlIGhpZ2hlc3QgbnVtYmVyIG9mIGFsbCBvZiB0aGUgY291bnRzIHRoYXQgaGF2ZSBjb21lIGluXHJcbiAgICAgKiBmcm9tIHNldEhpZ2hlc3RDb3VudC4gVGhpcyBpcyBhc3N1bWVkIHRvIGJlIHNldCB2aWEgYWpheCBjYWxsYmFja3MuXHJcbiAgICAgKiBAcmV0dXJucyB7bnVtYmVyfVxyXG4gICAgICovXHJcbiAgICBnZXRIaWdoZXN0Q291bnQ6IGZ1bmN0aW9uICgpIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5faGlnaGVzdENvdW50O1xyXG4gICAgfSxcclxuXHJcbiAgICBzZXRMb3dlc3RDb3VudDogZnVuY3Rpb24gKGNvdW50KSB7XHJcbiAgICAgICAgaWYgKCF0aGlzLl9sb3dlc3RDb3VudCB8fCBjb3VudCA8IHRoaXMuX2xvd2VzdENvdW50KSB7XHJcbiAgICAgICAgICAgIHRoaXMuX2xvd2VzdENvdW50ID0gY291bnQ7XHJcbiAgICAgICAgfVxyXG4gICAgfSxcclxuXHJcbiAgICBnZXRMb3dlc3RDb3VudDogZnVuY3Rpb24gKCkge1xyXG4gICAgICAgIHJldHVybiB0aGlzLl9sb3dlc3RDb3VudDtcclxuICAgIH0sXHJcblxyXG4gICAgc2V0Q291bnRSYW5nZTogZnVuY3Rpb24gKGNvdW50KSB7XHJcbiAgICAgICAgdGhpcy5zZXRIaWdoZXN0Q291bnQoY291bnQpO1xyXG4gICAgICAgIHRoaXMuc2V0TG93ZXN0Q291bnQoY291bnQpO1xyXG4gICAgfSxcclxuXHJcbiAgICAvL1RoaXMgaXMgdGhlIG9sZCB3YXkuICBJdCB3b3JrcywgYnV0IGlzIHNsb3cgZm9yIG1vdXNlb3ZlciBldmVudHMuICBGaW5lIGZvciBjbGljayBldmVudHMuXHJcbiAgICBoYW5kbGVDbGlja0V2ZW50OiBmdW5jdGlvbiAoZXZ0LCBjYikge1xyXG4gICAgICAgIC8vQ2xpY2sgaGFwcGVuZWQgb24gdGhlIEdyb3VwTGF5ZXIgKE1hbmFnZXIpIGFuZCBwYXNzZWQgaXQgaGVyZVxyXG4gICAgICAgIHZhciB0aWxlSURzID0gZXZ0LnRpbGVJRC5zcGxpdChcIjpcIik7XHJcbiAgICAgICAgdmFyIHRpbGVJRCA9IGV2dC50aWxlSUQuc3BsaXQoXCI6XCIpLnNsaWNlKDEsIDMpLmpvaW4oXCI6XCIpO1xyXG4gICAgICAgIHZhciB6b29tID0gZXZ0LnRpbGVJRC5zcGxpdChcIjpcIilbMF07XHJcbiAgICAgICAgdmFyIGNhbnZhcyA9IHRoaXMuX3RpbGVzW3RpbGVJRF07XHJcbiAgICAgICAgaWYgKCFjYW52YXMpIChjYihldnQpKTsgLy9icmVhayBvdXRcclxuICAgICAgICB2YXIgeCA9IGV2dC5sYXllclBvaW50LnggLSBjYW52YXMuX2xlYWZsZXRfcG9zLng7XHJcbiAgICAgICAgdmFyIHkgPSBldnQubGF5ZXJQb2ludC55IC0gY2FudmFzLl9sZWFmbGV0X3Bvcy55O1xyXG5cclxuICAgICAgICB2YXIgdGlsZVBvaW50ID0geyB4OiB4LCB5OiB5IH07XHJcbiAgICAgICAgdmFyIGZlYXR1cmVzID0gdGhpcy5fY2FudmFzSURUb0ZlYXR1cmVzW2V2dC50aWxlSURdLmZlYXR1cmVzO1xyXG5cclxuICAgICAgICB2YXIgbWluRGlzdGFuY2UgPSBOdW1iZXIuUE9TSVRJVkVfSU5GSU5JVFk7XHJcbiAgICAgICAgdmFyIG5lYXJlc3QgPSBudWxsO1xyXG4gICAgICAgIHZhciBqLCBwYXRocywgZGlzdGFuY2U7XHJcblxyXG4gICAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgZmVhdHVyZXMubGVuZ3RoOyBpKyspIHtcclxuICAgICAgICAgICAgdmFyIGZlYXR1cmUgPSBmZWF0dXJlc1tpXTtcclxuICAgICAgICAgICAgc3dpdGNoIChmZWF0dXJlLnR5cGUpIHtcclxuXHJcbiAgICAgICAgICAgICAgICBjYXNlIDE6IC8vUG9pbnQgLSBjdXJyZW50bHkgcmVuZGVyZWQgYXMgY2lyY3VsYXIgcGF0aHMuICBJbnRlcnNlY3Qgd2l0aCB0aGF0LlxyXG5cclxuICAgICAgICAgICAgICAgICAgICAvL0ZpbmQgdGhlIHJhZGl1cyBvZiB0aGUgcG9pbnQuXHJcbiAgICAgICAgICAgICAgICAgICAgdmFyIHJhZGl1cyA9IDM7XHJcbiAgICAgICAgICAgICAgICAgICAgaWYgKHR5cGVvZiBmZWF0dXJlLnN0eWxlLnJhZGl1cyA9PT0gJ2Z1bmN0aW9uJykge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICByYWRpdXMgPSBmZWF0dXJlLnN0eWxlLnJhZGl1cyh6b29tKTsgLy9BbGxvd3MgZm9yIHNjYWxlIGRlcGVuZGVudCByZWRuZXJpbmdcclxuICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICAgICAgZWxzZSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIHJhZGl1cyA9IGZlYXR1cmUuc3R5bGUucmFkaXVzO1xyXG4gICAgICAgICAgICAgICAgICAgIH1cclxuXHJcbiAgICAgICAgICAgICAgICAgICAgcGF0aHMgPSBmZWF0dXJlLmdldFBhdGhzRm9yVGlsZShldnQudGlsZUlEKTtcclxuICAgICAgICAgICAgICAgICAgICBmb3IgKGogPSAwOyBqIDwgcGF0aHMubGVuZ3RoOyBqKyspIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgLy9CdWlsZHMgYSBjaXJjbGUgb2YgcmFkaXVzIGZlYXR1cmUuc3R5bGUucmFkaXVzIChhc3N1bWluZyBjaXJjdWxhciBwb2ludCBzeW1ib2xvZ3kpLlxyXG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoaW5fY2lyY2xlKHBhdGhzW2pdWzBdLngsIHBhdGhzW2pdWzBdLnksIHJhZGl1cywgeCwgeSkpIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5lYXJlc3QgPSBmZWF0dXJlO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbWluRGlzdGFuY2UgPSAwO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xyXG5cclxuICAgICAgICAgICAgICAgIGNhc2UgMjogLy9MaW5lU3RyaW5nXHJcbiAgICAgICAgICAgICAgICAgICAgcGF0aHMgPSBmZWF0dXJlLmdldFBhdGhzRm9yVGlsZShldnQudGlsZUlEKTtcclxuICAgICAgICAgICAgICAgICAgICBmb3IgKGogPSAwOyBqIDwgcGF0aHMubGVuZ3RoOyBqKyspIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGZlYXR1cmUuc3R5bGUpIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciBkaXN0YW5jZSA9IHRoaXMuX2dldERpc3RhbmNlRnJvbUxpbmUodGlsZVBvaW50LCBwYXRoc1tqXSk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YXIgdGhpY2tuZXNzID0gKGZlYXR1cmUuc2VsZWN0ZWQgJiYgZmVhdHVyZS5zdHlsZS5zZWxlY3RlZCA/IGZlYXR1cmUuc3R5bGUuc2VsZWN0ZWQuc2l6ZSA6IGZlYXR1cmUuc3R5bGUuc2l6ZSk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoZGlzdGFuY2UgPCB0aGlja25lc3MgLyAyICsgdGhpcy5vcHRpb25zLmxpbmVDbGlja1RvbGVyYW5jZSAmJiBkaXN0YW5jZSA8IG1pbkRpc3RhbmNlKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmVhcmVzdCA9IGZlYXR1cmU7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbWluRGlzdGFuY2UgPSBkaXN0YW5jZTtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgICAgICBicmVhaztcclxuXHJcbiAgICAgICAgICAgICAgICBjYXNlIDM6IC8vUG9seWdvblxyXG4gICAgICAgICAgICAgICAgICAgIHBhdGhzID0gZmVhdHVyZS5nZXRQYXRoc0ZvclRpbGUoZXZ0LnRpbGVJRCk7XHJcbiAgICAgICAgICAgICAgICAgICAgZm9yIChqID0gMDsgaiA8IHBhdGhzLmxlbmd0aDsgaisrKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICh0aGlzLl9pc1BvaW50SW5Qb2x5KHRpbGVQb2ludCwgcGF0aHNbal0pKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuZWFyZXN0ID0gZmVhdHVyZTtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1pbkRpc3RhbmNlID0gMDsgLy8gcG9pbnQgaXMgaW5zaWRlIHRoZSBwb2x5Z29uLCBzbyBkaXN0YW5jZSBpcyB6ZXJvXHJcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgaWYgKG1pbkRpc3RhbmNlID09IDApIGJyZWFrO1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgaWYgKG5lYXJlc3QgJiYgbmVhcmVzdC50b2dnbGVFbmFibGVkKSB7XHJcbiAgICAgICAgICAgIG5lYXJlc3QudG9nZ2xlKCk7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIGV2dC5mZWF0dXJlID0gbmVhcmVzdDtcclxuICAgICAgICBjYihldnQpO1xyXG4gICAgfSxcclxuXHJcbiAgICBjbGVhclRpbGU6IGZ1bmN0aW9uIChpZCkge1xyXG4gICAgICAgIC8vaWQgaXMgdGhlIGVudGlyZSB6b29tOng6eS4gIHdlIGp1c3Qgd2FudCB4OnkuXHJcbiAgICAgICAgdmFyIGNhID0gaWQuc3BsaXQoXCI6XCIpO1xyXG4gICAgICAgIHZhciBjYW52YXNJZCA9IGNhWzFdICsgXCI6XCIgKyBjYVsyXTtcclxuICAgICAgICBpZiAodHlwZW9mIHRoaXMuX3RpbGVzW2NhbnZhc0lkXSA9PT0gJ3VuZGVmaW5lZCcpIHtcclxuICAgICAgICAgICAgY29uc29sZS5lcnJvcihcInR5cGVvZiB0aGlzLl90aWxlc1tjYW52YXNJZF0gPT09ICd1bmRlZmluZWQnXCIpO1xyXG4gICAgICAgICAgICByZXR1cm47XHJcbiAgICAgICAgfVxyXG4gICAgICAgIHZhciBjYW52YXMgPSB0aGlzLl90aWxlc1tjYW52YXNJZF07XHJcblxyXG4gICAgICAgIHZhciBjb250ZXh0ID0gY2FudmFzLmdldENvbnRleHQoJzJkJyk7XHJcbiAgICAgICAgY29udGV4dC5jbGVhclJlY3QoMCwgMCwgY2FudmFzLndpZHRoLCBjYW52YXMuaGVpZ2h0KTtcclxuICAgIH0sXHJcblxyXG4gICAgY2xlYXJUaWxlRmVhdHVyZUhhc2g6IGZ1bmN0aW9uIChjYW52YXNJRCkge1xyXG4gICAgICAgIHRoaXMuX2NhbnZhc0lEVG9GZWF0dXJlc1tjYW52YXNJRF0gPSB7IGZlYXR1cmVzOiBbXSB9OyAvL0dldCByaWQgb2YgYWxsIHNhdmVkIGZlYXR1cmVzXHJcbiAgICB9LFxyXG5cclxuICAgIGNsZWFyTGF5ZXJGZWF0dXJlSGFzaDogZnVuY3Rpb24gKCkge1xyXG4gICAgICAgIHRoaXMuZmVhdHVyZXMgPSB7fTtcclxuICAgIH0sXHJcblxyXG4gICAgcmVkcmF3VGlsZTogZnVuY3Rpb24gKGNhbnZhc0lEKSB7XHJcbiAgICAgICAgLy9GaXJzdCwgY2xlYXIgdGhlIGNhbnZhc1xyXG4gICAgICAgIHRoaXMuY2xlYXJUaWxlKGNhbnZhc0lEKTtcclxuXHJcbiAgICAgICAgLy8gSWYgdGhlIGZlYXR1cmVzIGFyZSBub3QgaW4gdGhlIHRpbGUsIHRoZW4gdGhlcmUgaXMgbm90aGluZyB0byByZWRyYXcuXHJcbiAgICAgICAgLy8gVGhpcyBtYXkgaGFwcGVuIGlmIHlvdSBjYWxsIHJlZHJhdyBiZWZvcmUgZmVhdHVyZXMgaGF2ZSBsb2FkZWQgYW5kIGluaXRpYWxseVxyXG4gICAgICAgIC8vIGRyYXduIHRoZSB0aWxlLlxyXG4gICAgICAgIHZhciBmZWF0ZmVhdHMgPSB0aGlzLl9jYW52YXNJRFRvRmVhdHVyZXNbY2FudmFzSURdO1xyXG4gICAgICAgIGlmICghZmVhdGZlYXRzKSB7XHJcbiAgICAgICAgICAgIHJldHVybjtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIC8vR2V0IHRoZSBmZWF0dXJlcyBmb3IgdGhpcyB0aWxlLCBhbmQgcmVkcmF3IHRoZW0uXHJcbiAgICAgICAgdmFyIGZlYXR1cmVzID0gZmVhdGZlYXRzLmZlYXR1cmVzO1xyXG5cclxuICAgICAgICAvLyB3ZSB3YW50IHRvIHNraXAgZHJhd2luZyB0aGUgc2VsZWN0ZWQgZmVhdHVyZXMgYW5kIGRyYXcgdGhlbSBsYXN0XHJcbiAgICAgICAgdmFyIHNlbGVjdGVkRmVhdHVyZXMgPSBbXTtcclxuXHJcbiAgICAgICAgLy8gZHJhd2luZyBhbGwgb2YgdGhlIG5vbi1zZWxlY3RlZCBmZWF0dXJlc1xyXG4gICAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgZmVhdHVyZXMubGVuZ3RoOyBpKyspIHtcclxuICAgICAgICAgICAgdmFyIGZlYXR1cmUgPSBmZWF0dXJlc1tpXTtcclxuICAgICAgICAgICAgaWYgKGZlYXR1cmUuc2VsZWN0ZWQpIHtcclxuICAgICAgICAgICAgICAgIHNlbGVjdGVkRmVhdHVyZXMucHVzaChmZWF0dXJlKTtcclxuICAgICAgICAgICAgICAgIC8vIGNvbnNvbGUubG9nKFwic2VsZWN0ZWQgZmVhdHVyZSBvbiBkcmF3OlwiLCBmZWF0dXJlKTtcclxuICAgICAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgICAgIGZlYXR1cmUuZHJhdyhjYW52YXNJRCk7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIC8vIGRyYXdpbmcgdGhlIHNlbGVjdGVkIGZlYXR1cmVzIGxhc3RcclxuICAgICAgICBmb3IgKHZhciBqID0gMCwgbGVuMiA9IHNlbGVjdGVkRmVhdHVyZXMubGVuZ3RoOyBqIDwgbGVuMjsgaisrKSB7XHJcbiAgICAgICAgICAgIHZhciBzZWxGZWF0ID0gc2VsZWN0ZWRGZWF0dXJlc1tqXTtcclxuICAgICAgICAgICAgc2VsRmVhdC5kcmF3KGNhbnZhc0lEKTtcclxuICAgICAgICB9XHJcbiAgICB9LFxyXG5cclxuICAgIF9yZXNldENhbnZhc0lEVG9GZWF0dXJlczogZnVuY3Rpb24gKGNhbnZhc0lELCBjYW52YXMpIHtcclxuXHJcbiAgICAgICAgdGhpcy5fY2FudmFzSURUb0ZlYXR1cmVzW2NhbnZhc0lEXSA9IHt9O1xyXG4gICAgICAgIHRoaXMuX2NhbnZhc0lEVG9GZWF0dXJlc1tjYW52YXNJRF0uZmVhdHVyZXMgPSBbXTtcclxuICAgICAgICB0aGlzLl9jYW52YXNJRFRvRmVhdHVyZXNbY2FudmFzSURdLmNhbnZhcyA9IGNhbnZhcztcclxuXHJcbiAgICB9LFxyXG5cclxuICAgIGxpbmtlZExheWVyOiBmdW5jdGlvbiAoKSB7XHJcbiAgICAgICAgaWYgKHRoaXMubXZ0U291cmNlLmxheWVyTGluaykge1xyXG4gICAgICAgICAgICB2YXIgbGlua05hbWUgPSB0aGlzLm12dFNvdXJjZS5sYXllckxpbmsodGhpcy5uYW1lKTtcclxuICAgICAgICAgICAgcmV0dXJuIHRoaXMubXZ0U291cmNlLmxheWVyc1tsaW5rTmFtZV07XHJcbiAgICAgICAgfVxyXG4gICAgICAgIGVsc2Uge1xyXG4gICAgICAgICAgICByZXR1cm4gbnVsbDtcclxuICAgICAgICB9XHJcbiAgICB9LFxyXG5cclxuICAgIGZlYXR1cmVXaXRoTGFiZWxBZGRlZDogZnVuY3Rpb24gKGZlYXR1cmUpIHtcclxuICAgICAgICB0aGlzLmZlYXR1cmVzV2l0aExhYmVscy5wdXNoKGZlYXR1cmUpO1xyXG4gICAgfVxyXG5cclxufSk7XHJcblxyXG5cclxuZnVuY3Rpb24gcmVtb3ZlTGFiZWxzKHNlbGYpIHtcclxuICAgIHZhciBmZWF0dXJlcyA9IHNlbGYuZmVhdHVyZXNXaXRoTGFiZWxzO1xyXG4gICAgZm9yICh2YXIgaSA9IDAsIGxlbiA9IGZlYXR1cmVzLmxlbmd0aDsgaSA8IGxlbjsgaSsrKSB7XHJcbiAgICAgICAgdmFyIGZlYXQgPSBmZWF0dXJlc1tpXTtcclxuICAgICAgICBmZWF0LnJlbW92ZUxhYmVsKCk7XHJcbiAgICB9XHJcbiAgICBzZWxmLmZlYXR1cmVzV2l0aExhYmVscyA9IFtdO1xyXG59XHJcblxyXG5mdW5jdGlvbiBpbl9jaXJjbGUoY2VudGVyX3gsIGNlbnRlcl95LCByYWRpdXMsIHgsIHkpIHtcclxuICAgIHZhciBzcXVhcmVfZGlzdCA9IE1hdGgucG93KChjZW50ZXJfeCAtIHgpLCAyKSArIE1hdGgucG93KChjZW50ZXJfeSAtIHkpLCAyKTtcclxuICAgIHJldHVybiBzcXVhcmVfZGlzdCA8PSBNYXRoLnBvdyhyYWRpdXMsIDIpO1xyXG59XHJcbi8qKlxyXG4gKiBTZWUgaHR0cHM6Ly9naXRodWIuY29tL2FyaXlhL3BoYW50b21qcy9ibG9iL21hc3Rlci9leGFtcGxlcy93YWl0Zm9yLmpzXHJcbiAqXHJcbiAqIFdhaXQgdW50aWwgdGhlIHRlc3QgY29uZGl0aW9uIGlzIHRydWUgb3IgYSB0aW1lb3V0IG9jY3Vycy4gVXNlZnVsIGZvciB3YWl0aW5nXHJcbiAqIG9uIGEgc2VydmVyIHJlc3BvbnNlIG9yIGZvciBhIHVpIGNoYW5nZSAoZmFkZUluLCBldGMuKSB0byBvY2N1ci5cclxuICpcclxuICogQHBhcmFtIHRlc3RGeCBqYXZhc2NyaXB0IGNvbmRpdGlvbiB0aGF0IGV2YWx1YXRlcyB0byBhIGJvb2xlYW4sXHJcbiAqIGl0IGNhbiBiZSBwYXNzZWQgaW4gYXMgYSBzdHJpbmcgKGUuZy46IFwiMSA9PSAxXCIgb3IgXCIkKCcjYmFyJykuaXMoJzp2aXNpYmxlJylcIiBvclxyXG4gKiBhcyBhIGNhbGxiYWNrIGZ1bmN0aW9uLlxyXG4gKiBAcGFyYW0gb25SZWFkeSB3aGF0IHRvIGRvIHdoZW4gdGVzdEZ4IGNvbmRpdGlvbiBpcyBmdWxmaWxsZWQsXHJcbiAqIGl0IGNhbiBiZSBwYXNzZWQgaW4gYXMgYSBzdHJpbmcgKGUuZy46IFwiMSA9PSAxXCIgb3IgXCIkKCcjYmFyJykuaXMoJzp2aXNpYmxlJylcIiBvclxyXG4gKiBhcyBhIGNhbGxiYWNrIGZ1bmN0aW9uLlxyXG4gKiBAcGFyYW0gdGltZU91dE1pbGxpcyB0aGUgbWF4IGFtb3VudCBvZiB0aW1lIHRvIHdhaXQuIElmIG5vdCBzcGVjaWZpZWQsIDMgc2VjIGlzIHVzZWQuXHJcbiAqL1xyXG5mdW5jdGlvbiB3YWl0Rm9yKHRlc3RGeCwgb25SZWFkeSwgdGltZU91dE1pbGxpcykge1xyXG4gICAgdmFyIG1heHRpbWVPdXRNaWxsaXMgPSB0aW1lT3V0TWlsbGlzID8gdGltZU91dE1pbGxpcyA6IDMwMDAsIC8vPCBEZWZhdWx0IE1heCBUaW1vdXQgaXMgM3NcclxuICAgICAgc3RhcnQgPSBuZXcgRGF0ZSgpLmdldFRpbWUoKSxcclxuICAgICAgY29uZGl0aW9uID0gKHR5cGVvZiAodGVzdEZ4KSA9PT0gXCJzdHJpbmdcIiA/IGV2YWwodGVzdEZ4KSA6IHRlc3RGeCgpKSwgLy88IGRlZmVuc2l2ZSBjb2RlXHJcbiAgICAgIGludGVydmFsID0gc2V0SW50ZXJ2YWwoZnVuY3Rpb24gKCkge1xyXG4gICAgICAgICAgaWYgKChuZXcgRGF0ZSgpLmdldFRpbWUoKSAtIHN0YXJ0IDwgbWF4dGltZU91dE1pbGxpcykgJiYgIWNvbmRpdGlvbikge1xyXG4gICAgICAgICAgICAgIC8vIElmIG5vdCB0aW1lLW91dCB5ZXQgYW5kIGNvbmRpdGlvbiBub3QgeWV0IGZ1bGZpbGxlZFxyXG4gICAgICAgICAgICAgIGNvbmRpdGlvbiA9ICh0eXBlb2YgKHRlc3RGeCkgPT09IFwic3RyaW5nXCIgPyBldmFsKHRlc3RGeCkgOiB0ZXN0RngoKSk7IC8vPCBkZWZlbnNpdmUgY29kZVxyXG4gICAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgICBpZiAoIWNvbmRpdGlvbikge1xyXG4gICAgICAgICAgICAgICAgICAvLyBJZiBjb25kaXRpb24gc3RpbGwgbm90IGZ1bGZpbGxlZCAodGltZW91dCBidXQgY29uZGl0aW9uIGlzICdmYWxzZScpXHJcbiAgICAgICAgICAgICAgICAgIGNvbnNvbGUubG9nKFwiJ3dhaXRGb3IoKScgdGltZW91dFwiKTtcclxuICAgICAgICAgICAgICAgICAgY2xlYXJJbnRlcnZhbChpbnRlcnZhbCk7IC8vPCBTdG9wIHRoaXMgaW50ZXJ2YWxcclxuICAgICAgICAgICAgICAgICAgdHlwZW9mIChvblJlYWR5KSA9PT0gXCJzdHJpbmdcIiA/IGV2YWwob25SZWFkeSkgOiBvblJlYWR5KCd0aW1lb3V0Jyk7IC8vPCBEbyB3aGF0IGl0J3Mgc3VwcG9zZWQgdG8gZG8gb25jZSB0aGUgY29uZGl0aW9uIGlzIGZ1bGZpbGxlZFxyXG4gICAgICAgICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgICAgICAgIC8vIENvbmRpdGlvbiBmdWxmaWxsZWQgKHRpbWVvdXQgYW5kL29yIGNvbmRpdGlvbiBpcyAndHJ1ZScpXHJcbiAgICAgICAgICAgICAgICAgIGNvbnNvbGUubG9nKFwiJ3dhaXRGb3IoKScgZmluaXNoZWQgaW4gXCIgKyAobmV3IERhdGUoKS5nZXRUaW1lKCkgLSBzdGFydCkgKyBcIm1zLlwiKTtcclxuICAgICAgICAgICAgICAgICAgY2xlYXJJbnRlcnZhbChpbnRlcnZhbCk7IC8vPCBTdG9wIHRoaXMgaW50ZXJ2YWxcclxuICAgICAgICAgICAgICAgICAgdHlwZW9mIChvblJlYWR5KSA9PT0gXCJzdHJpbmdcIiA/IGV2YWwob25SZWFkeSkgOiBvblJlYWR5KCdzdWNjZXNzJyk7IC8vPCBEbyB3aGF0IGl0J3Mgc3VwcG9zZWQgdG8gZG8gb25jZSB0aGUgY29uZGl0aW9uIGlzIGZ1bGZpbGxlZFxyXG4gICAgICAgICAgICAgIH1cclxuICAgICAgICAgIH1cclxuICAgICAgfSwgNTApOyAvLzwgcmVwZWF0IGNoZWNrIGV2ZXJ5IDUwbXNcclxufTsiLCJ2YXIgVmVjdG9yVGlsZSA9IHJlcXVpcmUoJ3ZlY3Rvci10aWxlJykuVmVjdG9yVGlsZTtcclxudmFyIFByb3RvYnVmID0gcmVxdWlyZSgncGJmJyk7XHJcbnZhciBQb2ludCA9IHJlcXVpcmUoJ3BvaW50LWdlb21ldHJ5Jyk7XHJcbnZhciBVdGlsID0gcmVxdWlyZSgnLi9NVlRVdGlsJyk7XHJcbnZhciBNVlRMYXllciA9IHJlcXVpcmUoJy4vTVZUTGF5ZXInKTtcclxuXHJcblxyXG5tb2R1bGUuZXhwb3J0cyA9IEwuVGlsZUxheWVyLk1WVFNvdXJjZSA9IEwuVGlsZUxheWVyLkNhbnZhcy5leHRlbmQoe1xyXG5cclxuICBvcHRpb25zOiB7XHJcbiAgICBkZWJ1ZzogZmFsc2UsXHJcbiAgICB1cmw6IFwiXCIsIC8vVVJMIFRPIFZlY3RvciBUaWxlIFNvdXJjZSxcclxuICAgIGdldElERm9yTGF5ZXJGZWF0dXJlOiBmdW5jdGlvbiAoKSB7IH0sXHJcbiAgICB0aWxlU2l6ZTogMjU2LFxyXG4gICAgdmlzaWJsZUxheWVyczogW10sXHJcbiAgICB4aHJIZWFkZXJzOiB7fVxyXG4gIH0sXHJcbiAgbGF5ZXJzOiB7fSwgLy9LZWVwIGEgbGlzdCBvZiB0aGUgbGF5ZXJzIGNvbnRhaW5lZCBpbiB0aGUgUEJGc1xyXG4gIHByb2Nlc3NlZFRpbGVzOiB7fSwgLy9LZWVwIGEgbGlzdCBvZiB0aWxlcyB0aGF0IGhhdmUgYmVlbiBwcm9jZXNzZWQgYWxyZWFkeVxyXG4gIF9ldmVudEhhbmRsZXJzOiB7fSxcclxuICBfdHJpZ2dlck9uVGlsZXNMb2FkZWRFdmVudDogdHJ1ZSwgLy93aGV0aGVyIG9yIG5vdCB0byBmaXJlIHRoZSBvblRpbGVzTG9hZGVkIGV2ZW50IHdoZW4gYWxsIG9mIHRoZSB0aWxlcyBmaW5pc2ggbG9hZGluZy5cclxuICBfdXJsOiBcIlwiLCAvL2ludGVybmFsIFVSTCBwcm9wZXJ0eVxyXG5cclxuICBzdHlsZTogZnVuY3Rpb24gKGZlYXR1cmUpIHtcclxuICAgIHZhciBzdHlsZSA9IHt9O1xyXG5cclxuICAgIHZhciB0eXBlID0gZmVhdHVyZS50eXBlO1xyXG4gICAgc3dpdGNoICh0eXBlKSB7XHJcbiAgICAgIGNhc2UgMTogLy8nUG9pbnQnXHJcbiAgICAgICAgc3R5bGUuY29sb3IgPSAncmdiYSg0OSw3OSw3OSwxKSc7XHJcbiAgICAgICAgc3R5bGUucmFkaXVzID0gNTtcclxuICAgICAgICBzdHlsZS5zZWxlY3RlZCA9IHtcclxuICAgICAgICAgIGNvbG9yOiAncmdiYSgyNTUsMjU1LDAsMC41KScsXHJcbiAgICAgICAgICByYWRpdXM6IDZcclxuICAgICAgICB9O1xyXG4gICAgICAgIGJyZWFrO1xyXG4gICAgICBjYXNlIDI6IC8vJ0xpbmVTdHJpbmcnXHJcbiAgICAgICAgc3R5bGUuY29sb3IgPSAncmdiYSgxNjEsMjE3LDE1NSwwLjgpJztcclxuICAgICAgICBzdHlsZS5zaXplID0gMztcclxuICAgICAgICBzdHlsZS5zZWxlY3RlZCA9IHtcclxuICAgICAgICAgIGNvbG9yOiAncmdiYSgyNTUsMjUsMCwwLjUpJyxcclxuICAgICAgICAgIHNpemU6IDRcclxuICAgICAgICB9O1xyXG4gICAgICAgIGJyZWFrO1xyXG4gICAgICBjYXNlIDM6IC8vJ1BvbHlnb24nXHJcbiAgICAgICAgc3R5bGUuY29sb3IgPSAncmdiYSg0OSw3OSw3OSwxKSc7XHJcbiAgICAgICAgc3R5bGUub3V0bGluZSA9IHtcclxuICAgICAgICAgIGNvbG9yOiAncmdiYSgxNjEsMjE3LDE1NSwwLjgpJyxcclxuICAgICAgICAgIHNpemU6IDFcclxuICAgICAgICB9O1xyXG4gICAgICAgIHN0eWxlLnNlbGVjdGVkID0ge1xyXG4gICAgICAgICAgY29sb3I6ICdyZ2JhKDI1NSwxNDAsMCwwLjMpJyxcclxuICAgICAgICAgIG91dGxpbmU6IHtcclxuICAgICAgICAgICAgY29sb3I6ICdyZ2JhKDI1NSwxNDAsMCwxKScsXHJcbiAgICAgICAgICAgIHNpemU6IDJcclxuICAgICAgICAgIH1cclxuICAgICAgICB9O1xyXG4gICAgICAgIGJyZWFrO1xyXG4gICAgfVxyXG4gICAgcmV0dXJuIHN0eWxlO1xyXG4gIH0sXHJcblxyXG5cclxuICBpbml0aWFsaXplOiBmdW5jdGlvbiAob3B0aW9ucykge1xyXG4gICAgTC5VdGlsLnNldE9wdGlvbnModGhpcywgb3B0aW9ucyk7XHJcblxyXG4gICAgLy9hIGxpc3Qgb2YgdGhlIGxheWVycyBjb250YWluZWQgaW4gdGhlIFBCRnNcclxuICAgIHRoaXMubGF5ZXJzID0ge307XHJcblxyXG4gICAgLy8gdGlsZXMgY3VycmVudGx5IGluIHRoZSB2aWV3cG9ydFxyXG4gICAgdGhpcy5hY3RpdmVUaWxlcyA9IHt9O1xyXG5cclxuICAgIC8vIHRoYXRzIHRoYXQgaGF2ZSBiZWVuIGxvYWRlZCBhbmQgZHJhd25cclxuICAgIHRoaXMubG9hZGVkVGlsZXMgPSB7fTtcclxuXHJcbiAgICB0aGlzLl91cmwgPSB0aGlzLm9wdGlvbnMudXJsO1xyXG5cclxuICAgIC8qKlxyXG4gICAgICogRm9yIHNvbWUgcmVhc29uLCBMZWFmbGV0IGhhcyBzb21lIGNvZGUgdGhhdCByZXNldHMgdGhlXHJcbiAgICAgKiB6IGluZGV4IGluIHRoZSBvcHRpb25zIG9iamVjdC4gSSdtIGhhdmluZyB0cm91YmxlIHRyYWNraW5nXHJcbiAgICAgKiBkb3duIGV4YWN0bHkgd2hhdCBkb2VzIHRoaXMgYW5kIHdoeSwgc28gZm9yIG5vdywgd2Ugc2hvdWxkXHJcbiAgICAgKiBqdXN0IGNvcHkgdGhlIHZhbHVlIHRvIHRoaXMuekluZGV4IHNvIHdlIGNhbiBoYXZlIHRoZSByaWdodFxyXG4gICAgICogbnVtYmVyIHdoZW4gd2UgbWFrZSB0aGUgc3Vic2VxdWVudCBNVlRMYXllcnMuXHJcbiAgICAgKi9cclxuICAgIHRoaXMuekluZGV4ID0gb3B0aW9ucy56SW5kZXg7XHJcblxyXG4gICAgaWYgKHR5cGVvZiBvcHRpb25zLnN0eWxlID09PSAnZnVuY3Rpb24nKSB7XHJcbiAgICAgIHRoaXMuc3R5bGUgPSBvcHRpb25zLnN0eWxlO1xyXG4gICAgfVxyXG5cclxuICAgIGlmICh0eXBlb2Ygb3B0aW9ucy5hamF4U291cmNlID09PSAnZnVuY3Rpb24nKSB7XHJcbiAgICAgIHRoaXMuYWpheFNvdXJjZSA9IG9wdGlvbnMuYWpheFNvdXJjZTtcclxuICAgIH1cclxuXHJcbiAgICB0aGlzLmxheWVyTGluayA9IG9wdGlvbnMubGF5ZXJMaW5rO1xyXG5cclxuICAgIHRoaXMuX2V2ZW50SGFuZGxlcnMgPSB7fTtcclxuXHJcbiAgICB0aGlzLl90aWxlc1RvUHJvY2VzcyA9IDA7IC8vc3RvcmUgdGhlIG1heCBudW1iZXIgb2YgdGlsZXMgdG8gYmUgbG9hZGVkLiAgTGF0ZXIsIHdlIGNhbiB1c2UgdGhpcyBjb3VudCB0byBjb3VudCBkb3duIFBCRiBsb2FkaW5nLlxyXG4gIH0sXHJcblxyXG4gIHJlZHJhdzogZnVuY3Rpb24gKHRyaWdnZXJPblRpbGVzTG9hZGVkRXZlbnQpIHtcclxuICAgIC8vT25seSBzZXQgdG8gZmFsc2UgaWYgaXQgYWN0dWFsbHkgaXMgcGFzc2VkIGluIGFzICdmYWxzZSdcclxuICAgIGlmICh0cmlnZ2VyT25UaWxlc0xvYWRlZEV2ZW50ID09PSBmYWxzZSkge1xyXG4gICAgICB0aGlzLl90cmlnZ2VyT25UaWxlc0xvYWRlZEV2ZW50ID0gZmFsc2U7XHJcbiAgICB9XHJcblxyXG4gICAgTC5UaWxlTGF5ZXIuQ2FudmFzLnByb3RvdHlwZS5yZWRyYXcuY2FsbCh0aGlzKTtcclxuICB9LFxyXG5cclxuICBvbkFkZDogZnVuY3Rpb24gKG1hcCkge1xyXG4gICAgdmFyIHNlbGYgPSB0aGlzO1xyXG4gICAgc2VsZi5tYXAgPSBtYXA7XHJcbiAgICBMLlRpbGVMYXllci5DYW52YXMucHJvdG90eXBlLm9uQWRkLmNhbGwodGhpcywgbWFwKTtcclxuXHJcbiAgICB2YXIgbWFwT25DbGlja0NhbGxiYWNrID0gZnVuY3Rpb24gKGUpIHtcclxuICAgICAgc2VsZi5fb25DbGljayhlKTtcclxuICAgIH07XHJcblxyXG4gICAgbWFwLm9uKCdjbGljaycsIG1hcE9uQ2xpY2tDYWxsYmFjayk7XHJcblxyXG4gICAgbWFwLm9uKFwibGF5ZXJyZW1vdmVcIiwgZnVuY3Rpb24gKGUpIHtcclxuICAgICAgLy8gY2hlY2sgdG8gc2VlIGlmIHRoZSBsYXllciByZW1vdmVkIGlzIHRoaXMgb25lXHJcbiAgICAgIC8vIGNhbGwgYSBtZXRob2QgdG8gcmVtb3ZlIHRoZSBjaGlsZCBsYXllcnMgKHRoZSBvbmVzIHRoYXQgYWN0dWFsbHkgaGF2ZSBzb21ldGhpbmcgZHJhd24gb24gdGhlbSkuXHJcbiAgICAgIGlmIChlLmxheWVyLl9sZWFmbGV0X2lkID09PSBzZWxmLl9sZWFmbGV0X2lkICYmIGUubGF5ZXIucmVtb3ZlQ2hpbGRMYXllcnMpIHtcclxuICAgICAgICBlLmxheWVyLnJlbW92ZUNoaWxkTGF5ZXJzKG1hcCk7XHJcbiAgICAgICAgbWFwLm9mZignY2xpY2snLCBtYXBPbkNsaWNrQ2FsbGJhY2spO1xyXG4gICAgICB9XHJcbiAgICB9KTtcclxuXHJcbiAgICBzZWxmLmFkZENoaWxkTGF5ZXJzKG1hcCk7XHJcblxyXG4gICAgaWYgKHR5cGVvZiBEeW5hbWljTGFiZWwgPT09ICdmdW5jdGlvbicpIHtcclxuICAgICAgdGhpcy5keW5hbWljTGFiZWwgPSBuZXcgRHluYW1pY0xhYmVsKG1hcCwgdGhpcywge30pO1xyXG4gICAgfVxyXG5cclxuICB9LFxyXG5cclxuICBkcmF3VGlsZTogZnVuY3Rpb24gKGNhbnZhcywgdGlsZVBvaW50LCB6b29tKSB7XHJcbiAgICB2YXIgY3R4ID0ge1xyXG4gICAgICBpZDogW3pvb20sIHRpbGVQb2ludC54LCB0aWxlUG9pbnQueV0uam9pbihcIjpcIiksXHJcbiAgICAgIGNhbnZhczogY2FudmFzLFxyXG4gICAgICB0aWxlOiB0aWxlUG9pbnQsXHJcbiAgICAgIHpvb206IHpvb20sXHJcbiAgICAgIHRpbGVTaXplOiB0aGlzLm9wdGlvbnMudGlsZVNpemVcclxuICAgIH07XHJcblxyXG4gICAgLy9DYXB0dXJlIHRoZSBtYXggbnVtYmVyIG9mIHRoZSB0aWxlcyB0byBsb2FkIGhlcmUuIHRoaXMuX3RpbGVzVG9Qcm9jZXNzIGlzIGFuIGludGVybmFsIG51bWJlciB3ZSB1c2UgdG8ga25vdyB3aGVuIHdlJ3ZlIGZpbmlzaGVkIHJlcXVlc3RpbmcgUEJGcy5cclxuICAgIGlmICh0aGlzLl90aWxlc1RvUHJvY2VzcyA8IHRoaXMuX3RpbGVzVG9Mb2FkKSB0aGlzLl90aWxlc1RvUHJvY2VzcyA9IHRoaXMuX3RpbGVzVG9Mb2FkO1xyXG5cclxuICAgIHZhciBpZCA9IGN0eC5pZCA9IFV0aWwuZ2V0Q29udGV4dElEKGN0eCk7XHJcbiAgICB0aGlzLmFjdGl2ZVRpbGVzW2lkXSA9IGN0eDtcclxuXHJcbiAgICBpZiAoIXRoaXMucHJvY2Vzc2VkVGlsZXNbY3R4Lnpvb21dKSB0aGlzLnByb2Nlc3NlZFRpbGVzW2N0eC56b29tXSA9IHt9O1xyXG5cclxuICAgIGlmICh0aGlzLm9wdGlvbnMuZGVidWcpIHtcclxuICAgICAgdGhpcy5fZHJhd0RlYnVnSW5mbyhjdHgpO1xyXG4gICAgfVxyXG4gICAgdGhpcy5fZHJhdyhjdHgpO1xyXG4gIH0sXHJcblxyXG4gIHNldE9wYWNpdHk6IGZ1bmN0aW9uIChvcGFjaXR5KSB7XHJcbiAgICB0aGlzLl9zZXRWaXNpYmxlTGF5ZXJzU3R5bGUoJ29wYWNpdHknLCBvcGFjaXR5KTtcclxuICB9LFxyXG5cclxuICBzZXRaSW5kZXg6IGZ1bmN0aW9uICh6SW5kZXgpIHtcclxuICAgIHRoaXMuX3NldFZpc2libGVMYXllcnNTdHlsZSgnekluZGV4JywgekluZGV4KTtcclxuICB9LFxyXG5cclxuICBfc2V0VmlzaWJsZUxheWVyc1N0eWxlOiBmdW5jdGlvbiAoc3R5bGUsIHZhbHVlKSB7XHJcbiAgICBmb3IgKHZhciBrZXkgaW4gdGhpcy5sYXllcnMpIHtcclxuICAgICAgdGhpcy5sYXllcnNba2V5XS5fdGlsZUNvbnRhaW5lci5zdHlsZVtzdHlsZV0gPSB2YWx1ZTtcclxuICAgIH1cclxuICB9LFxyXG5cclxuICBfZHJhd0RlYnVnSW5mbzogZnVuY3Rpb24gKGN0eCkge1xyXG4gICAgdmFyIG1heCA9IHRoaXMub3B0aW9ucy50aWxlU2l6ZTtcclxuICAgIHZhciBnID0gY3R4LmNhbnZhcy5nZXRDb250ZXh0KCcyZCcpO1xyXG4gICAgZy5zdHJva2VTdHlsZSA9ICcjMDAwMDAwJztcclxuICAgIGcuZmlsbFN0eWxlID0gJyNGRkZGMDAnO1xyXG4gICAgZy5zdHJva2VSZWN0KDAsIDAsIG1heCwgbWF4KTtcclxuICAgIGcuZm9udCA9IFwiMTJweCBBcmlhbFwiO1xyXG4gICAgZy5maWxsUmVjdCgwLCAwLCA1LCA1KTtcclxuICAgIGcuZmlsbFJlY3QoMCwgbWF4IC0gNSwgNSwgNSk7XHJcbiAgICBnLmZpbGxSZWN0KG1heCAtIDUsIDAsIDUsIDUpO1xyXG4gICAgZy5maWxsUmVjdChtYXggLSA1LCBtYXggLSA1LCA1LCA1KTtcclxuICAgIGcuZmlsbFJlY3QobWF4IC8gMiAtIDUsIG1heCAvIDIgLSA1LCAxMCwgMTApO1xyXG4gICAgZy5zdHJva2VUZXh0KGN0eC56b29tICsgJyAnICsgY3R4LnRpbGUueCArICcgJyArIGN0eC50aWxlLnksIG1heCAvIDIgLSAzMCwgbWF4IC8gMiAtIDEwKTtcclxuICB9LFxyXG5cclxuICBfZHJhdzogZnVuY3Rpb24gKGN0eCkge1xyXG4gICAgdmFyIHNlbGYgPSB0aGlzO1xyXG5cclxuICAgIC8vICAgIC8vVGhpcyB3b3JrcyB0byBza2lwIGZldGNoaW5nIGFuZCBwcm9jZXNzaW5nIHRpbGVzIGlmIHRoZXkndmUgYWxyZWFkeSBiZWVuIHByb2Nlc3NlZC5cclxuICAgIC8vICAgIHZhciB2ZWN0b3JUaWxlID0gdGhpcy5wcm9jZXNzZWRUaWxlc1tjdHguem9vbV1bY3R4LmlkXTtcclxuICAgIC8vICAgIC8vaWYgd2UndmUgYWxyZWFkeSBwYXJzZWQgaXQsIGRvbid0IGdldCBpdCBhZ2Fpbi5cclxuICAgIC8vICAgIGlmKHZlY3RvclRpbGUpe1xyXG4gICAgLy8gICAgICBjb25zb2xlLmxvZyhcIlNraXBwaW5nIGZldGNoaW5nIFwiICsgY3R4LmlkKTtcclxuICAgIC8vICAgICAgc2VsZi5jaGVja1ZlY3RvclRpbGVMYXllcnMocGFyc2VWVCh2ZWN0b3JUaWxlKSwgY3R4LCB0cnVlKTtcclxuICAgIC8vICAgICAgc2VsZi5yZWR1Y2VUaWxlc1RvUHJvY2Vzc0NvdW50KCk7XHJcbiAgICAvLyAgICAgIHJldHVybjtcclxuICAgIC8vICAgIH1cclxuXHJcbiAgICBpZiAoIXRoaXMuX3VybCkgcmV0dXJuO1xyXG4gICAgdmFyIHNyYyA9IHRoaXMuZ2V0VGlsZVVybCh7IHg6IGN0eC50aWxlLngsIHk6IGN0eC50aWxlLnksIHo6IGN0eC56b29tIH0pO1xyXG5cclxuICAgIHZhciB4aHIgPSBuZXcgWE1MSHR0cFJlcXVlc3QoKTtcclxuICAgIHhoci5vbmxvYWQgPSBmdW5jdGlvbiAoKSB7XHJcbiAgICAgIGlmICh4aHIuc3RhdHVzID09IFwiMjAwXCIpIHtcclxuXHJcbiAgICAgICAgaWYgKCF4aHIucmVzcG9uc2UpIHJldHVybjtcclxuXHJcbiAgICAgICAgdmFyIGFycmF5QnVmZmVyID0gbmV3IFVpbnQ4QXJyYXkoeGhyLnJlc3BvbnNlKTtcclxuICAgICAgICB2YXIgYnVmID0gbmV3IFByb3RvYnVmKGFycmF5QnVmZmVyKTtcclxuICAgICAgICB2YXIgdnQgPSBuZXcgVmVjdG9yVGlsZShidWYpO1xyXG4gICAgICAgIC8vQ2hlY2sgdGhlIGN1cnJlbnQgbWFwIGxheWVyIHpvb20uICBJZiBmYXN0IHpvb21pbmcgaXMgb2NjdXJyaW5nLCB0aGVuIHNob3J0IGNpcmN1aXQgdGlsZXMgdGhhdCBhcmUgZm9yIGEgZGlmZmVyZW50IHpvb20gbGV2ZWwgdGhhbiB3ZSdyZSBjdXJyZW50bHkgb24uXHJcbiAgICAgICAgaWYgKHNlbGYubWFwICYmIHNlbGYubWFwLmdldFpvb20oKSAhPSBjdHguem9vbSkge1xyXG4gICAgICAgICAgY29uc29sZS5sb2coXCJGZXRjaGVkIHRpbGUgZm9yIHpvb20gbGV2ZWwgXCIgKyBjdHguem9vbSArIFwiLiBNYXAgaXMgYXQgem9vbSBsZXZlbCBcIiArIHNlbGYuX21hcC5nZXRab29tKCkpO1xyXG4gICAgICAgICAgcmV0dXJuO1xyXG4gICAgICAgIH1cclxuICAgICAgICBzZWxmLmNoZWNrVmVjdG9yVGlsZUxheWVycyhwYXJzZVZUKHZ0KSwgY3R4KTtcclxuICAgICAgICB0aWxlTG9hZGVkKHNlbGYsIGN0eCk7XHJcbiAgICAgIH1cclxuXHJcbiAgICAgIC8vZWl0aGVyIHdheSwgcmVkdWNlIHRoZSBjb3VudCBvZiB0aWxlc1RvUHJvY2VzcyB0aWxlcyBoZXJlXHJcbiAgICAgIHNlbGYucmVkdWNlVGlsZXNUb1Byb2Nlc3NDb3VudCgpO1xyXG4gICAgfTtcclxuXHJcbiAgICB4aHIub25lcnJvciA9IGZ1bmN0aW9uICgpIHtcclxuICAgICAgY29uc29sZS5sb2coXCJ4aHIgZXJyb3I6IFwiICsgeGhyLnN0YXR1cylcclxuICAgIH07XHJcbiAgICB0cnkge1xyXG4gICAgICB4aHIub3BlbignR0VUJywgc3JjLCB0cnVlKTsgLy9hc3luYyBpcyB0cnVlXHJcbiAgICAgIHZhciBoZWFkZXJzID0gc2VsZi5vcHRpb25zLnhockhlYWRlcnM7XHJcbiAgICAgIGZvciAodmFyIGhlYWRlciBpbiBoZWFkZXJzKSB7XHJcbiAgICAgICAgeGhyLnNldFJlcXVlc3RIZWFkZXIoaGVhZGVyLCBoZWFkZXJzW2hlYWRlcl0pXHJcbiAgICAgIH1cclxuICAgICAgeGhyLnJlc3BvbnNlVHlwZSA9ICdhcnJheWJ1ZmZlcic7XHJcbiAgICAgIHhoci5zZW5kKCk7XHJcbiAgICAgIH0gY2F0Y2ggKGV4KSB7XHJcbiAgICAgIC8vIHRoZXJlIHdhcyBhIEdFVCBlcnJvciBvbiB0aGUgdGlsZVxyXG4gICAgIH1cclxuXHJcbiAgfSxcclxuXHJcbiAgcmVkdWNlVGlsZXNUb1Byb2Nlc3NDb3VudDogZnVuY3Rpb24gKCkge1xyXG4gICAgdGhpcy5fdGlsZXNUb1Byb2Nlc3MtLTtcclxuICAgIGlmICghdGhpcy5fdGlsZXNUb1Byb2Nlc3MpIHtcclxuICAgICAgLy9UcmlnZ2VyIGV2ZW50IGxldHRpbmcgdXMga25vdyB0aGF0IGFsbCBQQkZzIGhhdmUgYmVlbiBsb2FkZWQgYW5kIHByb2Nlc3NlZCAob3IgNDA0J2QpLlxyXG4gICAgICBpZiAodGhpcy5fZXZlbnRIYW5kbGVyc1tcIlBCRkxvYWRcIl0pIHRoaXMuX2V2ZW50SGFuZGxlcnNbXCJQQkZMb2FkXCJdKCk7XHJcbiAgICAgIHRoaXMuX3BiZkxvYWRlZCgpO1xyXG4gICAgfVxyXG4gIH0sXHJcblxyXG4gIGNoZWNrVmVjdG9yVGlsZUxheWVyczogZnVuY3Rpb24gKHZ0LCBjdHgsIHBhcnNlZCkge1xyXG4gICAgdmFyIHNlbGYgPSB0aGlzO1xyXG5cclxuICAgIC8vQ2hlY2sgaWYgdGhlcmUgYXJlIHNwZWNpZmllZCB2aXNpYmxlIGxheWVyc1xyXG4gICAgaWYgKHNlbGYub3B0aW9ucy52aXNpYmxlTGF5ZXJzICYmIHNlbGYub3B0aW9ucy52aXNpYmxlTGF5ZXJzLmxlbmd0aCA+IDApIHtcclxuICAgICAgLy9vbmx5IGxldCB0aHJ1IHRoZSBsYXllcnMgbGlzdGVkIGluIHRoZSB2aXNpYmxlTGF5ZXJzIGFycmF5XHJcbiAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgc2VsZi5vcHRpb25zLnZpc2libGVMYXllcnMubGVuZ3RoOyBpKyspIHtcclxuICAgICAgICB2YXIgbGF5ZXJOYW1lID0gc2VsZi5vcHRpb25zLnZpc2libGVMYXllcnNbaV07XHJcbiAgICAgICAgaWYgKHZ0LmxheWVyc1tsYXllck5hbWVdKSB7XHJcbiAgICAgICAgICAvL1Byb2NlZWQgd2l0aCBwYXJzaW5nXHJcbiAgICAgICAgICBzZWxmLnByZXBhcmVNVlRMYXllcnModnQubGF5ZXJzW2xheWVyTmFtZV0sIGxheWVyTmFtZSwgY3R4LCBwYXJzZWQpO1xyXG4gICAgICAgIH1cclxuICAgICAgfVxyXG4gICAgfSBlbHNlIHtcclxuICAgICAgLy9QYXJzZSBhbGwgdnQubGF5ZXJzXHJcbiAgICAgIGZvciAodmFyIGtleSBpbiB2dC5sYXllcnMpIHtcclxuICAgICAgICBzZWxmLnByZXBhcmVNVlRMYXllcnModnQubGF5ZXJzW2tleV0sIGtleSwgY3R4LCBwYXJzZWQpO1xyXG4gICAgICB9XHJcbiAgICB9XHJcbiAgfSxcclxuXHJcbiAgcHJlcGFyZU1WVExheWVyczogZnVuY3Rpb24gKGx5ciwga2V5LCBjdHgsIHBhcnNlZCkge1xyXG4gICAgdmFyIHNlbGYgPSB0aGlzO1xyXG5cclxuICAgIGlmICghc2VsZi5sYXllcnNba2V5XSkge1xyXG4gICAgICAvL0NyZWF0ZSBNVlRMYXllciBvciBNVlRQb2ludExheWVyIGZvciB1c2VyXHJcbiAgICAgIHNlbGYubGF5ZXJzW2tleV0gPSBzZWxmLmNyZWF0ZU1WVExheWVyKGtleSwgbHlyLnBhcnNlZEZlYXR1cmVzWzBdLnR5cGUgfHwgbnVsbCk7XHJcbiAgICB9XHJcblxyXG4gICAgaWYgKHBhcnNlZCkge1xyXG4gICAgICAvL1dlJ3ZlIGFscmVhZHkgcGFyc2VkIGl0LiAgR28gZ2V0IGNhbnZhcyBhbmQgZHJhdy5cclxuICAgICAgc2VsZi5sYXllcnNba2V5XS5nZXRDYW52YXMoY3R4LCBseXIpO1xyXG4gICAgfSBlbHNlIHtcclxuICAgICAgc2VsZi5sYXllcnNba2V5XS5wYXJzZVZlY3RvclRpbGVMYXllcihseXIsIGN0eCk7XHJcbiAgICB9XHJcblxyXG4gIH0sXHJcblxyXG4gIGNyZWF0ZU1WVExheWVyOiBmdW5jdGlvbiAoa2V5LCB0eXBlKSB7XHJcbiAgICB2YXIgc2VsZiA9IHRoaXM7XHJcblxyXG4gICAgdmFyIGdldElERm9yTGF5ZXJGZWF0dXJlID0gVXRpbC5nZXRJREZvckxheWVyRmVhdHVyZTtcclxuXHJcbiAgICB2YXIgb3B0aW9ucyA9IHtcclxuICAgICAgZ2V0SURGb3JMYXllckZlYXR1cmU6IGdldElERm9yTGF5ZXJGZWF0dXJlLFxyXG4gICAgICBmaWx0ZXI6IHNlbGYub3B0aW9ucy5maWx0ZXIsXHJcbiAgICAgIGxheWVyT3JkZXJpbmc6IHNlbGYub3B0aW9ucy5sYXllck9yZGVyaW5nLFxyXG4gICAgICBzdHlsZTogc2VsZi5zdHlsZSxcclxuICAgICAgbmFtZToga2V5LFxyXG4gICAgICBhc3luY2g6IHRydWVcclxuICAgIH07XHJcblxyXG4gICAgaWYgKHNlbGYub3B0aW9ucy56SW5kZXgpIHtcclxuICAgICAgb3B0aW9ucy56SW5kZXggPSBzZWxmLnpJbmRleDtcclxuICAgIH1cclxuXHJcbiAgICAvL1Rha2UgdGhlIGxheWVyIGFuZCBjcmVhdGUgYSBuZXcgTVZUTGF5ZXIgb3IgTVZUUG9pbnRMYXllciBpZiBvbmUgZG9lc24ndCBleGlzdC5cclxuICAgIHZhciBsYXllciA9IG5ldyBNVlRMYXllcihzZWxmLCBvcHRpb25zKS5hZGRUbyhzZWxmLm1hcCk7XHJcblxyXG4gICAgcmV0dXJuIGxheWVyO1xyXG4gIH0sXHJcblxyXG4gIGdldExheWVyczogZnVuY3Rpb24gKCkge1xyXG4gICAgcmV0dXJuIHRoaXMubGF5ZXJzO1xyXG4gIH0sXHJcblxyXG4gIGhpZGVMYXllcjogZnVuY3Rpb24gKGlkKSB7XHJcbiAgICBpZiAodGhpcy5sYXllcnNbaWRdKSB7XHJcbiAgICAgIHRoaXMuX21hcC5yZW1vdmVMYXllcih0aGlzLmxheWVyc1tpZF0pO1xyXG4gICAgICBpZiAodGhpcy5vcHRpb25zLnZpc2libGVMYXllcnMuaW5kZXhPZihcImlkXCIpID4gLTEpIHtcclxuICAgICAgICB0aGlzLnZpc2libGVMYXllcnMuc3BsaWNlKHRoaXMub3B0aW9ucy52aXNpYmxlTGF5ZXJzLmluZGV4T2YoXCJpZFwiKSwgMSk7XHJcbiAgICAgIH1cclxuICAgIH1cclxuICB9LFxyXG5cclxuICBzaG93TGF5ZXI6IGZ1bmN0aW9uIChpZCkge1xyXG4gICAgaWYgKHRoaXMubGF5ZXJzW2lkXSkge1xyXG4gICAgICB0aGlzLl9tYXAuYWRkTGF5ZXIodGhpcy5sYXllcnNbaWRdKTtcclxuICAgICAgaWYgKHRoaXMub3B0aW9ucy52aXNpYmxlTGF5ZXJzLmluZGV4T2YoXCJpZFwiKSA9PSAtMSkge1xyXG4gICAgICAgIHRoaXMudmlzaWJsZUxheWVycy5wdXNoKGlkKTtcclxuICAgICAgfVxyXG4gICAgfVxyXG4gICAgLy9NYWtlIHN1cmUgbWFuYWdlciBsYXllciBpcyBhbHdheXMgaW4gZnJvbnRcclxuICAgIHRoaXMuYnJpbmdUb0Zyb250KCk7XHJcbiAgfSxcclxuXHJcbiAgcmVtb3ZlQ2hpbGRMYXllcnM6IGZ1bmN0aW9uIChtYXApIHtcclxuICAgIC8vUmVtb3ZlIGNoaWxkIGxheWVycyBvZiB0aGlzIGdyb3VwIGxheWVyXHJcbiAgICBmb3IgKHZhciBrZXkgaW4gdGhpcy5sYXllcnMpIHtcclxuICAgICAgdmFyIGxheWVyID0gdGhpcy5sYXllcnNba2V5XTtcclxuICAgICAgbWFwLnJlbW92ZUxheWVyKGxheWVyKTtcclxuICAgIH1cclxuICB9LFxyXG5cclxuICBhZGRDaGlsZExheWVyczogZnVuY3Rpb24gKG1hcCkge1xyXG4gICAgdmFyIHNlbGYgPSB0aGlzO1xyXG4gICAgaWYgKHNlbGYub3B0aW9ucy52aXNpYmxlTGF5ZXJzLmxlbmd0aCA+IDApIHtcclxuICAgICAgLy9vbmx5IGxldCB0aHJ1IHRoZSBsYXllcnMgbGlzdGVkIGluIHRoZSB2aXNpYmxlTGF5ZXJzIGFycmF5XHJcbiAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgc2VsZi5vcHRpb25zLnZpc2libGVMYXllcnMubGVuZ3RoOyBpKyspIHtcclxuICAgICAgICB2YXIgbGF5ZXJOYW1lID0gc2VsZi5vcHRpb25zLnZpc2libGVMYXllcnNbaV07XHJcbiAgICAgICAgdmFyIGxheWVyID0gdGhpcy5sYXllcnNbbGF5ZXJOYW1lXTtcclxuICAgICAgICBpZiAobGF5ZXIpIHtcclxuICAgICAgICAgIC8vUHJvY2VlZCB3aXRoIHBhcnNpbmdcclxuICAgICAgICAgIG1hcC5hZGRMYXllcihsYXllcik7XHJcbiAgICAgICAgfVxyXG4gICAgICB9XHJcbiAgICB9IGVsc2Uge1xyXG4gICAgICAvL0FkZCBhbGwgbGF5ZXJzXHJcbiAgICAgIGZvciAodmFyIGtleSBpbiB0aGlzLmxheWVycykge1xyXG4gICAgICAgIHZhciBsYXllciA9IHRoaXMubGF5ZXJzW2tleV07XHJcbiAgICAgICAgLy8gbGF5ZXIgaXMgc2V0IHRvIHZpc2libGUgYW5kIGlzIG5vdCBhbHJlYWR5IG9uIG1hcFxyXG4gICAgICAgIGlmICghbGF5ZXIuX21hcCkge1xyXG4gICAgICAgICAgbWFwLmFkZExheWVyKGxheWVyKTtcclxuICAgICAgICB9XHJcbiAgICAgIH1cclxuICAgIH1cclxuICB9LFxyXG5cclxuICBiaW5kOiBmdW5jdGlvbiAoZXZlbnRUeXBlLCBjYWxsYmFjaykge1xyXG4gICAgdGhpcy5fZXZlbnRIYW5kbGVyc1tldmVudFR5cGVdID0gY2FsbGJhY2s7XHJcbiAgfSxcclxuXHJcbiAgX29uQ2xpY2s6IGZ1bmN0aW9uIChldnQpIHtcclxuICAgIC8vSGVyZSwgcGFzcyB0aGUgZXZlbnQgb24gdG8gdGhlIGNoaWxkIE1WVExheWVyIGFuZCBoYXZlIGl0IGRvIHRoZSBoaXQgdGVzdCBhbmQgaGFuZGxlIHRoZSByZXN1bHQuXHJcbiAgICB2YXIgc2VsZiA9IHRoaXM7XHJcbiAgICB2YXIgb25DbGljayA9IHNlbGYub3B0aW9ucy5vbkNsaWNrO1xyXG4gICAgdmFyIGNsaWNrYWJsZUxheWVycyA9IHNlbGYub3B0aW9ucy5jbGlja2FibGVMYXllcnM7XHJcbiAgICB2YXIgbGF5ZXJzID0gc2VsZi5sYXllcnM7XHJcblxyXG4gICAgZXZ0LnRpbGVJRCA9IGdldFRpbGVVUkwoZXZ0LmxhdGxuZy5sYXQsIGV2dC5sYXRsbmcubG5nLCB0aGlzLm1hcC5nZXRab29tKCkpO1xyXG5cclxuICAgIC8vIFdlIG11c3QgaGF2ZSBhbiBhcnJheSBvZiBjbGlja2FibGUgbGF5ZXJzLCBvdGhlcndpc2UsIHdlIGp1c3QgcGFzc1xyXG4gICAgLy8gdGhlIGV2ZW50IHRvIHRoZSBwdWJsaWMgb25DbGljayBjYWxsYmFjayBpbiBvcHRpb25zLlxyXG5cclxuICAgIGlmICghY2xpY2thYmxlTGF5ZXJzKSB7XHJcbiAgICAgIGNsaWNrYWJsZUxheWVycyA9IE9iamVjdC5rZXlzKHNlbGYubGF5ZXJzKTtcclxuICAgIH1cclxuXHJcbiAgICBpZiAoY2xpY2thYmxlTGF5ZXJzICYmIGNsaWNrYWJsZUxheWVycy5sZW5ndGggPiAwKSB7XHJcbiAgICAgIGZvciAodmFyIGkgPSAwLCBsZW4gPSBjbGlja2FibGVMYXllcnMubGVuZ3RoOyBpIDwgbGVuOyBpKyspIHtcclxuICAgICAgICB2YXIga2V5ID0gY2xpY2thYmxlTGF5ZXJzW2ldO1xyXG4gICAgICAgIHZhciBsYXllciA9IGxheWVyc1trZXldO1xyXG4gICAgICAgIGlmIChsYXllcikge1xyXG4gICAgICAgICAgbGF5ZXIuaGFuZGxlQ2xpY2tFdmVudChldnQsIGZ1bmN0aW9uIChldnQpIHtcclxuICAgICAgICAgICAgaWYgKHR5cGVvZiBvbkNsaWNrID09PSAnZnVuY3Rpb24nKSB7XHJcbiAgICAgICAgICAgICAgb25DbGljayhldnQpO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgICB9KTtcclxuICAgICAgICB9XHJcbiAgICAgIH1cclxuICAgIH0gZWxzZSB7XHJcbiAgICAgIGlmICh0eXBlb2Ygb25DbGljayA9PT0gJ2Z1bmN0aW9uJykge1xyXG4gICAgICAgIG9uQ2xpY2soZXZ0KTtcclxuICAgICAgfVxyXG4gICAgfVxyXG5cclxuICB9LFxyXG5cclxuICBzZXRGaWx0ZXI6IGZ1bmN0aW9uIChmaWx0ZXJGdW5jdGlvbiwgbGF5ZXJOYW1lKSB7XHJcbiAgICAvL3Rha2UgaW4gYSBuZXcgZmlsdGVyIGZ1bmN0aW9uLlxyXG4gICAgLy9Qcm9wYWdhdGUgdG8gY2hpbGQgbGF5ZXJzLlxyXG5cclxuICAgIC8vQWRkIGZpbHRlciB0byBhbGwgY2hpbGQgbGF5ZXJzIGlmIG5vIGxheWVyIGlzIHNwZWNpZmllZC5cclxuICAgIGZvciAodmFyIGtleSBpbiB0aGlzLmxheWVycykge1xyXG4gICAgICB2YXIgbGF5ZXIgPSB0aGlzLmxheWVyc1trZXldO1xyXG5cclxuICAgICAgaWYgKGxheWVyTmFtZSkge1xyXG4gICAgICAgIGlmIChrZXkudG9Mb3dlckNhc2UoKSA9PSBsYXllck5hbWUudG9Mb3dlckNhc2UoKSkge1xyXG4gICAgICAgICAgbGF5ZXIub3B0aW9ucy5maWx0ZXIgPSBmaWx0ZXJGdW5jdGlvbjsgLy9Bc3NpZ24gZmlsdGVyIHRvIGNoaWxkIGxheWVyLCBvbmx5IGlmIG5hbWUgbWF0Y2hlc1xyXG4gICAgICAgICAgLy9BZnRlciBmaWx0ZXIgaXMgc2V0LCB0aGUgb2xkIGZlYXR1cmUgaGFzaGVzIGFyZSBpbnZhbGlkLiAgQ2xlYXIgdGhlbSBmb3IgbmV4dCBkcmF3LlxyXG4gICAgICAgICAgbGF5ZXIuY2xlYXJMYXllckZlYXR1cmVIYXNoKCk7XHJcbiAgICAgICAgICAvL2xheWVyLmNsZWFyVGlsZUZlYXR1cmVIYXNoKCk7XHJcbiAgICAgICAgfVxyXG4gICAgICB9XHJcbiAgICAgIGVsc2Uge1xyXG4gICAgICAgIGxheWVyLm9wdGlvbnMuZmlsdGVyID0gZmlsdGVyRnVuY3Rpb247IC8vQXNzaWduIGZpbHRlciB0byBjaGlsZCBsYXllclxyXG4gICAgICAgIC8vQWZ0ZXIgZmlsdGVyIGlzIHNldCwgdGhlIG9sZCBmZWF0dXJlIGhhc2hlcyBhcmUgaW52YWxpZC4gIENsZWFyIHRoZW0gZm9yIG5leHQgZHJhdy5cclxuICAgICAgICBsYXllci5jbGVhckxheWVyRmVhdHVyZUhhc2goKTtcclxuICAgICAgICAvL2xheWVyLmNsZWFyVGlsZUZlYXR1cmVIYXNoKCk7XHJcbiAgICAgIH1cclxuICAgIH1cclxuICB9LFxyXG5cclxuICAvKipcclxuICAgKiBUYWtlIGluIGEgbmV3IHN0eWxlIGZ1bmN0aW9uIGFuZCBwcm9wb2dhdGUgdG8gY2hpbGQgbGF5ZXJzLlxyXG4gICAqIElmIHlvdSBkbyBub3Qgc2V0IGEgbGF5ZXIgbmFtZSwgaXQgcmVzZXRzIHRoZSBzdHlsZSBmb3IgYWxsIG9mIHRoZSBsYXllcnMuXHJcbiAgICogQHBhcmFtIHN0eWxlRnVuY3Rpb25cclxuICAgKiBAcGFyYW0gbGF5ZXJOYW1lXHJcbiAgICovXHJcbiAgc2V0U3R5bGU6IGZ1bmN0aW9uIChzdHlsZUZuLCBsYXllck5hbWUpIHtcclxuICAgIGZvciAodmFyIGtleSBpbiB0aGlzLmxheWVycykge1xyXG4gICAgICB2YXIgbGF5ZXIgPSB0aGlzLmxheWVyc1trZXldO1xyXG4gICAgICBpZiAobGF5ZXJOYW1lKSB7XHJcbiAgICAgICAgaWYgKGtleS50b0xvd2VyQ2FzZSgpID09IGxheWVyTmFtZS50b0xvd2VyQ2FzZSgpKSB7XHJcbiAgICAgICAgICBsYXllci5zZXRTdHlsZShzdHlsZUZuKTtcclxuICAgICAgICB9XHJcbiAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgbGF5ZXIuc2V0U3R5bGUoc3R5bGVGbik7XHJcbiAgICAgIH1cclxuICAgIH1cclxuICB9LFxyXG5cclxuICBmZWF0dXJlU2VsZWN0ZWQ6IGZ1bmN0aW9uIChtdnRGZWF0dXJlKSB7XHJcbiAgICBpZiAodGhpcy5vcHRpb25zLm11dGV4VG9nZ2xlKSB7XHJcbiAgICAgIGlmICh0aGlzLl9zZWxlY3RlZEZlYXR1cmUpIHtcclxuICAgICAgICB0aGlzLl9zZWxlY3RlZEZlYXR1cmUuZGVzZWxlY3QoKTtcclxuICAgICAgfVxyXG4gICAgICB0aGlzLl9zZWxlY3RlZEZlYXR1cmUgPSBtdnRGZWF0dXJlO1xyXG4gICAgfVxyXG4gICAgaWYgKHRoaXMub3B0aW9ucy5vblNlbGVjdCkge1xyXG4gICAgICB0aGlzLm9wdGlvbnMub25TZWxlY3QobXZ0RmVhdHVyZSk7XHJcbiAgICB9XHJcbiAgfSxcclxuXHJcbiAgZmVhdHVyZURlc2VsZWN0ZWQ6IGZ1bmN0aW9uIChtdnRGZWF0dXJlKSB7XHJcbiAgICBpZiAodGhpcy5vcHRpb25zLm11dGV4VG9nZ2xlICYmIHRoaXMuX3NlbGVjdGVkRmVhdHVyZSkge1xyXG4gICAgICB0aGlzLl9zZWxlY3RlZEZlYXR1cmUgPSBudWxsO1xyXG4gICAgfVxyXG4gICAgaWYgKHRoaXMub3B0aW9ucy5vbkRlc2VsZWN0KSB7XHJcbiAgICAgIHRoaXMub3B0aW9ucy5vbkRlc2VsZWN0KG12dEZlYXR1cmUpO1xyXG4gICAgfVxyXG4gIH0sXHJcblxyXG4gIF9wYmZMb2FkZWQ6IGZ1bmN0aW9uICgpIHtcclxuICAgIC8vRmlyZXMgd2hlbiBhbGwgdGlsZXMgZnJvbSB0aGlzIGxheWVyIGhhdmUgYmVlbiBsb2FkZWQgYW5kIGRyYXduIChvciA0MDQnZCkuXHJcblxyXG4gICAgLy9NYWtlIHN1cmUgbWFuYWdlciBsYXllciBpcyBhbHdheXMgaW4gZnJvbnRcclxuICAgIHRoaXMuYnJpbmdUb0Zyb250KCk7XHJcblxyXG4gICAgLy9TZWUgaWYgdGhlcmUgaXMgYW4gZXZlbnQgdG8gZXhlY3V0ZVxyXG4gICAgdmFyIHNlbGYgPSB0aGlzO1xyXG4gICAgdmFyIG9uVGlsZXNMb2FkZWQgPSBzZWxmLm9wdGlvbnMub25UaWxlc0xvYWRlZDtcclxuXHJcbiAgICBpZiAob25UaWxlc0xvYWRlZCAmJiB0eXBlb2Ygb25UaWxlc0xvYWRlZCA9PT0gJ2Z1bmN0aW9uJyAmJiB0aGlzLl90cmlnZ2VyT25UaWxlc0xvYWRlZEV2ZW50ID09PSB0cnVlKSB7XHJcbiAgICAgIG9uVGlsZXNMb2FkZWQodGhpcyk7XHJcbiAgICB9XHJcbiAgICBzZWxmLl90cmlnZ2VyT25UaWxlc0xvYWRlZEV2ZW50ID0gdHJ1ZTsgLy9yZXNldCAtIGlmIHJlZHJhdygpIGlzIGNhbGxlZCB3aXRoIHRoZSBvcHRpbmFsICdmYWxzZScgcGFyYW1ldGVyIHRvIHRlbXBvcmFyaWx5IGRpc2FibGUgdGhlIG9uVGlsZXNMb2FkZWQgZXZlbnQgZnJvbSBmaXJpbmcuICBUaGlzIHJlc2V0cyBpdCBiYWNrIHRvIHRydWUgYWZ0ZXIgYSBzaW5nbGUgdGltZSBvZiBmaXJpbmcgYXMgJ2ZhbHNlJy5cclxuICB9XHJcblxyXG59KTtcclxuXHJcblxyXG5pZiAodHlwZW9mIChOdW1iZXIucHJvdG90eXBlLnRvUmFkKSA9PT0gXCJ1bmRlZmluZWRcIikge1xyXG4gIE51bWJlci5wcm90b3R5cGUudG9SYWQgPSBmdW5jdGlvbiAoKSB7XHJcbiAgICByZXR1cm4gdGhpcyAqIE1hdGguUEkgLyAxODA7XHJcbiAgfVxyXG59XHJcblxyXG5mdW5jdGlvbiBnZXRUaWxlVVJMKGxhdCwgbG9uLCB6b29tKSB7XHJcbiAgdmFyIHh0aWxlID0gcGFyc2VJbnQoTWF0aC5mbG9vcigobG9uICsgMTgwKSAvIDM2MCAqICgxIDw8IHpvb20pKSk7XHJcbiAgdmFyIHl0aWxlID0gcGFyc2VJbnQoTWF0aC5mbG9vcigoMSAtIE1hdGgubG9nKE1hdGgudGFuKGxhdC50b1JhZCgpKSArIDEgLyBNYXRoLmNvcyhsYXQudG9SYWQoKSkpIC8gTWF0aC5QSSkgLyAyICogKDEgPDwgem9vbSkpKTtcclxuICByZXR1cm4gXCJcIiArIHpvb20gKyBcIjpcIiArIHh0aWxlICsgXCI6XCIgKyB5dGlsZTtcclxufVxyXG5cclxuZnVuY3Rpb24gdGlsZUxvYWRlZChwYmZTb3VyY2UsIGN0eCkge1xyXG4gIHBiZlNvdXJjZS5sb2FkZWRUaWxlc1tjdHguaWRdID0gY3R4O1xyXG59XHJcblxyXG5mdW5jdGlvbiBwYXJzZVZUKHZ0KSB7XHJcbiAgZm9yICh2YXIga2V5IGluIHZ0LmxheWVycykge1xyXG4gICAgdmFyIGx5ciA9IHZ0LmxheWVyc1trZXldO1xyXG4gICAgcGFyc2VWVEZlYXR1cmVzKGx5cik7XHJcbiAgfVxyXG4gIHJldHVybiB2dDtcclxufVxyXG5cclxuZnVuY3Rpb24gcGFyc2VWVEZlYXR1cmVzKHZ0bCkge1xyXG4gIHZ0bC5wYXJzZWRGZWF0dXJlcyA9IFtdO1xyXG4gIHZhciBmZWF0dXJlcyA9IHZ0bC5fZmVhdHVyZXM7XHJcbiAgZm9yICh2YXIgaSA9IDAsIGxlbiA9IGZlYXR1cmVzLmxlbmd0aDsgaSA8IGxlbjsgaSsrKSB7XHJcbiAgICB2YXIgdnRmID0gdnRsLmZlYXR1cmUoaSk7XHJcbiAgICB2dGYuY29vcmRpbmF0ZXMgPSB2dGYubG9hZEdlb21ldHJ5KCk7XHJcbiAgICB2dGwucGFyc2VkRmVhdHVyZXMucHVzaCh2dGYpO1xyXG4gIH1cclxuICByZXR1cm4gdnRsO1xyXG59XHJcbiIsIi8qKlxyXG4gKiBDcmVhdGVkIGJ5IE5pY2hvbGFzIEhhbGxhaGFuIDxuaGFsbGFoYW5Ac3BhdGlhbGRldi5jb20+XHJcbiAqICAgICAgIG9uIDgvMTUvMTQuXHJcbiAqL1xyXG52YXIgVXRpbCA9IG1vZHVsZS5leHBvcnRzID0ge307XHJcblxyXG5VdGlsLmdldENvbnRleHRJRCA9IGZ1bmN0aW9uKGN0eCkge1xyXG4gIHJldHVybiBbY3R4Lnpvb20sIGN0eC50aWxlLngsIGN0eC50aWxlLnldLmpvaW4oXCI6XCIpO1xyXG59O1xyXG5cclxuLyoqXHJcbiAqIERlZmF1bHQgZnVuY3Rpb24gdGhhdCBnZXRzIHRoZSBpZCBmb3IgYSBsYXllciBmZWF0dXJlLlxyXG4gKiBTb21ldGltZXMgdGhpcyBuZWVkcyB0byBiZSBkb25lIGluIGEgZGlmZmVyZW50IHdheSBhbmRcclxuICogY2FuIGJlIHNwZWNpZmllZCBieSB0aGUgdXNlciBpbiB0aGUgb3B0aW9ucyBmb3IgTC5UaWxlTGF5ZXIuTVZUU291cmNlLlxyXG4gKlxyXG4gKiBAcGFyYW0gZmVhdHVyZVxyXG4gKiBAcmV0dXJucyB7Y3R4LmlkfCp8aWR8c3RyaW5nfGpzdHMuaW5kZXguY2hhaW4uTW9ub3RvbmVDaGFpbi5pZHxudW1iZXJ9XHJcbiAqL1xyXG5VdGlsLmdldElERm9yTGF5ZXJGZWF0dXJlID0gZnVuY3Rpb24gKGZlYXR1cmUpIHtcclxuICByZXR1cm4gZmVhdHVyZS5wcm9wZXJ0aWVzLmlkO1xyXG59O1xyXG5cclxuVXRpbC5nZXRKU09OID0gZnVuY3Rpb24odXJsLCBjYWxsYmFjaykge1xyXG4gIHZhciB4bWxodHRwID0gdHlwZW9mIFhNTEh0dHBSZXF1ZXN0ICE9PSAndW5kZWZpbmVkJyA/IG5ldyBYTUxIdHRwUmVxdWVzdCgpIDogbmV3IEFjdGl2ZVhPYmplY3QoJ01pY3Jvc29mdC5YTUxIVFRQJyk7XHJcbiAgeG1saHR0cC5vbnJlYWR5c3RhdGVjaGFuZ2UgPSBmdW5jdGlvbigpIHtcclxuICAgIHZhciBzdGF0dXMgPSB4bWxodHRwLnN0YXR1cztcclxuICAgIGlmICh4bWxodHRwLnJlYWR5U3RhdGUgPT09IDQgJiYgc3RhdHVzID49IDIwMCAmJiBzdGF0dXMgPCAzMDApIHtcclxuICAgICAgdmFyIGpzb24gPSBKU09OLnBhcnNlKHhtbGh0dHAucmVzcG9uc2VUZXh0KTtcclxuICAgICAgY2FsbGJhY2sobnVsbCwganNvbik7XHJcbiAgICB9IGVsc2Uge1xyXG4gICAgICBjYWxsYmFjayggeyBlcnJvcjogdHJ1ZSwgc3RhdHVzOiBzdGF0dXMgfSApO1xyXG4gICAgfVxyXG4gIH07XHJcbiAgeG1saHR0cC5vcGVuKFwiR0VUXCIsIHVybCwgdHJ1ZSk7XHJcbiAgeG1saHR0cC5zZW5kKCk7XHJcbn07XHJcbiIsIi8qKlxyXG4gKiBDcmVhdGVkIGJ5IE5pY2hvbGFzIEhhbGxhaGFuIDxuaGFsbGFoYW5Ac3BhdGlhbGRldi5jb20+XHJcbiAqICAgICAgIG9uIDcvMzEvMTQuXHJcbiAqL1xyXG52YXIgVXRpbCA9IHJlcXVpcmUoJy4uL01WVFV0aWwnKTtcclxubW9kdWxlLmV4cG9ydHMgPSBTdGF0aWNMYWJlbDtcclxuXHJcbmZ1bmN0aW9uIFN0YXRpY0xhYmVsKG12dEZlYXR1cmUsIGN0eCwgbGF0TG5nLCBzdHlsZSkge1xyXG4gIHZhciBzZWxmID0gdGhpcztcclxuICB0aGlzLm12dEZlYXR1cmUgPSBtdnRGZWF0dXJlO1xyXG4gIHRoaXMubWFwID0gbXZ0RmVhdHVyZS5tYXA7XHJcbiAgdGhpcy56b29tID0gY3R4Lnpvb207XHJcbiAgdGhpcy5sYXRMbmcgPSBsYXRMbmc7XHJcbiAgdGhpcy5zZWxlY3RlZCA9IGZhbHNlO1xyXG5cclxuICBpZiAobXZ0RmVhdHVyZS5saW5rZWRGZWF0dXJlKSB7XHJcbiAgICB2YXIgbGlua2VkRmVhdHVyZSA9IG12dEZlYXR1cmUubGlua2VkRmVhdHVyZSgpO1xyXG4gICAgaWYgKGxpbmtlZEZlYXR1cmUgJiYgbGlua2VkRmVhdHVyZS5zZWxlY3RlZCkge1xyXG4gICAgICBzZWxmLnNlbGVjdGVkID0gdHJ1ZTtcclxuICAgIH1cclxuICB9XHJcblxyXG4gIGluaXQoc2VsZiwgbXZ0RmVhdHVyZSwgY3R4LCBsYXRMbmcsIHN0eWxlKVxyXG59XHJcblxyXG5mdW5jdGlvbiBpbml0KHNlbGYsIG12dEZlYXR1cmUsIGN0eCwgbGF0TG5nLCBzdHlsZSkge1xyXG4gIHZhciBhamF4RGF0YSA9IG12dEZlYXR1cmUuYWpheERhdGE7XHJcbiAgdmFyIHN0eSA9IHNlbGYuc3R5bGUgPSBzdHlsZS5zdGF0aWNMYWJlbChtdnRGZWF0dXJlLCBhamF4RGF0YSk7XHJcbiAgdmFyIGljb24gPSBzZWxmLmljb24gPSBMLmRpdkljb24oe1xyXG4gICAgY2xhc3NOYW1lOiBzdHkuY3NzQ2xhc3MgfHwgJ2xhYmVsLWljb24tdGV4dCcsXHJcbiAgICBodG1sOiBzdHkuaHRtbCxcclxuICAgIGljb25TaXplOiBzdHkuaWNvblNpemUgfHwgWzUwLDUwXVxyXG4gIH0pO1xyXG5cclxuICBzZWxmLm1hcmtlciA9IEwubWFya2VyKGxhdExuZywge2ljb246IGljb259KS5hZGRUbyhzZWxmLm1hcCk7XHJcblxyXG4gIGlmIChzZWxmLnNlbGVjdGVkKSB7XHJcbiAgICBzZWxmLm1hcmtlci5faWNvbi5jbGFzc0xpc3QuYWRkKHNlbGYuc3R5bGUuY3NzU2VsZWN0ZWRDbGFzcyB8fCAnbGFiZWwtaWNvbi10ZXh0LXNlbGVjdGVkJyk7XHJcbiAgfVxyXG5cclxuICBzZWxmLm1hcmtlci5vbignY2xpY2snLCBmdW5jdGlvbihlKSB7XHJcbiAgICBzZWxmLnRvZ2dsZSgpO1xyXG4gIH0pO1xyXG5cclxuICBzZWxmLm1hcC5vbignem9vbWVuZCcsIGZ1bmN0aW9uKGUpIHtcclxuICAgIHZhciBuZXdab29tID0gZS50YXJnZXQuZ2V0Wm9vbSgpO1xyXG4gICAgaWYgKHNlbGYuem9vbSAhPT0gbmV3Wm9vbSkge1xyXG4gICAgICBzZWxmLm1hcC5yZW1vdmVMYXllcihzZWxmLm1hcmtlcik7XHJcbiAgICB9XHJcbiAgfSk7XHJcbn1cclxuXHJcblxyXG5TdGF0aWNMYWJlbC5wcm90b3R5cGUudG9nZ2xlID0gZnVuY3Rpb24oKSB7XHJcbiAgaWYgKHRoaXMuc2VsZWN0ZWQpIHtcclxuICAgIHRoaXMuZGVzZWxlY3QoKTtcclxuICB9IGVsc2Uge1xyXG4gICAgdGhpcy5zZWxlY3QoKTtcclxuICB9XHJcbn07XHJcblxyXG5TdGF0aWNMYWJlbC5wcm90b3R5cGUuc2VsZWN0ID0gZnVuY3Rpb24oKSB7XHJcbiAgdGhpcy5zZWxlY3RlZCA9IHRydWU7XHJcbiAgdGhpcy5tYXJrZXIuX2ljb24uY2xhc3NMaXN0LmFkZCh0aGlzLnN0eWxlLmNzc1NlbGVjdGVkQ2xhc3MgfHwgJ2xhYmVsLWljb24tdGV4dC1zZWxlY3RlZCcpO1xyXG4gIHZhciBsaW5rZWRGZWF0dXJlID0gdGhpcy5tdnRGZWF0dXJlLmxpbmtlZEZlYXR1cmUoKTtcclxuICBpZiAoIWxpbmtlZEZlYXR1cmUuc2VsZWN0ZWQpIGxpbmtlZEZlYXR1cmUuc2VsZWN0KCk7XHJcbn07XHJcblxyXG5TdGF0aWNMYWJlbC5wcm90b3R5cGUuZGVzZWxlY3QgPSBmdW5jdGlvbigpIHtcclxuICB0aGlzLnNlbGVjdGVkID0gZmFsc2U7XHJcbiAgdGhpcy5tYXJrZXIuX2ljb24uY2xhc3NMaXN0LnJlbW92ZSh0aGlzLnN0eWxlLmNzc1NlbGVjdGVkQ2xhc3MgfHwgJ2xhYmVsLWljb24tdGV4dC1zZWxlY3RlZCcpO1xyXG4gIHZhciBsaW5rZWRGZWF0dXJlID0gdGhpcy5tdnRGZWF0dXJlLmxpbmtlZEZlYXR1cmUoKTtcclxuICBpZiAobGlua2VkRmVhdHVyZS5zZWxlY3RlZCkgbGlua2VkRmVhdHVyZS5kZXNlbGVjdCgpO1xyXG59O1xyXG5cclxuU3RhdGljTGFiZWwucHJvdG90eXBlLnJlbW92ZSA9IGZ1bmN0aW9uKCkge1xyXG4gIGlmICghdGhpcy5tYXAgfHwgIXRoaXMubWFya2VyKSByZXR1cm47XHJcbiAgdGhpcy5tYXAucmVtb3ZlTGF5ZXIodGhpcy5tYXJrZXIpO1xyXG59O1xyXG4iLCIvKipcclxuICogQ29weXJpZ2h0IChjKSAyMDE0LCBTcGF0aWFsIERldmVsb3BtZW50IEludGVybmF0aW9uYWxcclxuICogQWxsIHJpZ2h0cyByZXNlcnZlZC5cclxuICpcclxuICogU291cmNlIGNvZGUgY2FuIGJlIGZvdW5kIGF0OlxyXG4gKiBodHRwczovL2dpdGh1Yi5jb20vU3BhdGlhbFNlcnZlci9MZWFmbGV0Lk1hcGJveFZlY3RvclRpbGVcclxuICpcclxuICogQGxpY2Vuc2UgSVNDXHJcbiAqL1xyXG5cclxubW9kdWxlLmV4cG9ydHMgPSByZXF1aXJlKCcuL01WVFNvdXJjZScpO1xyXG4iXX0=
