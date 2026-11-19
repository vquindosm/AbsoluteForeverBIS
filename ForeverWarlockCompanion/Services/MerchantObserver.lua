-- Reads the open merchant. Never buys items, spends currency or sends data externally.
local A=FWC
local M={active={},isOpen=false};A.Services.MerchantObserver=M
local function number(v) return A.Compat.Readable(v) and type(v)=='number' and v==v and math.abs(v)<math.huge end
function M.Close() M.active={};M.isOpen=false end
function M.Read()
 if not M.isOpen then return end
 M.active={}
 local guid=A.Compat.Call(UnitGUID,'npc');local name=A.Compat.Call(UnitName,'npc')
 if not A.Compat.Readable(guid) or type(guid)~='string' or not A.Compat.Readable(name) or type(name)~='string' then return end
 local npcId=tonumber(guid:match('^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-'))
 if not npcId then return end
 local count=A.Compat.Call(GetMerchantNumItems);if not number(count) then return end
 for index=1,math.min(200,count) do
  local link=A.Compat.Call(GetMerchantItemLink,index);local itemId=A.Compat.ItemID(link)
  if itemId and A.Services.AcquisitionRequirementsResolver.Has(itemId) then
   local price,stack,stock,purchasable,usable,extended
   if type(C_MerchantFrame and C_MerchantFrame.GetItemInfo)=='function' then
    local d=A.Compat.Call(C_MerchantFrame.GetItemInfo,index)
    if type(d)=='table' then price=d.price;stack=d.stackCount;stock=d.numAvailable;purchasable=d.isPurchasable;usable=d.isUsable;extended=d.hasExtendedCost end
   else local itemName,texture;itemName,texture,price,stack,stock,purchasable,usable,extended=A.Compat.Call(GetMerchantItemInfo,index) end
   local seen={npcId=npcId,vendorName=name,itemId=itemId,itemLink=link,observedAt=A.Compat.Now(),source='client_open_merchant',costs={},costsComplete=false}
   if number(price) and price>=0 and price%1==0 then seen.goldCostCopper=price end
   if number(stack) and stack>0 then seen.stackCount=stack end
   if number(stock) and stock>=-1 then seen.stock=stock end
   if A.Compat.Readable(purchasable) and type(purchasable)=='boolean' then seen.clientPurchasable=purchasable end
   if A.Compat.Readable(usable) and type(usable)=='boolean' then seen.clientUsable=usable end
   if A.Compat.Readable(extended) and type(extended)=='boolean' then
    if not extended then seen.costsComplete=true
    else
     local n=A.Compat.Call(GetMerchantItemCostInfo,index)
     if number(n) and n>0 and n<=20 and n%1==0 then
      seen.costsComplete=true
      for ci=1,math.min(n,20) do
       local _,amount,costLink,costName=A.Compat.Call(GetMerchantItemCostItem,index,ci)
       if number(amount) and amount>0 and A.Compat.Readable(costLink) and type(costLink)=='string' then
        local token=A.Compat.ItemID(costLink);local currency=tonumber(costLink:match('currency:(%d+)'))
        if token or currency then seen.costs[#seen.costs+1]={kind=token and 'item' or 'currency',itemId=token,currencyId=currency,quantity=amount,name=A.Compat.Readable(costName) and type(costName)=='string' and costName or nil}
        else seen.costsComplete=false end
       else seen.costsComplete=false end
      end
     end
    end
   end
   M.active[itemId]=seen
   A.db.vendorObservations=A.db.vendorObservations or {};A.db.vendorObservations[npcId..':'..itemId]=A.Services.Persistence.Copy(seen)
  end
 end
end
