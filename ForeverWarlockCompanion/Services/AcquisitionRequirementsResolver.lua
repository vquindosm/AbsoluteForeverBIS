local A=FWC
local R={version=1};A.Services.AcquisitionRequirementsResolver=R
local function known(field) return type(field)=='table' and field.status=='KNOWN' and field.value~=nil end
local function value(field) if known(field) then return field.value end end
local function number(v) return A.Compat.Readable(v) and type(v)=='number' and v==v and math.abs(v)<math.huge end
R.Value=value
function R.Methods(itemId)
 local rows={};local data=A.Data.foundation
 for _,source in pairs(data and data.acquisitions or {}) do if source.itemId==itemId and source.type=='Vendor' then rows[#rows+1]=source end end
 table.sort(rows,function(a,b) return a.acquisitionId<b.acquisitionId end);return rows
end
function R.Has(itemId) return #R.Methods(itemId)>0 end
function R.Current(node)
 if node.metric=='stock' then return node.observedStock
 elseif node.metric=='level' then local n=A.Compat.Call(UnitLevel,'player');return number(n) and n or nil
 elseif node.metric=='gold' then local n=A.Compat.Call(GetMoney);return number(n) and n or nil
 elseif node.metric=='item' then local n,checked=A.Services.Inventory.Count({id=node.itemId});return checked and n or nil
 elseif node.metric=='currency' then local d=A.Compat.Call(C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo,node.currencyId);return type(d)=='table' and number(d.quantity) and d.quantity or nil
 elseif node.metric=='reputation' then local d=A.Compat.Call(C_Reputation and C_Reputation.GetFactionDataByID,node.factionId);return type(d)=='table' and number(d.reaction) and d.reaction or nil
 elseif node.metric=='quest' then local ok=A.Compat.Call(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted,node.questId);if A.Compat.Readable(ok) and type(ok)=='boolean' then return ok and 1 or 0 end
 elseif node.metric=='profession' then for _,p in pairs(A.Services.Character.professions or {}) do if p.canonical==node.profession and number(p.rank) then return p.rank end end end
end
function R.Evaluate(node,context,path)
 path=path or 'root';local out={node=type(node)=='table' and node or {op='UNKNOWN'},id=type(node)=='table' and node.id or path,status='unknown',children={}}
 if type(node)~='table' then return out end
 if node.op=='ALL' or node.op=='ANY' then
  local met,missing,unknown,manual=0,0,0,0
  for i,child in ipairs(node.children or {}) do local c=R.Evaluate(child,context,path..':'..i);out.children[#out.children+1]=c
   if c.status=='met' then met=met+1 elseif c.status=='missing' then missing=missing+1 elseif c.status=='manual' then manual=manual+1 else unknown=unknown+1 end
  end
  if #out.children==0 then out.status=node.op=='ALL' and node.confirmedEmpty==true and 'met' or 'unknown'
  elseif node.op=='ALL' then out.status=missing>0 and 'missing' or unknown>0 and 'unknown' or manual>0 and 'manual' or 'met'
  else out.status=met>0 and 'met' or unknown>0 and 'unknown' or manual>0 and 'manual' or 'missing' end
 elseif node.op=='QUANTITY' then
  local current;if context and type(context.current)=='function' then current=context.current(node) else current=R.Current(node) end
  out.current=current;out.required=node.amount
  if node.metric=='stock' and current==-1 then out.status='met';out.unlimited=true
  elseif number(current) and number(node.amount) and node.amount>=0 then out.status=current>=node.amount and 'met' or 'missing' end
 elseif node.op=='MANUAL' then out.status=context and context.manual and context.manual[out.id]==true and 'met' or 'manual'
 end
 return out
end
local function title(node)
 if node.title then return node.title end
 if node.op=='UNKNOWN' then return node.reason or 'Requirements unknown'
 elseif node.op=='MANUAL' then return 'Confirm requirement in game'
 elseif node.op=='ANY' then return 'One of the alternative requirements'
 elseif node.metric=='stock' then return 'Check vendor stock (wait if sold out)'
 elseif node.metric=='level' then return 'Reach level '..tostring(node.amount)
 elseif node.metric=='gold' then return 'Have '..tostring(node.amount)..' copper (observed price)'
 elseif node.metric=='item' or node.metric=='currency' then return 'Collect '..tostring(node.amount)..' '..(node.name or ('resource '..tostring(node.itemId or node.currencyId)))
 elseif node.metric=='reputation' then return 'Reach reputation rank '..tostring(node.amount)..' with faction '..tostring(node.factionId)
 elseif node.metric=='quest' then return 'Complete quest '..tostring(node.questId)
 elseif node.metric=='profession' then return node.profession..' skill '..tostring(node.amount) end
 return 'Review requirement'
end
local function observation(offer)
 local observer=A.Services.MerchantObserver;if not observer or not observer.active then return nil end
 local seen=observer.active[offer.itemId];if not seen then return nil end
 local vendor=A.Data.foundation.vendors[offer.vendorId]
 local expected=value(vendor.npcId);local binding=A.db.vendorSourceBindings and A.db.vendorSourceBindings[offer.vendorId];expected=expected or (binding and binding.npcId)
 if (expected and seen.npcId==expected) or (not expected and seen.vendorName==value(vendor.name)) then return seen end
end
function R.RequiredTree(offer,source)
 local tree=A.Services.Persistence.Copy(source.conditions or {op='UNKNOWN',reason='Source conditions unknown'})
 if tree.op~='ALL' then tree={op='ALL',children={tree}} end;tree.children=tree.children or {}
 local function same(a,b) return a.op=='QUANTITY' and a.metric==b.metric and a.itemId==b.itemId and a.currencyId==b.currencyId and a.factionId==b.factionId and a.questId==b.questId and a.amount==b.amount end
 local function append(node) for _,old in ipairs(tree.children) do if same(old,node) then return end end;tree.children[#tree.children+1]=node end
 local item=A.Data.foundation.items[source.itemId];local level=value(item.requiredLevel)
 if number(level) then append({op='QUANTITY',metric='level',amount=level}) end
 local gold=value(offer.goldCostCopper);if number(gold) then append({op='QUANTITY',metric='gold',amount=gold,role='purchase_gold'}) end
 for _,cost in ipairs(value(offer.additionalCurrencies) or {}) do append({op='QUANTITY',metric=cost.kind,itemId=cost.itemId,currencyId=cost.currencyId,name=cost.name,amount=cost.quantity,role='purchase_cost'}) end
 for _,cost in ipairs(value(offer.requiredItems) or {}) do append({op='QUANTITY',metric='item',itemId=cost.itemId,name=cost.name,amount=cost.quantity,role='purchase_cost'}) end
 local faction,rank=value(offer.requiredReputationFaction),value(offer.requiredReputationRank)
 if number(faction) and number(rank) then append({op='QUANTITY',metric='reputation',factionId=faction,amount=rank}) end
 local quests=value(offer.questPrerequisites)
 if type(quests)=='table' then if quests.op then tree.children[#tree.children+1]=A.Services.Persistence.Copy(quests) else for _,q in ipairs(quests) do append({op='QUANTITY',metric='quest',questId=q,amount=1}) end end end
 if known(offer.requiredProfession) and known(offer.requiredSkill) then append({op='QUANTITY',metric='profession',profession=value(offer.requiredProfession),amount=value(offer.requiredSkill)}) end
 return tree
end
function R.BindObserved(itemId,methodId)
 local methods=R.Methods(itemId);local method
 for _,m in ipairs(methods) do if not methodId or m.acquisitionId==methodId then method=m;break end end
 local seen=A.Services.MerchantObserver.active[itemId]
 if not method or not seen or not number(seen.npcId) then return false end
 local offer=A.Data.foundation.vendorOffers[method.sourceId]
 A.db.vendorSourceBindings=A.db.vendorSourceBindings or {}
 A.db.vendorSourceBindings[offer.vendorId]={npcId=seen.npcId,name=seen.vendorName,confidence='user_confirmed_mapping',confirmedAt=A.Compat.Now()}
 A:Refresh();return true
end
function R.ResourceName(cost)
 if cost.name then return cost.name end
 local item=cost.itemId and A.Data.foundation.items[cost.itemId]
 return item and value(item.name) or 'resource '..tostring(cost.itemId or cost.currencyId)
end
function R.Plan(itemId,methodId,manual)
 local methods=R.Methods(itemId);local chosen
 for _,m in ipairs(methods) do if m.acquisitionId==methodId then chosen=m end end;chosen=chosen or methods[1]
 if not chosen then return nil end
 local offer=A.Data.foundation.vendorOffers[chosen.sourceId];local root=R.RequiredTree(offer,chosen)
 local function identify(node,path) node.id=node.id or path;for i,c in ipairs(node.children or {}) do identify(c,path..':'..i) end end;identify(root,chosen.acquisitionId)
 local seen=offer and observation(offer)
 if seen and seen.costsComplete then
  if root.op~='ALL' then root={op='ALL',children={root}} end
  local kept={};for _,node in ipairs(root.children or {}) do if node.role~='purchase_cost' then kept[#kept+1]=node end end;root.children=kept
  for _,cost in ipairs(seen.costs) do root.children[#root.children+1]={op='QUANTITY',metric=cost.kind,itemId=cost.itemId,currencyId=cost.currencyId,name=R.ResourceName(cost),amount=cost.quantity,id='observed:cost:'..tostring(cost.itemId or cost.currencyId),role='purchase_cost'} end
 end
 if seen and number(seen.goldCostCopper) then
  if root.op~='ALL' then root={op='ALL',children={root}} end
  local kept={};for _,node in ipairs(root.children or {}) do if node.role~='purchase_gold' then kept[#kept+1]=node end end;root.children=kept
  root.children[#root.children+1]={op='QUANTITY',metric='gold',amount=seen.goldCostCopper,id='observed:gold'}
 end
 if seen and number(seen.stock) then root.children[#root.children+1]={op='QUANTITY',metric='stock',amount=1,observedStock=seen.stock,id='observed:stock'} end
 local evaluated=R.Evaluate(root,{manual=manual},chosen.acquisitionId)
 return {method=chosen,methods=methods,offer=offer,evaluated=evaluated,observation=seen,coverage=offer and offer.requirementsComplete and 'complete source requirements' or 'partial requirements'}
end
function R.Steps(plan,item,owned)
 local steps={}
 local function add(out)
  if out.node.op=='ALL' then for _,child in ipairs(out.children) do add(child) end;return end
  local node=out.node;local amount=out.current~=nil and out.required~=nil and (out.current..' / '..out.required) or nil
  local s={stepId='requirement:'..out.id,nodeId=out.id,type=node.op=='QUANTITY' and 'AcquisitionQuantity' or node.op=='UNKNOWN' and 'UnknownRequirement' or node.op=='ANY' and 'RequirementAlternatives' or 'ManualAction',title=title(node),description=title(node),completionMode=node.op=='MANUAL' and 'manual' or 'requirements',completed=out.status=='met',currentAmount=out.current,requiredAmount=out.required,confidence=plan.method.confidence,sourceReference=A.Data.foundation.provenance[plan.method.provenance[1]].sourceURL,dependencies={},requirementStatus=out.status,progressLabel=out.status..(amount and (' · '..amount) or '')}
  if out.unlimited then s.currentAmount=nil;s.requiredAmount=nil;s.progressLabel='Unlimited stock (observed)' end
  s.progressUnit=node.metric=='gold' and 'copper' or node.metric=='level' and 'levels' or node.name or node.metric
  if node.metric=='item' then s.reagent={id=node.itemId,name=node.name or tostring(node.itemId)} end
  if node.op=='ANY' then local labels={};for _,child in ipairs(out.children) do labels[#labels+1]=title(child.node)..' ['..child.status..']' end;s.progressLabel=table.concat(labels,' OR ') end
  steps[#steps+1]=s
 end
 add(plan.evaluated)
 steps[#steps+1]={stepId='obtain',type='ObtainItem',title='Buy '..item.name..' from '..value(A.Data.foundation.vendors[plan.offer.vendorId].name),completionMode='ownership',completed=owned,currentAmount=owned and 1 or 0,requiredAmount=1,dependencies={},confidence=plan.method.confidence}
 return steps
end
function R.UpdateObjective(o,owned)
 local plan=R.Plan(o.itemId,o.acquisitionMethod,o.requirementManual);if not plan then return end
 if not o.requirementsVersion then o.legacySourceId=o.sourceId;o.legacyAcquisitionSteps=A.Services.Persistence.Copy(o.steps) end
 local custom={};for _,step in ipairs(o.steps or {}) do if type(step.stepId)=='string' and step.stepId:match('^user:') then custom[#custom+1]=step end end
 o.requirementsVersion=R.version;o.acquisitionMethod=plan.method.acquisitionId;o.requirementsStatus=plan.evaluated.status;o.requirementsCoverage=plan.coverage
 o.sourceType='Vendor';o.sourceId=plan.offer.vendorId;o.steps=R.Steps(plan,A.Data.items[o.itemId],owned)
 for _,step in ipairs(custom) do step.completed=step.manualCompleted==true;o.steps[#o.steps+1]=step end
 A.Services.Progress.Dependencies(o.steps)
 local done,blocked=0,false;for _,step in ipairs(o.steps) do if step.completed then done=done+1 end;if step.blocked then blocked=true end end;o.progress={completed=done,total=#o.steps}
 o.completionState=owned and 'Obtained' or blocked and 'Blocked' or plan.evaluated.status=='met' and 'Ready to Acquire' or plan.evaluated.status=='missing' and 'Blocked' or 'Unknown'
end
function R.Select(o,id)
 for _,m in ipairs(R.Methods(o.itemId)) do if m.acquisitionId==id then o.acquisitionMethod=id;A:Refresh();return true end end
 return false
end
function R.SharedResources(rows)
 local resources,unknown={},{}
 for _,o in ipairs(rows) do if o.completionState~='Obtained' then
  local plan=R.Plan(o.itemId,o.acquisitionMethod)
  local function add(out)
   if out.node.op=='ALL' then for _,child in ipairs(out.children) do add(child) end
   elseif out.node.op=='ANY' then unknown[#unknown+1]=o.objectiveId..': alternatives are not summed'
   elseif out.node.op=='QUANTITY' and (out.node.metric=='item' or out.node.metric=='currency') then
    local key=out.node.metric..':'..tostring(out.node.itemId or out.node.currencyId);local entry=resources[key] or {kind=out.node.metric,itemId=out.node.itemId,currencyId=out.node.currencyId,required=0,objectives={}}
    entry.required=entry.required+out.node.amount;entry.objectives[#entry.objectives+1]=o.objectiveId;resources[key]=entry
   end
  end
  if plan then add(plan.evaluated) end
 end end
 for _,entry in pairs(resources) do entry.available=R.Current({metric=entry.kind,itemId=entry.itemId,currencyId=entry.currencyId});if entry.available~=nil then entry.missing=math.max(0,entry.required-entry.available) end end
 return resources,unknown
end
function R.Next(o)
 for _,step in ipairs(o.steps) do if not step.completed and step.requirementStatus=='missing' then return step end end
 for _,step in ipairs(o.steps) do if not step.completed then return step end end
end
function R.Summary(itemId,methodId)
 local plan=R.Plan(itemId,methodId);if not plan then return '' end
 local offer=plan.offer;local v=A.Data.foundation.vendors[offer.vendorId];local src=A.Data.foundation.provenance[plan.method.provenance[1]]
 local lines={value(v.name)..' · '..tostring(value(v.zone) or 'Zone unknown')}
 local coords=value(v.coordinates);lines[#lines+1]=coords and (tostring(coords.x)..', '..tostring(coords.y)) or 'Coordinates: Unknown'
 lines[#lines+1]='Vendor affiliation: '..tostring(value(v.faction) or 'Unknown')..' (not a purchase restriction)'
 lines[#lines+1]='Base gold: '..(known(offer.goldCostCopper) and (tostring(offer.goldCostCopper.value)..' copper') or 'Unknown')
 for _,cost in ipairs(value(offer.additionalCurrencies) or {}) do local n=R.Current({metric=cost.kind,itemId=cost.itemId,currencyId=cost.currencyId});lines[#lines+1]=(cost.name or 'Currency')..': '..tostring(n or 'Unknown')..' / '..cost.quantity end
 lines[#lines+1]='Required reputation: '..tostring(value(offer.requiredReputationFaction) or 'Unknown')..' / '..tostring(value(offer.requiredReputationRank) or 'Unknown')
 lines[#lines+1]='Extra items / quests / stock: '..(offer.requirementsComplete and 'See verified requirements' or 'Unknown')
 if plan.observation then for _,cost in ipairs(plan.observation.costs or {}) do lines[#lines+1]='Current observed cost: '..cost.quantity..' '..R.ResourceName(cost) end;lines[#lines+1]='Current observed price: '..tostring(plan.observation.goldCostCopper or 'Unknown')..' copper';lines[#lines+1]='Current stock: '..(plan.observation.stock==-1 and 'Unlimited (observed)' or tostring(plan.observation.stock or 'Unknown')) end
 lines[#lines+1]='Coverage: '..plan.coverage
 lines[#lines+1]='Data from ForeverDB.net · '..src.sourceURL
 return table.concat(lines,'\n')
end
return R
