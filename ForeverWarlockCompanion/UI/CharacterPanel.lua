local A=FWC
local G={};A.UI.CharacterPanel=G
function G.Create(parent)
    local W=A.UI.Widgets;local f=CreateFrame("Frame",nil,parent);f:SetAllPoints(parent)
    f.left=W.Panel(f);f.left:SetPoint("TOPLEFT");f.left:SetPoint("BOTTOMLEFT")
    f.heading=W.Label(f.left,"TARGET EQUIPMENT","GameFontNormal");f.heading:SetPoint("TOPLEFT",12,-12)
    f.list=W.List(f.left,92);f.list:SetPoint("TOPLEFT",10,-38);f.list:SetPoint("BOTTOMRIGHT",-26,10)
    f.model=A.UI.ModelViewer.Create(f);f.details=A.UI.ItemDetails.Create(f)
    f.basic=W.Label(f.model,'');f.basic:SetPoint('BOTTOMLEFT',12,10);f.basic:SetPoint('BOTTOMRIGHT',-12,10);f.basic:SetHeight(20)
    f.alternatives=f.details.alternatives
    f:SetScript("OnSizeChanged",function(self,width)
        self.left:Hide()
        local center=math.max(282,math.floor(width*.51))
        self.model:ClearAllPoints();self.model:SetPoint('TOPLEFT');self.model:SetPoint('BOTTOMLEFT');self.model:SetWidth(center)
        self.details:ClearAllPoints();self.details:SetPoint('TOPLEFT',self.model,'TOPRIGHT',12,0);self.details:SetPoint('BOTTOMRIGHT')
    end)
    G.frame=f;return f
end
function G.Render()
    local f=G.frame;local W=A.UI.Widgets
    f.list:Render(A.Data.slots,function(row,slot)
        local item=A.Services.Catalog.Target(slot.key)
        if not row.icon then row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetSize(32,32);row.icon:SetPoint("TOPLEFT",8,-8) end
        row.icon:SetTexture(item and item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.title:ClearAllPoints();row.title:SetPoint("TOPLEFT",48,-7);row.title:SetPoint("TOPRIGHT",-8,-7);row.title:SetHeight(50)
        row.title:SetText(slot.label.."\n"..(item and (W.Color(item)..item.name.."|r") or "No imported target"))
        row.sub:SetHeight(16);row.sub:SetText(A.db.mode.." | "..A.Services.Inventory.Status(item)..(item and A.Services.Persistence.Profile().obtained[item.id] and " | Obtained*" or ""))
        W.Active(row,A.UI.selectedSlot==slot.key)
        row:SetScript("OnClick",function()
            A.UI.selectedItem=nil;A.UI.SetTab('Character & Gear',{slot=slot.key})
        end)
        W.Tooltip(row,function() return item and item.id end)
    end)
    local slot=A.UI.selectedSlot or "Head"
    local item=A.UI.selectedItem and A.Data.items[A.UI.selectedItem] or A.Services.Catalog.Target(slot)
    if item and not A.Services.Catalog.Contains(slot,item.id) then item=A.Services.Catalog.Target(slot) end
    f.alternatives:SetText(item and ('Alternatives: '..item.name) or 'Alternatives: no data')
    A.UI.ItemDetails.Render(f.details,slot,item)
    local stats=A.Services.ItemStats;local before=stats.Equipped(slot);local after=stats.Candidate(item);local parts={}
    for _,entry in ipairs({{'ITEM_MOD_INTELLECT_SHORT','Int'},{'ITEM_MOD_STAMINA_SHORT','Sta'},{'ITEM_MOD_SPELL_POWER_SHORT','SP'}}) do
        local value=stats.Delta(before,after,entry[1]);if value then parts[#parts+1]=entry[2]..' '..string.format('%+g',value) end
    end
    f.basic:SetText(#parts>0 and table.concat(parts,' · ') or ('Data: '..before.state..' / '..after.state..' · Inspect Stats'))
    A.UI.ModelViewer.Apply(false)
    A.UI.ModelViewer.UpdateEquipment()
end
