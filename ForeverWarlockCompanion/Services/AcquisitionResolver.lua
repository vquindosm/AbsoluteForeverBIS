local A=FWC
local R={};A.Services.Acquisition=R
R.dungeons={['Blackrock Spire: Upper']=true,['Blackrock Spire: Lower']=true,['Blackrock Depths']=true,['Scholomance']=true,['Stratholme']=true,['Dire Maul: East']=true,['Dire Maul: West']=true,['Dire Maul: North']=true,['Sunken Temple']=true,['Zul\'Farrak']=true,['Maraudon']=true}
function R.Kind(item)
 if not item then return 'Unknown' end
 if A.Services.AcquisitionRequirementsResolver.Has(item.id) then return 'Vendor' end
 if item.sourceType=='Unknown' or item.source=='Unknown' then return 'Unknown' end
 if R.dungeons[item.sourceType] then return 'Dungeon' end
 if item.sourceType=='Crafted' then return 'Crafting' end
 if item.sourceType=='Reputation' then return 'Reputation' end
 if string.find(item.sourceType or '','Quest',1,true) then return 'Quest' end
 return 'Other'
end
function R.Recipe(id)
 for _,recipe in ipairs(A.Data.recipes) do if recipe.itemID==id then return recipe end end
end
function R.Resolve(item)
 local steps={};local kind=R.Kind(item)
 if item and kind=='Vendor' then local resolver=A.Services.AcquisitionRequirementsResolver;return resolver.Steps(resolver.Plan(item.id),item,false),kind end
 local function add(id,t,title,mode,extra)
  local s={stepId=id,type=t,title=title,description=title,completionMode=mode,confidence=item and item.provenance or 'unknown',sourceReference=item and item.reference,dependencies={}}
  for key,value in pairs(extra or {}) do s[key]=value end;steps[#steps+1]=s;return s
 end
 if kind=='Dungeon' then
  add('dungeon','CompleteDungeon',item.sourceType,'manual')
  if item.source and item.source~='Unknown' then add('boss','KillBoss',item.source,'manual') end
 elseif kind=='Crafting' then
  local recipe=R.Recipe(item.id)
  add('learn','LearnRecipe','Confirm recipe: '..item.name,'manual',{confidence='pending_review'})
  if recipe and recipe.reagents and recipe.provenance~='legacy_unverified' then
   for i,r in ipairs(recipe.reagents) do add('material:'..i,'CollectMaterial',r.name,'inventory',{requiredAmount=r.qty,reagent=A.Services.Persistence.Copy(r)}) end
  else add('costs','ManualAction','Recipe costs not verified — review in game','manual',{confidence='unknown'}) end
  add('craft','CraftItem','Craft '..item.name,'manual')
 elseif kind=='Reputation' then
  local name,rank=item.source:match('^(.-) %- ([%a]+)$')
  add('reputation','ReachReputation',name and (name..' — '..rank) or item.source,'reputation',{factionName=name,requiredRank=rank})
  add('purchase','PurchaseItem','Acquire from reputation source: '..item.source,'manual')
 elseif kind=='Quest' then add('quest','CompleteQuest',item.source,'manual')
 elseif item and item.source~='Unknown' then add('source','ManualAction',item.source..' — '..item.sourceType,'manual')
 else add('unknown','ManualAction','Acquisition details not yet available.','manual',{confidence='unknown'}) end
 add('obtain','ObtainItem',item and ('Obtain '..item.name) or 'Obtain item','ownership',{requiredAmount=1})
 return steps,kind
end
