local menu = MarineCommander:GetButtonTable()[kTechId.AdvancedMenu]
for i, v in ipairs(menu) do
	if v == kTechId.None then
		menu[i] = kTechId.FlameSentry
	end
end
