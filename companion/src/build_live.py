"""Builds live_scroll.c into ..\\live_scroll.json for Apply-CompanionPatches.ps1.

Needs the MSVC x86 compiler (Visual Studio Build Tools); nothing else. The
object file is linked here into one position-independent blob:

    [entry stubs][.text][.rdata][.data][.bss]

"relocs" are the offsets of 32-bit absolute addresses inside the blob (the
patcher adds the blob's address), "calls" the rel32 fields that call into the
program (the patcher writes target - next instruction). Run:

    python build_live.py            # writes ..\\live_scroll.json, leaves no other file
"""
import glob, json, os, struct, subprocess, sys, tempfile, hashlib

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'live_scroll.c')
OUT = os.path.join(os.path.dirname(HERE), 'live_scroll.json')

# the program, 0.1.37
UPLOAD = 0x601ee680
HELD = 0x60b444b0
DRAG_BUTTON = 0x60b44468
SITES = [   # va, original bytes, stub, bytes after the call
    (0x601e9f50, 'e82b470000', 'frame', ''),                                   # render_main: upload(t, now)
    (0x601de213, 'c704b5b044b46000000000', 'key', '660f1f440000'),             # camera_input_pan_key: g_held[k] = 0
    (0x601decee, 'c704b5b044b46000000000', 'key', '660f1f440000'),             # camera_input_event, key up
    (0x601def17, 'c7056844b46000000000', 'button', '0f1f440000'),              # camera_input_event, drag button up
]
# bytes the patcher checks before it installs anything: va -> hex (functions the blob calls or reads the layout of)
SIGNATURE = {
    0x601ee680: '5589e553575683e4f083ec60f20f11442408',                         # upload
    0x601ef0f0: '8b442404f20f10a1103a0400',                                     # slide_offset: off_dur at Rt+0x43a10
    0x601e24d0: None, 0x601e2bdc: None, 0x601e2afb: None, 0x601e29f2: None,     # filled from the program by --sign
    0x601de978: None, 0x60001cc0: 'e91b510100', 0x601df828: None,
    0x601ea2da: '83bef83a040000',                                               # render_main: t->zon
    0x601f6150: 'a1d466e2603b058467e2600f84',                                   # take(): g_pending.serial against R.serial
    0x601f6177: '393dd866e260',                                                 # take(): g_pending.frame against shown
}


def find_cl():
    pats = [r'C:\Program Files (x86)\Microsoft Visual Studio\*\*\VC\Tools\MSVC\*\bin\Hostx64\x86\cl.exe',
            r'C:\Program Files\Microsoft Visual Studio\*\*\VC\Tools\MSVC\*\bin\Hostx64\x86\cl.exe']
    for p in pats:
        hits = sorted(glob.glob(p))
        if hits: return hits[-1]
    sys.exit('MSVC x86 compiler (cl.exe) not found')


def compile_obj(tmp):
    obj = os.path.join(tmp, 'live_scroll.obj')
    cmd = [find_cl(), '/nologo', '/c', '/O2', '/Oi', '/GS-', '/Gd', '/arch:SSE2', '/fp:precise', '/Zl', '/W3', '/Fo' + obj, SRC]
    r = subprocess.run(cmd, cwd=tmp, capture_output=True, text=True)
    if r.returncode or 'warning' in r.stdout: print(r.stdout, r.stderr)
    if r.returncode: sys.exit('compile failed')
    return open(obj, 'rb').read()


def link(o):
    machine, nsec, _, symoff, nsym, opt, _ = struct.unpack_from('<HHIIIHH', o, 0)
    assert machine == 0x14c and opt == 0
    strtab = symoff + nsym * 18

    def name_of(raw):
        if raw[:4] == b'\0\0\0\0':
            off = struct.unpack('<I', raw[4:])[0]
            return o[strtab + off:o.index(b'\0', strtab + off)].decode()
        return raw.rstrip(b'\0').decode()

    secs = []
    for i in range(nsec):
        h = o[20 + i * 40:60 + i * 40]
        raw, _, _, size, ptr, relptr, _, nrel, _, ch = struct.unpack('<8sIIIIIIHHI', h)
        nm = raw.rstrip(b'\0').decode()
        secs.append(dict(name=nm, size=size, ptr=ptr, relptr=relptr, nrel=nrel, ch=ch, off=None))
    syms = []; i = 0
    while i < nsym:
        raw, value, sec, typ, cls, naux = struct.unpack_from('<8sIhHBB', o, symoff + i * 18)
        syms.append(dict(name=name_of(raw), value=value, sec=sec, cls=cls))
        syms.extend([None] * naux); i += 1 + naux

    def kind(s):
        if s['ch'] & 0x800 or s['name'].startswith('.debug') or s['name'] in ('.drectve', '.chks64', '.llvm_addrsig'): return None   # removed / info
        if s['ch'] & 0x20: return 0            # code
        if s['ch'] & 0x80: return 3            # bss
        if s['ch'] & 0x80000000: return 2      # writable data
        return 1                               # read-only data

    # entry stubs first
    blob = bytearray(); calls = []; entries = {}; pending = []   # pending: (offset of rel32, symbol)

    def emit(h): blob.extend(bytes.fromhex(h))

    def call_sym(sym): emit('e8'); pending.append((len(blob), sym)); emit('00000000')

    def call_abs(va): emit('e8'); calls.append([len(blob), va]); emit('00000000')

    entries['frame'] = len(blob)   # in place of call upload: ecx = t, xmm0 = now; ls_frame calls upload itself
    emit('51'); emit('83ec08'); emit('f20f110424'); call_sym('_ls_frame'); emit('83c40c'); emit('c3')
    while len(blob) % 16: emit('cc')
    entries['key'] = len(blob)     # in place of mov dword [esi*4 + g_held], 0
    emit('60'); call_sym('_ls_adopt'); emit('61'); emit('c704b5' + struct.pack('<I', HELD).hex() + '00000000'); emit('c3')
    while len(blob) % 16: emit('cc')
    entries['button'] = len(blob)  # in place of mov dword [g_drag.button], 0
    emit('60'); call_sym('_ls_adopt'); emit('61'); emit('c705' + struct.pack('<I', DRAG_BUTTON).hex() + '00000000'); emit('c3')

    for k in (0, 1, 2, 3):
        for s in secs:
            if kind(s) != k: continue
            align = 1 << (((s['ch'] >> 20) & 0xf) - 1) if (s['ch'] >> 20) & 0xf else 16
            while len(blob) % max(align, 4): blob.append(0xCC if k == 0 else 0)
            s['off'] = len(blob)
            blob.extend(o[s['ptr']:s['ptr'] + s['size']] if k != 3 and s['ptr'] else bytes(s['size']))

    def sym_off(sy):
        if sy['sec'] <= 0: sys.exit('undefined symbol %s (the blob has no C runtime)' % sy['name'])
        s = secs[sy['sec'] - 1]
        if s['off'] is None: sys.exit('symbol %s in dropped section %s' % (sy['name'], s['name']))
        return s['off'] + sy['value']

    by_name = {s['name']: s for s in syms if s and s['cls'] == 2 and s['sec'] > 0}
    relocs = []
    for s in secs:
        if s['off'] is None: continue
        for r in range(s['nrel']):
            va, si, typ = struct.unpack_from('<IIH', o, s['relptr'] + r * 10)
            loc = s['off'] + va; target = sym_off(syms[si]); add = struct.unpack_from('<i', blob, loc)[0]
            if typ == 6: struct.pack_into('<i', blob, loc, target + add); relocs.append(loc)           # DIR32
            elif typ == 0x14: struct.pack_into('<i', blob, loc, target + add - (loc + 4))              # REL32
            else: sys.exit('relocation type %#x in %s' % (typ, s['name']))
    for loc, name in pending:
        struct.pack_into('<i', blob, loc, sym_off(by_name[name]) - (loc + 4))
    entries['state'] = sym_off(by_name['_ls_state'])
    st = entries['state']   # the fields the patcher and the tests address by offset
    assert struct.unpack_from('<I', blob, st)[0] == 0x3143534c and struct.unpack_from('<i', blob, st + 0x58)[0] == 800 \
        and struct.unpack_from('<i', blob, st + 0x74)[0] == 12, 'ls_state layout changed'
    while len(blob) % 16: blob.append(0)
    return blob, sorted(relocs), calls, entries


def main():
    with tempfile.TemporaryDirectory() as tmp:
        blob, relocs, calls, entries = link(compile_obj(tmp))
    sig = dict(SIGNATURE)
    exe = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Programs', 'SimGolf Remastered', 'Sim Golf Remastered.exe.companion-backup')
    if any(v is None for v in sig.values()):
        if not os.path.exists(exe): sys.exit('the stock program (%s) is needed once to take the signature bytes' % exe)
        import pefile
        pe = pefile.PE(exe, fast_load=True)
        for va, v in sig.items():
            if v is None: sig[va] = pe.get_data(va - pe.OPTIONAL_HEADER.ImageBase, 12).hex()
    out = dict(version='0.1.37', size=len(blob), sha1=hashlib.sha1(bytes(blob)).hexdigest(), hex=bytes(blob).hex(), relocs=relocs, calls=calls,
               entries=entries, fields=dict(enabled=4, hold_ms=0x58, lead_pct=0x74, sync_on=0x7c), sites=[dict(va=va, original=orig, stub=stub, pad=pad) for va, orig, stub, pad in SITES],
               signature=[dict(va=va, hex=h) for va, h in sorted(sig.items())])
    with open(OUT, 'w', newline='\n') as f: json.dump(out, f, indent=1); f.write('\n')
    print('live_scroll.json: %d bytes, %d relocs, %d calls, entries %s' % (len(blob), len(relocs), len(calls), {k: hex(v) for k, v in entries.items()}))


if __name__ == '__main__':
    main()
