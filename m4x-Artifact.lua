local dropData = {};
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

text:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE");
text:SetJustifyH("LEFT");
text:SetTextColor(1, 0.82, 0);
text:SetPoint("TOP", UIParent, "TOPLEFT", 335, -3);

frame:SetFrameStrata("HIGH");
frame:SetAllPoints(text);

dropdown.displayMode = "MENU";

frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
frame:RegisterEvent("ARTIFACT_CLOSE");
frame:RegisterEvent("ARTIFACT_RESPEC_PROMPT");
frame:RegisterEvent("ARTIFACT_XP_UPDATE");

local function UpdateValues()
    local itemID, _, _, _, totalXP, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo();
    if itemID then
        local pointsFree, xpToNextPoint = 0, C_ArtifactUI.GetCostForPointAtRank(pointsSpent, artifactTier);
        while totalXP >= xpToNextPoint do
			totalXP, pointsSpent, pointsFree, xpToNextPoint = totalXP - xpToNextPoint, pointsSpent + 1, pointsFree + 1, C_ArtifactUI.GetCostForPointAtRank(pointsSpent + 1, artifactTier);
		end
		if m4xArtifactDB["view"] == "full" then
			text:SetFormattedText("AP |cff00ff00%d/%d (%.1f%%)|r" .. (pointsFree > 0 and " (+%d)" or ""), totalXP, xpToNextPoint, 100 * totalXP / xpToNextPoint, pointsFree);
		elseif m4xArtifactDB["view"] == "partial" then
			text:SetFormattedText("AP |cff00ff00%.1f%%|r" .. (pointsFree > 0 and " (+%d)" or ""), 100 * totalXP / xpToNextPoint, pointsFree);
		end
		return totalXP, xpToNextPoint, pointsFree;
	end
    -- frame:SetShown(itemID and true or false);
end

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		if not m4xArtifactDB["view"] then
			m4xArtifactDB["view"] = "partial";
		end
	end
	UpdateValues();
end);

local function OnEnter(self)
	local _, akLevel = GetCurrencyInfo(1171);
	local _, _, itemName, itemIcon, _, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo()
	local _, effectiveStat = UnitStat("player", 3);

	if HasArtifactEquipped() then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM");
		GameTooltip:SetText(string.format("|T%d:0|t %s", itemIcon, itemName));
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(string.format("Artifact Knowledge Level: |cff00ff00%d (+%d%%)|r", akLevel, akMulti[akLevel] or 0));

		if akLevel < 50 then
			GameTooltip:AddLine(string.format("Next Artifact Knowledge: |cff00ff00%d (+%d%%)|r", akLevel + 1, akMulti[akLevel + 1]));
		end

		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(string.format("Stamina from points: |cff00ff00+%g%% (+%d)|r", pointsSpent * 0.75, effectiveStat - (effectiveStat / ((pointsSpent * 0.75 / 100) + 1))));
	else
		GameTooltip:SetText("No Artifact Weapon Equipped");
	end
	GameTooltip:Show();
end

local function OnLeave(self)
	GameTooltip:Hide();
end

dropdown.initialize = function(self, dropLevel)
	if not dropLevel then return end
	wipe(dropData);

	if dropLevel == 1 then
		dropData.isTitle = 1;
		dropData.notCheckable = 1;

		dropData.text = "m4x ArtifactBroker";
		UIDropDownMenu_AddButton(dropData, dropLevel);

		dropData.isTitle = nil;
		dropData.disabled = nil;
		dropData.keepShownOnClick = 1;
		dropData.hasArrow = 1;
		dropData.notCheckable = 1;

		dropData.text = "View";
		UIDropDownMenu_AddButton(dropData, dropLevel);

		dropData.value = nil;
		dropData.hasArrow = nil;
		dropData.keepShownOnClick = nil;

		dropData.text = CLOSE;
		dropData.func = function() CloseDropDownMenus(); end
		dropData.checked = nil;
		UIDropDownMenu_AddButton(dropData, dropLevel);

	elseif dropLevel == 2 then
		totalXP, xpToNextPoint, pointsFree = UpdateValues(totalXP, xpToNextPoint, pointsFree);
		dropData.keepShownOnClick = 1;
		dropData.notCheckable = 1;

		dropData.text = string.format("|cff00ff00%d/%d (%.1f%%)|r" .. (pointsFree > 0 and " (+%d)" or ""), totalXP, xpToNextPoint, 100 * totalXP / xpToNextPoint, pointsFree);
		dropData.func = function() m4xArtifactDB["view"] = "full"; UpdateValues(); end
		UIDropDownMenu_AddButton(dropData, dropLevel);

		dropData.text = string.format("|cff00ff00%.1f%%|r" .. (pointsFree > 0 and " (+%d)" or ""), 100 * totalXP / xpToNextPoint, pointsFree);
		dropData.func = function() m4xArtifactDB["view"] = "partial"; UpdateValues(); end
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

frame:SetScript("OnEnter", OnEnter);
frame:SetScript("OnLeave", OnLeave);