local A=FWC
local S={records={},requests={},seenLogs={},maxAttempts=3};A.Services.ItemStats=S
-- Only spelling aliases of the SAME quantity/unit. Spell hit %, spell hit rating and
-- general hit rating remain separate. No locale-dependent tooltip parsing.
local aliases={ITEM_MOD_SPELL_HIT_RATING_SHORT='ITEM_MOD_HIT_SPELL_RATING_SHORT',ITEM_MOD_SPELL_CRIT_RATING_SHORT='ITEM_MOD_CRIT_SPELL_RATING_SHORT',ITEM_MOD_SHADOW_DAMAGE_SHORT='ITEM_MOD_DAMAGE_SHADOW_SHORT',ITEM_MOD_FIRE_DAMAGE_SHORT='ITEM_MOD_DAMAGE_FIRE_SHORT'}
S.attributes={
 {'ITEM_MOD_INTELLECT_SHORT','Intellect'}, {'ITEM_MOD_SPELL_POWER_SHORT','Spell power'},
 {'ITEM_MOD_STAMINA_SHORT','Stamina'}, {'ITEM_MOD_STRENGTH_SHORT','Strength'},
 {'ITEM_MOD_AGILITY_SHORT','Agility'}, {'ITEM_MOD_SPIRIT_SHORT','Spirit'},
 {'ITEM_MOD_CRIT_SPELL_RATING_SHORT','Spell crit (rating)'}, {'ITEM_MOD_CRIT_RATING_SHORT','Crit (rating)'},
 {'ITEM_MOD_HIT_SPELL_RATING_SHORT','Spell hit (rating)'}, {'ITEM_MOD_HIT_RATING_SHORT','Hit (rating)'},
 {'ITEM_MOD_SPELL_PENETRATION_SHORT','Spell penetration / pierce'},
 {'ITEM_MOD_HASTE_RATING_SHORT','Haste (rating)'}, {'ITEM_MOD_MANA_REGENERATION_SHORT','MP5'},
 {'ITEM_MOD_ATTACK_POWER_SHORT','Attack power'}, {'RESISTANCE0_NAME','Armor'},
 {'ITEM_MOD_SPELL_DAMAGE_DONE_SHORT','Spell damage (all schools)'}, {'ITEM_MOD_SPELL_HEALING_DONE_SHORT','Spell healing'},
 {'ITEM_MOD_DAMAGE_SHADOW_SHORT','Shadow damage'}, {'ITEM_MOD_DAMAGE_FIRE_SHORT','Fire damage'},
 {'SPELL_HIT_PERCENT','Spell hit (%) · catalog unit'}, {'SPELL_CRIT_PERCENT','Spell crit (%) · catalog unit'},
}
-- Alternate global-string suffixes describe the same units; they do not convert ratings.
for _,entry in ipairs(S.attributes) do if entry[1]:match('^ITEM_MOD_.*_SHORT$') then aliases[entry[1]:gsub('_SHORT$','')]=entry[1] end end
local shortAliases={};for key,value in pairs(aliases) do shortAliases[key]=value end
for key,value in pairs(shortAliases) do if key:match('_SHORT$') then aliases[key:gsub('_SHORT$','')]=value end end
local sourceMap={intellect='ITEM_MOD_INTELLECT_SHORT',stamina='ITEM_MOD_STAMINA_SHORT',strength='ITEM_MOD_STRENGTH_SHORT',agility='ITEM_MOD_AGILITY_SHORT',spirit='ITEM_MOD_SPIRIT_SHORT',armor='RESISTANCE0_NAME',spell_power='ITEM_MOD_SPELL_POWER_SHORT',shadow_damage='ITEM_MOD_DAMAGE_SHADOW_SHORT',fire_damage='ITEM_MOD_DAMAGE_FIRE_SHORT',spell_penetration='ITEM_MOD_SPELL_PENETRATION_SHORT',hit='SPELL_HIT_PERCENT',crit='SPELL_CRIT_PERCENT'}
function S.Normalize(key) return aliases[key] or key end
local function finite(n) return type(n)=='number' and n==n and n~=math.huge and n~=-math.huge end
local function reference(input)
 if not A.Compat.Readable(input) then return nil end
 if type(input)=='number' and finite(input) and input>0 and input%1==0 then return tostring(input) end
 if type(input)=='string' and A.Compat.ItemID(input) then return input:match('|H(item:[^|]+)|h') or input end
end
local function sortedKeys(t) local keys={};for k in pairs(t or {}) do keys[#keys+1]=k end;table.sort(keys);return keys end
function S.Log(record)
 if not A.db or not A.db.settings.itemStatDiagnostics then return end
 local parts={record.kind,record.state,'ID='..tostring(record.itemId or 'unknown'),'input='..tostring(record.input or 'none'),'link='..tostring(record.link or 'none'),'source='..tostring(record.source or 'none')}
 for _,key in ipairs(sortedKeys(record.raw)) do parts[#parts+1]=key..'='..tostring(record.raw[key]) end
 for _,key in ipairs(sortedKeys(record.values)) do parts[#parts+1]='normalized '..key..'='..tostring(record.values[key])..(record.references and record.references[key] and ' (offline reference)' or '') end
 local absent={};for _,entry in ipairs(S.attributes) do if record.values[entry[1]]==nil then absent[#absent+1]=entry[1] end end;if #absent>0 then parts[#parts+1]='not exposed/unknown: '..table.concat(absent,',') end
 for _,key in ipairs(sortedKeys(record.errors)) do parts[#parts+1]=key..': '..record.errors[key] end
 if record.info and record.info.baseLink then parts[#parts+1]='GetItemInfo link='..tostring(record.info.baseLink) end
 local load=S.requests[record.itemId];if load then parts[#parts+1]='loader='..tostring(load.provider or load.state);if load.error then parts[#parts+1]='load error='..load.error end end
 if record.reason then parts[#parts+1]=record.reason end
 local message=table.concat(parts,' | ');if S.seenLogs[message] then return end;S.seenLogs[message]=true
 A.db.itemStatDiagnostics=A.db.itemStatDiagnostics or {};local logs=A.db.itemStatDiagnostics;logs[#logs+1]=message
 if #logs>80 then local removed=table.remove(logs,1);S.seenLogs[removed]=nil end
end
function S.Capabilities()
 return {GetItemInfo=type(C_Item and C_Item.GetItemInfo)=='function',GetItemStats=type(C_Item and C_Item.GetItemStats)=='function',
  LegacyItemInfo=type(GetItemInfo)=='function',LegacyItemStats=type(GetItemStats)=='function',RequestLoad=type(C_Item and C_Item.RequestLoadItemDataByID)=='function',
  IsCached=type(C_Item and C_Item.IsItemDataCachedByID)=='function',ItemFromLink=type(Item and Item.CreateFromItemLink)=='function',ItemFromID=type(Item and Item.CreateFromItemID)=='function'}
end
function S.Tracks(id)
 if S.requests[id] then return true end
 for _,r in pairs(S.records) do if r.itemId==id then return true end end
 return false
end
function S.Invalidate(id,retry)
 if A.Services.UpgradeComparison then A.Services.UpgradeComparison.Invalidate(id) end
 for key,r in pairs(S.records) do if not id or r.itemId==id then S.records[key]=nil end end
 if retry then if id then S.requests[id]=nil else S.requests={} end end
end
function S.Loaded(id,success,notify)
 if type(id)~='number' then return end
 local req=S.requests[id] or {};S.requests[id]=req
 req.state=success==false and 'failed' or 'loaded';req.time=A.Compat.Now()
 if success~=false and req.object and type(req.object.GetItemLink)=='function' then
  local ok,link=pcall(req.object.GetItemLink,req.object)
  if ok and A.Compat.Readable(link) and type(link)=='string' and A.Compat.ItemID(link)==id then req.link=link end
 end
 S.Invalidate(id,false)
 if notify and S.OnDataAvailable then S.OnDataAvailable(id) end
end
function S.Request(input)
 local id=A.Compat.ItemID(input);if not id or not reference(input) then return false end
 local old=S.requests[id];local now=A.Compat.Now()
 if old and (old.state~='pending' or now-(old.time or now)<10 or (old.attempts or 0)>=S.maxAttempts) then return false end
 local req={state='pending',time=now,attempts=(old and old.attempts or 0)+1};S.requests[id]=req
 local factory=Item
 local useLink=type(input)=='string' and type(factory and factory.CreateFromItemLink)=='function'
 local maker=useLink and factory.CreateFromItemLink or factory and factory.CreateFromItemID
 if type(maker)=='function' then
  local ok,obj=pcall(maker,factory,useLink and input or id)
  if ok and type(obj)=='table' and type(obj.ContinueOnItemLoad)=='function' then
   req.object=obj
   local success=pcall(obj.ContinueOnItemLoad,obj,function() S.Loaded(id,true,true) end)
   if success then req.provider='Item:ContinueOnItemLoad';return true end
  end
 end
 local fn=C_Item and C_Item.RequestLoadItemDataByID
 if type(fn)=='function' then
  local ok,err=pcall(fn,id);req.provider='C_Item.RequestLoadItemDataByID'
  if ok then return true end;req.state='failed';req.error=tostring(err);return false
 end
 req.state='unsupported';return false
end
local function finish(r) S.Log(r);return r end
function S.Read(input,options)
 local opts=options or {};local ref=reference(input);local key=(opts.kind or 'client')..':'..tostring(opts.itemId or A.Compat.ItemID(input) or '')..':'..(ref or ('missing:'..tostring(opts.slot or opts.itemId or 'unknown')))
 if S.records[key] then return S.records[key] end
 local r={kind=opts.kind or 'client',input=A.Compat.Readable(input) and input or '<restricted>',itemId=opts.itemId or A.Compat.ItemID(input),values={},raw={},errors={},state='pending',source='client'};S.records[key]=r
 if not ref then r.state=opts.checked==false and 'pending' or 'unavailable';r.reason=opts.kind=='equipped' and 'Equipped full link unavailable; not substituting a base item.' or 'Item identity unavailable';return finish(r) end
 if r.itemId~=A.Compat.ItemID(input) then r.state='error';r.reason='Item ID and supplied link disagree';return finish(r) end
 local info=A.Compat.ItemInfo(input);r.info=info;r.name=info.name
 local req=S.requests[r.itemId]
 r.link=type(input)=='string' and input or info.link or (req and req.link)
 if info.state=='error' then r.state='error';r.reason=info.error or 'Identity read error';return finish(r) end
 if req and req.state=='failed' then r.state='error';r.reason='Item data load failed; use Refresh data to retry';return finish(r) end
 if not r.link then S.Request(input);r.state=info.state=='unavailable' and 'unavailable' or 'pending';r.reason='Data pending: full candidate link not loaded';return finish(r) end
 if A.Compat.ItemID(r.link)~=r.itemId then r.state='error';r.reason='Returned link belongs to another item';return finish(r) end
 local fn=C_Item and C_Item.GetItemStats or GetItemStats
 r.source=C_Item and type(C_Item.GetItemStats)=='function' and 'C_Item.GetItemStats' or 'GetItemStats'
 if type(fn)~='function' then r.state='unavailable';r.reason='Item statistics API unavailable';return finish(r) end
 local ok,raw=pcall(fn,r.link)
 if not ok then r.state='error';r.reason='Stats read error: '..tostring(raw);return finish(r) end
 if not A.Compat.Readable(raw) then r.state='error';r.reason='Restricted stat table';return finish(r) end
 if type(raw)~='table' then S.Request(input);r.state='pending';r.reason='Data pending: API returned no stat table';return finish(r) end
 local cache=A.Compat.Call(C_Item and C_Item.IsItemDataCachedByID,r.itemId)
 if cache==false or (not next(raw) and not info.name and cache~=true) then S.Request(input);r.state='pending';r.reason='Data pending: empty/unloaded item';return finish(r) end
 for k,v in pairs(raw) do
  if A.Compat.Readable(k) and type(k)=='string' then
   local normalized=S.Normalize(k)
   if not A.Compat.Readable(v) or not finite(v) then r.errors[normalized]='Restricted, non-numeric or invalid stat'
   else
    r.raw[k]=v
    if r.values[normalized]~=nil and r.values[normalized]~=v then r.errors[normalized]='Conflicting alias values';r.values[normalized]=nil
    elseif not r.errors[normalized] then r.values[normalized]=v end
   end
  else r.errors['unreadable-key']='Restricted or unsupported attribute key' end
 end
 r.state=next(r.errors) and 'partial' or next(r.values) and 'confirmed' or 'empty'
 r.reason=r.state=='empty' and 'Loaded item: no attributes exposed by this API' or r.state=='partial' and 'Some attributes could not be read' or nil
 return finish(r)
end
function S.Equipped(slot)
 local snapshot=A.Services.Inventory.snapshot;local entry=snapshot.equipped[slot]
 return S.Read(entry and entry.link,{kind='equipped',slot=slot,itemId=entry and entry.id,checked=entry and entry.checked~=false and snapshot.equipmentChecked~=false or false})
end
function S.WithOffline(item,record)
 local data=A.Data.foundation;local offline=data and item and data.items[item.id]
 if not offline or item.link or record.itemId~=item.id then return record end
 if offline.sourceConfidence~='publisher_reported' and offline.sourceConfidence~='verified_forever_client' then return record end
 local _,build=A.Compat.Call(GetBuildInfo)
 if tostring(offline.buildVersion):match('(%d+)$')~=tostring(build) then return record end
 local merged=A.Services.Persistence.Copy(record);local used=0;merged.references={}
 for label,stat in pairs(offline.stats or {}) do
  local key=stat.statKey;local allowed=true
  for _,id in ipairs(stat.provenance or {}) do local p=data.provenance[id];if not p or (p.evidenceType~='published_forever_client_page' and p.evidenceType~='published_forever_api' and p.evidenceType~='client_verified') then allowed=false end end
  if allowed and key and stat.unit~='unknown' and finite(stat.value) and merged.values[key]==nil and not merged.errors[key] then
   merged.values[key]=stat.value;merged.references[key]=stat.provenance;used=used+1
  end
 end
 if used==0 then return record end
 merged.clientState=record.state;merged.state='partial';merged.source=record.source..' + offline reference (ForeverDB.net; publisher reported)'
 merged.errors['offline-coverage']='Publisher reported; effects/units coverage partial, excluded from EP'
 merged.fallbackSource=data.provenance[offline.provenance[1]].sourceURL
 merged.reason='Offline base-item reference for matching build; current client data retains priority'
 return finish(merged)
end
function S.Candidate(item)
 local input=item and (item.link or item.id);local r=S.Read(input,{kind='candidate',itemId=item and item.id})
 -- Imported/unranked fields are never an implicit repair of a client read. A fallback
 -- must explicitly identify a verified base variant, build, source and normalized values.
 local verified=item and item.verifiedStats
 if (r.state=='pending' or r.state=='unavailable') and type(verified)=='table' and verified.variant=='base' and type(input)=='number' and type(verified.source)=='string' then
  local _,build=A.Compat.Call(GetBuildInfo)
  if tostring(verified.build)==tostring(build) and type(verified.values)=='table' then
   local fallback={kind='candidate',itemId=item.id,input=input,link=r.link,info=r.info,name=r.name or item.name,values={},raw={},errors={},source='verified catalog: '..verified.source,state='confirmed',clientState=r.state}
   for k,v in pairs(verified.values) do if type(k)~='string' or not finite(v) then return r end;local normalized=S.Normalize(k);if fallback.values[normalized]~=nil and fallback.values[normalized]~=v then return r end;fallback.values[normalized]=v end
   if next(fallback.values) then return finish(fallback) end
  end
 end
 return S.WithOffline(item,r)
end
function S.Value(record,key)
 key=S.Normalize(key)
 if not record then return nil,'unknown' end
 if record.errors[key] then return nil,'error' end
 local value=record.values[key]
 if value~=nil then return value,record.references and record.references[key] and 'reference' or value==0 and 'zero' or 'confirmed' end
 if record.state=='confirmed' or record.state=='empty' or record.state=='partial' then return nil,'absent' end
 return nil,record.state=='pending' and 'pending' or record.state=='error' and 'error' or 'unknown'
end
function S.Display(record,key)
 local value,state=S.Value(record,key)
 return value~=nil and (tostring(value)..(state=='reference' and ' *' or '')) or ({absent='Not present',pending='Data pending',error='Read error',unknown='Unknown'})[state] or 'Unknown',state
end
function S.Delta(before,after,key)
 local x,xstate=S.Value(before,key);local y,ystate=S.Value(after,key)
 if xstate=='reference' or ystate=='reference' then return nil,'Offline reference' end
 if x~=nil and y~=nil then return y-x end
 return nil,(xstate=='error' or ystate=='error') and 'Read error' or (xstate=='pending' or ystate=='pending') and 'Data pending' or (xstate=='absent' or ystate=='absent') and 'Not comparable' or 'Unknown'
end
-- A missing entry in GetItemStats alone proves nothing. The client's pairwise
-- comparison can explicitly report losses for stats missing from the new item.
-- Calibrate its direction against common numeric stats, rather than assuming
-- all client generations subtract arguments in the same order.
function S.NativeComparison(before,after)
 local fn=C_Item and C_Item.GetItemStatDelta or GetItemStatDelta
 if type(fn)~='function' or not before or not after or before.state~='confirmed' or after.state~='confirmed' or type(before.link)~='string' or type(after.link)~='string' then return nil end
 local ok,raw=pcall(fn,before.link,after.link)
 if not ok or not A.Compat.Readable(raw) or type(raw)~='table' then return nil end
 local deltas={}
 for key,value in pairs(raw) do
  if not A.Compat.Readable(key) or type(key)~='string' or not A.Compat.Readable(value) or not finite(value) then return nil end
  key=S.Normalize(key)
  if deltas[key]~=nil and deltas[key]~=value then return nil end
  deltas[key]=value
 end
 local direction
 for key,x in pairs(before.values) do
  local y=after.values[key]
  if finite(y) and y~=x then
   local d=deltas[key];if not d then return nil end
   local sign=math.abs(d-(y-x))<0.000001 and 1 or math.abs(d+(y-x))<0.000001 and -1 or nil
   if not sign or direction and direction~=sign then return nil end;direction=sign
  elseif finite(y) and deltas[key] and math.abs(deltas[key])>0.000001 then return nil end
 end
 if not direction then return nil end -- No numeric anchor: retain strict fallback.
 local a,b={},{}
 for k,v in pairs(before.values) do a[k]=v end
 for k,v in pairs(after.values) do b[k]=v end
 for key,value in pairs(deltas) do
  local d=value*direction;deltas[key]=d
  if a[key]~=nil and b[key]==nil then
   local inferred=a[key]+d;if inferred<0 then return nil end;b[key]=inferred
  elseif b[key]~=nil and a[key]==nil then
   local inferred=b[key]-d;if inferred<0 then return nil end;a[key]=inferred
  end
 end
 return {before=a,after=b,deltas=deltas,source='client pairwise comparison'}
end
function S.Weights(weights)
 if weights~=nil and type(weights)~='table' then return nil,'Invalid weight table' end
 local result={}
 for key,value in pairs(weights or {}) do
  if type(key)~='string' or not finite(value) then return nil,'Invalid weight' end
  local normalized=S.Normalize(key)
  if result[normalized]~=nil and result[normalized]~=value then return nil,'Conflicting weight aliases: '..normalized end
  result[normalized]=value
 end
 return result
end
function S.Keys(before,after,weights)
 local known,rows={},{}
 for _,a in ipairs(S.attributes) do rows[#rows+1]={key=a[1],label=a[2]};known[a[1]]=true end
 local extra={};for _,values in ipairs({before and before.values or {},after and after.values or {},weights or {}}) do for k in pairs(values) do k=S.Normalize(k);if not known[k] then extra[k]=true end end end
 for _,key in ipairs(sortedKeys(extra)) do rows[#rows+1]={key=key,label=type(_G[key])=='string' and _G[key] or key} end
 return rows
end
function S.Describe(r)
 return r and (r.state..' · '..r.source..(r.reason and (' · '..r.reason) or '')) or 'Unknown'
end
function S.Lines(r)
 local lines={S.Describe(r)};if r.fallbackSource then lines[#lines+1]='Data: ForeverDB.net · https://foreverdb.net' end;for _,entry in ipairs(S.Keys(r)) do local v,state=S.Value(r,entry.key);if v~=nil then lines[#lines+1]=entry.label..': '..v..(state=='reference' and ' (offline reference)' or '') elseif state=='error' then lines[#lines+1]=entry.label..': Read error' end end
 if #lines==1 then lines[#lines+1]=r.state=='pending' and 'Data pending' or r.state=='empty' and 'No attributes exposed; zero is not confirmed' or 'Unknown' end
 return table.concat(lines,'\n')
end
function S.Report()
 local version,build,_,interface=A.Compat.Call(GetBuildInfo)
 local lines={'ITEM STATS · '..tostring(version)..' / '..tostring(build)..' / interface '..tostring(interface),'Runtime capabilities (presence does not prove returned data)'}
 for _,k in ipairs(sortedKeys(S.Capabilities())) do lines[#lines+1]=k..': '..tostring(S.Capabilities()[k]) end
 lines[#lines+1]='Diagnostics: '..(A.db.settings.itemStatDiagnostics and 'On' or 'Off')
 for _,message in ipairs(A.db.itemStatDiagnostics or {}) do lines[#lines+1]=message end
 return table.concat(lines,'\n')
end
function S.Guide(item)
 local lines={'Imported guide · unverified (excluded from client stats and rating)'}
 for _,key in ipairs(sortedKeys(item and item.sourceStats)) do local value=item.sourceStats[key];if type(value)=='number' then lines[#lines+1]=(sourceMap[key] or key)..': '..value end end
 return table.concat(lines,'\n')
end
