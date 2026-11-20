local A=FWC
local S={};A.Services.LootScore=S
local function finite(n) return A.Compat.Readable(n) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function api()
 local f=ForeverLevelingBiS_API
 if type(f)=='table' and finite(f.version) and f.version>=2 and type(f.ScoreItem)=='function' and type(f.GetSpec)=='function' then return f end
end
function S.Init()
 local f=api();if not f or S.registered==f or type(f.OnChanged)~='function' then return end
 if not (C_Timer and type(C_Timer.After)=='function') and not S.timerFrame then S.timerFrame=CreateFrame('Frame') end
 local ok=pcall(f.OnChanged,function()
  if S.queued then return end
  -- OnChanged may fire while another addon is constructing its tooltip. Refresh
  -- after that stack unwinds; never rebuild the native item tooltip here.
  S.queued=true
  local function refresh()
   S.queued=false
   if A.UI.LootIndicator then local success,err=pcall(A.UI.LootIndicator.Refresh);if not success then A:Log('Loot score refresh: '..tostring(err)) end end
  end
  if C_Timer and type(C_Timer.After)=='function' then C_Timer.After(0,refresh)
  else S.timerFrame:SetScript('OnUpdate',function(frame) frame:SetScript('OnUpdate',nil);refresh() end) end
 end)
 if ok then S.registered=f end
end
function S.Compare(link,current,slot)
 local f=api();if not f then return nil,'Forever Leveling BiS API v2 no disponible' end
 S.Init()
 local ok,spec,setup,class=pcall(f.GetSpec)
 local _,playerClass=A.Compat.Call(UnitClass,'player')
 if not ok or type(spec)~='string' or type(setup)~='string' or class~=playerClass then return nil,'Perfil de Forever Leveling BiS pendiente' end
 if type(link)~='string' or type(current)~='string' then return nil,'Enlaces de equipo pendientes' end
 if slot=='MainHand' then
  local a,b=A.Compat.ItemInfo(current),A.Compat.ItemInfo(link)
  local wasTwo=a.equipLoc=='INVTYPE_2HWEAPON';local isTwo=b.equipLoc=='INVTYPE_2HWEAPON'
  if not a.equipLoc or not b.equipLoc or wasTwo~=isTwo or isTwo and setup~='twohand' or not isTwo and setup=='twohand' then return nil,'Cambio de configuración de armas: compara el conjunto completo' end
 end
 -- Score each ACTUALLY equipped slot, not GetGain's optional Equipment Manager
 -- comparison set. Keep suffix/enchantment fields and the off-hand context.
 local offHand=slot=='OffHand'
 local a,b,loadingA,loadingB
 ok,a,loadingA=pcall(f.ScoreItem,current,offHand)
 if not ok or loadingA==true or not finite(a) then return nil,'Puntuación equipada pendiente' end
 ok,b,loadingB=pcall(f.ScoreItem,link,offHand)
 if not ok or loadingB==true or not finite(b) then return nil,'Puntuación del objeto pendiente' end
 local absolute=b-a;if not finite(absolute) then return nil,'Puntuación inválida' end
 local percent=a>0 and absolute/a*100 or nil
 if percent and not finite(percent) then percent=nil end
 return {before=a,after=b,absolute=absolute,delta=percent,provider='flb',source='Forever Leveling BiS',spec=spec,setup=setup}
end
return S
