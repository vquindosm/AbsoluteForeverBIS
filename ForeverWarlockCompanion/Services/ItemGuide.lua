local A=FWC
local G={credit='Data from ForeverDB.net · https://foreverdb.net'};A.Services.ItemGuide=G
local function data() return A.Data.itemGuide or {items={},enhancements={},recipes={},slotEnhancements={},recommendations={}} end
local function finite(v) return A.Compat.Readable(v) and type(v)=='number' and v==v and math.abs(v)<math.huge end
local function icon(url) return type(url)=='string' and tonumber(url:match('/(%d+)%.webp')) or nil end
function G.Record(item) return item and data().items[item.id] end
function G.Icon(item) local r=G.Record(item);return r and icon(r.icon) or item and item.icon or 'Interface\\Icons\\INV_Misc_QuestionMark' end
function G.EnchantIcon(e) return icon(e.icon) or 'Interface\\Icons\\INV_Enchant_EssenceEternalLarge' end
function G.Reference(item) return item and ('https://foreverdb.net/item/'..item.id) or 'https://foreverdb.net' end
function G.Summary(item,limit)
 local r=G.Record(item);local lines={}
 for _,s in ipairs(r and r.stats or {}) do if finite(s.value) then lines[#lines+1]=string.format('%+g ',s.value)..s.stat;if #lines>=(limit or 4) then break end end end
 return #lines>0 and table.concat(lines,' · ') or 'Atributos publicados no disponibles'
end
function G.Recommendation(slot,item)
 if A.db.viewClass~='WARLOCK' or A.db.spec~='Affliction' or not item then return nil end
 local rows=data().recommendations[slot];return rows and rows[item.id]
end
function G.ScoreLabel(slot,item)
 local record=G.Record(item)
 if record and record.betaEvent then return 'Copia beta histórica' end
 if record and record.speculation then return 'Disponibilidad sin confirmar' end
 if record and record.dataFromBuild then return 'Referencia de build anterior' end
 local r=G.Recommendation(slot,item)
 if r and r.score then return string.format('%g',r.score)..' · guía JcE 60'
 elseif r and r.behindPercent then return '−'..r.behindPercent..'% · frente al mejor de la guía' end
 return 'Sin índice de guía'
end
function G.ShortSource(item)
 if not item then return 'Origen sin confirmar' end
 if A.Services.AcquisitionRequirementsResolver.Has(item.id) then
  local p=A.Services.AcquisitionRequirementsResolver.Plan(item.id);local v=A.Data.foundation.vendors[p.offer.vendorId]
  return 'Vendedor · '..tostring(A.Services.AcquisitionRequirementsResolver.Value(v.name))
 end
 local recipes=data().recipes[item.id]
 if recipes and recipes[1] then return 'Fabricación · '..recipes[1].profession end
 return (item.source or 'Origen sin confirmar')..' · '..(item.sourceType or 'Guía importada')
end
function G.Requirements(item)
 local r=G.Record(item);local rows={}
 if not r then return {{label='Nivel requerido sin publicar',status='unknown'}} end
 local current=A.Compat.Call(UnitLevel,'player');local need=r.requiredLevel
 rows[#rows+1]={label=need~=nil and ('Nivel '..need..' para equipar') or 'Nivel requerido sin publicar',current=finite(current) and current or nil,required=need,
  status=finite(current) and finite(need) and (current>=need and 'met' or 'missing') or 'unknown'}
 if type(r.bonding)=='string' then rows[#rows+1]={label=r.bonding,status='info'} end
 if r.unique~=nil then rows[#rows+1]={label=r.unique and 'Objeto único' or 'No marcado como único',status='info'} end
 if r.betaEvent then rows[#rows+1]={label='Objeto de evento beta: disponibilidad histórica',status='unknown'}
 elseif r.speculation then rows[#rows+1]={label='Disponibilidad no confirmada',status='unknown'} end
 if r.dataFromBuild then rows[#rows+1]={label='Datos conservados de un build anterior; confirmar en el cliente',status='unknown'} end
 rows[#rows+1]={label='Restricciones extra de clase/profesión: sin confirmar',status='unknown'}
 return rows
end
function G.RequirementsText(item)
 local lines={}
 for _,row in ipairs(G.Requirements(item)) do
  local mark=({met='|cff77df66[ok] ',missing='|cffff8877[!] ',unknown='|cffe6c66c[?] ',info='|cffb9c2d4'})[row.status]
  lines[#lines+1]=mark..row.label..(row.current and row.required and (' · '..row.current..' / '..row.required) or '')..'|r'
 end
 local r=G.Record(item);if r then lines[#lines+1]='Referencia publicada · build '..r.build end
 lines[#lines+1]=G.credit;return table.concat(lines,'\n')
end
function G.Materials(recipe)
 local rows={}
 for _,r in ipairs(recipe.reagents or {}) do
  local n,checked=A.Services.Inventory.Count({id=r.itemId});local required=r.count
  rows[#rows+1]={itemId=r.itemId,name=r.name,required=required,available=checked and n or nil,
   complete=checked and finite(n) and finite(required) and n>=required or false}
 end
 return rows
end
local function materialLines(recipe)
 local lines={};for _,r in ipairs(G.Materials(recipe)) do
  lines[#lines+1]=(r.complete and '|cff77df66' or '|cffb9c2d4')..tostring(r.available or '?')..' / '..tostring(r.required)..' '..r.name..'|r'
 end;return lines
end
function G.LearningSources(recipe)
 local lf=recipe.learnedFrom;local src=lf and lf.sources;local lines={}
 if not src then return {'Origen de la fórmula sin confirmar en Forever'} end
 local faction=A.Compat.Call(UnitFactionGroup,'player');local group=type(faction)=='string' and faction:lower() or nil
 local function people(kind,title)
  local choices=src[kind] or {};local all={}
  if group and choices[group] then all=choices[group]
  else local seen={};for _,side in ipairs({'alliance','horde'}) do for _,npc in ipairs(choices[side] or {}) do if not seen[npc.npcId or npc.name] then all[#all+1]=npc;seen[npc.npcId or npc.name]=true end end end end
  for _,npc in ipairs(all) do
   local coords=finite(npc.x) and finite(npc.y) and (' ('..npc.x..', '..npc.y..')') or ''
   local quality=npc.seenInForever==true and 'Visto en Forever' or 'Classic; sin confirmar en Forever'
   lines[#lines+1]=title..': '..tostring(npc.name)..' · '..tostring(npc.zone or 'zona sin publicar')..coords..' · '..quality
   if npc.notOnListPlayersSaw then lines[#lines+1]='Esta oferta no estaba en la lista observada; comprobar disponibilidad.' end
   if finite(npc.price) then lines[#lines+1]='Precio publicado de la fórmula: '..npc.price..' cobre' end
   for _,cost in ipairs(npc.costs or {}) do lines[#lines+1]='Coste de la fórmula: '..tostring(cost.amount)..' '..tostring(cost.name or cost.type) end
  end
 end
 people('vendors','Fórmula');people('trainers','Instructor')
 for _,quest in ipairs(src.quests or {}) do lines[#lines+1]='Misión para aprender: '..tostring(quest.name or 'nombre sin publicar')..' · '..(quest.inForeverClient==true and 'Cliente Forever' or 'sin confirmar en Forever') end
 if lf.automatic==true then lines[#lines+1]='Aprendizaje automático publicado para la profesión' end
 for i,drop in ipairs(src.drops or {}) do if i<=3 then lines[#lines+1]='Fórmula: '..tostring(drop.from or (drop.kind=='world drop' and 'botín del mundo' or 'botín'))..' · '..(drop.seenInForever==true and 'Visto en Forever' or 'Classic; sin confirmar en Forever') end end
 if #(src.drops or {})>3 then lines[#lines+1]='Otros orígenes en el enlace de la fórmula.' end
 if #lines==0 then lines[1]='Origen de la fórmula sin confirmar en Forever' end
 return lines
end
function G.CraftingText(recipe)
 local src=recipe.learnedFrom and recipe.learnedFrom.sources
 local skill=src and src.learnAtSkill or recipe.skill and recipe.skill.orange
 local lines={'Para fabricar: '..recipe.profession..' '..tostring(skill or '?')..' (no es un requisito para equipar)'}
 for _,line in ipairs(G.LearningSources(recipe)) do lines[#lines+1]=line end
 if recipe.tools and #recipe.tools>0 then lines[#lines+1]='Herramienta: '..table.concat(recipe.tools,', ') end
 if type(recipe.needsNearby)=='string' then lines[#lines+1]='Necesita: '..recipe.needsNearby
 elseif recipe.needsNearby then lines[#lines+1]='Condición de estación: consultar la receta enlazada' end
 lines[#lines+1]='Materiales en bolsas:';for _,line in ipairs(materialLines(recipe)) do lines[#lines+1]=line end
 return table.concat(lines,'\n')
end
function G.SourceText(item,method)
 if A.Services.AcquisitionRequirementsResolver.Has(item.id) then return A.Services.AcquisitionRequirementsResolver.Summary(item.id,method) end
 local recipes=data().recipes[item.id];local lines={G.ShortSource(item)}
 if recipes and recipes[1] then lines[#lines+1]=G.CraftingText(recipes[1])
 else lines[#lines+1]='Origen de la guía importada; pendiente de verificar en Forever.' end
 lines[#lines+1]='Reputación, misiones y costes no publicados: sin confirmar.'
 lines[#lines+1]=G.credit;return table.concat(lines,'\n')
end
function G.Enhancements(slot,item)
 if not item or A.db.viewClass~='WARLOCK' or A.db.spec~='Affliction' then return {} end
 local ids=data().slotEnhancements[slot] or {};local r=G.Record(item)
 if slot=='MainHand' and r and r.inventoryTypeId==17 then ids={1248607,23804} end
 local rows={};for _,id in ipairs(ids) do local e=data().enhancements[id];if e then rows[#rows+1]=e end end;return rows
end
function G.EnhancementDetails(e)
 if not e then return '' end
 local lines={e.name,e.effect or 'Efecto sin publicar'}
 if e.profession then lines[#lines+1]=G.CraftingText(e)
 else lines[#lines+1]='Dónde conseguirlo: sin confirmar en Forever';lines[#lines+1]='Materiales / requisitos de aplicación: sin publicar' end
 if e.targetMinItemLevel then lines[#lines+1]='Requisito para aplicarlo: objeto de nivel '..e.targetMinItemLevel..' o superior (nivel del objeto, no del personaje).' end
 lines[#lines+1]='Aplicar una sola mejora permanente por ranura; el kit y el encantamiento son alternativas.'
 lines[#lines+1]=G.credit;return table.concat(lines,'\n')
end
function G.EnhancementRequirement(e,item)
 local r=G.Record(item);local current=r and r.itemLevel
 if not e.targetMinItemLevel then return {status='unknown'} end
 return {current=current,required=e.targetMinItemLevel,status=finite(current) and (current>=e.targetMinItemLevel and 'met' or 'missing') or 'unknown'}
end
function G.EnhancementSubtitle(e)
 local src=e.learnedFrom and e.learnedFrom.sources
 local effect=e.shortEffect or e.effect or 'Efecto sin publicar'
 if src and src.vendors then
  local faction=A.Compat.Call(UnitFactionGroup,'player');local side=type(faction)=='string' and faction:lower() or 'horde'
  local people=src.vendors[side] or src.vendors.alliance or {};local v=people[1]
  return effect..'\n'..(v and ('Fórmula: '..v.name..' · '..tostring(v.zone or 'zona sin publicar')) or 'Fórmula de vendedor')..' · ver materiales'
 end
 if src and src.trainers then return effect..'\nInstructor (procedencia indicada en detalles)' end
 return effect..'\n'..(src and #(src.drops or {})>0 and 'Fórmula de botín · comprobar procedencia Classic/Forever' or 'Origen sin confirmar · ver detalles')
end
return G
