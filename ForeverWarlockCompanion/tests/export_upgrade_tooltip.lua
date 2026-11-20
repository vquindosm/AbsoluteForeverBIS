-- Before/after geometry from the same published item and synthetic player.
local M=dofile('tests/inspector_fixture.lua');local F=dofile('tests/tooltip_fixture.lua')
local tip=F.Attach(GameTooltip,'GameTooltip',{'|cffa335eeFel Cape|r','Item Level 65','Binds when equipped','Back · Cloth','50 Armor','+16 Stamina','+15 Shadow Damage','+14 Critical Strike','Requires Level 60'})
tip:SetPoint('TOPLEFT',UIParent,'TOPLEFT',30,-30)
local bg=tip:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(tip);bg:SetColorTexture(.025,.025,.045,.98)
local postcall
tip.HasScript=function(_,event) return event~='OnTooltipSetItem' or M.scenario=='legacy' end
tip.HookScript=function(self,event,fn) local old=self:GetScript(event);self:SetScript(event,function(...) if old then old(...) end;fn(...) end) end
tip.GetItem=function(self) return 'Fel Cape',self.link end
tip.SetHyperlink=function(self,link)
 local clear=self:GetScript('OnTooltipCleared');if clear then clear(self) end
 self:PaintNative(link)
 if postcall then postcall(self) elseif self:GetScript('OnTooltipSetItem') then self:GetScript('OnTooltipSetItem')(self) end
 self:Show()
end
if M.scenario~='legacy' then Enum.TooltipDataType={Item=1};TooltipDataProcessor={AddTooltipPostCall=function(_,fn) postcall=fn end} end
GetBuildInfo=function() return '1.60.1','70959','Nov 19 2026',16001 end
local A=M.Load();local p=A.Services.Persistence.Profile()
p.epWeights={ITEM_MOD_STAMINA_SHORT=.2,ITEM_MOD_DAMAGE_SHADOW_SHORT=1,ITEM_MOD_CRIT_RATING_SHORT=.4,ITEM_MOD_DAMAGE_FROST_SHORT=.5}
tip:SetHyperlink(M.cape)
if not A.UI.UpgradeTooltip then
 -- Approximate the old engine's AddLine multiline reflow, which the generic
 -- frame double does not perform. Never use this for the new overlay layout.
 local y=10
 for n=1,tip.lines do
  local font=_G['GameTooltipTextLeft'..n];local h=math.max(16,font:GetStringHeight())
  font:ClearAllPoints();font:SetPoint('TOPLEFT',tip,'TOPLEFT',10,-y);font:SetHeight(h);y=y+h+2
 end
 tip:SetHeight(y+10)
end
local dest=arg[2] or '/tmp/fwc-tooltip'
local function escape(s) return tostring(s or ''):gsub('\\','\\\\'):gsub('\t','\\t'):gsub('\n','\\n') end
local ids={};for n,node in ipairs(M.frames) do ids[node]=n end
local x,w=tip:Bounds(true);local y,h=tip:Bounds(false)
local file=assert(io.open(dest..'.tsv','w'));file:write('ROOT\t'..x..'\t'..y..'\t'..w..'\t'..h..'\n')
for _,node in ipairs(M.frames) do
 local parent=node;local shown,inside=true,false
 while parent do if not parent.shown then shown=false end;if parent==tip then inside=true end;parent=parent.parent end
 if shown and inside then
  local fx,fw=node:Bounds(true);local fy,fh=node:Bounds(false);local color={}
  for _,v in ipairs(node.color or {}) do color[#color+1]=v end
  local fields={ids[node],ids[node.parent] or 0,node.kind,fx,fy,fw,fh,node.layer or '',node.font or '',node.text or '',node.texture or '',table.concat(color,','),node.justifyH or '',node.justifyV or ''}
  for n,v in ipairs(fields) do fields[n]=escape(v) end;file:write(table.concat(fields,'\t')..'\n')
 end
end
file:close();M.print('Exported simulated tooltip: '..dest)
