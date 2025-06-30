DFRL:NewDefaults("Menu", {
    enabled = { true },
})

DFRL:NewMod("Menu", 1, function()
    debugprint(">> BOOTING")

    --=================
    -- SETUP
    --=================
    local Setup = {
        menuframe = nil,
        w = 200,
        h = 430,
        gap = 0,
        space = 15,
        btnw = 120,
        btnh = 30,
    }

    function Setup:KillBlizz()
        KillFrame(GameMenuFrame)

        _G.ToggleGameMenu = function()
            if StaticPopup_EscapePressed() then
                return
            elseif Setup.menuframe:IsVisible() then
                Setup.menuframe:Hide()
            else
                local closedMenus = CloseMenus()
                local closedWindows = CloseAllWindows()
                if not (closedMenus or closedWindows) then
                    if UnitExists("target") then
                        ClearTarget()
                    else
                        Setup.menuframe:Show()
                    end
                end
            end
        end

        local origShowUIPanel = ShowUIPanel
        _G.ShowUIPanel = function(frame, force)
            if frame == GameMenuFrame then
                return
            end
            return origShowUIPanel(frame, force)
        end

        _G.Disable_BagButtons = function() end
    end

    function Setup:MenuFrame()
        if not self.menuframe then
            self.menuframe = T.CreateDFRLFrame(nil, self.w, self.h)
            self.menuframe:SetPoint("CENTER", 0,0)
            self.menuframe:EnableMouse(true)
            self.menuframe:Hide()

            local drBtn = DFRL.tools.CreateButton(self.menuframe, "|cFFFFD100Dragonflight:|r Reloaded", self.btnw, self.btnh)
            drBtn:SetPoint("TOP", self.menuframe, "TOP", 0, -self.space)
            drBtn:SetScript("OnClick", function()
                self.menuframe:Hide()
                _G.SlashCmdList["DFRL"]()

            end)

            local addonsBtn = DFRL.tools.CreateButton(self.menuframe, "Addon Manager", self.btnw, self.btnh)
            addonsBtn:SetPoint("TOP", drBtn, "BOTTOM", 0, -self.gap)
            addonsBtn:SetScript("OnClick", function()
                self.menuframe:Hide()
                if DFRL.addonFrame then
                    DFRL.addonFrame:Show()
                end
            end)

            local donationBtn = DFRL.tools.CreateButton(self.menuframe, "|cFFFFD100Donation Rewards", self.btnw, self.btnh)
            donationBtn:SetPoint("TOP", addonsBtn, "BOTTOM", 0, -self.space)
            donationBtn:SetScript("OnClick", function()
                self.menuframe:Hide()
                 ShopFrame_Toggle()
            end)

            local videoBtn = DFRL.tools.CreateButton(self.menuframe, "Video Options", self.btnw, self.btnh)
            videoBtn:SetPoint("TOP", donationBtn, "BOTTOM", 0, -self.space)
            videoBtn:SetScript("OnClick", function()
                self.menuframe:Hide()
                ShowUIPanel(OptionsFrame)
            end)

            local soundBtn = DFRL.tools.CreateButton(self.menuframe, "Sound Options", self.btnw, self.btnh)
            soundBtn:SetPoint("TOP", videoBtn, "BOTTOM", 0, -self.gap)
            soundBtn:SetScript("OnClick", function()
                self.menuframe:Hide()
                ShowUIPanel(SoundOptionsFrame)
            end)

            local uiBtn = DFRL.tools.CreateButton(self.menuframe, "UI Options", self.btnw, self.btnh)
            uiBtn:SetPoint("TOP", soundBtn, "BOTTOM", 0, -self.gap)
            uiBtn:SetScript("OnClick", function()
                self.menuframe:Hide()
                ShowUIPanel(UIOptionsFrame)
            end)

            local keyBtn = DFRL.tools.CreateButton(self.menuframe, "Key Bindings", self.btnw, self.btnh)
            keyBtn:SetPoint("TOP", uiBtn, "BOTTOM", 0, -self.space)
            keyBtn:SetScript("OnClick", function()
                self.menuframe:Hide()
                KeyBindingFrame_LoadUI()
                ShowUIPanel(KeyBindingFrame)
            end)

            local macroBtn = DFRL.tools.CreateButton(self.menuframe, "Macros", self.btnw, self.btnh)
            macroBtn:SetPoint("TOP", keyBtn, "BOTTOM", 0, -self.gap)
            macroBtn:SetScript("OnClick", function()
                self.menuframe:Hide()
                ShowMacroFrame()
            end)

            local logBtn = DFRL.tools.CreateButton(self.menuframe, "Logout", self.btnw, self.btnh)
            logBtn:SetPoint("TOP", macroBtn, "BOTTOM", 0, -self.space)
            logBtn:SetScript("OnClick", function()
                self.menuframe:Hide()
                Logout()
            end)

            local exitBtn = DFRL.tools.CreateButton(self.menuframe, "Exit Game", self.btnw, self.btnh)
            exitBtn:SetPoint("TOP", logBtn, "BOTTOM", 0, -self.gap)
            exitBtn:SetScript("OnClick", function()
                self.menuframe:Hide()
                Quit()
            end)

            local resumeBtn = DFRL.tools.CreateButton(self.menuframe, "Resume Game", self.btnw, self.btnh)
            resumeBtn:SetPoint("TOP", exitBtn, "BOTTOM", 0, -self.gap)
            resumeBtn:SetScript("OnClick", function() self.menuframe:Hide() end)
        end
    end

    --=================
    -- INIT
    --=================
    function Setup:Run()
        self:KillBlizz()
        self:MenuFrame()
    end

    Setup:Run()

    --=================
    -- CALLBACKS
    --=================
    local callbacks = {}

    --=================
    -- EVENT
    --=================

    DFRL:NewCallbacks("Menu", callbacks)
end)
