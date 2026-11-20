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
  if row.eligible==true and not row.compatibility and (row.state=='upgrade' or row.state=='downgrade') and s and finite(s.before) and s.before>0 and finite(s.delta) and s.delta~=0 and finite(s.absolute) and s.absolute~=0 and (s.delta>0)==(s.absolute>0) then
   if not best or s.delta>best.score.delta then best=row end
  end
 end
 if not best then return nil end
 local rank=I.Rank(result,best);local color=I.Color(rank)
 local upgrade=best.score.absolute>0
 local title=(upgrade and 'Item Improvement' or 'Item Downgrade')..(rank and (' - '..rank..' BiS') or '')
 local function signed(n) local v=math.abs(n);return v<.01 and string.format('%+.2g',n) or v<.1 and string.format('%+.2f',n) or string.format('%+.1f',n) end
 local gains=signed(best.score.delta)..'% · '..signed(best.score.absolute)..' GS/EP'
 local className,class=A.Compat.Call(UnitClass,'player')
 if not A.Compat.Readable(className) or type(className)~='string' then className='Character' end
 if not A.Compat.Readable(class) or type(class)~='string' then class=nil end
 local spec=best.score.provider=='flb' and best.score.spec or A.db.spec
 if not A.Compat.Readable(spec) or type(spec)~='string' then spec=nil end
 local specLabel=type(spec)=='string' and spec:gsub('^%l',string.upper) or 'Profile'
 for _,name in ipairs(A.Data.classes[class] or {}) do if name:lower():gsub('%s','')==specLabel:lower():gsub('%s','') then specLabel=name;break end end
 return {text=title..'\n'..gains,color=color,rank=rank,row=best,upgrade=upgrade,
  class=class,className=className,spec=spec,specLabel=specLabel,gains=gains,
  stateColor=upgrade and '78e49a' or 'ef9797',meter=math.max(-1,math.min(1,best.score.delta/100))}
end
return I
