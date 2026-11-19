local M=dofile('tests/wow_mock.lua');local checks=0
local function check(ok,message) checks=checks+1;assert(ok,message) end
M.equipped={}
ForeverWarlockCompanionDB={schema=2,viewClass='WARLOCK',spec='Affliction',mode='Pre-BiS',profiles={['WARLOCK:Affliction']={planner={[22267]='Head',[999999]='Unknown'},epWeights={ITEM_MOD_INTELLECT_SHORT=2},targets={['Pre-BiS']={Head=22267},BiS={}},obtained={},priorities={}}},professions={'Tailoring','Enchanting'}}
for line in io.lines('ForeverWarlockCompanion.toc') do if line:match('%.lua$') then dofile((line:gsub('\\','/'))) end end
M.Event('ADDON_LOADED','ForeverWarlockCompanion')
local A=FWC;local O=A.Services.Objectives;local P=A.Services.Persistence;local p=P.Profile()
check(A.db.schema==3 and A.db.preV3Backup.schema==2,'schema 2 backed up and migrated')
check(p.epWeights.ITEM_MOD_INTELLECT_SHORT==2 and p.targets['Pre-BiS'].Head==22267,'weights and targets retained')
local o=O.Find(22267,'Head');check(o and o.sourceType=='Dungeon' and #o.steps==3,'real turban has dungeon, boss and item steps')
check(O.Find(999999,'Unknown')~=nil,'unknown legacy item preserved')
local count=0;for _ in pairs(p.objectives) do count=count+1 end;P.Init();local n=0;for _ in pairs(p.objectives) do n=n+1 end
check(count==n,'migration idempotent')
O.List();check(o.completionState=='Not Started','initial state')
O.ToggleStep(o,o.steps[1]);O.List();check(o.completionState=='In Progress','manual dungeon step')
O.ToggleStep(o,o.steps[2]);O.List();check(o.completionState=='Ready to Acquire' and not o.steps[3].completed,'boss does not grant item')
check(not O.ToggleStep(o,o.steps[3]),'acquisition is not a manual prerequisite')
O.AddManual(o,'Personal route note');check(o.steps[4].confidence=='user','custom manual step')
M.bags[1]={{id=22267,count=1}};A.Services.Inventory.Scan();O.List();check(o.completionState=='Obtained','observed ownership')
M.bags[1]={};A.Services.Inventory.Scan();O.List();check(o.completionState~='Obtained','prerequisites separated from ownership')
O.Untrack(o);check(o.trackingState=='Untracked','untrack retains record')
check(O.Track(22267,'Head')==o and o.steps[1].manualCompleted,'retrack retains progress')
local steps=A.Services.Acquisition.Resolve(nil);check(steps[1].confidence=='unknown','unknown source is explicit')
local quest=A.Services.Acquisition.Resolve({id=1,name='Test',sourceType='Quest (Alliance)',source='Known quest',provenance='fixture'})
check(quest[1].type=='CompleteQuest' and #quest==2,'no invented quest chain')
A.Data.recipes[#A.Data.recipes+1]={key='fixture',itemID=900001,name='Fixture',profession='Tailoring',provenance='imported_recipe',reagents={{name='Felcloth',id=14256,qty=2}}}
A.Data.items[900001]={id=900001,name='Fixture',source='Tailoring',sourceType='Crafted',zone='Crafted',provenance='fixture'}
local a=O.Ensure(p,900001,'Chest','Pre-BiS');local b=O.Ensure(p,900001,'Head','Pre-BiS');local mats=A.Services.Materials.ForObjectives({a,b})
check(#mats==1 and mats[1].required==4 and mats[1].available==3 and mats[1].missing==1,'shared material demand and one bag supply')
O.Untrack(a);O.Untrack(b)
SlashCmdList.FWC('');M.Layout();check(A.UI.tab=='Dashboard' and A.UI.window:IsShown(),'dashboard first')
A.UI.SetTab('Character & Gear',{slot='Head'});M.Layout();A.UI.SetTab('Dungeons',{sourceId='Blackrock Spire: Upper'});M.Layout();A.Services.Navigation.Back();M.Layout()
check(A.UI.tab=='Character & Gear' and A.UI.selectedSlot=='Head','Back retains context')
A.UI.SetTab('Progression',{objectiveId=o.objectiveId});M.Layout();check(A.UI.ObjectivesPanel.selected==o,'objective details context')
for _,route in ipairs({'Dashboard','Dungeons','Reputations','Crafting Planner','Activity Planner','Professions','Cooldowns','Stats','Settings'}) do A.UI.SetTab(route);M.Layout();check(A.UI.window.panels[route]:IsShown(),'section '..route) end
check(#A.diagnostics==0,'no swallowed errors: '..table.concat(A.diagnostics,'; '))
O.AddManual(o,'Dependency test')
check(O.AddDependency(o,'user:2','user:1') and not O.AddDependency(o,'user:1','user:2'),'dependencies reject cycles')
O.List();check(o.steps[#o.steps].blocked and not O.ToggleStep(o,o.steps[#o.steps]),'pending dependencies block manual completion')
O.ToggleStep(o,o.steps[4]);O.List();check(not o.steps[#o.steps].blocked,'dependency unlocks after completion')
A.UI.SetTab('Progression',{objectiveId=o.objectiveId});M.Layout()
local old=o.steps[1].manualCompleted;A.UI.ObjectivesPanel.frame.steps.rows[1]:Click();check(o.steps[1].manualCompleted~=old,'objective checklist changes persistent step')
A.UI.Tracker.selected=o;A.db.settings.trackerMode='Expanded';A.db.settings.trackerCollapsed=false;A.UI.Tracker.Render();M.Layout()
local trackerRow
for i,entry in ipairs(A.UI.Tracker.frame.list.data) do if entry.kind=='step' and entry.objective==o and entry.step==o.steps[1] then trackerRow=A.UI.Tracker.frame.list.rows[i] end end
check(trackerRow~=nil,'expanded tracker renders objective steps')
trackerRow:Click();check(o.steps[1].manualCompleted==old,'tracker checklist uses same persistent step')
p.focusObjective=o.objectiveId;check(O.List()[1]==o,'focus sorts objective first')
local function encode(value)
 if type(value)=='table' then local out={};for k,v in pairs(value) do out[#out+1]='['..encode(k)..']='..encode(v) end;return '{'..table.concat(out,',')..'}' end
 if type(value)=='string' then return string.format('%q',value) end
 if type(value)=='number' or type(value)=='boolean' then return tostring(value) end
 error('unexpected SavedVariables type')
end
local tmp=os.tmpname();local handle=assert(io.open(tmp,'w'));handle:write('return '..encode(A.db));handle:close()
ForeverWarlockCompanionDB=assert(loadfile(tmp))();os.remove(tmp);P.Init();p=P.Profile();local restored=O.Find(22267,'Head')
check(restored and restored.steps[1].manualCompleted==old and #restored.steps==5,'real item objective roundtrips through disk')
local pre=restored;A.db.mode='BiS';check(O.Find(22267,'Head')==nil,'objective modes isolated');A.db.mode='Pre-BiS';check(O.Find(22267,'Head')==pre,'mode returns objective progress')
for _,size in ipairs({{880,640},{1180,780},{1700,1100}}) do
 A.UI.window:SetSize(unpack(size));M.Layout();check(A.UI.window.content:GetWidth()>600,'compact shell keeps usable content')
 A.UI.SetTab('Character & Gear');M.Layout();check(A.UI.CharacterPanel.frame.details:GetWidth()>300,'compact equipment detail remains usable')
end
A.UI.DesignSystem.Apply('Blizzard Classic Inspired');check(A.UI.Widgets.colors.panel[1]==.078,'Classic theme applied')
A.UI.DesignSystem.Apply('Modern Azeroth');check(A.UI.Widgets.colors.panel[1]==.085,'Modern theme applied')
check(#A.diagnostics==0,'no errors after all milestone flows')
local unknown=O.Find(999999,'Unknown')
A.UI.SetTab('Progression',{objectiveId=unknown.objectiveId});M.Layout();check(A.UI.ObjectivesPanel.selected==unknown,'unknown legacy objective can be inspected')
A.UI.selectedSlot='Unknown';A.UI.SetTab('Stats');M.Layout();check(A.UI.StatsPanel.frame.result:GetText():find('valid slot',1,true),'unknown slot produces useful comparison empty state')
A.UI.selectedSlot='Head';A.UI.SetTab('Dashboard');M.Layout()
check(#A.diagnostics==0,'unknown metadata does not crash navigation')
check(#A.UI.window.tabs==14 and #A.UI.window.navEntries==18,'grouped navigation exposes all primary sections')
check(A.UI.Dashboard.frame.title:GetText():find('/',1,true)~=nil,'dashboard uses actual equipment progress')
check(A.UI.Dashboard.selected~=nil and A.UI.Dashboard.frame.objective:IsShown(),'dashboard exposes actual next tracked objective')
O.Track(14111,'Head');O.Track(18691,'Neck');A.UI.Dashboard.Render();M.Layout()
check(#A.UI.Dashboard.frame.list.data==3,'dashboard shows up to three real objectives')
check(A.UI.Dashboard.frame.statsText:GetText():find('—',1,true),'missing character stat uses placeholder')
local row=A.UI.Dashboard.frame.list.rows[1];row:Click();check(A.UI.tab=='Progression' and A.UI.ObjectivesPanel.selected~=nil,'dashboard card opens objective details')
for _,objective in ipairs(O.List()) do O.Untrack(objective) end
A.UI.SetTab('Dashboard');A.UI.Dashboard.Render();M.Layout()
check(A.UI.Dashboard.frame.empty:GetText():find('No tracked',1,true) and A.UI.Dashboard.frame.start:IsShown(),'dashboard offers a useful empty state')
local done=O.Track(22267,'Head');P.Profile().obtained[22267]=true;A.UI.Dashboard.Render()
check(done.completionState=='Obtained' and A.UI.Dashboard.frame.empty:GetText():find('All tracked',1,true),'completed state differs from no objectives')
M.print('PASS v3: '..checks..' checks')
