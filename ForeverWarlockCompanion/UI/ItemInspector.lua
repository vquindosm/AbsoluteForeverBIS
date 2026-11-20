local A=FWC
local I={};A.UI.ItemInspector=I
local statIcons={ITEM_MOD_INTELLECT_SHORT='Spell_Holy_MagicalSentry',ITEM_MOD_STAMINA_SHORT='Spell_Holy_WordFortitude',ITEM_MOD_DAMAGE_SHADOW_SHORT='Spell_Shadow_ShadowBolt',
 ITEM_MOD_CRIT_RATING_SHORT='Ability_CriticalStrike',ITEM_MOD_SPELL_POWER_SHORT='Spell_Shadow_ShadowBolt',ITEM_MOD_DAMAGE_FROST_SHORT='Spell_Frost_FrostBolt02',RESISTANCE0_NAME='INV_Chest_Plate01'}
local labels={ITEM_MOD_DAMAGE_SHADOW_SHORT='Shadow damage',ITEM_MOD_CRIT_RATING_SHORT='Crit',ITEM_MOD_STAMINA_SHORT='Stamina',ITEM_MOD_DAMAGE_FROST_SHORT='Frost damage',RESISTANCE0_NAME='Armor'}
local function tint(s,positive) return (positive and '|cff78e49a' or '|cffef9797')..s..'|r' end
local function label(d)
 local text=labels[d.key] or (d.label:gsub(' %(rating%)',''))
 return text:match('^ITEM_MOD_') and 'Other attribute' or text
end
local function section(parent,title)
 local f=A.UI.DesignSystem.Section(parent,title);f.text:Hide();return f
end
local function row(parent)
 local f=CreateFrame('Frame',nil,parent);f:SetHeight(28)
 f.icon=f:CreateTexture(nil,'ARTWORK');f.icon:SetSize(22,22);f.icon:SetPoint('TOPLEFT',0,-2)
 f.text=A.UI.Widgets.Label(f,'','GameFontHighlight');f.text:SetPoint('TOPLEFT',30,-4);f.text:SetPoint('TOPRIGHT',0,-4);f.text:SetHeight(22)
 return f
end
function I.PaintRating(font,result)
 local state,text,color=A.Services.UpgradeComparison.Rating(result)
 font:SetText('|cff'..color..text..'|r');return state
end
function I.Create(owner)
 local W=A.UI.Widgets;local f=CreateFrame('Frame',nil,owner.scroll.content);f:SetPoint('TOPLEFT');f:SetPoint('TOPRIGHT')
 f.stats=section(f,'Key stats');f.statRows={}
 for n=1,4 do f.statRows[n]=row(f.stats) end
 f.comparison=section(f,'Comparación con tu equipo')
 f.current=W.Button(f.comparison,'',function() end);f.current:SetHeight(36)
 f.candidate=W.Button(f.comparison,'',function() end);f.candidate:SetHeight(36)
 for _,b in ipairs({f.current,f.candidate}) do
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(24,24);b.icon:SetPoint('LEFT',6,0)
  b.label:ClearAllPoints();b.label:SetPoint('LEFT',36,0);b.label:SetPoint('RIGHT',-6,0);b.label:SetJustifyH('LEFT');A.Compat.Method(b.label,'SetWordWrap',true)
 end
 f.deltas={};for n=1,8 do f.deltas[n]=row(f.comparison) end
 f.score=W.Label(f.comparison,'','GameFontHighlight');f.score:SetHeight(30)
 f.partial=W.Label(f.comparison,'','GameFontHighlight');f.partial:SetHeight(28)
 f.source=section(f,'Cómo conseguirlo')
 f.recipe=W.Label(f.source,'','GameFontHighlight');f.recipe:SetPoint('TOPLEFT',12,-36);f.recipe:SetPoint('TOPRIGHT',-12,-36)
 f.pattern=W.Button(f.source,'',function() end);f.pattern:SetHeight(30)
 f.materials={}
 for n=1,8 do
  local r=row(f.source);r:SetHeight(48);r.text:SetHeight(21)
  r.progress=W.Label(r,'','GameFontHighlightSmall');r.progress:SetPoint('TOPLEFT',30,-27);r.progress:SetPoint('TOPRIGHT',0,-27);r.progress:SetHeight(16)
  f.materials[n]=r
 end
 f.next=W.Label(f.source,'','GameFontHighlight');f.next:SetHeight(40)
 f.costs=section(f,'Costes y precios');f.costRows={}
 for n=1,4 do local r=W.Label(f.costs,'','GameFontHighlight');f.costRows[n]=r end
 f.affinity=section(f,'Afinidad de especialización');f.affinity.text:Show()
 f.alternatives=section(f,'Alternativas')
 f.expand=W.Button(f.alternatives,'',function() f.alternativesOpen=not f.alternativesOpen;I.Layout(owner) end);f.expand:SetPoint('TOPLEFT',10,-34);f.expand:SetWidth(130)
 f.viewAll=W.Button(f.alternatives,'View All',function()
  A.UI.explorerSlot=owner.slot;A.UI.search='';A.UI.source=nil;A.UI.ItemSelector.filters={}
  A.UI.SetTab('Item Explorer',{slot=owner.slot,itemId=owner.item.id})
 end);f.viewAll:SetPoint('TOPRIGHT',-10,-34);f.viewAll:SetWidth(110)
 f.alternativeRows={}
 for n=1,3 do
  local r=W.Button(f.alternatives,'',function() end);r:SetHeight(72)
  r.icon=r:CreateTexture(nil,'ARTWORK');r.icon:SetSize(30,30);r.icon:SetPoint('TOPLEFT',6,-7)
  r.name=W.Label(r,'','GameFontNormal');r.name:SetPoint('TOPLEFT',44,-6);r.name:SetPoint('TOPRIGHT',-8,-6);r.name:SetHeight(30)
  r.state=W.Label(r,'','GameFontHighlight');r.state:SetPoint('TOPLEFT',44,-38);r.state:SetPoint('TOPRIGHT',-8,-38);r.state:SetHeight(28)
  f.alternativeRows[n]=r
 end
 f.advanced=section(f,'Advanced Details');f.advanced.text:Show()
 owner.inspector=f
 owner.pilotCredit=W.Button(owner,'ForeverDB.net · https://foreverdb.net',function() A.UI.CopyReference('https://foreverdb.net') end)
 owner.pilotCredit:SetHeight(20);owner.pilotCredit:SetPoint('TOPLEFT',12,-85);owner.pilotCredit:SetPoint('TOPRIGHT',-12,-85)
 W.Tooltip(f.current,function() return f.model and f.model.comparison.before.link end)
 W.Tooltip(f.candidate,function() return owner.item and (owner.item.link or owner.item.id) end)
 return f
end
local function put(frame,parent,y,height,inset)
 inset=inset or 0
 frame:ClearAllPoints();frame:SetPoint('TOPLEFT',parent,'TOPLEFT',inset,-y);frame:SetPoint('TOPRIGHT',parent,'TOPRIGHT',-inset,-y);frame:SetHeight(height)
end
function I.Layout(owner)
 local f=owner.inspector;if not f or not f.model then return end
 local m=f.model;local width=math.max(180,owner.scroll:GetWidth());f:SetWidth(width)
 local y=0
 local function place(panel,h) put(panel,f,y,h);y=y+h+8 end
 place(f.stats,42+#m.stats*28)
 for n,r in ipairs(f.statRows) do put(r,f.stats,36+(n-1)*28,28,12) end
 put(f.current,f.comparison,36,36,10);put(f.candidate,f.comparison,76,36,10)
 local shown=math.min(#m.comparison.deltas,8)
 for n,r in ipairs(f.deltas) do put(r,f.comparison,118+(n-1)*28,28,12) end
 put(f.score,f.comparison,120+shown*28,30,12);put(f.partial,f.comparison,151+shown*28,28,12)
 place(f.comparison,185+shown*28)
 f.recipe:SetWidth(width-24);f.recipe:SetHeight(f.recipe:GetStringHeight())
 local top=42+f.recipe:GetHeight();put(f.pattern,f.source,top,30);top=top+40
 for n,r in ipairs(f.materials) do put(r,f.source,top+(n-1)*48,48,12) end
 top=top+#m.materials*48;put(f.next,f.source,top+8,40,12);place(f.source,top+58)
 local costY=36
 for _,r in ipairs(f.costRows) do r:SetWidth(width-24);local h=r:GetStringHeight()+10;put(r,f.costs,costY,h,12);costY=costY+h end
 place(f.costs,costY+8)
 f.affinity:SetShown(m.affinity~=nil)
 if m.affinity then f.affinity.text:SetWidth(width-24);place(f.affinity,f.affinity.text:GetStringHeight()+48) end
 local altH=74+(f.alternativesOpen and #m.alternatives*78 or 0)
 place(f.alternatives,altH);f.expand:SetText(f.alternativesOpen and 'Ocultar −' or ('Alternativas ('..#m.alternatives..') +'))
 for n,r in ipairs(f.alternativeRows) do r:SetShown(f.alternativesOpen and m.alternatives[n]~=nil);put(r,f.alternatives,70+(n-1)*78,72) end
 f.advanced:SetShown(owner.expanded==true)
 if owner.expanded then f.advanced.text:SetWidth(width-24);place(f.advanced,f.advanced.text:GetStringHeight()+48) end
 f:SetHeight(y);owner.scroll.content:SetHeight(y);owner.scroll:UpdateRange()
end
function I.Render(owner,slot,item)
 local f=owner.inspector or I.Create(owner);local W=A.UI.Widgets
 f.model=A.Services.ItemInspector.Model(slot,item);local m=f.model
 f.stats.heading:SetText(m.publishedStats and 'Key stats · referencia publicada' or 'Key stats')
 f:Show();owner.pilotCredit:Show()
 owner.name:SetText(W.Color(item)..(m.live.name or item.name)..'|r');owner.texture:SetTexture(m.live.icon or A.Services.ItemGuide.Icon(item))
 owner.status:SetText('Cloth · Back · ilvl '..tostring(m.live.level or m.record.itemLevel)..'\n'..m.status..' · Tailoring')
 for n,r in ipairs(f.statRows) do
  local stat=m.stats[n];r:SetShown(stat~=nil)
  if stat then r.icon:SetTexture('Interface\\Icons\\'..stat.icon);r.text:SetText('+'..stat.value..' '..stat.label) end
 end
 local before=m.comparison.before
 f.current:SetText('Equipped: '..(before.name or 'Unknown / empty'));f.candidate:SetText('Candidate: '..item.name)
 f.current.icon:SetTexture(before.info and before.info.icon or 'Interface\\Icons\\INV_Misc_QuestionMark');f.candidate.icon:SetTexture(m.live.icon or A.Services.ItemGuide.Icon(item))
 for n,r in ipairs(f.deltas) do
  local d=m.displayDeltas[n];r:SetShown(d~=nil)
  if d then r.icon:SetTexture('Interface\\Icons\\'..(statIcons[d.key] or 'INV_Misc_QuestionMark'));r.text:SetText(tint(string.format('%+g ',d.delta)..label(d),d.delta>0)) end
 end
 local score=m.comparison.score
 f.score:SetText(score and tint(string.format('EP: %+.1f (%+.1f%%)',score.absolute,score.delta),score.absolute>=0) or '|cffe5c575Upgrade score unavailable|r')
 f.partial:SetText(not m.comparison.complete and 'Comparación parcial · faltan atributos' or 'EP de objeto · no es DPS')
 local recipe=m.recipe
 f.recipe:SetText(recipe and ('Tailoring '..tostring(recipe.skill and recipe.skill.orange or '?')..' · '..tostring(recipe.needsNearby or '')..'\nRequires level '..m.record.requiredLevel..' para equipar\nOrigen del patrón sin confirmar') or 'Receta no publicada')
 local pattern=recipe and recipe.learnedFrom and recipe.learnedFrom.recipeItems and recipe.learnedFrom.recipeItems[1]
 f.pattern:SetText(pattern and pattern.name or 'Pattern unavailable');W.Tooltip(f.pattern,function() return pattern and pattern.itemId end)
 for n,r in ipairs(f.materials) do
  local mat=m.materials[n];r:SetShown(mat~=nil)
  if mat then
   r.icon:SetTexture(A.Compat.ItemInfo(mat.itemId).icon or 'Interface\\Icons\\INV_Misc_QuestionMark');r.text:SetText(mat.name)
   r.progress:SetText((mat.complete and '|cff78e49a' or '|cffe5c575')..tostring(mat.available or '?')..' / '..mat.required..(mat.missing and (' · Faltan '..mat.missing) or ' · Bolsas sin comprobar')..'|r')
   W.Tooltip(r,function() return mat.itemId end)
  end
 end
 f.next:SetText('|cffffd16aSiguiente: '..m.nextAction..'|r')
 for n,cost in ipairs(m.costs) do f.costRows[n]:SetText('|cffffd16a'..cost.label..'|r\n'..cost.value) end
 if m.affinity then f.affinity.text:SetText('Aflicción · JcE 60\n'..m.affinity.behindPercent..'% por debajo del mejor de la guía\nReferencia ForeverDB · no es tu mejora') end
 for n,r in ipairs(f.alternativeRows) do
  local other=m.alternatives[n]
  if other then
   r.icon:SetTexture(A.Services.ItemGuide.Icon(other.item));r.name:SetText(W.Color(other.item)..other.item.name..'|r')
   local _,rating,color=A.Services.UpgradeComparison.Rating(other.comparison);r.state:SetText(other.status..' · |cff'..color..rating..'|r')
   r:SetScript('OnClick',function() A.UI.selectedItem=other.item.id;A:Refresh() end);W.Tooltip(r,function() return other.item.id end)
  end
 end
 f.advanced.text:SetText(m.advanced)
 local profile=A.Services.Persistence.Profile();local objective=A.Services.Objectives.Find(item.id,slot)
 owner.buttons[2]:SetText(profile.obtained[item.id] and 'Unmark Obtained' or 'Mark as Obtained');owner.buttons[3]:SetText(objective and objective.trackingState=='Tracked' and 'Untrack Objective' or 'Track Objective')
 owner.priority:SetText('Priority: '..({'High','Normal','Low'})[profile.priorities[item.id] or 2])
 owner:LayoutActions()
end
function I.UpgradeLines(result,marker)
 local lines={marker}
 for _,r in ipairs(result.comparisons) do
  lines[#lines+1]='Compared with: '..(r.before and r.before.name or 'Unknown / empty')
  for n,d in ipairs(A.Services.UpgradeComparison.DisplayDeltas(r)) do if n<=8 then lines[#lines+1]=tint(string.format('%+g ',d.delta)..label(d),d.delta>0) end end
  if not r.complete then lines[#lines+1]='|cffe5c575Partial comparison|r' end
  if r.state=='blocked' or r.state=='loadout' or r.compatibility then lines[#lines+1]=r.reason or r.compatibility or 'Equipment change required' end
  lines[#lines+1]=r.score and string.format('EP: %+.1f (%+.1f%%) · not DPS',r.score.absolute,r.score.delta) or 'EP: Not calculated'
 end
 return table.concat(lines,'\n')
end
return I
