-- Synthetic client/API responses reproducing the shape of the reported boots
-- comparison. Not a capture or verification of actual Forever item records.
local M=dofile('tests/wow_mock.lua');local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,msg) end
local base='item:910001:0:0:0:0:0:0:0:60'
local boots='item:910002:0:0:0:0:0:-19:9000:60'
local values={
 [910001]={ITEM_MOD_INTELLECT_SHORT=7,ITEM_MOD_SPIRIT_SHORT=10,RESISTANCE0_NAME=58,ITEM_MOD_SPELL_POWER_SHORT=9,ITEM_MOD_STAMINA_SHORT=17},
 [910002]={ITEM_MOD_INTELLECT_SHORT=13,ITEM_MOD_SPIRIT_SHORT=13,RESISTANCE0_NAME=52}}
local diff={ITEM_MOD_INTELLECT_SHORT=6,ITEM_MOD_SPIRIT_SHORT=3,RESISTANCE0_NAME=-6,ITEM_MOD_SPELL_POWER_SHORT=-9,ITEM_MOD_STAMINA_SHORT=-17}
local nativeMode='normal';local deltaCalls={};local scoreCalls={};local callback;local registrations=0;local loading=false;local scoreFailure=false
local function id(link) return type(link)=='number' and link or tonumber(tostring(link):match('item:(%d+)')) end
local oldInfo=C_Item and C_Item.GetItemInfo or GetItemInfo
local function info(link)
 if not values[id(link)] then return oldInfo(link) end
 return id(link)==910001 and 'Equipped boots control' or 'Random suffix boots control','item:'..id(link),2,59,54,'Armor','Cloth',1,'INVTYPE_FEET',123,0,4,1
end
local function raw(link) return values[id(link)] end
local function delta(first,second)
 deltaCalls[#deltaCalls+1]={first,second}
 if nativeMode=='throw' then error('not available') end
 if nativeMode=='nil' then return nil end
 if nativeMode=='secret' then return {ITEM_MOD_INTELLECT_SHORT='SECRET'} end
 local r={};for k,v in pairs(diff) do r[k]=nativeMode=='reverse' and -v or v end
 if nativeMode=='conflict' then r.ITEM_MOD_SPIRIT_SHORT=-3 end
 if nativeMode=='nan' then r.ITEM_MOD_STAMINA_SHORT=0/0 end
 if nativeMode=='omit' then r.ITEM_MOD_SPELL_POWER_SHORT=nil end
 if nativeMode=='extra' then r.ITEM_MOD_ATTACK_POWER_SHORT=5 end
 return r
end
if M.scenario=='legacy' then GetItemInfo=info;GetItemStats=raw;GetItemStatDelta=delta;IsEquippableItem=function() return true end
else C_Item.GetItemInfo=info;C_Item.GetItemStats=raw;C_Item.GetItemStatDelta=delta;C_Item.IsEquippableItem=function() return true end end
C_PlayerInfo={CanUseItem=function() return true end}
M.equipped={[8]=910001}
GetInventoryItemLink=function(_,slot) return slot==8 and base end
local activeSpec='affliction';local activeClass='WARLOCK';local baseline=13.6;local candidate=3.7
local f={version=2,GetSpec=function() return activeSpec,'held',activeClass end,
 ScoreItem=function(link,offHand)
  scoreCalls[#scoreCalls+1]={link,offHand}
  if scoreFailure then error('external failure') end
  return link==base and baseline or candidate,loading
 end,
 GetGain=function() return 999 end, -- Must not use a potentially different saved equipment set.
 IsUpgrade=function() return false end, -- Bag arrows off must not disable numeric comparison.
 OnChanged=function(fn) registrations=registrations+1;callback=fn end}
ForeverLevelingBiS_API=f
local postcall
Enum.TooltipDataType={Item=1}
if M.scenario~='legacy' then TooltipDataProcessor={AddTooltipPostCall=function(_,fn) postcall=fn end} end
local tip=dofile('tests/tooltip_fixture.lua').Attach(GameTooltip,'GameTooltip')
tip.GetItem=function(self) return 'control',self.link end
tip.HasScript=function(_,event) return event~='OnTooltipSetItem' or M.scenario=='legacy' end
tip.HookScript=function(self,event,fn)
 local previous=self:GetScript(event);self:SetScript(event,function(...) if previous then previous(...) end;fn(...) end)
end
tip.SetHyperlink=function(self,link)
 local clear=self:GetScript('OnTooltipCleared');if clear then clear(self) end
 self.lines=0;self.link=link;self:AddLine('Native item name');self:AddLine('Other addon footer')
 if postcall then postcall(self) elseif self:GetScript('OnTooltipSetItem') then self:GetScript('OnTooltipSetItem')(self) end
 self:Show()
end
ForeverWarlockCompanionDB={viewClass='WARLOCK',spec='Affliction',mode='Pre-BiS'}
for line in io.lines('ForeverWarlockCompanion.toc') do if line:match('%.lua$') then dofile((line:gsub('\\','/'))) end end
M.Event('ADDON_LOADED','ForeverWarlockCompanion')
local A=FWC;local I=A.Services.LootComparison;local S=A.Services.ItemStats;local T=A.UI.LootIndicator;local P=A.Services.Persistence.Profile()
P.epWeights={}
local result=I.Compare(boots);local row=result.comparisons[1]
check(row.nativeDelta and row.complete and #row.unknown==0,'sparse candidate resolved by explicit pairwise deltas')
local seen={};for _,d in ipairs(row.deltas) do seen[d.key]=d.delta end
for k,v in pairs(diff) do check(seen[k]==v,'correct screenshot-shaped change: '..k) end
check(S.Value(result.after,'ITEM_MOD_SPELL_POWER_SHORT')==nil,'pair reconstruction never changes sparse item cache')
check(deltaCalls[1][1]==base and deltaCalls[1][2]==boots,'pairwise native API receives both complete instance links')
check(row.score.provider=='flb' and row.state=='downgrade' and math.abs(row.score.absolute+9.9)<1e-8,'external public API scores actual worn baseline')
check(math.abs(row.score.delta+72.794117647)<1e-6,'percentage uses actual positive equipped score')
check(scoreCalls[1][1]==base and scoreCalls[2][1]==boots and scoreCalls[2][2]==false,'suffix preserved; API saved-set GetGain not substituted')
local text=T.Lines(result)
check(text and text:find('Item Downgrade',1,true),'downgrade represented by comparison card')
check(#row.deltas==5,'full attribute differences still available to inspector')
check(row.score.spec=='affliction','score retains provider profile identity')
check(row.score.source=='Forever Leveling BiS','score retains provider attribution metadata')
for _,mode in ipairs({'normal','reverse'}) do
 nativeMode=mode;S.Invalidate(nil,true);check(I.Compare(boots).comparisons[1].nativeDelta,'both native subtraction directions validated by common stats: '..mode)
end
for _,mode in ipairs({'throw','nil','secret','conflict','nan'}) do
 nativeMode=mode;S.Invalidate(nil,true);row=I.Compare(boots).comparisons[1]
 check(not row.nativeDelta and #row.unknown==2,'failed or inconsistent native comparison does not invent zero: '..mode)
 check(row.score and row.score.provider=='flb','independent provider handles sparse native records: '..mode)
end
nativeMode='normal'
local originalInt=values[910001].ITEM_MOD_INTELLECT_SHORT
local originalSpirit=values[910001].ITEM_MOD_SPIRIT_SHORT
local originalArmor=values[910001].RESISTANCE0_NAME
values[910001].ITEM_MOD_INTELLECT_SHORT=13;values[910001].ITEM_MOD_SPIRIT_SHORT=13;values[910001].RESISTANCE0_NAME=52
S.Invalidate(nil,true)
check(not I.Compare(boots).comparisons[1].nativeDelta,'no common nonzero anchor: native direction is not guessed')
values[910001].ITEM_MOD_INTELLECT_SHORT=originalInt;values[910001].ITEM_MOD_SPIRIT_SHORT=originalSpirit;values[910001].RESISTANCE0_NAME=originalArmor
S.Invalidate(nil,true);nativeMode='omit';row=I.Compare(boots).comparisons[1]
check(row.nativeDelta and #row.unknown==1 and row.unknown[1].label=='Spell power','a missing pairwise delta cannot zero-fill a missing item stat')
nativeMode='normal';S.Invalidate(nil,true)
P.epWeights={ITEM_MOD_INTELLECT_SHORT=.3,ITEM_MOD_SPIRIT_SHORT=.15,ITEM_MOD_SPELL_POWER_SHORT=1,ITEM_MOD_STAMINA_SHORT=.2}
row=I.Compare(boots).comparisons[1]
check(row.score.provider=='manual' and math.abs(row.score.absolute+10.15)<1e-8,'automatic mode preserves explicitly entered weights and validated losses')
nativeMode='extra';S.Invalidate(nil,true);row=I.Compare(boots).comparisons[1]
check(not row.complete and not row.score,'native-only change without absolute values cannot silently disappear from manual EP')
nativeMode='normal';S.Invalidate(nil,true)
P.lootScoreSource='flb';check(I.Compare(boots).comparisons[1].score.provider=='flb','explicit provider selection overrides manual weights')
P.lootScoreSource='manual';check(I.Compare(boots).comparisons[1].score.provider=='manual','manual source explicitly available')
P.lootScoreSource='flb';baseline=0;row=I.Compare(boots).comparisons[1]
check(row.score and row.score.delta==nil and row.score.absolute==candidate,'zero baseline gives absolute score only, no infinite percentage')
check(T.Lines(I.Compare(boots))==nil,'zero baseline cannot display a percentage improvement')
baseline=13.6
loading=true;check(not I.Compare(boots).comparisons[1].score,'external loading result not declared an upgrade');loading=false
scoreFailure=true;check(not I.Compare(boots).comparisons[1].score,'external exception contained');scoreFailure=false
candidate=0/0;check(not I.Compare(boots).comparisons[1].score,'external non-finite score rejected');candidate=3.7
f.version=1;check(not I.Compare(boots).comparisons[1].score,'unsupported external API version ignored');f.version=2
activeClass='MAGE';check(not I.Compare(boots).comparisons[1].score,'external wrong class profile rejected');activeClass='WARLOCK'
activeSpec='destruction';check(I.Compare(boots).comparisons[1].score.spec=='destruction','external profile preserved in scoring metadata');activeSpec='affliction'
ForeverLevelingBiS_API=nil;check(not I.Compare(boots).comparisons[1].score,'explicit missing provider never silently falls back to another score')
P.lootScoreSource='auto';check(I.Compare(boots).comparisons[1].score.provider=='manual','optional dependency absent: configured EP remains usable')
P.epWeights={};check(not I.Compare(boots).comparisons[1].score and I.Compare(boots).comparisons[1].state=='mixed','no API/no weights still gives honest mixed attribute comparison')
ForeverLevelingBiS_API=f
local savedValues=values[910002];values[910002]={};S.Invalidate(nil,true)
check(I.Compare(boots).comparisons[1].score.provider=='flb','loaded gear with no exposed native stats can still use independent score API')
values[910002]=savedValues;S.Invalidate(nil,true)
candidate=20;tip:SetHyperlink(boots)
local own=T.tooltips[tip].indicator
check(own and own:IsShown() and tip.lines==2,'one overlay under name; native line count unchanged')
check(_G.GameTooltipTextLeft1:GetText()=='Native item name' and _G.GameTooltipTextLeft2:GetText()=='Other addon footer','native and other addon texts preserved')
local count=#M.frames;local height=tip:GetHeight()
for i=1,10 do T.Refresh() end
check(tip.lines==2 and #M.frames==count and tip:GetHeight()==height,'refresh reuses overlay without height or frame growth')
check(registrations==1,'external change callback registered once')
candidate=30;callback();callback();M.Flush()
local timer=A.Services.LootScore.timerFrame
if timer and timer:GetScript('OnUpdate') then timer:GetScript('OnUpdate')(timer,.01) end
check(own.text:GetText():find('+120.6%',1,true),'debounced profile change refreshes percentage')
tip:AddLine('Later addon content');T.Refresh()
check(_G.GameTooltipTextLeft3:GetText()=='Later addon content' and tip.lines==3,'later addon rows not overwritten')
T.SetEnabled(false)
check(not own:IsShown() and _G.GameTooltipTextLeft3:GetText()=='Later addon content','disabling removes only own overlay')
T.SetEnabled(true);check(tip.lines==3 and own:IsShown(),'reenabling never appends a native line')
tip:Hide();check(not own:IsShown(),'hide clears own banner');tip:Show()
check(tip.lines==3 and own:IsShown(),'same item shows again without duplicate lines')
candidate=3.7;tip:SetHyperlink(boots);check(own:IsShown() and not own.model.upgrade,'changing to downgrade changes card state')
tip:SetHyperlink('spell:123');check(not own:IsShown(),'non-item tooltip never retains banner')
check(#A.diagnostics==0,'no compatibility errors: '..table.concat(A.diagnostics,'; '))
M.print('PASS loot visual: '..checks..' checks · '..M.scenario..' · synthetic APIs, no game rendering')
