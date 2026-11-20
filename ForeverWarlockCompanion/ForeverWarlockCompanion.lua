-- Bootstrap only. Folder/DB names stay unchanged for upgrades from 2.x.
FWC = { version = "3.7.0-pilot", UI = {}, Services = {}, Data = {}, diagnostics = {} }
local A = FWC
function A:Log(message)
    self.diagnostics[#self.diagnostics + 1] = tostring(message)
    if #self.diagnostics > 40 then table.remove(self.diagnostics, 1) end
end
function A:Print(message)
    if print then print("|cffd5ad68Forever Companion:|r " .. tostring(message)) end
end
function A:Refresh()
    if self.UI.window and self.UI.window:IsShown() then self.UI.Render() end
    if self.UI.Tracker then self.UI.Tracker.Render() end
    if self.UI.LootIndicator then self.UI.LootIndicator.Refresh() end
end
