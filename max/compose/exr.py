"""EXR work outside Max: split multi-layer EXRs into per-pass files Photoshop can
open, and cut Cryptomatte mattes into small 8-bit greyscale PNGs.

This is the memory fix: Photoshop never sees a matte EXR. Each matte arrives as
a W×H×1-byte mask (a 4K matte is ~8 MB in Photoshop instead of a 32-bit RGBA
smart object of ~130 MB), and only the mattes that exist get made.
"""
import json
import re
import struct
import zlib

import numpy as np
import OpenEXR


# ── Reading ─────────────────────────────────────────────────────────────────

def read_layers(path):
    """{layer: {"R": arr, "G": arr, …}, …} plus the header of the first part."""
    f = OpenEXR.File(path, separate_channels=True)
    layers = {}
    header = {}
    for part in f.parts:
        header.update(part.header)
        for name, ch in part.channels.items():
            layer, _, comp = name.rpartition(".")
            layers.setdefault(layer, {})[comp or name] = ch.pixels
    return layers, header


def write_rgb(path, chans, half=True):
    """Single-layer R,G,B(,A) EXR — the form Photoshop opens."""
    dtype = np.float16 if half else np.float32
    out = {}
    for c in ("R", "G", "B", "A"):
        if c in chans:
            out[c] = np.ascontiguousarray(chans[c].astype(dtype))
    if "R" in out and "G" not in out:      # single-channel pass (Z) → grey RGB
        out["G"] = out["B"] = out["R"]
    hdr = {"compression": OpenEXR.ZIP_COMPRESSION, "type": OpenEXR.scanlineimage}
    OpenEXR.File(hdr, out).write(path)


# ── Cryptomatte ─────────────────────────────────────────────────────────────

def _mmh3(key, seed=0):
    data = key.encode("utf-8")
    n, h = len(data), seed
    c1, c2 = 0xCC9E2D51, 0x1B873593
    for i in range(0, n - n % 4, 4):
        k = int.from_bytes(data[i:i + 4], "little")
        k = (k * c1) & 0xFFFFFFFF
        k = ((k << 15) | (k >> 17)) & 0xFFFFFFFF
        h ^= (k * c2) & 0xFFFFFFFF
        h = ((h << 13) | (h >> 19)) & 0xFFFFFFFF
        h = (h * 5 + 0xE6546B64) & 0xFFFFFFFF
    k = 0
    for j, b in enumerate(data[n - n % 4:]):
        k |= b << (8 * j)
    if n % 4:
        k = (k * c1) & 0xFFFFFFFF
        k = ((k << 15) | (k >> 17)) & 0xFFFFFFFF
        h ^= (k * c2) & 0xFFFFFFFF
    h ^= n
    h ^= h >> 16
    h = (h * 0x85EBCA6B) & 0xFFFFFFFF
    h ^= h >> 13
    h = (h * 0xC2B2AE35) & 0xFFFFFFFF
    return h ^ (h >> 16)


def crypto_id(name):
    """Cryptomatte spec: MurmurHash3_32 → float32, avoiding inf/nan/denormal exponents."""
    h = _mmh3(name)
    if (h >> 23) & 0xFF in (0, 255):
        h ^= 1 << 23
    return np.frombuffer(struct.pack("<I", h), dtype=np.float32)[0]


def _header_manifest(header, layer):
    """name → id from the EXR's own Cryptomatte manifest (V-Ray/Corona write one)."""
    keys = {k.rsplit("/", 1)[0] for k in header if k.startswith("cryptomatte/")}
    for key in keys:
        if str(header.get(key + "/name", "")).split(".")[0] in (layer, layer.split(":")[-1]):
            raw = header.get(key + "/manifest")
            if raw:
                m = json.loads(raw if isinstance(raw, str) else raw.decode())
                return {n: np.frombuffer(bytes.fromhex(v)[::-1], dtype=np.float32)[0]
                        for n, v in m.items()}
    return None


class Crypto:
    """One Cryptomatte layer, split by ID in a single pass so any number of mattes can be
    cut cheaply: each ID keeps just its own pixels (flat index + coverage), sorted by ID.
    A matte then costs only the pixels it covers, not a scan of the frame."""

    def __init__(self, layers, header, crypto_layer):
        ranks = sorted(k for k in layers if re.fullmatch(re.escape(crypto_layer) + r"\d{2}", k))
        self.ok = bool(ranks)
        self.lookup = _header_manifest(header, crypto_layer) or {}
        keys, pix, cov = [], [], []
        self.h = self.w = 0
        self.top = None     # per pixel, the ID with the most coverage (rank 00's first)
        for r in ranks:
            ch = layers[r]
            for idc, cc in (("R", "G"), ("B", "A")):
                c = np.ascontiguousarray(ch[cc], dtype=np.float32)
                self.h, self.w = c.shape
                nz = np.flatnonzero(c > 0)
                ids = np.ascontiguousarray(ch[idc], dtype=np.float32).ravel()
                if self.top is None:
                    self.top = np.where(c.ravel() > 0, ids.view(np.uint32), 0).astype(np.uint32)
                keys.append(ids[nz].view(np.uint32))
                pix.append(nz)
                cov.append(c.ravel()[nz])
        k = np.concatenate(keys) if keys else np.zeros(0, np.uint32)
        order = np.argsort(k)
        self._k = k[order]
        self._pix = (np.concatenate(pix) if pix else np.zeros(0, np.int64))[order]
        self._cov = (np.concatenate(cov) if cov else np.zeros(0, np.float32))[order]

    def _parts(self, names):
        pix, cov = [], []
        for n in names:
            key = np.float32(self.lookup.get(n, crypto_id(n))).view(np.uint32)
            a, b = np.searchsorted(self._k, key, "left"), np.searchsorted(self._k, key, "right")
            if b > a:
                pix.append(self._pix[a:b])
                cov.append(self._cov[a:b])
        return pix, cov

    def cut(self, names):
        """Everything in `names` as (coverage crop float32 0–1, (x, y) of its top-left,
        share of the frame it covers), or None if none of it is in the image."""
        pix, cov = self._parts(names)
        if not pix:
            return None
        pix, cov = np.concatenate(pix), np.concatenate(cov)
        y, x = np.divmod(pix, self.w)
        x0, y0 = int(x.min()), int(y.min())
        cw, chh = int(x.max()) - x0 + 1, int(y.max()) - y0 + 1
        crop = np.bincount((y - y0) * cw + (x - x0), weights=cov, minlength=cw * chh)
        crop = np.clip(crop, 0.0, 1.0).astype(np.float32).reshape(chh, cw)
        return crop, (x0, y0), float(cov.sum()) / (self.w * self.h)

    def key(self, name):
        """The uint32 an ID name is stored as."""
        return int(np.float32(self.lookup.get(name, crypto_id(name))).view(np.uint32))

    def dominant(self, owner):
        """A full-frame uint16 map: per pixel, owner[ID] for the ID covering most of it
        (0xFFFF where nothing is, or its ID has no owner). `owner`: {uint32 ID: index}."""
        out = np.full(self.w * self.h, 0xFFFF, np.uint16)
        if self.top is None or not owner:
            return out.reshape(self.h, self.w)
        ks = np.array(sorted(owner), np.uint32)
        vs = np.array([owner[k] for k in ks], np.uint16)
        at = np.clip(np.searchsorted(ks, self.top), 0, len(ks) - 1)
        hit = (ks[at] == self.top) & (self.top != 0)
        out[hit] = vs[at[hit]]
        return out.reshape(self.h, self.w)

    def full(self, cut):
        """A cut put back into a full-frame array."""
        out = np.zeros((self.h, self.w), np.float32)
        crop, (x0, y0), _ = cut
        out[y0:y0 + crop.shape[0], x0:x0 + crop.shape[1]] = crop
        return out


def write_mask_png(path, cov):
    """8-bit greyscale PNG, no imaging library needed."""
    a = (np.clip(cov, 0, 1) * 255.0 + 0.5).astype(np.uint8)
    h, w = a.shape
    raw = np.concatenate([np.zeros((h, 1), np.uint8), a], axis=1).tobytes()   # filter 0 per row

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 0, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 6)))
        f.write(chunk(b"IEND", b""))
