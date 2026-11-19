local A = FWC
local R = { character={}, talents={branches={}}, professions={} }; A.Services.Character = R
local professionIDs = {[197]="Tailoring",[333]="Enchanting",[171]="Alchemy",[164]="Blacksmithing",[202]="Engineering",[165]="Leatherworking",[182]="Herbalism",[186]="Mining",[393]="Skinning"}
function R.Read()
    local name = A.Compat.Call(UnitName, "player") or "Unknown character"
    local className, class = A.Compat.Call(UnitClass, "player")
    R.character = {name=name, class=class or "WARLOCK", className=className or class, level=A.Compat.Call(UnitLevel,"player") or "?"}
    local api = C_SpecializationInfo
    local specIndex = A.Compat.Call(api and api.GetSpecialization or GetSpecialization)
    local _, detected = A.Compat.Call(api and api.GetSpecializationInfo or GetSpecializationInfo, specIndex)
    R.character.detectedSpec = detected
    if not A.db.manualSpec and detected then
        for _, spec in ipairs(A.Data.classes[R.character.class] or {}) do
            if spec == detected then A.db.viewClass=R.character.class; A.db.spec=spec end
        end
    end
    R.professions = {}
    local first, second = A.Compat.Call(GetProfessions)
    for index, skill in pairs({[1]=first,[2]=second}) do
        local prof, _, rank, maxRank, _, _, skillLine = A.Compat.Call(GetProfessionInfo, skill)
        if prof then
            R.professions[index] = {name=prof, canonical=professionIDs[skillLine],rank=rank,maxRank=maxRank}
            if not A.db.manualProfessions then A.db.professions[index] = professionIDs[skillLine] or "Any profession" end
        end
    end
end
function R.ReadTalents()
    local branches = {}; local api = C_SpecializationInfo
    if api and type(api.GetTalentInfo) == "function" then
        local count = A.Compat.Call(GetNumSpecializations) or 3
        for tree = 1, math.min(count, 10) do
            local _, name = A.Compat.Call(api.GetSpecializationInfo, tree)
            local branch = {name=name or ("Branch "..tree),entries={},points=0}
            for index = 1, 100 do
                local info = A.Compat.Call(api.GetTalentInfo, {specializationIndex=tree,talentIndex=index,isInspect=false,isPet=false})
                if type(info) ~= "table" or not info.name then break end
                local rank = type(info.rank) == "number" and info.rank or (info.selected and 1 or 0)
                branch.entries[#branch.entries + 1] = {id=info.talentID,name=info.name,rank=rank,max=info.maxRank,spellID=info.spellID,tier=info.tier,column=info.column}
                branch.points = branch.points + rank
            end
            if #branch.entries > 0 then branches[#branches + 1] = branch end
        end
    end
    if #branches == 0 and C_ClassTalents and C_Traits then
        local configID = A.Compat.Call(C_ClassTalents.GetActiveConfigID)
        local config = configID and A.Compat.Call(C_Traits.GetConfigInfo, configID)
        for _, treeID in ipairs(type(config) == "table" and config.treeIDs or {}) do
            local branch = {name="Tree "..treeID,entries={},points=0}
            local nodes = A.Compat.Call(C_Traits.GetTreeNodes, treeID) or {}
            for _, nodeID in ipairs(nodes) do
                local node = A.Compat.Call(C_Traits.GetNodeInfo, configID, nodeID)
                if type(node) == "table" then
                    for _, entryID in ipairs(node.entryIDs or {}) do
                        local entry = A.Compat.Call(C_Traits.GetEntryInfo, configID, entryID)
                        local def = entry and entry.definitionID and A.Compat.Call(C_Traits.GetDefinitionInfo, entry.definitionID)
                        if def then
                            local active = node.activeEntry and node.activeEntry.entryID == entryID
                            local rank = active and (node.activeRank or node.currentRank or 0) or 0
                            local spell = C_Spell and A.Compat.Call(C_Spell.GetSpellInfo, def.spellID)
                            branch.entries[#branch.entries+1] = {id=entryID,name=def.overrideName or (spell and spell.name) or ("Entry "..entryID),rank=rank,max=node.maxRanks,spellID=def.spellID}
                            branch.points = branch.points + rank
                        end
                    end
                end
            end
            if #branch.entries > 0 then branches[#branches+1] = branch end
        end
    end
    R.talents = {branches=branches, checkedAt=A.Compat.Now(),class=R.character.class,spec=R.character.detectedSpec}
end
