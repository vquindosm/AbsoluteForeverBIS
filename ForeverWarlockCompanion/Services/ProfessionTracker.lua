local A = FWC
local T = {}; A.Services.Professions = T
function T.Recipes()
    local result = {}; local p1, p2 = A.db.professions[1], A.db.professions[2]
    for _, recipe in ipairs(A.Data.recipes) do
        if (not p1 or p1=="Any profession") and (not p2 or p2=="Any profession")
            or recipe.profession==p1 or recipe.profession==p2 then result[#result+1] = recipe end
    end
    return result
end
function T.Materials(recipe)
    if not recipe.reagents then return nil, false end
    local rows = {}; local ready = recipe.provenance ~= "legacy_unverified"
    for _, reagent in ipairs(recipe.reagents) do
        local count, checked = A.Services.Inventory.Count(reagent)
        rows[#rows+1] = {name=reagent.name,qty=reagent.qty,available=count,missing=math.max(0,reagent.qty-count),checked=checked}
        if not checked or count < reagent.qty then ready = false end
    end
    return rows, ready
end
function T.Cooldown()
    local h = A.db.moonclothHistory; local last = h[#h]
    if type(last) ~= "number" then return nil end
    return math.max(0, last + 95*3600 - A.Compat.Now())
end
function T.RecordMooncloth()
    local h = A.db.moonclothHistory; local now = A.Compat.Now()
    if type(h[#h]) == "number" and now - h[#h] < 60 then return false end
    h[#h+1] = now; return true
end
function T.Priority(recipe)
    local p = A.Services.Persistence.Profile()
    return p.priorities[recipe.key] or 2
end
function T.Remind()
    if A.db.settings.moonclothReminders==false then return end
    local remaining=T.Cooldown();local h=A.db.moonclothHistory;local last=h[#h]
    if remaining==0 and A.db.lastMoonclothReminder~=last then
        A.db.lastMoonclothReminder=last
        A:Print("Estimated Mooncloth window reached. Verify the real recipe cooldown before crafting.")
    end
end
