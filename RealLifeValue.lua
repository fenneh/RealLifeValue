
C_WowTokenPublic.UpdateMarketPrice()

gbpTokenPrice = 1700
eurTokenPrice = 2000
usdTokenPrice = 2000
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
    gbpExchangeRate = tokenGold / gbpTokenPrice
    eurExchangeRate = tokenGold / eurTokenPrice
    usdExchangeRate = tokenGold / usdTokenPrice
    gbpRealPrice = monies / gbpExchangeRate
    eurRealPrice = monies / eurExchangeRate
    usdRealPrice = monies / usdExchangeRate
    print ("I am worth £"..gbpRealPrice..", €"..eurRealPrice..", $"..usdRealPrice.."")
end


local function OnTooltipSetItem(self)
    tokenGold = C_WowTokenPublic.GetCurrentMarketPrice()
    local name, link = self:GetItem()
    
    if not link then
        return
    end

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(link)
    
    local itemStackCount = tonumber(itemStackCount)
    local leftString = "Vendor Price"

    gbpExchangeRate = tokenGold / gbpTokenPrice
    eurExchangeRate = tokenGold / eurTokenPrice
    usdExchangeRate = tokenGold / usdTokenPrice

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

    if (itemSellPrice > 0) then
        gbpRealPrice = itemSellPrice / gbpExchangeRate
        eurRealPrice = itemSellPrice / eurExchangeRate
        usdRealPrice = itemSellPrice / usdExchangeRate

        gbpRealPrice = (gbpRealPrice) / 100
        eurRealPrice = (eurRealPrice) / 100
        usdRealPrice = (usdRealPrice) / 100
    end

    -- Auctionator Support
    if IsAddOnLoaded(string.lower("Auctionator")) then
        auctionatorPrice = Atr_GetAuctionBuyout(itemLink);
        if auctionatorPrice then 
            auctionatorPrice = tonumber(auctionatorPrice)
            auctionatorStackprice = auctionatorPrice * itemStackCount
            auctionatorGBPReal = auctionatorPrice / gbpExchangeRate
            auctionatorGBP = (auctionatorGBPReal) / 100
            auctionatorStackGBP = (auctionatorStackprice / gbpExchangeRate) / 100
            auctionatorUSD = (auctionatorPrice / usdExchangeRate) / 100
            auctionatorStackUSD = (auctionatorStackprice / usdExchangeRate) / 100
            auctionatorEUR = (auctionatorPrice / eurExchangeRate) / 100
            auctionatorStackEUR = (auctionatorStackprice / eurExchangeRate) / 100
        end
    end

    if (gbpRealPrice < 0.0001) then
        GameTooltip:AddDoubleLine(leftString, "<£/€/$0.0001", 1, 1, 0, 0.5, 0.5, 0.5)
        if underminePrice then 
            if (currency == 'gbp') then 
                GameTooltip:AddDoubleLine("3-Day Stack Price", "£" .. string.format("%.4f", (gbpRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
            end      
            if (currency == 'eur') then 
                GameTooltip:AddDoubleLine("3-Day Stack Price", "€" .. string.format("%.4f", (eurRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
            end
            if (currency == 'usd') then
                GameTooltip:AddDoubleLine("3-Day Stack Price", "$" .. string.format("%.4f", (usdRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
            end
        end

        if (auctionatorGBP > 0.0001) then 
            if (currency == 'gbp') then 
                GameTooltip:AddDoubleLine("Auctionator Price", "£" .. string.format("%.4f", (auctionatorGBP)), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("Auctionator Stack Price", "£" .. string.format("%.4f", (auctionatorStackGBP)), 1, 1, 0, 1, 1, 0)
            end      
            if (currency == 'eur') then 
                GameTooltip:AddDoubleLine("Auctionator Price", "€" .. string.format("%.4f", (auctionatorEUR)), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("Auctionator Stack Price", "€" .. string.format("%.4f", (auctionatorStackEUR)), 1, 1, 0, 1, 1, 0)
            end
            if (currency == 'usd') then
                GameTooltip:AddDoubleLine("Auctionator Price", "$" .. string.format("%.4f", (auctionatorUSD)), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("Auctionator Stack Price", "$" .. string.format("%.4f", (auctionatorStackUSD)), 1, 1, 0, 1, 1, 0)
            end
        end   
    else 
        if (allcurrencies == true) then
            GameTooltip:AddDoubleLine(leftString, "" .. string.format("£%.4f €%.4f $%.4f", gbpRealPrice, eurRealPrice, usdRealPrice), 1, 1, 0, 1, 1, 0)
            GameTooltip:AddDoubleLine("3-Day Stack Price", "" .. string.format("£%.4f €%.4f $%.4f", (gbpRealPrice * itemStackCount), (eurRealPrice * itemStackCount), (usdRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)

            if (auctionatorGBP > 0.001) then
                GameTooltip:AddDoubleLine("Auctionator Price", "" .. string.format("£%.4f €%.4f $%.4f", auctionatorGBP, auctionatorEUR, auctionatorUSD), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("Auctionator Stack Price", "" .. string.format("£%.4f €%.4f $%.4f", auctionatorStackGBP, auctionatorStackEUR, auctionatorStackUSD), 1, 1, 0, 1, 1, 0)
            end
        end

        if (currency == "gbp") then 
            GameTooltip:AddDoubleLine(leftString, "£" .. string.format("%.4f", gbpRealPrice), 1, 1, 0, 1, 1, 0)
            GameTooltip:AddDoubleLine("3-Day Stack Price", "£" .. string.format("%.4f", (gbpRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
        end

        if (currency == "eur") then 
            GameTooltip:AddDoubleLine(leftString, "€" .. string.format("%.4f", eurRealPrice), 1, 1, 0, 1, 1, 0)
            GameTooltip:AddDoubleLine("3-Day Stack Price", "€" .. string.format("%.4f", (eurRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
        end

        if (currency == "usd") then
            GameTooltip:AddDoubleLine(leftString, "$" .. string.format("%.4f", usdRealPrice), 1, 1, 0, 1, 1, 0)
            GameTooltip:AddDoubleLine("3-Day Stack Price", "$" .. string.format("%.4f", (usdRealPrice * itemStackCount)), 1, 1, 0, 1, 1, 0)
        end

        if (auctionatorGBP > 0.0001) then 
            if (currency == 'gbp') then 
                GameTooltip:AddDoubleLine("Auctionator Price", "£" .. string.format("%.4f", (auctionatorGBP)), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("Auctionator Stack Price", "£" .. string.format("%.4f", (auctionatorStackGBP)), 1, 1, 0, 1, 1, 0)
            end      
            if (currency == 'eur') then 
                GameTooltip:AddDoubleLine("Auctionator Price", "€" .. string.format("%.4f", (auctionatorEUR)), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("Auctionator Stack Price", "€" .. string.format("%.4f", (auctionatorStackEUR)), 1, 1, 0, 1, 1, 0)
            end
            if (currency == 'usd') then
                GameTooltip:AddDoubleLine("Auctionator Price", "$" .. string.format("%.4f", (auctionatorUSD)), 1, 1, 0, 1, 1, 0)
                GameTooltip:AddDoubleLine("Auctionator Stack Price", "$" .. string.format("%.4f", (auctionatorStackUSD)), 1, 1, 0, 1, 1, 0)
            end
        end
    end
    cleared = true
end

GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
C_Timer.NewTicker(301, C_WowTokenPublic.UpdateMarketPrice)