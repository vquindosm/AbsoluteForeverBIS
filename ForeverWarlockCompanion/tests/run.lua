local M=dofile('tests/wow_mock.lua')
local checks=0
local function check(condition,message) checks=checks+1;assert(condition,message) end
ForeverWarlockCompanionDB={viewClass='WARLOCK',spec='Affliction',selected={['affliction:Head']='Crimson Felt Hat',['affliction:Wrists']='Unresolved original cuff'},done={['affliction:Head']=true},moonclothHistory={M.now-1000},professions={'Tailoring','Enchanting'}}
for line in io.lines('ForeverWarlockCompanion.toc') do
 if line:match('%.lua$') then dofile((line:gsub('\\','/'))) end
end
M.Event('ADDON_LOADED','ForeverWarlockCompanion')
local A=FWC;local P=A.Services.Persistence;local G=A.Services.Catalog;local I=A.Services.Inventory
local planner=A.Services.Planner
local weights=planner.ParseWeights('ITEM_MOD_INTELLECT_SHORT=2, ITEM_MOD_STAMINA_SHORT=0')
check(weights and weights.ITEM_MOD_INTELLECT_SHORT==2,'valid per-stat EP weights parsed')
check(not planner.ParseWeights('INTELLECT=2') and not planner.ParseWeights('ITEM_MOD_INTELLECT_SHORT=2,ITEM_MOD_INTELLECT_SHORT=3'),'invalid or duplicate weights rejected')
local estimate=planner.WeightedComparison({ITEM_MOD_INTELLECT_SHORT=10},{ITEM_MOD_INTELLECT_SHORT=15},weights)
check(estimate and estimate.before==20 and estimate.after==30 and estimate.delta==50,'EP percentage calculated against equipped item')
check(not planner.WeightedComparison({ITEM_MOD_INTELLECT_SHORT=10},{ITEM_MOD_INTELLECT_SHORT=15,ITEM_MOD_STRENGTH_SHORT=1},weights),'missing stat weight blocks misleading estimate')
check(not planner.WeightedComparison({},{ITEM_MOD_INTELLECT_SHORT=15},weights),'zero baseline does not produce percentage')
check(A.db.schema==3,'SavedVariables migration')
check(A.db.legacyBackup.selected['affliction:Head']=='Crimson Felt Hat','legacy backup preserved')
check(G.Target('Head').id==18727,'name migrated to verified source ID')
check(P.Profile().unresolved.Wrists=='Unresolved original cuff' and not G.Target('Wrists'),'unresolved original selection retained')
check(#G.List('WARLOCK','Affliction','Pre-BiS','Head')==10,'ten imported Head candidates')
local specs=0;for _,list in pairs(A.Data.classes) do specs=specs+#list end
check(specs==29 and #A.Data.slots==17,'all source variants and slots')
check(I.Status(A.Data.items[22267])=='Equipped','equipped detected by ID')
check(I.Status(A.Data.items[18727])=='In bags','bag detected by ID')
check(I.Status(A.Data.items[14111])=='Not found','absence only after complete scan')
local n,known=I.Count({id=14256});check(n==3 and known,'full stack quantities')
local getID,getLink=GetInventoryItemID,GetInventoryItemLink
GetInventoryItemID=function() error('equipment inaccessible') end;GetInventoryItemLink=GetInventoryItemID
I.Scan();check(I.Status(A.Data.items[14111])=='Unchecked','equipment failures do not prove absence')
GetInventoryItemID=getID;GetInventoryItemLink=getLink;I.Scan()
local scans=I.scans;for i=1,20 do M.Event('BAG_UPDATE',0);M.Event('BAG_UPDATE_DELAYED') end
M.Advance();check(I.scans==scans+1,'event burst coalesced to one scan')
M.combat=true;M.Event('BAG_UPDATE');M.Advance();check(I.pending and I.scans==scans+1,'scan deferred in combat')
M.combat=false;M.Event('PLAYER_REGEN_ENABLED');M.Advance();check(not I.pending and I.scans==scans+2,'deferred scan resumed')
if C_Container then
 M.bagError=true;I.Scan();check(not I.snapshot.complete and I.Status(A.Data.items[14111])=='Unchecked','API failure does not become absence');M.bagError=false;I.Scan()
end
SlashCmdList.FWC('gear');M.Layout()
check(A.UI.window and A.UI.window:IsShown(),'slash opens native UI')
check(#A.diagnostics==0,'UI builds without swallowed errors: '..table.concat(A.diagnostics,'; '))
SlashCmdList.FWC('stats');M.Layout()
local stats=A.UI.StatsPanel;local panel=stats.frame
check(A.UI.tab=='Stats' and panel:IsShown(),'dedicated Stats tab reachable by slash')
check(#panel.rows>=14,'readable stat and weight rows visible')
local intRow
for _,row in ipairs(panel.rows) do if row.key=='ITEM_MOD_INTELLECT_SHORT' then intRow=row end end
check(intRow and intRow.cells[2]:GetText()=='10' and intRow.cells[3]:GetText()=='15','equipped and candidate values visible without weights')
intRow.edit:SetText('1');check(stats.Save(),'weights saved through named fields')
check(P.Profile().epWeights.ITEM_MOD_INTELLECT_SHORT==1 and panel.result:GetText():find('+50.0',1,true),'visible EP comparison updates from saved weight')
intRow.edit:SetText('invalid');check(not stats.Save() and P.Profile().epWeights.ITEM_MOD_INTELLECT_SHORT==1,'invalid weight cannot overwrite profile')
intRow.edit:SetText('1');stats.Save();SlashCmdList.FWC('gear');M.Layout()
check(#A.UI.CharacterPanel.frame.list.rows==17,'all slot rows created')
check(A.UI.CharacterPanel.frame.list.limit>0,'slot list scrolls')
A.UI.CharacterPanel.frame.list.rows[1]:Click();M.Layout()
check(A.UI.tab=='Character & Gear' and A.UI.selectedSlot=='Head','Head keeps contextual equipment view')
A.UI.explorerSlot='Head';A.UI.SetTab('Item Explorer');M.Layout()
check(#A.UI.ItemSelector.frame.list.data==10,'Head alternatives visible')
A.UI.ItemSelector.frame.list.rows[3]:Click();A.UI.ItemSelector.frame.details.buttons[1]:Click();M.Layout()
check(G.Target('Head').id==14111 and A.UI.tab=='Character & Gear','target action persists ID and returns to model')
check(A.UI.ModelViewer.mode=='Planned','planned model selected')
local beforeRenderScan=I.scans;A.UI.Render();check(I.scans==beforeRenderScan,'painting does not scan bags')
if M.scenario=='modern' or M.scenario=='legacy' then check((M.tryOns or 0)>0,'native TryOn invoked') end
if M.scenario=='no-model' then check(A.UI.ModelViewer.status:GetText():find('unavailable'),'explicit missing-model state') end
if M.scenario=='player-model' then check(A.UI.ModelViewer.status:GetText():find('unavailable'),'read-only PlayerModel fallback') end
local p=P.Profile();P.SetView('WARLOCK','Demonology');A.UI.ViewChanged();M.Layout()
check(not G.Target('Head'),'other spec gets honest empty catalog')
P.SetView('WARLOCK','Affliction');check(G.Target('Head').id==14111,'spec switch restores previous selection')
A.db.mode='BiS';check(not G.Target('Head'),'no fake BiS catalog')
A.db.mode='Pre-BiS';check(G.Target('Head').id==14111,'mode switch preserves goals')
A.UI.SetTab('Item Explorer');A.UI.explorerSlot='Head';A.UI.ItemSelector.frame.search:SetText('Crimson');M.Layout()
check(#A.UI.ItemSelector.frame.list.data==1,'name filter')
A.UI.ItemSelector.frame.search:SetText('');A.UI.source='Crafted';A.UI.ItemSelector.Render()
for _,row in ipairs(A.UI.ItemSelector.frame.list.data) do check(row.item.sourceType=='Crafted','source filter') end
A.UI.source=nil
A.db.professions={'Enchanting','Enchanting'};A.db.manualProfessions=true
for _,recipe in ipairs(A.Services.Professions.Recipes()) do check(recipe.profession=='Enchanting','profession filter applied') end
A.db.professions={'Tailoring','Enchanting'}
if M.scenario~='legacy' then
 A.UI.SetTab('Talents');A.UI.Supporting.talents.save:Click();local saved=P.Profile().talents[1]
 check(saved and #saved.data.branches>0,'live talent snapshot saved')
 check(saved.targets['Pre-BiS'].Head==14111,'talent snapshot associated with effective target IDs')
 A.UI.Supporting.talents.use:Click();check(P.Profile().activeTalent==1,'planning talent profile selectable')
end
local history=#A.db.moonclothHistory;check(A.Services.Professions.RecordMooncloth(),'manual craft record')
check(not A.Services.Professions.RecordMooncloth() and #A.db.moonclothHistory==history+1,'no accidental duplicate history')
local all=A.Services.Planner.Rows('All');check(#all>0,'planner derives selected targets')
p.planner[18727]='Head';local extra=false
for _,row in ipairs(A.Services.Planner.Rows('Added manually')) do if row.item.id==18727 then extra=true end end
check(extra,'non-target alternative can be added to planner')
local ringID=G.List('WARLOCK','Affliction','Pre-BiS','Ring1')[1]
local old1,old2=p.targets['Pre-BiS'].Ring1,p.targets['Pre-BiS'].Ring2
p.targets['Pre-BiS'].Ring1=ringID;p.targets['Pre-BiS'].Ring2=ringID
I.snapshot.bags[ringID]=1;local copies=0
for _,row in ipairs(A.Services.Planner.Rows('Completed')) do if row.item.id==ringID then copies=copies+1 end end
check(copies==1,'one physical ring does not satisfy two targets')
p.targets['Pre-BiS'].Ring1=old1;p.targets['Pre-BiS'].Ring2=old2;I.snapshot.bags[ringID]=nil
for _,name in ipairs({'Talents','Professions','Progression','Daily / Weekly','Settings','Character & Gear','Item Explorer'}) do
 A.UI.SetTab(name);M.Layout();check(A.UI.window.panels[name]:IsShown(),'tab visible: '..name)
end
local sizes={{1100,700},{1180,780},{1700,1200}}
for _,size in ipairs(sizes) do
 A.UI.window:SetSize(unpack(size));M.Layout()
 local gear=A.UI.CharacterPanel.frame
 check((not gear.left:IsShown() or gear.left:GetWidth()>200) and gear.model:GetWidth()>270 and gear.details:GetWidth()>300,'responsive character dimensions')
 for _,f in ipairs({gear.details,A.UI.ItemSelector.frame.details}) do
  check(f.scroll:GetHeight()>120,'detail viewport has usable height')
  for _,b in ipairs(f.buttons) do check(b:GetWidth()>130,'action buttons fit minimum geometry') end
 end
end
A.UI.SetTab('Character & Gear');M.Layout();local frameCount=#M.frames
for i=1,20 do A.UI.Render();M.Layout() end
check(#M.frames==frameCount,'repeated renders reuse pooled frames')
check(I.scans>=1,'cached inventory service active')
check(#A.diagnostics==0,'all tabs run without compatibility errors')
if A.UI.ModelViewer.model and A.UI.ModelViewer.model.TryOn then
 M.rejectPreview=true;local ok=A.UI.ModelViewer.Preview(A.Data.items[22267],'Head')
 check(not ok and A.UI.ModelViewer.status:GetText():find('result'),'preview rejection visible')
 M.rejectPreview=false;A.UI.ModelViewer.mode='Current';A.UI.ModelViewer.Apply(true)
end
local selectedID=G.Target('Head').id;P.Init();check(G.Target('Head').id==selectedID,'initialization is idempotent')
C_Reputation={GetNumFactions=function() return 1 end,GetFactionDataByIndex=function() return {name='The Watchers',reaction=5,currentReactionThreshold=3000,nextReactionThreshold=9000,currentStanding=3300} end}
FACTION_STANDING_LABEL5='Friendly'
local rep=A.UI.Tracker.Reputation({sourceType='Reputation',source='The Watchers - Exalted'})
check(rep and rep.value==300 and rep.total==6000 and rep.goal=='Exalted','reputation shows real next-rank progress with separate goal')
check(not A.UI.Tracker.Reputation({sourceType='Reputation',source='Faction A / Faction B - Exalted'}),'ambiguous factions remain unavailable')
check(not A.UI.Tracker.Reputation({sourceType='Reputation',source='Unknown - Exalted'}),'missing factions do not invent progress')
C_Reputation.GetFactionDataByID=function(id) if id==77 then return {name='Los Vigilantes',reaction=5,currentReactionThreshold=3000,nextReactionThreshold=9000,currentStanding=3300} end end
p.factions={[275982]=77}
local localized=A.UI.Tracker.Reputation({id=275982,sourceType='Reputation',source='The Watchers - Exalted'})
check(localized and localized.name=='Los Vigilantes' and localized.value==300,'manual faction association supports localized names')
p.factions[275982]=88
check(not A.UI.Tracker.Reputation({id=275982,sourceType='Reputation',source='The Watchers - Exalted'}),'missing manually selected faction does not fall back to unrelated index')
p.factions=nil
local details=A.UI.ItemSelector.frame.details
check(not details.expanded and not details.buttons[4]:IsShown(),'secondary item actions start collapsed')
details.more:Click();check(details.expanded and details.buttons[4]:IsShown(),'more options reveals retained actions');details.more:Click()
local watch=A.Data.items[275982]
if watch then
 local objective=A.Services.Objectives.Track(watch.id,'Ring1');A.UI.Tracker.Render()
 local found=false
 for i,entry in ipairs(A.UI.Tracker.frame.list.data) do
  if entry.kind=='objective' and entry.item and entry.item.id==watch.id then local row=A.UI.Tracker.frame.list.rows[i];found=row.itemIcon and not row.bar:IsShown() and objective.steps[1].requiredAmount==nil end
 end
 check(found,'tracker does not confuse next-rank bar with Exalted requirement')
 A.Services.Objectives.Untrack(objective);A.UI.Tracker.Render()
end
local oldUnits=M.setUnits or 0;A.UI.SetTab('Character & Gear');A.UI.Render();A.UI.Render()
check((M.setUnits or 0)<=oldUnits+1,'ordinary redraws do not repeatedly reload model')
if A.UI.ModelViewer.model then
 local before=M.setUnits or 0;A.UI.ModelViewer.mode='Current';A.UI.ModelViewer.Apply(true)
 check(M.setUnits==before+1 and A.UI.ModelViewer.mode=='Current','restore forces actual appearance')
end
check(#A.UI.ModelViewer.equipment==17,'equipped slots surround character')
check(A.UI.Tracker.frame and A.UI.Tracker.frame:IsShown(),'floating tracker available')
local hidden=A.db.settings.trackerHidden;SlashCmdList.FWC('tracker');check(A.db.settings.trackerHidden~=hidden,'tracker slash toggles visibility');SlashCmdList.FWC('tracker')
A.db.settings.trackerCollapsed=true;A.UI.Tracker.Render();check(A.UI.Tracker.frame:GetHeight()==36,'tracker collapses');A.db.settings.trackerCollapsed=false;A.UI.Tracker.Render()
check(A.db.legacyBackup.selected['affliction:Head']=='Crimson Felt Hat','backup unchanged after new selections')
local function serialize(value)
 if type(value)=='table' then local parts={};for k,v in pairs(value) do parts[#parts+1]='['..serialize(k)..']='..serialize(v) end;return '{'..table.concat(parts,',')..'}' end
 if type(value)=='string' then return string.format('%q',value) end
 if type(value)=='number' or type(value)=='boolean' then return tostring(value) end
 error('unexpected non-serializable SavedVariables value')
end
local temp=os.tmpname();local out=assert(io.open(temp,'w'));out:write('return '..serialize(A.db));out:close()
ForeverWarlockCompanionDB=assert(loadfile(temp))();os.remove(temp);P.Init()
check(G.Target('Head').id==selectedID,'SavedVariables roundtrip through disk preserves target')
check(A.db.moonclothHistory[#A.db.moonclothHistory]==M.now,'disk roundtrip preserves craft history')
SlashCmdList.FWC('');check(not A.UI.window:IsShown(),'slash closes')
SlashCmdList.FWC('');check(A.UI.window:IsShown(),'slash reopens')
check(#A.diagnostics==0,'no hidden module errors')
M.print('PASS '..M.scenario..': '..checks..' checks; '..#M.frames..' native-frame doubles; '..I.scans..' cached scans')
