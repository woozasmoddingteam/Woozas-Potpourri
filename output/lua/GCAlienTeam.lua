
local function ApplyGorgeStructureTheme(structure, player)

    assert(player:isa("Gorge"))
    
    if structure.SetVariant then
        structure:SetVariant(player:GetVariant())
    end
    
end

local function RemoveGorgeStructureFromClient(self, techId, clientId, player)

    local structureTypeTable = self.clientOwnedStructures[clientId]
    
    if structureTypeTable then
    
        if not structureTypeTable[techId] then
        
            structureTypeTable[techId] = { }
            return
            
        end    
        
        local removeIndex = 0
        local structure = nil
		local skip = false
		if techId == kTechId.GorgeTunnel and player and player:GetCrouching() then
			skip = true
		end
        for index, id in ipairs(structureTypeTable[techId])  do
        
            if id and not skip then
            
                removeIndex = index
                structure = Shared.GetEntity(id)
                break
                
            else
				skip = false
			end
            
        end
        
        if structure then
        
            table.remove(structureTypeTable[techId], removeIndex)
            structure.consumed = true
            if structure:GetCanDie() then
                structure:Kill()
            else
                DestroyEntity(structure)
            end
            
        end
        
    end
    
end

function AlienTeam:AddGorgeStructure(player, structure)

    if player ~= nil and structure ~= nil then
    
        local clientId = Server.GetOwner(player):GetUserId()
        local structureId = structure:GetId()
        local techId = structure:GetTechId()
        
        if not self.clientOwnedStructures[clientId] then
            self.clientOwnedStructures[clientId] = { }
        end
        
        local structureTypeTable = self.clientOwnedStructures[clientId]
        
        if not structureTypeTable[techId] then
            structureTypeTable[techId] = { }
        end
        
        table.insertunique(structureTypeTable[techId], structureId)
        
        ApplyGorgeStructureTheme(structure, player)
        
        local numAllowedStructure = LookupTechData(techId, kTechDataMaxAmount, -1) --* self:GetNumHives()
        
        if numAllowedStructure >= 0 and table.count(structureTypeTable[techId]) > numAllowedStructure then
            RemoveGorgeStructureFromClient(self, techId, clientId, player)
        end
        
    end
    
end


