local addonName, addon = ...

-- Constants for WoW Token prices in real money
local CURRENCIES = {
    gbp = { symbol = "£", tokenPrice = 17, name = "British Pound" },
    eur = { symbol = "€", tokenPrice = 20, name = "Euro" },
    usd = { symbol = "$", tokenPrice = 20, name = "US Dollar" }
}

-- Saved variables
RealLifeValueDB = RealLifeValueDB or { 
    currency = "gbp",
    point = "CENTER",
    relativePoint = "CENTER",
    xOfs = 0,
    yOfs = 0
}

-- State
local currentCurrency = "gbp"

-- Initialize the addon
local function Initialize()
    C_WowTokenPublic.UpdateMarketPrice()
end

-- Helper function to convert gold to real money
local function ConvertGoldToRealMoney(goldAmount, currency)
    local tokenPrice = C_WowTokenPublic.GetCurrentMarketPrice()
    if not tokenPrice or tokenPrice == 0 then return nil end
    
    -- tokenPrice is in copper, convert to gold
    local tokenGoldPrice = tokenPrice / 10000
    
    -- Calculate conversion rate (gold per currency unit)
    local goldPerCurrency = tokenGoldPrice / CURRENCIES[currency].tokenPrice
    
    -- Convert gold amount to currency
    return goldAmount / goldPerCurrency
end

-- Helper functions
local function FormatCurrencyValue(value)
    if not value or value < 0.01 then return "<0.01" end
    return string.format("%.2f", value)
end

-- Tooltip modification
local function AddTooltipLine(tooltip, label, value, r, g, b)
    if value then
        tooltip:AddDoubleLine(label, value, r or 1, g or 1, b or 0, r or 1, g or 1, b or 0)
    end
end

local function GetAuctionatorPrice(itemLink)
    -- Check if Auctionator is loaded
    if not C_AddOns.IsAddOnLoaded("Auctionator") then
        return nil
    end

    -- Get the price using Auctionator's v1 API
    if Auctionator and Auctionator.API and Auctionator.API.v1 then
        local price = Auctionator.API.v1.GetAuctionPriceByItemLink("RealLifeValue", itemLink)
        if price then
            return price / 10000  -- Convert copper to gold
        end
    end
    
    return nil
end

local function GetItemPrice(link)
    -- Try to get Auctionator price first
    local auctionPrice = GetAuctionatorPrice(link)
    if auctionPrice then
        return auctionPrice, "Price"
    end
    
    -- Then try UnderMine Journal
    if C_AddOns.IsAddOnLoaded("TheUndermineJournal") and TUJMarketInfo then
        local tujData = TUJMarketInfo(link)
        if tujData and tujData['recent'] and tujData['recent'] > 0 then
            return (tujData['recent'] / 10000), "Price"
        end
    end
    
    -- Fall back to vendor price
    local vendorPrice = select(11, GetItemInfo(link)) or 0
    return (vendorPrice / 10000), "Vendor Price"
end

local function OnTooltipSetItem(tooltip)
    local name, link = TooltipUtil.GetDisplayedItem(tooltip)
    if not link then return end

    local itemInfo = C_Item.GetItemInfo(link)
    if not itemInfo then return end

    local stackCount = select(8, GetItemInfo(link)) or 1
    local goldPrice, priceSource = GetItemPrice(link)
    
    if goldPrice and goldPrice > 0 then
        local realPrice = ConvertGoldToRealMoney(goldPrice, currentCurrency)
        if realPrice then
            local info = CURRENCIES[currentCurrency]
            AddTooltipLine(tooltip, info.symbol .. " " .. priceSource, 
                         info.symbol .. FormatCurrencyValue(realPrice))
            if stackCount > 1 then
                AddTooltipLine(tooltip, info.symbol .. " Stack Price", 
                             info.symbol .. FormatCurrencyValue(realPrice * stackCount))
            end
        end
    end
end

-- Create the settings UI
local function CreateSettingsUI()
    -- Create the main frame
    local frame = CreateFrame("Frame", "RealLifeValueSettings", UIParent, "BackdropTemplate")
    frame:SetSize(300, 200)
    frame:SetFrameStrata("DIALOG")
    
    -- Save position between sessions
    frame:SetPoint(
        RealLifeValueDB.point or "CENTER",
        UIParent,
        RealLifeValueDB.relativePoint or "CENTER",
        RealLifeValueDB.xOfs or 0,
        RealLifeValueDB.yOfs or 0
    )
    
    -- Use the correct API for retail/classic backdrops
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        frame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
    else
        -- Classic backdrop handling
        frame.backdropInfo = {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        }
        frame:ApplyBackdrop()
    end
    
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    
    -- Save position when dragged
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint(1)
        RealLifeValueDB.point = point
        RealLifeValueDB.relativePoint = relativePoint
        RealLifeValueDB.xOfs = xOfs
        RealLifeValueDB.yOfs = yOfs
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
    
    -- Add title with better styling
    local titleBg = frame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
    titleBg:SetTexCoord(0.31, 0.67, 0, 0.63)
    titleBg:SetPoint("TOP", 0, 12)
    titleBg:SetSize(150, 40)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", titleBg, "TOP", 0, -14)
    title:SetText("RealLifeValue Settings")

    -- Create radio buttons
    local radioButtons = {}
    local yOffset = -50

    -- Status text for token price
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("TOPLEFT", 16, -30)
    
    -- Update status text periodically
    local function UpdateStatusText()
        local tokenPrice = C_WowTokenPublic.GetCurrentMarketPrice()
        if tokenPrice and tokenPrice > 0 then
            if GetCoinTextureString then
                statusText:SetText("Current Token Price: " .. GetCoinTextureString(tokenPrice))
            else
                -- Fallback if GetCoinTextureString isn't available
                local gold = math.floor(tokenPrice / 10000)
                statusText:SetText("Current Token Price: " .. gold .. "g")
            end
            statusText:SetTextColor(0, 1, 0)
        else
            statusText:SetText("Token Price: Updating...")
            statusText:SetTextColor(1, 1, 0)
        end
    end
    
    -- Create enhanced radio buttons
    local function CreateRadioButton(currency, label)
        local button = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate")
        button:SetPoint("TOPLEFT", 20, yOffset)
        button.currency = currency
        
        -- Get the text object properly
        local text = button.Text or button:GetFontString()
        if not text then
            text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", button, "RIGHT", 5, 0)
        end
        text:SetText(label)
        
        button:SetScript("OnClick", function(self)
            -- Just uncheck other buttons, no color changes
            for _, otherButton in pairs(radioButtons) do
                if otherButton ~= self then
                    otherButton:SetChecked(false)
                end
            end
        end)
        
        return button
    end

    -- Create radio button for each currency
    for currency, info in pairs(CURRENCIES) do
        radioButtons[currency] = CreateRadioButton(currency, info.symbol .. " - " .. info.name)
        yOffset = yOffset - 25
    end

    -- Save button with enhanced styling
    local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 22)
    saveButton:SetPoint("BOTTOMRIGHT", -16, 16)
    saveButton:SetText("Save")
    
    -- Cancel button
    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetSize(100, 22)
    cancelButton:SetPoint("BOTTOMLEFT", 16, 16)
    cancelButton:SetText("Cancel")
    
    cancelButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    saveButton:SetScript("OnClick", function()
        local selectedCurrency = nil
        for currency, button in pairs(radioButtons) do
            if button:GetChecked() then
                selectedCurrency = currency
                break
            end
        end
        
        if selectedCurrency then
            -- Save settings
            RealLifeValueDB.currency = selectedCurrency
            currentCurrency = selectedCurrency
            print("|cFF00FF00RealLifeValue:|r Currency set to " .. CURRENCIES[selectedCurrency].name)
            frame:Hide()
        else
            print("|cFFFF0000RealLifeValue:|r Please select a currency")
        end
    end)

    -- Function to update UI state based on saved settings
    frame.UpdateState = function()
        -- Check the currently selected currency
        for currency, button in pairs(radioButtons) do
            local isSelected = currency == RealLifeValueDB.currency
            button:SetChecked(isSelected)
        end
        UpdateStatusText()
    end

    -- Update token price status periodically
    if C_Timer then
        C_Timer.NewTicker(5, UpdateStatusText)
    end

    -- Add a help text
    local helpText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    helpText:SetPoint("BOTTOM", 0, 45)
    helpText:SetText("Use /myrlvalue to check your character's worth")
    helpText:SetTextColor(1, 0.82, 0)

    frame:Hide()
    return frame
end

-- Initialize settings frame
RealLifeValueSettings = CreateSettingsUI()

-- Enhanced slash commands with better feedback
SLASH_RLVALUE1 = '/rlvalue'
SlashCmdList['RLVALUE'] = function(msg)
    if RealLifeValueSettings then
        if RealLifeValueSettings:IsShown() then
            RealLifeValueSettings:Hide()
        else
            RealLifeValueSettings:Show()
            RealLifeValueSettings.UpdateState()
        end
    else
        print("|cFFFF0000RealLifeValue:|r Error loading settings UI. Try reloading UI (/reload).")
    end
end

SLASH_MYRLVALUE1 = '/myrlvalue'
SlashCmdList['MYRLVALUE'] = function()
    local playerGold = GetMoney() / 10000  -- Convert copper to gold
    local realPrice = ConvertGoldToRealMoney(playerGold, currentCurrency)
    if realPrice then
        local info = CURRENCIES[currentCurrency]
        print("|cFF00FF00RealLifeValue:|r Your current gold is worth " .. info.symbol .. FormatCurrencyValue(realPrice))
    else
        print("|cFFFF0000RealLifeValue:|r Could not get current token price. Please try again later.")
    end
end

-- Event handling and initialization
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        Initialize()
        -- Load saved settings
        currentCurrency = RealLifeValueDB.currency or "gbp"
        
        -- Register tooltip hooks based on WoW version
        if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
        else
            -- Classic tooltip hook
            GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
        end
        
        -- Print loaded message
        print("|cFF00FF00RealLifeValue loaded.|r Type /rlvalue for settings.")
    end
end)

-- Update token price periodically
if C_Timer then
    C_Timer.NewTicker(300, function() 
        C_WowTokenPublic.UpdateMarketPrice()
    end)
end