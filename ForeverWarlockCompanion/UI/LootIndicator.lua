local A=FWC
local L={tooltips=setmetatable({},{__mode='k'}),badges=setmetatable({},{__mode='k'}),mode='unavailable'};A.UI.LootIndicator=L
local colors={upgrade='78e49a',['stats-up']='78e49a',downgrade='ef9797',['stats-down']='ef9797',
 partial='e5c575',mixed='e5c575',pending='e5c575',blocked='ef9797',loadout='e5c575',empty='e5c575',equal='b8c4d5',same='b8c4d5'}
local function paint(text,state) return '|cff'..(colors[state] or colors.partial)..text..'|r' end
local function num(v) return A.Compat.Readable(v) and type(v)=='number' and v==v and math.abs(v)<math.huge end
local function icon(name) return '|TInterface\\Icons\\'..name..':14:14:0:0|t ' end
local statIcons={ITEM_MOD_INTELLECT_SHORT='Spell_Holy_MagicalSentry',ITEM_MOD_STAMINA_SHORT='Spell_Holy_WordFortitude',
 ITEM_MOD_SPIRIT_SHORT='Spell_Holy_SpiritOfRedemption',ITEM_MOD_STRENGTH_SHORT='Spell_Nature_Strength',ITEM_MOD_AGILITY_SHORT='Ability_Rogue_Sprint',
 ITEM_MOD_SPELL_POWER_SHORT='Spell_Shadow_ShadowBolt',ITEM_MOD_SPELL_DAMAGE_DONE_SHORT='Spell_Shadow_ShadowBolt',
 ITEM_MOD_DAMAGE_SHADOW_SHORT='Spell_Shadow_ShadowBolt',ITEM_MOD_DAMAGE_FIRE_SHORT='Spell_Fire_FireBolt02',
 ITEM_MOD_SPELL_PENETRATION_SHORT='Spell_Shadow_ShadowWordDominate',RESISTANCE0_NAME='INV_Chest_Plate01',
 ITEM_MOD_HIT_SPELL_RATING_SHORT='Ability_Marksmanship',ITEM_MOD_HIT_RATING_SHORT='Ability_Marksmanship',
 ITEM_MOD_CRIT_SPELL_RATING_SHORT='Spell_Fire_Incinerate',ITEM_MOD_CRIT_RATING_SHORT='Ability_CriticalStrike',
 ITEM_MOD_ATTACK_POWER_SHORT='Ability_MeleeDamage',ITEM_MOD_MANA_REGENERATION_SHORT='Spell_Nature_ManaRegenTotem'}
local specs={affliction={'Aflicción','Spell_Shadow_DeathCoil'},demonology={'Demonología','Spell_Shadow_Metamorphosis'},destruction={'Destrucción','Spell_Shadow_RainOfFire'}}
local marker=icon('INV_Misc_Book_09')..'|cffffd16aForever Companion · Upgrade|r'
local function statLabel(d)
 -- Let the client supply localized terminology. Do not call percentage-based
 -- Forever stats "rating" just because a historical global key contains RATING.
 local label=_G[d.key]
 return type(label)=='string' and label or (d.label:gsub(' %(rating%)',''))
end
function L.Enabled() return A.db and A.db.settings.lootIndicators~=false end
function L.Lines(result)
 if not result then return nil end
 if result.itemId==279269 then return A.UI.ItemInspector.UpgradeLines(result,marker) end
 local lines={marker}
 if result.state=='pending' then lines[#lines+1]=paint(result.reason,'pending');return table.concat(lines,'\n') end
 local shift=A.Compat.Call(IsShiftKeyDown)==true;local limit=shift and 16 or 6;local more=false;local scored=false
 for _,row in ipairs(result.comparisons) do
  local title
  if row.score then
   scored=true
   if row.score.provider=='flb' then
    local spec=specs[row.score.spec];local name=spec and spec[1] or row.score.spec
    title=(spec and icon(spec[2]) or '')..name..string.format('  %.1f',row.score.after)
    local change=string.format('%+.1f',row.score.absolute)
    if row.score.delta then change=change..string.format(' (%+.0f%%)',row.score.delta) end
    title=title..'  '..change
   else title=row.state=='upgrade' and string.format('↑ Mejora estimada %+.1f%% EP',row.score.delta) or row.state=='downgrade' and string.format('↓ Menor EP: %+.1f%%',row.score.delta) or '= EP equivalente' end
  else title=({['stats-up']='↑ Gana atributos comparados',['stats-down']='↓ Pierde atributos comparados',
   mixed='± Ventajas y pérdidas',partial='? Comparación parcial',pending='? Datos pendientes',
   equal='= Sin cambio en los atributos leídos',same='= Ya equipado',empty='+ Ranura vacía',
   blocked='! No utilizable ahora',loadout='? Cambio de armas necesario'})[row.state] end
  if row.compatibility and (row.state=='upgrade' or row.state=='stats-up') then title=title..' · uso sin comprobar' end
  local state=row.compatibility and (row.state=='upgrade' or row.state=='stats-up') and 'partial' or row.state
  lines[#lines+1]=paint(row.label..' · '..(title or 'Sin valoración'),state)
  if row.before and row.before.name then lines[#lines+1]='|cff9da9b8vs '..row.before.name..'|r' end
  local cells={}
  for i,d in ipairs(row.deltas) do
   if i<=limit then
    cells[#cells+1]=icon(statIcons[d.key] or 'INV_Misc_QuestionMark')..paint(string.format('%+g ',d.delta)..statLabel(d),d.delta>0 and 'stats-up' or 'stats-down')
    if #cells==2 then lines[#lines+1]=table.concat(cells,'   ');cells={} end
   else more=true end
  end
  if #cells>0 then lines[#lines+1]=table.concat(cells,'   ') end
  for i,u in ipairs(row.unknown) do if i<=2 then lines[#lines+1]=paint(u.label..': botín '..tostring(u.after or '?')..' · equipado '..tostring(u.before or '?'),'partial') end end
  if row.state=='blocked' or row.state=='loadout' or row.state=='pending' or row.state=='empty' then lines[#lines+1]=row.reason end
  if row.compatibility then lines[#lines+1]=paint(row.compatibility,'partial') end
  if row.score and row.score.provider=='flb' then lines[#lines+1]='|cff9da9b8Forever Leveling BiS · perfil activo · no es DPS|r' end
 end
 if more then lines[#lines+1]=shift and 'Otros atributos: consulta también el tooltip nativo.' or 'Mayús: ver más cambios de atributos.' end
 if scored then
  local manual=false;for _,r in ipairs(result.comparisons) do if r.score and r.score.provider~='flb' then manual=true end end
  if manual then lines[#lines+1]='|cff9da9b8Tus pesos EP · no es DPS|r' end
 else
  lines[#lines+1]='|cff9da9b8Sin valoración global · sólo atributos|r'
  if shift then for _,r in ipairs(result.comparisons) do if r.reason then lines[#lines+1]=r.reason end end end
 end
 return table.concat(lines,'\n')
end
function L.Clear(tip,reset)
 local state=L.tooltips[tip]
 if state then
  state.link=nil;state.pendingId=nil
  if state.inline then
   local own=state.inline
   if A.Compat.Call(tip.IsForbidden,tip)~=true and A.Compat.Call(own.header.GetText,own.header)==marker and A.Compat.Call(own.body.GetText,own.body)==own.text then
    A.Compat.Method(own.header,'SetText','');A.Compat.Method(own.body,'SetText','');own.inactive=true
   end
   if reset then state.inline=nil end
  end
  if state.panel then state.panel:Hide() end
 end
end
local function inline(tip,state,text)
 local name=A.Compat.Call(tip.GetName,tip)
 if type(name)~='string' or type(tip.AddLine)~='function' or type(tip.NumLines)~='function' then return false end
 local body=text:match('^[^\n]*\n(.*)$') or ''
 local own=state.inline
 if own then
  local header=own.header:GetText();local content=own.body:GetText()
  if not ((header==marker and content==own.text) or (own.inactive and header=='' and content=='')) then state.inline=nil;own=nil end
 end
 if not own then
  local count=A.Compat.Call(tip.NumLines,tip);if not num(count) then return false end
  -- Only our two native lines are edited later. No ClearLines, SetHyperlink or
  -- tooltip-wide font/color changes that could destroy another addon's output.
  if not A.Compat.Method(tip,'AddLine',marker,1,1,1,true) then return false end
  if not A.Compat.Method(tip,'AddLine',body,1,1,1,true) then return false end
  local header=_G[name..'TextLeft'..(count+1)];local content=_G[name..'TextLeft'..(count+2)]
  if not header or not content or type(header.GetText)~='function' or type(content.SetText)~='function' then return false end
  own={header=header,body=content};state.inline=own
 end
 own.header:SetText(marker);own.body:SetText(body);own.text=body;own.inactive=nil
 if state.panel then state.panel:Hide() end
 A.Compat.Method(tip,'Show')
 return true
end
local function hiddenOrForbidden(tip)
 return A.Compat.Call(tip.IsForbidden,tip)==true or A.Compat.Call(tip.IsShown,tip)==false
end
function L.Update(tip)
 local state=L.tooltips[tip];if not state or state.updating then return end
 if not L.Enabled() or hiddenOrForbidden(tip) then L.Clear(tip);return end
 local ok,_,current=false,nil,nil
 if type(tip.GetItem)=='function' then ok,_,current=pcall(tip.GetItem,tip) end
 if not ok then L.Clear(tip);return end
 if not A.Compat.Readable(current) or not A.Compat.ItemID(current) then L.Clear(tip);return end
 if current~=state.link then state.link=current end
 local result=A.Services.LootComparison.Compare(state.link);local text=L.Lines(result)
 if not text then L.Clear(tip);return end
 state.updating=true
 local okInline,used=pcall(inline,tip,state,text);state.updating=false
 if okInline and used then return end
 if not state.panel then
  local p=A.UI.Widgets.Panel(tip);state.panel=p;p:EnableMouse(false);p:SetClampedToScreen(true)
  p.text=A.UI.Widgets.Label(p,'');p.text:SetPoint('TOPLEFT',8,-8);p.text:SetPoint('TOPRIGHT',-8,-8)
 end
 local p=state.panel;local width=A.Compat.Call(tip.GetWidth,tip);width=num(width) and width or 300
 p:SetWidth(math.max(280,math.min(460,width)));p.text:SetWidth(p:GetWidth()-16);p.text:SetText(text)
 p:SetHeight(math.max(40,p.text:GetStringHeight()+16));p:ClearAllPoints()
 local bottom=A.Compat.Call(tip.GetBottom,tip)
 if num(bottom) and bottom<p:GetHeight()+8 then p:SetPoint('BOTTOMLEFT',tip,'TOPLEFT',0,3)
 else p:SetPoint('TOPLEFT',tip,'BOTTOMLEFT',0,-3) end
 p:Show()
end
function L.Watch(tip)
 if not tip then return end
 if tip~=GameTooltip and tip~=ItemRefTooltip then return end
 if not L.Enabled() or A.Compat.Call(tip.IsForbidden,tip)==true then L.Clear(tip);return end
 local state=L.tooltips[tip]
 if not state or not state.lifecycleAttempted then L.Init();state=L.tooltips[tip] end
 if not state or not state.lifecycle then L.Clear(tip);return end
 L.Update(tip)
end
local function hook(tip,event,fn)
 if type(tip.HookScript)~='function' then return false end
 if type(tip.HasScript)=='function' and A.Compat.Call(tip.HasScript,tip,event)~=true then return false end
 return A.Compat.Method(tip,'HookScript',event,fn)
end
local function watchSafe(tip)
 local ok,err=pcall(L.Watch,tip)
 if not ok then L.Clear(tip);if L.lastError~=tostring(err) then L.lastError=tostring(err);A:Log('Loot indicator: '..L.lastError) end end
end
function L.Init()
 A.Services.LootScore.Init()
 if not L.modernAttempted and TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall)=='function' and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item~=nil then
  L.modernAttempted=true
  L.modern=pcall(TooltipDataProcessor.AddTooltipPostCall,Enum.TooltipDataType.Item,watchSafe)
  if L.modern then L.mode='modern' end
 end
 for _,name in ipairs({'GameTooltip','ItemRefTooltip'}) do
  local tip=_G[name]
  if tip and A.Compat.Call(tip.IsForbidden,tip)~=true then
   local state=L.tooltips[tip] or {};L.tooltips[tip]=state
   if not state.lifecycleAttempted then
    state.lifecycleAttempted=true
    local a=hook(tip,'OnHide',L.Clear);local b=hook(tip,'OnTooltipCleared',function(frame) L.Clear(frame,true) end)
    hook(tip,'OnShow',watchSafe)
    -- If neither lifecycle hook is supported, never attach persistent content.
    state.lifecycle=a and b
   end
   if not L.modern and not state.itemHook and state.lifecycle then state.itemHook=hook(tip,'OnTooltipSetItem',watchSafe);if state.itemHook then L.mode='legacy' end end
  end
 end
 local supported=false;for _,state in pairs(L.tooltips) do if state.lifecycle and (L.modern or state.itemHook) then supported=true end end
 L.mode=supported and (L.modern and 'modern' or 'legacy') or 'unavailable'
 if not L.lootUpdateHooked and type(hooksecurefunc)=='function' and type(LootFrame_Update)=='function' then
  L.lootUpdateHooked=pcall(hooksecurefunc,'LootFrame_Update',function() L.RefreshLoot() end)
 end
 local box=LootFrame and LootFrame.ScrollBox
 if box and box~=L.scrollBoxHooked and type(hooksecurefunc)=='function' and type(box.Update)=='function' then
  if pcall(hooksecurefunc,box,'Update',function() L.RefreshLoot() end) then L.scrollBoxHooked=box end
 end
 return L.mode~='unavailable'
end
function L.ScheduleLoot()
 L.RefreshLoot()
 if not L.lootQueued and C_Timer and type(C_Timer.After)=='function' then
  L.lootQueued=true;C_Timer.After(0,function() L.lootQueued=false;if L.lootOpen then L.Init();L.RefreshLoot() end end)
 end
end
function L.RefreshLoot()
 if not L.lootOpen then return end
 local visited={}
 local function update(button,slot)
   visited[button]=true
   local badge=L.badges[button]
   local link=L.Enabled() and num(slot) and slot>0 and slot%1==0 and A.Compat.Call(button.IsShown,button)~=false and A.Compat.Call(GetLootSlotLink,slot) or nil
   local result=type(link)=='string' and A.Services.LootComparison.Compare(link) or nil
   local text,state=A.Services.LootComparison.Badge(result)
   if text then
    if not badge then badge=A.UI.Widgets.Panel(button);L.badges[button]=badge;badge:SetSize(48,18);badge:SetPoint('TOPRIGHT',-3,-2);badge:EnableMouse(false);badge.text=A.UI.Widgets.Label(badge,'');badge.text:SetAllPoints(badge);badge.text:SetJustifyH('CENTER');badge.text:SetJustifyV('MIDDLE') end
    badge.text:SetText(paint(text,state));badge:Show()
   elseif badge then badge:Hide() end
 end
 -- Classic/Forever rows expose their current loot slot. Never assume row 1 is
 -- loot slot 1: the game reuses these buttons while scrolling the loot window.
 for i=1,math.min(20,type(LOOTFRAME_NUMBUTTONS)=='number' and LOOTFRAME_NUMBUTTONS or 4) do
  local button=_G['LootButton'..i]
  if button then update(button,button.slot) end
 end
 local box=LootFrame and LootFrame.ScrollBox
 if box and type(box.ForEachFrame)=='function' then A.Compat.Method(box,'ForEachFrame',function(frame) update(frame,A.Compat.Call(frame.GetSlotIndex,frame)) end) end
 for button,badge in pairs(L.badges) do if not visited[button] then badge:Hide() end end
end
function L.Refresh()
 if not A.db then return end
 L.Init()
 for tip,state in pairs(L.tooltips) do if tip~=GameTooltip and tip~=ItemRefTooltip then L.Clear(tip) elseif state.link or state.panel then L.Update(tip) end end
 L.RefreshLoot()
end
function L.SetEnabled(enabled)
 A.db.settings.lootIndicators=enabled==true
 if not enabled then
  for tip in pairs(L.tooltips) do L.Clear(tip) end
  for _,badge in pairs(L.badges) do badge:Hide() end
 else L.Init();L.Watch(GameTooltip);if ItemRefTooltip then L.Watch(ItemRefTooltip) end;L.RefreshLoot() end
end
return L
