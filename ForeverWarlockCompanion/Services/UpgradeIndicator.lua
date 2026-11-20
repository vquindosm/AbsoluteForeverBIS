local A=FWC
local I={};A.Services.UpgradeIndicator=I
local function finite(n) return A.Compat.Readable(n) and type(n)=='number' and n==n and math.abs(n)<math.huge end
function I.Color(rank)
 if rank==1 then return 'ff8000' end
 if rank==2 or rank==3 then return 'a335ee' end
 if rank==4 or rank==5 then return '0070dd' end
 return '1eff00'
end
function I.Rank(result,row)
 local data=A.Data.itemGuide;local profile=data and data.profile
 local _,class=A.Compat.Call(UnitClass,'player');local level=A.Compat.Call(UnitLevel,'player')
 local spec=row.score.provider=='flb' and row.score.spec or A.db.spec
 if not A.Compat.Readable(class) or not A.Compat.Readable(level) or not A.Compat.Readable(spec) or not profile or class~=profile.class or type(spec)~='string' or spec:lower()~=profile.spec:lower() or level~=profile.level then return nil end
 local item=data.items[result.itemId];local rec=data.recommendations[row.slot] and data.recommendations[row.slot][result.itemId]
 if not item or not rec or item.betaEvent or item.speculation or item.dataFromBuild then return nil end
 local provenance=data.provenance and data.provenance[rec.source]
 if not provenance or provenance.evidenceType~='published_guide_reference' then return nil end
 local _,build=A.Compat.Call(GetBuildInfo)
 if not A.Compat.Readable(build) or not item.build or tostring(build)~=item.build:match('(%d+)$') then return nil end
 -- Published positions describe the base item, not an arbitrary random suffix.
 local fields={};local payload=result.link and result.link:match('item:([^|]+)')
 if payload then for field in (payload..':'):gmatch('(.-):') do fields[#fields+1]=field end end
 if fields[7] and fields[7]~='' and fields[7]~='0' then return nil end
 local rank=rec.position
 return finite(rank) and rank>=1 and rank%1==0 and rank or nil
end
function I.Build(result)
 if not result or result.state=='pending' then return nil end
 local best
 for _,row in ipairs(result.comparisons or {}) do
  local s=row.score
  if row.eligible==true and not row.compatibility and row.state=='upgrade' and s and finite(s.before) and s.before>0 and finite(s.delta) and s.delta>0 and finite(s.absolute) and s.absolute>0 then
   if not best or s.delta>best.score.delta then best=row end
  end
 end
 if not best then return nil end
 local rank=I.Rank(result,best);local color=I.Color(rank)
 local title='Item Improvement'..(rank and (' - '..rank..' BiS') or '')
 local function positive(n) return n<.01 and string.format('+%.2g',n) or n<.1 and string.format('+%.2f',n) or string.format('+%.1f',n) end
 local text=title..'\n'..positive(best.score.delta)..'% · '..positive(best.score.absolute)..' GS/EP'
 if rank then text=text..' · https://foreverdb.net' end
 return {text='|cff'..color..text..'|r',color=color,rank=rank,row=best}
end
return I
