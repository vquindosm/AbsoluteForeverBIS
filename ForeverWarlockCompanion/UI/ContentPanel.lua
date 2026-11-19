local A=FWC
local C={frames={}};A.UI.ContentPanel=C
function C.Create(parent,kind)
 local W=A.UI.Widgets;local f=CreateFrame('Frame',nil,parent);f:SetAllPoints(parent);C.frames[kind]=f
 f.left=W.Panel(f);f.left:SetPoint('TOPLEFT');f.left:SetPoint('BOTTOMLEFT')
 f.right=W.Panel(f);f.right:SetPoint('TOPLEFT',f.left,'TOPRIGHT',10,0);f.right:SetPoint('BOTTOMRIGHT')
 f.title=W.Label(f.left,kind,'GameFontNormal');f.title:SetPoint('TOPLEFT',12,-12)
 f.list=W.List(f.left,82);f.list:SetPoint('TOPLEFT',10,-42);f.list:SetPoint('BOTTOMRIGHT',-26,10)
 f.text=W.TextScroll(f.right);f.text:SetPoint('TOPLEFT',12,-14);f.text:SetPoint('BOTTOMRIGHT',-28,50)
    f.related=W.List(f.right,82);f.related:SetPoint('TOPLEFT',12,-132);f.related:SetPoint('BOTTOMRIGHT',-28,50)
 f.open=W.Button(f.right,'Open objective',function() if f.objective then A.UI.SetTab('Progression',{objectiveId=f.objective.objectiveId}) end end);f.open:SetPoint('BOTTOMLEFT',12,12);f.open:SetPoint('BOTTOMRIGHT',-12,12)
 f:SetScript('OnSizeChanged',function(self,width) self.left:SetWidth(width*.44) end);return f
end
function C.Render(kind)
 local f=C.frames[kind];local groups=A.Services.Dungeons.Groups(kind=='Dungeons' and 'Dungeon' or kind=='Reputations' and 'Reputation' or nil)
 if kind=='Cooldowns' or kind=='Professions Overview' then
  f.related:Hide();f.text:ClearAllPoints();f.text:SetPoint('TOPLEFT',12,-14);f.text:SetPoint('BOTTOMRIGHT',-28,50)
  local moon
  for _,r in ipairs(A.Data.recipes) do if r.key=='mooncloth' then moon=r end end
  local recipes=kind=='Cooldowns' and (moon and {moon} or {}) or A.Services.Professions.Recipes()
  f.list:Render(recipes,function(row,r)
   row.title:SetText(r.name);row.sub:SetText(r.profession..' · '..(A.Data.provenance[r.provenance] or 'Pending review'))
   row:SetScript('OnClick',function() A.UI.SetTab('Professions',{recipeKey=r.key}) end)
  end)
  f.open:SetText('Open Recipes');f.open:SetEnabled(true);f.open:SetScript('OnClick',function() A.UI.SetTab('Professions',moon and kind=='Cooldowns' and {recipeKey=moon.key} or nil) end)
  local lines={'PROFESSIONS / COOLDOWNS', 'Active filters: '..(A.db.professions[1] or 'Any')..' / '..(A.db.professions[2] or 'Any'),'Only manual Mooncloth history is available. Its inherited 2 Felcloth / 95h estimate remains unverified. No recipe is asserted learned or craftable.'}
  local remaining=A.Services.Professions.Cooldown();lines[#lines+1]=remaining and ('Estimated Mooncloth remaining: '..math.floor(remaining/3600)..'h') or 'No Mooncloth craft recorded.'
  for i=#A.db.moonclothHistory,math.max(1,#A.db.moonclothHistory-9),-1 do if type(A.db.moonclothHistory[i])=='number' then lines[#lines+1]=A.Compat.Date('%Y-%m-%d %H:%M',A.db.moonclothHistory[i]) end end
  local materials,unknown=A.Services.Materials.ForObjectives(A.Services.Objectives.List());lines[#lines+1]='Known material requirements: '..#materials..'; objectives with unknown costs: '..#unknown
  f.text:SetText(table.concat(lines,'\n\n'));return
 end
 if kind=='Crafting Planner' then
      f.related:Hide();f.text:ClearAllPoints();f.text:SetPoint('TOPLEFT',12,-14);f.text:SetPoint('BOTTOMRIGHT',-28,50)
  local rows,unknown=A.Services.Materials.ForObjectives(A.Services.Objectives.List());local lines={'SHARED MATERIAL REQUIREMENTS','Bags only. Costs and availability must be known. No recipe is declared craftable without knowledge and cooldown checks.',''}
  for _,r in ipairs(rows) do lines[#lines+1]=r.name..': '..tostring(r.available or '?')..' / '..r.required..'  Missing: '..tostring(r.missing or '?') end
  for _,name in ipairs(unknown) do lines[#lines+1]='Costs pending: '..name end
  if #rows==0 and #unknown==0 then lines[#lines+1]='No tracked crafting requirements. Track a crafted item first.' end
  f.text:SetText(table.concat(lines,'\n\n'))
  local crafting={};for _,o in ipairs(A.Services.Objectives.List()) do if o.sourceType=='Crafting' then crafting[#crafting+1]=o end end
  f.list:Render(crafting,function(row,o)
   A.UI.DesignSystem.ItemCard(row,A.Data.items[o.itemId],o.completionState)
   row:SetScript('OnClick',function() f.objective=o;A.UI.SetTab('Progression',{objectiveId=o.objectiveId}) end)
  end);f.objective=crafting[1];f.open:SetEnabled(f.objective~=nil);return
 end
 local context=A.Services.Navigation.context
 local chosen
 for _,g in ipairs(groups) do if g.name==(context.sourceId or f.selected) then chosen=g end end
 chosen=chosen or groups[1];f.selected=chosen and chosen.name
 f.list:Render(groups,function(row,g)
  row.title:SetText(g.name);row.sub:SetText(g.obtained..' / '..#g.objectives..' obtained  ·  partial coverage')
  row:SetScript('OnClick',function() f.selected=g.name;A.Services.Navigation.context={};C.Render(kind) end)
 end)
 f.objective=chosen and chosen.objectives[1];f.open:SetEnabled(f.objective~=nil)
    f.text:ClearAllPoints();f.text:SetPoint('TOPLEFT',12,-14);f.text:SetPoint('TOPRIGHT',-28,-14);f.text:SetHeight(104)
    f.related:Show();f.related:Render(chosen and chosen.objectives or {},function(row,o)
        local item=A.Data.items[o.itemId]
        A.UI.DesignSystem.ItemCard(row,item,o.completionState..'\n'..(item and item.source or 'Unknown source'))
        row:SetScript('OnClick',function() A.UI.SetTab('Progression',{objectiveId=o.objectiveId}) end)
    end)
    if not chosen then f.text:SetText('No tracked objectives for this source.\n\nTrack an item to derive its activities. Catalog coverage is partial. No boss or drop data is invented.');return end
 local lines={chosen.name,'Personal objectives only — catalog coverage is partial.',''}
 for _,o in ipairs(chosen.objectives) do
  local item=A.Data.items[o.itemId];lines[#lines+1]=o.title..'  —  '..o.completionState
  if item then lines[#lines+1]='Source: '..item.source end
  local nextStep=A.Services.Objectives.Next(o);if nextStep then lines[#lines+1]='Next: '..nextStep.title end
 end
 lines[#lines+1]='';lines[#lines+1]='Use My Objectives to open any individual item and its steps. No boss kill, drop rate or optimal route is assumed.'
    f.text:SetText(chosen.name..'\n\n'..chosen.obtained..' / '..#chosen.objectives..' obtained. Coverage partial.\nSelect an item below for its source and steps. Zone/loot beyond imported metadata is unknown.')
end
