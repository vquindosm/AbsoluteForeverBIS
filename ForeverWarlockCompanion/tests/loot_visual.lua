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
local tip=GameTooltip;tip.GetName=function() return 'GameTooltip' end
tip.lines=0;tip.NumLines=function(self) return self.lines end
tip.AddLine=function(self,text)
 self.lines=self.lines+1;local key='GameTooltipTextLeft'..self.lines
 local font=_G[key] or self:CreateFontString();_G[key]=font;font:SetText(text)
end
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
check(text:find('|TInterface\\Icons\\',1,true) and text:find('|cffef9797',1,true) and text:find('|cff78e49a',1,true),'stat icons and loss/gain colors')
check(text:find('-9 Spell power',1,true) and text:find('-17 Stamina',1,true),'omitted sparse stats displayed as explicit native losses')
check(text:find('Aflicción',1,true) and text:find('3.7',1,true) and text:find('-73%',1,true) and text:find('Forever Leveling BiS',1,true),'compact profile, score, percentage and source')
check(not text:find('Pesos EP en',1,true) and not text:find('health',1,true),'no technical instructions or unverified derived health formula in compact view')
for _,mode in ipairs({'normal','reverse'}) do
 nativeMode=mode;check(I.Compare(boots).comparisons[1].nativeDelta,'both native subtraction directions validated by common stats: '..mode)
end
for _,mode in ipairs({'throw','nil','secret','conflict','nan'}) do
 nativeMode=mode;row=I.Compare(boots).comparisons[1]
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
nativeMode='normal'
P.epWeights={ITEM_MOD_INTELLECT_SHORT=.3,ITEM_MOD_SPIRIT_SHORT=.15,ITEM_MOD_SPELL_POWER_SHORT=1,ITEM_MOD_STAMINA_SHORT=.2}
row=I.Compare(boots).comparisons[1]
check(row.score.provider=='manual' and math.abs(row.score.absolute+10.15)<1e-8,'automatic mode preserves explicitly entered weights and validated losses')
nativeMode='extra';row=I.Compare(boots).comparisons[1]
check(not row.complete and not row.score,'native-only change without absolute values cannot silently disappear from manual EP')
nativeMode='normal'
P.lootScoreSource='flb';check(I.Compare(boots).comparisons[1].score.provider=='flb','explicit provider selection overrides manual weights')
P.lootScoreSource='manual';check(I.Compare(boots).comparisons[1].score.provider=='manual','manual source explicitly available')
P.lootScoreSource='flb';baseline=0;row=I.Compare(boots).comparisons[1]
check(row.score and row.score.delta==nil and row.score.absolute==candidate,'zero baseline gives absolute score only, no infinite percentage')
check(T.Lines(I.Compare(boots)):find('3.7',1,true),'zero baseline formats safely')
baseline=13.6
loading=true;check(not I.Compare(boots).comparisons[1].score,'external loading result not declared an upgrade');loading=false
scoreFailure=true;check(not I.Compare(boots).comparisons[1].score,'external exception contained');scoreFailure=false
candidate=0/0;check(not I.Compare(boots).comparisons[1].score,'external non-finite score rejected');candidate=3.7
f.version=1;check(not I.Compare(boots).comparisons[1].score,'unsupported external API version ignored');f.version=2
activeClass='MAGE';check(not I.Compare(boots).comparisons[1].score,'external wrong class profile rejected');activeClass='WARLOCK'
activeSpec='destruction';check(T.Lines(I.Compare(boots)):find('Destrucción',1,true),'actual external profile identified instead of FWC view selection');activeSpec='affliction'
ForeverLevelingBiS_API=nil;check(not I.Compare(boots).comparisons[1].score,'explicit missing provider never silently falls back to another score')
P.lootScoreSource='auto';check(I.Compare(boots).comparisons[1].score.provider=='manual','optional dependency absent: configured EP remains usable')
P.epWeights={};check(not I.Compare(boots).comparisons[1].score and I.Compare(boots).comparisons[1].state=='mixed','no API/no weights still gives honest mixed attribute comparison')
ForeverLevelingBiS_API=f
local savedValues=values[910002];values[910002]={};S.Invalidate(nil,true)
check(I.Compare(boots).comparisons[1].score.provider=='flb','loaded gear with no exposed native stats can still use independent score API')
values[910002]=savedValues;S.Invalidate(nil,true)
tip:SetHyperlink(boots)
local own=T.tooltips[tip].inline
check(own and not T.tooltips[tip].panel and tip.lines==4,'comparison embedded into exactly two native lines, no detached panel')
check(_G.GameTooltipTextLeft1:GetText()=='Native item name' and _G.GameTooltipTextLeft2:GetText()=='Other addon footer','native and other addon text preserved')
local count=#M.frames
for i=1,10 do T.Refresh() end
check(tip.lines==4 and #M.frames==count,'live refresh reuses native lines with no row or frame growth')
check(registrations==1,'external change callback registered once')
candidate=20;callback();callback();M.Flush()
local timer=A.Services.LootScore.timerFrame
if timer and timer:GetScript('OnUpdate') then timer:GetScript('OnUpdate')(timer,.01) end
check(own.body:GetText():find('+47%',1,true),'debounced external profile changes refresh current comparison')
candidate=3.7
tip:AddLine('Later addon content');T.Refresh()
check(_G.GameTooltipTextLeft5:GetText()=='Later addon content' and tip.lines==5,'later addon rows not overwritten by refresh')
T.SetEnabled(false)
check(own.header:GetText()=='' and own.body:GetText()=='' and _G.GameTooltipTextLeft5:GetText()=='Later addon content','disabling clears only owned content')
T.SetEnabled(true);check(tip.lines==5 and own.header:GetText()~='','reenabling reuses cleared owned rows')
tip:Hide();check(own.body:GetText()=='','hide removes stale comparison');tip:Show()
check(tip.lines==5 and own.body:GetText():find('3.7',1,true),'same visible item can show again without accumulating rows')
tip:SetHyperlink(base);check(tip.lines==4 and T.tooltips[tip].inline.body:GetText():find('Ya equipado',1,true),'item change rebuilds native-owned footer for correct item')
tip:SetHyperlink('spell:123');check(not T.tooltips[tip].inline,'non-item tooltip never retains comparison')
check(#A.diagnostics==0,'no compatibility errors: '..table.concat(A.diagnostics,'; '))
M.print('PASS loot visual: '..checks..' checks · '..M.scenario..' · synthetic APIs, no game rendering')
