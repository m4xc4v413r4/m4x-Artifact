local dropData = {};
local name, _ = UnitName("Player");
local realm = GetRealmName("Player");
local frameW, frameH = 200, 20;
m4xArtifactDB = m4xArtifactDB or {};

local akMulti = {
	25, 50, 90, 140, 200,
	275, 375, 500, 650, 850,
	1100, 1400, 1775, 2250, 2850,
	3600, 4550, 5700, 7200, 9000,
	11300, 14200, 17800, 22300, 24900,
	100000, 130000, 170000, 220000, 290000,
	380000, 490000, 640000, 830000, 1080000,
	1400000, 1820000, 2370000, 3080000, 4000000,
	5200000, 6760000, 8790000, 11430000, 14860000,
	19320000, 25120000, 32660000, 42460000, 55200000
};
 
local frame = CreateFrame("Button", "m4xArtifactFrame", UIParent);
local dropdown = CreateFrame("Button", "m4xArtifactDropDown");
local text = frame:CreateFontString(nil, "ARTWORK");

dropdown.displayMode = "MENU";

frame:SetPoint("CENTER", UIParent);
frame:SetFrameStrata("HIGH");

text:SetPoint("CENTER", frame);
text:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE");
text:SetTextColor(1, 0.82, 0);

frame:EnableMouse(true);
frame:SetScript("OnDragStart", frame.StartMoving);
frame:SetScript("OnDragStop", frame.StopMovingOrSizing);

frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
frame:RegisterEvent("ARTIFACT_CLOSE");
frame:RegisterEvent("ARTIFACT_RESPEC_PROMPT");
frame:RegisterEvent("ARTIFACT_XP_UPDATE");

SLASH_M4XARTIFACT1 = "/mart";
SlashCmdList["M4XARTIFACT"] = function()
	if frame:IsShown() then
		frame:Hide();
	else
		frame:Show();
	end
end

local function UpdateValues()
	local itemID, _, _, _, totalXP, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo();
	if itemID then
		local pointsFree, xpToNextPoint = 0, C_ArtifactUI.GetCostForPointAtRank(pointsSpent, artifactTier);
		while totalXP >= xpToNextPoint do
			totalXP, pointsSpent, pointsFree, xpToNextPoint = totalXP - xpToNextPoint, pointsSpent + 1, pointsFree + 1, C_ArtifactUI.GetCostForPointAtRank(pointsSpent + 1, artifactTier);
		end
		if m4xArtifactDB[realm][name]["view"] == "full" then
			text:SetFormattedText("AP |cff00ff00%s/%s (%.1f%%)|r" .. (pointsFree > 0 and " (+%d)" or ""), BreakUpLargeNumbers(totalXP), BreakUpLargeNumbers(xpToNextPoint), 100 * totalXP / xpToNextPoint, pointsFree);
		elseif m4xArtifactDB[realm][name]["view"] == "partial" then
			text:SetFormattedText("AP |cff00ff00%.1f%%|r" .. (pointsFree > 0 and " (+%d)" or ""), 100 * totalXP / xpToNextPoint, pointsFree);
		end
		frameW, frameH = text:GetSize();
		frame:SetWidth(frameW);
		frame:SetHeight(frameH);
		return totalXP, xpToNextPoint, pointsFree;
	end
end

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		if not m4xArtifactDB[realm] then
			m4xArtifactDB[realm] = {};
		end
		if not m4xArtifactDB[realm][name] then
			m4xArtifactDB[realm][name] = {};
		end
		if not m4xArtifactDB[realm][name]["view"] then
			m4xArtifactDB[realm][name]["view"] = "partial";
		end
		if m4xArtifactDB[realm][name]["point"] then
			frame:SetPoint(m4xArtifactDB[realm][name]["point"], nil, m4xArtifactDB[realm][name]["relativePoint"], m4xArtifactDB[realm][name]["xOfs"], m4xArtifactDB[realm][name]["yOfs"]);
		end
	end
	UpdateValues();
end);

frame:SetScript("OnEnter", function(self)
	local _, akLevel = GetCurrencyInfo(1171);
	local _, _, itemName, itemIcon, _, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo()
	local _, effectiveStat = UnitStat("player", 3);

	if HasArtifactEquipped() then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM");
		GameTooltip:SetText(string.format("|T%d:0|t %s", itemIcon, itemName));
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(string.format("Artifact Knowledge Level: |cff00ff00%d (+%s%%)|r", akLevel, BreakUpLargeNumbers(akMulti[akLevel]) or 0));

		if akLevel < 50 then
			GameTooltip:AddLine(string.format("Next Artifact Knowledge: |cff00ff00%d (+%s%%)|r", akLevel + 1, BreakUpLargeNumbers(akMulti[akLevel + 1])));
		end

		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(string.format("Stamina from points: |cff00ff00+%g%% (+%d)|r", pointsSpent * 0.75, effectiveStat - (effectiveStat / ((pointsSpent * 0.75 / 100) + 1))));
	end
	GameTooltip:Show();
end);

frame:SetScript("OnLeave", function(self)
	GameTooltip:Hide();
end);

local function LockTracker()
	if not frame:IsMovable() then
		frame:SetMovable(true);
		frame:RegisterForDrag("LeftButton");
	else
		frame:SetMovable(false);
		frame:RegisterForDrag();
		m4xArtifactDB[realm][name]["point"], _, m4xArtifactDB[realm][name]["relativePoint"], m4xArtifactDB[realm][name]["xOfs"], m4xArtifactDB[realm][name]["yOfs"] = frame:GetPoint();
	end
end

dropdown.initialize = function(self, dropLevel)
	if not dropLevel then return end
	wipe(dropData);

	if dropLevel == 1 then
		dropData.isTitle = 1;
		dropData.notCheckable = 1;

		dropData.text = "m4x Artifact";
		UIDropDownMenu_AddButton(dropData, dropLevel);

		dropData.isTitle = nil;
		dropData.disabled = nil;
		dropData.notCheckable = nil;

		dropData.text = "Lock Display";
		dropData.func = function() LockTracker(); end
		dropData.checked = not frame:IsMovable();
		UIDropDownMenu_AddButton(dropData, dropLevel);

		dropData.keepShownOnClick = 1;
		dropData.hasArrow = 1;
		dropData.notCheckable = 1;

		dropData.text = "View";
		UIDropDownMenu_AddButton(dropData, dropLevel);

		dropData.value = nil;
		dropData.hasArrow = nil;
		dropData.keepShownOnClick = nil;

		dropData.text = "Hide Display";
		dropData.func = function() frame:Hide(); end
		UIDropDownMenu_AddButton(dropData, dropLevel);

		dropData.text = CLOSE;
		dropData.func = function() CloseDropDownMenus(); end
		dropData.checked = nil;
		UIDropDownMenu_AddButton(dropData, dropLevel);

	elseif dropLevel == 2 then
		totalXP, xpToNextPoint, pointsFree = UpdateValues(totalXP, xpToNextPoint, pointsFree);
		dropData.keepShownOnClick = 1;
		dropData.notCheckable = 1;

		dropData.text = string.format("|cff00ff00%s/%s (%.1f%%)|r", BreakUpLargeNumbers(totalXP), BreakUpLargeNumbers(xpToNextPoint), 100 * totalXP / xpToNextPoint, pointsFree);
		dropData.func = function() m4xArtifactDB[realm][name]["view"] = "full"; UpdateValues(); end
		UIDropDownMenu_AddButton(dropData, dropLevel);

		dropData.text = string.format("|cff00ff00%.1f%%|r", 100 * totalXP / xpToNextPoint, pointsFree);
		dropData.func = function() m4xArtifactDB[realm][name]["view"] = "partial"; UpdateValues(); end
		UIDropDownMenu_AddButton(dropData, dropLevel);
	end
end

frame:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" then
		ArtifactFrame_LoadUI();
		if ( ArtifactFrame:IsVisible() ) then
			HideUIPanel(ArtifactFrame);
		else
			SocketInventoryItem(16);
		end
	elseif button == "RightButton" then
		itemID = C_ArtifactUI.GetEquippedArtifactInfo();
		if itemID then
			ToggleDropDownMenu(1, nil, dropdown, self:GetName(), 0, 0);
		end
	end
end);