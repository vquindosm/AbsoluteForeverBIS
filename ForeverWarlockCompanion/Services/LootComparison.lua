local A=FWC
local L={};A.Services.LootComparison=L
local slots={INVTYPE_HEAD={'Head'},INVTYPE_NECK={'Neck'},INVTYPE_SHOULDER={'Shoulders'},
 INVTYPE_CLOAK={'Back'},INVTYPE_CHEST={'Chest'},INVTYPE_ROBE={'Chest'},INVTYPE_WRIST={'Wrists'},
 INVTYPE_HAND={'Hands'},INVTYPE_WAIST={'Waist'},INVTYPE_LEGS={'Legs'},INVTYPE_FEET={'Feet'},
 INVTYPE_FINGER={'Ring1','Ring2'},INVTYPE_TRINKET={'Trinket1','Trinket2'},
 INVTYPE_WEAPONMAINHAND={'MainHand'},INVTYPE_2HWEAPON={'MainHand'},
 INVTYPE_WEAPONOFFHAND={'OffHand'},INVTYPE_HOLDABLE={'OffHand'},INVTYPE_SHIELD={'OffHand'},
 INVTYPE_RANGED={'Ranged'},INVTYPE_RANGEDRIGHT={'Ranged'},INVTYPE_THROWN={'Ranged'},INVTYPE_RELIC={'Ranged'}}
local function number(n) return A.Compat.Readable(n) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function boolean(fn,...)
 local v=A.Compat.Call(fn,...);if A.Compat.Readable(v) and type(v)=='boolean' then return v end
end
local function payload(link) return type(link)=='string' and (link:match('|H(item:[^|]+)|h') or link) end
local function equipped(slot)
 local id,link,checked=A.Compat.Equipped(A.Data.slotByKey[slot].inventory)
 if not A.Compat.Readable(id) or not A.Compat.Readable(link) then checked=false;id=nil;link=nil end
 local S=A.Services.ItemStats
 if not id and link then id=A.Compat.ItemID(link) end
 if checked and not id and not link then return {empty=true,slot=slot} end
 return {slot=slot,id=id,link=link,record=S.Read(link,{kind='loot-equipped',slot=slot,itemId=id,checked=checked})}
end
-- Sum only quantities explicitly exposed on every nonempty item in the loadout.
-- An absent stat is not converted to zero, even when another member exposes it.
local function combine(first,second)
 if first.empty then return second.record end
 if second.empty then return first.record end
 local a,b=first.record,second.record
 local out={values={},raw={},errors={},state='confirmed',source='client loadout',name='Arma + mano izquierda',members={first.link,second.link}}
 if not a or not b or a.state~='confirmed' or b.state~='confirmed' then out.state='partial' end
 local keys={};for _,r in ipairs({a or {},b or {}}) do for key in pairs(r.values or {}) do keys[key]=true end end
 for key in pairs(keys) do
  local x=A.Services.ItemStats.Value(a,key);local y=A.Services.ItemStats.Value(b,key)
  if number(x) and number(y) then out.values[key]=x+y else out.state='partial';out.errors['loadout-coverage']='Missing member stat' end
 end
 return out
end
function L.Eligibility(link,info)
 local canUse=boolean(C_PlayerInfo and C_PlayerInfo.CanUseItem,A.Compat.ItemID(link))
 local canEquip=boolean(C_Item and C_Item.IsEquippableItem or IsEquippableItem,link)
 local level=A.Compat.Call(UnitLevel,'player')
 if number(level) and number(info.requiredLevel) and level<info.requiredLevel then return false,'Requiere nivel '..info.requiredLevel end
 if canUse==false or canEquip==false then return false,'El cliente indica que no puedes equiparlo ahora' end
 if canUse==true or canEquip==true then return true end
 -- If neither capability returns an explicit answer, keep compatibility unknown.
 return nil,'Compatibilidad con tu personaje sin comprobar'
end
function L.One(slot,link,info,after,eligible,eligibilityReason)
 local S=A.Services.ItemStats;local current=equipped(slot)
 local out={slot=slot,label=A.Data.slotByKey[slot].label,deltas={},unknown={},eligible=eligible,before=current.record,after=after}
 if eligible==false then out.state='blocked';out.reason=eligibilityReason;return out end
 local otherSlot=({Ring1='Ring2',Ring2='Ring1',Trinket1='Trinket2',Trinket2='Trinket1'})[slot]
 if otherSlot and current.id~=after.itemId and equipped(otherSlot).id==after.itemId then
  out.eligible=nil;out.compatibility='Ya llevas otra copia: comprueba el límite Único-equipado en el tooltip nativo'
 end
 if slot=='OffHand' then
  local main=equipped('MainHand');local mainInfo=main.link and A.Compat.ItemInfo(main.link)
  if mainInfo and mainInfo.equipLoc=='INVTYPE_2HWEAPON' then out.state='loadout';out.reason='Necesitas cambiar el arma de dos manos para usar esta mano izquierda';return out end
  if not main.empty and (not mainInfo or not mainInfo.equipLoc) then out.state='pending';out.reason='Tipo del arma principal sin comprobar';return out end
 end
 if slot=='MainHand' and info.equipLoc=='INVTYPE_2HWEAPON' then
  local off=equipped('OffHand')
  if not off.empty then out.before=combine(current,off);out.label='Arma + mano izquierda';out.loadout=true end
 end
 if current.empty and not out.loadout then
  out.state='empty';out.reason='Ranura vacía; opción para equipar';return out
 end
 if after.itemId~=279269 and not out.loadout and payload(link)==payload(current.link) then out.state='same';out.reason='Mismo objeto y variante equipados';return out end
 local before=out.before
 local profile=A.Services.Persistence.Profile();local weights=profile.epWeights
 local options=out.loadout and {before=before,after=after,loadout=true} or nil
 local compared=A.Services.UpgradeComparison.Compare(current.link,link,A.db.viewClass,A.db.spec,weights,options)
 for _,key in ipairs({'deltas','unknown','complete','gains','losses','score','reason','nativeDelta','coverage','warnings','confidence','calculationStatus','normalizedEquippedStats','normalizedCandidateStats'}) do out[key]=compared[key] end
 local complete=out.complete;local gains,losses=out.gains,out.losses
 -- A documented external scoring engine can score sparse native stat tables
 -- without manufacturing their missing values. Weapons that change both hands
 -- still require the loadout comparison above; a per-item API is insufficient.
 local mode=profile.lootScoreSource or 'auto'
 if mode=='flb' and after.itemId~=279269 then out.score=nil end
 local providerReady=before and (before.state=='confirmed' or before.state=='empty') and (after.state=='confirmed' or after.state=='empty')
 if after.itemId~=279269 and mode~='manual' and (mode=='flb' or type(weights)~='table' or not next(weights)) and not out.loadout and providerReady then
  local score,why=A.Services.LootScore.Compare(link,current.link,slot)
  if score then out.score=score;out.reason=nil
  elseif mode=='flb' then out.score=nil;out.reason=why end
 end
 if out.score then
  local delta=out.score.delta or out.score.absolute
  out.state=delta>0.01 and 'upgrade' or delta<-.01 and 'downgrade' or 'equal'
 elseif not complete then out.state='partial'
 elseif gains>0 and losses==0 then out.state='stats-up'
 elseif losses>0 and gains==0 then out.state='stats-down'
 elseif gains>0 or losses>0 then out.state='mixed'
 else out.state='equal' end
 if eligible~=true then out.compatibility=eligibilityReason end
 return out
end
function L.Compare(link)
 if type(link)~='string' or not A.Compat.ItemID(link) or not A.db then return nil end
 local info=A.Compat.ItemInfo(link)
 if info.state=='error' then return {state='pending',reason='No se pudo leer el objeto',comparisons={}} end
 if not info.equipLoc then
  A.Services.ItemStats.Request(link)
  local req=A.Services.ItemStats.requests[A.Compat.ItemID(link)]
  local reason=req and req.state=='failed' and 'Carga fallida · /fwc refresh para reintentar' or req and req.state=='unsupported' and 'Datos del objeto no disponibles' or 'Cargando datos del objeto…'
  return {state='pending',reason=reason,comparisons={}}
 end
 local choices=slots[info.equipLoc]
 if info.equipLoc=='INVTYPE_WEAPON' then choices={'MainHand'};if boolean(CanDualWield)==true then choices={'MainHand','OffHand'} end end
 if not choices then return nil end -- Bags, currencies, recipes and other nonequipment.
 local S=A.Services.ItemStats;local after=S.Read(link,{kind='loot',itemId=A.Compat.ItemID(link)})
 local eligible,reason=L.Eligibility(link,info)
 if info.equipLoc=='INVTYPE_WEAPONOFFHAND' and boolean(CanDualWield)==false then eligible=false;reason='No puedes empuñar un arma en la mano izquierda' end
 local result={link=link,itemId=A.Compat.ItemID(link),info=info,after=after,comparisons={}}
 for _,slot in ipairs(choices) do result.comparisons[#result.comparisons+1]=L.One(slot,link,info,after,eligible,reason) end
 return result
end
function L.Badge(result)
 if not result then return nil end
 if result.state=='pending' then return '?','pending' end
 local best=-1;local text,state
 local priority={upgrade=9,['stats-up']=8,empty=7,equal=6,same=5,mixed=4,partial=3,pending=3,['stats-down']=2,downgrade=1,blocked=0,loadout=0}
 for _,row in ipairs(result.comparisons) do
  local p=priority[row.state] or 0
  if p>best then
   best=p;state=row.state
   if row.state=='upgrade' then text='↑ EP'
   elseif row.state=='stats-up' then text='↑ stats'
   elseif row.state=='downgrade' then text='↓ EP'
   elseif row.state=='stats-down' then text='↓ stats'
   elseif row.state=='same' or row.state=='equal' then text='='
   elseif row.state=='empty' then text='+'
   elseif row.state=='blocked' or row.state=='loadout' then text='!'
   else text='?' end
   if row.eligible~=true and (row.state=='upgrade' or row.state=='stats-up' or row.state=='empty') then text='?';state='partial' end
  end
 end
 return text,state
end
return L
