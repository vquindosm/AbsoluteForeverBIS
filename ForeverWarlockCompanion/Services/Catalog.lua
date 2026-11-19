local A = FWC
local G = {}; A.Services.Catalog = G
function G.Validate()
    for id, item in pairs(A.Data.items) do
        if type(id) ~= "number" or id<=0 or type(item)~="table" or type(item.name) ~= "string" or item.name == "" then
            A.Data.items[id] = nil; A:Log("Rejected invalid catalog item: " .. tostring(id))
        else
            item.id=id
            for _,field in ipairs({"source","sourceType","zone"}) do if type(item[field])~="string" then item[field]="Unknown" end end
            if type(item.quality)~="number" or item.quality<0 or item.quality>7 then item.quality=1 end
            if type(item.icon)~="string" and type(item.icon)~="number" then item.icon="Interface\\Icons\\INV_Misc_QuestionMark" end
            if type(item.sourceStats)~="table" then item.sourceStats={} end
        end
    end
    for spec, modes in pairs(A.Data.catalogs) do
        if type(modes)~="table" then A.Data.catalogs[spec]=nil
        else
            for mode, slots in pairs(modes) do
                if type(slots)~="table" then modes[mode]={}
                else
                    for slot,ids in pairs(slots) do
                        if type(ids)~="table" then slots[slot]={}
                        else for i=#ids,1,-1 do if not A.Data.items[ids[i]] then table.remove(ids,i) end end end
                    end
                end
            end
        end
    end
    for i=#A.Data.recipes,1,-1 do
        local recipe=A.Data.recipes[i]
        if type(recipe)~="table" or type(recipe.name)~="string" or type(recipe.profession)~="string" then
            table.remove(A.Data.recipes,i);A:Log("Rejected invalid recipe")
        elseif recipe.reagents then
            if type(recipe.reagents)~="table" or #recipe.reagents==0 then recipe.reagents=nil
            else for _,r in ipairs(recipe.reagents) do
                if type(r)~="table" or type(r.name)~="string" or type(r.qty)~="number" or r.qty<=0 or r.qty%1~=0 then recipe.reagents=nil;break end
            end end
        end
    end
end
function G.List(class, spec, mode, slot)
    local catalog = A.Data.catalogs[class .. ":" .. spec]
    return catalog and catalog[mode] and catalog[mode][slot] or {}
end
function G.Default(class, spec, mode, slot) return A.Data.items[G.List(class, spec, mode, slot)[1]] end
function G.Target(slot)
    local profile=A.Services.Persistence.Profile()
    local id = profile.targets[A.db.mode][slot]
    if id and A.Data.items[id] then return A.Data.items[id] end
    if A.db.mode=="Pre-BiS" and profile.unresolved[slot] then return nil end
    return G.Default(A.db.viewClass, A.db.spec, A.db.mode, slot)
end
function G.FindByName(name)
    for _, item in pairs(A.Data.items) do if item.name == name then return item end end
end
function G.Contains(slot, id)
    for _, candidate in ipairs(G.List(A.db.viewClass, A.db.spec, A.db.mode, slot)) do if candidate == id then return true end end
    return false
end
function G.Select(slot, id)
    if not G.Contains(slot, id) then return false end
    local p=A.Services.Persistence.Profile();p.targets[A.db.mode][slot]=id;p.unresolved[slot]=nil;return true
end
function G.Filter(slot, search, source)
    local rows = {}; local needle = string.lower(search or "")
    for _, s in ipairs(A.Data.slots) do
        if not slot or slot == "All slots" or slot == s.key then
            for _, id in ipairs(G.List(A.db.viewClass, A.db.spec, A.db.mode, s.key)) do
                local item = A.Data.items[id]
                if item and (not source or source == "All sources" or source == item.sourceType)
                    and string.find(string.lower(item.name), needle, 1, true) then rows[#rows + 1] = {slot=s.key, item=item} end
            end
        end
    end
    return rows
end
