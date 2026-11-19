local A=FWC
local U={filter='All',search=''};A.UI.ObjectivesPanel=U
function U.Create(parent)
 local W,S=A.UI.Widgets,A.UI.DesignSystem;local f=CreateFrame('Frame',nil,parent);f:SetAllPoints(parent);U.frame=f
 f.toolbar=CreateFrame('Frame',nil,f);f.toolbar:SetPoint('TOPLEFT');f.toolbar:SetPoint('TOPRIGHT');f.toolbar:SetHeight(32)
 f.filter=W.Menu(f.toolbar,'All objectives',{'All','In Progress','Not Started','Obtained'},function(v) U.filter=v;U.Render() end);f.filter:SetPoint('TOPLEFT');f.filter:SetWidth(150)
 f.search=W.Edit(f.toolbar,function(v) U.search=v;U.Render() end);f.search:SetPoint('TOPLEFT',f.filter,'TOPRIGHT',10,0);f.search:SetPoint('TOPRIGHT');f.search:SetHeight(26)
 f.methods=W.Menu(f.toolbar,'Acquisition method',function() local rows={};if U.selected then for _,m in ipairs(A.Services.AcquisitionRequirementsResolver.Methods(U.selected.itemId)) do rows[#rows+1]={label=m.type..' · '..m.sourceId,value=m.acquisitionId} end end;return rows end,function(id) if U.selected then A.Services.AcquisitionRequirementsResolver.Select(U.selected,id) end end)
 f.methods:SetPoint('TOPLEFT',f.filter,'TOPRIGHT',10,0);f.methods:SetWidth(180);f.methods:Hide()
 f.left=S.Card(f);f.left:SetPoint('TOPLEFT',0,-42);f.left:SetPoint('BOTTOMLEFT')
 f.right=S.Card(f);f.right:SetPoint('TOPLEFT',f.left,'TOPRIGHT',12,0);f.right:SetPoint('BOTTOMRIGHT')
 f.heading=W.Label(f.left,'Tracked items','GameFontNormal');f.heading:SetPoint('TOPLEFT',12,-12)
 f.list=W.List(f.left,92);f.list:SetPoint('TOPLEFT',8,-42);f.list:SetPoint('BOTTOMRIGHT',-24,10)
 f.empty=W.Label(f.left,'No matching objectives.');f.empty:SetPoint('TOPLEFT',12,-50);f.empty:SetPoint('TOPRIGHT',-12,-50)
 f.icon=f.right:CreateTexture(nil,'ARTWORK');f.icon:SetSize(42,42);f.icon:SetPoint('TOPLEFT',14,-14)
 f.title=W.Label(f.right,'','GameFontNormalLarge');f.title:SetPoint('TOPLEFT',68,-14);f.title:SetPoint('TOPRIGHT',-14,-14);f.title:SetHeight(42)
 f.badge=S.Badge(f.right);f.badge:SetPoint('TOPRIGHT',-12,-66)
 f.state=W.Label(f.right,'');f.state:SetPoint('TOPLEFT',14,-64);f.state:SetPoint('TOPRIGHT',-128,-64);f.state:SetHeight(42)
 f.progress=S.ProgressBar(f.right);f.progress:SetPoint('TOPLEFT',14,-116);f.progress:SetPoint('TOPRIGHT',-14,-116);f.progress:SetHeight(10);f.progress.label:Hide()
 f.next=S.Section(f.right,'Next action');f.next:SetPoint('TOPLEFT',12,-140);f.next:SetPoint('TOPRIGHT',-12,-140);f.next:SetHeight(94);f.next.text:SetHeight(44)
 for _,edge in ipairs(f.next.edges) do edge:SetColorTexture(.78,.56,.16,1) end
 f.body=W.Scroll(f.right);f.body:SetPoint('TOPLEFT',12,-246);f.body:SetPoint('BOTTOMRIGHT',-28,132)
 f.stepsSection=S.Section(f.body.content,'Acquisition steps');f.stepsSection.text:Hide()
 f.steps=W.List(f.stepsSection,70);f.steps:SetPoint('TOPLEFT',8,-38);f.steps:SetPoint('BOTTOMRIGHT',-24,10)
 f.info=S.Section(f.body.content,'Source & related objectives')
 f.custom=W.Edit(f.right);f.custom:SetPoint('BOTTOMLEFT',12,96);f.custom:SetPoint('BOTTOMRIGHT',-110,96)
 f.add=W.Button(f.right,'Add step',function() if U.selected and A.Services.Objectives.AddManual(U.selected,f.custom:GetText()) then f.custom:SetText('') end end);f.add:SetWidth(88);f.add:SetPoint('BOTTOMRIGHT',-12,96)
 f.actions={};local actions={
  {'Pin as main',function(o) A.Services.Persistence.Profile().focusObjective=o.objectiveId end},
  {'Priority',function(o) local p=A.Services.Persistence.Profile();p.priorities[o.itemId]=(p.priorities[o.itemId] or o.priority or 2)%3+1 end},
  {'View item',function(o) A.UI.SetTab('Item Details',{slot=o.slot,itemId=o.itemId}) end},
  {'View source',function(o)
   if o.requirementsVersion then local p=A.Services.AcquisitionRequirementsResolver.Plan(o.itemId,o.acquisitionMethod);if p then A.UI.CopyReference(A.Data.foundation.provenance[p.method.provenance[1]].sourceURL);return end end
   if o.sourceType=='Crafting' then local recipe=A.Services.Acquisition.Recipe(o.itemId);if recipe then A.UI.SetTab('Professions',{recipeKey=recipe.key,objectiveId=o.objectiveId});return end end
   A.UI.SetTab(o.sourceType=='Dungeon' and 'Dungeons' or o.sourceType=='Reputation' and 'Reputations' or o.sourceType=='Crafting' and 'Crafting Planner' or 'Activity Planner',{objectiveId=o.objectiveId,sourceId=o.sourceId})
  end},
  {'Mark obtained',function(o) local p=A.Services.Persistence.Profile();p.obtained[o.itemId]=not p.obtained[o.itemId] end},
  {'Stop tracking',function(o) A.Services.Objectives.Untrack(o) end},
 }
 for i,entry in ipairs(actions) do local fn=entry[2];f.actions[i]=W.Button(f.right,entry[1],function() if U.selected then fn(U.selected);A:Refresh() end end) end
 function f:LayoutBody()
  local w=math.max(240,self.body:GetWidth());local two=w>=610;local left=two and w*.56 or w
  self.stepsSection:ClearAllPoints();self.stepsSection:SetPoint('TOPLEFT');self.stepsSection:SetSize(left,300)
  self.info:ClearAllPoints();self.info:SetPoint('TOPLEFT',two and left+12 or 0,two and 0 or -312);self.info:SetSize(two and w-left-12 or w,math.max(170,self.info.text:GetStringHeight()+50))
  self.body.content:SetHeight(two and math.max(300,self.info:GetHeight()) or 312+self.info:GetHeight());self.body:UpdateRange()
 end
 f.body.reflow=function() f:LayoutBody() end
 f:SetScript('OnSizeChanged',function(self,width)
  self.left:SetWidth(math.max(206,math.min(300,width*.30)));local bw=math.max(1,(self.right:GetWidth()-36)/3)
  for i,b in ipairs(self.actions) do b:ClearAllPoints();b:SetPoint('BOTTOMLEFT',12+((i-1)%3)*(bw+6),14+math.floor((i-1)/3)*34);b:SetWidth(bw) end
  self:LayoutBody()
 end);return f
end
function U.Render()
 local f=U.frame;local all=A.Services.Objectives.List();local rows={};local context=A.Services.Navigation.context
 for _,o in ipairs(all) do if (U.filter=='All' or o.completionState==U.filter) and (U.search=='' or o.title:lower():find(U.search:lower(),1,true)) then rows[#rows+1]=o end end
 f.filter:SetText(U.filter=='All' and 'All objectives' or U.filter);f.empty:SetShown(#rows==0)
 local selected
 for _,o in ipairs(rows) do if o.objectiveId==(context.objectiveId or (U.selected and U.selected.objectiveId)) then selected=o end end
 U.selected=selected or rows[1];selected=U.selected
 local methods=selected and A.Services.AcquisitionRequirementsResolver.Methods(selected.itemId) or {};f.methods:SetShown(#methods>1);f.methods:SetText(selected and selected.acquisitionMethod or 'Acquisition method')
 f.search:ClearAllPoints();f.search:SetPoint('TOPLEFT',#methods>1 and f.methods or f.filter,'TOPRIGHT',10,0);f.search:SetPoint('TOPRIGHT',f.toolbar,'TOPRIGHT');f.search:SetHeight(26)
 f.list:Render(rows,function(row,o)
  A.UI.DesignSystem.ItemCard(row,A.Data.items[o.itemId],o.progress.completed..' / '..o.progress.total..' steps\n'..o.completionState)
  if not row.progress then row.progress=A.UI.DesignSystem.ProgressBar(row);row.progress:SetPoint('BOTTOMLEFT',54,5);row.progress:SetPoint('BOTTOMRIGHT',-8,5);row.progress:SetHeight(4);row.progress.label:Hide() end
  row.progress:SetProgress(o.progress.completed,o.progress.total);row.sub:ClearAllPoints();row.sub:SetPoint('BOTTOMLEFT',54,15);row.sub:SetPoint('BOTTOMRIGHT',-8,15)
  A.UI.Widgets.Active(row,selected==o);row:SetScript('OnClick',function() U.selected=o;A.Services.Navigation.context={objectiveId=o.objectiveId};U.Render() end)
 end)
 for _,b in ipairs(f.actions) do b:SetEnabled(selected~=nil) end;f.add:SetEnabled(selected~=nil)
 if not selected then
  f.title:SetText('No tracked objectives');f.badge:Hide();f.icon:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark');f.state:SetText('Choose an item to track.');f.next.text:SetText('Explore Equipment or Item Explorer to choose your next upgrade.');f.info.text:SetText('No objective selected.');f.progress:SetProgress(nil,nil);f.steps:Render({},function() end);f:LayoutBody();return
 end
 f.title:SetText(selected.title);f.badge:Show();f.badge:SetText(selected.completionState);f.icon:SetTexture(selected.icon or 'Interface\\Icons\\INV_Misc_QuestionMark')
 local step=A.Services.Objectives.Next(selected);local item=A.Data.items[selected.itemId];local related={}
 for _,other in ipairs(all) do if other~=selected and other.sourceId==selected.sourceId and other.sourceType==selected.sourceType then related[#related+1]=other.title end end
 f.state:SetText((A.Data.slotByKey[selected.slot] and A.Data.slotByKey[selected.slot].label or selected.slot)..' · '..selected.mode..'\n'..selected.progress.completed..' / '..selected.progress.total..' steps')
 f.next.text:SetText(step and step.title or selected.completionState=='Obtained' and 'Objective obtained. Choose your next upgrade.' or 'No remaining acquisition steps recorded.')
 f.info.text:SetText(selected.sourceType..'\n'..(item and item.source or 'Source unavailable')..(#related>0 and ('\n\nOther tracked objectives\n'..table.concat(related,'\n')) or ''))
 if selected.requirementsVersion then f.info.text:SetText(A.Services.AcquisitionRequirementsResolver.Summary(selected.itemId,selected.acquisitionMethod)) end
 f.progress:SetProgress(selected.progress.completed,selected.progress.total)
 f.steps:Render(selected.steps,function(row,s)
  row.title:SetText((s.completed and '[x] ' or s.blocked and '[blocked] ' or '[ ] ')..s.title)
  local amount=type(s.currentAmount)=='number' and type(s.requiredAmount)=='number' and ('  '..s.currentAmount..'/'..s.requiredAmount) or ''
  row.sub:SetText((s.completionMode=='manual' and 'Click to update' or s.completionMode=='requirements' and (s.requirementStatus or 'Unknown') or 'Checked when available')..amount..(s.progressLabel and ('\n'..s.progressLabel) or ''))
  row:SetScript('OnClick',function() A.Services.Objectives.ToggleStep(selected,s) end)
 end)
 f.actions[1]:SetText(A.Services.Persistence.Profile().focusObjective==selected.objectiveId and 'Pinned' or 'Pin as main');f.actions[2]:SetText('Priority '..(A.Services.Persistence.Profile().priorities[selected.itemId] or selected.priority or 2));f:LayoutBody()
end
