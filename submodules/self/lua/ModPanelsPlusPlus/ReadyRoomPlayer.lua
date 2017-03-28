-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ReadyRoomPlayer.lua
--
--    Created by:   Brian Cronin (brainc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Player.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/JumpMoveMixin.lua")
Script.Load("lua/Mixins/CrouchMoveMixin.lua")
Script.Load("lua/Mixins/LadderMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/Marine.lua")
Script.Load("lua/MarineVariantMixin.lua")

--
-- ReadyRoomPlayer is a simple Player class that adds the required Move type mixin
-- to Player. Player should not be instantiated directly.
--
class 'ReadyRoomPlayer' (Player)

ReadyRoomPlayer.kMapName = "ready_room_player"

local networkVars = { }

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(JumpMoveMixin, networkVars)
AddMixinNetworkVars(CrouchMoveMixin, networkVars)
AddMixinNetworkVars(LadderMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(ScoringMixin, networkVars)
AddMixinNetworkVars(MarineVariantMixin, networkVars)

function ReadyRoomPlayer:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, JumpMoveMixin)
    InitMixin(self, CrouchMoveMixin)
    InitMixin(self, LadderMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kDefaultFov })
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    InitMixin(self, MarineVariantMixin )

    Player.OnCreate(self)

	InitMixin(self, RagdollMixin)

    self:SetModel(MarineVariantMixin.kDefaultModelName, MarineVariantMixin.kMarineAnimationGraph)

    if Client and Client.GetLocalPlayer() == self then

        self.actionIconGUI = GetGUIManager():CreateGUIScript("GUIActionIcon")
        self.actionIconGUI:SetColor(kMarineFontColor)
        self.actionIconGUI:Hide()

    end

end

function ReadyRoomPlayer:GetPlayerStatusDesc()
    return kPlayerStatus.Void
end

if Client then

    function ReadyRoomPlayer:OnCountDown()
    end

    function ReadyRoomPlayer:OnCountDownEnd()
    end

end

function ReadyRoomPlayer:GetHealthbarOffset()
    return 0.85
end

function ReadyRoomPlayer:OnDestroy()

    Player.OnDestroy(self)

    if Client and self.actionIconGUI then

        GetGUIManager():DestroyGUIScript(self.actionIconGUI)
        self.actionIconGUI = nil

    end

end

function ReadyRoomPlayer:GetCanDieOverride()
    return true
end

if Client then

    function ReadyRoomPlayer:OnProcessMove(input)

        Player.OnProcessMove(self, input)

        local ent = self:PerformUseTrace()
        if ent then

            if GetPlayerCanUseEntity(self, ent) and not self:GetIsUsing() then

                self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, nil, nil)

                return

            end

        end

        self.actionIconGUI:Hide()

    end

end

Shared.LinkClassToMap("ReadyRoomPlayer", ReadyRoomPlayer.kMapName, networkVars)
