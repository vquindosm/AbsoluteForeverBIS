local A=FWC
local U={};A.UI.UpgradeTooltip=U
local function number(n) return A.Compat.Readable(n) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function points(font)
 local count=A.Compat.Call(font.GetNumPoints,font)
 if not number(count) or count<1 or count>8 then return nil end
 local out={}
 for n=1,count do
  local ok,p,relative,rp,x,y=pcall(font.GetPoint,font,n)
  if not ok or type(p)~='string' or not number(x) or not number(y) then return nil end
  out[n]={p,relative,rp,x,y}
 end
 return out
end
local function same(a,b)
 if not a or not b or #a~=#b then return false end
 for i,p in ipairs(a) do for n=1,5 do if p[n]~=b[i][n] then return false end end end
 return true
end
local function set(font,anchors)
 font:ClearAllPoints();for _,p in ipairs(anchors) do font:SetPoint(p[1],p[2],p[3],p[4],p[5]) end
end
function U.Clear(tip,state,reset)
 if state.indicator then state.indicator:Hide() end
 local layout=state.layout;state.layout=nil
 if not layout or A.Compat.Call(tip.IsForbidden,tip)==true or A.Compat.Call(tip.IsProtected,tip)==true then return end
 local ownedOffset=false;local currentCount=A.Compat.Call(tip.NumLines,tip)
 for _,entry in ipairs(layout.entries) do
  -- Restore only anchors still owned by us. A native rebuild or another addon
  -- may already have replaced them since the previous update.
  if same(points(entry.font),entry.applied) then
   if number(currentCount) and entry.index<=currentCount and not same(entry.original,entry.applied) then ownedOffset=true end
   set(entry.font,entry.original)
  end
 end
 local height=A.Compat.Call(tip.GetHeight,tip)
 if not reset and number(height) and (ownedOffset or #layout.entries==0 and math.abs(height-layout.height-layout.extra)<.01) then tip:SetHeight(math.max(1,height-layout.extra)) end
end
function U.Show(tip,state,model)
 U.Clear(tip,state)
 if not model or A.Compat.Call(tip.IsForbidden,tip)==true or A.Compat.Call(tip.IsProtected,tip)==true then return false end
 local name=A.Compat.Call(tip.GetName,tip);local count=A.Compat.Call(tip.NumLines,tip)
 local height=A.Compat.Call(tip.GetHeight,tip);local width=A.Compat.Call(tip.GetWidth,tip)
 if type(name)~='string' or not number(count) or count<1 or not number(height) or not number(width) then return false end
 local title=_G[name..'TextLeft1'];if not title or not points(title) then return false end
 local entries,moved={},{}
 for n=2,count do
  for _,side in ipairs({'Left','Right'}) do
   local font=_G[name..'Text'..side..n]
   local text=font and A.Compat.Call(font.GetText,font)
   if not A.Compat.Readable(text) then return false end
   if font and type(text)=='string' and text~='' then
    local original=points(font);if not original then return false end
    entries[#entries+1]={font=font,original=original,index=n};moved[font]=true
   end
  end
 end
 if not state.indicator then
  local f=CreateFrame('Frame',nil,tip);state.indicator=f;f:EnableMouse(false)
  f.text=A.UI.Widgets.Label(f,'','GameFontHighlightSmall');f.text:SetAllPoints(f)
 end
 local f=state.indicator;f:ClearAllPoints();f:SetPoint('TOPLEFT',title,'BOTTOMLEFT',0,-3)
 f:SetWidth(math.max(100,width-20));f.text:SetWidth(math.max(100,width-20));f.text:SetText(model.text)
 local extra=math.ceil(f.text:GetStringHeight())+6;f:SetHeight(extra-3)
 for _,entry in ipairs(entries) do
  local shifted={}
  for n,p in ipairs(entry.original) do
   local relative=p[2];if type(relative)=='string' then relative=_G[relative] end
   shifted[n]={p[1],p[2],p[3],p[4],p[5]-(moved[relative] and 0 or extra)}
  end
  entry.applied=shifted
 end
 state.layout={entries=entries,height=height,extra=extra}
 for _,entry in ipairs(entries) do set(entry.font,entry.applied) end
 tip:SetHeight(height+extra);f:Show();return true
end
return U
