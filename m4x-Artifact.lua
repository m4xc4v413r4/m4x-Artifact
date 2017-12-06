local dropData = {}
local name, _ = UnitName("Player")
local realm = GetRealmName("Player")
m4xArtifactDB = m4xArtifactDB or {}

local frame = CreateFrame("Button", "m4xArtifactFrame", UIParent)
local dropdown = CreateFrame("Button", "m4xArtifactDropDown")
local text = frame:CreateFontString(nil, "ARTWORK")

dropdown.displayMode = "MENU"

frame:SetPoint("CENTER", UIParent)
frame:SetFrameStrata("HIGH")

text:SetPoint("CENTER", frame)
text:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
text:SetTextColor(1, 0.82, 0)

frame:SetHeight(15)

frame:EnableMouse(true)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("ARTIFACT_UPDATE")
frame:RegisterEvent("ARTIFACT_CLOSE")
frame:RegisterEvent("ARTIFACT_RESPEC_PROMPT")
frame:RegisterEvent("ARTIFACT_XP_UPDATE")

SLASH_M4XARTIFACT1 = "/mart"
SlashCmdList["M4XARTIFACT"] = function()
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end

local function FormatText(arg)
	local formatedText = "|cff00ff00%.2f|r|cffff7f00%s|r"
	if arg >= 1000000000 then
		arg = string.format(formatedText, arg / 1000000000, "B")
	elseif arg >= 1000000 then
		arg = string.format(formatedText, arg / 1000000, "M")
	elseif arg >= 1000 then
		arg = string.format(formatedText, arg / 1000, "K")
	end
	return arg
end

local function ColorText(arg)
	local cR, cG
	if arg > 0.5 then
		cR = 255 * (1 - arg) * 2
		cG = 255
	elseif arg <= 0.5 then
		cR = 255
		cG = 255 * arg * 2
	end
	arg = string.format("|cff%02x%02x00", cR, cG)
	return arg
end

local function UpdateValues()
	local itemID, _, _, itemIcon, totalXP, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
	if itemID then
		local pointsFree, xpToNextPoint = 0, C_ArtifactUI.GetCostForPointAtRank(pointsSpent, artifactTier)
		while totalXP >= xpToNextPoint and xpToNextPoint > 0 do
			totalXP, pointsSpent, pointsFree, xpToNextPoint = totalXP - xpToNextPoint, pointsSpent + 1, pointsFree + 1, C_ArtifactUI.GetCostForPointAtRank(pointsSpent + 1, artifactTier)
		end
		if xpToNextPoint < 1 then
			text:SetFormattedText("Use %d ranks to calculate", pointsFree - 88)
		elseif m4xArtifactDB[realm][name]["view"] == "full" then
			text:SetFormattedText("|T%d:0|t AP %s/%s (%s%.1f%%|r)" .. (pointsFree > 0 and " (+%d)" or ""), itemIcon,FormatText(totalXP), FormatText(xpToNextPoint), ColorText(totalXP / xpToNextPoint), 100 * totalXP / xpToNextPoint, pointsFree)
		elseif m4xArtifactDB[realm][name]["view"] == "partial" then
			text:SetFormattedText("|T%d:0|t AP %s%.1f%%|r" .. (pointsFree > 0 and " (+%d)" or ""), itemIcon, ColorText(totalXP / xpToNextPoint), 100 * totalXP / xpToNextPoint, pointsFree)
		end
		local frameW = text:GetSize()
		frame:SetWidth(frameW)
		return totalXP, xpToNextPoint, pointsFree
	end
end

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		if not m4xArtifactDB[realm] then
			m4xArtifactDB[realm] = {}
		end
		if not m4xArtifactDB[realm][name] then
			m4xArtifactDB[realm][name] = {}
		end
		if not m4xArtifactDB[realm][name]["view"] then
			m4xArtifactDB[realm][name]["view"] = "partial"
		end
		if m4xArtifactDB[realm][name]["point"] then
			frame:ClearAllPoints()
			
			frame:SetPoint(m4xArtifactDB[realm][name]["point"], nil, m4xArtifactDB[realm][name]["relativePoint"], m4xArtifactDB[realm][name]["xOfs"], m4xArtifactDB[realm][name]["yOfs"])
		end
		if m4xArtifactDB[realm][name]["font"] then
			text:SetFont("Fonts\\FRIZQT__.TTF", m4xArtifactDB[realm][name]["font"], "OUTLINE");
		end
		C_Timer.After(10, UpdateValues)
		frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
	UpdateValues()
end)

frame:SetScript("OnEnter", function(self)
	local _, _, itemName, itemIcon, _, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo()
	local totalXP, xpToNextPoint = UpdateValues()
	
	if HasArtifactEquipped() then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText(string.format("|T%d:0|t %s", itemIcon, itemName))
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine("Artifact Weapon Rank:", string.format("|cff00ff00%d|r", pointsSpent))
		if xpToNextPoint > 0 then
			GameTooltip:AddDoubleLine("AP left for next Rank:", string.format("%s", FormatText(xpToNextPoint - totalXP)))
		end
	end
	GameTooltip:Show()
end)

frame:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)

local function LockTracker()
	if not frame:IsMovable() then
		frame:SetMovable(true)
		frame:RegisterForDrag("LeftButton")
	else
		frame:SetMovable(false)
		frame:RegisterForDrag()
		m4xArtifactDB[realm][name]["point"], _, m4xArtifactDB[realm][name]["relativePoint"], m4xArtifactDB[realm][name]["xOfs"], m4xArtifactDB[realm][name]["yOfs"] = frame:GetPoint()
	end
end

local function ChooseFont()
	local _, fSize, _ = text:GetFont()
	local fSizeInt = math.floor(fSize+0.5);
	for i = fSizeInt - 3, fSizeInt + 3 do
		if i > 0 then
			if i == fSizeInt then
				dropData.disabled = 1;
			else
				dropData.disabled = nil;
			end
			dropData.text = i;
			dropData.func = function() text:SetFont("Fonts\\FRIZQT__.TTF", i, "OUTLINE"); m4xArtifactDB[realm][name]["font"] = i end
			UIDropDownMenu_AddButton(dropData, 2);
		end
	end
end

local function ResetDisplay()
	frame:ClearAllPoints();

	frame:SetPoint("CENTER", UIParent);
	m4xArtifactDB[realm][name]["point"] = nil;

	text:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE");
	m4xArtifactDB[realm][name]["font"] = 15;
end

dropdown.initialize = function(self, dropLevel)
	if not dropLevel then return end
	wipe(dropData)

	if dropLevel == 1 then
		dropData.isTitle = 1
		dropData.notCheckable = 1

		dropData.text = "m4x Artifact"
		UIDropDownMenu_AddButton(dropData, dropLevel)

		dropData.isTitle = nil
		dropData.disabled = nil
		dropData.notCheckable = nil

		dropData.text = "Lock Display"
		dropData.func = function() LockTracker() end
		dropData.checked = not frame:IsMovable()
		UIDropDownMenu_AddButton(dropData, dropLevel)

		dropData.keepShownOnClick = 1
		dropData.hasArrow = 1
		dropData.notCheckable = 1

		dropData.value = "reset";
		dropData.text = "Reset";
		UIDropDownMenu_AddButton(dropData, dropLevel);

		dropData.value = "view"
		dropData.text = "View"
		UIDropDownMenu_AddButton(dropData, dropLevel)

		dropData.value = "font";
		dropData.text = "Font Size";
		UIDropDownMenu_AddButton(dropData, dropLevel);

		dropData.value = nil
		dropData.hasArrow = nil
		dropData.keepShownOnClick = nil

		dropData.text = "Hide Display"
		dropData.func = function() frame:Hide() end
		UIDropDownMenu_AddButton(dropData, dropLevel)

		dropData.text = CLOSE
		dropData.func = function() CloseDropDownMenus() end
		dropData.checked = nil
		UIDropDownMenu_AddButton(dropData, dropLevel)

	elseif dropLevel == 2 then
		local totalXP, xpToNextPoint, pointsFree = UpdateValues()
		dropData.keepShownOnClick = 1
		dropData.notCheckable = 1

		if UIDROPDOWNMENU_MENU_VALUE == "reset" then
			dropData.keepShownOnClick = nil;

			dropData.text = "|cffff0000Position/Size|r";
			dropData.func = function() ResetDisplay(); end
			UIDropDownMenu_AddButton(dropData, dropLevel);

		elseif UIDROPDOWNMENU_MENU_VALUE == "view" and xpToNextPoint > 0 then
			dropData.text = string.format("%s/%s (%s%.1f%%|r)", FormatText(totalXP), FormatText(xpToNextPoint), ColorText(totalXP / xpToNextPoint), 100 * totalXP / xpToNextPoint, pointsFree)
			dropData.func = function() m4xArtifactDB[realm][name]["view"] = "full" UpdateValues() end
			UIDropDownMenu_AddButton(dropData, dropLevel)

			dropData.text = string.format("%s%.1f%%|r", ColorText(totalXP / xpToNextPoint), 100 * totalXP / xpToNextPoint, pointsFree)
			dropData.func = function() m4xArtifactDB[realm][name]["view"] = "partial" UpdateValues() end
			UIDropDownMenu_AddButton(dropData, dropLevel)
		
		elseif UIDROPDOWNMENU_MENU_VALUE == "font" then
			dropData.keepShownOnClick = nil;
			ChooseFont();
		end
	end
end

frame:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" then
		ArtifactFrame_LoadUI()
		if ( ArtifactFrame:IsVisible() ) then
			HideUIPanel(ArtifactFrame)
		else
			SocketInventoryItem(16)
		end
	elseif button == "RightButton" then
		local itemID = C_ArtifactUI.GetEquippedArtifactInfo()
		if itemID then
			ToggleDropDownMenu(1, nil, dropdown, self:GetName(), 0, 0)
		end
	end
end)