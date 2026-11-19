-- Imported facts come from Catalog/public-vendor-slice.json. Player/API responses and
-- malformed/alternative condition graphs below are test controls, not game-data claims.
local M=dofile('tests/wow_mock.lua');local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,msg) end
ForeverWarlockCompanionDB={viewClass='WARLOCK',spec='Affliction',mode='Pre-BiS'}
for line in io.lines('ForeverWarlockCompanion.toc') do if line:match('%.lua$') then
 local path=line:gsub('\\','/');dofile(path)
 if path=='Data/Foundation.lua' then dofile('tests/fixtures/public_foundation.lua') end
end end
M.Event('ADDON_LOADED','ForeverWarlockCompanion');SlashCmdList.FWC('settings');M.Layout()
local A=FWC;local R=A.Services.AcquisitionRequirementsResolver;local O=A.Services.Objectives;local D=A.Data.foundation;local I=A.Services.Inventory
check(D.items[272411].name.value=='Arcanoweave Cloak','real item identity')
check(D.vendorOffers['pix:272411'].additionalCurrencies.value[1].quantity==75,'published price is 75 reals')
check(D.vendorOffers['pix:272411'].goldCostCopper.status=='UNKNOWN','sell price never used as gold purchase price')
check(D.vendors['pix-xizzix'].npcId.status=='UNKNOWN','unpublished NPC ID not invented')
check(D.vendorOffers['pix:272411'].requiredReputationFaction.status=='UNKNOWN','vendor faction is not a reputation requirement')
check(R.Value({status='KNOWN',value=false})==false,'confirmed false not converted to unknown')
local function evaluate(node,amount) return R.Evaluate(node,{current=function() return amount end}) end
local q={op='QUANTITY',metric='item',itemId=226404,amount=75}
check(evaluate(q,nil).status=='unknown','unknown amount not zero')
check(evaluate(q,0).status=='missing' and evaluate(q,0).current==0,'explicit empty wallet known')
check(evaluate(q,75).status=='met','quantity threshold')
check(evaluate({op='ALL',children={q,{op='UNKNOWN'}}},75).status=='unknown','ALL retains unknown requirement')
check(evaluate({op='ANY',children={q,{op='UNKNOWN'}}},75).status=='met','ANY does not require every alternative')
check(evaluate({op='ANY',children={q,{op='UNKNOWN'}}},0).status=='unknown','unresolved alternative stays unknown')
check(evaluate({op='ANY',children={q,{op='QUANTITY',metric='item',amount=100}}},0).status=='missing','ANY all missing')
check(evaluate({op='ANY',children={}},0).status=='unknown','empty ANY is not success')
check(evaluate({op='ALL',children={}},0).status=='unknown','absence of requirements is not proven success')
check(evaluate({op='ALL',confirmedEmpty=true,children={}},0).status=='met','explicit confirmed empty requirement set')
check(R.Evaluate(nil).status=='unknown','malformed condition does not crash')
check(R.Evaluate({op='MANUAL',id='fixture'},{manual={fixture=true}}).status=='met','manual evidence distinct')
local p=A.Services.Persistence.Profile()
-- Simulate the shallow persisted plan the previous addon created, then preserve it.
p.objectives['Pre-BiS:Back:272411']={objectiveId='Pre-BiS:Back:272411',itemId=272411,slot='Back',mode='Pre-BiS',title='Arcanoweave Cloak',steps={{stepId='source',type='ManualAction',title='Pix Xizzix',completionMode='manual',manualCompleted=true}},trackingState='Tracked',sourceType='Other',sourceId='Stranglethorn Vale',priority=2,progress={}}
local o=O.Track(272411,'Back');O.List();M.Layout()
check(o.requirementsVersion==1 and o.sourceType=='Vendor','legacy goal adopts normalized plan')
check(o.legacyAcquisitionSteps[1].manualCompleted and o.legacySourceId=='Stranglethorn Vale','legacy manual data backed up')
check(o.completionState=='Blocked' and O.Next(o).requiredAmount==75,'next action is the real missing currency')
check(O.Next(o).currentAmount==0,'progress comes from actual bag snapshot')
local requiredRep=false;for _,s in ipairs(o.steps) do if s.title:find('reputation rank',1,true) then requiredRep=true end end
check(not requiredRep,'Horde affiliation did not fabricate rep gate')
check(not O.ToggleStep(o,o.steps[#o.steps]),'purchase is ownership evidence, not a fake checkbox')
M.bags[0]={{id=226404,count=40}};I.Scan();O.List()
check(O.Next(o).currentAmount==40 and O.Next(o).requiredAmount==75,'partial currency progress')
A.UI.Tracker.selected=o;A.db.settings.trackerMode='Expanded';A.UI.Tracker.Render();M.Layout()
check(A.UI.Tracker.frame.sourceCredit:IsShown(),'tracker visible attribution for sourced data')
A.UI.SetTab('Progression',{objectiveId=o.objectiveId});M.Layout()
check(A.UI.ObjectivesPanel.frame.info.text:GetText():find('ForeverDB.net',1,true),'source and provenance visible in existing panel')
check(A.UI.ObjectivesPanel.frame.next.text:GetText():find('75',1,true),'next action tied to requirement data')
O.AddManual(o,'Personal route note');O.AddManual(o,'Follow-up note');O.AddDependency(o,'user:2','user:1');O.List()
check(o.steps[#o.steps].blocked,'custom dependencies retained under new plan')
O.ToggleStep(o,o.steps[#o.steps-1]);O.List();check(not o.steps[#o.steps].blocked,'custom prerequisite completion unlocks dependent note')
M.bags[0]={{id=226404,count=75}};I.Scan();O.List()
check(o.completionState=='Unknown','75 reals does not prove unpublished gates satisfied')
check(O.Next(o).type=='UnknownRequirement','missing data is a single explicit condition, not invented quest steps')
check(not O.ToggleStep(o,O.Next(o)),'unknown requirement cannot be marked as verified manually')
-- Merchant API controls: no purchasing function should ever be invoked.
local buys=0;BuyMerchantItem=function() buys=buys+1 end
local originalName=UnitName;UnitName=function(unit) return unit=='npc' and 'Pix Xizzix' or originalName(unit) end
UnitGUID=function() return 'Creature-0-1-2-3-227853-0001' end
local nativePrice,nativeStock,cost,count=0,-1,75,1
GetMoney=function() return 0 end;GetMerchantNumItems=function() return 1 end
GetMerchantItemLink=function() return 'item:272411' end
GetMerchantItemCostInfo=function() return count end
GetMerchantItemCostItem=function() return 123,cost,'item:226404','Tarnished Undermine Real' end
GetMerchantItemInfo=function() return 'Arcanoweave Cloak',123,nativePrice,1,nativeStock,true,true,true end
M.Event('MERCHANT_SHOW');O.List();M.Layout()
local seen=A.Services.MerchantObserver.active[272411]
check(seen.npcId==227853 and seen.goldCostCopper==0,'native GUID and explicit zero price recorded')
check(seen.costsComplete and seen.costs[1].quantity==75,'native extended costs independently recorded')
C_MerchantFrame={GetItemInfo=function() return {price=0,stackCount=1,numAvailable=-1,isPurchasable=true,isUsable=true,hasExtendedCost=true} end};M.Event('MERCHANT_UPDATE');check(A.Services.MerchantObserver.active[272411].goldCostCopper==0,'modern table merchant API capability checked');C_MerchantFrame=nil
check(A.db.vendorObservations['227853:272411']~=nil,'observation retained as evidence')
local named=A.Services.MerchantObserver.active[272411];local storedName=named.vendorName;named.vendorName='Localized fixture name';check(not R.Plan(272411).observation,'unmatched localized name does not fabricate identity');check(R.BindObserved(272411) and R.Plan(272411).observation~=nil,'explicit user NPC binding supports localized names');named.vendorName=storedName
local summary=R.Summary(272411,o.acquisitionMethod)
check(summary:find('Published gold: Unknown',1,true) and summary:find('Current observed price: 0 copper',1,true),'published unknown and effective zero remain distinct')
check(summary:find('Unlimited (observed)',1,true),'unlimited stock preserves native sentinel meaning')
check(o.requirementsStatus=='unknown','merchant observation does not invent reputation/quest absence')
cost=100;M.Event('MERCHANT_UPDATE');O.List()
check(O.Next(o).requiredAmount==100 and O.Next(o).currentAmount==75,'current merchant cost supersedes published historical amount')
M.bags[0]={{id=226404,count=100}};I.Scan();nativeStock=0;M.Event('MERCHANT_UPDATE');O.List()
check(O.Next(o).title:find('stock',1,true) and o.completionState=='Blocked','zero observed stock is a real blocker')
M.Event('MERCHANT_CLOSED');O.List()
check(not R.Plan(272411).observation,'saved effective price/stock is not reused as current after close')
check(not R.Summary(272411):find('Current observed price',1,true),'closed vendor does not imply current discounts')
count=0;nativeStock=-1;M.Event('MERCHANT_SHOW');O.List()
check(not A.Services.MerchantObserver.active[272411].costsComplete,'extended flag with zero returned costs means pending, not free')
local plan=R.Plan(272411);local found75=false
for _,c in ipairs(plan.evaluated.children) do if c.node.metric=='item' and c.required==75 then found75=true end end
check(found75,'pending native costs keep published price as a labeled reference')
M.Event('MERCHANT_CLOSED')
local shared=R.SharedResources({{itemId=272411,objectiveId='a'},{itemId=272411,objectiveId='b'}})
check(shared['item:226404'].required==150 and shared['item:226404'].available==100 and shared['item:226404'].missing==50,'shared resource demand uses one actual wallet')
-- Logic-only alternatives use the real record; no second method is shipped as game data.
local original=D.acquisitions['vendor:272411:pix'];local alt=A.Services.Persistence.Copy(original);alt.acquisitionId='fixture:alternative';alt.conditions={op='ANY',children={{op='QUANTITY',metric='level',amount=1},{op='UNKNOWN'}}};D.acquisitions[alt.acquisitionId]=alt
check(R.Select(o,alt.acquisitionId),'method selection persists')
A.UI.SetTab('Progression',{objectiveId=o.objectiveId});M.Layout();check(A.UI.ObjectivesPanel.frame.methods:IsShown(),'methods exposed when alternatives exist')
local alternativePlan=R.Plan(272411,alt.acquisitionId);local steps=R.Steps(alternativePlan,A.Data.items[272411],false);local group
for _,s in ipairs(steps) do if s.type=='RequirementAlternatives' then group=s end end
check(group~=nil and group.completed,'ANY rendered as one logical choice rather than required linear steps')
D.acquisitions[alt.acquisitionId]=nil;R.Select(o,original.acquisitionId)
M.bags[0]={{id=226404,count=25},{id=272411,count=1}};I.Scan();O.List()
check(o.completionState=='Obtained' and o.acquisitionEvidence=='Observed in equipment/bags','actual possession completes goal')
check(D.vendorOffers['pix:272411'].goldCostCopper.status=='UNKNOWN','ownership does not rewrite unverified source facts')
local function encode(x)
 if type(x)=='table' then local out={};for k,v in pairs(x) do out[#out+1]='['..encode(k)..']='..encode(v) end;return '{'..table.concat(out,',')..'}' end
 if type(x)=='string' then return string.format('%q',x) end
 if type(x)=='number' or type(x)=='boolean' then return tostring(x) end;error('invalid SavedVariables type')
end
local tmp=os.tmpname();local file=assert(io.open(tmp,'w'));file:write('return '..encode(A.db));file:close();ForeverWarlockCompanionDB=assert(loadfile(tmp))();os.remove(tmp);A.Services.Persistence.Init();o=O.Find(272411,'Back');O.List()
check(o and o.acquisitionMethod==original.acquisitionId and #o.legacyAcquisitionSteps==1,'reload preserves method and backed-up plan')
check(o.steps[#o.steps-1].manualCompleted,'reload preserves custom checklist')
check(buys==0,'observer/resolver never buy or spend')
-- Offline references are compared only for matching build and base item; no EP granted.
local oldBuild=GetBuildInfo;GetBuildInfo=function() return '1.60.1','70959','Nov 18 2026',16001 end
local oldC,oldInfo,oldStats=C_Item,GetItemInfo,GetItemStats
C_Item={GetItemInfo=function(id) local item=A.Data.items[A.Compat.ItemID(id)];return item and item.name,'item:'..tostring(A.Compat.ItemID(id)),3 end,GetItemStats=function() return nil end};GetItemInfo=nil;GetItemStats=nil
A.Services.ItemStats.Invalidate(nil,true)
local gloves=A.Services.ItemStats.Candidate(A.Data.items[18407]);local dream=A.Services.ItemStats.Candidate(A.Data.items[10019])
check(gloves.state=='partial' and gloves.values.ITEM_MOD_DAMAGE_SHADOW_SHORT==33,'real Felcloth offline reference contains school damage')
check(dream.state=='partial' and dream.values.ITEM_MOD_SPELL_POWER_SHORT==18,'real Dreamweave reference loaded')
check(select(2,A.Services.ItemStats.Value(gloves,'ITEM_MOD_DAMAGE_SHADOW_SHORT'))=='reference','reference distinguished from client-confirmed data')
check(A.Services.ItemStats.Display(gloves,'ITEM_MOD_DAMAGE_SHADOW_SHORT')=='33 *','offline values visibly tagged')
check(not A.Services.Planner.SlotScore('Hands',A.Data.items[18407]),'partial/reference stats cannot receive fictitious EP')
local oldConfidence=D.items[18407].sourceConfidence;D.items[18407].sourceConfidence='legacy_classic';check(not A.Services.ItemStats.Candidate(A.Data.items[18407]).fallbackSource,'legacy confidence is never promoted to Forever reference');D.items[18407].sourceConfidence=oldConfidence
local modified=A.Services.Persistence.Copy(A.Data.items[18407]);modified.link='item:18407:1234';check(not A.Services.ItemStats.Candidate(modified).fallbackSource,'base stats do not overwrite modified instances')
C_Item.GetItemStats=function() return {ITEM_MOD_STAMINA_SHORT=0} end;A.Services.ItemStats.Invalidate(nil,true)
check(A.Services.ItemStats.Candidate(A.Data.items[18407]).values.ITEM_MOD_STAMINA_SHORT==0,'explicit client zero overrides offline 9')
GetBuildInfo=oldBuild;C_Item=oldC;GetItemInfo=oldInfo;GetItemStats=oldStats;A.Services.ItemStats.Invalidate(nil,true)
for _,route in ipairs({'Dashboard','Stats','Character & Gear','Item Details','Progression','Settings'}) do A.UI.SetTab(route);M.Layout() end
check(#A.diagnostics==0,'all screens still run: '..table.concat(A.diagnostics,'; '))
M.print('PASS data foundation: '..checks..' checks · '..M.scenario..' · published records + simulated player state')
