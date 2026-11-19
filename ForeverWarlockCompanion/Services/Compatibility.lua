local A = FWC
local C = {}; A.Compat = C
local unpackValues = unpack or table.unpack
function C.Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local results = {pcall(fn, ...)}
    if not results[1] then return nil end
    return unpackValues(results, 2)
end
function C.Readable(value)
    if type(canaccessvalue) == "function" then
        local ok, readable = pcall(canaccessvalue, value)
        return ok and readable
    end
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        return ok and not secret
    end
    return true
end
function C.Method(object, method, ...)
    if not object or type(object[method]) ~= "function" then return false end
    return pcall(object[method], object, ...)
end
function C.ItemID(link)
    if not C.Readable(link) then return nil end
    local id=type(link)=='number' and link or type(link)=='string' and tonumber(string.match(link,'item:(%d+)')) or nil
    if type(id)=='number' and id==id and id>0 and id<math.huge and id%1==0 then return id end
    return nil
end
-- Keep the supplied instance link. GetItemInfo may return a base/canonical link.
function C.ItemInfo(item)
    if not item or not C.Readable(item) then return {state='unavailable'} end
    local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
    local provider=C_Item and type(C_Item.GetItemInfo)=='function' and 'C_Item.GetItemInfo' or 'GetItemInfo'
    if type(fn)~='function' then return {state='unavailable',provider=provider} end
    local ok,name,link,quality,level,requiredLevel,_,_,_,equipLoc,icon,_,classID,subclassID=pcall(fn,item)
    local supplied=type(item)=='string' and C.ItemID(item) and item or nil
    if not ok then return {state='error',error=tostring(name),link=supplied,provider=provider} end
    if not C.Readable(name) or not C.Readable(link) then return {state='error',error='Restricted item identity',provider=provider} end
    local expected=C.ItemID(item)
    if expected and link and C.ItemID(link)~=expected then return {state='error',error='Identity link belongs to another item',link=supplied,provider=provider} end
    if name~=nil and type(name)~='string' then return {state='error',error='Invalid item name',link=supplied,provider=provider} end
    if not C.Readable(quality) then quality=nil end;if not C.Readable(level) then level=nil end
    if not C.Readable(requiredLevel) or type(requiredLevel)~='number' then requiredLevel=nil end
    if not C.Readable(classID) or type(classID)~='number' then classID=nil end
    if not C.Readable(subclassID) or type(subclassID)~='number' then subclassID=nil end
    if not C.Readable(equipLoc) then equipLoc=nil end;if not C.Readable(icon) then icon=nil end
    if not name and A.Services.ItemStats then A.Services.ItemStats.Request(item) end
    return {name=name,link=supplied or link,baseLink=link,quality=quality,level=level,requiredLevel=requiredLevel,classID=classID,subclassID=subclassID,equipLoc=equipLoc,icon=icon,
        state=name and 'loaded' or 'pending',provider=provider}
end
function C.BagSlots(bag)
    return C.Call(C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots, bag)
end
function C.BagItem(bag, slot)
    if C_Container and type(C_Container.GetContainerItemInfo) == "function" then
        local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
        if not ok then return nil,nil,nil,false end
        if type(info) == "table" then return info.itemID or C.ItemID(info.hyperlink), info.stackCount, info.hyperlink,true end
        return nil,nil,nil,true
    end
    if type(GetContainerItemInfo)~="function" or type(GetContainerItemLink)~="function" then return nil,nil,nil,false end
    local ok, _, count = pcall(GetContainerItemInfo, bag, slot)
    local linked, link = pcall(GetContainerItemLink, bag, slot)
    return C.ItemID(link), count, link,ok and linked
end
function C.Equipped(slot)
    local id,link,idChecked,linkChecked
    if type(GetInventoryItemLink)=="function" then linkChecked,link=pcall(GetInventoryItemLink,"player",slot) end
    if type(GetInventoryItemID)=="function" then idChecked,id=pcall(GetInventoryItemID,"player",slot) end
    if not idChecked then id=nil end;if not linkChecked then link=nil end
    return id or C.ItemID(link),link,idChecked or linkChecked or false
end
-- Legacy adapter for third-party/older callers; absence is never filled with zero.
function C.Stats(link)
    if A.Services.ItemStats then
        local r=A.Services.ItemStats.Read(link)
        if r.state=='confirmed' then return r.values end
        return nil
    end
    return nil
end
function C.Tooltip(owner, item)
    if not GameTooltip or not item then return end
    C.Method(GameTooltip, "SetOwner", owner, "ANCHOR_RIGHT")
    local ok = C.Method(GameTooltip, "SetHyperlink", type(item) == "number" and ("item:" .. item) or item)
    if ok then C.Method(GameTooltip, "Show") end
end
function C.Now() return C.Call(time) or 0 end
function C.Date(format, timestamp) return C.Call(date, format, timestamp) or "unknown" end
function C.InCombat() return C.Call(InCombatLockdown) == true end
