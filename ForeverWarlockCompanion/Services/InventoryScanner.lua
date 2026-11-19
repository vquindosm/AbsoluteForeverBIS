local A = FWC
local S = { snapshot = {bags={}, equipped={}, names={}, complete=false}, scans=0 }; A.Services.Inventory = S
function S.Scan()
    if A.Compat.InCombat() then S.pending = true; return end
    S.pending = false
    local data = {bags={}, equipped={}, names={}, complete=true,namesComplete=true,checkedAt=A.Compat.Now()}
    local function collect()
        local bagAvailable = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemLink
        data.complete = type(bagAvailable) == "function"
        local maxBag = type(NUM_BAG_SLOTS) == "number" and NUM_BAG_SLOTS or 4
        local bags = {}; for bag = 0, maxBag do bags[#bags + 1] = bag end
        local reagentBag = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
        if type(reagentBag) == "number" and reagentBag > maxBag then bags[#bags + 1] = reagentBag end
        for _, bag in ipairs(bags) do
            local count = A.Compat.BagSlots(bag)
            if not A.Compat.Readable(count) or type(count) ~= "number" then data.complete = false
            else
                for slot = 1, count do
                    local id, quantity, link, checked = A.Compat.BagItem(bag, slot)
                    if not checked or not A.Compat.Readable(id) or not A.Compat.Readable(quantity) then data.complete = false
                    elseif id then
                        quantity = type(quantity) == "number" and quantity or 1
                        data.bags[id] = (data.bags[id] or 0) + quantity
                        local name = A.Compat.ItemInfo(link or id).name
                        if name then data.names[name] = (data.names[name] or 0) + quantity else data.namesComplete=false end
                    end
                end
            end
        end
        data.equipmentChecked = type(GetInventoryItemLink) == "function" or type(GetInventoryItemID) == "function"
        for _, slot in ipairs(A.Data.slots) do
            local id, link, checked = A.Compat.Equipped(slot.inventory)
            if not checked or not A.Compat.Readable(id) or not A.Compat.Readable(link) then data.equipmentChecked = false
            else data.equipped[slot.key] = {id=id, link=link,checked=true} end
        end
    end
    local ok, err = pcall(collect)
    if not ok then data.complete=false; data.equipmentChecked=false; A:Log("Inventory: " .. tostring(err)) end
    S.snapshot = data; S.scans = S.scans + 1
    if A.Services.ItemStats then for key,r in pairs(A.Services.ItemStats.records) do if r.kind=='equipped' then A.Services.ItemStats.records[key]=nil end end end
end
function S.Status(item)
    if not item then return "Unknown" end
    local data = S.snapshot
    for _, entry in pairs(data.equipped) do if entry.id == item.id then return "Equipped" end end
    if (data.bags[item.id] or 0) > 0 then return "In bags" end
    if data.complete and data.equipmentChecked then return "Not found" end
    return "Unchecked"
end
function S.Count(reagent)
    if reagent.id then return S.snapshot.bags[reagent.id] or 0, S.snapshot.complete end
    -- An imported English name cannot prove absence on a localized client.
    local n = S.snapshot.names[reagent.name]
    local locale=A.Compat.Call(GetLocale)
    return n or 0, n ~= nil or (S.snapshot.complete and S.snapshot.namesComplete and (locale=="enUS" or locale=="enGB"))
end
