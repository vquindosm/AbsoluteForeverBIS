local A=FWC
local O={};A.Services.Objectives=O
function O.Find(itemId,slot)
 local p=A.Services.Persistence.Profile();return (p.objectives or {})[A.db.mode..':'..tostring(slot)..':'..tostring(itemId)]
end
function O.Ensure(profile,id,slot,mode,profileKey)
 profile.objectives=profile.objectives or {}
    profile.priorities=profile.priorities or {}
 local key=(mode or 'Pre-BiS')..':'..tostring(slot)..':'..tostring(id)
 if profile.objectives[key] then return profile.objectives[key] end
 local item=A.Data.items[id];local steps,kind=A.Services.Acquisition.Resolve(item)
 local o={objectiveId=key,itemId=id,slot=slot,mode=mode or 'Pre-BiS',characterProfile=profileKey,title=item and item.name or ('Legacy item '..tostring(id)),icon=item and item.icon or 'Interface\\Icons\\INV_Misc_QuestionMark',sourceType=kind,sourceId=item and item.sourceType,priority=profile.priorities[id] or 2,trackingState='Tracked',completionState='Unknown',steps=steps,dependencies={},progress={},dataConfidence=item and item.provenance or 'unknown',lastUpdated=A.Compat.Now()}
 profile.objectives[key]=o;return o
end
function O.Migrate()
 for key,p in pairs(A.db.profiles) do
  if type(p)=='table' and not p.objectivesMigrated then
   p.objectives=p.objectives or {}
   for id,slot in pairs(type(p.planner)=='table' and p.planner or {}) do
    if slot then O.Ensure(p,id,type(slot)=='string' and slot or 'Unknown','Pre-BiS',key) end
   end
   p.objectivesMigrated=true
  end
 end
end
function O.Track(itemId,slot)
 local p=A.Services.Persistence.Profile();local o=O.Ensure(p,itemId,slot,A.db.mode,A.db.viewClass..':'..A.db.spec)
 o.trackingState='Tracked';o.lastUpdated=A.Compat.Now();p.planner[itemId]=slot;A:Refresh();return o
end
function O.Untrack(o)
 o.trackingState='Untracked';o.lastUpdated=A.Compat.Now()
 local p=A.Services.Persistence.Profile();p.planner[o.itemId]=nil
 for _,other in pairs(p.objectives or {}) do if other.itemId==o.itemId and other.trackingState=='Tracked' then p.planner[o.itemId]=other.slot end end
 A:Refresh()
end
function O.List(includeUntracked)
 local p=A.Services.Persistence.Profile();local rows={}
 for _,o in pairs(p.objectives or {}) do
  local priority=p.priorities[o.itemId] or o.priority or 2
  if o.priority~=priority then o.priority=priority;o.lastUpdated=A.Compat.Now() end
  if (includeUntracked or o.trackingState=='Tracked') and o.mode==A.db.mode then rows[#rows+1]=o end
 end
 table.sort(rows,function(a,b)
  if (p.focusObjective==a.objectiveId)~=(p.focusObjective==b.objectiveId) then return p.focusObjective==a.objectiveId end
  local ap,bp=p.priorities[a.itemId] or a.priority or 2,p.priorities[b.itemId] or b.priority or 2
  if ap~=bp then return ap<bp end;return a.objectiveId<b.objectiveId
 end)
 A.Services.Progress.Update(rows,p);return rows
end
function O.ToggleStep(o,step)
 if step.completionMode~='manual' or step.blocked then return false end
 step.manualCompleted=not step.manualCompleted;if step.nodeId then o.requirementManual=o.requirementManual or {};o.requirementManual[step.nodeId]=step.manualCompleted end;o.lastUpdated=A.Compat.Now();A:Refresh();return true
end
function O.AddDependency(o,stepId,dependencyId)
 local byId={};for _,s in ipairs(o.steps) do byId[s.stepId]=s end
 if not byId[stepId] or not byId[dependencyId] or stepId==dependencyId then return false end
 local function reaches(id,target,visited)
  if id==target then return true end
  if visited[id] then return false end;visited[id]=true
  for _,dep in ipairs(byId[id] and byId[id].dependencies or {}) do if reaches(dep,target,visited) then return true end end
  return false
 end
 if reaches(dependencyId,stepId,{}) then return false end
 local s=byId[stepId];s.dependencies=s.dependencies or {}
 for _,dep in ipairs(s.dependencies) do if dep==dependencyId then return true end end
 s.dependencies[#s.dependencies+1]=dependencyId;return true
end
function O.AddManual(o,title)
 title=(title or ''):match('^%s*(.-)%s*$')
 if title=='' or #title>240 then return false end
 o.customSerial=(o.customSerial or 0)+1
 o.steps[#o.steps+1]={stepId='user:'..o.customSerial,type='ManualAction',title=title,description=title,completionMode='manual',confidence='user',dependencies={}}
 o.lastUpdated=A.Compat.Now();A:Refresh();return true
end
function O.Next(o)
 if o.requirementsVersion then return A.Services.AcquisitionRequirementsResolver.Next(o) end
 for _,step in ipairs(o.steps) do if not step.completed then return step end end
end
