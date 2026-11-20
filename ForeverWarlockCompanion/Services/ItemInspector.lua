local A=FWC
local I={};A.Services.ItemInspector=I
function I.IsPilot(item) return item and item.id==A.Data.inspectorPilot.itemId end
local function money(n)
 return string.format('%dg %ds %dc',math.floor(n/10000),math.floor(n/100)%100,n%100)
end
function I.Model(slot,item)
 if not I.IsPilot(item) then return nil end
 local G=A.Services.ItemGuide;local data=A.Data.itemGuide;local pilot=A.Data.inspectorPilot
 local record=G.Record(item);local live=A.Compat.ItemInfo(item.link or item.id)
 local compared=A.Services.UpgradeComparison.ForSlot(slot,item)
 local model={item=item,record=record,live=live,comparison=compared,stats={},alternatives={},status=A.Services.Inventory.Status(item),sourceType='Profession',displayDeltas=A.Services.UpgradeComparison.DisplayDeltas(compared)}
 local recipe=data.recipes[item.id] and data.recipes[item.id][1];model.recipe=recipe
 for _,entry in ipairs(pilot.stats) do
  local value,state=A.Services.ItemStats.Value(compared.after,entry.key)
  if state~='confirmed' and state~='zero' then value=nil end
  if value==nil then for _,stat in ipairs(record.stats) do if stat.statId==entry.statId then value=stat.value;model.publishedStats=true end end end
  if type(value)=='number' then model.stats[#model.stats+1]={key=entry.key,label=entry.label,value=value,icon=entry.icon} end
 end
 model.materials=recipe and G.Materials(recipe) or {}
 for _,mat in ipairs(model.materials) do
  mat.missing=mat.available and math.max(0,mat.required-mat.available) or nil
  if not model.nextAction and mat.missing and mat.missing>0 then model.nextAction='Reúne '..mat.missing..' '..mat.name end
 end
 model.nextAction=model.nextAction or 'Comprueba el patrón y prepara la fabricación'
 model.costs={{kind='crafting',label='Fabricación',value='Materiales de arriba · sin estimación en oro'},
  {kind='purchase',label='Compra al vendedor',value='Oferta no publicada'},
  {kind='sell',label='Reventa al vendedor',value=money(pilot.sellPriceCopper)},
  {kind='market',label='Subasta',value='Precio de mercado no disponible'}}
 local reference=G.Recommendation(slot,item)
 if reference and reference.behindPercent then model.affinity={spec='Aflicción',context='JcE · nivel 60',behindPercent=reference.behindPercent} end
 for _,id in ipairs(A.Services.Catalog.List(A.db.viewClass,A.db.spec,A.db.mode,slot)) do
  if id~=item.id and #model.alternatives<3 then
   local other=A.Data.items[id];model.alternatives[#model.alternatives+1]={item=other,status=A.Services.Inventory.Status(other),comparison=A.Services.UpgradeComparison.ForSlot(slot,other)}
  end
 end
 local prov=data.provenance[record.source] or {};local raw={}
 for _,s in ipairs(pilot.stats) do raw[#raw+1]=s.statId..' → '..s.key end
 model.advanced=table.concat({'itemID: '..item.id,'Source URL: '..pilot.sourceURL,'Provenance: '..tostring(prov.evidenceType)..' · '..pilot.status,
  'Imported: '..tostring(prov.importedAt),'Reviewed: '..pilot.reviewedAt,'Client API: '..A.Services.ItemStats.Describe(compared.after),
  'Equipped: '..A.Services.ItemStats.Describe(compared.before),'Raw identifiers: '..table.concat(raw,', '),
  'Calculation: '..tostring(compared.reason or compared.calculationStatus),'Warnings: '..table.concat(compared.warnings or {},', '),
  'Published affinity: https://foreverdb.net/bis/warlock/affliction'},'\n\n')
 return model
end
return I
