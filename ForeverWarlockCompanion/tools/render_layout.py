"""Render a MOCK-API geometry inspection, never a WoW screenshot.
Usage: python3 tools/render_layout.py /tmp/fwc-before /tmp/fwc-after docs/validation
Requires Pillow; native icons, fonts and models are deliberately not reproduced.
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import sys, re, math
REG='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
ROOT=Path(__file__).resolve().parents[1]
def font(size,bold=False): return ImageFont.truetype(BOLD if bold else REG,size)
def parse(path):
 lines=Path(path).read_text().splitlines();_,rx,ry,rw,rh=lines[0].split('\t');root=list(map(float,(rx,ry,rw,rh)));nodes={};children={}
 for line in lines[1:]:
  cols=line.split('\t');cols += ['']*(14-len(cols))
  i,p,kind,x,y,w,h,layer,fn,text,tex,color,jh,jv=cols
  unescape=lambda t:t.replace('\\n','\n').replace('\\t','\t').replace('\\\\','\\')
  node=dict(i=int(i),p=int(p),kind=kind,x=float(x),y=float(y),w=float(w),h=float(h),layer=layer,font=fn,text=unescape(text),tex=tex,color=color,jh=jh,jv=jv)
  nodes[node['i']]=node;children.setdefault(node['p'],[]).append(node)
 return root,nodes,children

def render(path):
 (rx,ry,rw,rh),nodes,children=parse(path);canvas=Image.new('RGBA',(round(rw),round(rh)),(10,10,16,255))
 def rect(n):return (round(n['x']-rx),round(ry+rh-n['y']-n['h']),round(n['x']-rx+n['w']),round(ry+rh-n['y']))
 def intersect(a,b):return (max(a[0],b[0]),max(a[1],b[1]),min(a[2],b[2]),min(a[3],b[3]))
 def draw_region(n,clip):
  if n['layer']=='HIGHLIGHT': return
  x,y,r,b=rect(n);w,h=r-x,b-y
  if w<=0 or h<=0:return
  layer=Image.new('RGBA',canvas.size);d=ImageDraw.Draw(layer)
  if n['kind']=='Texture':
   if n['color']:
    c=tuple(round(float(v)*255) for v in n['color'].split(','));d.rectangle((x,y,r-1,b-1),fill=c)
   elif n['tex']:
    name=n['tex'].split('\\')[-1];asset=ROOT/'Media'/(name+'.tga')
    if asset.exists():
     im=Image.open(asset).convert('RGBA')
     if name=='DarkStone':
      for xx in range(x,r,im.width):
       for yy in range(y,b,im.height):layer.paste(im,(xx,yy),im)
      # tile strictly within this region
      crop=layer.crop((x,y,r,b));layer=Image.new('RGBA',canvas.size);layer.paste(crop,(x,y))
     else: im=im.resize((w,h));layer.paste(im,(x,y),im)
    elif w>8 and h>8:
     d.rectangle((x,y,r-1,b-1),fill=(40,25,54,255),outline=(130,96,46,255));d.text((x+w/2,y+h/2),'◇',font=font(min(20,max(8,h//2))),anchor='mm',fill=(208,168,83,255))
  elif n['kind']=='FontString' and n['text']:
   match=re.search(r'\|c([0-9a-fA-F]{8})',n['text']);color=('#'+match[1][2:]) if match else ('#e2bf70' if n['font'].startswith('GameFontNormal') else '#dddce2')
   text=re.sub(r'\|c[0-9a-fA-F]{8}|\|r','',n['text']);size=19 if 'Large' in n['font'] else 13 if n['font']=='GameFontNormal' else 11
   ft=font(size,'Normal' in n['font']);lines=[]
   for original in text.split('\n'):
    words=original.split();line=''
    for word in words:
     trial=(line+' '+word).strip()
     if line and d.textlength(trial,font=ft)>w: lines.append(line);line=word
     else:line=trial
    lines.append(line)
   lh=16 if 'Normal' in n['font'] else 13;yy=y+(max(0,h-len(lines)*lh)//2 if n['jv']=='MIDDLE' else 0)
   for line in lines:
    xx=x+(max(0,w-d.textlength(line,font=ft))/2 if n['jh']=='CENTER' else 0)
    d.text((xx,yy),line,font=ft,fill=color);yy+=lh
   clip=intersect(clip,(x,y,r,b))
  elif n['kind'] in ('DressUpModel','PlayerModel'):
   d.rounded_rectangle((x+10,y+10,r-10,b-10),radius=16,fill=(26,21,36,255),outline=(80,62,98,255),width=2)
   d.text((x+w/2,y+h/2),'MODELO 3D NATIVO\nRequiere cliente WoW',font=font(16),anchor='mm',align='center',fill=(162,143,180,255))
  else:return
  crop=intersect(clip,(0,0,canvas.width,canvas.height))
  if crop[2]>crop[0] and crop[3]>crop[1]:canvas.alpha_composite(layer.crop(crop),(crop[0],crop[1]))
 def walk(n,clip):
  draw_region(n,clip)
  child=children.get(n['i'],[])
  regions=[c for c in child if c['kind'] in ('Texture','FontString')];frames=[c for c in child if c not in regions]
  levels={'BACKGROUND':0,'BORDER':1,'ARTWORK':2,'OVERLAY':3,'HIGHLIGHT':4}
  for c in sorted(regions,key=lambda c:levels.get(c['layer'],0)):draw_region(c,clip)
  if n['kind']=='ScrollFrame':clip=intersect(clip,rect(n))
  for c in frames:walk(c,clip)
 root=next(n for n in nodes.values() if n['p'] not in nodes);walk(root,(0,0,canvas.width,canvas.height));return canvas.convert('RGB')

def main(before,after,dest):
 dest=Path(dest);dest.mkdir(parents=True,exist_ok=True)
 for screen in ('dashboard','equipment','item','objectives'):
  old=render(before+'-'+screen+'.tsv');new=render(after+'-'+screen+'.tsv');w=1100;h=round(old.height*w/old.width)
  board=Image.new('RGB',(w*2,h+120),(13,14,21));d=ImageDraw.Draw(board)
  d.text((22,10),'PRUEBA DE DISTRIBUCIÓN · API SIMULADA · NO ES UNA CAPTURA DE WOW',font=font(20,True),fill='#e8c878')
  d.text((22,42),'Datos de prueba. Iconos, fuentes y modelo 3D reales pendientes de validación en el cliente.',font=font(16),fill='#c2c4d0')
  for i,(im,label) in enumerate(((old,'ANTES · 3.2'),(new,'DESPUÉS · 3.3 · '+screen.upper()))):
   d.text((i*w+22,77),label,font=font(20,True),fill='#eee7d6');board.paste(im.resize((w,h),Image.Resampling.LANCZOS),(i*w,112))
  board.save(dest/(screen+'-comparison.png'))
if __name__=='__main__': main(*sys.argv[1:])
