-- Real normalized ForeverDB records; player APIs are controlled test doubles.
-- Geometry inspection does not render the WoW client.
local M=dofile('tests/wow_mock.lua');local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,msg) end
local function bounds(f) local x,w=f:Bounds(true);local y,h=f:Bounds(false);return x,y,w,h end
local function inside(c,p) local x,y,w,h=bounds(c);local px,py,pw,ph=bounds(p);return w>0 and h>0 and x>=px-.1 and y>=py-.1 and x+w<=px+pw+.1 and y+h<=py+ph+.1 end
local function apart(a,b) local x,y,w,h=bounds(a);local bx,by,bw,bh=bounds(b);return x+w<=bx+.1 or bx+bw<=x+.1 or y+h<=by+.1 or by+bh<=y+.1 end
ForeverWarlockCompanionDB={viewClass='WARLOCK',spec='Affliction',mode='Pre-BiS'}
for line in io.lines('ForeverWarlockCompanion.toc') do if line:match('%.lua$') then dofile((line:gsub('\\','/'))) end end
M.Event('ADDON_LOADED','ForeverWarlockCompanion');SlashCmdList.FWC('');M.Layout()
local A=FWC;local G=A.Services.ItemGuide;local data=A.Data.itemGuide;local D=A.UI.ItemDetails;local I=A.Services.Inventory
local n=0;for id,item in pairs(A.Data.items) do
 n=n+1;check(G.Record(item) and #G.Requirements(item)>=3,'published requirements for item '..id)
end
check(n==157 and data.coverage.itemsImported==157,'all existing gear items covered')
check(data.coverage.enhancements==17 and data.coverage.craftingItems==29,'selected enhancement and crafting scope')
check(not data.coverage.liveClientValidated,'simulations do not mark live client validated')
local turban=A.Data.items[22267];local cloak=A.Data.items[272411]
check(G.ScoreLabel('Head',turban)=='47 · guía JcE 60','source score explicitly marked as guide context')
check(G.ScoreLabel('Head',A.Data.items[18727]):find('23%%'),'published guide difference')
check(G.Recommendation('Head',A.Data.items[226909])==nil,'same name never substitutes source item ID 22074')
local oldLevel=UnitLevel;UnitLevel=function() return 40 end
local req=G.Requirements(turban)[1];check(req.required==60 and req.current==40 and req.status=='missing','required player level compared with actual level')
UnitLevel=function() return nil end;check(G.Requirements(turban)[1].status=='unknown','unknown player level never zero')
UnitLevel=oldLevel
local r=data.items[22267];local saved=r.requiredLevel;r.requiredLevel=0;check(G.Requirements(turban)[1].required==0,'explicit zero retained');r.requiredLevel=saved
local kit=data.enhancements[1254966]
check(G.EnhancementRequirement(kit,turban).status=='met','kit checks item level')
local savedIlvl=r.itemLevel;r.itemLevel=20;check(G.EnhancementRequirement(kit,turban).status=='missing','kit target minimum is item level 35');r.itemLevel=savedIlvl
check(G.EnhancementDetails(kit):find('no del personaje',1,true),'target level distinguished from player level')
check(G.Enhancements('Head',turban)[1].spellId==24164 and G.Enhancements('Head',turban)[2].spellId==22844,'head arcanum options')
check(G.EnhancementDetails(data.enhancements[24164]):find('sin confirmar',1,true),'unpublished arcanum source explicit')
check(G.Enhancements('Back',cloak)[1].recommendationType=='utility','cloak utility does not claim damage score')
local main=A.Data.items[18372];local m=data.items[18372];local savedType=m.inventoryTypeId
m.inventoryTypeId=17;check(G.Enhancements('MainHand',main)[1].spellId==1248607,'two-handed weapon chooses applicable enchant')
m.inventoryTypeId=savedType;check(G.Enhancements('MainHand',main)[1].spellId==22749,'one-handed weapon uses reference choice')
local faction=UnitFactionGroup;UnitFactionGroup=function() return 'Horde' end
local neck=data.enhancements[1249057]
local text=G.EnhancementDetails(neck)
check(text:find('Beneris',1,true) and not text:find('Alynsia',1,true),'Horde formula location selected')
check(text:find('120',1,true) and text:find("Merchant's Favor",1,true),'formula currency cost visible')
UnitFactionGroup=function() return 'Alliance' end;check(G.EnhancementDetails(neck):find('Alynsia',1,true),'Alliance formula location selected');UnitFactionGroup=faction
M.bags[0]={{id=11175,count=2}};I.Scan()
local mats=G.Materials(neck);check(mats[1].available==2 and mats[1].required==5 and not mats[1].complete,'enchant material progress uses real bag counts')
check(G.EnhancementDetails(neck):find('2 / 5',1,true),'material progress visible in details')
check(G.EnhancementDetails(data.enhancements[22749]):find('Classic; sin confirmar en Forever',1,true),'legacy formula drops labeled')
local craft=G.SourceText(A.Data.items[14153])
check(craft:find('Tailoring 295',1,true) and craft:find('no es un requisito para equipar',1,true),'crafting skill distinct from equip requirement')
check(not craft:find('Nivel del elaborador',1,true),'unmapped recipe.requiredLevel not asserted as caster level')
check(G.SourceText(A.Data.items[10025]):find('The Undermarket',1,true),'published quest for recipe learning visible')
check(G.SourceText(cloak):find('75',1,true) and G.SourceText(cloak):find('https://foreverdb.net',1,true),'vendor resolver and attribution retained')
local beforeCount=#M.frames
for _,size in ipairs({{880,640},{1180,780},{1700,1040}}) do
 A.UI.window:SetSize(unpack(size));A.UI.SetTab('Item Details',{slot='Neck',itemId=19426});M.Layout()
 local f=D.page
 for _,panel in ipairs({f.stats,f.alternativesSection,f.enchantSection,f.requirements,f.source,f.comparison,f.stepsSection}) do check(inside(panel,f.scroll.content),'guide section inside scroll body') end
 check(apart(f.stats,f.alternativesSection) and apart(f.enchantSection,f.requirements),'reference hierarchy does not overlap')
 check(apart(f.requirements,f.source),'equip requirements separate from acquisition')
 f.enchants.rows[1]:Click();M.Layout()
 check(f.enchantInfo:IsShown() and f.enchantInfo:GetText():find('Materiales',1,true),'enchant click expands actual sources and materials')
 check(apart(f.enchantInfo,f.enchantCredit) and inside(f.enchantInfo,f.enchantSection),'expanded details remain above visible credit')
 f.enchants.rows[1]:Click();M.Layout();check(not f.enchantInfo:IsShown(),'enchant details collapse')
 check(f.enchantCredit.label:GetText():find('https://foreverdb.net',1,true),'permanent visible source credit')
 check(f.requirements.text:GetText():find('https://foreverdb.net',1,true),'requirement source credit')
 check(#f.alternativeCards.data==2,'two visual alternatives')
 local other=f.alternativeCards.data[1];f.alternativeCards.rows[1]:Click();M.Layout()
 check(f.item.id==other.id,'alternative icon card selects item details')
end
A.UI.SetTab('Item Details',{slot='Head',itemId=22267});M.Layout()
D.page.enchants.rows[1]:Click();M.Layout();check(D.page.enchantOpen,'selected head enchant open')
A.UI.SetTab('Item Details',{slot='Head',itemId=18727});M.Layout();check(not D.page.enchantOpen,'changing item resets expanded enchant context')
local frameCount=#M.frames;for i=1,10 do A:Refresh();M.Layout() end
check(#M.frames==frameCount,'guide rerenders reuse pooled rows')
local spec=A.db.spec;A.db.spec='Demonology';D.Render(D.page,'Head',turban);M.Layout()
check(#D.page.enchantRows==0 and G.Recommendation('Head',turban)==nil,'Affliction recommendations not asserted for another spec')
D.Render(D.page,'Head',nil);M.Layout();check(#D.page.alternativeCards.data==0 and not D.page.enchantInfo:IsShown(),'empty profile clears previous item/enchant data')
A.db.spec=spec
A.UI.explorerSlot='Head';A.UI.search='';A.UI.source=nil;A.UI.SetTab('Item Explorer');M.Layout()
check(#A.UI.ItemSelector.frame.list.data==10,'all candidates and existing filters preserved')
check(A.UI.ItemSelector.frame.list.rows[1].sub:GetText():find('Spell Power',1,true),'explorer cards show published attributes')
check(A.UI.ItemSelector.frame.credit:GetText():find('https://foreverdb.net',1,true),'explorer visible source credit')
check(#A.diagnostics==0,'no native compatibility errors: '..table.concat(A.diagnostics,'; '))
M.print('PASS item guide: '..checks..' checks · '..M.scenario..' · real records + simulated player/layout')
