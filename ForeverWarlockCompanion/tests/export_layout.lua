-- Geometry inspection only: this emits no game screenshot and uses fixture APIs.
local M=dofile('tests/wow_mock.lua')
ForeverWarlockCompanionDB={viewClass='WARLOCK',spec='Affliction',mode='Pre-BiS',window={width=1700,height=1040},professions={'Tailoring','Enchanting'}}
for line in io.lines('ForeverWarlockCompanion.toc') do if line:match('%.lua$') then dofile((line:gsub('\\','/'))) end end
M.Event('ADDON_LOADED','ForeverWarlockCompanion');SlashCmdList.FWC('')
local A=FWC
A.Services.Objectives.Track(22267,'Head');A.Services.Objectives.Track(14111,'Head');A.Services.Objectives.Track(18691,'Neck');A.Services.Objectives.Track(14153,'Chest')
local ids={};for i,f in ipairs(M.frames) do ids[f]=i end
local function escaped(s) return tostring(s or ''):gsub('\\','\\\\'):gsub('\t','\\t'):gsub('\n','\\n') end
local dest=arg[2] or '/tmp/fwc-layout';local routes={{'Dashboard','dashboard'},{'Character & Gear','equipment'},{A.UI.window.panels['Item Details'] and 'Item Details' or 'Item Explorer','item'},{'Progression','objectives'},{'Item Explorer','explorer'}}
for _,route in ipairs(routes) do
 A.UI.SetTab(route[1],{slot='Head',itemId=22267});M.Layout();for i,f in ipairs(M.frames) do ids[f]=i end
 local root=A.UI.window;local x,w=root:Bounds(true);local y,h=root:Bounds(false)
 local file=assert(io.open(dest..'-'..route[2]..'.tsv','w'));file:write('ROOT\t'..x..'\t'..y..'\t'..w..'\t'..h..'\n')
 for _,f in ipairs(M.frames) do
  local p=f;local visible,inside=true,false
  while p do if not p.shown then visible=false end;if p==root then inside=true end;p=p.parent end
  if visible and inside then
   local fx,fw=f:Bounds(true);local fy,fh=f:Bounds(false);local color={};for _,v in ipairs(f.color or {}) do color[#color+1]=tostring(v) end
   local data={ids[f],ids[f.parent] or 0,f.kind,fx,fy,fw,fh,f.layer or '',f.font or '',f.text or '',f.texture or '',table.concat(color,','),f.justifyH or '',f.justifyV or ''}
   for i,v in ipairs(data) do data[i]=escaped(v) end;file:write(table.concat(data,'\t')..'\n')
  end
 end;file:close()
end
M.print('Exported mock geometry: '..dest)
