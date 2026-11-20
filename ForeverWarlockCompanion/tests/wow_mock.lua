-- Strict native-frame test double. This does not render WoW or prove engine support.
local M={frames={},timers={},logs={},equipped={[1]=22267},bags={[0]={{id=14256,count=3},{id=18727,count=1}}},now=1794950000,combat=false,scenario=arg[1] or 'modern'}
M.epoch=0
local function dirty() M.epoch=M.epoch+1 end
local Methods={};local mt={__index=Methods}
local function frame(kind,parent)
 local f=setmetatable({kind=kind,parent=parent,points={},scripts={},shown=true,events={},text='',value=0},mt)
 M.frames[#M.frames+1]=f;return f
end
function Methods:SetPoint(point,a,b,c,d)
 dirty()
 local relative,relativePoint,x,y
 if type(a)=='table' then relative=a;relativePoint=b or point;x=c or 0;y=d or 0
 else relative=self.parent or UIParent;relativePoint=point;x=a or 0;y=b or 0 end
 self.points[#self.points+1]={point,relative,relativePoint,x,y}
end
function Methods:GetPoint(index) return unpack(self.points[index or 1] or {'CENTER',self.parent,'CENTER',0,0}) end
function Methods:GetNumPoints() return #self.points end
function Methods:ClearAllPoints() dirty();self.points={} end
function Methods:SetAllPoints(relative) self:ClearAllPoints();self:SetPoint('TOPLEFT',relative or self.parent,'TOPLEFT');self:SetPoint('BOTTOMRIGHT',relative or self.parent,'BOTTOMRIGHT') end
local anchors={LEFT=0,RIGHT=1,TOP=1,BOTTOM=0,CENTER=.5}
local function fraction(point,horizontal)
 if horizontal then if point:find('LEFT') then return 0 elseif point:find('RIGHT') then return 1 else return .5 end
 else if point:find('BOTTOM') then return 0 elseif point:find('TOP') then return 1 else return .5 end end
end
function Methods:Bounds(horizontal,depth)
 local cacheKey=horizontal and 'hcache' or 'vcache'
 local cached=self[cacheKey]
 if cached and cached.epoch==M.epoch then return cached.start,cached.size end
 depth=(depth or 0)+1;assert(depth<30,'circular frame anchors')
 local explicit;if horizontal then explicit=self.width else explicit=self.height end
 local coords={}
 for _,p in ipairs(self.points) do
  local start,size=p[2]:Bounds(horizontal,depth)
  coords[#coords+1]={f=fraction(p[1],horizontal),v=start+fraction(p[3],horizontal)*size+(horizontal and p[4] or p[5])}
  if explicit then break end
 end
 if not explicit then
  for i=1,#coords do for j=i+1,#coords do
   if coords[i].f~=coords[j].f then explicit=(coords[j].v-coords[i].v)/(coords[j].f-coords[i].f);break end
  end;if explicit then break end end
 end
 if not explicit then
  if self.kind=='FontString' then explicit=horizontal and (#self.text*6) or self:GetStringHeight() else explicit=1 end
 end
 local start=coords[1] and coords[1].v-coords[1].f*explicit or 0
 self[cacheKey]={epoch=M.epoch,start=start,size=explicit}
 return start,explicit
end
function Methods:GetWidth() local _,size=self:Bounds(true);return size end
function Methods:GetHeight() local _,size=self:Bounds(false);return size end
function Methods:SetWidth(value) if self.width~=value then dirty();self.width=value end end
function Methods:SetHeight(value) if self.height~=value then dirty();self.height=value end end
function Methods:SetSize(width,height) self:SetWidth(width);self:SetHeight(height) end
function Methods:GetCenter() local x,w=self:Bounds(true);local y,h=self:Bounds(false);return x+w/2,y+h/2 end
function Methods:SetScript(name,fn) self.scripts[name]=fn end
function Methods:GetScript(name) return self.scripts[name] end
function Methods:Show() local old=self.shown;self.shown=true;if not old and self.scripts.OnShow then self.scripts.OnShow(self) end end
function Methods:Hide() local old=self.shown;self.shown=false;if old and self.scripts.OnHide then self.scripts.OnHide(self) end end
function Methods:SetShown(value) if value then self:Show() else self:Hide() end end
function Methods:IsShown() return self.shown end
function Methods:SetEnabled(value) self.enabled=value end
function Methods:IsEnabled() return self.enabled~=false end
function Methods:Click() if self.enabled~=false and self.scripts.OnClick then self.scripts.OnClick(self) end end
function Methods:SetText(value) value=tostring(value or '');if self.text~=value then dirty();self.text=value end;if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end end
function Methods:GetText() return self.text end
function Methods:GetStringHeight()
 local width=self:GetWidth();local lines=0
 for line in (self.text..'\n'):gmatch('(.-)\n') do
  line=line:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
  lines=lines+math.max(1,math.ceil(#line*6/math.max(20,width)))
 end
 return lines*13
end
function Methods:CreateTexture(_,layer) local t=frame('Texture',self);t.layer=layer;return t end
function Methods:CreateFontString(_,layer,font) local t=frame('FontString',self);t.layer=layer;t.font=font;return t end
function Methods:SetColorTexture(...) self.color={...} end
function Methods:SetTexture(value) self.texture=value end
function Methods:SetTexCoord(...) self.texCoord={...} end
function Methods:SetOrientation(value) self.orientation=value end
function Methods:SetMinMaxValues(min,max) self.min=min;self.max=max end
function Methods:SetValue(value) self.value=value;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end end
function Methods:GetValue() return self.value end
function Methods:SetThumbTexture(path) self.thumb=frame('Texture',self);self.thumb.texture=path end
function Methods:GetThumbTexture() return self.thumb end
function Methods:SetScrollChild(child) self.scrollChild=child;child:SetPoint('TOPLEFT',self,'TOPLEFT') end
function Methods:SetVerticalScroll(value) self.scrollOffset=value end
function Methods:RegisterEvent(event) self.events[event]=true end
function Methods:SetUnit(unit) self.unit=unit;M.setUnits=(M.setUnits or 0)+1 end
function Methods:Dress() M.dresses=(M.dresses or 0)+1 end
function Methods:TryOn(link,hand) M.tryOns=(M.tryOns or 0)+1;M.lastTry={link,hand};if M.rejectPreview then return 3 end;return 0 end
function Methods:SetRotation(value) self.rotation=value end
function Methods:SetFacing(value) self.rotation=value end
function Methods:SetPortraitZoom(value) self.zoom=value end
function Methods:SetOwner(owner) self.owner=owner end
function Methods:SetHyperlink(link) self.link=link end
function Methods:SetScale(scale) self.scale=scale end
function Methods:GetScale() return self.scale or 1 end
function Methods:GetEffectiveScale() return self:GetScale() end
function Methods:SetJustifyH(v) self.justifyH=v end
function Methods:SetJustifyV(v) self.justifyV=v end
local noops={'SetFontObject','SetWordWrap','SetMaxLines','EnableMouse','EnableMouseWheel','SetFrameStrata','SetMovable','SetResizable','SetClampedToScreen','RegisterForDrag','StartMoving','StopMovingOrSizing','StartSizing','SetResizeBounds','SetMinResize','SetValueStep','SetAutoFocus','SetTextInsets','ClearFocus','SetFocus','HighlightText'}
for _,name in ipairs(noops) do Methods[name]=function() end end
UIParent=frame('Frame');UIParent:SetSize(1920,1080)
function CreateFrame(kind,_,parent,template)
 assert(not template,'unexpected dependency on a native template: '..tostring(template))
 if M.scenario=='no-model' and (kind=='DressUpModel' or kind=='PlayerModel') then error('unsupported model type') end
 if M.scenario=='player-model' and kind=='DressUpModel' then error('unsupported DressUpModel') end
 local f=frame(kind,parent or UIParent)
 if kind=='PlayerModel' then f.TryOn=false end
 return f
end
GameTooltip=frame('GameTooltip',UIParent)
SlashCmdList={};time=function(t) return t and os.time(t) or M.now end;date=function(fmt,t) return os.date(fmt,t or M.now) end
GetBuildInfo=function() return '1.60.1','70790','Nov 3 2026',16001 end
UnitClass=function() return 'Warlock','WARLOCK' end
UnitName=function() return 'Test Warlock' end
UnitLevel=function() return 60 end
GetCursorPosition=function() return 100,100 end
GetLocale=function() return 'enUS' end
InCombatLockdown=function() return M.combat end
canaccessvalue=function(value) return value~='SECRET' end
Enum={ItemTryOnReason={Success=0},BagIndex={ReagentBag=5}}
C_Timer={After=function(_,callback) M.timers[#M.timers+1]=callback end}
function M.Flush() local queue=M.timers;M.timers={};for _,fn in ipairs(queue) do fn() end end
GetInventoryItemID=function(_,slot) return M.equipped[slot] end
GetInventoryItemLink=function(_,slot) return M.equipped[slot] and ('item:'..M.equipped[slot]) end
local function itemInfo(value)
 local id=type(value)=='number' and value or tonumber(tostring(value):match('item:(%d+)'))
 if value=='Felcloth' then id=14256 end
 local item=FWC and FWC.Data.items and FWC.Data.items[id]
 if not item and id~=14256 then return end
 return id==14256 and 'Felcloth' or item.name,'item:'..id,item and item.quality or 1,60,1,'Armor','Cloth',1,'INVTYPE_HEAD',item and item.icon or 123
end
C_Item={GetItemInfo=itemInfo,RequestLoadItemDataByID=function() end,GetItemStats=function(link) return {ITEM_MOD_INTELLECT_SHORT=link=='item:22267' and 10 or 15} end}
C_Container={
 GetContainerNumSlots=function(bag) M.bagReads=(M.bagReads or 0)+1;return #(M.bags[bag] or {}) end,
 GetContainerItemInfo=function(bag,slot)
  if M.bagError then error('bag locked/unreadable') end
  local entry=M.bags[bag] and M.bags[bag][slot]
  return entry and {itemID=entry.id,stackCount=entry.count,hyperlink='item:'..entry.id}
 end,
}
GetProfessions=function() return 1,2 end
GetProfessionInfo=function(index) if index==1 then return 'Tailoring',1,300,300,1,1,197 else return 'Enchanting',1,300,300,1,1,333 end end
GetNumSpecializations=function() return 3 end
C_SpecializationInfo={
 GetSpecialization=function() return 1 end,
 GetSpecializationInfo=function(index) return index,({'Affliction','Demonology','Destruction'})[index] end,
 GetTalentInfo=function(query)
  if query.talentIndex==1 then return {talentID=100+query.specializationIndex,name='Live test talent',rank=2,maxRank=5,spellID=123} end
 end,
}
local realPrint=print
print=function(...) local words={...};for i,v in ipairs(words) do words[i]=tostring(v) end;M.logs[#M.logs+1]=table.concat(words,' ') end
M.print=realPrint
if M.scenario=='legacy' then
 GetItemInfo=C_Item.GetItemInfo;GetItemStats=C_Item.GetItemStats;C_Item=nil
 GetContainerNumSlots=C_Container.GetContainerNumSlots
 GetContainerItemInfo=function(bag,slot) local item=M.bags[bag] and M.bags[bag][slot];return 1,item and item.count end
 GetContainerItemLink=function(bag,slot) local item=M.bags[bag] and M.bags[bag][slot];return item and ('item:'..item.id) end
 C_Container=nil;C_SpecializationInfo=nil;C_Timer=nil
end
function M.Layout()
 for pass=1,8 do
  local n=#M.frames
  for i=1,n do local f=M.frames[i];local w,h=f:GetWidth(),f:GetHeight()
   if f.lastWidth~=w or f.lastHeight~=h then f.lastWidth=w;f.lastHeight=h;if f.scripts.OnSizeChanged then f.scripts.OnSizeChanged(f,w,h) end end
  end
 end
end
function M.Event(event,...)
 local fn=FWC.eventFrame.scripts.OnEvent;fn(FWC.eventFrame,event,...)
end
function M.Advance()
 if C_Timer then M.Flush() else local fn=FWC.eventFrame.scripts.OnUpdate;if fn then fn(FWC.eventFrame,.2) end end
end
return M
