-- Geometry preview from the actual Lua frame tree, not a game screenshot.
local M=dofile('tests/inspector_fixture.lua');local A=M.Load()
local f=A.UI.ItemDetails.Create(UIParent);f:SetPoint('TOPLEFT',UIParent,'TOPLEFT',20,-20);f:SetSize(360,1000)
A.UI.ItemDetails.Render(f,'Back',A.Data.items[279269]);M.Layout();A.UI.ItemDetails.Render(f,'Back',A.Data.items[279269]);M.Layout()
local dest=arg[2] or '/tmp/fwc-inspector'
local function escaped(s) return tostring(s or ''):gsub('\\','\\\\'):gsub('\t','\\t'):gsub('\n','\\n') end
local ids={};for i,node in ipairs(M.frames) do ids[node]=i end
local function export(suffix)
 local x,w=f:Bounds(true);local y,h=f:Bounds(false)
 local file=assert(io.open(dest..'-'..suffix..'.tsv','w'));file:write('ROOT\t'..x..'\t'..y..'\t'..w..'\t'..h..'\n')
 for _,node in ipairs(M.frames) do
  local p=node;local visible,within=true,false;local shift=0
  while p do
   if not p.shown then visible=false end;if p==f then within=true end
   if p.parent and p.parent.kind=='ScrollFrame' and p.parent.scrollChild==p then shift=shift+(p.parent.scrollOffset or 0) end
   p=p.parent
  end
  if visible and within then
   local nx,nw=node:Bounds(true);local ny,nh=node:Bounds(false);local color={}
   for _,v in ipairs(node.color or {}) do color[#color+1]=tostring(v) end
   local fields={ids[node],ids[node.parent] or 0,node.kind,nx,ny+shift,nw,nh,node.layer or '',node.font or '',node.text or '',node.texture or '',table.concat(color,','),node.justifyH or '',node.justifyV or ''}
   for i,v in ipairs(fields) do fields[i]=escaped(v) end;file:write(table.concat(fields,'\t')..'\n')
  end
 end
 file:close()
end
export('item')
local source=f.inspectorActive and f.inspector.source or f.source
local _,_,_,_,offset=source:GetPoint(1)
f.scroll.offset=math.max(0,-offset-4);f.scroll:UpdateRange();M.Layout();export('acquisition')
M.print('Exported inspector preview: '..dest..' (published Fel Cape; simulated equipment/bags; no WoW renderer)')
