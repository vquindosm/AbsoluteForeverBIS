local A=FWC
local D={};A.UI.ItemDetails=D
function D.Create(parent)
 local W,S=A.UI.Widgets,A.UI.DesignSystem;local f=S.Card(parent)
 f.icon=CreateFrame('Button',nil,f);f.icon:SetSize(48,48);f.icon:SetPoint('TOPLEFT',14,-14)
 f.texture=f.icon:CreateTexture(nil,'ARTWORK');f.texture:SetAllPoints(f.icon)
 f.name=W.Label(f,'Select a slot','GameFontNormalLarge');f.name:SetPoint('TOPLEFT',74,-14);f.name:SetPoint('TOPRIGHT',-14,-14);f.name:SetHeight(42)
 f.status=W.Label(f,'');f.status:SetPoint('TOPLEFT',74,-59);f.status:SetPoint('TOPRIGHT',-12,-59);f.status:SetHeight(32)
 f.scroll=W.Scroll(f);f.scroll:SetPoint('TOPLEFT',10,-102);f.scroll:SetPoint('BOTTOMRIGHT',-26,86)
 local body=f.scroll.content
 f.stats=S.Section(body,'Candidate statistics');f.comparison=S.Section(body,'Comparison with equipped');f.source=S.Section(body,'How to get it');f.stepsSection=S.Section(body,'Steps to follow');f.stepsSection.text:Hide()
 f.steps=W.List(f.stepsSection,58);f.steps:SetPoint('TOPLEFT',10,-38);f.steps:SetPoint('BOTTOMRIGHT',-24,10)
 f.alternativesSection=S.Section(body,'Alternatives');f.alternativesSection.text:Hide()
 f.alternatives=W.Menu(f.alternativesSection,'Choose alternative',function()
  local result={};for _,id in ipairs(A.Services.Catalog.List(A.db.viewClass,A.db.spec,A.db.mode,f.slot or 'Head')) do result[#result+1]={label=A.Data.items[id].name,value=id} end
  if #result==0 then result[1]={label='No imported alternatives',value=0} end;return result
 end,function(id) A.UI.selectedItem=id~=0 and id or nil;A:Refresh() end)
 f.alternatives:SetPoint('TOPLEFT',12,-38);f.alternatives:SetPoint('TOPRIGHT',-12,-38)
 f.advanced=S.Section(body,'Advanced information')
 f.equipped=W.Button(f.comparison,'Compare full stats',function() A.UI.selectedSlot=f.slot;A.UI.StatsPanel.candidate=f.item and f.item.id;A.UI.SetTab('Stats') end)
 f.equipped:SetPoint('BOTTOMLEFT',12,12);f.equipped:SetPoint('BOTTOMRIGHT',-12,12)
 f.buttons={}
 local definitions={
  {'Set as Target',function() if f.item and A.Services.Catalog.Select(f.slot,f.item.id) then A.UI.selectedSlot=f.slot;A.UI.selectedItem=nil;A.UI.ModelViewer.mode='Planned';A.UI.SetTab('Character & Gear') end end},
  {'Mark as Obtained',function() if f.item then local p=A.Services.Persistence.Profile();p.obtained[f.item.id]=not p.obtained[f.item.id];A:Refresh() end end},
  {'Track Objective',function() if f.item then local o=A.Services.Objectives.Find(f.item.id,f.slot);if o and o.trackingState=='Tracked' then A.Services.Objectives.Untrack(o) else A.Services.Objectives.Track(f.item.id,f.slot) end end end},
  {'Preview on Character',function() if f.item then A.UI.selectedSlot=f.slot;A.UI.previewItem=f.item;A.UI.SetTab('Character & Gear');A.UI.ModelViewer.Preview(f.item,f.slot) end end},
  {'Reset Selection',function() local p=A.Services.Persistence.Profile();p.targets[A.db.mode][f.slot]=nil;p.unresolved[f.slot]=nil;A.UI.selectedItem=nil;A:Refresh() end},
  {'Reference link',function() if f.item then A.UI.CopyReference(f.item.reference) end end},
 }
 for i,def in ipairs(definitions) do f.buttons[i]=W.Button(f,def[1],def[2]) end
 f.more=W.Button(f,'More options +',function() f.expanded=not f.expanded;D.Render(f,f.slot,f.item) end)
 f.acquisition=W.Button(f.stepsSection,'Open objective',function() if f.item then local o=A.Services.Objectives.Track(f.item.id,f.slot);A.UI.SetTab('Progression',{objectiveId=o.objectiveId}) end end);f.acquisition:Hide()
 f.priority=W.Menu(f,'Priority',{{label='High priority',value=1},{label='Normal priority',value=2},{label='Low priority',value=3}},function(v) if f.item then A.Services.Persistence.Profile().priorities[f.item.id]=v;A:Refresh() end end)
 f.reputation=W.Menu(f,'Choose faction',function()
  local choices={{label='Automatic / unassigned',value=0}};local api=C_Reputation;local count=api and A.Compat.Call(api.GetNumFactions) or 0
  if not A.Compat.Readable(count) or type(count)~='number' then count=0 end
  for i=1,count do local d=A.Compat.Call(api.GetFactionDataByIndex,i);if type(d)=='table' and A.Compat.Readable(d.name) and A.Compat.Readable(d.factionID) and type(d.name)=='string' and type(d.factionID)=='number' and (not d.isHeader or d.isHeaderWithRep) then choices[#choices+1]={label=d.name,value=d.factionID} end end;return choices
 end,function(id) if f.item then local p=A.Services.Persistence.Profile();p.factions=p.factions or {};p.factions[f.item.id]=id~=0 and id or nil;A:Refresh() end end)
 function f:LayoutBody()
  local width=math.max(180,self.scroll:GetWidth());local two=width>=560;local half=(width-12)/2;local y=0
  local function place(panel,x,top,w,h) panel:ClearAllPoints();panel:SetPoint('TOPLEFT',body,'TOPLEFT',x,-top);panel:SetSize(w,h) end
  local statsH=math.max(142,self.stats.text:GetStringHeight()+50);local sourceH=math.max(142,self.source.text:GetStringHeight()+50);local topH=math.max(statsH,sourceH)
  place(self.stats,0,0,two and half or width,topH)
  place(self.source,two and half+12 or 0,two and 0 or topH+12,two and half or width,sourceH)
  y=two and topH+12 or topH+sourceH+24
  local compareH=math.max(185,self.comparison.text:GetStringHeight()+85)
  place(self.comparison,0,y,two and half or width,compareH)
  place(self.stepsSection,two and half+12 or 0,two and y or y+compareH+12,two and half or width,244)
  y=y+(two and math.max(compareH,244)+12 or compareH+268)
  place(self.alternativesSection,0,y,width,80);y=y+92
  self.advanced:SetShown(self.expanded==true)
  if self.expanded then local h=math.max(160,self.advanced.text:GetStringHeight()+52);place(self.advanced,0,y,width,h);y=y+h+12 end
  body:SetHeight(y);self.scroll:UpdateRange()
 end
 function f:LayoutActions()
  if self.standalone then
   local bw=math.max(1,(self:GetWidth()-54)/4)
   local order={1,3,2};for i,index in ipairs(order) do local b=self.buttons[index];b:ClearAllPoints();b:SetPoint('BOTTOMLEFT',12+(i-1)*(bw+10),16);b:SetWidth(bw);b:Show() end
   self.more:ClearAllPoints();self.more:SetPoint('BOTTOMLEFT',12+3*(bw+10),16);self.more:SetWidth(bw);self.more:SetText(self.expanded and 'Less −' or 'More options +')
   for i=4,6 do local b=self.buttons[i];b:ClearAllPoints();b:SetPoint('BOTTOMLEFT',12+(i-4)*(bw+10),50);b:SetWidth(bw);b:SetShown(self.expanded==true) end
   self.priority:ClearAllPoints();self.priority:SetPoint('BOTTOMLEFT',12+3*(bw+10),50);self.priority:SetWidth(bw);self.priority:SetShown(self.expanded==true)
   self.reputation:ClearAllPoints();self.reputation:SetPoint('BOTTOMLEFT',12,84);self.reputation:SetWidth(bw);self.reputation:SetShown(self.expanded and self.item and self.item.sourceType=='Reputation' or false)
   self.scroll:ClearAllPoints();self.scroll:SetPoint('TOPLEFT',10,-102);self.scroll:SetPoint('BOTTOMRIGHT',-26,self.expanded and 124 or 58);self:LayoutBody();return
  end
  local bw=math.max(1,(self:GetWidth()-36)/2)
  for i,b in ipairs(self.buttons) do
   local col,row
   if i==1 then col=0;row=0 elseif i==3 then col=1;row=0 elseif i==2 then col=0;row=1 else col=(i-4)%2;row=2+math.floor((i-4)/2) end
   b:ClearAllPoints();b:SetPoint('BOTTOMLEFT',12+col*(bw+12),(self.expanded and 144 or 48)-row*32);b:SetWidth(bw);b:SetShown(i<=3 or self.expanded==true)
  end
  self.more:ClearAllPoints();self.more:SetPoint('BOTTOMLEFT',24+bw,self.expanded and 112 or 16);self.more:SetWidth(bw);self.more:SetText(self.expanded and 'Less −' or 'More options +')
  self.priority:ClearAllPoints();self.priority:SetPoint('BOTTOMLEFT',12,16);self.priority:SetWidth(bw);self.priority:SetShown(self.expanded==true)
  self.reputation:ClearAllPoints();self.reputation:SetPoint('BOTTOMLEFT',24+bw,16);self.reputation:SetWidth(bw);self.reputation:SetShown(self.expanded and self.item and self.item.sourceType=='Reputation' or false)
  self.scroll:ClearAllPoints();self.scroll:SetPoint('TOPLEFT',10,-102);self.scroll:SetPoint('BOTTOMRIGHT',-26,self.expanded and 182 or 86);self:LayoutBody()
 end
 f.scroll.reflow=function() f:LayoutBody() end;f:SetScript('OnSizeChanged',function() f:LayoutActions() end)
 f.icon:SetScript('OnClick',function() if f.item and not f.standalone then A.UI.SetTab('Item Details',{slot=f.slot,itemId=f.item.id}) end end)
 W.Tooltip(f.icon,function() return f.item and f.item.id end)
 W.Tooltip(f.equipped,function() local eq=A.Services.Inventory.snapshot.equipped[f.slot];return eq and (eq.link or eq.id) end)
 A.UI.Widgets.Active(f.buttons[1],true)
 return f
end
function D.Render(f,slot,item)
 local W=A.UI.Widgets;f.slot=slot or 'Head';f.item=item
 for _,b in ipairs(f.buttons) do b:SetEnabled(item~=nil) end;f.equipped:SetEnabled(A.Data.slotByKey[f.slot]~=nil);f.priority:SetEnabled(item~=nil)
 if not item then
  f.name:SetText('No target selected');f.texture:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark');f.status:SetText(A.db.mode..' · No imported candidate')
  f.stats.text:SetText('Choose an item to inspect its statistics.');f.source.text:SetText('Source unavailable.');f.comparison.text:SetText('Select a target from Item Explorer or Alternatives.');f.steps:Render({},function() end)
  local legacy=A.Services.Persistence.Profile().unresolved[f.slot]
  f.advanced.text:SetText(legacy and ('Legacy selection preserved: '..legacy) or 'No reviewed catalog for this specialization / slot. Selections remain separate by specialization and mode.')
  f.alternatives:SetText('Choose alternative');f:LayoutActions();return
 end
 local live=A.Compat.ItemInfo(item.id);local p=A.Services.Persistence.Profile();local eq=A.Services.Inventory.snapshot.equipped[slot];local equipped=eq and eq.id and A.Compat.ItemInfo(eq.link or eq.id)
 local objective=A.Services.Objectives.Find(item.id,slot);local status=A.Services.Inventory.Status(item)
 f.name:SetText(W.Color(item)..(live.name or item.name)..'|r');f.texture:SetTexture(live.icon or item.icon)
 f.status:SetText((A.Data.slotByKey[slot] and A.Data.slotByKey[slot].label or slot)..' · '..A.db.mode..'\n'..status..(p.obtained[item.id] and ' · Marked obtained' or ''))
 f.buttons[2]:SetText(p.obtained[item.id] and 'Unmark Obtained' or 'Mark as Obtained');f.buttons[3]:SetText(objective and objective.trackingState=='Tracked' and 'Untrack Objective' or 'Track Objective')
 f.priority:SetText('Priority: '..({'High','Normal','Low'})[p.priorities[item.id] or 2]);f.alternatives:SetText(item.name..'  v')
 local stats=A.Services.ItemStats;local before=stats.Equipped(slot);local after=stats.Candidate(item)
 f.stats.text:SetText(stats.Lines(after))
 local delta={};for _,entry in ipairs(stats.Keys(before,after)) do local v=stats.Delta(before,after,entry.key);if v and v~=0 then delta[#delta+1]=(v>0 and '|cff77df66' or '|cffff8877')..string.format('%+g ',v)..entry.label..'|r' end end
 local score=A.Services.Planner.SlotScore(slot,item)
 local compare={'Current: '..(equipped and equipped.name or 'Unknown / empty'),stats.Lines(before),'',#delta>0 and table.concat(delta,'\n') or 'Attribute differences unavailable.'}
 compare[#compare+1]=score and string.format('Estimated item EP: %+.1f%%',score.delta) or 'Rating unavailable · inspect Stats / data status.'
 f.comparison.text:SetText(table.concat(compare,'\n'))
 f.source.text:SetText((item.sourceType or 'Unknown')..'\n'..(item.source or 'Source unavailable')..(item.zone and ('\nZone: '..item.zone) or ''))
 if A.Services.AcquisitionRequirementsResolver.Has(item.id) then f.source.text:SetText(A.Services.AcquisitionRequirementsResolver.Summary(item.id,objective and objective.acquisitionMethod)) end
 local steps=objective and objective.steps or A.Services.Acquisition.Resolve(item)
 f.steps:Render(steps or {},function(row,step,index)
  row.title:SetText((step.completed and '[x] ' or '[ ] ')..step.title);row.title:SetHeight(32)
  row.sub:SetText(step.blocked and 'Prerequisite pending' or step.completionMode=='manual' and 'Click to update step' or 'Checked from game data');row.sub:SetHeight(14)
  row:SetScript('OnClick',function() local o=A.Services.Objectives.Track(item.id,slot);local actual=o.steps[index];if actual then A.Services.Objectives.ToggleStep(o,actual) end end)
 end)
 local advanced={'Item #'..item.id..' · Imported / unranked',A.Services.Planner.Comparison(slot,item),stats.Guide(item),'Equipped full link: '..tostring(before.link or 'Unknown'),'Candidate full link: '..tostring(after.link or 'Data pending'),after.fallbackSource and ('Offline data source: '..after.fallbackSource) or ''}
 if item.sourceType=='Crafted' then local recipe=A.Services.Acquisition.Recipe(item.id);local materials=recipe and A.Services.Professions.Materials(recipe);if materials then for _,m in ipairs(materials) do advanced[#advanced+1]=m.name..': '..(m.checked and tostring(m.available) or '?')..'/'..m.qty end else advanced[#advanced+1]='Recipe quantities pending verification.' end end
 f.advanced.text:SetText(table.concat(advanced,'\n\n'));f:LayoutActions()
end

function D.CreatePage(parent)
 local f=D.Create(parent);f:SetAllPoints(parent);f.standalone=true;D.page=f;return f
end
function D.RenderPage()
 local slot=A.UI.selectedSlot or 'Head';local item=A.UI.selectedItem and A.Data.items[A.UI.selectedItem] or A.Services.Catalog.Target(slot)
 D.Render(D.page,slot,item)
end
