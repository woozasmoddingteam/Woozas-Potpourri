--noinspection UnusedDef
local Plugin = Plugin
local Shine = Shine

--Hooks
do
	Shine.Hook.Add( "Think", "LoadPGPHooks", function()
		local SetupGlobalHook = Shine.Hook.SetupGlobalHook

		SetupGlobalHook( "PlayerUI_GetPlayerResources", "PlayerUI_GetPlayerResources", "ActivePre" )
		SetupGlobalHook( "PlayerUI_GetWeaponLevel", "PlayerUI_GetWeaponLevel", "ActivePre" )
		SetupGlobalHook( "PlayerUI_GetArmorLevel", "PlayerUI_GetArmorLevel", "ActivePre" )

		Shine.Hook.Remove( "Think", "LoadPGPHooks")
	end)
end

function Plugin:Initialise()
	self.Enabled = true
	return true
end

function Plugin:PlayerUI_GetPlayerResources()
	if GetGameInfoEntity():GetWarmUpActive() then
		return 100
	end
end

function Plugin:PlayerUI_GetWeaponLevel()
	if GetGameInfoEntity():GetWarmUpActive() then
		return self.dt.WeaponLevel
	end
end

function Plugin:PlayerUI_GetArmorLevel()
	if GetGameInfoEntity():GetWarmUpActive() then
		return self.dt.ArmorLevel
	end
end

function Plugin:ShowStatus( NewStatus )
	if NewStatus then
		if not self.Status then
			--We use a timer here as the database fields don't ge networked the same way we intialized them at the
			--server-side. This means the status can change even before the message's position was networked.
			if not self:GetTimer( "StatusSetup" )then
				self:CreateTimer( "StatusSetup", 0.5, 1, function()
					self.Status = Shine.ScreenText.Add( "PGPStatus", {
						X =self.dt.StatusX,
						Y = self.dt.StatusY,
						Text = self.dt.StatusText,
						R = self.dt.StatusR,
						G = self.dt.StatusG,
						B = self.dt.StatusB,
						Alignment = 0
					})
				end)
			end
		else
			self.Status.Obj:SetIsVisible(true)
		end
	elseif self.Status then
		self.Status.Obj:SetIsVisible(false)
	else
		self:DestroyTimer( "StatusSetup" )
	end
end

function Plugin:UpdateStatusText( NewText )
	Shine.ScreenText.SetText("PGPStatus", NewText)
end

function Plugin:UpdateStatusCountdown( NewStatus )
	if self.Status then
		self.Status.Obj:SetIsVisible( NewStatus == "" and self.dt.ShowStatus)
	end
	
	if NewStatus ~= "" then
		self.Countdown = Shine.ScreenText.Add( "PGPCoundown", {
			X =self.dt.StatusX,
			Y = self.dt.StatusY,
			Text = NewStatus,
			R = self.dt.StatusR,
			G = self.dt.StatusG,
			B = self.dt.StatusB,
			Alignment = 0,
			Duration = self.dt.StatusDelay
		})
	else
		Shine.ScreenText.Remove("PGPCoundown")
	end
end

function Plugin:Cleanup()
	Shine.ScreenText.Remove("PGPStatus")
	self.Status = nil

	Shine.ScreenText.Remove("PGPCoundown")
	self.Countdown = nil

	self.BaseClass.Cleanup( self )

	self.Enabled = false
end