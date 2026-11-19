-- Real normalized API records in Catalog/api-vendor-slice.json; player/merchant
-- responses here are test controls. These tests do not certify the WoW client.
local M=dofile('tests/wow_mock.lua');local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,msg) end
ForeverWarlockCompanionDB={viewClass='WARLOCK',spec='Affliction',mode='Pre-BiS'}
for line in io.lines('ForeverWarlockCompanion.toc') do if line:match('%.lua$') then dofile((line:gsub('\\','/'))) end end
M.Event('ADDON_LOADED','ForeverWarlockCompanion');SlashCmdList.FWC('settings');M.Layout()
local A=FWC;local R=A.Services.AcquisitionRequirementsResolver;local O=A.Services.Objectives;local D=A.Data.foundation;local I=A.Services.Inventory
local offer=D.vendorOffers['pix:272411'];local cost=offer.additionalCurrencies.value[1]
check(cost.kind=='currency' and cost.currencyId==3469 and cost.itemId==nil,'actual API currency identity, no bag item substitution')
check(offer.goldCostCopper.status=='KNOWN' and offer.goldCostCopper.value==0,'explicit published zero purchase price')
check(D.vendors['pix-xizzix'].npcId.value==227853,'API NPC identity')
check(D.vendors['pix-xizzix'].coordinates.value.x==28.5,'API coordinates')
check(offer.requiredReputationFaction.status=='UNKNOWN' and offer.questPrerequisites.status=='UNKNOWN','unpublished gates unknown')
check(not offer.requirementsComplete,'authentication does not claim complete data')
local balance=40;C_CurrencyInfo={GetCurrencyInfo=function(id) if id==3469 then return {quantity=balance} end end}
GetMoney=function() return 0 end
M.bags[0]={{id=226404,count=999}};I.Scan()
local profile=A.Services.Persistence.Profile()
profile.objectives['Pre-BiS:Back:272411']={objectiveId='Pre-BiS:Back:272411',itemId=272411,slot='Back',mode='Pre-BiS',title='Arcanoweave Cloak',requirementsVersion=1,acquisitionMethod='vendor:272411:pix',trackingState='Tracked',sourceType='Vendor',priority=2,progress={},
 steps={{stepId='old:cost',type='AcquisitionQuantity',title='Old bag-item cost',requiredAmount=75},{stepId='user:1',type='ManualAction',title='Personal note',completionMode='manual',manualCompleted=true}}}
local o=O.Track(272411,'Back');O.List()
check(O.Next(o).currentAmount==40 and O.Next(o).requiredAmount==75,'progress reads currency wallet')
check(o.completionState=='Blocked','insufficient currency blocks')
check(o.steps[#o.steps].title=='Personal note' and o.steps[#o.steps].completed,'same stable goal preserves user note')
local oldCost=false;for _,step in ipairs(o.steps) do if step.title=='Old bag-item cost' then oldCost=true end end
check(not oldCost,'persisted public cost replaced by API requirement')
local shared=R.SharedResources({{itemId=272411,objectiveId='a'},{itemId=272411,objectiveId='b'}})
check(shared['currency:3469'].required==150 and shared['currency:3469'].missing==110,'shared resources use one actual currency wallet')
check(shared['item:226404']==nil,'bag token does not masquerade as currency')
local provider=C_CurrencyInfo;C_CurrencyInfo=nil;O.List()
local currencyUnknown=false;for _,step in ipairs(o.steps) do if step.requiredAmount==75 then currencyUnknown=step.currentAmount==nil and step.requirementStatus=='unknown' end end
check(currencyUnknown,'unavailable currency API remains unknown, not zero or item count')
C_CurrencyInfo=provider;balance=0;O.List();check(O.Next(o).currentAmount==0,'actual wallet zero retained')
balance=75;O.List();check(o.completionState=='Unknown','wallet threshold does not prove unpublished gates')
local summary=R.Summary(272411)
check(summary:find('Published gold: 0 copper per purchase',1,true),'published zero is visible')
check(summary:find('28.5, 75.8',1,true),'published coordinates visible')
check(summary:find('current stock not checked',1,true),'published unlimited offer is not current stock')
check(summary:find('https://foreverdb.net',1,true),'visible source link despite optional API attribution metadata')
local originalName=UnitName;UnitName=function(unit) return unit=='npc' and 'Localized vendor control' or originalName(unit) end
local npc=227853;UnitGUID=function() return 'Creature-0-1-2-3-'..npc..'-0001' end
GetMerchantNumItems=function() return 1 end;GetMerchantItemLink=function() return 'item:272411' end
local currentCost,stock=100,-1
GetMerchantItemInfo=function() return 'Arcanoweave Cloak',123,0,1,stock,true,true,true end
GetMerchantItemCostInfo=function() return 1 end
GetMerchantItemCostItem=function() return 123,currentCost,'currency:3469','Tarnished Undermine Real' end
local buys=0;BuyMerchantItem=function() buys=buys+1 end
M.Event('MERCHANT_SHOW');O.List()
check(R.Plan(272411).observation~=nil,'published NPC ID matches localized merchant independently of name')
check(O.Next(o).requiredAmount==100 and O.Next(o).currentAmount==75,'live currency cost overrides published cost')
balance=100;stock=0;M.Event('MERCHANT_UPDATE');O.List()
check(o.completionState=='Blocked' and O.Next(o).title:find('stock',1,true),'live sold-out stock blocks')
M.Event('MERCHANT_CLOSED');O.List();check(not R.Plan(272411).observation,'observation expires on close')
local publishedCost=false;for _,c in ipairs(R.Plan(272411).evaluated.children) do if c.node.metric=='currency' and c.required==75 then publishedCost=true end end
check(publishedCost,'close returns to labeled published currency cost')
npc=227854;M.Event('MERCHANT_SHOW');check(not R.Plan(272411).observation,'wrong GUID cannot override published source');M.Event('MERCHANT_CLOSED')
check(buys==0,'no automated spending')
A.UI.Tracker.selected=o;A.db.settings.trackerMode='Expanded';A.UI.Tracker.Render();M.Layout()
check(A.UI.Tracker.frame.sourceCredit:IsShown() and A.UI.Tracker.frame.sourceCredit:GetText():find('https://foreverdb.net',1,true),'tracker visible credit')
A.UI.SetTab('Progression',{objectiveId=o.objectiveId});M.Layout()
check(A.UI.ObjectivesPanel.frame.info.text:GetText():find('Data from ForeverDB.net',1,true),'objectives source credit')
A.UI.SetTab('Item Details',{slot='Back',itemId=272411});M.Layout()
check(A.UI.ItemDetails.page.source.text:GetText():find('https://foreverdb.net',1,true),'item acquisition source credit')
-- Authenticated publisher stats remain references, native instance values retain priority.
local oldBuild=GetBuildInfo;GetBuildInfo=function() return '1.60.1','70959','Nov 18 2026',16001 end
local oldC,oldInfo,oldStats=C_Item,GetItemInfo,GetItemStats
C_Item={GetItemInfo=function(id) local item=A.Data.items[A.Compat.ItemID(id)];return item and item.name,'item:'..tostring(A.Compat.ItemID(id)),3 end,GetItemStats=function() return nil end};GetItemInfo=nil;GetItemStats=nil
local S=A.Services.ItemStats;S.Invalidate(nil,true)
local gloves=S.Candidate(A.Data.items[18407]);local dream=S.Candidate(A.Data.items[10019]);local cloak=S.Candidate(A.Data.items[272411])
check(gloves.values.ITEM_MOD_DAMAGE_SHADOW_SHORT==33 and dream.values.ITEM_MOD_SPELL_POWER_SHORT==18,'API glove stats distinct')
check(select(2,S.Value(gloves,'ITEM_MOD_DAMAGE_SHADOW_SHORT'))=='reference','API access is not local client verification')
check(cloak.values.ITEM_MOD_HIT_RATING_SHORT==nil,'unknown Hit unit not coerced into rating')
check(S.Lines(gloves):find('https://foreverdb.net',1,true),'offline stat credit visible')
check(not A.Services.Planner.SlotScore('Hands',A.Data.items[18407]),'no EP from partial publisher reference')
A.UI.SetTab('Item Details',{slot='Hands',itemId=18407});M.Layout()
check(A.UI.ItemDetails.page.stats.text:GetText():find('https://foreverdb.net',1,true),'item stats source credit')
A.UI.selectedSlot='Hands';A.UI.StatsPanel.candidate=18407;A.UI.SetTab('Stats');M.Layout()
check(A.UI.StatsPanel.frame.result:GetText():find('https://foreverdb.net',1,true),'comparison source credit')
C_Item.GetItemStats=function() return {ITEM_MOD_STAMINA_SHORT=0} end;S.Invalidate(nil,true)
check(S.Candidate(A.Data.items[18407]).values.ITEM_MOD_STAMINA_SHORT==0,'explicit client zero takes priority')
GetBuildInfo=function() return '1.60.1','99999','control',16001 end;S.Invalidate(nil,true)
check(not S.Candidate(A.Data.items[18407]).fallbackSource,'mismatched build does not use offline stats')
GetBuildInfo=oldBuild;C_Item=oldC;GetItemInfo=oldInfo;GetItemStats=oldStats;S.Invalidate(nil,true)
M.bags[0]={{id=272411,count=1}};I.Scan();O.List()
check(o.completionState=='Obtained','possession completes goal independently of missing source gates')
check(offer.requiredReputationFaction.status=='UNKNOWN','ownership does not rewrite unknown gates')
for _,route in ipairs({'Dashboard','Stats','Character & Gear','Item Details','Progression','Settings'}) do A.UI.SetTab(route);M.Layout() end
check(#A.diagnostics==0,'screens remain compatible: '..table.concat(A.diagnostics,'; '))
M.print('PASS authenticated foundation: '..checks..' checks · '..M.scenario..' · API records + simulated player state')
