local A=FWC
local N={history={},context={},filters={}};A.Services.Navigation=N
local fields={'selectedSlot','selectedItem','explorerSlot','source','search'}
function N.Capture()
 local view={route=A.UI.tab,context=A.Services.Persistence.Copy(N.context),fields={}}
 for _,key in ipairs(fields) do view.fields[key]=A.UI[key] end
 return view
end
function N.Go(route,context,replace)
 if not replace and A.UI.tab and (A.UI.tab~=route or context) then
  N.history[#N.history+1]=N.Capture();if #N.history>24 then table.remove(N.history,1) end
 end
 N.context=context or {};A.UI.tab=route
 if context then
  if context.slot then A.UI.selectedSlot=context.slot end
  if context.itemId then A.UI.selectedItem=context.itemId end
 end
 if A.db then A.db.lastRoute=route end
 if A.UI.menu then A.UI.menu:Hide() end
 A:Refresh()
end
function N.Back()
 local view=table.remove(N.history);if not view then return end
 for _,key in ipairs(fields) do A.UI[key]=view.fields[key] end
 N.Go(view.route,view.context,true)
end
function N.Breadcrumb()
 local parts={A.UI.tab or 'Dashboard'}
 if N.context.slot then parts[#parts+1]=A.Data.slotByKey[N.context.slot] and A.Data.slotByKey[N.context.slot].label or N.context.slot end
 if N.context.itemId then local item=A.Data.items[N.context.itemId];if item then parts[#parts+1]=item.name end end
 return table.concat(parts,'  >  ')
end
