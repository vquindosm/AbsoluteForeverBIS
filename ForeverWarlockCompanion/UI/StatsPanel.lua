local A=FWC
local S={};A.UI.StatsPanel=S
function S.Create(parent)
 local W=A.UI.Widgets;local f=W.Panel(parent);f:SetAllPoints(parent);S.frame=f;f.rows={}
 f.slot=W.Menu(f,'Ranura',function() local choices={};for _,s in ipairs(A.Data.slots) do choices[#choices+1]={label=s.label,value=s.key} end;return choices end,function(key) A.UI.selectedSlot=key;S.candidate=nil;S.Render() end)
 f.slot:SetSize(190,26);f.slot:SetPoint('TOPLEFT',14,-12)
 f.candidate=W.Menu(f,'Objetivo / alternativa',function()
  local rows={};for _,id in ipairs(A.Services.Catalog.List(A.db.viewClass,A.db.spec,A.db.mode,A.UI.selectedSlot or 'Head')) do local item=A.Data.items[id];rows[#rows+1]={label=item.name,value=id} end
  if #rows==0 then rows[1]={label='Sin candidatos importados',value=0} end;return rows
 end,function(id) S.candidate=id~=0 and id or nil;S.Render() end)
 f.candidate:SetPoint('TOPLEFT',f.slot,'TOPRIGHT',10,0);f.candidate:SetPoint('TOPRIGHT',-14,-12)
 f.items=W.Label(f,'');f.items:SetPoint('TOPLEFT',14,-48);f.items:SetPoint('TOPRIGHT',-14,-48);f.items:SetHeight(36)
 f.headers={};for i,label in ipairs({'Estadística del objeto','Equipado','Candidato','Diferencia','Peso EP / punto'}) do f.headers[i]=W.Label(f,label,'GameFontNormal') end
 f.scroll=W.Scroll(f);f.scroll:SetPoint('TOPLEFT',14,-110);f.scroll:SetPoint('BOTTOMRIGHT',-30,118)
 f.result=W.Label(f,'');f.result:SetPoint('BOTTOMLEFT',14,48);f.result:SetPoint('BOTTOMRIGHT',-14,48);f.result:SetHeight(59)
 f.save=W.Button(f,'Guardar pesos',function() S.Save() end);f.save:SetSize(150,26);f.save:SetPoint('BOTTOMLEFT',14,12)
 f.choose=W.Button(f,'Usar como objetivo',function() if S.candidate and A.Services.Catalog.Select(A.UI.selectedSlot or 'Head',S.candidate) then S.notice='Target saved';A:Refresh() end end);f.choose:SetSize(170,26);f.choose:SetPoint('LEFT',f.save,'RIGHT',10,0)
 f.refresh=W.Button(f,'Actualizar datos',function() A.Services.ItemStats.Invalidate(nil,true);A.Services.Inventory.Scan();S.notice='Data refresh requested';S.Render() end);f.refresh:SetSize(150,26);f.refresh:SetPoint('LEFT',f.choose,'RIGHT',10,0)
 f:SetScript('OnSizeChanged',function() S.Layout() end)
 return f
end
local columns={0,.36,.49,.62,.77}
function S.Layout()
 local f=S.frame;if not f then return end
 local width=math.max(100,f:GetWidth()-44)
 for i,label in ipairs(f.headers) do label:ClearAllPoints();label:SetPoint('TOPLEFT',14+width*columns[i],-90) end
 for _,row in ipairs(f.rows) do
  row:SetWidth(width)
  for i,label in ipairs(row.cells) do label:ClearAllPoints();label:SetPoint('TOPLEFT',width*columns[i],-6);label:SetWidth(width*(i==1 and .34 or .12));label:SetHeight(30) end
  row.edit:ClearAllPoints();row.edit:SetPoint('TOPLEFT',width*.77,-2);row.edit:SetWidth(width*.2)
 end
end
function S.Save()
 local f=S.frame;local p=A.Services.Persistence.Profile();local values,err=A.Services.ItemStats.Weights(p.epWeights)
 if not values then f.result:SetText(err);return false end
 for _,row in ipairs(f.rows) do
  if row:IsShown() then
   local text=row.edit:GetText():match('^%s*(.-)%s*$')
   local value=tonumber(text)
   if text~='' and (not value or value~=value or math.abs(value)>100000) then f.result:SetText('Peso inválido: '..row.label);return false end
   values[row.key]=text~='' and value or nil
  end
 end
 p.epWeights=values;local keys={};for key in pairs(values) do keys[#keys+1]=key end;table.sort(keys)
 local parts={};for _,key in ipairs(keys) do parts[#parts+1]=key..'='..values[key] end;p.epWeightsText=table.concat(parts,',')
 A.UI.Supporting.settings.weightProfile=nil
 S.profile=nil;S.notice='Weights saved';A:Refresh();return true
end
function S.Render()
 local f=S.frame;if not f then return end
 local p=A.Services.Persistence.Profile();local normalizedWeights=A.Services.ItemStats.Weights(p.epWeights) or {};local changed=S.profile~=p;S.profile=p
 local slot=A.UI.selectedSlot or 'Head';local target=A.Services.Catalog.Target(slot)
 if not A.Data.slotByKey[slot] then
  f.items:SetText('Unknown legacy slot: '..tostring(slot));f.result:SetText('Select a valid slot to compare. The legacy objective is retained.');f.choose:SetEnabled(false)
  for _,row in ipairs(f.rows) do row:Hide() end;f.scroll.content:SetHeight(1);f.scroll:UpdateRange();return
 end
 if not S.candidate or not A.Services.Catalog.Contains(slot,S.candidate) then S.candidate=target and target.id end
 local item=S.candidate and A.Data.items[S.candidate]
 local eq=A.Services.Inventory.snapshot.equipped[slot]
 local current=eq and eq.id and A.Compat.ItemInfo(eq.link or eq.id) or {}
 local nextItem=item and A.Compat.ItemInfo(item.id) or {}
 local stats=A.Services.ItemStats;local before=stats.Equipped(slot);local after=stats.Candidate(item)
 f.slot:SetText(A.Data.slotByKey[slot].label);f.candidate:SetText(item and item.name or 'Sin objetivo / catálogo')
 f.items:SetText('Equipado: '..(current.name or (eq and eq.id and ('#'..eq.id) or 'Vacío / sin comprobar'))..'\nCandidato: '..(item and item.name or 'Ninguno'))
 f.choose:SetEnabled(item~=nil)
 local data=stats.Keys(before,after,p.epWeights)
 for i,entry in ipairs(data) do
  local row=f.rows[i]
  if not row then
   row=CreateFrame('Frame',nil,f.scroll.content);row.cells={};for col=1,4 do row.cells[col]=A.UI.Widgets.Label(row,'') end
   row.edit=A.UI.Widgets.Edit(row);f.rows[i]=row
  end
  local newKey=row.key~=entry.key
  row.key=entry.key;row.label=entry.label;row:SetHeight(40);row:ClearAllPoints();row:SetPoint('TOPLEFT',0,-(i-1)*40);row:Show()
  row.cells[1]:SetText(entry.label)
  row.cells[2]:SetText(stats.Display(before,entry.key))
  row.cells[3]:SetText(stats.Display(after,entry.key))
  local delta,reason=stats.Delta(before,after,entry.key);row.cells[4]:SetText(delta and string.format('%+g',delta) or reason)
  if changed or newKey then row.edit:SetText(normalizedWeights[entry.key]~=nil and tostring(normalizedWeights[entry.key]) or '') end
 end
 for i=#data+1,#f.rows do f.rows[i]:Hide() end
 f.scroll.content:SetHeight(math.max(1,#data*40));S.Layout();f.scroll:UpdateRange()
 local score,reason=A.Services.Planner.SlotScore(slot,item)
 f.result:SetText((S.notice and (S.notice..' · ') or '')..(score and string.format('EP estimado: %.1f → %.1f (%+.1f%%). No es DPS.',score.before,score.after,score.delta) or ('Rating unavailable: '..((before.state=='confirmed' and after.state=='confirmed') and reason or 'Client data incomplete.')))..'\nEquipped: '..before.state..' · Planned: '..after.state..' · Not present ≠ 0. * = offline reference; no EP. Diagnostics in Settings.'..(after.fallbackSource and '\nData: ForeverDB.net · https://foreverdb.net' or ''))
end
