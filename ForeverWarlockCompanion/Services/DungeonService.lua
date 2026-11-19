local A=FWC
local D={};A.Services.Dungeons=D
function D.Groups(kind)
 local groups={}
 for _,o in ipairs(A.Services.Objectives.List()) do
  if not kind or o.sourceType==kind then
   local item=A.Data.items[o.itemId];local key=item and item.sourceType or 'Unknown'
   if kind=='Reputation' then key=item and item.source or 'Unknown' end
   local g=groups[key] or {name=key,objectives={},obtained=0,bosses={}}
   g.objectives[#g.objectives+1]=o;if o.completionState=='Obtained' then g.obtained=g.obtained+1 end
   if kind=='Dungeon' and item then g.bosses[item.source]=true end
   groups[key]=g
  end
 end
 local list={};for _,g in pairs(groups) do list[#list+1]=g end;table.sort(list,function(a,b) return a.name<b.name end);return list
end
