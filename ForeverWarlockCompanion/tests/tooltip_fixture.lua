-- Named native-tooltip lines with independently anchored left/right columns.
-- Simulates layout contracts only; does not reproduce the WoW tooltip engine.
local F={}
function F.Attach(tip,name,rows)
 tip.nativeRows=rows or {'Native item name','Other addon footer'}
 tip.GetName=function() return name end;tip.lines=0;tip.NumLines=function(self) return self.lines end
 tip:SetSize(360,100)
 tip.AddLine=function(self,text)
  self.lines=self.lines+1
  for _,side in ipairs({'Left','Right'}) do
   local key=name..'Text'..side..self.lines;local font=_G[key] or self:CreateFontString(nil,'OVERLAY',self.lines==1 and 'GameFontNormal' or 'GameFontHighlightSmall');_G[key]=font
   font:ClearAllPoints();font:SetPoint('TOPLEFT',self,'TOPLEFT',side=='Left' and 10 or 250,-10-(self.lines-1)*18)
   font:SetSize(side=='Left' and self:GetWidth()-20 or 100,16);font:SetText(side=='Left' and text or '')
  end
  if not self.nativeBuilding then self:SetHeight(self:GetHeight()+18) end
 end
 tip.PaintNative=function(self,link)
  local old=self.lines;self.lines=0;self.link=link;self.nativeBuilding=true
  for _,text in ipairs(self.nativeRows) do self:AddLine(text) end
  self.nativeBuilding=false;self:SetHeight(20+#self.nativeRows*18)
  for n=self.lines+1,old do for _,side in ipairs({'Left','Right'}) do local font=_G[name..'Text'..side..n];if font then font:SetText('') end end end
 end
 tip.SetHyperlink=tip.PaintNative
 return tip
end
return F
