-- Regression fixtures, not assertions about real Forever itemization.
local M=dofile('tests/wow_mock.lua');local count=0
local function check(ok,msg) count=count+1;assert(ok,msg) end
ForeverWarlockCompanionDB={viewClass='WARLOCK',spec='Affliction',mode='Pre-BiS'}
for line in io.lines('ForeverWarlockCompanion.toc') do if line:match('%.lua$') then dofile((line:gsub('\\','/'))) end end
M.Event('ADDON_LOADED','ForeverWarlockCompanion');SlashCmdList.FWC('stats');M.Layout()
local A=FWC;local S=A.Services.ItemStats;local P=A.Services.Persistence
local gloves=A.Data.items[18407];check(gloves.name=='Felcloth Gloves','regression uses real imported item identity')
check(gloves.provenance=='imported_unranked' and gloves.sourceStats.shadow_damage==33,'guide exists but is not client verification')
local oldC,oldInfo,oldStats=C_Item,GetItemInfo,GetItemStats
local base='item:18407';local enchanted='|cff0070dd|Hitem:18407:1234:0:0:0:0:42|h[Felcloth Gloves]|h|r'
local second='item:18407:5678:0:0:0:0:73'
local pending,throws,empty,identityError,identityWrong=false,false,false,false,false
local raw={ITEM_MOD_STAMINA_SHORT=9,RESISTANCE0_NAME=55,ITEM_MOD_DAMAGE_SHADOW_SHORT=33,ITEM_MOD_INTELLECT_SHORT=0}
local readLinks,requests={},0
local function info(input)
 if identityError then error('fixture identity failure') end
 local id=A.Compat.ItemID(input);if pending then return end
 if id==18407 then return 'Felcloth Gloves',identityWrong and 'item:22267' or base,3,60,1,'Armor','Cloth',1,'INVTYPE_HAND','Interface\\Icons\\inv_gauntlets_19' end
 local item=A.Data.items[id];if item then return item.name,'item:'..id,item.quality,60,1,'Armor','Cloth',1,'INVTYPE_HEAD',item.icon end
end
local function getStats(link)
 readLinks[#readLinks+1]=link
 if throws then error('fixture stat read failure') end
 if pending then return nil end;if empty then return {} end
 if link==enchanted then return {ITEM_MOD_STAMINA_SHORT=14,RESISTANCE0_NAME=55,ITEM_MOD_DAMAGE_SHADOW_SHORT=33,ITEM_MOD_INTELLECT_SHORT=0} end
 if link==second then return {ITEM_MOD_STAMINA_SHORT=20} end
 return raw
end
local function install()
 if M.scenario=='legacy' then C_Item=nil;GetItemInfo=info;GetItemStats=getStats
 else C_Item={GetItemInfo=info,GetItemStats=getStats,RequestLoadItemDataByID=function() requests=requests+1 end,IsItemDataCachedByID=function() return not pending end};GetItemInfo=nil;GetItemStats=nil end
 S.Invalidate(nil,true)
end
install()
local originalID,originalLink=GetInventoryItemID,GetInventoryItemLink
GetInventoryItemID=function(_,slot) if slot==10 then return 18407 end;return originalID('player',slot) end
GetInventoryItemLink=function(_,slot) if slot==10 then return enchanted end;return originalLink('player',slot) end
A.Services.Inventory.Scan()
local eq=S.Equipped('Hands');local target=S.Candidate(gloves)
check(eq.itemId==18407 and eq.name=='Felcloth Gloves','equipped identity remains its real ID/name')
check(eq.link==enchanted and A.Compat.ItemInfo(enchanted).link==enchanted,'canonical GetItemInfo result cannot replace instance link')
check(readLinks[#readLinks-1]==enchanted and target.link==base,'stats receive independent equipped and candidate links')
check(S.Value(eq,'ITEM_MOD_STAMINA_SHORT')==14 and S.Value(target,'ITEM_MOD_STAMINA_SHORT')==9,'candidate never copies equipped values')
check(S.Delta(eq,target,'ITEM_MOD_STAMINA_SHORT')==-5,'valid per-stat delta uses exact variant')
local other=S.Read(second,{kind='equipped',itemId=18407})
check(other~=eq and S.Value(other,'ITEM_MOD_STAMINA_SHORT')==20,'same ID with another suffix/enchant has distinct cache entry')
check(S.Read(base,{kind='candidate',itemId=99999}).state=='error','mismatched expected ID cannot reuse valid cached identity')
local value,state=S.Value(target,'ITEM_MOD_INTELLECT_SHORT');check(value==0 and state=='zero','explicit zero confirmed')
value,state=S.Value(target,'ITEM_MOD_STRENGTH_SHORT');check(value==nil and state=='absent','missing attribute is not zero')
check(S.Display(target,'ITEM_MOD_STRENGTH_SHORT')=='Not present','absent attribute displayed explicitly')
local difference,reason=S.Delta(target,other,'ITEM_MOD_INTELLECT_SHORT');check(difference==nil and reason=='Not comparable','absent side cannot produce numeric delta')
A.UI.SetTab('Stats');A.UI.selectedSlot='Hands';A.UI.StatsPanel.candidate=18407;A.UI.StatsPanel.Render();M.Layout()
local cells={};for _,row in ipairs(A.UI.StatsPanel.frame.rows) do cells[row.key]=row.cells end
check(cells.ITEM_MOD_STAMINA_SHORT[2]:GetText()=='14' and cells.ITEM_MOD_STAMINA_SHORT[3]:GetText()=='9','UI exposes correct equipped and candidate values')
check(cells.ITEM_MOD_STRENGTH_SHORT[2]:GetText()=='Not present','UI regression: no fabricated absent zero')
check(cells.ITEM_MOD_INTELLECT_SHORT[2]:GetText()=='0','UI distinguishes actual zero')
check(cells.ITEM_MOD_DAMAGE_SHADOW_SHORT[3]:GetText()=='33','Felcloth shadow attribute visible when client exposes it')
local f=A.UI.ItemSelector.frame.details;A.UI.ItemDetails.Render(f,'Hands',gloves)
check(f.stats.text:GetText():find('Shadow damage: 33',1,true),'item detail uses same client reader')
raw={RESISTANCE0_NAME=55};S.Invalidate(nil,true);target=S.Candidate(gloves)
check(S.Display(target,'ITEM_MOD_DAMAGE_SHADOW_SHORT')=='Not present','partial client table cannot be repaired by unverified guide')
A.UI.ItemDetails.Render(f,'Hands',gloves)
check(not f.stats.text:GetText():find('Shadow damage: 33',1,true),'unverified source stat not asserted in main detail')
check(f.advanced.text:GetText():find('unverified',1,true),'guide provenance remains visible in Advanced')
check(not A.Services.Planner.SlotScore('Hands',gloves),'insufficient individual data blocks rating')
raw={ITEM_MOD_SPELL_HIT_RATING_SHORT=7,ITEM_MOD_SPELL_CRIT_RATING_SHORT=4,ITEM_MOD_HIT_RATING_SHORT=3};S.Invalidate(nil,true);target=S.Candidate(gloves)
check(S.Value(target,'ITEM_MOD_HIT_SPELL_RATING_SHORT')==7,'equivalent spelling alias normalized')
check(S.Value(target,'ITEM_MOD_CRIT_SPELL_RATING_SHORT')==4,'crit spelling alias normalized')
check(S.Value(target,'ITEM_MOD_HIT_RATING_SHORT')==3 and S.Value(target,'SPELL_HIT_PERCENT')==nil,'generic rating and percent never conflated')
check(S.Weights({ITEM_MOD_SPELL_HIT_RATING_SHORT=1}).ITEM_MOD_HIT_SPELL_RATING_SHORT==1,'existing equivalent weight spelling remains usable')
check(not S.Weights({ITEM_MOD_SPELL_HIT_RATING_SHORT=1,ITEM_MOD_HIT_SPELL_RATING_SHORT=2}),'conflicting weight aliases rejected')
raw={ITEM_MOD_SHADOW_DAMAGE_SHORT=33,ITEM_MOD_SPELL_DAMAGE_DONE=11};S.Invalidate(nil,true);target=S.Candidate(gloves)
check(S.Value(target,'ITEM_MOD_DAMAGE_SHADOW_SHORT')==33 and S.Value(target,'ITEM_MOD_SPELL_DAMAGE_DONE_SHORT')==11 and S.Value(target,'ITEM_MOD_SPELL_POWER_SHORT')==nil,'school damage and offensive spell damage remain separate from spell power')
raw={ITEM_MOD_SPELL_HIT_RATING_SHORT=7,ITEM_MOD_HIT_SPELL_RATING_SHORT=8};S.Invalidate(nil,true);target=S.Candidate(gloves)
value,state=S.Value(target,'ITEM_MOD_HIT_SPELL_RATING_SHORT');check(value==nil and state=='error' and target.state=='partial','conflicting aliases produce read error')
raw={ITEM_MOD_STAMINA_SHORT=9,ITEM_MOD_INTELLECT_SHORT='SECRET'};S.Invalidate(nil,true);target=S.Candidate(gloves)
check(S.Value(target,'ITEM_MOD_STAMINA_SHORT')==9 and select(2,S.Value(target,'ITEM_MOD_INTELLECT_SHORT'))=='error','readable values survive restricted peer attribute')
check(not A.Services.Planner.SlotScore('Hands',gloves),'partial/error result cannot receive EP')
raw={ITEM_MOD_INTELLECT_SHORT=0/0};S.Invalidate(nil,true);check(S.Candidate(gloves).state=='partial','NaN rejected')
raw={ITEM_MOD_INTELLECT_SHORT=math.huge};S.Invalidate(nil,true);check(S.Candidate(gloves).state=='partial','infinite stat rejected')
empty=true;S.Invalidate(nil,true);target=S.Candidate(gloves)
check(target.state=='empty' and S.Display(target,'ITEM_MOD_STAMINA_SHORT')=='Not present','cached empty table is explicit API absence, not all zeros')
empty=false;pending=true;S.Invalidate(nil,true);local requestBefore=requests;target=S.Candidate(gloves)
check(target.state=='pending' and S.Display(target,'ITEM_MOD_STAMINA_SHORT')=='Data pending','unloaded item receives no fake stat')
check(not A.Services.Planner.SlotScore('Hands',gloves),'unloaded candidate receives no rating')
for i=1,15 do S.Candidate(gloves) end
check(requests-requestBefore<=1,'load requests coalesced across repeated UI reads')
pending=false;raw={ITEM_MOD_STAMINA_SHORT=9};M.Event('ITEM_DATA_LOAD_RESULT',18407,true);M.Advance()
check(S.Candidate(gloves).state=='confirmed','load event invalidates pending cache')
pending=true;S.Invalidate(18407,true);S.Candidate(gloves);S.Loaded(18407,false,false);check(S.Candidate(gloves).state=='error','failed load with no identity/link remains error');pending=false
S.Invalidate(18407,true);S.Candidate(gloves);M.Event('ITEM_DATA_LOAD_RESULT',18407,false);M.Advance()
check(S.Candidate(gloves).state=='error','failed load event distinct from pending and zero')
S.Invalidate(18407,true);check(S.Candidate(gloves).state=='confirmed','manual retry clears failure state')
throws=true;S.Invalidate(nil,true);target=S.Candidate(gloves)
check(target.state=='error' and S.Display(target,'ITEM_MOD_STAMINA_SHORT')=='Read error','API throw is explicit read error')
throws=false;identityError=true;S.Invalidate(nil,true);check(S.Candidate(gloves).state=='error','identity API error is not pending')
identityError=false;identityWrong=true;S.Invalidate(nil,true);check(S.Read(enchanted,{kind='equipped',itemId=18407}).state=='error','wrong identity link rejected even if supplied instance link is valid');identityWrong=false
local modern=C_Item;C_Item=nil;GetItemInfo=info;GetItemStats=getStats;S.Invalidate(nil,true)
check(S.Candidate(gloves).source=='GetItemStats','available legacy API used when modern API absent')
GetItemStats=nil;S.Invalidate(nil,true);check(S.Candidate(gloves).state=='unavailable','missing statistics API explicit')
C_Item=modern;GetItemInfo=info;GetItemStats=getStats
-- Only a versioned, verified base-variant map may supply a fallback.
pending=true;S.Invalidate(nil,true)
local verified={id=18407,verifiedStats={variant='base',build='70790',source='fixture verification',values={ITEM_MOD_STAMINA_SHORT=9}}}
check(S.Candidate(verified).source:find('verified catalog',1,true),'explicit verified matching-build base fallback supported')
verified.verifiedStats.build='other';check(S.Candidate(verified).state=='pending','build mismatch disallows fallback')
verified.verifiedStats.build='70790';verified.link=enchanted;check(S.Candidate(verified).source:find('verified catalog',1,true)==nil,'base catalog cannot override modified instance')
pending=false;S.Invalidate(nil,true)
-- ContinueOnItemLoad is capability-checked, and requests only data, not another instance's stats.
local callback,usedInput;Item={CreateFromItemLink=function(_,link) usedInput=link;return {ContinueOnItemLoad=function(_,fn) callback=fn end} end}
S.Request(enchanted);check(usedInput==enchanted and type(callback)=='function','Item continuation uses supplied full link')
local signal=false;local oldNotify=S.OnDataAvailable;S.OnDataAvailable=function() signal=true end;callback()
check(signal and S.requests[18407].state=='loaded','continuation invalidates and schedules refresh')
S.OnDataAvailable=oldNotify;Item=nil;S.Invalidate(nil,true)
local beforeLinkC,beforeLinkInfo=C_Item,GetItemInfo
C_Item={GetItemInfo=function() return nil end,GetItemStats=getStats};GetItemInfo=nil
Item={CreateFromItemID=function(_,id) return {GetItemLink=function() return 'item:'..id end,ContinueOnItemLoad=function(_,fn) fn() end} end}
S.Invalidate(nil,true);local viaObject=S.Candidate(gloves)
check(viaObject.link==base and viaObject.state=='confirmed','Item:GetItemLink supplies candidate link when direct item info is pending')
C_Item=beforeLinkC;GetItemInfo=beforeLinkInfo;Item=nil;S.Invalidate(nil,true)
-- Equipped item absent from catalog AND bags must still be refreshed on data events.
local foreign='item:990001:1234';A.Services.Inventory.snapshot.equipped.Head={id=990001,link=foreign,checked=true}
local foreignRecord=S.Equipped('Head');M.Event('GET_ITEM_INFO_RECEIVED',990001,true);M.Advance()
check(S.Read(foreign,{kind='equipped',itemId=990001})~=foreignRecord,'foreign equipped item event invalidates individual cache')
A.Services.Inventory.Scan()
local oldLink=A.Services.Inventory.snapshot.equipped.Hands.link;A.Services.Inventory.snapshot.equipped.Hands.link=nil;S.Invalidate(nil,true)
check(S.Equipped('Hands').state~='confirmed','equipped ID without full instance link cannot get base stats')
A.Services.Inventory.snapshot.equipped.Hands.link=oldLink
A.UI.SetTab('Settings');local settings=A.UI.Supporting.settings
check(not A.db.settings.itemStatDiagnostics,'diagnostics off by default')
S.Invalidate(nil,true);S.Candidate(gloves);check(not A.db.itemStatDiagnostics or #A.db.itemStatDiagnostics==0,'no traces while disabled')
settings.itemDiagnostics:Click();S.Invalidate(nil,true);S.Candidate(gloves)
check(A.db.settings.itemStatDiagnostics and #A.db.itemStatDiagnostics>0,'Settings enables item diagnostics')
local logs=#A.db.itemStatDiagnostics;for i=1,20 do S.Candidate(gloves) end;check(#A.db.itemStatDiagnostics==logs,'diagnostics deduplicate stable reads')
check(S.Report():find('18407',1,true) and S.Report():find('GetItemStats',1,true),'report includes actual identity and reader provenance')
settings.clearItemDiagnostics:Click();check(#A.db.itemStatDiagnostics==0,'diagnostic log can be cleared')
settings.inspectGloves:Click();check(#A.db.itemStatDiagnostics>0,'one-click gloves diagnostic captures regression item')
local saved=A.db.itemStatDiagnostics;P.Init();check(A.db.itemStatDiagnostics==saved,'diagnostics retained through DB init')
settings.itemDiagnostics:Click();check(not A.db.settings.itemStatDiagnostics,'diagnostics can be disabled')
C_Item=oldC;GetItemInfo=oldInfo;GetItemStats=oldStats;GetInventoryItemID=originalID;GetInventoryItemLink=originalLink
S.Invalidate(nil,true);A.Services.Inventory.Scan()
for _,route in ipairs({'Stats','Character & Gear','Item Details','Settings','Dashboard','Talents','Progression'}) do A.UI.SetTab(route);M.Layout() end
check(#A.diagnostics==0,'no hidden Lua errors after phase-1 flows: '..table.concat(A.diagnostics,'; '))
M.print('PASS phase 1 stats: '..count..' checks · '..M.scenario..' · fixture APIs only')
