DFRL:NewDefaults("Focus", {
    enabled = { true },
    focusDarkMode = { 0, "slider", { 0, 1 }, nil, "focus appearance", 1, "Adjust dark mode intensity", nil, nil },
    textShow = { true, "checkbox", nil, nil, "focus text settings", 2, "Show health and mana text", nil, nil },
    noPercent = { true, "checkbox", nil, nil, "focus text settings", 3, "Show only current values without percentages", nil, nil },
    textColoring = { false, "checkbox", nil, nil, "focus text settings", 4, "Color text based on health/mana percentage", nil, nil },
    nameSize = { 11, "slider", { 8, 20, 0.5 }, nil, "focus text settings", 5, "Name text font size", nil, nil },
    levelSize = { 11, "slider", { 8, 20, 0.5 }, nil, "focus text settings", 6, "Level text font size", nil, nil },
    healthSize = { 15, "slider", { 8, 20, 0.5 }, nil, "focus text settings", 7, "Health text font size", nil, nil },
    manaSize = { 9, "slider", { 8, 20, 0.5 }, nil, "focus text settings", 8, "Mana text font size", nil, nil },
    frameFont = { "BigNoodleTitling", "dropdown", {
        "FRIZQT__.TTF",
        "Expressway",
        "Homespun",
        "Hooge",
        "Myriad-Pro",
        "Prototype",
        "PT-Sans-Narrow-Bold",
        "PT-Sans-Narrow-Regular",
        "RobotoMono",
        "BigNoodleTitling",
        "Continuum",
        "DieDieDie"
    }, nil, "text settings", 7, "Change the font used for the focus frame", nil, nil },
    colorReaction = { true, "checkbox", nil, nil, "focus bar color", 8, "Color health bar based on reaction", nil, nil },
    colorClass = { false, "checkbox", nil, nil, "focus bar color", 9, "Color health bar based on class", nil, nil },
    frameScale = { 1, "slider", { 0.7, 1.3 }, nil, "focus tweaks", 10, "Adjust frame size", nil, nil },
})

DFRL:NewMod("Focus", 1, function()
    local configCache = {
        noPercent = nil,
        textColoring = nil,
        lastUpdate = 0
    }

    local texpath = "Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\unitframes\\"
    local fontpath = "Interface\\AddOns\\-DragonflightReloaded\\media\\fnt\\"

    -- Build FocusFrame from scratch - no Blizzard frame exists in 1.12 for focus
    local FocusFrame = CreateFrame("Frame", "FocusFrame", UIParent)
    FocusFrame:SetWidth(232)
    FocusFrame:SetHeight(100)
    FocusFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -160)
    FocusFrame:SetMovable(true)
    FocusFrame:EnableMouse(true)
    FocusFrame:RegisterForDrag("LeftButton")
    FocusFrame:SetScript("OnMouseUp", function()
        if not (IsControlKeyDown() and IsShiftKeyDown() and IsAltKeyDown()) then
            TargetUnit("focus")
        end
    end)
    FocusFrame:Hide()

    local FocusFrameBackground = FocusFrame:CreateTexture("FocusFrameBackground", "BACKGROUND")
    FocusFrameBackground:SetWidth(256)
    FocusFrameBackground:SetHeight(128)
    FocusFrameBackground:SetPoint("TOPRIGHT", FocusFrame, "TOPRIGHT", 0, 0)
    FocusFrameBackground:SetTexture(texpath .. "UI-TargetingFrameDF1-Background.blp")

    local FocusFrameTexture = FocusFrame:CreateTexture("FocusFrameTexture", "ARTWORK")
    FocusFrameTexture:SetWidth(256)
    FocusFrameTexture:SetHeight(128)
    FocusFrameTexture:SetPoint("TOPRIGHT", FocusFrame, "TOPRIGHT", 0, 0)
    FocusFrameTexture:SetTexture(texpath .. "UI-TargetingFrameDF.blp")

    local FocusFrameHealthBar = CreateFrame("StatusBar", "FocusFrameHealthBar", FocusFrame)
    FocusFrameHealthBar:SetStatusBarTexture(texpath .. "healthDF2.tga")
    FocusFrameHealthBar:SetStatusBarColor(0, 1, 0)
    FocusFrameHealthBar:SetMinMaxValues(0, 100)
    FocusFrameHealthBar:SetValue(100)
    FocusFrameHealthBar:SetPoint("TOPRIGHT", FocusFrame, "TOPRIGHT", -100, -29)
    FocusFrameHealthBar:SetWidth(129)
    FocusFrameHealthBar:SetHeight(30)

    local FocusFrameManaBar = CreateFrame("StatusBar", "FocusFrameManaBar", FocusFrame)
    FocusFrameManaBar:SetStatusBarTexture(texpath .. "UI-HUD-UnitFrame-Target-PortraitOn-Bar-Mana-Status.blp")
    FocusFrameManaBar:SetStatusBarColor(0, 0, 1)
    FocusFrameManaBar:SetMinMaxValues(0, 100)
    FocusFrameManaBar:SetValue(100)
    FocusFrameManaBar:SetPoint("TOPRIGHT", FocusFrame, "TOPRIGHT", -100, -53)
    FocusFrameManaBar:SetWidth(129)
    FocusFrameManaBar:SetHeight(15)

    local FocusFramePortrait = FocusFrame:CreateTexture("FocusFramePortrait", "BACKGROUND")
    FocusFramePortrait:SetWidth(61)
    FocusFramePortrait:SetHeight(61)
    FocusFramePortrait:SetPoint("TOPRIGHT", FocusFrame, "TOPRIGHT", -42, -12)

    local FocusFrameName = FocusFrame:CreateFontString("FocusFrameName", "OVERLAY")
    FocusFrameName:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    FocusFrameName:SetTextColor(1, .82, 0)
    FocusFrameName:SetWidth(120)
    FocusFrameName:SetPoint("CENTER", FocusFrame, "CENTER", -40, 25)
    FocusFrameName:SetJustifyH("RIGHT")

    local FocusLevelText = FocusFrame:CreateFontString("FocusLevelText", "OVERLAY")
    FocusLevelText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    FocusLevelText:SetTextColor(1, .82, 0)
    FocusLevelText:SetPoint("CENTER", FocusFrame, "CENTER", -102, 25)

    local Setup = {
        texts = {
            healthPercent = nil,
            healthValue = nil,
            manaPercent = nil,
            manaValue = nil,
            config = {
                font = "Fonts\\FRIZQT__.TTF",
                healthFontSize = 12,
                manaFontSize = 9,
                nameFontSize = 9,
                levelFontSize = 9,
                outline = "OUTLINE",
                nameColor = { 1, .82, 0 },
                levelColor = { 1, .82, 0 },
            }
        },

        barColorState = {
            colorReaction = false,
            colorClass = false,
        }
    }

    function Setup:HealthBarText()
        local cfg = self.texts.config

        self.texts.healthTextFrame = CreateFrame("Frame", nil, FocusFrame)
        self.texts.healthTextFrame:SetAllPoints(FocusFrameHealthBar)
        self.texts.healthTextFrame:SetFrameStrata(FocusFrame:GetFrameStrata())
        self.texts.healthTextFrame:SetFrameLevel(FocusFrame:GetFrameLevel() + 2)

        self.texts.healthPercent = self.texts.healthTextFrame:CreateFontString(nil)
        self.texts.healthPercent:SetFont(cfg.font, cfg.healthFontSize, cfg.outline)
        self.texts.healthPercent:SetPoint("LEFT", FocusFrameHealthBar, "LEFT", 5, 0)

        self.texts.healthValue = self.texts.healthTextFrame:CreateFontString(nil)
        self.texts.healthValue:SetFont(cfg.font, cfg.healthFontSize, cfg.outline)
        self.texts.healthValue:SetPoint("RIGHT", FocusFrameHealthBar, "RIGHT", -5, 0)
    end

    function Setup:ManaBarText()
        local cfg = self.texts.config

        self.texts.manaTextFrame = CreateFrame("Frame", nil, FocusFrame)
        self.texts.manaTextFrame:SetAllPoints(FocusFrameManaBar)
        self.texts.manaTextFrame:SetFrameStrata(FocusFrame:GetFrameStrata())
        self.texts.manaTextFrame:SetFrameLevel(FocusFrame:GetFrameLevel() + 2)

        self.texts.manaPercent = self.texts.manaTextFrame:CreateFontString(nil)
        self.texts.manaPercent:SetFont(cfg.font, cfg.manaFontSize, cfg.outline)
        self.texts.manaPercent:SetPoint("LEFT", FocusFrameManaBar, "LEFT", 5, 0)

        self.texts.manaValue = self.texts.manaTextFrame:CreateFontString(nil)
        self.texts.manaValue:SetFont(cfg.font, cfg.manaFontSize, cfg.outline)
        self.texts.manaValue:SetPoint("RIGHT", FocusFrameManaBar, "RIGHT", -12, 0)
    end

    function Setup:UpdateManaBarColor()
        local info = ManaBarColor[UnitPowerType("focus")]
        if info then
            FocusFrameManaBar:SetStatusBarColor(info.r, info.g, info.b)
        end
    end

    function Setup:UpdateTexts()
        if not UnitExists("focus") then return end

        self:UpdateManaBarColor()

        local health = UnitHealth("focus")
        local maxHealth = UnitHealthMax("focus")
        local healthPercent = maxHealth > 0 and health / maxHealth or 0
        local healthPercentInt = math.floor(healthPercent * 100)

        local mana = UnitMana("focus")
        local maxMana = UnitManaMax("focus")
        local manaPercent = maxMana > 0 and mana / maxMana or 0
        local manaPercentInt = math.floor(manaPercent * 100)

        local now = GetTime()
        if not configCache.noPercent or not configCache.textColoring or (now - configCache.lastUpdate > 1) then
            configCache.noPercent = DFRL:GetTempDB("Focus", "noPercent")
            configCache.textColoring = DFRL:GetTempDB("Focus", "textColoring")
            configCache.lastUpdate = now
        end

        local noPercentEnabled = configCache.noPercent
        local coloringEnabled = configCache.textColoring
        local isDead = UnitIsDead("focus")

        FocusFrameHealthBar:SetMinMaxValues(0, maxHealth > 0 and maxHealth or 1)
        FocusFrameHealthBar:SetValue(health)

        FocusFrameManaBar:SetMinMaxValues(0, maxMana > 0 and maxMana or 1)
        FocusFrameManaBar:SetValue(mana)

        if noPercentEnabled then
            self.texts.healthPercent:SetText("")
            if isDead then
                self.texts.healthValue:SetText("")
            else
                self.texts.healthValue:SetText(health)
            end
            self.texts.healthValue:ClearAllPoints()
            self.texts.healthValue:SetPoint("CENTER", FocusFrameHealthBar, "CENTER", 0, 0)

            self.texts.manaPercent:SetText("")
            if maxMana > 0 then
                self.texts.manaValue:SetText(mana)
                self.texts.manaValue:ClearAllPoints()
                self.texts.manaValue:SetPoint("CENTER", FocusFrameManaBar, "CENTER", 0, 0)
            else
                self.texts.manaValue:SetText("")
            end
        else
            if isDead then
                self.texts.healthPercent:SetText("")
                self.texts.healthValue:SetText("")
            else
                self.texts.healthPercent:SetText(healthPercentInt .. "%")
                self.texts.healthValue:SetText(health)
            end
            self.texts.healthValue:ClearAllPoints()
            self.texts.healthValue:SetPoint("RIGHT", FocusFrameHealthBar, "RIGHT", 0, 0)

            if maxMana > 0 then
                self.texts.manaPercent:SetText(manaPercentInt .. "%")
                self.texts.manaValue:SetText(mana)
                self.texts.manaValue:ClearAllPoints()
                self.texts.manaValue:SetPoint("RIGHT", FocusFrameManaBar, "RIGHT", 0, 0)
            else
                self.texts.manaPercent:SetText("")
                self.texts.manaValue:SetText("")
            end
        end

        if coloringEnabled then
            local r, g, b = 1, healthPercent, healthPercent
            self.texts.healthPercent:SetTextColor(r, g, b)
            self.texts.healthValue:SetTextColor(r, g, b)

            if maxMana > 0 then
                self.texts.manaPercent:SetTextColor(1, manaPercent, manaPercent)
                self.texts.manaValue:SetTextColor(1, manaPercent, manaPercent)
            end
        else
            self.texts.healthPercent:SetTextColor(1, 1, 1)
            self.texts.healthValue:SetTextColor(1, 1, 1)
            self.texts.manaPercent:SetTextColor(1, 1, 1)
            self.texts.manaValue:SetTextColor(1, 1, 1)
        end

        FocusFrameName:SetText(UnitName("focus") or "")

        local focusLevel = UnitLevel("focus")
        if UnitIsCorpse("focus") then
            FocusLevelText:SetText("")
        elseif focusLevel and focusLevel > 0 then
            FocusLevelText:SetText(focusLevel)
            if UnitCanAttack("player", "focus") then
                local color = GetDifficultyColor(focusLevel)
                FocusLevelText:SetTextColor(color.r, color.g, color.b)
            else
                FocusLevelText:SetTextColor(1, 0.82, 0)
            end
        else
            FocusLevelText:SetText("??")
            FocusLevelText:SetTextColor(1, 0, 0)
        end

        SetPortraitTexture(FocusFramePortrait, "focus")
    end

    function Setup:UpdateClassification()
        FocusFrameHealthBar:SetStatusBarTexture(texpath .. "healthDF2.tga")
        FocusFrameManaBar:SetStatusBarTexture(texpath .. "UI-HUD-UnitFrame-Target-PortraitOn-Bar-Mana-Status.blp")

        local classification = UnitClassification("focus")
        if classification == "worldboss" then
            FocusFrameTexture:SetTexture(texpath .. "UI-TargetingFrame-Boss.blp")
        elseif classification == "rareelite" then
            FocusFrameTexture:SetTexture(texpath .. "UI-TargetingFrame-RareElite.blp")
        elseif classification == "elite" then
            FocusFrameTexture:SetTexture(texpath .. "UI-TargetingFrame-Elite.blp")
        elseif classification == "rare" then
            FocusFrameTexture:SetTexture(texpath .. "UI-TargetingFrame-Rare.blp")
        else
            FocusFrameTexture:SetTexture(texpath .. "UI-TargetingFrameDF.blp")
        end
    end

    function Setup:UpdateBarColor()
        if not UnitExists("focus") then return end

        if not UnitIsPlayer("focus") and UnitIsTapped("focus") and not UnitIsTappedByPlayer("focus") then
            FocusFrameHealthBar:SetStatusBarColor(0.5, 0.5, 0.5)
            return
        end

        if self.barColorState.colorClass and UnitIsPlayer("focus") then
            local _, class = UnitClass("focus")
            if class and RAID_CLASS_COLORS[class] then
                local color = RAID_CLASS_COLORS[class]
                FocusFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
                return
            end
        end

        if self.barColorState.colorReaction then
            local reaction = UnitReaction("player", "focus")
            if reaction then
                if reaction <= 2 then
                    FocusFrameHealthBar:SetStatusBarColor(1, 0, 0)
                elseif reaction == 3 or reaction == 4 then
                    FocusFrameHealthBar:SetStatusBarColor(1, 1, 0)
                else
                    FocusFrameHealthBar:SetStatusBarColor(0, 1, 0)
                end
                return
            end
        end

        FocusFrameHealthBar:SetStatusBarColor(0, 1, 0)
    end

    function Setup:Run()
        self:HealthBarText()
        self:ManaBarText()
    end

    Setup:Run()

    -- callbacks
    local callbacks = {}

    callbacks.focusDarkMode = function(value)
        local intensity = value or 0
        local c = 1 - intensity
        FocusFrameTexture:SetVertexColor(c, c, c)
        FocusFrameBackground:SetVertexColor(c, c, c)
    end

    callbacks.textShow = function(value)
        if value then
            Setup.texts.healthPercent:Show()
            Setup.texts.healthValue:Show()
            Setup.texts.manaPercent:Show()
            Setup.texts.manaValue:Show()
        else
            Setup.texts.healthPercent:Hide()
            Setup.texts.healthValue:Hide()
            Setup.texts.manaPercent:Hide()
            Setup.texts.manaValue:Hide()
        end
    end

    callbacks.noPercent = function(value)
        configCache.noPercent = value
        configCache.lastUpdate = GetTime()
        Setup:UpdateTexts()
    end

    callbacks.textColoring = function(value)
        configCache.textColoring = value
        configCache.lastUpdate = GetTime()
        Setup:UpdateTexts()
    end

    callbacks.nameSize = function(value)
        Setup.texts.config.nameFontSize = value
        FocusFrameName:SetFont(Setup.texts.config.font, value, "OUTLINE")
    end

    callbacks.levelSize = function(value)
        Setup.texts.config.levelFontSize = value
        FocusLevelText:SetFont(Setup.texts.config.font, value, "OUTLINE")
    end

    callbacks.healthSize = function(value)
        Setup.texts.config.healthFontSize = value
        Setup.texts.healthPercent:SetFont(Setup.texts.config.font, value, Setup.texts.config.outline)
        Setup.texts.healthValue:SetFont(Setup.texts.config.font, value, Setup.texts.config.outline)
    end

    callbacks.manaSize = function(value)
        Setup.texts.config.manaFontSize = value
        Setup.texts.manaPercent:SetFont(Setup.texts.config.font, value, Setup.texts.config.outline)
        Setup.texts.manaValue:SetFont(Setup.texts.config.font, value, Setup.texts.config.outline)
    end

    callbacks.frameFont = function(value)
        local fontPath
        if value == "Expressway" then
            fontPath = fontpath .. "Expressway.ttf"
        elseif value == "Homespun" then
            fontPath = fontpath .. "Homespun.ttf"
        elseif value == "Hooge" then
            fontPath = fontpath .. "Hooge.ttf"
        elseif value == "Myriad-Pro" then
            fontPath = fontpath .. "Myriad-Pro.ttf"
        elseif value == "Prototype" then
            fontPath = fontpath .. "Prototype.ttf"
        elseif value == "PT-Sans-Narrow-Bold" then
            fontPath = fontpath .. "PT-Sans-Narrow-Bold.ttf"
        elseif value == "PT-Sans-Narrow-Regular" then
            fontPath = fontpath .. "PT-Sans-Narrow-Regular.ttf"
        elseif value == "RobotoMono" then
            fontPath = fontpath .. "RobotoMono.ttf"
        elseif value == "BigNoodleTitling" then
            fontPath = fontpath .. "BigNoodleTitling.ttf"
        elseif value == "Continuum" then
            fontPath = fontpath .. "Continuum.ttf"
        elseif value == "DieDieDie" then
            fontPath = fontpath .. "DieDieDie.ttf"
        else
            fontPath = "Fonts\\FRIZQT__.TTF"
        end

        Setup.texts.config.font = fontPath
        Setup.texts.healthPercent:SetFont(fontPath, Setup.texts.config.healthFontSize, "OUTLINE")
        Setup.texts.healthValue:SetFont(fontPath, Setup.texts.config.healthFontSize, "OUTLINE")
        Setup.texts.manaPercent:SetFont(fontPath, Setup.texts.config.manaFontSize, "OUTLINE")
        Setup.texts.manaValue:SetFont(fontPath, Setup.texts.config.manaFontSize, "OUTLINE")
        FocusFrameName:SetFont(fontPath, Setup.texts.config.nameFontSize, "OUTLINE")
        FocusLevelText:SetFont(fontPath, Setup.texts.config.levelFontSize, "OUTLINE")
    end

    callbacks.colorReaction = function(value)
        Setup.barColorState.colorReaction = value
        Setup:UpdateBarColor()
    end

    callbacks.colorClass = function(value)
        Setup.barColorState.colorClass = value
        Setup:UpdateBarColor()
    end

    callbacks.frameScale = function(value)
        FocusFrame:SetScale(value)
    end

    -- event handler
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_FOCUS_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UNIT_HEALTH_GUID")
    f:RegisterEvent("UNIT_MANA_GUID")
    f:RegisterEvent("UNIT_ENERGY_GUID")
    f:RegisterEvent("UNIT_RAGE_GUID")
    f:SetScript("OnEvent", function()
        if event == "PLAYER_FOCUS_CHANGED" then
            local guid = UnitGUID("focus")
            if guid then
                FocusFrame:Show()
                Setup:UpdateClassification()
                Setup:UpdateTexts()
                Setup:UpdateBarColor()
            else
                FocusFrame:Hide()
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
            FocusFrame:Hide()
            f:UnregisterEvent("PLAYER_ENTERING_WORLD")
            -- frames.lua may fire its PLAYER_ENTERING_WORLD before or after ours,
            -- so poll briefly until MakeFrameMovable is available
            local waited = 0
            local ticker = CreateFrame("Frame")
            ticker:SetScript("OnUpdate", function()
                waited = waited + arg1
                if DFRL.MakeFrameMovable then
                    DFRL.MakeFrameMovable(FocusFrame)
                    this:SetScript("OnUpdate", nil)
                elseif waited > 5 then
                    this:SetScript("OnUpdate", nil)
                end
            end)
        elseif event == "UNIT_HEALTH_GUID" or
            event == "UNIT_MANA_GUID" or
            event == "UNIT_ENERGY_GUID" or
            event == "UNIT_RAGE_GUID" then
            local focusGuid = UnitGUID("focus")
            if focusGuid and arg1 == focusGuid then
                Setup:UpdateTexts()
                Setup:UpdateBarColor()
            end
        end
    end)

    -- slash commands
    _G["SLASH_FOCUS1"] = "/focus"
    _G.SlashCmdList["FOCUS"] = function()
        FocusUnit("target")
    end

    _G["SLASH_CLEARFOCUS1"] = "/clearfocus"
    _G.SlashCmdList["CLEARFOCUS"] = function()
        ClearFocus()
    end

    -- execute callbacks
    DFRL:NewCallbacks("Focus", callbacks)
end)
