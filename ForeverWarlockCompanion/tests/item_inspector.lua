local M=dofile('tests/inspector_fixture.lua');local A=M.Load();local n=0
local function check(ok,msg) n=n+1;assert(ok,msg) end
local U=A.Services.UpgradeComparison;local P=A.Services.Persistence.Profile();local item=A.Data.items[279269]
local function reset() A.Services.ItemStats.Invalidate(nil,true) end
local function bounds(f) local x,w=f:Bounds(true);local y,h=f:Bounds(false);return x,y,w,h end
local function inside(f,p) local x,y,w,h=bounds(f);local a,b,c,d=bounds(p);return w>0 and h>0 and x>=a-.1 and y>=b-.1 and x+w<=a+c+.1 and y+h<=b+d+.1 end
local function apart(f,p) local x,y,w,h=bounds(f);local a,b,c,d=bounds(p);return x+w<=a+.1 or a+c<=x+.1 or y+h<=b+.1 or b+d<=y+.1 end
local model=A.Services.ItemInspector.Model('Back',item)
check(model.record.itemLevel==65 and model.record.qualityId==4 and model.record.requiredLevel==60,'real published identity')
local stats={};for _,s in ipairs(model.stats) do stats[s.key]=s.value end
check(stats.ITEM_MOD_DAMAGE_SHADOW_SHORT==15 and stats.ITEM_MOD_CRIT_RATING_SHORT==14 and stats.ITEM_MOD_STAMINA_SHORT==16,'real published Fel Cape key stats; crit not divided into percent')
check(model.recipe.spellId==1306543 and model.recipe.skill.orange==300,'real tailoring skill and spell')
check(model.recipe.learnedFrom.recipeItems[1].itemId==279318,'real pattern identity')
local mats=model.materials
check(#mats==3 and mats[1].itemId==274030 and mats[1].required==1 and mats[2].required==1 and mats[3].required==5,'correct three published recipe quantities')
check(mats[1].available==0 and mats[1].missing==1 and mats[2].complete and mats[3].available==2 and mats[3].missing==3,'simulated bag counts and shortages')
check(model.costs[1].kind=='crafting' and model.costs[2].kind=='purchase' and model.costs[3].kind=='sell' and model.costs[4].kind=='market','four distinct cost categories')
check(model.costs[3].value=='0g 99s 99c' and model.costs[2].value~='0g 99s 99c','sell price is never a purchase price')
check(model.affinity.behindPercent==22 and not model.comparison.score,'guide affinity never becomes personal EP')
local r=U.ForSlot('Back',item);local changes={};for _,d in ipairs(r.deltas) do changes[d.key]=d.delta end
check(r.complete and changes.ITEM_MOD_STAMINA_SHORT==15 and changes.ITEM_MOD_DAMAGE_SHADOW_SHORT==15 and changes.ITEM_MOD_CRIT_RATING_SHORT==14 and changes.ITEM_MOD_DAMAGE_FROST_SHORT==-11 and changes.RESISTANCE0_NAME==-20,'numeric client comparison against actual worn cloak')
check(M.deltaLinks[1]==M.worn and M.deltaLinks[2]==M.cape,'full equipped instance passed to native comparison')
local calls=M.deltaCalls;U.ForSlot('Back',item);check(M.deltaCalls==calls,'comparison cache avoids repeating native pair calculation')
P.epWeights={ITEM_MOD_STAMINA_SHORT=.2,ITEM_MOD_DAMAGE_SHADOW_SHORT=1,ITEM_MOD_CRIT_RATING_SHORT=.4,ITEM_MOD_DAMAGE_FROST_SHORT=.5}
r=U.ForSlot('Back',item)
check(r.score and math.abs(r.score.before-5.7)<1e-8 and math.abs(r.score.after-23.8)<1e-8 and math.abs(r.score.absolute-18.1)<1e-8,'weighted delta 18.1 from explicitly configured profile')
check(U.Rating(r)=='UPGRADE','valid positive EP indicator')
P.epWeights.ITEM_MOD_DAMAGE_SHADOW_SHORT=-1;r=U.ForSlot('Back',item);check(U.Rating(r)=='DOWNGRADE','valid negative EP indicator')
P.epWeights.ITEM_MOD_DAMAGE_SHADOW_SHORT=1
A.db.settings.upgradeEqualThreshold=20;check(U.Rating(U.ForSlot('Back',item))=='NEAR EQUAL','configurable absolute EP threshold');A.db.settings.upgradeEqualThreshold=.5
P.epWeights.ITEM_MOD_CRIT_RATING_SHORT=nil;check(not U.ForSlot('Back',item).score and U.Rating(U.ForSlot('Back',item))=='UNKNOWN','missing mandatory weight does not produce rating')
P.epWeights.ITEM_MOD_CRIT_RATING_SHORT=.4
M.canUse=false;check(not U.ForSlot('Back',item).score,'ineligible candidate never green');M.canUse=true
local mismatched=U.Compare(M.worn,M.cape,'MAGE','Frost',P.epWeights);check(not mismatched.score,'wrong character class cannot score')
M.noDelta=true;reset();r=U.ForSlot('Back',item);check(not r.complete and not r.score and #r.unknown>0,'unexposed quantities without pairwise evidence remain unknown')
M.noDelta=false;reset()
M.candidateStats.ITEM_MOD_SHADOW_DAMAGE_SHORT=15;reset();r=U.ForSlot('Back',item)
check(r.score and math.abs(r.score.absolute-18.1)<1e-8,'equivalent stable school-damage aliases counted once')
M.candidateStats.ITEM_MOD_SHADOW_DAMAGE_SHORT=nil;reset()
local overlap=U.Compare(M.worn,M.cape,'WARLOCK','Affliction',P.epWeights,{overlappingStats={{'ITEM_MOD_DAMAGE_SHADOW_SHORT','ITEM_MOD_CRIT_RATING_SHORT'}}})
check(not overlap.score and overlap.warnings[1]=='overlapping-stat-contributions','explicit overlapping contributions cannot enter EP twice')
local loot=A.Services.LootComparison.Compare(M.cape).comparisons[1]
check(loot.score and math.abs(loot.score.absolute-r.score.absolute)<1e-8 and #loot.deltas==#r.deltas,'tooltip and inspector consume same comparison result')
local tip=A.UI.LootIndicator.Lines(A.Services.LootComparison.Compare(M.cape))
check(tip:find('Item Improvement',1,true) and not tip:find('Compared with',1,true),'hover reduced to improvement indicator')
check(tip:find('+18.1 GS/EP',1,true) and tip:find('+317.5%',1,true),'hover numeric score and percent match shared calculation')
local oldWorn=M.worn;M.worn=M.cape;M.equipped[15]=279269;P.epWeights.ITEM_MOD_DAMAGE_FROST_SHORT=0;reset()
local same=A.Services.LootComparison.Compare(M.cape).comparisons[1]
check(same.complete and same.score and same.score.absolute==0,'same Fel Cape uses shared calculation and confirmed zero EP')
check(U.Rating(U.ForSlot('Back',item))=='NEAR EQUAL','same pilot item has neutral rating with configured weights')
M.worn=oldWorn;M.equipped[15]=910010;P.epWeights.ITEM_MOD_DAMAGE_FROST_SHORT=.5;reset()
P.epWeights={};tip=A.UI.LootIndicator.Lines(A.Services.LootComparison.Compare(M.cape))
check(tip==nil,'unavailable score leaves native hover without extra banner')
M.itemPending=true;reset();model=A.Services.ItemInspector.Model('Back',item)
check(#model.stats==3 and model.publishedStats and not model.comparison.score,'published stat card remains useful while native comparison pending')
M.itemPending=false;reset()
SlashCmdList.FWC('');A.UI.SetTab('Item Details',{slot='Back',itemId=item.id});M.Layout()
local owner=A.UI.ItemDetails.page;local f=owner.inspector
check(owner.inspectorActive and f:IsShown() and not owner.stats:IsShown(),'pilot replaces legacy textual body')
check(f.score:GetText():find('Upgrade score unavailable',1,true),'score-unavailable state visible')
check(not f.advanced:IsShown() and not f.alternativeRows[1]:IsShown(),'advanced and alternatives collapsed initially')
check(owner.pilotCredit.label:GetText():find('https://foreverdb.net',1,true),'permanent visible source link')
for _,width in ipairs({280,360,510}) do
 owner:ClearAllPoints();owner:SetPoint('TOPLEFT',UIParent,'TOPLEFT',20,-20);owner:SetSize(width,860);M.Layout();A.UI.ItemDetails.Render(owner,'Back',item);M.Layout()
 local sections={f.stats,f.comparison,f.source,f.costs,f.affinity,f.alternatives}
 for i,panel in ipairs(sections) do check(inside(panel,owner.scroll.content),'section inside scroll content at width '..width);if i>1 then check(apart(panel,sections[i-1]),'sections do not overlap at '..width) end end
 for i,mat in ipairs(model.materials) do check(inside(f.materials[i],f.source),'material row fits at '..width) end
 check(owner.scroll.limit>0 and inside(owner.pilotCredit,owner),'scroll available; credit stays inside panel')
 f.expand:Click();M.Layout();check(f.alternativeRows[1]:IsShown() and #f.model.alternatives<=3,'up to three compact alternatives expand')
 for i,other in ipairs(f.model.alternatives) do check(inside(f.alternativeRows[i],f.alternatives),'alternative row fits') end
 f.expand:Click();owner.more:Click();M.Layout();check(f.advanced:IsShown() and f.advanced.text:GetText():find('itemID: 279269',1,true),'advanced details reveal ID/provenance/API');owner.more:Click();M.Layout()
end
local count=#M.frames
for i=1,8 do A.UI.ItemDetails.Render(owner,'Back',item);M.Layout() end
check(#M.frames==count,'inspector rows reused on repeated item updates')
A.db.spec='Demonology';A.UI.ItemDetails.Render(owner,'Back',item);M.Layout();check(not f.affinity:IsShown(),'no Affliction guide affinity asserted for another selected spec')
A.db.spec='Affliction';A.UI.ItemDetails.Render(owner,'Back',item);f.viewAll:Click();M.Layout()
check(A.UI.tab=='Item Explorer' and A.UI.explorerSlot=='Back','View All opens existing explorer filtered to slot')
local capeRow;for i,data in ipairs(A.UI.ItemSelector.frame.list.data) do if data.item.id==279269 then capeRow=A.UI.ItemSelector.frame.list.rows[i] end end
check(capeRow and capeRow.ratingState=='UNKNOWN','explorer discrete question mark with no weights')
P.epWeights={ITEM_MOD_STAMINA_SHORT=.2,ITEM_MOD_DAMAGE_SHADOW_SHORT=1,ITEM_MOD_CRIT_RATING_SHORT=.4,ITEM_MOD_DAMAGE_FROST_SHORT=.5};A.UI.ItemSelector.Render()
check(capeRow.ratingState=='UPGRADE','explorer updates valid rating independently of ownership')
A.Services.Catalog.Select('Back',item.id);A.UI.SetTab('Character & Gear',{slot='Back'});M.Layout()
local badge;for _,b in ipairs(A.UI.ModelViewer.equipment) do if b.slot.key=='Back' then badge=b end end
check(badge and badge.ratingState=='UPGRADE','equipment slot uses same validated EP result')
A.UI.ItemDetails.Render(owner,'Head',A.Data.items[22267]);M.Layout();check(not owner.inspectorActive and not f:IsShown() and owner.stats:IsShown(),'other objects retain existing inspector until pilot validated')
check(#A.diagnostics==0,'no Lua diagnostics: '..table.concat(A.diagnostics,'; '))
M.print('PASS item inspector: '..n..' checks · '..M.scenario..' · published Fel Cape / simulated player and frames')
