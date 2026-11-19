local A=FWC
local eventFrame=CreateFrame("Frame");A.eventFrame=eventFrame
local initialized=false
local function safe(fn,...)
    local ok,err=pcall(fn,...)
    if not ok then A:Log(err);A:Print("A module could not refresh. See /fwc diag.") end
    return ok
end
local function initialize()
    if initialized then return end
    A.Services.Catalog.Validate();A.Services.Persistence.Init()
    safe(A.Services.Character.Read);safe(A.Services.Character.ReadTalents);A.Services.Inventory.Scan()
    local _,_,_,interface=A.Compat.Call(GetBuildInfo)
    if interface and interface~=16001 then A:Log("Client interface differs from target 16001: "..tostring(interface)) end
    A.UI.tab=A.db.lastRoute or 'Dashboard'
    initialized=true;safe(A.UI.Tracker.Create);safe(A.UI.LootIndicator.Init);A:Print(A.version.." loaded. /fwc")
end
local function refresh()
    A.Services.Inventory.Scan();A:Refresh()
end
local queued=false
local function queueRefresh()
    if queued then return end;queued=true
    if C_Timer and type(C_Timer.After)=="function" then
        C_Timer.After(.15,function() queued=false;safe(refresh) end)
    else
        -- A one-shot debounce, never a permanent polling/scan loop.
        local elapsed=0
        eventFrame:SetScript("OnUpdate",function(self,delta)
            elapsed=elapsed+delta;if elapsed>=.15 then self:SetScript("OnUpdate",nil);queued=false;safe(refresh) end
        end)
    end
end
A.Services.ItemStats.OnDataAvailable=function() if initialized then queueRefresh() end end
eventFrame:SetScript("OnEvent",function(_,event,addon,result)
    if event=="ADDON_LOADED" then if addon=="ForeverWarlockCompanion" then safe(initialize) end;return end
    if event=="PLAYER_LOGIN" or event=="PLAYER_ENTERING_WORLD" then
        safe(initialize);safe(A.Services.Character.Read);safe(A.Services.Character.ReadTalents);queueRefresh();return
    end
    if not initialized then return end
    if event=='LOOT_OPENED' or event=='LOOT_READY' then A.UI.LootIndicator.lootOpen=true;safe(A.UI.LootIndicator.Init);safe(A.UI.LootIndicator.ScheduleLoot)
    elseif event=='LOOT_CLOSED' then A.UI.LootIndicator.lootOpen=false;for _,badge in pairs(A.UI.LootIndicator.badges) do badge:Hide() end
    elseif event=='LOOT_SLOT_CLEARED' or event=='LOOT_SLOT_CHANGED' then safe(A.UI.LootIndicator.ScheduleLoot)
    elseif event=='MODIFIER_STATE_CHANGED' then safe(A.UI.LootIndicator.Refresh)
    elseif event=='MERCHANT_SHOW' then A.Services.MerchantObserver.isOpen=true;safe(A.Services.MerchantObserver.Read);A:Refresh()
    elseif event=='MERCHANT_UPDATE' then safe(A.Services.MerchantObserver.Read);A:Refresh()
    elseif event=='MERCHANT_CLOSED' then A.Services.MerchantObserver.Close();A:Refresh()
    elseif event=='PLAYER_MONEY' or event=='CURRENCY_DISPLAY_UPDATE' then A:Refresh()
    elseif event=="PLAYER_LOGOUT" then
        if A.UI.window then A.db.window.width=A.UI.window:GetWidth();A.db.window.height=A.UI.window:GetHeight() end
    elseif event=="PLAYER_TALENT_UPDATE" or event=="ACTIVE_TALENT_GROUP_CHANGED" or event=="TRAIT_CONFIG_UPDATED" or event=="PLAYER_SPECIALIZATION_CHANGED" then
        safe(A.Services.Character.Read);safe(A.Services.Character.ReadTalents);A:Refresh()
    elseif event=="SKILL_LINES_CHANGED" or event=="PLAYER_LEVEL_UP" then safe(A.Services.Character.Read);A:Refresh()
    elseif event=="UPDATE_FACTION" then A:Refresh()
    elseif event=="GET_ITEM_INFO_RECEIVED" or event=="ITEM_DATA_LOAD_RESULT" then
        local id=tonumber(addon)
        if id then
            local relevant=A.Data.items[id] or A.Services.Inventory.snapshot.bags[id] or A.Services.ItemStats.Tracks(id)
            for _,entry in pairs(A.Services.Inventory.snapshot.equipped) do if entry.id==id then relevant=true end end
            if relevant then A.Services.ItemStats.Loaded(id,result,false);safe(A.Services.MerchantObserver.Read);queueRefresh() end
        end
    else queueRefresh() end
end)
for _,event in ipairs({"LOOT_OPENED","LOOT_READY","LOOT_CLOSED","LOOT_SLOT_CLEARED","LOOT_SLOT_CHANGED","MODIFIER_STATE_CHANGED","MERCHANT_SHOW","MERCHANT_UPDATE","MERCHANT_CLOSED","PLAYER_MONEY","CURRENCY_DISPLAY_UPDATE","ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LOGOUT","BAG_UPDATE","BAG_UPDATE_DELAYED","PLAYER_EQUIPMENT_CHANGED","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT","PLAYER_REGEN_ENABLED","PLAYER_TALENT_UPDATE","ACTIVE_TALENT_GROUP_CHANGED","TRAIT_CONFIG_UPDATED","PLAYER_SPECIALIZATION_CHANGED","SKILL_LINES_CHANGED","PLAYER_LEVEL_UP","UPDATE_FACTION"}) do
    if not A.Compat.Method(eventFrame,"RegisterEvent",event) then A:Log("Event unavailable: "..event) end
end
SLASH_FWC1="/fwc"
SlashCmdList.FWC=function(message)
    if not safe(initialize) then return end
    local cmd,a,b=string.match(string.lower(message or ""),"^%s*(%S*)%s*(%S*)%s*(%S*)")
    local tabs={dashboard='Dashboard',gear="Character & Gear",explorer="Item Explorer",stats="Stats",route="Daily / Weekly",prof="Professions",specs="Talents",settings="Settings",planner="Progression",dungeons='Dungeons',objectives='Progression'}
    if cmd=="loot" then
        local enabled=a=='on' or a~='off' and not A.UI.LootIndicator.Enabled()
        A.UI.LootIndicator.SetEnabled(enabled);A:Print('Indicadores de botín: '..(enabled and 'activados' or 'desactivados'));return
    elseif cmd=="tracker" then A.UI.Tracker.Toggle();return
    elseif cmd=="diag" then
        A:Print("Build target 16001; cached inventory scans: "..A.Services.Inventory.scans)
        for _,line in ipairs(A.diagnostics) do A:Print(line) end
        for line in A.Services.ItemStats.Report():gmatch("[^\n]+") do A:Print(line) end;return
    elseif cmd=="history" then
        for i=#A.db.moonclothHistory,math.max(1,#A.db.moonclothHistory-9),-1 do
            if type(A.db.moonclothHistory[i])=="number" then A:Print(A.Compat.Date("%Y-%m-%d %H:%M",A.db.moonclothHistory[i])) end
        end;return
    elseif cmd=="mooncloth" then
        if A.Services.Professions.RecordMooncloth() then A:Print("Manual timestamp recorded; 95h remains an unverified estimate.") end
    elseif cmd=="choose" or cmd=="done" then
        local slot=A.Data.slots[tonumber(a) or 0]
        if not slot then A:Print("Use a slot number from 1 to 17.");return end
        if cmd=="choose" then
            local ids=A.Services.Catalog.List(A.db.viewClass,A.db.spec,A.db.mode,slot.key)
            if not ids[tonumber(b) or 0] then A:Print("Candidate unavailable in this catalog.");return end
            A.Services.Catalog.Select(slot.key,ids[tonumber(b)])
        else
            local item=A.Services.Catalog.Target(slot.key)
            if item then local p=A.Services.Persistence.Profile();p.obtained[item.id]=not p.obtained[item.id] end
        end
    elseif cmd=="refresh" then A.Services.ItemStats.Invalidate(nil,true);safe(A.Services.Character.Read);safe(A.Services.Character.ReadTalents);A.Services.Inventory.Scan()
    elseif cmd~="" and not tabs[cmd] then A:Print("Commands: gear, explorer, planner, route, prof, specs, settings, refresh, diag, loot on/off, choose, done, mooncloth, history");return end
    if not A.UI.window then if not safe(A.UI.Create) then return end end
    if tabs[cmd] then A.UI.tab=tabs[cmd] end
    if cmd=="" and A.UI.window:IsShown() then A.UI.window:Hide()
    else A.UI.window:Show();safe(A.UI.Render) end
end
