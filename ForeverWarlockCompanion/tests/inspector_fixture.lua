-- Fel Cape's published values/recipe are production references. The worn cloak,
-- bags, player and all native API responses below are deliberately synthetic.
local M=dofile('tests/wow_mock.lua')
M.cape='item:279269';M.worn='item:910010:0:0:0:0:0:0:0:60';M.canUse=true
M.candidateStats={ITEM_MOD_STAMINA_SHORT=16,ITEM_MOD_DAMAGE_SHADOW_SHORT=15,ITEM_MOD_CRIT_RATING_SHORT=14,RESISTANCE0_NAME=50}
M.wornStats={ITEM_MOD_STAMINA_SHORT=1,ITEM_MOD_DAMAGE_FROST_SHORT=11,RESISTANCE0_NAME=70}
M.deltaCalls=0
local oldInfo=C_Item and C_Item.GetItemInfo or GetItemInfo
local oldStats=C_Item and C_Item.GetItemStats or GetItemStats
local function id(link) return type(link)=='number' and link or tonumber(tostring(link):match('item:(%d+)')) end
local function info(link)
 local n=id(link)
 if n~=279269 and n~=910010 then return oldInfo(link) end
 if M.itemPending and n==279269 then return nil end
 return n==279269 and 'Fel Cape' or 'Frost Leather Cloak (simulado)','item:'..n,n==279269 and 4 or 2,65,60,'Armor','Cloth',1,'INVTYPE_CLOAK',133753,9999,4,1
end
local function stats(link)
 local n=id(link)
 if n==279269 then return not M.itemPending and M.candidateStats or nil end
 if n==910010 then return M.wornStats end
 return oldStats(link)
end
local function delta(before,after)
 M.deltaCalls=M.deltaCalls+1
 if M.noDelta then return nil end
 if id(before)~=910010 or id(after)~=279269 then return nil end
 M.deltaLinks={before,after}
 local keys={};local r={}
 for k in pairs(M.wornStats) do keys[k]=true end;for k in pairs(M.candidateStats) do keys[k]=true end
 for k in pairs(keys) do if type(M.candidateStats[k] or 0)~='number' or type(M.wornStats[k] or 0)~='number' then return nil end;r[k]=(M.candidateStats[k] or 0)-(M.wornStats[k] or 0) end
 return r
end
if M.scenario=='legacy' then GetItemInfo=info;GetItemStats=stats;GetItemStatDelta=delta;IsEquippableItem=function() return M.canUse end
else C_Item.GetItemInfo=info;C_Item.GetItemStats=stats;C_Item.GetItemStatDelta=delta;C_Item.IsEquippableItem=function() return M.canUse end end
C_PlayerInfo={CanUseItem=function() return M.canUse end}
M.equipped={[15]=910010};GetInventoryItemLink=function(_,slot) return slot==15 and M.worn end
M.bags={[0]={{id=14342,count=1},{id=14048,count=2}}}
function M.Load()
 ForeverWarlockCompanionDB={viewClass='WARLOCK',spec='Affliction',mode='Pre-BiS',professions={'Tailoring','Enchanting'}}
 for line in io.lines('ForeverWarlockCompanion.toc') do if line:match('%.lua$') then dofile((line:gsub('\\','/'))) end end
 M.Event('ADDON_LOADED','ForeverWarlockCompanion')
 return FWC
end
return M
