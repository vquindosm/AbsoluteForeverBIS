-- All items, item stats and player/loot responses in this test are synthetic controls.
-- This exercises native API contracts, not itemization or a rendered WoW client.
local M=dofile('tests/wow_mock.lua');local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,msg) end
local I,S,T,P
local id=810000;local gear={};local pending={};local readLinks={};local canUse=true;local canEquip=true
local function add(loc,stats,extra)
 id=id+1;gear[id]={name='Loot control '..id,loc=loc,stats=stats,requiredLevel=60}
 for k,v in pairs(extra or {}) do gear[id][k]=v end
 return 'item:'..id
end
local function stats(int,sp,sta) return {ITEM_MOD_INTELLECT_SHORT=int,ITEM_MOD_SPELL_POWER_SHORT=sp,ITEM_MOD_STAMINA_SHORT=sta} end
local base=add('INVTYPE_HEAD',stats(10,0,10));local up=add('INVTYPE_HEAD',stats(20,6,5));local down=add('INVTYPE_HEAD',stats(5,0,20))
local missing=add('INVTYPE_HEAD',{ITEM_MOD_INTELLECT_SHORT=20});local nonGear=add('',{}, {requiredLevel=1})
local ringA=add('INVTYPE_FINGER',stats(10,0,10));local ringB=add('INVTYPE_FINGER',stats(30,0,10));local ring=add('INVTYPE_FINGER',stats(20,0,10))
local trinket=add('INVTYPE_TRINKET',stats(20,0,10))
local main=add('INVTYPE_WEAPON',stats(10,0,10));local off=add('INVTYPE_HOLDABLE',stats(10,6,10));local two=add('INVTYPE_2HWEAPON',stats(30,8,15))
local otherVariant=up..':444:0:0:0:0:83'
local preInfo=C_Item and C_Item.GetItemInfo or GetItemInfo;local preStats=C_Item and C_Item.GetItemStats or GetItemStats
local function info(link)
 local n=type(link)=='number' and link or tonumber(tostring(link):match('item:(%d+)'));local r=gear[n]
 if not r then return preInfo(link) end
 if pending[n] then return nil end
 return r.name,'item:'..n,3,65,r.requiredLevel,'Armor','Cloth',1,r.loc,123,0,4,1
end
local function raw(link)
 readLinks[#readLinks+1]=link
 local n=tonumber(tostring(link):match('item:(%d+)'));local r=gear[n]
 if not r then return preStats(link) end
 if pending[n] then return nil end
 if link==otherVariant then return stats(40,6,5) end
 return r.stats
end
if M.scenario=='legacy' then GetItemInfo=info;GetItemStats=raw;IsEquippableItem=function() return canEquip end
else C_Item.GetItemInfo=info;C_Item.GetItemStats=raw;C_Item.IsEquippableItem=function() return canEquip end end
C_PlayerInfo={CanUseItem=function() return canUse end}
CanDualWield=function() return false end
M.equipped={[1]=tonumber(base:match('%d+'))}
local postcalls={};local originalCalls=0;local registrations=0
local function makeTooltip(tip)
 local originalSet=tip.SetHyperlink
 tip.HasScript=function(_,event) return event~='OnTooltipSetItem' or M.scenario=='legacy' end
 tip.HookScript=function(self,event,fn)
  assert(self:HasScript(event),'unsupported script')
  local old=self:GetScript(event);self:SetScript(event,function(...) if old then old(...) end;fn(...) end)
 end
 tip.GetItem=function(self) if self.unitTip then return end;return 'control',self.link end
 tip.SetHyperlink=function(self,link)
  if self:GetScript('OnTooltipCleared') then self:GetScript('OnTooltipCleared')(self) end
  self.unitTip=false;originalSet(self,link)
  if M.scenario=='legacy' then local f=self:GetScript('OnTooltipSetItem');if f then f(self) end
  elseif postcalls[1] then postcalls[1](self,{id=tonumber(link:match('item:(%d+)'))}) end
  self:Show()
 end
 tip:SetSize(310,220);tip:SetPoint('TOPLEFT',UIParent,'TOPLEFT',700,-180)
 tip:SetScript('OnTooltipSetItem',function() originalCalls=originalCalls+1 end)
end
makeTooltip(GameTooltip)
if M.scenario~='legacy' then
 Enum.TooltipDataType={Item=1};TooltipDataProcessor={AddTooltipPostCall=function(kind,fn) registrations=registrations+1;postcalls[kind]=fn end}
end
local hookCount=0
hooksecurefunc=function(target,method,fn)
 hookCount=hookCount+1
 if type(target)=='string' then local callback=method;local old=_G[target];_G[target]=function(...) old(...);callback(...) end
 else local old=target[method];target[method]=function(...) old(...);fn(...) end end
end
local nativeUpdates=0;LootFrame_Update=function() nativeUpdates=nativeUpdates+1 end
ForeverWarlockCompanionDB={viewClass='WARLOCK',spec='Affliction',mode='Pre-BiS'}
for line in io.lines('ForeverWarlockCompanion.toc') do if line:match('%.lua$') then dofile((line:gsub('\\','/'))) end end
M.Event('ADDON_LOADED','ForeverWarlockCompanion')
local A=FWC;I=A.Services.LootComparison;S=A.Services.ItemStats;T=A.UI.LootIndicator;P=A.Services.Persistence.Profile()
P.epWeights={ITEM_MOD_INTELLECT_SHORT=1,ITEM_MOD_SPELL_POWER_SHORT=2,ITEM_MOD_STAMINA_SHORT=0}
check(T.Enabled(),'indicators enabled by default')
check(T.mode==(M.scenario=='legacy' and 'legacy' or 'modern'),'capability-selected tooltip path')
local r=I.Compare(up);local row=r.comparisons[1]
check(row.state=='upgrade' and row.score.before==10 and row.score.after==32,'actual equipped item compared with external catalog item')
check(math.abs(row.score.delta-220)<.00001,'EP change uses actual baseline and selected weights')
check(#row.deltas==3 and row.deltas[1].delta==10,'per-attribute gains and losses')
check(T.Lines(r):find('+6 Spell power',1,true) and T.Lines(r):find('-5 Stamina',1,true),'tooltip explains gain and tradeoff')
check(T.Lines(r):find('no es DPS',1,true),'EP explicitly not DPS')
P.epWeights.ITEM_MOD_HIT_SPELL_RATING_SHORT=1
check(I.Compare(up).comparisons[1].state=='partial' and not I.Compare(up).comparisons[1].score,'nonzero weighted stat absent on both sides is not silently ignored')
P.epWeights.ITEM_MOD_HIT_SPELL_RATING_SHORT=nil
check(I.Compare(down).comparisons[1].state=='downgrade','weighted downgrade')
P.epWeights={};r=I.Compare(up);check(r.comparisons[1].state=='mixed','no weights: mixed stats do not imply global upgrade')
check(T.Lines(r):find('Sin valoración global',1,true),'no-weight status explicit')
local dominated=add('INVTYPE_HEAD',stats(20,6,10));r=I.Compare(dominated)
check(r.comparisons[1].state=='stats-up' and not r.comparisons[1].score,'unweighted dominance limited to read attributes')
check(select(1,I.Badge(r))=='↑ stats','stats arrow distinct from EP arrow')
P.epWeights={ITEM_MOD_INTELLECT_SHORT=1,ITEM_MOD_SPELL_POWER_SHORT=2,ITEM_MOD_STAMINA_SHORT=0}
r=I.Compare(missing);check(r.comparisons[1].state=='partial' and not r.comparisons[1].score,'missing side never zero-filled for score')
check(#r.comparisons[1].unknown==2,'unexposed attrs retained as unknown')
check(T.Lines(r):find('equipado 0',1,true),'explicit equipped zero remains distinguishable from unknown')
local zero=add('INVTYPE_HEAD',stats(10,0,10));check(I.Compare(zero).comparisons[1].state=='equal','explicit numeric equality')
check(I.Compare(base).comparisons[1].state=='same','same exact equipped payload')
local colored='|cff0070dd|H'..base..'|h[display differs]|h|r';check(I.Compare(colored).comparisons[1].state=='same','cosmetic link decoration does not change variant')
local variant=I.Compare(otherVariant);check(variant.after.link==otherVariant and variant.after.values.ITEM_MOD_INTELLECT_SHORT==40,'full suffix/enchant link reaches native reader')
check(I.Compare(up).after.values.ITEM_MOD_INTELLECT_SHORT==20,'base variant cache not contaminated')
check(not A.Data.items[r.itemId],'loot outside imported BiS catalog supported')
check(I.Compare(nonGear)==nil and I.Compare('spell:123')==nil,'materials and non-item tooltips skipped')
local oldLevel=UnitLevel;UnitLevel=function() return 40 end
check(I.Compare(up).comparisons[1].state=='blocked','level restriction overrides positive EP')
UnitLevel=oldLevel;canUse=false;check(I.Compare(up).comparisons[1].state=='blocked','client class/use restriction overrides score');canUse=true
local oldCanUse=C_PlayerInfo;C_PlayerInfo=nil;canEquip=nil
r=I.Compare(up);check(r.comparisons[1].eligible==nil and select(2,I.Badge(r))=='partial','unknown compatibility never green overall arrow')
C_PlayerInfo=oldCanUse;canEquip=true
M.equipped[11]=tonumber(ringA:match('%d+'));M.equipped[12]=tonumber(ringB:match('%d+'))
r=I.Compare(ring);check(#r.comparisons==2 and r.comparisons[1].state=='upgrade' and r.comparisons[2].state=='downgrade','ring compared independently with both slots')
M.equipped[12]=tonumber(ring:match('%d+'));r=I.Compare(ring)
check(r.comparisons[1].eligible==nil and select(2,I.Badge(r))=='partial' and T.Lines(r):find('Único-equipado',1,true),'second identical ring copy needs unique-equipped check before green marker')
M.equipped[12]=tonumber(ringB:match('%d+'))
M.equipped[13]=M.equipped[11];M.equipped[14]=M.equipped[12];check(#I.Compare(trinket).comparisons==2,'both trinket slots compared')
M.equipped[12]=nil;r=I.Compare(ring);check(r.comparisons[2].state=='empty' and not r.comparisons[2].score,'empty slot is not infinite percentage improvement')
M.equipped[16]=tonumber(main:match('%d+'));M.equipped[17]=tonumber(off:match('%d+'))
r=I.Compare(two);row=r.comparisons[1]
check(row.loadout and row.before.values.ITEM_MOD_INTELLECT_SHORT==20 and row.before.values.ITEM_MOD_SPELL_POWER_SHORT==6,'2H baseline includes equipped offhand')
check(row.score and row.score.before==32 and row.score.after==46,'2H score uses combined old loadout')
gear[M.equipped[17]].stats.ITEM_MOD_SPELL_POWER_SHORT=nil;S.Invalidate(nil,true)
check(I.Compare(two).comparisons[1].state=='partial','missing offhand stat never treated as zero in loadout sum')
gear[M.equipped[17]].stats.ITEM_MOD_SPELL_POWER_SHORT=6;S.Invalidate(nil,true)
M.equipped[16]=tonumber(two:match('%d+'));M.equipped[17]=nil
check(I.Compare(off).comparisons[1].state=='loadout','offhand cannot look like free upgrade while wielding 2H')
M.equipped[16]=tonumber(main:match('%d+'));CanDualWield=function() return true end
check(#I.Compare(main).comparisons==2,'generic weapon compares both hands only with native dual-wield capability')
CanDualWield=function() return false end;check(#I.Compare(main).comparisons==1,'no assumed dual wield')
-- Current equipment is read directly even when cached inventory is stale/in combat.
local stale=A.Services.Inventory.snapshot.equipped.Head.id
M.equipped[1]=tonumber(up:match('%d+'));M.combat=true
check(I.Compare(up).comparisons[1].state=='same' and A.Services.Inventory.snapshot.equipped.Head.id==stale,'fresh equipped links used in combat without a bag scan')
M.combat=false;M.equipped[1]=tonumber(base:match('%d+'))
GameTooltip:SetHyperlink(up);local panel=T.tooltips[GameTooltip].panel
check(panel and panel:IsShown() and panel.text:GetText():find('+220.0%',1,true),'visible comparison without opening addon window')
check(A.UI.window==nil,'loot indicator does not require main window')
local nativeText=GameTooltip:GetText();local panelIdentity=panel
for i=1,8 do GameTooltip:SetHyperlink(up);T.Refresh() end
check(T.tooltips[GameTooltip].panel==panelIdentity and GameTooltip:GetText()==nativeText,'tooltip panel reused without replacing native text')
if M.scenario=='legacy' then check(originalCalls>0,'legacy hook preserves other tooltip script')
else check(registrations==1,'modern processor registered only once') end
-- An old async result cannot repaint the next item under the cursor.
local late=add('INVTYPE_HEAD',stats(50,6,10));local lateId=tonumber(late:match('%d+'));pending[lateId]=true;S.Invalidate(lateId,true)
GameTooltip:SetHyperlink(late);check(T.tooltips[GameTooltip].panel.text:GetText():find(M.scenario=='legacy' and 'Datos del objeto no disponibles' or 'Cargando',1,true),'uncached/unsupported item data state visible')
GameTooltip:SetHyperlink(down);pending[lateId]=nil;M.Event('ITEM_DATA_LOAD_RESULT',lateId,true);M.Advance();T.Refresh()
check(T.tooltips[GameTooltip].link==down and not panel.text:GetText():find('+520.0%',1,true),'late callback respects current tooltip item')
GameTooltip:SetHyperlink(late);check(panel.text:GetText():find('Mejora estimada',1,true),'loaded item resolves to live comparison')
local clear=GameTooltip:GetScript('OnTooltipCleared');clear(GameTooltip);GameTooltip.unitTip=true
check(not panel:IsShown(),'changing tooltip to a unit clears indicator')
GameTooltip:SetHyperlink(up);GameTooltip:Hide();check(not panel:IsShown(),'tooltip hide clears own panel')
ItemRefTooltip=CreateFrame('GameTooltip',nil,UIParent);makeTooltip(ItemRefTooltip);T.Init();ItemRefTooltip:SetHyperlink(up)
check(T.tooltips[ItemRefTooltip].panel:IsShown(),'chat item-link tooltip supported when frame appears late')
local foreign=CreateFrame('GameTooltip',nil,UIParent);makeTooltip(foreign);T.Watch(foreign)
check(T.tooltips[foreign]==nil,'shopping/custom tooltips do not receive recursive comparisons')
-- Buttons deliberately have row index != loot index, matching scrolling Blizzard rows.
LootButton1=CreateFrame('Button',nil,UIParent);LootButton1.slot=7
LootButton2=CreateFrame('Button',nil,UIParent);LootButton2.slot=4
local drops={[7]=up,[4]=nonGear};GetLootSlotLink=function(slot) return drops[slot] end
local scans=A.Services.Inventory.scans;M.Event('LOOT_OPENED');M.Flush()
check(T.badges[LootButton1] and T.badges[LootButton1].text:GetText():find('↑ EP',1,true),'automatic upgrade marker on the actual loot slot')
check(T.badges[LootButton2]==nil,'junk gets no upgrade marker')
check(A.Services.Inventory.scans==scans,'loot markers do not rescan every bag')
LootButton1.slot=4;LootFrame_Update();check(not T.badges[LootButton1]:IsShown() and nativeUpdates>0,'scroll/update hook clears recycled row and preserves native update')
LootButton1.slot=7;M.Event('LOOT_SLOT_CHANGED');M.Flush();check(T.badges[LootButton1]:IsShown(),'loot-slot changes refresh marker')
local recycled=CreateFrame('Frame',nil,UIParent);recycled.GetSlotIndex=function() return 7 end
local updateCount=0;LootFrame={ScrollBox={ForEachFrame=function(_,fn) fn(recycled) end,Update=function() updateCount=updateCount+1 end}}
T.Init();LootFrame.ScrollBox:Update()
check(T.badges[recycled] and T.badges[recycled]:IsShown() and updateCount==1,'modern ScrollBox row and native update supported')
M.Event('LOOT_CLOSED');M.Flush();check(not T.badges[LootButton1]:IsShown() and not T.badges[recycled]:IsShown(),'closing loot hides all markers, including delayed refresh')
GameTooltip:SetHyperlink(up);SlashCmdList.FWC('loot off')
check(not T.Enabled() and not panel:IsShown(),'slash disables overlay immediately')
GameTooltip:SetHyperlink(up);check(not panel:IsShown(),'disabled callbacks leave native tooltip alone')
SlashCmdList.FWC('loot on');check(T.Enabled() and panel:IsShown(),'slash reenables current visible comparison')
local hooksBefore=hookCount;local frames=#M.frames
for i=1,10 do T.Init();GameTooltip:SetHyperlink(up) end
check(hookCount==hooksBefore and #M.frames==frames,'no accumulating hooks or frames on repeated hovers')
SlashCmdList.FWC('settings');M.Layout();local b=A.UI.Supporting.settings.lootIndicators;b:Click()
check(not T.Enabled() and A.db.settings.lootIndicators==false,'settings control saved per character')
b:Click();check(T.Enabled(),'settings enables indicators again')
local originalHook=GameTooltip.HookScript;GameTooltip.HookScript=nil
-- Existing successful hooks remain functional; unsupported new frames are skipped.
local unsupported=CreateFrame('GameTooltip',nil,UIParent);ItemRefTooltip=unsupported;T.Init();T.Watch(unsupported)
check(not T.tooltips[unsupported].panel,'unsupported lifecycle does not create stale content')
GameTooltip.HookScript=originalHook
local badStats=gear[tonumber(up:match('%d+'))].stats;gear[tonumber(up:match('%d+'))].stats={ITEM_MOD_INTELLECT_SHORT='SECRET'};S.Invalidate(nil,true)
check(I.Compare(up).comparisons[1].state=='partial','restricted stats never produce positive overall score')
gear[tonumber(up:match('%d+'))].stats=badStats;S.Invalidate(nil,true)
check(#A.diagnostics==0,'no compatibility errors: '..table.concat(A.diagnostics,'; '))
M.print('PASS loot indicator: '..checks..' checks · '..M.scenario..' · synthetic player/loot APIs')
