local A = FWC
local W = {}; A.UI.Widgets = W
W.colors = {background={.04,.03,.02,1},panel={.075,.061,.048,1},edge={.38,.30,.16,1},accent={.79,.64,.38,1}}
W.panels={};W.buttons={}
function W.Fill(parent, color, layer)
    local t=parent:CreateTexture(nil,layer or "BACKGROUND"); t:SetAllPoints(parent); t:SetColorTexture(unpack(color)); return t
end
function W.Panel(parent,name)
    local f=CreateFrame("Frame",name,parent);f.background=W.Fill(f,W.colors.panel);f.edges={};W.panels[#W.panels+1]=f
    for _, edge in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
        local t=f:CreateTexture(nil,"BORDER"); t:SetColorTexture(unpack(W.colors.edge))
        f.edges[#f.edges+1]=t
        if edge=="TOP" or edge=="BOTTOM" then t:SetHeight(1);t:SetPoint(edge.."LEFT");t:SetPoint(edge.."RIGHT")
        else t:SetWidth(1);t:SetPoint("TOP"..edge);t:SetPoint("BOTTOM"..edge) end
    end
    return f
end
function W.Label(parent,text,font)
    local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
    label:SetJustifyH("LEFT"); label:SetJustifyV("TOP");label:SetText(text or ""); return label
end
function W.Button(parent,text,callback)
    local b=CreateFrame("Button",nil,parent); b:SetHeight(26)
    b.bg=W.Fill(b,W.colors.button or {.13,.105,.08,1});W.buttons[#W.buttons+1]=b
    local highlight=b:CreateTexture(nil,"HIGHLIGHT");highlight:SetAllPoints(b);highlight:SetColorTexture(.72,.56,.29,.20)
    b.label=W.Label(b,text);b.label:SetPoint("LEFT",7,0);b.label:SetPoint("RIGHT",-7,0);b.label:SetJustifyH("CENTER");b.label:SetJustifyV("MIDDLE")
    A.Compat.Method(b.label,"SetWordWrap",false)
    b:SetScript("OnClick",callback)
    function b:SetText(value) self.label:SetText(value) end
    local nativeEnabled=b.SetEnabled
    function b:SetEnabled(enabled)
        nativeEnabled(self,enabled);self.disabled=not enabled
        A.Compat.Method(self.label,'SetTextColor',enabled and 1 or .45,enabled and 1 or .45,enabled and 1 or .45)
        A.Compat.Method(self,'SetAlpha',enabled and 1 or .55)
    end
    return b
end
function W.Active(button,active)
    button.active=active
    button.bg:SetColorTexture(unpack(active and {.29,.24,.15,1} or W.colors.button or {.13,.105,.08,1}))
end
function W.Scroll(parent)
    local viewport=CreateFrame("ScrollFrame",nil,parent);viewport:EnableMouseWheel(true)
    local content=CreateFrame("Frame",nil,viewport);content:SetSize(100,1);viewport:SetScrollChild(content)
    local slider=CreateFrame("Slider",nil,parent);slider:SetWidth(10);slider:SetPoint("TOPLEFT",viewport,"TOPRIGHT",3,0);slider:SetPoint("BOTTOMLEFT",viewport,"BOTTOMRIGHT",3,0)
    slider:SetOrientation("VERTICAL");slider:SetMinMaxValues(0,0);slider:SetValueStep(20);slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    local thumb=slider:GetThumbTexture();if thumb then thumb:SetSize(10,25) end
    W.Fill(slider,{.10,.10,.12,1})
    viewport.content=content;viewport.slider=slider;viewport.offset=0
    function viewport:UpdateRange()
        local limit=math.max(0,self.content:GetHeight()-self:GetHeight())
        self.limit=limit;self.offset=math.min(self.offset,limit)
        self.slider:SetMinMaxValues(0,limit);self.slider:SetValue(self.offset)
        self:SetVerticalScroll(self.offset);self.slider:SetShown(limit>0)
    end
    slider:SetScript("OnValueChanged",function(_,value) viewport.offset=value;viewport:SetVerticalScroll(value) end)
    viewport:SetScript("OnMouseWheel",function(self,delta)
        self.offset=math.max(0,math.min(self.limit or 0,self.offset-delta*50));slider:SetValue(self.offset)
    end)
    viewport:SetScript("OnSizeChanged",function(self,width)
        content:SetWidth(math.max(10,width));if self.reflow then self.reflow() end;self:UpdateRange()
    end)
    return viewport
end
function W.List(parent,rowHeight)
    local scroll=W.Scroll(parent);scroll.rows={};scroll.rowHeight=rowHeight or 48
    function scroll:Render(data,renderer)
        self.data=data
        for index,value in ipairs(data) do
            local row=self.rows[index]
            if not row then
                row=W.Button(self.content,"",nil);row.label:Hide()
                row.title=W.Label(row,"","GameFontHighlight");row.title:SetPoint("TOPLEFT",9,-7);row.title:SetPoint("TOPRIGHT",-8,-7)
                row.sub=W.Label(row,"");row.sub:SetPoint("BOTTOMLEFT",9,6);row.sub:SetPoint("BOTTOMRIGHT",-8,6)
                self.rows[index]=row
            end
            row:SetHeight(self.rowHeight-4);row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-(index-1)*self.rowHeight);row:SetPoint("RIGHT",self.content,"RIGHT",0,0)
            if self.rowHeight>=60 then row.title:SetHeight(34);row.sub:SetHeight(26) end
            row:Show();row:SetScript("OnEnter",nil);row:SetScript("OnLeave",nil);renderer(row,value,index)
        end
        for i=#data+1,#self.rows do self.rows[i]:Hide() end
        self.content:SetHeight(math.max(1,#data*self.rowHeight));self:UpdateRange()
    end
    return scroll
end
function W.TextScroll(parent)
    local scroll=W.Scroll(parent);scroll.text=W.Label(scroll.content, "", "GameFontHighlight")
    scroll.text:SetPoint("TOPLEFT",2,-2)
    scroll.reflow=function()
        scroll.text:SetWidth(math.max(20,scroll:GetWidth()-5))
        scroll.content:SetHeight(math.max(1,scroll.text:GetStringHeight()+12))
    end
    function scroll:SetText(text) self.text:SetText(text);self.reflow();self:UpdateRange() end
    return scroll
end
function W.Menu(parent,label,options,pick)
    local b=W.Button(parent,label,nil);b.options=options;b.pick=pick
    b:SetScript("OnClick",function(self)
        local choices=type(self.options)=="function" and self.options() or self.options
        if A.UI.menu and A.UI.menu.owner==self and A.UI.menu:IsShown() then A.UI.menu:Hide();return end
        if not A.UI.menu then
            local menu=W.Panel(UIParent);menu:SetFrameStrata("TOOLTIP");menu:SetClampedToScreen(true);menu:EnableMouse(true)
            menu.list=W.List(menu,27);menu.list:SetPoint("TOPLEFT",5,-5);menu.list:SetPoint("BOTTOMRIGHT",-19,5)
            A.UI.menu=menu
        end
        local menu=A.UI.menu;menu.owner=self;menu:ClearAllPoints();menu:SetPoint("TOPLEFT",self,"BOTTOMLEFT",0,-3)
        menu:SetSize(math.max(self:GetWidth(),190),math.min(300,#choices*27+10));menu:Show()
        menu.list:Render(choices,function(row,value)
            row.title:SetFontObject("GameFontHighlightSmall");row.title:SetText(type(value)=="table" and value.label or value);row.sub:SetText("")
            row:SetScript("OnClick",function() menu:Hide();self.pick(type(value)=="table" and value.value or value) end)
        end)
    end)
    return b
end
function W.Edit(parent,changed)
    local e=CreateFrame("EditBox",nil,parent);e:SetHeight(26);e:SetAutoFocus(false);e:SetFontObject("GameFontHighlight");e:SetTextInsets(8,8,0,0);W.Fill(e,{.025,.03,.04,1})
    e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    e:SetScript("OnTextChanged",function(self) if changed then changed(self:GetText()) end end)
    return e
end
function W.Tooltip(button,itemFn)
    button:SetScript("OnEnter",function(self) A.Compat.Tooltip(self,itemFn()) end)
    button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end
function W.Color(item)
    local colors={"ff9d9d9d","ffffffff","ff1eff00","ff0070dd","ffa335ee","ffff8000"}
    return "|c"..(colors[(item and item.quality or 1)+1] or "ffffffff")
end
