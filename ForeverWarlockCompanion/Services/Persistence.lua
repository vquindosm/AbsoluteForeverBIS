local A = FWC
local P = {}; A.Services.Persistence = P
function P.Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}; for k, v in pairs(value) do copy[k] = P.Copy(v) end
    return copy
end
local function ensure(t, key)
    if type(t[key]) ~= "table" then t[key] = {} end
    return t[key]
end
function P.Init()
    if type(ForeverWarlockCompanionDB) ~= "table" then ForeverWarlockCompanionDB = {} end
    local d = ForeverWarlockCompanionDB; A.db = d
    ensure(d, "profiles"); ensure(d, "settings"); ensure(d, "professions")
    ensure(d, "moonclothHistory"); ensure(d, "window")
    if type(d.schema)~='number' or d.schema<2 then
        if not d.legacyBackup then d.legacyBackup = P.Copy(d) end
        if d.viewClass or d.spec then d.manualSpec=true end
        if d.professions[1] or d.professions[2] then d.manualProfessions=true end
        local profile = P.Profile("WARLOCK", "Affliction")
        for _, slot in ipairs(A.Data.slots) do
            local key = "affliction:" .. slot.legacy
            local name = type(d.selected) == "table" and d.selected[key]
            local item = name and A.Services.Catalog.FindByName(name)
            if name and name~="TBD" and not item then profile.unresolved[slot.key]=name end
            if item then profile.targets["Pre-BiS"][slot.key] = item.id end
            if type(d.done) == "table" and d.done[key] then
                local target = item or A.Services.Catalog.Default("WARLOCK", "Affliction", "Pre-BiS", slot.key)
                if target and not profile.unresolved[slot.key] then profile.obtained[target.id] = true end
            end
        end
        profile.activities = type(d.routines) == "table" and P.Copy(d.routines) or {}
        profile.activityDay = d.day; d.schema = 2
    end
    local _, class = A.Compat.Call(UnitClass, "player")
    d.viewClass = A.Data.classes[d.viewClass] and d.viewClass or class or "WARLOCK"
    if not A.Data.classes[d.viewClass] then d.viewClass = "WARLOCK" end
    local valid = false
    for _, spec in ipairs(A.Data.classes[d.viewClass]) do if d.spec == spec then valid = true end end
    if not valid then d.spec = A.Data.classes[d.viewClass][1] end
    d.mode = d.mode == "BiS" and "BiS" or "Pre-BiS"
    if d.schema==2 then
        if not d.preV3Backup then d.preV3Backup=P.Copy(d) end
        A.Services.Objectives.Migrate();d.schema=3
    end
end
function P.Profile(class, spec)
    local d = A.db or ForeverWarlockCompanionDB
    local p = ensure(ensure(d, "profiles"), (class or d.viewClass) .. ":" .. (spec or d.spec))
    local targets = ensure(p, "targets"); ensure(targets, "Pre-BiS"); ensure(targets, "BiS")
    ensure(p, "obtained"); ensure(p, "priorities"); ensure(p, "planner");ensure(p,"unresolved")
    ensure(p, "activities"); ensure(p, "weekly"); ensure(p, "talents")
    ensure(p,'objectives')
    return p
end
function P.SetView(class, spec)
    A.db.viewClass = class; A.db.spec = spec or A.Data.classes[class][1]; A.db.manualSpec = true
end
function P.ResetActivities()
    local p = P.Profile(); local today = A.Compat.Date("%Y%m%d")
    if p.activityDay ~= today then p.activities = {}; p.activityDay = today end
    -- Local Monday is a checklist boundary, not the realm's weekly reset.
    local weekday = tonumber(A.Compat.Date("%w")) or 0
    local localDay=A.Compat.Call(date,"*t")
    local monday
    if type(localDay)=="table" then
        localDay.day=localDay.day-((weekday+6)%7);localDay.hour=12;localDay.min=0;localDay.sec=0;localDay.isdst=nil
        monday=A.Compat.Call(time,localDay)
    end
    local week = A.Compat.Date("%Y%m%d",monday or (A.Compat.Now()-((weekday+6)%7)*86400))
    if p.activityWeek ~= week then p.weekly = {}; p.activityWeek = week end
end
