local A=FWC
local U={};A.UI.UpgradeTooltip=U
local function number(n) return A.Compat.Readable(n) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local classCoords={WARRIOR={0,.25,0,.25},MAGE={.25,.5,0,.25},ROGUE={.5,.75,0,.25},DRUID={.75,1,0,.25},
 HUNTER={0,.25,.25,.5},SHAMAN={.25,.5,.25,.5},PRIEST={.5,.75,.25,.5},WARLOCK={.75,1,.25,.5},PALADIN={0,.25,.5,.75}}
local specIcons={affliction='Spell_Shadow_DeathCoil',demonology='Spell_Shadow_Metamorphosis',destruction='Spell_Shadow_RainOfFire'}
function U.Clear(tip,state)
 if state.indicator then state.indicator:Hide() end
end
local function create(tip)
 local W=A.UI.Widgets;local f=CreateFrame('Frame',nil,tip)
 -- Semantic performance colors stay independent of the main window's theme.
 f.background=W.Fill(f,{.025,.03,.035,.97});f.edges={}
 for _,edge in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
  local t=f:CreateTexture(nil,'BORDER');f.edges[#f.edges+1]=t
  if edge=='TOP' or edge=='BOTTOM' then t:SetHeight(1);t:SetPoint(edge..'LEFT');t:SetPoint(edge..'RIGHT')
  else t:SetWidth(1);t:SetPoint('TOP'..edge);t:SetPoint('BOTTOM'..edge) end
 end
 f:EnableMouse(false);f:SetClampedToScreen(true);f:SetHeight(74)
 f.classIcon=f:CreateTexture(nil,'ARTWORK');f.classIcon:SetSize(32,32);f.classIcon:SetPoint('TOPLEFT',10,-12)
 f.specIcon=f:CreateTexture(nil,'ARTWORK');f.specIcon:SetSize(16,16);f.specIcon:SetPoint('TOPLEFT',52,-10)
 f.identity=W.Label(f,'','GameFontNormal');f.identity:SetPoint('TOPLEFT',74,-8);f.identity:SetPoint('TOPRIGHT',-74,-8);f.identity:SetHeight(28)
 f.rank=W.Label(f,'','GameFontNormal');f.rank:SetPoint('TOPRIGHT',-10,-10);f.rank:SetSize(60,20);f.rank:SetJustifyH('RIGHT')
 f.text=W.Label(f,'','GameFontHighlight');f.text:SetPoint('TOPLEFT',52,-37);f.text:SetPoint('TOPRIGHT',-10,-37);f.text:SetHeight(22)
 f.track=CreateFrame('Frame',nil,f);f.track:SetPoint('BOTTOMLEFT',10,9);f.track:SetPoint('BOTTOMRIGHT',-10,9);f.track:SetHeight(5)
 W.Fill(f.track,{.025,.03,.035,1})
 f.fill=f.track:CreateTexture(nil,'ARTWORK');f.fill:SetHeight(5)
 f.zero=f.track:CreateTexture(nil,'OVERLAY');f.zero:SetSize(1,9);f.zero:SetPoint('CENTER');f.zero:SetColorTexture(.8,.83,.8,.9)
 return f
end
function U.Show(tip,state,model)
 U.Clear(tip,state)
 if not model or A.Compat.Call(tip.IsForbidden,tip)==true or A.Compat.Call(tip.IsProtected,tip)==true then return false end
 local width=A.Compat.Call(tip.GetWidth,tip);if not number(width) or width<=0 then return false end
 local f=state.indicator or create(tip);state.indicator=f
 local screenWidth=A.Compat.Call(UIParent.GetWidth,UIParent)
 f:SetWidth(math.max(180,math.min(math.max(260,width),number(screenWidth) and screenWidth-16 or width)))
 f:ClearAllPoints();f:SetPoint('TOPLEFT',tip,'BOTTOMLEFT',0,-4);f.placement='below'
 local bottom=A.Compat.Call(tip.GetBottom,tip)
 if number(bottom) and bottom<f:GetHeight()+4 then
  local right=A.Compat.Call(tip.GetRight,tip);local left=A.Compat.Call(tip.GetLeft,tip)
  f:ClearAllPoints()
  if number(right) and number(screenWidth) and screenWidth-right>=f:GetWidth()+4 then f:SetPoint('BOTTOMLEFT',tip,'BOTTOMRIGHT',4,0);f.placement='right'
  elseif number(left) and left>=f:GetWidth()+4 then f:SetPoint('BOTTOMRIGHT',tip,'BOTTOMLEFT',-4,0);f.placement='left'
  else return false end -- Never obscure native text to force a card onto a crowded screen.
 end
 local bg=model.upgrade and {.025,.15,.07,.97} or {.18,.035,.035,.97}
 local edge=model.upgrade and {.2,.78,.36,1} or {.9,.22,.22,1}
 f.background:SetColorTexture(unpack(bg));for _,e in ipairs(f.edges) do e:SetColorTexture(unpack(edge)) end
 local coords=classCoords[model.class]
 if coords then
  f.classIcon:SetTexture('Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes');A.Compat.Method(f.classIcon,'SetTexCoord',unpack(coords))
 else f.classIcon:SetTexture('Interface\\Icons\\INV_Misc_Book_09');A.Compat.Method(f.classIcon,'SetTexCoord',0,1,0,1) end
 local key=type(model.spec)=='string' and model.spec:lower() or ''
 f.specIcon:SetTexture('Interface\\Icons\\'..(specIcons[key] or 'INV_Misc_Book_09'))
 f.identity:SetText(model.className..' · '..model.specLabel)
 f.rank:SetText(model.rank and ('|cff'..model.color..model.rank..' BiS|r') or '')
 f.text:SetText('|cff'..model.stateColor..model.gains..'|r')
 f.fill:SetColorTexture(unpack(edge));f.fill:ClearAllPoints()
 f.fill:SetPoint(model.upgrade and 'LEFT' or 'RIGHT',f.track,'CENTER',0,0)
 f.fill:SetWidth(math.max(.01,(f:GetWidth()-20)*.5*math.abs(model.meter)))
 f.model=model;f:Show();return true
end
return U
