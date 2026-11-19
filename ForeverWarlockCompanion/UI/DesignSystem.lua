local A=FWC
local D={themes={
 ['Modern Azeroth']={panel={.085,.105,.14,.98},edge={.48,.36,.17,1},accent={.80,.65,.35,1},button={.085,.105,.14,1}},
 ['Blizzard Classic Inspired']={panel={.078,.061,.039,.98},edge={.40,.30,.15,1},accent={.90,.73,.30,1},button={.15,.11,.065,1}},
},spacing={small=6,medium=12,large=20},fonts={heading='GameFontNormalLarge',body='GameFontHighlight',small='GameFontHighlightSmall'},components={}}
A.UI.DesignSystem=D
function D.Apply(name)
 local theme=D.themes[name] or D.themes['Modern Azeroth'];D.active=name
 local W=A.UI.Widgets;W.colors.panel=theme.panel;W.colors.edge=theme.edge;W.colors.accent=theme.accent;W.colors.button=theme.button
 for _,panel in ipairs(W.panels or {}) do
  panel.background:SetColorTexture(unpack(theme.panel));if panel.fantasy then panel.background:SetTexture('Interface\\AddOns\\ForeverWarlockCompanion\\Media\\DarkStone') end;for _,edge in ipairs(panel.edges) do edge:SetColorTexture(unpack(theme.edge)) end
 end
 for _,button in ipairs(W.buttons or {}) do if not button.active then button.bg:SetColorTexture(unpack(theme.button)) end end
end
function D.ProgressBar(parent)
 local W=A.UI.Widgets;local f=CreateFrame('Frame',nil,parent);f:SetHeight(22)
 W.Fill(f,{.10,.12,.15,1});f.fill=f:CreateTexture(nil,'ARTWORK');f.fill:SetPoint('TOPLEFT');f.fill:SetPoint('BOTTOMLEFT');f.fill:SetColorTexture(.58,.17,.82,1)
 f.label=W.Label(f,'');f.label:SetPoint('CENTER');f.label:SetJustifyH('CENTER')
 function f:SetProgress(current,total)
  self.current=current;self.total=total
  local valid=type(current)=='number' and type(total)=='number' and total>0
  self.fill:SetWidth(valid and math.max(.01,self:GetWidth()*math.min(1,math.max(0,current/total))) or .01)
  self.label:SetText(valid and (current..' / '..total..'  ('..math.floor(100*current/total)..'%)') or 'Progress unknown')
 end
 f:SetScript('OnSizeChanged',function(self) self:SetProgress(self.current,self.total) end);return f
end
function D.ItemCard(row,item,subtitle)
 local W=A.UI.Widgets
 if not row.cardIcon then row.cardIcon=row:CreateTexture(nil,'ARTWORK');row.cardIcon:SetSize(36,36);row.cardIcon:SetPoint('TOPLEFT',8,-9) end
 row.cardIcon:SetTexture(item and item.icon or 'Interface\\Icons\\INV_Misc_QuestionMark')
 row.title:ClearAllPoints();row.title:SetPoint('TOPLEFT',54,-7);row.title:SetPoint('TOPRIGHT',-9,-7);row.title:SetText((item and W.Color(item) or '')..(item and item.name or 'Unknown item')..'|r')
 row.sub:ClearAllPoints();row.sub:SetPoint('BOTTOMLEFT',54,7);row.sub:SetPoint('BOTTOMRIGHT',-9,7);row.sub:SetText(subtitle or '')
 if item then W.Tooltip(row,function() return item.id end) end
end
function D.EmptyState(parent,title,description)
 local f=A.UI.Widgets.Label(parent,title..'\n\n'..description);return f
end
function D.Badge(parent)
 local W=A.UI.Widgets;local f=W.Panel(parent);f:SetSize(110,24)
 f.label=W.Label(f,'');f.label:SetPoint('LEFT',6,0);f.label:SetPoint('RIGHT',-6,0);f.label:SetJustifyH('CENTER');f.label:SetJustifyV('MIDDLE')
 function f:SetText(value) self.label:SetText(value or '') end
 return f
end
function D.Card(parent)
 local f=A.UI.Widgets.Panel(parent);f.fantasy=true
 f.background:SetTexture('Interface\\AddOns\\ForeverWarlockCompanion\\Media\\DarkStone')
 for _,edge in ipairs(f.edges) do edge:SetColorTexture(.48,.36,.17,1) end
 f.corners={}
 for _,point in ipairs({'TOPLEFT','TOPRIGHT','BOTTOMLEFT','BOTTOMRIGHT'}) do
  local t=f:CreateTexture(nil,'BORDER');t:SetSize(18,18);t:SetPoint(point);t:SetTexture('Interface\\AddOns\\ForeverWarlockCompanion\\Media\\Corner'..point);f.corners[#f.corners+1]=t
 end
 return f
end
function D.Section(parent,title)
 local f=D.Card(parent);f.heading=A.UI.Widgets.Label(f,title,'GameFontNormal')
 f.heading:SetPoint('TOPLEFT',12,-10);f.heading:SetPoint('TOPRIGHT',-12,-10);f.heading:SetHeight(20)
 f.text=A.UI.Widgets.Label(f,'','GameFontHighlight');f.text:SetPoint('TOPLEFT',12,-38);f.text:SetPoint('TOPRIGHT',-12,-38)
 return f
end
-- Shared implementations retain the same hover/disabled/selected contracts as Widgets.
D.components.NavigationItem=function(...) return A.UI.Widgets.Button(...) end
D.components.SearchField=function(...) return A.UI.Widgets.Edit(...) end
D.components.ContextMenu=function(...) return A.UI.Widgets.Menu(...) end
D.components.SectionHeader=function(parent,text) return A.UI.Widgets.Label(parent,text,'GameFontNormal') end
D.components.TooltipAnchor=function(...) return A.UI.Widgets.Tooltip(...) end
D.components.DetailPanel=function(...) return A.UI.ItemDetails.Create(...) end
D.components.ItemCard=D.ItemCard;D.components.ObjectiveCard=D.ItemCard;D.components.ProgressBar=D.ProgressBar;D.components.EmptyState=D.EmptyState;D.components.Badge=D.Badge;D.components.InfoCard=D.Card
