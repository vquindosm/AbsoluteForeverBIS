-- Published Fel Cape position; synthetic equipment, weights, API and layout.
local M=dofile('tests/inspector_fixture.lua');local F=dofile('tests/tooltip_fixture.lua')
local tip=F.Attach(GameTooltip,'GameTooltip',{'|cffa335eeFel Cape|r','Item Level 65','Binds when equipped','Back','50 Armor','+16 Stamina','Requires Level 60','Equip: +15 Shadow damage','Equip: +14 Crit'})
local postcall;local originalCalls=0
tip.HasScript=function(_,event) return event~='OnTooltipSetItem' or M.scenario=='legacy' end
tip.HookScript=function(self,event,fn) local old=self:GetScript(event);self:SetScript(event,function(...) if old then old(...) end;fn(...) end) end
tip.GetItem=function(self) return 'control',self.link end
tip.SetHyperlink=function(self,link)
 local clear=self:GetScript('OnTooltipCleared');if clear then clear(self) end
 self:PaintNative(link)
 if postcall then postcall(self) elseif self:GetScript('OnTooltipSetItem') then self:GetScript('OnTooltipSetItem')(self) end
 self:Show()
end
tip:SetScript('OnTooltipSetItem',function() originalCalls=originalCalls+1 end)
if M.scenario~='legacy' then Enum.TooltipDataType={Item=1};TooltipDataProcessor={AddTooltipPostCall=function(_,fn) postcall=fn end} end
GetBuildInfo=function() return '1.60.1','70959','Nov 19 2026',16001 end
local A=M.Load();local T=A.UI.LootIndicator;local B=A.Services.UpgradeIndicator;local S=A.Services.ItemStats;local checks=0
local function check(v,msg) checks=checks+1;assert(v,msg) end
local p=A.Services.Persistence.Profile();p.epWeights={ITEM_MOD_STAMINA_SHORT=.2,ITEM_MOD_DAMAGE_SHADOW_SHORT=1,ITEM_MOD_CRIT_RATING_SHORT=.4,ITEM_MOD_DAMAGE_FROST_SHORT=.5}
local function result() return A.Services.LootComparison.Compare(M.cape) end
local model=B.Build(result())
check(model.rank==2 and model.color=='a335ee','published Fel Cape position 2 has epic color')
check(model.text:find('Item Improvement - 2 BiS',1,true) and model.text:find('+317.5%',1,true) and model.text:find('+18.1 GS/EP',1,true),'rank, percentage and score are independent verified calculations')
check(model.text:find('https://foreverdb.net',1,true),'rank source has visible attribution link')
check(not model.text:find('Stamina',1,true) and not model.text:find('Compared',1,true),'no verbose stat or comparison block')
local record=A.Data.itemGuide.recommendations.Back[279269];local position=record.position
for _,test in ipairs({{1,'ff8000'},{2,'a335ee'},{3,'a335ee'},{4,'0070dd'},{5,'0070dd'},{6,'1eff00'},{7,'1eff00'}}) do
 record.position=test[1];local m=B.Build(result());check(m.color==test[2] and m.rank==test[1],'synthetic rank color control '..test[1])
end
record.position=position
local build=GetBuildInfo;GetBuildInfo=function() return '1.60.1','70790' end
check(not B.Build(result()).rank,'different client build does not inherit a BiS claim');GetBuildInfo=build
local level=UnitLevel;UnitLevel=function() return 59 end
check(not B.Build(result()),'level restriction suppresses improvement');UnitLevel=level
local spec=A.db.spec;A.db.spec='Demonology';p=A.Services.Persistence.Profile();p.epWeights={ITEM_MOD_STAMINA_SHORT=.2,ITEM_MOD_DAMAGE_SHADOW_SHORT=1,ITEM_MOD_CRIT_RATING_SHORT=.4,ITEM_MOD_DAMAGE_FROST_SHORT=.5}
check(not B.Build(result()).rank,'another specialization does not inherit Affliction BiS rank');A.db.spec=spec;p=A.Services.Persistence.Profile()
local unknown=record.position;record.position=nil
check(B.Build(result()).color=='1eff00' and not B.Build(result()).text:find('BiS',1,true),'unranked improvement is green without fabricated ordinal');record.position=unknown
local saved=M.cape;M.cape='item:279269:0:0:0:0:0:-19:9:60';S.Invalidate(nil,true)
check(not B.Build(result()).rank,'random suffix never borrows base-item BiS rank');M.cape=saved;S.Invalidate(nil,true)
tip:SetHyperlink(M.cape)
local state=T.tooltips[tip];local banner=state.indicator;local count=tip.lines
check(banner and banner:IsShown() and state.layout,'indicator attached under native name')
local point,relative,relativePoint=banner:GetPoint(1)
check(point=='TOPLEFT' and relative==GameTooltipTextLeft1 and relativePoint=='BOTTOMLEFT','indicator anchored directly below item name')
local _,_,_,_,titleY=GameTooltipTextLeft1:GetPoint(1)
local _,_,_,_,secondY=GameTooltipTextLeft2:GetPoint(1)
check(titleY==-10 and secondY==-28-state.layout.extra,'title unchanged; second native line moved below indicator')
check(tip.lines==#tip.nativeRows,'no extra native comparison lines')
local height=tip:GetHeight();local frames=#M.frames
for n=1,20 do T.Refresh() end
check(tip:GetHeight()==height and tip.lines==count and #M.frames==frames,'repeated tooltip refresh cannot grow height, lines or frames')
tip:AddLine('Other addon content');T.Refresh();local grown=tip:GetHeight()
check(grown==height+18 and _G['GameTooltipTextLeft'..tip.lines]:GetText()=='Other addon content','another addon can append content without cumulative spacing')
T.SetEnabled(false)
local _,_,_,_,restored=GameTooltipTextLeft2:GetPoint(1)
check(not banner:IsShown() and restored==-28 and tip:GetHeight()==20+18*tip.lines,'disable restores native anchors and preserves extra native line')
T.SetEnabled(true);check(banner:IsShown() and tip:GetHeight()==grown,'enable restores one indicator only')
-- Native engine rebuilds its anchors without an OnTooltipCleared callback.
tip:PaintNative(M.cape)
if M.scenario=='legacy' then
 local frame=T.placementFrame;local update=frame and frame:GetScript('OnUpdate');if update then update(frame,.01) end
else M.Flush() end
check(tip:GetHeight()==20+18*tip.lines+state.layout.extra,'native relayout is not mistaken for an existing owned offset: '..tip:GetHeight()..' vs '..(20+18*tip.lines+state.layout.extra))
-- Dependent native anchors must move once, not once per ancestor.
T.SetEnabled(false);GameTooltipTextLeft3:ClearAllPoints();GameTooltipTextLeft3:SetPoint('TOPLEFT',GameTooltipTextLeft2,'BOTTOMLEFT',0,-3)
T.SetEnabled(true)
local _,_,_,_,chainY=GameTooltipTextLeft3:GetPoint(1)
check(chainY==-3,'relative native line chain is not double shifted')
T.SetEnabled(false)
tip:SetHyperlink(M.cape);T.SetEnabled(true)
-- Third-party changes are not overwritten by clearing our overlay.
GameTooltipTextLeft2:ClearAllPoints();GameTooltipTextLeft2:SetPoint('TOPLEFT',tip,'TOPLEFT',17,-91)
T.SetEnabled(false);local _,_,_,x,y=GameTooltipTextLeft2:GetPoint(1)
check(x==17 and y==-91,'clear preserves anchors no longer owned by this addon')
tip:PaintNative(M.cape);T.SetEnabled(true)
local weights=p.epWeights;p.epWeights={};T.Refresh();check(not banner:IsShown(),'no valid score means no improvement banner')
ForeverLevelingBiS_API={version=2,GetSpec=function() return 'affliction','held','WARLOCK' end,ScoreItem=function(link) return link==M.worn and 5.7 or 23.8,false end}
T.Refresh();check(banner:IsShown() and B.Build(result()).rank==2,'optional active FLB profile can supply a valid Fel Cape comparison')
p.lootScoreSource='manual';T.Refresh();check(not banner:IsShown(),'explicit manual-only source does not use external scores')
p.lootScoreSource='auto';ForeverLevelingBiS_API=nil
p.epWeights=weights;T.Refresh();check(banner:IsShown(),'valid weights restore banner')
M.canUse=false;T.Refresh();check(not banner:IsShown(),'unusable item never gets an improvement banner');M.canUse=true
p.epWeights.ITEM_MOD_DAMAGE_SHADOW_SHORT=-1;T.Refresh();check(not banner:IsShown(),'negative gain suppressed');p.epWeights.ITEM_MOD_DAMAGE_SHADOW_SHORT=1
tip.IsProtected=function() return true end;tip:PaintNative(M.cape);T.Refresh()
check(not banner:IsShown() and tip:GetHeight()==20+18*tip.lines,'protected tooltip is untouched');tip.IsProtected=nil
tip:PaintNative(M.cape);GameTooltipTextLeft2:SetText('SECRET');T.Refresh()
check(not banner:IsShown(),'restricted native text prevents layout mutation')
tip:SetHyperlink(M.cape);tip:Hide();check(not banner:IsShown(),'hide removes overlay')
tip:Show();check(banner:IsShown(),'show reuses overlay')
tip:SetHyperlink('spell:123');check(not banner:IsShown(),'non-item tooltip clears overlay')
if M.scenario=='legacy' then check(originalCalls>0,'legacy native tooltip hook preserved') end
check(#A.diagnostics==0,'no Lua diagnostics: '..table.concat(A.diagnostics,'; '))
M.print('PASS upgrade banner: '..checks..' checks · '..M.scenario..' · source position + synthetic client/weights/layout')
