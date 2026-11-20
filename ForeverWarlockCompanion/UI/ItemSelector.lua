local A=FWC
local E={};A.UI.ItemSelector=E
function E.Create(parent)
    local W=A.UI.Widgets;local f=CreateFrame("Frame",nil,parent);f:SetAllPoints(parent)
    f.left=W.Panel(f);f.left:SetPoint("TOPLEFT");f.left:SetPoint("BOTTOMLEFT")
    f.searchTitle=W.Label(f.left,"Search name");f.searchTitle:SetPoint("TOPLEFT",12,-10)
    f.search=W.Edit(f.left,function(value) A.UI.search=value;E.Render() end);f.search:SetPoint("TOPLEFT",12,-28);f.search:SetPoint("TOPRIGHT",-12,-28)
    f.slot=W.Menu(f.left,"All slots",function()
        local choices={{label="All slots",value="All slots"}}
        for _,s in ipairs(A.Data.slots) do choices[#choices+1]={label=s.label,value=s.key} end;return choices
    end,function(value) A.UI.explorerSlot=value;A.UI.selectedItem=nil;E.Render() end)
    f.slot:SetPoint("TOPLEFT",12,-62)
    f.source=W.Menu(f.left,"All sources",function()
        local set={};local choices={"All sources"}
        for _,row in ipairs(A.Services.Catalog.Filter("All slots")) do set[row.item.sourceType]=true end
        for source in pairs(set) do choices[#choices+1]=source end;table.sort(choices);return choices
    end,function(value) A.UI.source=value;E.Render() end)
    f.source:SetPoint("TOPRIGHT",-12,-62)
    f.list=W.List(f.left,122);f.list:SetPoint("TOPLEFT",12,-104);f.list:SetPoint("BOTTOMRIGHT",-28,64)
    f.empty=W.Label(f.left,"");f.empty:SetPoint("TOPLEFT",20,-114);f.empty:SetPoint("TOPRIGHT",-20,-114)
    f.note=W.Button(f.left,"Open item details >",function() if f.details.item then A.UI.SetTab('Item Details',{slot=f.details.slot,itemId=f.details.item.id}) end end);f.note:SetPoint("BOTTOMLEFT",12,12);f.note:SetPoint("BOTTOMRIGHT",-12,12)
    f.details=A.UI.ItemDetails.Create(f)
    f.credit=W.Label(f.left,'Data from ForeverDB.net · https://foreverdb.net');f.credit:SetPoint('BOTTOMLEFT',12,42);f.credit:SetPoint('BOTTOMRIGHT',-12,42);f.credit:SetHeight(18)
    E.filters=E.filters or {}
    f.advanced=W.Button(f.left,'Filters +',function() E.expanded=not E.expanded;E.Render() end);f.advanced:SetSize(100,22);f.advanced:SetPoint('TOPRIGHT',-12,-3)
    f.extra={}
    f.extra[1]=W.Menu(f.left,'Quality',{{label='Any quality',value='Any'},{label='Common',value=1},{label='Uncommon',value=2},{label='Rare',value=3},{label='Epic',value=4}},function(v) E.filters.quality=v;E.Render() end)
    f.extra[2]=W.Menu(f.left,'Ownership',{'Any ownership','Owned','Missing','Unchecked'},function(v) E.filters.ownership=v;E.Render() end)
    f.extra[3]=W.Menu(f.left,'Profession',A.Data.professionChoices,function(v) E.filters.profession=v;E.Render() end)
    f.extra[4]=W.Menu(f.left,'Dungeon',function()
        local seen,rows={}, {'Any dungeon'}
        for _,entry in ipairs(A.Services.Catalog.Filter('All slots')) do if A.Services.Acquisition.Kind(entry.item)=='Dungeon' then seen[entry.item.sourceType]=true end end
        for name in pairs(seen) do rows[#rows+1]=name end;return rows
    end,function(v) E.filters.dungeon=v;E.Render() end)
    f:SetScript("OnSizeChanged",function(self,width)
        self.left:SetWidth(math.floor(width*.56));self.slot:SetWidth(self.left:GetWidth()*.44);self.source:SetWidth(self.left:GetWidth()*.44)
        self.details:ClearAllPoints();self.details:SetPoint("TOPLEFT",self.left,"TOPRIGHT",10,0);self.details:SetPoint("BOTTOMRIGHT")
        for i,b in ipairs(self.extra) do local col=(i-1)%2;b:ClearAllPoints();b:SetPoint(col==0 and 'TOPLEFT' or 'TOPRIGHT',col==0 and 12 or -12,-104-math.floor((i-1)/2)*34);b:SetWidth(self.left:GetWidth()*.44) end
    end)
    E.frame=f;return f
end
function E.Render()
    local f=E.frame;if not f then return end
    local W=A.UI.Widgets;local slot=A.UI.explorerSlot or "All slots"
    f.slot:SetText(A.Data.slotByKey[slot] and A.Data.slotByKey[slot].label or slot);f.source:SetText(A.UI.source or "All sources")
    local rows=A.Services.Catalog.Filter(slot,A.UI.search,A.UI.source)
    local filtered={};local filter=E.filters
    for _,entry in ipairs(rows) do
        local item=entry.item;local state=A.Services.Inventory.Status(item)
        local owned=state=='Equipped' or state=='In bags' or A.Services.Persistence.Profile().obtained[item.id]
        if (not filter.quality or filter.quality=='Any' or filter.quality==item.quality)
            and (not filter.profession or filter.profession=='Any profession' or (item.sourceType=='Crafted' and item.source==filter.profession))
            and (not filter.dungeon or filter.dungeon=='Any dungeon' or item.sourceType==filter.dungeon)
            and (not filter.ownership or filter.ownership=='Any ownership' or (filter.ownership=='Owned' and owned) or (filter.ownership=='Missing' and state=='Not found' and not owned) or (filter.ownership=='Unchecked' and state=='Unchecked')) then filtered[#filtered+1]=entry end
    end
    rows=filtered
    f.advanced:SetText(E.expanded and 'Filters −' or 'Filters +')
    for _,b in ipairs(f.extra) do b:SetShown(E.expanded==true) end
    f.extra[1]:SetText('Quality: '..tostring(filter.quality or 'Any'));f.extra[2]:SetText(filter.ownership or 'Any ownership');f.extra[3]:SetText(filter.profession or 'Any profession');f.extra[4]:SetText(filter.dungeon or 'Any dungeon')
    f.list:ClearAllPoints();f.list:SetPoint('TOPLEFT',12,E.expanded and -182 or -104);f.list:SetPoint('BOTTOMRIGHT',-28,64)
    f.empty:SetText(#rows==0 and "No candidates match these filters.\n\nOnly Affliction Pre-BiS has imported data. Clear the search / source filter, or switch catalog." or "")
    f.list:Render(rows,function(row,entry,index)
        local item=entry.item
        if not row.itemIcon then row.itemIcon=row:CreateTexture(nil,"ARTWORK");row.itemIcon:SetSize(42,42);row.itemIcon:SetPoint("TOPLEFT",8,-8) end
        local guide=A.Services.ItemGuide
        row.itemIcon:SetTexture(A.Compat.ItemInfo(item.id).icon or guide.Icon(item))
        row.title:ClearAllPoints();row.title:SetPoint("TOPLEFT",58,-7);row.title:SetPoint("TOPRIGHT",-8,-7)
        row.sub:ClearAllPoints();row.sub:SetPoint("TOPLEFT",58,-41);row.sub:SetPoint("TOPRIGHT",-8,-41);row.sub:SetHeight(70)
        row.title:SetText(W.Color(item)..item.name.."|r")
        if A.Services.ItemInspector.IsPilot(item) then
            if not row.rating then row.rating=W.Label(row,'','GameFontNormal');row.rating:SetPoint('TOPRIGHT',-8,-9);row.rating:SetSize(85,22);row.rating:SetJustifyH('RIGHT') end
            row.rating:Show();row.title:SetPoint('TOPRIGHT',-96,-7)
            row.ratingState=A.UI.ItemInspector.PaintRating(row.rating,A.Services.UpgradeComparison.ForSlot(entry.slot,item))
        elseif row.rating then row.rating:Hide();row.ratingState=nil end
        local target=A.Services.Catalog.Target(entry.slot)
        row.sub:SetText(guide.Summary(item,3)..'\n'..guide.ShortSource(item)..'\n'..A.Services.Inventory.Status(item)..(target and target.id==item.id and ' · Objetivo' or '')..' · '..guide.ScoreLabel(entry.slot,item))
        W.Active(row,A.UI.selectedItem==item.id and A.UI.selectedSlot==entry.slot)
        row:SetScript("OnClick",function() A.UI.selectedSlot=entry.slot;A.UI.selectedItem=item.id;E.Render() end)
        W.Tooltip(row,function() return item.id end)
    end)
    local selectedSlot=A.UI.selectedSlot or (slot~="All slots" and slot) or "Head"
    local item=A.UI.selectedItem and A.Data.items[A.UI.selectedItem] or A.Services.Catalog.Target(selectedSlot)
    if item and not A.Services.Catalog.Contains(selectedSlot,item.id) then item=nil end
    A.UI.ItemDetails.Render(f.details,selectedSlot,item)
end
