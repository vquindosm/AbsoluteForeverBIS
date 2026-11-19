local A=FWC
local P={};A.Services.Progress=P
function P.Dependencies(steps)
 local byId={};for _,s in ipairs(steps) do byId[s.stepId]=s end
  -- Dependencies affect manual planning steps, never the evidence of actual possession.
  for pass=1,#steps do
   for _,step in ipairs(steps) do
    step.blocked=false
    for _,dep in ipairs(step.dependencies or {}) do
     if not byId[dep] or not byId[dep].completed then step.blocked=true;break end
    end
    if step.blocked and step.completionMode=='manual' then step.completed=false end
   end
  end
end
function P.Update(rows,profile)
 local inv=A.Services.Inventory.snapshot;local counts={};local used={};local physical={}
 for id,n in pairs(inv.bags) do counts[id]=n end
 for _,entry in pairs(inv.equipped) do if entry.id then counts[entry.id]=(counts[entry.id] or 0)+1 end end
 for id,n in pairs(counts) do physical[id]=n end
 for id,manual in pairs(profile.obtained or {}) do if manual then counts[id]=math.max(counts[id] or 0,1) end end
 for _,o in ipairs(rows) do
  local owned=(counts[o.itemId] or 0)>(used[o.itemId] or 0)
  o.acquisitionEvidence=owned and ((physical[o.itemId] or 0)>(used[o.itemId] or 0) and 'Observed in equipment/bags' or 'Marked manually') or 'Not observed'
  if owned then used[o.itemId]=(used[o.itemId] or 0)+1 end
  if A.Services.AcquisitionRequirementsResolver.Has(o.itemId) then A.Services.AcquisitionRequirementsResolver.UpdateObjective(o,owned) else
  local done,unknown,blocked=0,not (inv.complete and inv.equipmentChecked),false
  for _,step in ipairs(o.steps) do
   step.completed=false;step.currentAmount=nil;step.requiredAmount=step.type=='ObtainItem' and 1 or step.requiredAmount
   if step.completionMode=='manual' then step.completed=step.manualCompleted==true
   elseif step.completionMode=='ownership' then step.completed=owned;step.currentAmount=owned and 1 or 0
   elseif step.completionMode=='inventory' then
    local n,checked=A.Services.Inventory.Count(step.reagent);step.currentAmount=checked and n or nil;step.completed=checked and n>=step.requiredAmount or false
    if not checked then unknown=true end
   elseif step.completionMode=='reputation' then
    local rep=A.UI.Tracker and A.UI.Tracker.Reputation(A.Data.items[o.itemId])
    local required=({Honored=6,Revered=7,Exalted=8})[step.requiredRank]
    step.progressLabel=rep and (rep.rank..' → '..tostring(step.requiredRank)) or 'Reputation unavailable'
    if rep and required and type(rep.reaction)=='number' then
     step.completed=rep.reaction>=required
     -- Only the client's next threshold is known, so only use it for the actual target rank.
     if rep.reaction==required-1 then step.currentAmount=rep.value;step.requiredAmount=rep.total
     elseif step.completed then step.currentAmount=1;step.requiredAmount=1
     else step.currentAmount=nil;step.requiredAmount=nil end
    else unknown=true end
   end
  end
  P.Dependencies(o.steps)
  for _,step in ipairs(o.steps) do
   if step.completed then done=done+1 end
   if step.blocked then blocked=true end
  end
  local total=#o.steps;o.progress={completed=done,total=total}
  if owned then o.completionState='Obtained'
  elseif not A.Data.items[o.itemId] or o.sourceType=='Unknown' then o.completionState='Unknown'
  elseif o.blocked or blocked then o.completionState='Blocked'
  elseif total>1 and done==total-1 then o.completionState='Ready to Acquire'
  elseif done>0 then o.completionState='In Progress'
  elseif unknown then o.completionState='Unknown'
  else o.completionState='Not Started' end
  end
  o.lastChecked=A.Compat.Now()
 end
end
