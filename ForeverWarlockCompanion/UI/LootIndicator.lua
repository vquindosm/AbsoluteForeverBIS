local A=FWC
local L={tooltips=setmetatable({},{__mode='k'}),badges=setmetatable({},{__mode='k'}),mode='unavailable'};A.UI.LootIndicator=L
local colors={upgrade='78e49a',['stats-up']='78e49a',downgrade='ef9797',['stats-down']='ef9797',
 partial='e5c575',mixed='e5c575',pending='e5c575',blocked='ef9797',loadout='e5c575',empty='e5c575',equal='b8c4d5',same='b8c4d5'}
local function paint(text,state) return '|cff'..(colors[state] or colors.partial)..text..'|r' end
local function num(v) return A.Compat.Readable(v) and type(v)=='number' and v==v and math.abs(v)<math.huge end
function L.Enabled() return A.db and A.db.settings.lootIndicators~=false end
function L.Lines(result)
 local model=A.Services.UpgradeIndicator.Build(result);return model and model.text
end
function L.Clear(tip,reset)
 local state=L.tooltips[tip]
 if state then state.link=nil;A.UI.UpgradeTooltip.Clear(tip,state,reset) end
end
function L.Update(tip)
 local state=L.tooltips[tip];if not state or state.updating then return end
 if not L.Enabled() or A.Compat.Call(tip.IsForbidden,tip)==true or A.Compat.Call(tip.IsProtected,tip)==true or A.Compat.Call(tip.IsShown,tip)==false then L.Clear(tip);return end
 local ok,_,link=false,nil,nil
 if type(tip.GetItem)=='function' then ok,_,link=pcall(tip.GetItem,tip) end
 if not ok or not A.Compat.Readable(link) or not A.Compat.ItemID(link) then L.Clear(tip);return end
 state.link=link
 local model=A.Services.UpgradeIndicator.Build(A.Services.LootComparison.Compare(link))
 state.updating=true
 local success,err=pcall(A.UI.UpgradeTooltip.Show,tip,state,model);state.updating=false
 if not success then L.Clear(tip);error(err) end
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
local function flushPlacement()
 local pending=L.pendingPlacement or {};L.pendingPlacement={}
 for tip in pairs(pending) do
  local state=L.tooltips[tip];if state then state.placementQueued=nil end
  watchSafe(tip)
 end
end
local function nativeChanged(tip)
 watchSafe(tip)
 local state=L.tooltips[tip]
 if not state or not state.link or state.placementQueued then return end
 state.placementQueued=true;L.pendingPlacement=L.pendingPlacement or {};L.pendingPlacement[tip]=true
 -- The native engine can finish its reflow after the item callback. Reapply
 -- once after that stack, rereading the current link; never poll OnUpdate.
 if C_Timer and type(C_Timer.After)=='function' then C_Timer.After(0,flushPlacement)
 elseif L.placementFrame then L.placementFrame:SetScript('OnUpdate',function(frame) frame:SetScript('OnUpdate',nil);flushPlacement() end) end
end
function L.Init()
 A.Services.LootScore.Init()
 if not (C_Timer and type(C_Timer.After)=='function') and not L.placementFrame then L.placementFrame=CreateFrame('Frame') end
 if not L.modernAttempted and TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall)=='function' and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item~=nil then
  L.modernAttempted=true
  L.modern=pcall(TooltipDataProcessor.AddTooltipPostCall,Enum.TooltipDataType.Item,nativeChanged)
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
   if not L.modern and not state.itemHook and state.lifecycle then state.itemHook=hook(tip,'OnTooltipSetItem',nativeChanged);if state.itemHook then L.mode='legacy' end end
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
 for tip,state in pairs(L.tooltips) do if tip~=GameTooltip and tip~=ItemRefTooltip then L.Clear(tip) elseif state.link or state.indicator then L.Update(tip) end end
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
