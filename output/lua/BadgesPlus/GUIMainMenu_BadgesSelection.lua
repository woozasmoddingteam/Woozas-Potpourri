-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\menu\GUIMainMenu_BadgesSelection.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'GUIBadgesSelection' (Window)

local function GetBadges()
    local badgerow = {} --array of selected badges
    local badges = {} --lookup table for selected badges
    for i = 1, 10 do
        local sSavedBadge = Client.GetOptionString( string.format("Badge%s", i), "" )
        if sSavedBadge and sSavedBadge ~= "" then
            local badgeid = rawget(gBadges, sSavedBadge) or gBadges.none

            --check if we own the badge
            local ownedBadges = Badges_GetOwnedBadges()
            badgeid = badgeid ~= gBadges.none and ownedBadges[badgeid] and badgeid or gBadges.none

            badgerow[i] = badgeid
            badges[badgeid] = true
        end
    end

    return badgerow, badges
end

function GUIBadgesSelection:ReloadBadgeOrder()
    local i = 1
    for _, badge in ipairs(self.activeBadges) do
        if badge:GetIsVisible() then
            badge:SetLeftOffset(GUIScale(10) + (i-1)* GUIScale(36))
            i = i + 1
        end
    end

    self.playername:SetLeftOffset(GUIScale(10) + (i-1)* GUIScale(36))
end

function GUIBadgesSelection:GetBadgeRows(bitmask)
    local columns = {}
    local acc = 1
    for i = 1, kMaxBadgeColumns do
        if bit.band(bitmask, acc) ~= 0 then
            columns[#columns+1] = i
        end

        acc = acc * 2
    end

    return columns
end

function GUIBadgesSelection:LoadBadges()
    local main = self
    local badges, selectedbadges = GetBadges()

    for i = 1, 10 do
        local badge = badges[i]

        if badge and badge ~= gBadges.none then
            local badgeTexture = Badges_GetBadgeData(badge).unitStatusTexture
            self.activeBadges[i].badgeId = badge
            self.activeBadges[i]:SetBackgroundTexture(badgeTexture)
            self.activeBadges[i]:SetIsVisible(true)
        else
            self.activeBadges[i]:SetIsVisible(false)
        end
    end

    self:ReloadBadgeOrder()

    for i, avaibleBadge in ipairs(self.avaibleBadges) do
        avaibleBadge:Uninitialize()
        self.avaibleBadges[i]= nil
    end

    local i = 1
    local ownedBadges = Badges_GetOwnedBadges()
    for _, badge in ipairs(gBadges) do
        local badgeid = gBadges[badge]

        if badgeid ~= gBadges.none and ownedBadges[badgeid] and not selectedbadges[badgeid] then
            self.avaibleBadges[i] = CreateMenuElement(self.avaibleRow, "Image")
            self.avaibleBadges[i]:SetCSSClass("badge")
            local badgeData = Badges_GetBadgeData(badgeid)
            local badgeTexture = badgeData.unitStatusTexture
            self.avaibleBadges[i].badgeId = badgeid
            self.avaibleBadges[i].badgeData = badgeData
            self.avaibleBadges[i].columns = ownedBadges[badgeid]
            self.avaibleBadges[i]:SetLeftOffset(GUIScale(5) + (i % 10 + 1) * GUIScale(36))
            self.avaibleBadges[i]:SetBackgroundTexture(badgeTexture)
            self.avaibleBadges[i]:SetIsVisible(math.ceil(i/10) == self.avaibleBadges.index)

            local activeBadges = self.activeBadges
            self.avaibleBadges[i].OnMouseDown = function(self)
                local columns = main:GetBadgeRows(self.columns)

                for i = 1, #columns do
                    activeBadges[columns[i]]:SetBackgroundTexture(self.badgeData.unitStatusTexture) --Todo proper highlight
                    activeBadges[columns[i]]:SetIsVisible(true)
                end

                main:ReloadBadgeOrder()

                self.mousedown = true
                self.originalPosition = self.background:GetPosition()
                self.lastmouseX, self.lastmouseY = Client.GetCursorPosScreen()
            end

            self.avaibleBadges[i].OnMouseUp = function(self)
                local columns = main:GetBadgeRows(self.columns)
                local mouseX, mouseY = Client.GetCursorPosScreen()

                for i = 1, #columns do
                    local activeBadge = activeBadges[columns[i]]
                    if GUIItemContainsPoint(activeBadge.background, mouseX, mouseY) then
                        SelectBadge(self.badgeId, columns[i])
                        break
                    end
                end

                self.background:SetPosition(self.originalPosition)
                self.mousedown = false

                main:LoadBadges()
            end

            self.avaibleBadges[i].OnMouseOver = function(self)
                if self.mousedown then
                    local mouseX, mouseY = Client.GetCursorPosScreen()
                    local deltaX, deltaY = self.lastmouseX - mouseX, self.lastmouseY - mouseY
                    self.lastmouseX, self.lastmouseY = mouseX, mouseY

                    local oldPos = self.background:GetPosition()
                    local newPos = Vector(oldPos.x - deltaX, oldPos.y - deltaY, oldPos.z)
                    self.background:SetPosition(newPos)
                end
            end

            i = i + 1
        end
    end

    local maxrow = math.ceil(i/10)

    if maxrow > 1 then
        local main = self
        self.previousBadges = CreateMenuElement(self.avaibleRow, "Image")
        self.previousBadges:SetCSSClass("badge")
        self.previousBadges:SetBackgroundTexture(kArrowHorizontalButtonTexture)
        self.previousBadges:SetTextureCoords(kArrowMinCoords)
        self.previousBadges:AddEventCallbacks({
            OnClick = function(self)
                main.avaibleBadges.index = main.avaibleBadges.index - 1
                if main.avaibleBadges.index == 0 then
                    main.avaibleBadges.index = maxrow
                end
                main:LoadBadges()
            end
        })

        self.nextBadges = CreateMenuElement(self.avaibleRow, "Image")
        self.nextBadges:SetCSSClass("badge")
        self.nextBadges:SetBackgroundTexture(kArrowHorizontalButtonTexture)
        self.nextBadges:SetTextureCoords(kArrowMaxCoords)
        self.nextBadges:SetLeftOffset(GUIScale(5) + 11 * GUIScale(36))
        self.nextBadges:AddEventCallbacks({
            OnClick = function(self)
                main.avaibleBadges.index = main.avaibleBadges.index + 1
                if main.avaibleBadges.index > maxrow then
                    main.avaibleBadges.index = 1
                end
                main:LoadBadges()
            end
        })

    else
        for i, badge in ipairs(self.avaibleBadges) do
            badge:SetLeftOffset( GUIScale(5) + (i-1)* GUIScale(36))
        end
    end
end

function GUIBadgesSelection:Initialize()
    Window.Initialize(self)

    self:SetWindowName("Badge Selection")
    self:SetInitialVisible(false)
    self:DisableResizeTile()
    self:DisableSlideBar()
    self:DisableTitleBar()
    self:DisableContentBox()
    self:DisableCloseButton()
    self:SetLayer(kGUILayerMainMenuDialogs)

    self.title = CreateMenuElement(self, "Font")
    self.title:SetCSSClass("title")
    self.title:SetText(Locale.ResolveString("BADGE_SELECTION_HELP"))

    self.activeBadgesBackground = CreateMenuElement(self, "Image")
    self.activeBadgesBackground:SetCSSClass("badgerow")

    self.activeBadgesHighlight = CreateMenuElement(self.activeBadgesBackground, "Image")
    self.activeBadgesHighlight:SetCSSClass("badgerowhighlight")

    self.playername = CreateMenuElement(self.activeBadgesBackground, "Font")
    self.playername:SetCSSClass("playername")
    self.playername:SetText(OptionsDialogUI_GetNickname())


    self.activeBadges = {}

    local main = self
    for i = 1, 10 do
        self.activeBadges[i] = CreateMenuElement(self.activeBadgesBackground, "Image")
        self.activeBadges[i]:SetCSSClass("badge")
        self.activeBadges[i]:AddEventCallbacks({ OnClick = function(self) SelectBadge(gBadges.none, i) main:LoadBadges() end })
        self.activeBadges[i]:SetIsVisible(false)
    end

    self.avaibleRow = CreateMenuElement(self, "Image")
    self.avaibleRow:SetCSSClass("badgerow2")
    self.avaibleBadges = {
        index = 1
    }

    self.applyButton = CreateMenuElement(self, "MenuButton")
    self.applyButton:SetText(Locale.ResolveString("CLOSE"))
    self.applyButton:AddEventCallbacks({ OnClick = function()
        self:SetIsVisible(false)
    end})
    self.applyButton:SetCSSClass("playnow")

    self:SetIsVisible(false)
end

function GUIBadgesSelection:OnEscape()
    self:SetIsVisible(false)
end

function GUIBadgesSelection:SetIsVisible(visible)
    Window.SetIsVisible(self, visible)

    if visible then self:LoadBadges() end
end

function GUIBadgesSelection:GetTagName()
    return "badgeselection"
end
