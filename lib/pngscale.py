#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
"""Enlarge a PNG by a whole factor with hard pixel edges (nearest neighbour).

    pngscale.py IN.png OUT.png FACTOR

Used for classic pixel-art icons on the boot screen: Plymouth's own scaling
smooths them. Standard library only (no Pillow). Reads 8-bit or lower,
non-interlaced PNGs (grey, RGB, palette, grey+alpha, RGBA); writes RGBA.
"""
import struct
import sys
import zlib


def read_png(path):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos, idat, palette, trns = 8, b"", None, None
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            w, h, depth, ctype, _, _, interlace = struct.unpack(">IIBBBBB", chunk)
        elif kind == b"PLTE":
            palette = [tuple(chunk[i:i + 3]) for i in range(0, len(chunk), 3)]
        elif kind == b"tRNS":
            trns = chunk
        elif kind == b"IDAT":
            idat += chunk
        elif kind == b"IEND":
            break
    if depth > 8 or interlace:
        raise ValueError("16-bit or interlaced PNGs are not supported")
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype]
    bits = depth * channels
    stride = (w * bits + 7) // 8
    bpp = max(1, bits // 8)
    raw = zlib.decompress(idat)
    rows, prev = [], bytearray(stride)
    for y in range(h):
        f = raw[y * (stride + 1)]
        line = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            if f == 1:
                line[i] = (line[i] + a) & 255
            elif f == 2:
                line[i] = (line[i] + b) & 255
            elif f == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(line)
        prev = line
    out = []
    for line in rows:
        if depth < 8:  # unpack sub-byte samples
            per = 8 // depth
            mask = (1 << depth) - 1
            samples = [(line[x // per] >> (8 - depth * (x % per + 1))) & mask for x in range(w * channels)]
        else:
            samples = list(line)
        px = []
        for x in range(w):
            s = samples[x * channels:(x + 1) * channels]
            if ctype == 3:
                r, g, b = palette[s[0]]
                a = trns[s[0]] if trns and s[0] < len(trns) else 255
            elif ctype == 0:
                v = s[0] * 255 // ((1 << depth) - 1)
                r = g = b = v
                a = 255
            elif ctype == 4:
                r = g = b = s[0]
                a = s[1]
            elif ctype == 2:
                r, g, b = s
                a = 255
            else:
                r, g, b, a = s
            px.append((r, g, b, a))
        out.append(px)
    return w, h, out


def write_png(path, w, h, rows):
    raw = b"".join(b"\x00" + bytes(c for p in row for c in p) for row in rows)

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xffffffff)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def main():
    src, dst, factor = sys.argv[1], sys.argv[2], int(sys.argv[3])
    w, h, rows = read_png(src)
    big = []
    for row in rows:
        line = [p for p in row for _ in range(factor)]
        big.extend([line] * factor)
    write_png(dst, w * factor, h * factor, big)


if __name__ == "__main__":
    main()
