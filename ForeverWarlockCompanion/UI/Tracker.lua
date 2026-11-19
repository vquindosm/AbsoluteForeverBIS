local A=FWC
local T={};A.UI.Tracker=T
function T.Create()
 if T.frame then return end
 local W=A.UI.Widgets;local f=A.UI.DesignSystem.Card(UIParent);T.frame=f
 A.db.trackerWindow=A.db.trackerWindow or {};local saved=A.db.trackerWindow
 f:SetSize(math.max(260,math.min(500,tonumber(saved.width) or 310)),math.max(240,math.min(700,tonumber(saved.height) or 350)))
 local anchors={CENTER=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true}
 f:SetPoint(anchors[saved.point] and saved.point or 'RIGHT',UIParent,anchors[saved.relativePoint] and saved.relativePoint or 'RIGHT',tonumber(saved.x) or -35,tonumber(saved.y) or 0)
 f:SetFrameStrata('MEDIUM');f:SetMovable(true);f:SetResizable(true);f:SetClampedToScreen(true);f:EnableMouse(true)
 A.Compat.Method(f,'SetResizeBounds',260,240,500,700)
 f.header=W.Button(f,'',function()
  local mode=A.db.settings.trackerMode or 'Compact'
  A.db.settings.trackerMode=mode=='Compact' and 'Expanded' or mode=='Expanded' and 'Collapsed' or 'Compact'
  A.db.settings.trackerCollapsed=A.db.settings.trackerMode=='Collapsed';T.Render()
 end)
 f.header:SetPoint('TOPLEFT',5,-5);f.header:SetPoint('TOPRIGHT',-5,-5);f.header:RegisterForDrag('LeftButton')
 f.header:SetScript('OnDragStart',function() f:StartMoving() end)
 f.header:SetScript('OnDragStop',function()
  f:StopMovingOrSizing();local point,relative,relativePoint,x,y=f:GetPoint()
  if not relative or relative==UIParent then saved.point=point;saved.relativePoint=relativePoint;saved.x=x;saved.y=y end
 end)
 f.next=A.UI.DesignSystem.Section(f,'Next action');f.next:SetPoint('TOPLEFT',8,-38);f.next:SetPoint('TOPRIGHT',-8,-38);f.next:SetHeight(88);f.next.text:SetHeight(42)
 f.list=W.List(f,80);f.list:SetPoint('TOPLEFT',8,-136);f.list:SetPoint('BOTTOMRIGHT',-24,44)
 f.sourceCredit=W.Label(f,'Data: ForeverDB.net · https://foreverdb.net');f.sourceCredit:SetPoint('BOTTOMLEFT',10,40);f.sourceCredit:SetPoint('BOTTOMRIGHT',-10,40);f.sourceCredit:SetHeight(26);f.sourceCredit:Hide()
 f.empty=W.Label(f,'No tracked objectives. Use Track Objective on an item.');f.empty:SetPoint('TOPLEFT',12,-47);f.empty:SetPoint('TOPRIGHT',-12,-47)
 f.details=W.Button(f,'Open Details',function()
  if not A.UI.window then A.UI.Create() end
  A.UI.window:Show();A.UI.SetTab('Progression',T.selected and {objectiveId=T.selected.objectiveId} or nil)
 end);f.details:SetPoint('BOTTOMLEFT',8,10);f.details:SetWidth(132)
 f.more=W.Menu(f,'Actions',{'Focus objective','Cycle priority','Untrack','Compact','Expanded'},function(action)
  local p=A.Services.Persistence.Profile();local o=T.selected
  if action=='Focus objective' and o then p.focusObjective=o.objectiveId
  elseif action=='Cycle priority' and o then p.priorities[o.itemId]=(p.priorities[o.itemId] or o.priority or 2)%3+1
  elseif action=='Untrack' and o then A.Services.Objectives.Untrack(o)
  elseif action=='Compact' or action=='Expanded' then A.db.settings.trackerMode=action;A.db.settings.trackerCollapsed=false end
  A:Refresh()
 end);f.more:SetPoint('BOTTOMLEFT',148,10);f.more:SetPoint('BOTTOMRIGHT',-22,10)
 f.resize=W.Button(f,'/',nil);f.resize:SetSize(16,18);f.resize:SetPoint('BOTTOMRIGHT',-2,2)
 f.resize:SetScript('OnMouseDown',function() f:StartSizing('BOTTOMRIGHT') end)
 f.resize:SetScript('OnMouseUp',function() f:StopMovingOrSizing();saved.width=f:GetWidth();saved.height=f:GetHeight();T.Render() end)
 T.Render()
end
function T.Reputation(item)
    if not item or item.sourceType~="Reputation" or type(item.source)~="string" then return nil end
    local name,goal=item.source:match("^(.-) %- ([%a]+)$")
    if not name or not ({Honored=true,Revered=true,Exalted=true})[goal] then return nil end
    local api=C_Reputation
    if not api then return nil end
    local p=A.Services.Persistence.Profile();local manual=p.factions and p.factions[item.id]
    local count=A.Compat.Call(api.GetNumFactions)
    if not A.Compat.Readable(count) or type(count)~="number" then count=0 end
    if not manual and name:find("/",1,true) then return nil end
    for i=1,(manual and 1 or count) do
        local data
        if manual then data=A.Compat.Call(api.GetFactionDataByID,manual) else data=A.Compat.Call(api.GetFactionDataByIndex,i) end
        if type(data)=="table" and A.Compat.Readable(data.name) and (manual or data.name==name) then
            local lo,hi,current=data.currentReactionThreshold,data.nextReactionThreshold,data.currentStanding
            if A.Compat.Readable(lo) and A.Compat.Readable(hi) and A.Compat.Readable(current)
                and type(lo)=="number" and type(hi)=="number" and type(current)=="number" and hi>lo then
                local reaction=A.Compat.Readable(data.reaction) and data.reaction
                local label=type(reaction)=="number" and _G["FACTION_STANDING_LABEL"..reaction] or nil
                return {name=data.name,goal=goal,reaction=reaction,rank=label or "Reputation",value=math.max(0,math.min(hi-lo,current-lo)),total=hi-lo}
            end
        end
    end
end
function T.Render()
 local f=T.frame;if not f or not A.db then return end
 if A.db.settings.trackerHidden then f:Hide();return end;f:Show()
 local mode=A.db.settings.trackerCollapsed and 'Collapsed' or A.db.settings.trackerMode or 'Compact'
 local all=A.Services.Objectives.List();local rows={};local p=A.Services.Persistence.Profile();local chosen
 for _,o in ipairs(all) do if o.objectiveId==p.focusObjective then chosen=o end end
 chosen=chosen or T.selected
 local valid=false;for _,o in ipairs(all) do if chosen==o then valid=true end end
 if not valid then chosen=all[1] end;T.selected=chosen
 for _,o in ipairs(all) do
  if o.completionState~='Obtained' or o==chosen then
   local item=A.Data.items[o.itemId];rows[#rows+1]={kind='objective',objective=o,item=item}
   if mode=='Expanded' and o==chosen then
    for _,step in ipairs(o.steps) do rows[#rows+1]={kind='step',objective=o,step=step,item=item} end
   end
  end
 end
 f:SetHeight(mode=='Collapsed' and 36 or math.max(240,tonumber(A.db.trackerWindow.height) or 350))
 f.header:SetText((mode=='Collapsed' and '+ ' or '− ')..'OBJECTIVES  ·  '..#all..'  ·  '..mode)
 f.sourceCredit:SetShown(false);f.next:SetShown(mode~='Collapsed');f.list:SetShown(mode~='Collapsed');f.empty:SetShown(mode~='Collapsed' and #rows==0)
 f.details:SetShown(mode~='Collapsed');f.more:SetShown(mode~='Collapsed');f.resize:SetShown(mode~='Collapsed')
 if mode=='Collapsed' then return end
 local credit=false;for _,o in ipairs(all) do if o.requirementsVersion then credit=true end end;f.sourceCredit:SetShown(credit)
 f.list:ClearAllPoints();f.list:SetPoint('TOPLEFT',8,-136);f.list:SetPoint('BOTTOMRIGHT',-24,credit and 76 or 44)
 local nextStep=chosen and A.Services.Objectives.Next(chosen)
 f.next.text:SetText(nextStep and nextStep.title or chosen and 'No remaining acquisition steps.' or 'Choose an item to track from Equipment.')
 f.list:Render(rows,function(row,entry)
  local o=entry.objective;local item=entry.item
  if not row.itemIcon then
   row.itemIcon=row:CreateTexture(nil,'ARTWORK');row.itemIcon:SetSize(28,28);row.itemIcon:SetPoint('TOPLEFT',6,-8)
   row.barBg=row:CreateTexture(nil,'ARTWORK');row.barBg:SetPoint('BOTTOMLEFT',42,6);row.barBg:SetPoint('BOTTOMRIGHT',-8,6);row.barBg:SetHeight(6);row.barBg:SetColorTexture(.12,.13,.15,1)
   row.bar=row:CreateTexture(nil,'OVERLAY');row.bar:SetPoint('BOTTOMLEFT',row.barBg,'BOTTOMLEFT');row.bar:SetHeight(6);row.bar:SetColorTexture(.70,.55,.22,1)
  end
  row.title:ClearAllPoints();row.title:SetPoint('TOPLEFT',42,-6);row.title:SetPoint('TOPRIGHT',-7,-6);row.title:SetHeight(28)
  row.sub:ClearAllPoints();row.sub:SetPoint('TOPLEFT',42,-36);row.sub:SetPoint('TOPRIGHT',-7,-36);row.sub:SetHeight(27)
  row.itemIcon:SetShown(entry.kind=='objective');row.itemIcon:SetTexture(item and item.icon or o.icon)
  if entry.kind=='objective' then
   local step=A.Services.Objectives.Next(o)
   row.title:SetText((o==chosen and '|cffffd100' or '|cffffffff')..o.title..'|r')
   row.sub:SetText(o.completionState..'\n'..(step and step.title or 'Acquisition recorded'))
   local current,total
   if step and (step.type=='ReachReputation' or step.type=='AcquisitionQuantity') then current=step.currentAmount;total=step.requiredAmount
   else current=o.progress.completed;total=o.progress.total end
   local show=type(current)=='number' and type(total)=='number' and total>0
   local amount=show and (current..'/'..total..(step and step.type=='ReachReputation' and ' reputation' or step and step.progressUnit and (' '..step.progressUnit) or ' steps')) or 'Amount unknown'
   row.sub:SetText(o.sourceType..' · '..o.completionState..' · '..amount..'\n'..(step and step.title or 'Acquisition recorded'))
   row.barBg:SetShown(show);row.bar:SetShown(show)
   if show then row.bar:SetWidth(math.max(.01,(row:GetWidth()-50)*math.min(1,current/total))) end
   row:SetScript('OnClick',function() T.selected=o;p.focusObjective=nil;A.db.settings.trackerMode='Expanded';T.Render() end)
   if item then A.UI.Widgets.Tooltip(row,function() return item.id end) end
  else
   local step=entry.step;row.bar:Hide();row.barBg:Hide()
   row.title:SetText((step.completed and '[x] ' or step.blocked and '[blocked] ' or '[ ] ')..step.title)
   local amount=type(step.currentAmount)=='number' and type(step.requiredAmount)=='number' and (step.currentAmount..' / '..step.requiredAmount) or ''
   row.sub:SetText((step.completionMode=='manual' and 'Click to update' or 'Checked when available')..'  '..amount..(step.progressLabel and ('\n'..step.progressLabel) or ''))
   row:SetScript('OnClick',function() A.Services.Objectives.ToggleStep(o,step) end)
  end
 end)
end
function T.Toggle()
 if not T.frame then T.Create() end
 A.db.settings.trackerHidden=not A.db.settings.trackerHidden;T.Render()
end
