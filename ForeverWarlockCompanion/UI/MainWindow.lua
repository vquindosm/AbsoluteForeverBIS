local A=FWC
local U=A.UI
U.selectedSlot='Head';U.tab='Dashboard'
local groups={
 {title='Character',icon='INV_Helmet_03',children={{'Equipment','Character & Gear'},{'Stats','Stats'},{'Talents','Talents'}}},
 {title='Gear & Content',icon='INV_Sword_04',children={{'Item Explorer','Item Explorer'},{'Dungeons','Dungeons'},{'Reputations','Reputations'}}},
 {title='Professions',icon='Trade_BlackSmithing',children={{'Recipes','Professions'},{'Crafting Planner','Crafting Planner'},{'Cooldowns','Cooldowns'}}},
 {title='Progression',icon='INV_Misc_Note_01',children={{'My Objectives','Progression'},{'Activity Planner','Activity Planner'},{'Daily / Weekly','Daily / Weekly'}}},
}
function U.ViewChanged()
 U.selectedItem=nil;U.ModelViewer.mode='Current';A.Services.Navigation.context={}
 A.Services.Objectives.Migrate();A:Refresh()
end
function U.SetTab(name,context) A.Services.Navigation.Go(name,context) end
function U.Create()
 if U.window then return end
 local W=U.Widgets;U.DesignSystem.Apply(A.db.settings.theme or 'Modern Azeroth')
 local f=W.Panel(UIParent,'ForeverWarlockCompanionFrame');U.window=f
 f:SetFrameStrata('DIALOG');f:SetMovable(true);f:SetResizable(true);f:SetClampedToScreen(true);f:EnableMouse(true)
 if type(UISpecialFrames)=='table' then table.insert(UISpecialFrames,'ForeverWarlockCompanionFrame') end
 local width=math.max(880,math.min(1700,tonumber(A.db.window.width) or 1180));local height=math.max(640,math.min(1200,tonumber(A.db.window.height) or 780))
 local anchors={CENTER=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true}
 f:SetSize(width,height);f:SetPoint(anchors[A.db.window.point] and A.db.window.point or 'CENTER',UIParent,anchors[A.db.window.relativePoint] and A.db.window.relativePoint or 'CENTER',tonumber(A.db.window.x) or 0,tonumber(A.db.window.y) or 0)
 local sw,sh=UIParent:GetWidth(),UIParent:GetHeight();f:SetScale(math.min(1,(sw-20)/width,(sh-20)/height))
 A.Compat.Method(f,'SetResizeBounds',880,640,math.max(880,math.min(1700,(sw-20)/f:GetScale())),math.max(640,math.min(1200,(sh-20)/f:GetScale())))
 f.title=W.Label(f,'FOREVER\nCOMPANION','GameFontNormal');f.title:SetPoint('TOPLEFT',56,-20);f.title:SetWidth(130);f.title:SetHeight(44)
 f.logo=f:CreateTexture(nil,'ARTWORK');f.logo:SetSize(34,34);f.logo:SetPoint('TOPLEFT',16,-20);f.logo:SetTexture('Interface\\Icons\\INV_Misc_Rune_01')
 f.pageTitle=W.Label(f,'Dashboard','GameFontNormalLarge');f.pageTitle:SetHeight(28)
 f.character=W.Label(f,'');f.character:SetHeight(20)
 local drag=CreateFrame('Frame',nil,f);drag:SetPoint('TOPLEFT');drag:SetPoint('TOPRIGHT',-40,0);drag:SetHeight(34);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
 drag:SetScript('OnDragStart',function() f:StartMoving() end)
 drag:SetScript('OnDragStop',function() f:StopMovingOrSizing();local point,relative,relativePoint,x,y=f:GetPoint();if not relative or relative==UIParent then A.db.window.point=point;A.db.window.relativePoint=relativePoint;A.db.window.x=x;A.db.window.y=y end end)
 local close=W.Button(f,'X',function() f:Hide() end);close:SetSize(26,24);close:SetPoint('TOPRIGHT',-10,-10)
 f.back=W.Button(f,'< Back',function() A.Services.Navigation.Back() end);f.back:SetSize(76,24);f.back:SetPoint('TOPLEFT',16,-68)
 f.breadcrumb=W.Label(f,'');f.breadcrumb:SetPoint('TOPLEFT',104,-73);f.breadcrumb:SetPoint('TOPRIGHT',-20,-73);f.breadcrumb:SetHeight(18)
 local filters=W.Button(f,'Filters',function() A.db.settings.showFilters=not A.db.settings.showFilters;U.Layout();U.Render() end);filters:SetSize(76,24);filters:SetPoint('TOPRIGHT',-16,-38)
 local refresh=W.Button(f,'Refresh',function() A.Services.Inventory.Scan();A.Services.Character.Read();A:Refresh() end);refresh:SetSize(76,24);refresh:SetPoint('RIGHT',filters,'LEFT',-8,0);f.refresh=refresh;f.filterToggle=filters
 f.mode=W.Menu(f,'Pre-BiS',{'Pre-BiS','BiS'},function(v) A.db.mode=v;U.ViewChanged() end);f.mode:SetSize(95,26);f.mode:SetPoint('RIGHT',refresh,'LEFT',-10,0)
 f.filterBar=CreateFrame('Frame',nil,f);f.filterBar:SetPoint('TOPLEFT',16,-103);f.filterBar:SetPoint('TOPRIGHT',-16,-103);f.filterBar:SetHeight(28)
 f.filters={}
 f.filters[1]=W.Menu(f.filterBar,'Class',A.Data.classOrder,function(v) A.Services.Persistence.SetView(v);U.ViewChanged() end)
 f.filters[2]=W.Menu(f.filterBar,'Spec',function() return A.Data.classes[A.db.viewClass] end,function(v) A.Services.Persistence.SetView(A.db.viewClass,v);U.ViewChanged() end)
 f.filters[3]=W.Menu(f.filterBar,'Mode',{'Pre-BiS','BiS'},function(v) A.db.mode=v;U.ViewChanged() end)
 for i=1,2 do local index=i;f.filters[i+3]=W.Menu(f.filterBar,'Profession',A.Data.professionChoices,function(v) A.db.professions[index]=v;A.db.manualProfessions=true;U.ViewChanged() end) end
 f.sidebar=U.DesignSystem.Card(f)
 f.title:Hide();f.logo:Hide()
 f.title=W.Label(f.sidebar,'FOREVER\nCOMPANION','GameFontNormal');f.title:SetHeight(44)
 f.logo=f.sidebar:CreateTexture(nil,'ARTWORK');f.logo:SetSize(32,32);f.logo:SetPoint('TOPLEFT',8,-16);f.logo:SetTexture('Interface\\Icons\\INV_Misc_Rune_01')
 f.version=W.Label(f.sidebar,A.version);f.version:SetPoint('TOPLEFT',48,-60);f.version:SetWidth(130)
 f.nav=W.Scroll(f.sidebar);f.nav:SetPoint('TOPLEFT',7,-84);f.nav:SetPoint('BOTTOMRIGHT',-20,8);f.tabs={};f.navEntries={}
 local function nav(label,route,icon,group)
  local b=W.Button(f.nav.content,label,function() U.SetTab(route) end);b.route=route;b.group=group
  b.label:SetJustifyH('LEFT');b.label:ClearAllPoints();b.label:SetPoint('LEFT',icon and 30 or 26,0);b.label:SetPoint('RIGHT',-4,0)
  if icon then b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(19,19);b.icon:SetPoint('LEFT',5,0);b.icon:SetTexture('Interface\\Icons\\'..icon) end
  f.tabs[#f.tabs+1]=b;f.navEntries[#f.navEntries+1]=b;return b
 end
 nav('Dashboard','Dashboard','INV_Misc_Book_09')
 for _,group in ipairs(groups) do
  local header=W.Button(f.nav.content,group.title..'  −',function() group.collapsed=not group.collapsed;U.Layout() end)
  header.groupHeader=group;header.label:SetJustifyH('LEFT');header.label:ClearAllPoints();header.label:SetPoint('LEFT',8,0);header.label:SetPoint('RIGHT',-4,0)
  f.navEntries[#f.navEntries+1]=header
  for _,entry in ipairs(group.children) do nav(entry[1],entry[2],nil,group) end
 end
 nav('Settings','Settings','INV_Misc_Gear_01')
 function f:LayoutNavigation()
  local y=0
  for _,b in ipairs(self.navEntries) do
   local visible=not b.group or not b.group.collapsed;b:SetShown(visible)
   if visible then
    local height=b.groupHeader and 34 or b.group and 28 or 38
    if b.groupHeader then b:SetText(b.groupHeader.title..(b.groupHeader.collapsed and '  +' or '  −')) end
    b:ClearAllPoints();b:SetPoint('TOPLEFT',0,-y);b:SetPoint('RIGHT',self.nav.content,'RIGHT',0,0);b:SetHeight(height);y=y+height+3
   end
  end
  self.nav.content:SetHeight(y+8);self.nav:UpdateRange()
 end
 f.content=CreateFrame('Frame',nil,f)
 f.panels={
  ['Item Details']=U.ItemDetails.CreatePage(f.content),['Dashboard']=U.Dashboard.Create(f.content),['Character & Gear']=U.CharacterPanel.Create(f.content),['Item Explorer']=U.ItemSelector.Create(f.content),['Stats']=U.StatsPanel.Create(f.content),
  ['Talents']=U.Supporting.CreateTalents(f.content),['Professions']=U.Supporting.CreateProfessions(f.content),['Progression']=U.ObjectivesPanel.Create(f.content),
  ['Daily / Weekly']=U.Supporting.CreateActivities(f.content),['Settings']=U.Supporting.CreateSettings(f.content),
 }
 f.panels['Character Progress']=f.panels['Dashboard']
 for _,kind in ipairs({'Dungeons','Reputations','Crafting Planner','Activity Planner','Professions Overview','Cooldowns'}) do f.panels[kind]=U.ContentPanel.Create(f.content,kind) end
 f.footer=W.Label(f,'');f.footer:SetPoint('BOTTOMLEFT',16,12);f.footer:SetPoint('BOTTOMRIGHT',-30,12)
 local resize=W.Button(f,'/',nil);resize:SetSize(22,22);resize:SetPoint('BOTTOMRIGHT',-4,4)
 resize:SetScript('OnMouseDown',function() f:StartSizing('BOTTOMRIGHT') end)
 resize:SetScript('OnMouseUp',function() f:StopMovingOrSizing();A.db.window.width=f:GetWidth();A.db.window.height=f:GetHeight() end)
 f:SetScript('OnSizeChanged',function() U.Layout() end)
 f:SetScript('OnHide',function() if U.menu then U.menu:Hide() end;if U.copy then U.copy:Hide() end;U.ModelViewer.dragX=nil end)
 f:SetScript('OnShow',function() U.Render() end)
 U.Layout();f:Hide()
end
function U.Layout()
 local f=U.window;if not f or not f.content then return end
 local show=A.db.settings.showFilters;local top=show and -146 or -102
 f.filterBar:SetShown(show==true)
 local side=f:GetWidth()<1050 and 162 or 190
 f.filterBar:ClearAllPoints();f.filterBar:SetPoint('TOPLEFT',side+26,-110);f.filterBar:SetPoint('TOPRIGHT',-16,-110)
 local fw=math.max(1,(f:GetWidth()-side-74)/5);for i,b in ipairs(f.filters) do b:ClearAllPoints();b:SetPoint('TOPLEFT',(i-1)*(fw+8),0);b:SetWidth(fw) end
 f.version:SetWidth(side-56)
 f.sidebar:ClearAllPoints();f.sidebar:SetPoint('TOPLEFT',8,-8);f.sidebar:SetPoint('BOTTOMLEFT',8,36);f.sidebar:SetWidth(side)
 -- Keep the brand above the navigation; page controls belong to the content header.
 f.sidebar.background:SetTexture('Interface\\AddOns\\ForeverWarlockCompanion\\Media\\DarkStone')
 f.content:ClearAllPoints();f.content:SetPoint('TOPLEFT',f,'TOPLEFT',side+24,top);f.content:SetPoint('BOTTOMRIGHT',-14,36)
 f.title:ClearAllPoints();f.title:SetPoint('TOPLEFT',48,-16);f.title:SetWidth(side-54)
 f.pageTitle:ClearAllPoints();f.pageTitle:SetPoint('TOPLEFT',side+26,-14);f.pageTitle:SetPoint('TOPRIGHT',-320,-14)
 f.character:ClearAllPoints();f.character:SetPoint('TOPLEFT',side+26,-46);f.character:SetPoint('TOPRIGHT',-320,-46)
 f.back:ClearAllPoints();f.back:SetPoint('TOPLEFT',side+26,-72)
 f.breadcrumb:ClearAllPoints();f.breadcrumb:SetPoint('TOPLEFT',side+110,-77);f.breadcrumb:SetPoint('TOPRIGHT',-16,-77)
 f:LayoutNavigation()

end
function U.Render()
 if not U.window or not A.db then return end
 local f=U.window;if not f.panels[U.tab] then U.tab='Dashboard' end
 if (A.db.settings.theme or 'Modern Azeroth')=='Modern Azeroth' then f.background:SetColorTexture(.037,.047,.063,1) end
 local c=A.Services.Character.character
 f.pageTitle:SetText(U.tab=='Character & Gear' and 'Equipment' or U.tab=='Progression' and 'My Objectives' or U.tab);f.mode:SetText(A.db.mode)
 f.character:SetText(A.db.viewClass..' · '..A.db.spec..' · '..A.db.mode)
 local labels={A.db.viewClass,A.db.spec,A.db.mode,A.db.professions[1] or 'Any profession',A.db.professions[2] or 'Any profession'}
 for i,label in ipairs(labels) do f.filters[i]:SetText(label) end
 for _,b in ipairs(f.tabs) do U.Widgets.Active(b,b.route==U.tab or (U.tab=='Item Details' and b.route=='Item Explorer'));if b.route==U.tab or (U.tab=='Item Details' and b.route=='Item Explorer') then b.bg:SetColorTexture(.31,.22,.08,1) end end
 local active=f.panels[U.tab];local unique={};for _,panel in pairs(f.panels) do if not unique[panel] then panel:SetShown(panel==active);unique[panel]=true end end
 f.breadcrumb:SetText(A.Services.Navigation.Breadcrumb());f.back:SetEnabled(#A.Services.Navigation.history>0)
 local render={['Item Details']=U.ItemDetails.RenderPage,['Dashboard']=U.Dashboard.Render,['Character Progress']=U.Dashboard.Render,['Character & Gear']=U.CharacterPanel.Render,['Item Explorer']=U.ItemSelector.Render,['Stats']=U.StatsPanel.Render,['Talents']=U.Supporting.RenderTalents,['Professions']=U.Supporting.RenderProfessions,['Progression']=U.ObjectivesPanel.Render,['Daily / Weekly']=U.Supporting.RenderActivities,['Settings']=U.Supporting.RenderSettings}
 if render[U.tab] then render[U.tab]() else U.ContentPanel.Render(U.tab) end
 f.footer:SetText('Bags + equipment  ·  '..(A.Services.Inventory.pending and 'Scan deferred until combat ends' or 'Saved on /reload or logout'))
 A.Services.Professions.Remind()
end
function U.CopyReference(reference)
    if not U.copy then
        local W=U.Widgets;local f=W.Panel(U.window);f:SetSize(580,135);f:SetPoint("CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");f:EnableMouse(true)
        local label=W.Label(f,"Reference: select and copy with Ctrl+C");label:SetPoint("TOPLEFT",16,-15)
        f.edit=W.Edit(f);f.edit:SetPoint("TOPLEFT",16,-42);f.edit:SetPoint("TOPRIGHT",-16,-42)
        local close=W.Button(f,"Close",function() f:Hide() end);close:SetSize(100,26);close:SetPoint("BOTTOMRIGHT",-16,16);U.copy=f
    end
    U.copy:Show();U.copy.edit:SetText(reference or A.Data.source);U.copy.edit:SetFocus();U.copy.edit:HighlightText()
end
