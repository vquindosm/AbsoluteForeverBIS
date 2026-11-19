local A=FWC
local M={};A.Services.Materials=M
function M.ForObjectives(rows)
 local result,unknown={},{}
 for _,o in ipairs(rows) do
  if o.sourceType=='Crafting' and o.completionState~='Obtained' then
   local found=false
   for _,step in ipairs(o.steps) do
    if step.type=='CollectMaterial' and step.reagent and step.requiredAmount then
     local r=step.reagent;local key=r.id and ('id:'..r.id) or ('name:'..r.name)
     local entry=result[key] or {name=r.name,id=r.id,required=0,objectives={}}
     entry.required=entry.required+step.requiredAmount;entry.objectives[#entry.objectives+1]=o.objectiveId;result[key]=entry;found=true
    end
   end
   if not found then unknown[#unknown+1]=o.title end
  end
 end
 local rowsOut={}
 for _,r in pairs(result) do local n,known=A.Services.Inventory.Count(r);r.available=known and n or nil;r.missing=known and math.max(0,r.required-n) or nil;rowsOut[#rowsOut+1]=r end
 table.sort(rowsOut,function(a,b) return a.name<b.name end);return rowsOut,unknown
end
