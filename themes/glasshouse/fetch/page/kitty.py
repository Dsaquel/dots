import struct

from .term import ESC, at

IMG = {"her": 0x67680001, "clip": 0x67680100, "page": 0x67680200}


def apc(keys, payload=""):
    return f"{ESC}_G{keys},q=2" + (f";{payload}" if payload else "") + f"{ESC}\\"


def b64(value):
    from base64 import standard_b64encode
    return standard_b64encode(value.encode()).decode()


def show(iid, path, row, col, x=0, y=0, z=0, crop=None):
    src = f",x={crop[0]},y={crop[1]},w={crop[2]},h={crop[3]}" if crop else ""
    return at(row, col) + apc(f"a=T,t=f,f=100,i={iid},p=1,X={x},Y={y},z={z},C=1{src}", b64(str(path)))


def png_size(path):
    with open(path, "rb") as fh:
        head = fh.read(24)
    return struct.unpack(">II", head[16:24])
