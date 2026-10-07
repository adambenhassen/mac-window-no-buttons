"""Point an LC_LOAD_DYLIB of an unsigned Mach-O file at a proxy dylib.

The proxy must re-export the original library, so every symbol still binds.
Usage: proxy_dylib.py BINARY OLD_PATH NEW_PATH
"""

import struct
import sys

FAT_MAGIC = 0xCAFEBABE
MH_MAGIC_64 = 0xFEEDFACF
LC_LOAD_DYLIB = 0xC
LC_SEGMENT_64 = 0x19
LC_CODE_SIGNATURE = 0x1D
SIGNATURE_CMD_SIZE = 16  # room codesign needs to add LC_CODE_SIGNATURE back


def dylib_name(cmd):
    return bytes(cmd[24:]).split(b"\0")[0].decode()


def patch_slice(data, base, old, new):
    magic, _, _, _, ncmds, sizeofcmds = struct.unpack_from("<6I", data, base)
    if magic != MH_MAGIC_64:
        sys.exit(f"unsupported slice magic {magic:#x}")

    cmds, first_data, off = [], None, base + 32
    for _ in range(ncmds):
        cmd, size = struct.unpack_from("<2I", data, off)
        if cmd == LC_CODE_SIGNATURE:
            sys.exit("binary is still signed; remove the signature first")
        if cmd == LC_SEGMENT_64:
            nsects = struct.unpack_from("<I", data, off + 64)[0]
            for s in range(nsects):
                sect_off = struct.unpack_from("<I", data, off + 72 + s * 80 + 48)[0]
                if sect_off and (first_data is None or sect_off < first_data):
                    first_data = sect_off
        cmds.append(data[off:off + size])
        off += size

    names = [dylib_name(c) for c in cmds if struct.unpack_from("<I", c)[0] == LC_LOAD_DYLIB]
    if new in names:
        return False
    if old not in names:
        sys.exit(f"{old} is not a dependency")

    out = bytearray()
    for c in cmds:
        if struct.unpack_from("<I", c)[0] == LC_LOAD_DYLIB and dylib_name(c) == old:
            name = new.encode() + b"\0"
            size = (24 + len(name) + 7) & ~7
            # Keep the original timestamp and version fields.
            c = (struct.pack("<3I", LC_LOAD_DYLIB, size, 24) + bytes(c[12:24]) + name).ljust(size, b"\0")
        out += c

    start, limit = base + 32, base + first_data
    if start + len(out) + SIGNATURE_CMD_SIZE > limit:
        sys.exit("not enough header padding for the new load command")
    data[start:limit] = out.ljust(limit - start, b"\0")
    struct.pack_into("<I", data, base + 20, len(out))
    return True


def main():
    path, old, new = sys.argv[1:4]
    with open(path, "rb") as f:
        data = bytearray(f.read())

    if struct.unpack_from(">I", data, 0)[0] == FAT_MAGIC:
        nfat = struct.unpack_from(">I", data, 4)[0]
        bases = [struct.unpack_from(">5I", data, 8 + i * 20)[2] for i in range(nfat)]
    else:
        bases = [0]

    changed = [patch_slice(data, b, old, new) for b in bases]
    if any(changed):
        with open(path, "wb") as f:
            f.write(data)
    print(f"{path}: {'patched' if any(changed) else 'already patched'}")


if __name__ == "__main__":
    main()
