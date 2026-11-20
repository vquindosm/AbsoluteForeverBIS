local A=FWC
local U={cache={}};A.Services.UpgradeComparison=U
local function finite(n) return A.Compat.Readable(n) and type(n)=='number' and n==n and math.abs(n)<math.huge end
function U.Invalidate(id)
 for key,r in pairs(U.cache) do if not id or r.before.itemId==id or r.after.itemId==id then U.cache[key]=nil end end
end
local function signature(weights)
 local parts={};for key,value in pairs(weights or {}) do parts[#parts+1]=key..'='..tostring(value) end
 table.sort(parts);return table.concat(parts,',')
end
function U.Compare(equipped,candidate,class,spec,weights,options)
 if not A.Compat.Readable(equipped) then equipped=nil end
 if not A.Compat.Readable(candidate) then candidate=nil end
 if not A.Compat.Readable(class) then class=nil end
 if not A.Compat.Readable(spec) then spec=nil end
 local S=A.Services.ItemStats;local o=options or {}
 local normalized,weightError=S.Weights(weights)
 local before=o.before or S.Read(equipped,{kind='upgrade-equipped',checked=equipped~=nil})
 local after=o.after or S.Read(candidate,{kind='upgrade-candidate'})
 local key=not o.before and not o.after and not o.overlappingStats and table.concat({tostring(before.link or equipped),tostring(after.link or candidate),class or '',spec or '',signature(normalized),weightError or ''},'|')
 if key and U.cache[key] then return U.cache[key] end
 local r={before=before,after=after,deltas={},unknown={},warnings={},gains=0,losses=0,confidence='partial',calculationStatus='unavailable'}
 local native=not o.loadout and S.NativeComparison(before,after)
 local a,b=before,after
 if native then
  a=setmetatable({values=native.before},{__index=before});b=setmetatable({values=native.after},{__index=after});r.nativeDelta=true
 end
 r.normalizedEquippedStats=a.values;r.normalizedCandidateStats=b.values
 local complete=a.state=='confirmed' and b.state=='confirmed'
 local known={}
 for _,entry in ipairs(S.Keys(a,b,normalized)) do
  local x,xs=S.Value(a,entry.key);local y,ys=S.Value(b,entry.key)
  local required=normalized and normalized[entry.key] and normalized[entry.key]~=0
  if x~=nil or y~=nil or required or xs=='error' or ys=='error' then
   local d=S.Delta(a,b,entry.key)
   if d~=nil then
    if d~=0 then r.deltas[#r.deltas+1]={key=entry.key,label=entry.label,delta=d};known[entry.key]=true end
   else complete=false;r.unknown[#r.unknown+1]={key=entry.key,label=entry.label,before=x,after=y} end
  end
 end
 if native then
  for stat,d in pairs(native.deltas) do
   if d~=0 and not known[stat] then
    r.deltas[#r.deltas+1]={key=stat,label=_G[stat] or stat,delta=d}
    if S.Value(a,stat)==nil and S.Value(b,stat)==nil then complete=false;r.unknown[#r.unknown+1]={key=stat,label=_G[stat] or stat} end
   end
  end
 end
 for _,d in ipairs(r.deltas) do if d.delta>0 then r.gains=r.gains+1 else r.losses=r.losses+1 end end
 local _,actualClass=A.Compat.Call(UnitClass,'player')
 local overlaps=o.overlappingStats or {{'ITEM_MOD_SPELL_POWER_SHORT','ITEM_MOD_SPELL_DAMAGE_DONE_SHORT'}}
 local overlap=false
 -- Do not fold school damage into generic spell power. Distinct native school
 -- contributions stay distinct; explicitly overlapping representations cannot
 -- both enter EP. Localized labels never participate in identity or arithmetic.
 for _,group in ipairs(overlaps) do
  local used=0
  for _,stat in ipairs(group) do if normalized and normalized[stat] and normalized[stat]~=0 and ((a.values[stat] or 0)~=0 or (b.values[stat] or 0)~=0) then used=used+1 end end
  if used>1 then overlap=true end
 end
 if not actualClass then r.reason='Clase del personaje sin comprobar'
 elseif class and class~=actualClass then r.reason='El perfil seleccionado corresponde a otra clase'
 elseif weightError then r.reason=weightError
 elseif overlap then r.reason='Overlapping spell contributions';r.warnings[#r.warnings+1]='overlapping-stat-contributions'
 elseif complete and normalized and next(normalized) then r.score,r.reason=A.Services.Planner.WeightedComparison(a.values,b.values,normalized)
 elseif not complete then r.reason='Datos incompletos; lo ausente no se supone cero'
 else r.reason='Sin pesos EP; sólo se comparan atributos' end
 if r.score then
  r.score.absolute=r.score.after-r.score.before;r.score.provider='manual';r.score.source='Tus pesos EP'
  r.calculationStatus='calculated';r.confidence='calculated';r.state=r.score.delta>.01 and 'upgrade' or r.score.delta<-.01 and 'downgrade' or 'equal'
 elseif not complete then r.state='partial'
 elseif r.gains>0 and r.losses==0 then r.state='stats-up'
 elseif r.losses>0 and r.gains==0 then r.state='stats-down'
 elseif r.gains+r.losses>0 then r.state='mixed'
 else r.state='equal' end
 r.complete=complete;r.coverage={complete=complete,unknown=#r.unknown,clientPairwise=native~=nil}
 if complete and not r.score then r.confidence='attributes-only' end
 if not complete then r.warnings[#r.warnings+1]='partial-stat-coverage' end
 if key then U.cache[key]=r end
 return r
end
function U.DisplayDeltas(result)
 local priority={ITEM_MOD_DAMAGE_SHADOW_SHORT=1,ITEM_MOD_SPELL_POWER_SHORT=2,ITEM_MOD_CRIT_RATING_SHORT=3,ITEM_MOD_INTELLECT_SHORT=4,ITEM_MOD_STAMINA_SHORT=5,RESISTANCE0_NAME=99}
 local rows={};for _,d in ipairs(result.deltas or {}) do rows[#rows+1]=d end
 table.sort(rows,function(a,b)
  if (a.delta>0)~=(b.delta>0) then return a.delta>0 end
  local x,y=priority[a.key] or 50,priority[b.key] or 50
  return x<y or x==y and a.key<b.key
 end)
 return rows
end
function U.ForSlot(slot,item)
 local def=A.Data.slotByKey[slot];local link
 if def then local id;id,link=A.Compat.Equipped(def.inventory) end
 local p=A.Services.Persistence.Profile()
 local result=U.Compare(link,item and (item.link or item.id),A.db.viewClass,A.db.spec,p.epWeights)
 local L=A.Services.LootComparison
 if L and item then
  if slot=='MainHand' or slot=='OffHand' then
   local info=A.Compat.ItemInfo(item.link or item.id);local rows=info.link and L.Compare(info.link)
   for _,r in ipairs(rows and rows.comparisons or {}) do if r.slot==slot then return r end end
  end
  local info=A.Compat.ItemInfo(item.link or item.id);local eligible,why=L.Eligibility(info.link or item.link or ('item:'..item.id),info)
  if eligible~=true then
   result=setmetatable({score=nil,reason=why,confidence='unavailable',calculationStatus='unavailable',eligible=eligible},{__index=result})
   -- A nil field would otherwise inherit the cached score through __index.
   result.score=false
  end
 end
 return result
end
function U.Rating(result)
 local n=A.db.settings.upgradeEqualThreshold
 local threshold=finite(n) and math.max(0,n) or .5
 local score=result and result.score
 if not score or not finite(score.absolute) then return 'UNKNOWN','?','e5c575' end
 if math.abs(score.absolute)<=threshold then return 'NEAR EQUAL',string.format('≈ %+.1f EP',score.absolute),'b8c4d5' end
 return score.absolute>0 and 'UPGRADE' or 'DOWNGRADE',string.format('%+.1f EP',score.absolute),score.absolute>0 and '78e49a' or 'ef9797'
end
return U
