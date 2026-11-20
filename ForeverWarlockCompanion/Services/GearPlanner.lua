local A = FWC
local P = {}; A.Services.Planner = P
-- EP is an optional user-supplied linear model, never a DPS simulation.
function P.ParseWeights(text)
    local result, count={},0
    if not text or text:match('^%s*$') then return result end
    for part in (text..','):gmatch('(.-),') do
        local key,value=part:match('^%s*([%w_]+)%s*=%s*([%+%-]?[%d%.]+)%s*$')
        value=tonumber(value)
        if not key or not key:match('^ITEM_MOD_[%w_]+$') or not value or value~=value or math.abs(value)>100000 or result[key]~=nil then
            return nil,'Use ITEM_MOD_KEY=number, separated by commas; no duplicates.'
        end
        result[key]=value;count=count+1
    end
    if count==0 then return nil,'No weights entered.' end
    return result
end
function P.WeightedComparison(before,after,weights)
    if type(before)~='table' or type(after)~='table' then return nil,'Item stats not loaded or unavailable.' end
    if type(weights)~='table' or not next(weights) then return nil,'Configura los pesos en la pestaña Stats.' end
    local normalized,weightError=A.Services.ItemStats.Weights(weights);if not normalized then return nil,weightError end;weights=normalized
    for key,value in pairs(weights) do if value~=0 and not key:match('^ITEM_MOD_') then return nil,'Unsupported weighted attribute: '..key end end
    local keys={};for k in pairs(before) do keys[k]=true end;for k in pairs(after) do keys[k]=true end
    local old,new,used=0,0,0
    for key in pairs(keys) do
        if type(key)=='string' and key:match('^ITEM_MOD_') then
            if before[key]==nil or after[key]==nil then return nil,'Attribute not present on both items: '..key end
            if before[key]~=0 or after[key]~=0 then
            if weights[key]==nil then return nil,'Missing weight: '..key..' (enter 0 if intentionally ignored).' end
            if type(before[key])~='number' or type(after[key])~='number' or type(weights[key])~='number' then return nil,'Invalid stat or weight: '..key end
            old=old+before[key]*weights[key];new=new+after[key]*weights[key];used=used+1
            end
        end
    end
    if old~=old or new~=new or math.abs(old)==math.huge or math.abs(new)==math.huge then return nil,'Rating unavailable: non-finite EP result.' end
    if used==0 or old<=0 then return nil,'Insufficient weighted stats or equipped score is not positive.' end
    return {before=old,after=new,delta=(new-old)/math.abs(old)*100}
end
function P.SlotScore(slot,item)
    if A.Services.ItemInspector and A.Services.ItemInspector.IsPilot(item) then local r=A.Services.UpgradeComparison.ForSlot(slot,item);return r.score or nil,r.reason end
    local eq=A.Services.Inventory.snapshot.equipped[slot]
    if not eq or not eq.id or not item then return nil,'Equipment or target unavailable.' end
    local stats=A.Services.ItemStats;local before=stats.Equipped(slot);local after=stats.Candidate(item)
    if before.state~='confirmed' or after.state~='confirmed' then return nil,'Rating unavailable: '..stats.Describe(before)..' / '..stats.Describe(after) end
    local profile=A.Services.Persistence.Profile()
    return P.WeightedComparison(before.values,after.values,profile.epWeights)
end
function P.Rows(filter)
    local rows = {}; local profile = A.Services.Persistence.Profile()
    local available, used = {}, {}
    local snapshot=A.Services.Inventory.snapshot
    for id,count in pairs(snapshot.bags) do available[id]=count end
    for _,entry in pairs(snapshot.equipped) do if entry.id then available[entry.id]=(available[entry.id] or 0)+1 end end
    for id,obtained in pairs(profile.obtained) do if obtained then available[id]=math.max(available[id] or 0,1) end end
    local included={}
    for _, slot in ipairs(A.Data.slots) do
        local item = A.Services.Catalog.Target(slot.key)
        if item then
            local status = A.Services.Inventory.Status(item)
            local complete = (available[item.id] or 0) > (used[item.id] or 0)
            if complete then used[item.id]=(used[item.id] or 0)+1 end
            included[item.id]=true
            local priority = profile.priorities[item.id] or 2
            if not filter or filter=="All" or (filter=="Missing" and not complete)
                or (filter=="Completed" and complete) or (filter=="High priority" and priority==1)
                or (filter=="Added manually" and profile.planner[item.id]) then
                rows[#rows+1] = {slot=slot.key,item=item,status=status,complete=complete,priority=priority}
            end
        end
    end
    for id,slot in pairs(profile.planner) do
        local item=A.Data.items[id]
        if item and not included[id] and A.Data.slotByKey[slot] then
            local complete=(available[id] or 0)>0
            local priority=profile.priorities[id] or 2
            if not filter or filter=="All" or filter=="Added manually" or (filter=="Missing" and not complete)
                or (filter=="Completed" and complete) or (filter=="High priority" and priority==1) then
                rows[#rows+1]={slot=slot,item=item,status=A.Services.Inventory.Status(item),complete=complete,priority=priority}
            end
        end
    end
    table.sort(rows,function(a,b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        if a.item.zone ~= b.item.zone then return a.item.zone < b.item.zone end
        return a.slot < b.slot
    end)
    return rows
end
function P.Comparison(slot, item)
    local eq = A.Services.Inventory.snapshot.equipped[slot]
    if not eq or not eq.id then return "Equipped slot empty or unchecked. Native comparison unavailable." end
    local live = A.Compat.ItemInfo(eq.link or eq.id)
    local lines = {"Equipped: "..(live.name or ("Item #"..eq.id))}
    local score,reason=P.SlotScore(slot,item)
    lines[#lines+1]=score and string.format('Estimated item EP: %.1f → %.1f (%+.1f%%)',score.before,score.after,score.delta) or ('EP unavailable: '..reason)
    lines[#lines+1]='Item stat-weight estimate only; not DPS. Effects, caps and set bonuses may be excluded.'
    local stats=A.Services.ItemStats;local before=stats.Equipped(slot);local after=stats.Candidate(item)
    lines[#lines+1]='Equipped data: '..stats.Describe(before);lines[#lines+1]='Candidate data: '..stats.Describe(after)
    for _,entry in ipairs(stats.Keys(before,after)) do
        local delta=stats.Delta(before,after,entry.key)
        if delta and delta~=0 then lines[#lines+1]=entry.label..': '..string.format('%+g',delta) end
    end
    lines[#lines+1]='Absent is not zero. Unexposed effects/enchants/sets are not modeled; no DPS ranking.'

    return table.concat(lines,"\n")
end
