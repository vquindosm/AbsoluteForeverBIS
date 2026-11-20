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
check(not model.text:find('foreverdb',1,true),'credit is inside addon rather than appended to score')
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
check(banner and banner:IsShown(),'comparison card shown')
local point,relative,relativePoint=banner:GetPoint(1)
check(point=='TOPLEFT' and relative==tip and relativePoint=='BOTTOMLEFT','card anchored below tooltip, never below its title font')
local _,_,_,_,titleY=GameTooltipTextLeft1:GetPoint(1)
local _,_,_,_,secondY=GameTooltipTextLeft2:GetPoint(1)
check(titleY==-10 and secondY==-28,'native name and stat anchors never shifted')
check(tip.lines==#tip.nativeRows and tip:GetHeight()==20+18*tip.lines,'native height and line count untouched')
check(banner.background.color[2]>banner.background.color[1] and banner.edges[1].color[2]>banner.edges[1].color[1],'upgrade tints whole background and border green')
A.UI.DesignSystem.Apply('Modern Azeroth');check(banner.background.color[2]>banner.background.color[1],'main theme cannot overwrite card performance colors')
check(banner.classIcon.texture:find('UI-CharacterCreate-Classes',1,true) and banner.classIcon.texCoord[1]==.75,'native Warlock class icon uses correct atlas coordinates')
check(banner.identity:GetText()=='Warlock · Affliction' and banner.specIcon.texture:find('DeathCoil',1,true),'class and active specialization identified')
check(banner.text:GetText():find('+317.5%',1,true) and banner.text:GetText():find('+18.1 GS/EP',1,true),'unchanged numeric gains')
check(not banner.text:GetText():find('foreverdb',1,true),'database suffix removed from card')
check(banner.rank:GetText():find('2 BiS',1,true),'published BiS tier retained separately')
check(banner.fill:GetWidth()==(banner:GetWidth()-20)/2,'meter saturates at 100 percent without changing numeric gain')
local meterPoint= banner.fill:GetPoint(1);check(meterPoint=='LEFT','positive meter extends right from zero')
tip:SetWidth(500);T.Refresh();check(banner:GetWidth()==500,'card matches a wide native tooltip');tip:SetWidth(360);T.Refresh()
local height=tip:GetHeight();local frames=#M.frames
for n=1,20 do T.Refresh() end
check(tip:GetHeight()==height and tip.lines==count and #M.frames==frames,'refresh cannot grow native tooltip or allocate duplicate cards')
tip:AddLine('Other addon content');T.Refresh()
check(tip:GetHeight()==height+18 and _G['GameTooltipTextLeft'..tip.lines]:GetText()=='Other addon content','another addon can append content unchanged')
T.SetEnabled(false)
local _,_,_,_,restored=GameTooltipTextLeft2:GetPoint(1)
check(not banner:IsShown() and restored==-28 and tip:GetHeight()==height+18,'disable removes only own card')
T.SetEnabled(true);check(banner:IsShown() and tip:GetHeight()==height+18,'enable reuses card without reserving native space')
tip:PaintNative(M.cape)
if M.scenario=='legacy' then local f=T.placementFrame;if f:GetScript('OnUpdate') then f:GetScript('OnUpdate')(f,.01) end else M.Flush() end
check(tip:GetHeight()==20+18*tip.lines and banner:IsShown(),'native reflow does not cause an offset or enlarged top area')
-- Layout never reads or writes native font anchors, including unusual clients.
local getName,numLines=tip.GetName,tip.NumLines;tip.GetName=nil;tip.NumLines=nil
local font=GameTooltipTextLeft2;local getText,clearPoints=font.GetText,font.ClearAllPoints
font.GetText=function() error('native text must not be read') end
font.ClearAllPoints=function() error('native anchors must not be changed') end
T.Refresh();check(banner:IsShown(),'card works without native line APIs and never touches native fonts')
font.GetText=getText;font.ClearAllPoints=clearPoints;tip.GetName=getName;tip.NumLines=numLines
-- If the bottom of the screen is crowded, use the available side, never the top.
tip.GetBottom=function() return 4 end;tip.GetRight=function() return 100 end;tip.GetLeft=function() return 20 end
T.Refresh();check(banner.placement=='right' and banner:IsShown(),'bottom collision uses right side')
tip.GetRight=function() return UIParent:GetWidth()-4 end;tip.GetLeft=function() return 700 end
T.Refresh();check(banner.placement=='left' and banner:IsShown(),'right edge collision uses left side')
tip.GetLeft=function() return 0 end;T.Refresh();check(not banner:IsShown(),'no free space hides card rather than covering native stats')
tip.GetBottom=nil;tip.GetRight=nil;tip.GetLeft=nil;T.Refresh()
local weights=p.epWeights;p.epWeights={};T.Refresh();check(not banner:IsShown(),'invalid score hides card')
ForeverLevelingBiS_API={version=2,GetSpec=function() return 'destruction','held','WARLOCK' end,ScoreItem=function(link) return link==M.worn and 5.7 or 23.8,false end}
T.Refresh();check(banner:IsShown() and banner.identity:GetText():find('Destruction',1,true) and banner.specIcon.texture:find('RainOfFire',1,true),'external active spec drives class/spec display')
p.lootScoreSource='manual';T.Refresh();check(not banner:IsShown(),'manual-only source excludes external scores')
p.lootScoreSource='auto';ForeverLevelingBiS_API=nil;p.epWeights=weights;T.Refresh()
M.canUse=false;T.Refresh();check(not banner:IsShown(),'unusable item has no card');M.canUse=true
-- A stronger, positively weighted worn item creates a genuine downgrade control.
M.wornStats.ITEM_MOD_DAMAGE_SHADOW_SHORT=40;S.Invalidate(nil,true);T.Refresh()
check(banner:IsShown() and not banner.model.upgrade,'valid downgrade shown')
check(banner.background.color[1]>banner.background.color[2] and banner.edges[1].color[1]>banner.edges[1].color[2],'downgrade tints entire background and border red')
check(banner.text:GetText():find('-47.9%',1,true) and banner.text:GetText():find('-21.9 GS/EP',1,true),'negative percent and score use the original scoring model')
check(banner.fill:GetPoint(1)=='RIGHT' and math.abs(banner.fill:GetWidth()-(banner:GetWidth()-20)/2*math.abs(banner.model.meter))<1e-8,'negative meter extends left from midpoint')
M.wornStats.ITEM_MOD_DAMAGE_SHADOW_SHORT=nil;S.Invalidate(nil,true)
tip.IsProtected=function() return true end;tip:PaintNative(M.cape);T.Refresh()
check(not banner:IsShown() and tip:GetHeight()==20+18*tip.lines,'protected tooltip untouched');tip.IsProtected=nil
tip:SetHyperlink(M.cape);tip:Hide();check(not banner:IsShown(),'hide removes card');tip:Show();check(banner:IsShown(),'show reuses card')
tip:SetHyperlink('spell:123');check(not banner:IsShown(),'non-item tooltip clears card')
if M.scenario=='legacy' then check(originalCalls>0,'native legacy hook preserved') end
check(#A.diagnostics==0,'no Lua diagnostics: '..table.concat(A.diagnostics,'; '))
M.print('PASS upgrade card: '..checks..' checks · '..M.scenario..' · published position / synthetic client and frames')
