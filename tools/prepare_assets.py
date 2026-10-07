"""Reproducible sprite cutting. The downloaded originals are never modified."""
import json, math, random, wave, struct
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'assets/sources'
ART = ROOT / 'assets/art'
ART.mkdir(exist_ok=True)

def source(name, key=None):
    im = Image.open(SOURCE / name).convert('RGBA')
    if key:
        im.putdata([(0,0,0,0) if p[:3] == key else p for p in im.getdata()])
    return im

def crop(im, name, box, trim=False):
    out = im.crop(box)
    if trim and out.getbbox():
        out = out.crop(out.getbbox())
    out.save(ART / (name+'.png'))
    return out

def walkers(name, cols, rows):
    im = source(name+'.gif' if name=='terra' else name+'.png', (0,128,128))
    out = Image.new('RGBA',(72,128))
    # Source rows: back, front, left. Output: down, left, right, up.
    for dest, sr in enumerate([1,2,2,0]):
        for frame in range(3):
            current_cols = [0,25,43,63] if name=='locke' and sr==2 else cols
            tile = im.crop((current_cols[frame],rows[sr],current_cols[frame+1],rows[sr+1]))
            tile = tile.crop(tile.getbbox())
            if dest==2:
                tile=tile.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            out.alpha_composite(tile,(frame*24+(24-tile.width)//2,dest*32+30-tile.height))
    out.save(ART/(name+'_walk.png'))
    return im

terra=walkers('terra',[0,20,38,56],[0,29,59,89])
locke=walkers('locke',[0,21,39,57],[0,31,62,94])
mog=source('mog.png',(0,128,128))
crop(mog,'mog',(0,31,22,63),True)
crop(terra,'terra_portrait',(60,169,103,213),True)
crop(locke,'locke_portrait',(48,154,91,198),True)
npcs=source('npcs.png',(0,136,255))
crop(npcs,'villager',(0,90,26,117),True)
crop(npcs,'merchant',(352,0,377,28),True)
crop(npcs,'elder',(176,178,200,207),True)
village=source('village.png')
crop(village,'village_tiles',(0,0,512,256))
crop(village,'pine',(416,160,448,208))
crop(village,'flowers',(256,48,272,64))
crop(village,'rock',(272,32,288,48))
crop(village,'lamp',(240,160,256,192),True)
crop(village,'sign',(256,64,272,80))
crop(village,'chest_closed',(256,80,272,96))
crop(village,'chest_open',(256,96,272,112))
crop(source('thamasa.png'),'town_map',(0,0,1024,784))
enemies=source('enemies.png',(255,0,255))
crop(enemies,'wolf',(33,7,81,56),True)
crop(enemies,'wasp',(49,138,97,187),True)
crop(enemies,'guardian',(113,519,211,616),True)
backgrounds=source('battle_backgrounds.png')
crop(backgrounds,'battle_forest',(768,0,1024,160))
crop(backgrounds,'battle_boss',(1024,256,1280,416))

# Original tiny utility textures for lights and shadow; not replacements for source art.
glow=Image.new('RGBA',(64,64))
for y in range(64):
    for x in range(64):
        a=max(0,1-math.hypot(x-31.5,y-31.5)/32)**2
        glow.putpixel((x,y),(255,220,139,round(a*110)))
glow.save(ART/'glow.png')
shadow=Image.new('RGBA',(20,8));ImageDraw.Draw(shadow).ellipse((0,0,19,7),fill=(6,15,20,92));shadow.save(ART/'shadow.png')
spark=Image.new('RGBA',(5,5));d=ImageDraw.Draw(spark);d.line((0,2,4,2),fill=(255,231,156));d.line((2,0,2,4),fill=(255,231,156));d.point((2,2),fill=(255,255,238));spark.save(ART/'spark.png')

# An original, quiet three-voice score and short interface effects.
audio=ROOT/'assets/audio';audio.mkdir(exist_ok=True)
rate=22050
def render(name, duration, notes):
    samples=[0.0]*int(duration*rate)
    for time, length, midi, vol, tone in notes:
        freq=440*2**((midi-69)/12)
        start=int(time*rate);count=int(length*rate)
        for k in range(min(count,len(samples)-start)):
            t=k/rate
            env=min(1,t/.018)*max(0,1-t/length)**(1.8 if tone=='bell' else .8)
            val=math.sin(2*math.pi*freq*t)
            if tone=='bell':val+=.28*math.sin(4*math.pi*freq*t)*math.exp(-t*7)
            else:val+=.17*math.sin(6*math.pi*freq*t)
            samples[start+k]+=val*env*vol
    with wave.open(str(audio/(name+'.wav')),'wb') as w:
        w.setparams((1,2,rate,0,'NONE','not compressed'))
        w.writeframes(b''.join(struct.pack('<h',int(max(-.95,min(.95,s))*32767)) for s in samples))
notes=[]
chords=[[57,60,64,69],[53,57,60,65],[60,64,67,72],[55,59,62,67]]
for bar in range(8):
    chord=chords[bar%4]
    for step in range(8):notes.append((bar*4+step*.5,.95,chord[[0,2,1,3,2,1,3,2][step]]+12,.065,'bell'))
    for note in chord[:3]:notes.append((bar*4,3.9,note-12,.033,'pad'))
render('starlight',32,notes)
notes=[]
for bar in range(8):
    chord=chords[bar%4]
    for step in range(8):notes.append((bar*2+step*.25,.28,chord[step%4],.07,'pad'))
    for step in range(4):notes.append((bar*2+step*.5,.42,chord[0]-12,.06,'pad'))
render('battle',16,notes)
render('confirm',.22,[(0,.12,81,.13,'bell'),(.08,.13,88,.1,'bell')])
render('hit',.25,[(0,.09,43,.18,'pad'),(.04,.16,38,.15,'pad')])
render('magic',.75,[(i*.07,.27,69+i*3,.09,'bell') for i in range(7)])
render('heal',.7,[(i*.12,.3,n,.1,'bell') for i,n in enumerate([72,76,79,84])])
render('victory',1.9,[(i*.16,.4,n,.1,'bell') for i,n in enumerate([72,72,72,79,77,79,84,83,84])])

# Preserve exact provenance of all downloaded sheets.
extra=[('Locke Cole','locke.png',6666,6,1755472428,'Unknown, daemoth, Mister Ton'),('Mog','mog.png',6680,6,1755472428,'Unknown, daemoth, Mister Ton'),('Phantom Forest','forest.png',541462,522,1775560421,'See source page'),('Enemies (World of Balance)','enemies.png',54613,51,1775839986,'See source page'),('Battle Backgrounds (USA)','battle_backgrounds.png',54685,52,1775918240,'daemoth, Gravrain'),('Icons, Font, & Menu','menu.png',54693,52,1755473108,'See source page'),('NPCs (Male)','npcs.png',54688,52,1755473108,'See source page'),('Thamasa (Exterior)','thamasa.png',64309,61,1755473488,'See source page')]
manifest=json.loads((SOURCE/'manifest.json').read_text())[:2]
for name,file,ident,group,date,credits in extra:
    manifest.append(dict(name=name,file=file,page=f'https://www.spriters-resource.com/snes/ff6/asset/{ident}/',image_url=f'https://www.spriters-resource.com/media/assets/{group}/{ident}.png?updated={date}',contributors=credits))
(SOURCE/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
print('Prepared',len(list(ART.glob('*.png'))),'art assets and',len(list(audio.glob('*.wav'))),'audio assets.')
