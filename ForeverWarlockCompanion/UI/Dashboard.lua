local A=FWC
local D={};A.UI.Dashboard=D
local activityInfo={{'Dungeons','Dungeons','INV_Misc_Map_01'},{'Reputation','Reputations','INV_Shield_04'},{'Crafting','Crafting Planner','Trade_Tailoring'},{'Cooldowns','Cooldowns','Spell_Nature_MoonGlow'}}
function D.Create(parent)
 local W,S=A.UI.Widgets,A.UI.DesignSystem;local f=CreateFrame('Frame',nil,parent);f:SetAllPoints(parent);D.frame=f
 f.scroll=W.Scroll(f);f.scroll:SetPoint('TOPLEFT');f.scroll:SetPoint('BOTTOMRIGHT',-16,0);local body=f.scroll.content
 f.summary=S.Section(body,'Character summary');f.summary:SetHeight(140);f.summary.text:Hide()
 f.portrait=f.summary:CreateTexture(nil,'ARTWORK');f.portrait:SetPoint('TOPLEFT',14,-44);f.portrait:SetSize(58,58)
 f.character=W.Label(f.summary,'','GameFontHighlight');f.character:SetPoint('TOPLEFT',84,-44);f.character:SetPoint('TOPRIGHT',-12,-44);f.character:SetHeight(82)
 f.progress=S.Section(body,'Equipment progress');f.progress:SetHeight(140);f.progress.text:Hide()
 f.title=W.Label(f.progress,'','GameFontNormalLarge');f.title:SetPoint('TOPLEFT',16,-47)
 f.info=W.Label(f.progress,'targets obtained');f.info:SetPoint('TOPLEFT',110,-52)
 f.bar=S.ProgressBar(f.progress);f.bar:SetPoint('BOTTOMLEFT',16,20);f.bar:SetPoint('BOTTOMRIGHT',-16,20);f.bar:SetHeight(15);f.bar.label:Hide()
 f.goals=S.Section(body,'Priority objectives');f.goals.text:Hide()
 f.empty=W.Label(f.goals,'');f.empty:SetPoint('TOPLEFT',16,-56);f.empty:SetPoint('TOPRIGHT',-16,-56);f.empty:SetHeight(60)
 f.start=W.Button(f.goals,'Explore items',function() A.UI.SetTab('Item Explorer') end);f.start:SetSize(140,28);f.start:SetPoint('BOTTOMLEFT',16,16)
 f.list={rows={},data={}}
 for i=1,3 do
  local b=W.Button(f.goals,'');b.label:Hide();b.surface=S.Card(b);b.surface:SetAllPoints(b)
  b.icon=b.surface:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',10,-12);b.icon:SetSize(38,38)
  b.title=W.Label(b.surface,'','GameFontNormal');b.title:SetPoint('TOPLEFT',58,-12);b.title:SetPoint('TOPRIGHT',-10,-12);b.title:SetHeight(42)
  b.source=W.Label(b.surface,'');b.source:SetPoint('TOPLEFT',10,-64);b.source:SetPoint('TOPRIGHT',-10,-64);b.source:SetHeight(44)
  b.next=W.Label(b.surface,'','GameFontHighlight');b.next:SetPoint('TOPLEFT',10,-112);b.next:SetPoint('BOTTOMRIGHT',-10,10)
  b.priority=W.Label(b.surface,'');b.priority:SetPoint('BOTTOMLEFT',10,10);b.priority:Hide()
  f.list.rows[i]=b
 end
 f.objective=f.list.rows[1]
 f.activities=S.Section(body,'Suggested activities');f.activities.text:Hide();f.activityCards={}
 for i,entry in ipairs(activityInfo) do
  local route=entry[2];local b=W.Button(f.activities,'',function() A.UI.SetTab(route) end);b.label:Hide()
  b.surface=S.Card(b);b.surface:SetAllPoints(b)
  b.icon=b.surface:CreateTexture(nil,'ARTWORK');b.icon:SetSize(34,34);b.icon:SetPoint('TOPLEFT',10,-10);b.icon:SetTexture('Interface\\Icons\\'..entry[3])
  b.title=W.Label(b.surface,entry[1],'GameFontNormal');b.title:SetPoint('TOPLEFT',10,-53);b.title:SetPoint('TOPRIGHT',-6,-53);b.title:SetHeight(20)
  b.detail=W.Label(b.surface,'');b.detail:SetPoint('TOPLEFT',10,-78);b.detail:SetPoint('BOTTOMRIGHT',-8,8)
  f.activityCards[i]=b
 end
 f.stats=S.Section(body,'Quick stats');f.stats.text:Hide()
 f.statsNote=W.Label(f.stats,'Current equipment');f.statsNote:SetPoint('TOPLEFT',14,-36)
 f.statsText=W.Label(f.stats,'','GameFontHighlight');f.statsText:SetPoint('TOPLEFT',14,-70);f.statsText:SetPoint('TOPRIGHT',-14,-70);f.statsText:SetHeight(220)
 f.coolText=W.Label(f.stats,'');f.coolText:SetPoint('BOTTOMLEFT',14,18);f.coolText:SetPoint('BOTTOMRIGHT',-14,18);f.coolText:SetHeight(60)
 f.actions=S.Section(body,'Quick actions');f.actions.text:Hide();f.quick={}
 for i,entry in ipairs({{'Equipment','Character & Gear'},{'Objectives','Progression'},{'Dungeons','Dungeons'},{'Professions','Professions Overview'}}) do
  local route=entry[2];local b=W.Button(f.actions,entry[1],function() A.UI.SetTab(route) end);f.quick[i]=b
 end
 function f:Layout()
  local width=math.max(320,self.scroll:GetWidth());local wide=width>=780;local split=width>=580;local gap=12
  local function place(frame,x,y,w,h) frame:ClearAllPoints();frame:SetPoint('TOPLEFT',body,'TOPLEFT',x,-y);frame:SetSize(math.max(1,w),h) end
  local half=(width-gap)/2;place(self.summary,0,0,split and half or width,140);place(self.progress,split and half+gap or 0,split and 0 or 152,split and half or width,140)
  local y=split and 152 or 304;local rail=wide and math.max(190,width*.22) or 0;local main=wide and width-rail-gap or width
  local cols=main>=570 and 3 or main>=400 and 2 or 1;local cardHeight=202;local goalHeight=48+math.ceil(3/cols)*(cardHeight+10)
  place(self.goals,0,y,main,goalHeight)
  local cw=(main-32-(cols-1)*10)/cols
  for i,b in ipairs(self.list.rows) do b:ClearAllPoints();b:SetPoint('TOPLEFT',16+((i-1)%cols)*(cw+10),-42-math.floor((i-1)/cols)*(cardHeight+10));b:SetSize(cw,cardHeight) end
  local ac=main>=570 and 4 or 2;local ah=44+math.ceil(4/ac)*130
  place(self.activities,0,y+goalHeight+gap,main,ah)
  local aw=(main-32-(ac-1)*10)/ac
  for i,b in ipairs(self.activityCards) do b:ClearAllPoints();b:SetPoint('TOPLEFT',16+((i-1)%ac)*(aw+10),-38-math.floor((i-1)/ac)*130);b:SetSize(aw,120) end
  local combined=goalHeight+gap+ah
  place(self.stats,wide and main+gap or 0,wide and y or y+combined+gap,wide and rail or width,wide and combined or 340)
  y=y+combined+gap+(wide and 0 or 352)
  place(self.actions,0,y,width,86);local bw=(width-32-30)/4
  for i,b in ipairs(self.quick) do b:ClearAllPoints();b:SetPoint('BOTTOMLEFT',16+(i-1)*(bw+10),12);b:SetSize(bw,28) end
  body:SetHeight(y+98);self.scroll:UpdateRange()
 end
 f.scroll.reflow=function() f:Layout() end;f:SetScript('OnSizeChanged',function() f:Layout() end);return f
end
local function number(value) return A.Compat.Readable(value) and type(value)=='number' and tostring(value) or '—' end
function D.Render()
 local f=D.frame;local c=A.Services.Character.character;local valid,obtained=0,0
 for _,r in ipairs(A.Services.Planner.Rows('All')) do local target=A.Services.Catalog.Target(r.slot);if target and target.id==r.item.id then valid=valid+1;if r.complete then obtained=obtained+1 end end end
 f.portrait:SetTexture(A.Compat.Call(GetInventoryItemTexture,'player',1) or 'Interface\\Icons\\Spell_Shadow_ShadowBolt')
 local professions={};for _,prof in pairs(A.Services.Character.professions or {}) do if prof.name then professions[#professions+1]=prof.name..(type(prof.rank)=='number' and (' ('..prof.rank..')') or '') end end
 f.character:SetText((c.name or 'Unknown')..'\nLevel '..tostring(c.level or '?')..' '..(c.className or c.class or '?')..'\n'..(c.detectedSpec or 'Specialization unavailable')..'\n'..(#professions>0 and table.concat(professions,' / ') or 'Professions unavailable'))
 f.title:SetText(obtained..' / '..valid);f.bar:SetProgress(obtained,valid)
 local top,activities={},{};local objectives=A.Services.Objectives.List()
 for _,o in ipairs(objectives) do if o.completionState~='Obtained' then if #top<3 then top[#top+1]=o end;activities[o.sourceType]=(activities[o.sourceType] or 0)+1 end end
 D.selected=top[1];f.list.data=top;f.empty:SetShown(#top==0);f.start:SetShown(#top==0)
 f.empty:SetText(#objectives>0 and 'All tracked objectives are obtained. Choose another item when you are ready.' or 'No tracked objectives yet. Choose an item in Equipment and select Track Objective.')
 for i,b in ipairs(f.list.rows) do local o=top[i];b:SetShown(o~=nil);if o then
  local item=A.Data.items[o.itemId];local step=A.Services.Objectives.Next(o);local slot=A.Data.slotByKey[o.slot]
  b.icon:SetTexture(item and item.icon or o.icon);b.title:SetText((item and A.UI.Widgets.Color(item) or '')..o.title..'|r')
  b.source:SetText((slot and slot.label or o.slot)..' · '..o.mode..'\n'..o.sourceType..' · '..({'High','Medium','Low'})[o.priority or 2])
  b.next:SetText('Next\n'..(step and step.title or 'Acquisition recorded'))
  b:SetScript('OnClick',function() A.UI.SetTab('Progression',{objectiveId=o.objectiveId}) end)
  A.UI.Widgets.Tooltip(b,function() return o.itemId end)
 end end
 for i,kind in ipairs({'Dungeon','Reputation','Crafting'}) do local n=activities[kind] or 0;f.activityCards[i].detail:SetText(n>0 and (n..' active objectives') or 'No tracked objectives') end
 local actual=c.class;local primary=({WARLOCK=4,MAGE=4,PRIEST=4,WARRIOR=1,ROGUE=2,HUNTER=2})[actual]
 if actual==A.db.viewClass then
  if actual=='DRUID' then primary=(A.db.spec=='Feral Tank' or A.db.spec=='Feral DPS') and 2 or 4
  elseif actual=='PALADIN' then primary=(A.db.spec=='Holy' or A.db.spec=='Shockadin') and 4 or 1
  elseif actual=='SHAMAN' then primary=A.db.spec=='Enhancement' and 2 or 4 end
 end
 local _,intellect=A.Compat.Call(UnitStat,'player',4);local _,primaryValue;if primary then _,primaryValue=A.Compat.Call(UnitStat,'player',primary) end
 local spellPower=A.Compat.Call(GetSpellBonusDamage,6);local hit=A.Compat.Call(GetSpellHitModifier)
 f.statsText:SetText('Spell power (Shadow)\n|cffffd180'..number(spellPower)..'|r\n\nSpell hit modifier\n|cffffd180'..number(hit)..'|r\n\n'..((({[1]='Strength',[2]='Agility',[4]='Intellect'})[primary]) or 'Primary stat')..'\n|cffffd180'..number(primaryValue)..'|r\n\nIntellect\n|cffffd180'..number(intellect)..'|r')
 local remaining=A.Services.Professions.Cooldown();local materials,unknown=A.Services.Materials.ForObjectives(objectives)
 f.activityCards[4].detail:SetText(remaining and (remaining>0 and ('Mooncloth\n~'..math.floor(remaining/3600)..'h (manual)') or 'Estimate elapsed\nVerify in game') or 'No craft recorded')
 f.coolText:SetText('Materials\n'..#materials..' known · '..#unknown..' recipes pending')
 f:Layout()
end
