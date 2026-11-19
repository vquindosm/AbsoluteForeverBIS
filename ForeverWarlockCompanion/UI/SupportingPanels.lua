local A=FWC
local S={};A.UI.Supporting=S
local function twoColumns(parent)
    local W=A.UI.Widgets;local f=CreateFrame("Frame",nil,parent);f:SetAllPoints(parent)
    f.left=W.Panel(f);f.left:SetPoint("TOPLEFT");f.left:SetPoint("BOTTOMLEFT")
    f.right=W.Panel(f);f.right:SetPoint("TOPLEFT",f.left,"TOPRIGHT",10,0);f.right:SetPoint("BOTTOMRIGHT")
    f.list=W.List(f.left,82);f.list:SetPoint("TOPLEFT",12,-48);f.list:SetPoint("BOTTOMRIGHT",-28,12)
    f.heading=W.Label(f.left,"","GameFontNormal");f.heading:SetPoint("TOPLEFT",12,-14)
    f.text=W.TextScroll(f.right);f.text:SetPoint("TOPLEFT",14,-16);f.text:SetPoint("BOTTOMRIGHT",-30,94)
    f:SetScript("OnSizeChanged",function(self,width) self.left:SetWidth(width*.48) end)
    return f
end
function S.CreateProfessions(parent)
    local f=twoColumns(parent);S.prof=f;f.heading:SetText("RECIPES / CRAFTING PRIORITY")
    local W=A.UI.Widgets
    f.search=W.Edit(f.left,function(value) S.recipeSearch=value;S.RenderProfessions() end)
    f.search:SetPoint('TOPLEFT',12,-40);f.search:SetPoint('TOPRIGHT',-12,-40)
    f.list:ClearAllPoints();f.list:SetPoint('TOPLEFT',12,-80);f.list:SetPoint('BOTTOMRIGHT',-28,12)
    f.record=W.Button(f.right,"Record successful Mooncloth craft",function()
        if A.Services.Professions.RecordMooncloth() then A:Print("Manual Mooncloth timestamp recorded.") end;S.RenderProfessions()
    end);f.record:SetPoint("BOTTOMLEFT",14,50);f.record:SetPoint("BOTTOMRIGHT",-14,50)
    f.priority=W.Menu(f.right,"Craft priority",{{label="High priority",value=1},{label="Normal priority",value=2},{label="Low priority",value=3}},function(value)
        if S.recipe then A.Services.Persistence.Profile().priorities[S.recipe.key]=value;S.RenderProfessions() end
    end);f.priority:SetPoint("BOTTOMLEFT",14,14);f.priority:SetPoint("BOTTOMRIGHT",-14,14)
    return f
end
function S.RenderProfessions()
    local f=S.prof;local recipes=A.Services.Professions.Recipes()
    local context=A.Services.Navigation.context;local linked
    if context.recipeKey then for _,r in ipairs(A.Data.recipes) do if r.key==context.recipeKey then linked=r;break end end end
    local filtered={};for _,r in ipairs(recipes) do if r==linked or string.find(string.lower(r.name),string.lower(S.recipeSearch or ''),1,true) then filtered[#filtered+1]=r end end
    recipes=filtered
    if linked then
        local present=false;for _,r in ipairs(recipes) do if r==linked then present=true end end
        if not present then recipes[#recipes+1]=linked end;S.recipe=linked
    end
    table.sort(recipes,function(a,b)
        local pa,pb=A.Services.Professions.Priority(a),A.Services.Professions.Priority(b)
        if pa~=pb then return pa<pb end;return a.name<b.name
    end)
    local found=false;for _,r in ipairs(recipes) do if r==S.recipe then found=true end end
    if not found then S.recipe=recipes[1] end
    f.list:Render(recipes,function(row,recipe)
        local _,ready=A.Services.Professions.Materials(recipe)
        local item=recipe.itemID and A.Data.items[recipe.itemID]
        if item then A.UI.DesignSystem.ItemCard(row,item,recipe.profession..' · '..(ready and 'Materials available; recipe/cooldown unchecked' or 'Materials missing / unchecked'))
        else row.title:SetText(recipe.name);row.sub:SetText(recipe.profession.." | "..(ready and "Materials available (confirm recipe)" or "Materials missing / unchecked")) end
        A.UI.Widgets.Active(row,S.recipe==recipe)
        row:SetScript("OnClick",function() S.recipe=recipe;S.RenderProfessions() end)
    end)
    local r=S.recipe;f.record:SetShown(r and r.key=="mooncloth" or false);f.priority:SetEnabled(r~=nil)
    if not r then f.text:SetText("No recipes for the selected professions.\n\nInitial catalogs cover Tailoring and relevant Enchanting recipes only. Select either profession or Any profession above.");return end
    f.priority:SetText("Craft priority: "..({"High","Normal","Low"})[A.Services.Professions.Priority(r)])
    local lines={r.name,"Profession: "..r.profession,A.Data.provenance[r.provenance] or "Pending review","", "MATERIALS (bags only)"}
    local materials,ready=A.Services.Professions.Materials(r)
    if not materials then lines[#lines+1]="Recipe costs pending verification. No quantities or craftability inferred."
    else
        for _,m in ipairs(materials) do
            lines[#lines+1]=m.name..": "..(m.checked and tostring(m.available) or "?").." / "..m.qty.."; missing "..(m.checked and tostring(m.missing) or "unchecked")
        end
        lines[#lines+1]="";lines[#lines+1]=ready and "Imported material requirements met; recipe knowledge/cooldown must be checked in game." or "Not confirmed craftable."
    end
    if r.key=="mooncloth" then
        local remain=A.Services.Professions.Cooldown()
        lines[#lines+1]="";lines[#lines+1]="MANUAL MOONCLOTH TRACKER"
        lines[#lines+1]="2 Felcloth / 95h is inherited, unverified data. This estimate does not prove the actual recipe or cooldown."
        lines[#lines+1]=remain and ("Estimated remaining: "..math.floor(remain/3600).."h "..math.floor(remain%3600/60).."m") or "No craft recorded."
        lines[#lines+1]="Only record after crafting yourself. No automatic crafting or success detection."
        lines[#lines+1]="Recent manual history:"
        for i=#A.db.moonclothHistory,math.max(1,#A.db.moonclothHistory-9),-1 do
            if type(A.db.moonclothHistory[i])=="number" then lines[#lines+1]=A.Compat.Date("%Y-%m-%d %H:%M",A.db.moonclothHistory[i]) end
        end
    end
    lines[#lines+1]="";lines[#lines+1]="Detected professions:"
    for _,p in pairs(A.Services.Character.professions) do lines[#lines+1]=p.name.." "..tostring(p.rank or "?").."/"..tostring(p.maxRank or "?") end
    lines[#lines+1]="";lines[#lines+1]=r.reference or "Source pending"
    f.text:SetText(table.concat(lines,"\n"))
end
function S.CreateTalents(parent)
    local f=twoColumns(parent);S.talents=f;f.heading:SetText("LIVE TALENTS / SAVED SNAPSHOTS")
    local W=A.UI.Widgets
    f.save=W.Button(f.right,"Save current talents + gear snapshot",function()
        local live=A.Services.Character.talents
        if #live.branches==0 or A.db.viewClass~=live.class then return end
        local p=A.Services.Persistence.Profile();local copy=A.Services.Persistence.Copy
        local targets=copy(p.targets)
        for _,slot in ipairs(A.Data.slots) do local item=A.Services.Catalog.Target(slot.key);if item then targets[A.db.mode][slot.key]=item.id end end
        p.talents[#p.talents+1]={name=A.Compat.Date("%Y-%m-%d %H:%M"),data=copy(live),targets=targets,mode=A.db.mode}
        p.activeTalent=#p.talents;S.talentSelection=p.talents[#p.talents];S.RenderTalents()
    end);f.save:SetPoint("BOTTOMLEFT",14,50);f.save:SetPoint("BOTTOMRIGHT",-14,50)
    f.use=W.Button(f.right,"Use selected planning profile",function()
        local p=A.Services.Persistence.Profile();for i,profile in ipairs(p.talents) do
            if S.talentSelection==profile then p.activeTalent=i;break end
        end
        S.RenderTalents()
    end);f.use:SetPoint("BOTTOMLEFT",14,14);f.use:SetPoint("BOTTOMRIGHT",-14,14)
    return f
end
function S.RenderTalents()
    local f=S.talents;local p=A.Services.Persistence.Profile();local live=A.Services.Character.talents
    local rows={{name="Live character talents",data=live,live=true}}
    for _,profile in ipairs(p.talents) do rows[#rows+1]=profile end
    local valid=false;for _,row in ipairs(rows) do if row==S.talentSelection then valid=true end end
    if not valid then S.talentSelection=rows[1] end
    local selection=S.talentSelection
    f.list:Render(rows,function(row,profile,index)
        row.title:SetText(profile.name);row.sub:SetText(profile.live and "Read from actual character, not the catalog filter" or (p.activeTalent==index-1 and "Selected planning profile" or "Saved with gear targets"))
        row:SetScript("OnClick",function() S.talentSelection=profile;S.RenderTalents() end)
    end)
    f.save:SetEnabled(#live.branches>0 and A.db.viewClass==live.class)
    f.use:SetEnabled(not selection.live)
    local lines={"Planning view: "..A.db.viewClass.." / "..A.db.spec,"Read-only snapshot: "..selection.name,"", "No talent points are spent. Saved profiles document a build; they never apply talents or equip gear.",""}
    if #selection.data.branches==0 then lines[#lines+1]="The client did not expose a readable talent tree. No point allocation or recommended build is invented."
    else
        for _,branch in ipairs(selection.data.branches) do
            lines[#lines+1]=branch.name.." ("..branch.points.." points)"
            for _,entry in ipairs(branch.entries) do lines[#lines+1]="  "..entry.name..": "..entry.rank.."/"..tostring(entry.max or "?") end
            lines[#lines+1]=""
        end
    end
    if selection.targets then
        lines[#lines+1]="ASSOCIATED GEAR (snapshot)"
        for _,slot in ipairs(A.Data.slots) do
            local id=selection.targets[selection.mode or "Pre-BiS"][slot.key]
            local item=id and A.Data.items[id];if item then lines[#lines+1]=slot.label..": "..item.name end
        end
    end
    f.text:SetText(table.concat(lines,"\n"))
end
function S.CreatePlanner(parent)
    local f=twoColumns(parent);S.planner=f
    f.heading:SetText("TARGETS / PRIORITY / SOURCE")
    f.filter=A.UI.Widgets.Menu(f.left,"Missing",{"All","Missing","Completed","High priority","Added manually"},function(value) S.plannerFilter=value;S.RenderPlanner() end)
    f.filter:SetSize(180,25);f.filter:SetPoint("TOPRIGHT",-12,-8)
    f.details=A.UI.ItemDetails.Create(f.right);f.details:SetAllPoints(f.right);f.text:Hide()
    return f
end
function S.RenderPlanner()
    local f=S.planner;local rows=A.Services.Planner.Rows(S.plannerFilter or "Missing")
    f.filter:SetText(S.plannerFilter or "Missing");local all=A.Services.Planner.Rows("All");local done=0
    for _,row in ipairs(all) do if row.complete then done=done+1 end end
    f.heading:SetText("PROGRESS "..done.."/"..#all)
    f.list:Render(rows,function(row,entry)
        if not row.itemIcon then row.itemIcon=row:CreateTexture(nil,"ARTWORK");row.itemIcon:SetSize(42,42);row.itemIcon:SetPoint("TOPLEFT",8,-8) end
        row.itemIcon:SetTexture(A.Compat.ItemInfo(entry.item.id).icon or entry.item.icon)
        row.title:ClearAllPoints();row.title:SetPoint("TOPLEFT",58,-7);row.title:SetPoint("TOPRIGHT",-8,-7)
        row.sub:ClearAllPoints();row.sub:SetPoint("BOTTOMLEFT",58,6);row.sub:SetPoint("BOTTOMRIGHT",-8,6)
        row.title:SetText((entry.complete and "[x] " or "[ ] ")..entry.item.name)
        row.sub:SetText("P"..entry.priority.." | "..entry.item.zone.."\n"..entry.item.source)
        row:SetScript("OnClick",function() S.plannerSelection=entry;S.RenderPlanner() end)
    end)
    local selected=S.plannerSelection;local found=false
    for _,row in ipairs(rows) do if selected and selected.slot==row.slot and selected.item.id==row.item.id then selected=row;found=true end end
    if not found then selected=rows[1] end;S.plannerSelection=selected
    A.UI.ItemDetails.Render(f.details,selected and selected.slot or "Head",selected and selected.item)
    if #rows==0 then f.details.scroll:SetText("No goals match this filter.\n\nSelect targets in Character & Gear / Item Explorer, or choose All to see completed goals.\n\nTargets carry their own source and location. Missing crafting costs are shown in Professions. No optimal route is calculated.") end
end
function S.CreateActivities(parent)
    local f=twoColumns(parent);S.activities=f;f.heading:SetText("DAILY / WEEKLY CHECKLIST")
    local W=A.UI.Widgets
    f.period=W.Menu(f.right,"Daily",{"Daily","Weekly"},function(value) S.period=value;S.RenderActivities() end)
    f.period:SetPoint("BOTTOMLEFT",14,14);f.period:SetPoint("BOTTOMRIGHT",-14,14)
    return f
end
function S.RenderActivities()
    A.Services.Persistence.ResetActivities();local p=A.Services.Persistence.Profile();local f=S.activities
    local period=S.period or "Daily";local state=period=="Daily" and p.activities or p.weekly
    local rows={};for i,route in ipairs(A.Data.routes) do rows[#rows+1]={id=i,route=route} end
    table.sort(rows,function(a,b) return a.route.zone<b.route.zone end)
    f.period:SetText(period)
    f.list:Render(rows,function(row,entry)
        row.title:SetText((state[entry.id] and "[x] " or "[ ] ")..entry.route.name);row.sub:SetText(entry.route.zone)
        row:SetScript("OnClick",function() state[entry.id]=not state[entry.id];S.activity=entry;S.RenderActivities() end)
    end)
    local lines={period.." checklist","Daily reset: local calendar date. Weekly reset: local Monday, not the realm reset.","These are repeatable planning suggestions, not verified daily / weekly quests.","Click an activity to toggle completion.",""}
    if S.activity then lines[#lines+1]=S.activity.route.zone;lines[#lines+1]=S.activity.route.name;lines[#lines+1]=S.activity.route.detail end
    f.text:SetText(table.concat(lines,"\n"))
end
function S.CreateSettings(parent)
    local W=A.UI.Widgets;local f=W.Panel(parent);f:SetAllPoints(parent);S.settings=f
    f.auto=W.Button(f,"Detect character spec / professions again",function() A.db.manualSpec=false;A.db.manualProfessions=false;A.Services.Character.Read();A.UI.ViewChanged() end)
    f.auto:SetSize(360,28);f.auto:SetPoint("TOPLEFT",16,-16)
    f.reminders=W.Button(f,"",function() A.db.settings.moonclothReminders=A.db.settings.moonclothReminders==false;S.RenderSettings() end)
    f.reminders:SetSize(340,28);f.reminders:SetPoint("LEFT",f.auto,"RIGHT",12,0)
    f.theme=W.Menu(f,'Theme',{'Modern Azeroth','Blizzard Classic Inspired'},function(name) A.db.settings.theme=name;A.UI.DesignSystem.Apply(name);S.RenderSettings() end)
    f.theme:SetSize(230,26);f.theme:SetPoint('TOPLEFT',16,-154)
    f.lootIndicators=W.Button(f,'',function() A.UI.LootIndicator.SetEnabled(not A.UI.LootIndicator.Enabled());S.RenderSettings() end)
    f.lootIndicators:SetPoint('LEFT',f.theme,'RIGHT',12,0);f.lootIndicators:SetSize(260,26)
    f.weightLabel=W.Label(f,"EP weights for this class / spec (client stat keys; comma separated)");f.weightLabel:SetPoint('TOPLEFT',16,-62)
    f.weights=W.Edit(f);f.weights:SetPoint('TOPLEFT',16,-82);f.weights:SetPoint('TOPRIGHT',-150,-82)
    f.saveWeights=W.Button(f,'Save EP',function()
        local weights,err=A.Services.Planner.ParseWeights(f.weights:GetText())
        if not weights then f.weightInfo:SetText(err);return end
        local p=A.Services.Persistence.Profile();p.epWeights=weights;p.epWeightsText=f.weights:GetText();f.weightInfo:SetText('Saved for '..A.db.viewClass..' / '..A.db.spec..'. Item EP is an estimate, not DPS.')
        A:Refresh()
    end);f.saveWeights:SetWidth(110);f.saveWeights:SetPoint('TOPRIGHT',-16,-82)
    f.weightInfo=W.Label(f,'');f.weightInfo:SetPoint('TOPLEFT',16,-115);f.weightInfo:SetPoint('TOPRIGHT',-16,-115);f.weightInfo:SetHeight(30)
    f.vendorExample=W.Button(f,'Track vendor: Arcanoweave Cloak',function() local o=A.Services.Objectives.Track(272411,'Back');A.UI.SetTab('Progression',{objectiveId=o.objectiveId}) end)
    f.vendorExample:SetPoint('TOPLEFT',16,-230);f.vendorExample:SetWidth(270)
    f.vendorInspect=W.Button(f,'Inspect open vendor',function() A.Services.MerchantObserver.Read();S.RenderSettings() end);f.vendorInspect:SetPoint('LEFT',f.vendorExample,'RIGHT',10,0);f.vendorInspect:SetWidth(190)
    f.vendorBind=W.Button(f,'Link observed NPC',function() A.Services.AcquisitionRequirementsResolver.BindObserved(272411);S.RenderSettings() end);f.vendorBind:SetPoint('LEFT',f.vendorInspect,'RIGHT',10,0);f.vendorBind:SetWidth(160)
    f.text=W.TextScroll(f);f.text:SetPoint("TOPLEFT",16,-272);f.text:SetPoint("BOTTOMRIGHT",-32,16)
    f.itemDiagnostics=W.Button(f,'',function() A.db.settings.itemStatDiagnostics=not A.db.settings.itemStatDiagnostics;A.Services.ItemStats.seenLogs={};A.Services.ItemStats.Invalidate(nil,false);S.RenderSettings() end)
    f.itemDiagnostics:SetPoint('TOPLEFT',16,-194);f.itemDiagnostics:SetWidth(250)
    f.inspectGloves=W.Button(f,'Inspect Felcloth Gloves',function() f.inspectedItem=18407;A.Services.ItemStats.Invalidate(18407,true);A.Services.ItemStats.Candidate(A.Data.items[18407]);S.RenderSettings() end)
    f.inspectGloves:SetPoint('LEFT',f.itemDiagnostics,'RIGHT',10,0);f.inspectGloves:SetWidth(190)
    f.clearItemDiagnostics=W.Button(f,'Clear log',function() A.db.itemStatDiagnostics={};A.Services.ItemStats.seenLogs={};S.RenderSettings() end)
    f.clearItemDiagnostics:SetPoint('LEFT',f.inspectGloves,'RIGHT',10,0);f.clearItemDiagnostics:SetWidth(100)
    f:SetScript('OnSizeChanged',function(self,width)
        local bw=math.max(120,(width-44)/2);self.auto:SetWidth(bw);self.reminders:SetWidth(bw)
    end)
    return f
end
function S.RenderSettings()
    local f=S.settings
    f.theme:SetText(A.db.settings.theme or 'Modern Azeroth')
    f.lootIndicators:SetText('Indicadores de botín: '..(A.UI.LootIndicator.Enabled() and 'On' or 'Off'))
    f.itemDiagnostics:SetText('Item stat diagnostics: '..(A.db.settings.itemStatDiagnostics and 'On' or 'Off'))
    local profile=A.Services.Persistence.Profile()
    if f.weightProfile~=profile then f.weightProfile=profile;f.weights:SetText(profile.epWeightsText or '');f.weightInfo:SetText('Example syntax: ITEM_MOD_INTELLECT_SHORT=0.2,ITEM_MOD_STAMINA_SHORT=0') end
    f.reminders:SetText("Mooncloth estimate reminders: "..(A.db.settings.moonclothReminders==false and "Off" or "On"))
    local _,build,_,interface=A.Compat.Call(GetBuildInfo)
    local lines={"Forever Companion "..A.version,"Client build: "..tostring(build).." / interface "..tostring(interface),
        "", "Data: Affliction Pre-BiS, imported and unranked. 29 specialization variants; other catalogs pending.",
        "Model: native DressUpModel with runtime feature checks; PlayerModel fallback. Preview requests do not prove the model rendered.",
        "Inventory: equipment and carried bags only, one cached scan per event batch; bank/alt contents are not read.",
        "Detected specialization: "..tostring(A.Services.Character.character.detectedSpec or "unavailable / select manually"),
        "Selected filter: "..A.db.viewClass.." / "..A.db.spec,
        "Persistence: original per-character SavedVariables, schema 3; legacyBackup retained. Saved by WoW on /reload or logout.",
        "", "Commands: /fwc | gear | explorer | route | prof | specs | settings | refresh | diag",
        "/fwc choose <slot 1-17> <candidate> | done <slot> | mooncloth | history",
        "", "EP: enter your own WoWSims simulation weights using client ITEM_MOD keys and matching units. Explicitly set irrelevant stats to 0. Percent is item EP change, not DPS. Procs, enchants, set bonuses and caps can invalidate the estimate. Blank clears weights.",
        "", "No automatic equipping, crafting, point spending or web fetching.",
        "", "Recent diagnostics:"}
    for _,message in ipairs(A.diagnostics) do lines[#lines+1]=message end
    if #A.diagnostics==0 then lines[#lines+1]="No recorded compatibility errors. In-game validation still required." end
    if f.inspectedItem then local record=A.Services.ItemStats.Candidate(A.Data.items[f.inspectedItem]);lines[#lines+1]='Inspected item: '..f.inspectedItem..' · '..A.Services.ItemStats.Describe(record) end
    lines[#lines+1]='Not present means not exposed by the API, not a confirmed zero. Enchants, gems, procs and set effects are not guaranteed by GetItemStats.'
    local merchant=A.Services.MerchantObserver.active[272411];f.vendorBind:SetEnabled(merchant~=nil)
    if merchant then lines[#lines+1]='Observed NPC: '..tostring(merchant.vendorName)..' (#'..tostring(merchant.npcId)..'). Link observed NPC is an explicit user mapping, not verification of the source database.' end
    lines[#lines+1]=A.Services.AcquisitionRequirementsResolver.Summary(272411)
    lines[#lines+1]='Offline item guide: 157 item references, 17 enhancements and recipes/materials for 29 crafted items. Vendor requirements remain a partial pilot. See docs/ITEM-GUIDE-3.4.md. Data from ForeverDB.net · https://foreverdb.net'
    lines[#lines+1]=A.Services.ItemStats.Report()
    lines[#lines+1]='Loot indicator: '..A.UI.LootIndicator.mode..'. /fwc loot on | off. Uses full live item links and your EP weights; incomplete comparisons remain marked.'
    f.text:SetText(table.concat(lines,"\n\n"))
end
