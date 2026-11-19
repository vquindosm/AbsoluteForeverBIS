-- Structural acceptance checks. Geometry uses fixture APIs, never a real game render.
local M=dofile('tests/wow_mock.lua');local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,msg) end
local function bounds(f) local x,w=f:Bounds(true);local y,h=f:Bounds(false);return x,y,w,h end
local function inside(child,parent)
 local x,y,w,h=bounds(child);local px,py,pw,ph=bounds(parent)
 return w>0 and h>0 and x>=px-.1 and y>=py-.1 and x+w<=px+pw+.1 and y+h<=py+ph+.1
end
local function apart(a,b)
 local x,y,w,h=bounds(a);local bx,by,bw,bh=bounds(b)
 return x+w<=bx+.1 or bx+bw<=x+.1 or y+h<=by+.1 or by+bh<=y+.1
end
ForeverWarlockCompanionDB={viewClass='WARLOCK',spec='Affliction',mode='Pre-BiS',window={width=1700,height=1040}}
for line in io.lines('ForeverWarlockCompanion.toc') do if line:match('%.lua$') then dofile((line:gsub('\\','/'))) end end
M.Event('ADDON_LOADED','ForeverWarlockCompanion');SlashCmdList.FWC('');local A=FWC
local O=A.Services.Objectives
O.Track(14111,'Head');O.Track(18691,'Neck');O.Track(14153,'Chest')
for _,size in ipairs({{880,640},{1180,780},{1700,1040}}) do
 A.UI.window:SetSize(unpack(size));M.Layout();A.db.settings.showFilters=true;A.UI.Layout();M.Layout();check(apart(A.UI.window.filterBar,A.UI.window.sidebar),'filters do not cover sidebar');A.db.settings.showFilters=false;A.UI.Layout();A.UI.SetTab('Dashboard');M.Layout()
 local d=A.UI.Dashboard.frame
 check(#d.list.data==3,'three actual incomplete objectives')
 for i,row in ipairs(d.list.rows) do check(inside(row,d.goals),'objective card stays in its panel');if i>1 then check(apart(row,d.list.rows[i-1]),'objective cards do not overlap') end end
 for i,row in ipairs(d.activityCards) do check(inside(row,d.activities),'activity remains within panel');if i>1 then check(apart(row,d.activityCards[i-1]),'activities do not overlap') end end
 check(apart(d.stats,d.goals) and apart(d.stats,d.activities),'stats rail does not cover objectives or activities')
 if size[1]==1700 then local y=d.list.rows[1]:Bounds(false);local y2=d.list.rows[2]:Bounds(false);check(y==y2,'wide dashboard objectives are horizontal') end
 A.UI.SetTab('Character & Gear',{slot='Head',itemId=14111});M.Layout();local g=A.UI.CharacterPanel.frame
 check(not g.left:IsShown() and g.model:GetWidth()>g:GetWidth()*.49,'model is the main equipment column')
 for _,b in ipairs(A.UI.ModelViewer.equipment) do check(inside(b,g.model),'equipment slot stays inside model panel');check(b:GetWidth()>=23,'slots remain clickable') end
 local left=A.UI.ModelViewer.equipment[1];local right=A.UI.ModelViewer.equipment[7]
 check(apart(left,right),'equipment slots flank model')
 g.details.icon:Click();M.Layout();check(A.UI.tab=='Item Details' and A.UI.ItemDetails.page.item.id==14111,'equipment icon opens full item detail')
 local detail=A.UI.ItemDetails.page
 for _,panel in ipairs({detail.stats,detail.source,detail.comparison,detail.stepsSection,detail.alternativesSection}) do check(inside(panel,detail.scroll.content),'detail block is within scroll content') end
 check(apart(detail.stats,detail.source) and apart(detail.comparison,detail.stepsSection),'detail blocks grouped without overlap')
 check(not detail.advanced:IsShown(),'technical notes hidden by default')
 A.Services.Navigation.Back();M.Layout();check(A.UI.tab=='Character & Gear','item detail Back retains equipment')
 A.UI.SetTab('Progression');M.Layout();local o=A.UI.ObjectivesPanel.frame
 check(inside(o.next,o.right) and apart(o.next,o.body),'next action is separate from checklist')
 check(o.next.text:GetText()==O.Next(A.UI.ObjectivesPanel.selected).title,'next action comes from persistent objective')
 check(o.body:GetHeight()>0,'objective checklist remains accessible at minimum size')
end
A.UI.window:SetSize(1700,1040);M.Layout();local f=A.UI.window
local group=f.navEntries[2];group:Click();check(not f.tabs[2]:IsShown(),'collapsing group hides its children');group:Click();check(f.tabs[2]:IsShown(),'group reopens')
A.UI.SetTab('Progression');local p=A.UI.ObjectivesPanel
p.frame.search:SetText('no matching fixture');M.Layout();check(#p.frame.list.data==0 and p.frame.empty:IsShown(),'objective search has empty state')
p.frame.search:SetText('');p.frame.filter.pick('Obtained');M.Layout();check(#p.frame.list.data==0,'state filter respects real objective states');p.frame.filter.pick('All')
local selected=p.selected;local old=selected.steps[1].manualCompleted;p.frame.steps.rows[1]:Click();check(selected.steps[1].manualCompleted~=old,'checklist still changes stored progress')
p.frame.actions[3]:Click();M.Layout();check(A.UI.tab=='Item Details','view item opens full detail route')
A.UI.ItemDetails.page.buttons[1]:Click();M.Layout();check(A.UI.tab=='Character & Gear' and A.UI.ModelViewer.mode=='Planned','target selection still activates planned preview')
local before=M.setUnits or 0;A:Refresh();A:Refresh();check((M.setUnits or 0)==before,'ordinary rerenders do not reload character')
A.UI.ModelViewer.currentButton:Click();check(A.UI.ModelViewer.mode=='Current','current mode restores appearance')
A.UI.Tracker.Render();M.Layout();check(A.UI.Tracker.frame.next.text:GetText()~='','tracker features persistent next action')
check(#A.diagnostics==0,'no compatibility errors')
M.print('PASS visual layout: '..checks..' checks (simulated APIs only)')
