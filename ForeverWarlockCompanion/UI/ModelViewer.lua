local A=FWC
local W
local V={mode="Current",rotation=0,zoom=.35};A.UI.ModelViewer=V
function V.Create(parent)
    W=A.UI.Widgets;local f=A.UI.DesignSystem.Card(parent);V.frame=f
    local heading=W.Label(f,"Equipped items","GameFontNormal");heading:SetPoint("TOPLEFT",14,-12);V.heading=heading
    local ok,model=pcall(CreateFrame,"DressUpModel",nil,f)
    if not ok or not model or type(model.SetUnit)~="function" then ok,model=pcall(CreateFrame,"PlayerModel",nil,f) end
    if ok and model and type(model.SetUnit)=="function" then
        V.model=model;model:SetPoint("TOPLEFT",48,-42);model:SetPoint("BOTTOMRIGHT",-48,144)
        model:EnableMouse(true);model:EnableMouseWheel(true)
        local function dragUpdate()
            if V.dragX then
                if type(IsMouseButtonDown)=="function" and not IsMouseButtonDown("LeftButton") then V.dragX=nil;model:SetScript("OnUpdate",nil);return end
                local x=A.Compat.Call(GetCursorPosition)
                if x then V.Rotate((x-V.dragX)*.012);V.dragX=x end
            end
        end
        model:SetScript("OnMouseDown",function(_,button) if button=="LeftButton" then V.dragX=A.Compat.Call(GetCursorPosition);model:SetScript("OnUpdate",dragUpdate) end end)
        model:SetScript("OnMouseUp",function() V.dragX=nil;model:SetScript("OnUpdate",nil) end)
        model:SetScript("OnMouseWheel",function(_,delta) V.Zoom(delta*.08) end)
    end
    V.status=W.Label(f,"");V.status:SetPoint("BOTTOMLEFT",14,111);V.status:SetPoint("BOTTOMRIGHT",-14,111);V.status:SetHeight(28)
    local current=W.Button(f,"Current",function() V.mode="Current";V.Apply(true) end);current:SetPoint("BOTTOMLEFT",12,76);current:SetWidth(105)
    local planned=W.Button(f,"Planned",function() V.mode="Planned";V.Apply(true) end);planned:SetPoint("LEFT",current,"RIGHT",8,0);planned:SetPoint("RIGHT",f,"RIGHT",-12,0)
    local restore=W.Button(f,"Restore actual appearance",function() V.mode="Current";V.Apply(true) end);restore:SetPoint("BOTTOMLEFT",12,42);restore:SetPoint("BOTTOMRIGHT",-12,42)
    local controls={{"<",function() V.Rotate(-.3) end},{">",function() V.Rotate(.3) end},{"+",function() V.Zoom(.08) end},{"-",function() V.Zoom(-.08) end}}
    for i,control in ipairs(controls) do local b=W.Button(f,control[1],control[2]);b:SetSize(38,23);b:SetPoint("BOTTOMLEFT",f,"BOTTOM",-82+(i-1)*43,146) end
    V.currentButton=current;V.plannedButton=planned
    V.equipment={}
    for i,slot in ipairs(A.Data.slots) do
        local index=i;local button=W.Button(f,"",function()
            A.UI.selectedItem=nil;A.UI.SetTab('Character & Gear',{slot=slot.key})
        end)
        button:SetSize(36,36);button.slot=slot
        button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetPoint("TOPLEFT",2,-2);button.icon:SetPoint("BOTTOMRIGHT",-2,2)
        button.badge=W.Label(button,"","GameFontNormalSmall");button.badge:SetPoint("BOTTOM",0,-10);button.badge:SetWidth(48);button.badge:SetHeight(12);button.badge:SetJustifyH("CENTER")
        button:SetScript('OnEnter',function(self)
            local eq=A.Services.Inventory.snapshot.equipped[slot.key]
            if V.mode=='Planned' then local item=A.Services.Catalog.Target(slot.key);if item then A.Compat.Tooltip(self,item.id) end;return end
            if GameTooltip and eq and eq.id then
                A.Compat.Method(GameTooltip,'SetOwner',self,'ANCHOR_RIGHT')
                if not A.Compat.Method(GameTooltip,'SetInventoryItem','player',slot.inventory) then A.Compat.Tooltip(self,eq.link or eq.id) else A.Compat.Method(GameTooltip,'Show') end
                A.Compat.Method(GameTooltip,'AddLine','Stats: '..A.Services.ItemStats.Describe(A.Services.ItemStats.Equipped(slot.key)));A.Compat.Method(GameTooltip,'Show')
            end
        end)
        button:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
        V.equipment[index]=button
    end
    f:SetScript('OnSizeChanged',function(self,width,height)
        local pitch=math.max(35,math.min(52,(height-184)/8));local size=math.min(42,pitch-12)
        local left={Head=1,Neck=2,Shoulders=3,Back=4,Chest=5,Wrists=6}
        local right={Hands=1,Waist=2,Legs=3,Feet=4,Ring1=5,Ring2=6,Trinket1=7,Trinket2=8}
        local weapons={MainHand=1,OffHand=2,Ranged=3}
        for _,button in ipairs(V.equipment) do
            local slot=button.slot.key;button:ClearAllPoints();button:SetSize(size,size)
            if left[slot] then button:SetPoint('TOPLEFT',12,-44-(left[slot]-1)*pitch)
            elseif right[slot] then button:SetPoint('TOPRIGHT',-12,-44-(right[slot]-1)*pitch)
            else button:SetPoint('BOTTOM',self,'BOTTOM',(weapons[slot]-2)*58,182) end
        end
    end)
    return f
end
function V.UpdateEquipment()
    for i,slot in ipairs(A.Data.slots) do
        local b=V.equipment and V.equipment[i]
        if b then
            local eq=A.Services.Inventory.snapshot.equipped[slot.key]
            local item=eq and eq.id and A.Compat.ItemInfo(eq.link or eq.id)
            local nativeIcon=A.Compat.Call(GetInventoryItemTexture,'player',slot.inventory)
            local target=A.Services.Catalog.Target(slot.key)
            b.icon:SetTexture(V.mode=='Planned' and target and target.icon or nativeIcon or (item and item.icon) or "Interface\\Icons\\INV_Misc_QuestionMark")
            local score=target and A.Services.Planner.SlotScore(slot.key,target)
            b.badge:SetText(score and string.format('%+.0f%%',score.delta) or (eq and eq.id and target and eq.id==target.id and '=' or '—'))
            local data=A.Services.ItemStats.Equipped(slot.key);b.dataState=data.state
        end
    end
end
function V.Rotate(delta)
    V.rotation=V.rotation+delta
    if not A.Compat.Method(V.model,"SetRotation",V.rotation) and not A.Compat.Method(V.model,"SetFacing",V.rotation) then
        V.status:SetText("Rotation unavailable on this client.")
    end
end
function V.Zoom(delta)
    V.zoom=math.max(0,math.min(1,V.zoom+delta))
    if not A.Compat.Method(V.model,"SetPortraitZoom",V.zoom) then V.status:SetText("Zoom unavailable on this client.") end
end
function V.Try(item,slot)
    if not V.model or type(V.model.TryOn)~="function" then return false,"Preview API unavailable" end
    local hand=slot=="OffHand" and "SECONDARYHANDSLOT" or slot=="MainHand" and "MAINHANDSLOT" or nil
    local ok,result=A.Compat.Method(V.model,"TryOn","item:"..item.id,hand)
    if not ok then return false,"Preview rejected by client" end
    local reasons=Enum and Enum.ItemTryOnReason
    if result~=nil and (not reasons or result~=reasons.Success) then return false,"Client TryOn result: "..tostring(result) end
    return true
end
function V.Apply(reset)
    if not V.frame then return end
    V.heading:SetText(V.mode=='Planned' and 'Target equipment preview' or 'Equipped items');V.UpdateEquipment()
    W.Active(V.currentButton,V.mode=="Current");W.Active(V.plannedButton,V.mode=="Planned")
    if not V.model then V.status:SetText("Native character model unavailable. Gear planning remains available.");return end
    local signature={V.mode}
    for _,slot in ipairs(A.Data.slots) do
        local eq=A.Services.Inventory.snapshot.equipped[slot.key]
        local target=V.mode=="Planned" and A.Services.Catalog.Target(slot.key)
        signature[#signature+1]=tostring(eq and eq.id or 0)..":"..tostring(target and target.id or 0)
    end
    signature=table.concat(signature,"|")
    if not reset and V.signature==signature then return end
    V.signature=signature
    reset=true
    if reset then
        V.loading=true
        local ok=A.Compat.Method(V.model,"SetUnit","player")
        A.Compat.Method(V.model,"Dress");V.loading=false
        if not ok then V.status:SetText("Player model could not load on this client.");return end
    end
    V.Rotate(0)
    if V.mode=="Current" then V.status:SetText("Actual appearance. Drag to rotate; wheel to zoom if supported.");return end
    local failed=0;local tried=0
    for _,slot in ipairs(A.Data.slots) do
        local item=A.Services.Catalog.Target(slot.key)
        if item then tried=tried+1;if not V.Try(item,slot.key) then failed=failed+1 end end
    end
    V.status:SetText(tried==0 and "No targets in this catalog." or (failed>0 and (failed.." previews unavailable; other requests sent.") or "Preview requests sent. Jewelry has no visible model; loading depends on client."))
end
function V.Preview(item,slot)
    V.mode="Current";V.Apply(true)
    local ok,reason=V.Try(item,slot)
    V.status:SetText(ok and "Item preview requested; appearance depends on client support." or reason)
    return ok
end
