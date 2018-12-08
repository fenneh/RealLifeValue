
C_WowTokenPublic.UpdateMarketPrice()

gbpTokenprice = 1700
euTokenPrice = 2000
usTokenPrice = 2000
allcurrencies = true

SLASH_RLVALUE1 = '/rlvalue'
SlashCmdList['RLVALUE'] = function(msg)
    msg = string.lower(msg)
    if msg == 'gbp' then
        allcurrencies = false
        currency = "gbp"
    elseif msg == 'eur' then
        allcurrencies = false
        currency = "eur"
    elseif msg == 'usd' then
        allcurrencies = false
        currency = "usd"
    else
        allcurrencies = true
    end
    if allcurrencies == true then
        print("Real Life Value - Will show all currencies")
    else
        print("Real Life Value - Will show only",(currency))
    end    
end

SLASH_MYRLVALUE1 = '/myrlvalue'
SlashCmdList['MYRLVALUE'] = function()
    local monies = GetMoney() / 100
    tokenGold = C_WowTokenPublic.GetCurrentMarketPrice()
    gbpExchangeRate = tokenGold / gbpTokenprice
    euExchangeRate = tokenGold / euTokenPrice
    usExchangeRate = tokenGold / usTokenPrice
    gbpRealPrice = monies / gbpExchangeRate
    euRealPrice = monies / euExchangeRate
    usdRealPrice = monies / usExchangeRate
    print ("I am worth £"..gbpRealPrice..", €"..euRealPrice..", $"..usdRealPrice.."")
end


local function OnTooltipSetItem(self)
   local name, link = self:GetItem()
    
    if not link then
        return
    end

   local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(link)
   
   local itemStackCount = tonumber(itemStackCount)
   local leftString = "Vendor Price"

    -- Undermine Journal support
    if IsAddOnLoaded(string.lower("TheUndermineJournal")) then
        underminePrice = TUJMarketInfo(itemLink);
        if underminePrice then
            underminePrice = tonumber(underminePrice['recent'])
            itemSellPrice = underminePrice
            itemStackPrice = underminePrice * itemStackCount
            leftString = "3-Day Price"
        end
    end

    if itemSellPrice and itemSellPrice > 0 then
        gbpExchangeRate =  C_WowTokenPublic.GetCurrentMarketPrice() / gbpTokenprice
        euExchangeRate =  C_WowTokenPublic.GetCurrentMarketPrice() / euTokenPrice
        usExchangeRate =  C_WowTokenPublic.GetCurrentMarketPrice() / usTokenPrice
        gbpRealPrice = itemSellPrice / gbpExchangeRate
        euRealPrice = itemSellPrice / euExchangeRate
        usdRealPrice = itemSellPrice / usExchangeRate
        gbpRealPrice = math.floor(gbpRealPrice) / 100
        euRealPrice = math.floor(euRealPrice) / 100
        usdRealPrice = math.floor(usdRealPrice) / 100
        if (gbpRealPrice < 0.01) then
            GameTooltip:AddDoubleLine(leftString, "<£/€/$0.01", 1, 1, 0, 0.5, 0.5, 0.5)
            if underminePrice then 
                if (currency == 'gbp') then 
                    GameTooltip:AddDoubleLine("3-Day Stack Price", "£" .. string.format("%.2f", (gbpRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
                end      
                if (currency == 'eur') then 
                    GameTooltip:AddDoubleLine("3-Day Stack Price", "€" .. string.format("%.2f", (euRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
                end
                if (currency == 'usd') then
                    GameTooltip:AddDoubleLine("3-Day Stack Price", "$" .. string.format("%.2f", (usdRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
                end
            end
        else 
            if (allcurrencies == true) then 
                GameTooltip:AddDoubleLine(leftString, "£" .. string.format("%.2f", gbpRealPrice), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine(leftString, "€" .. string.format("%.2f", euRealPrice), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine(leftString, "$" .. string.format("%.2f", usdRealPrice), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("3-Day Stack Price", "£" .. string.format("%.2f", (gbpRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("3-Day Stack Price", "€" .. string.format("%.2f", (euRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("3-Day Stack Price", "$" .. string.format("%.2f", (usdRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
            end
            if (currency == "gbp") then 
                GameTooltip:AddDoubleLine(leftString, "£" .. string.format("%.2f", gbpRealPrice), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("3-Day Stack Price", "£" .. string.format("%.2f", (gbpRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
            end      
            if (currency == "eur") then 
                GameTooltip:AddDoubleLine(leftString, "€" .. string.format("%.2f", euRealPrice), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("3-Day Stack Price", "€" .. string.format("%.2f", (euRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
            end
            if (currency == "usd") then
                GameTooltip:AddDoubleLine(leftString, "$" .. string.format("%.2f", usdRealPrice), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("3-Day Stack Price", "$" .. string.format("%.2f", (usdRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
            end
        end
        cleared = true
    end
end

GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
C_Timer.NewTicker(301, C_WowTokenPublic.UpdateMarketPrice)
