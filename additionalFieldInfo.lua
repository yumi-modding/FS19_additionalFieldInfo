﻿AdditionalFieldInfo = {};
AdditionalFieldInfo.PrecisionFarming = "FS19_precisionFarming"
AdditionalFieldInfo.InfoMenu = "FS19_InfoMenu"

function AdditionalFieldInfo:buildFarmlandsMapOverlay(selectedFarmland)
    if selectedFarmland then
        local farmLandArea =  g_i18n:formatArea(selectedFarmland.areaInHa, 2)
        self.selectedFarmlandAreaInHa = farmLandArea
    end
end
MapOverlayGenerator.buildFarmlandsMapOverlay = Utils.appendedFunction(MapOverlayGenerator.buildFarmlandsMapOverlay, AdditionalFieldInfo.buildFarmlandsMapOverlay)

function AdditionalFieldInfo:onFarmlandOverlayFinished(a, b, c, d)
    if not g_modIsLoaded[AdditionalFieldInfo.InfoMenu] then
        if self.mapOverlayGenerator.selectedFarmlandAreaInHa then
            if self.areaText == nil then
                local areaLabel = self.farmlandValueText:clone(self)
                areaLabel:setPosition(0, 0.04)
                self.farmlandValueText.parent:addElement(areaLabel)
                areaLabel:setText(g_i18n:getText("additionalFieldInfo_AREA")..":")
                areaLabel:setTextColor(1, 1, 1, 1)
                self.areaLabel = areaLabel
                local areaText = self.farmlandValueText:clone(self)
                areaText:setPosition(0.09, 0.04)
                self.farmlandValueText.parent:addElement(areaText)
                areaText:setText(self.mapOverlayGenerator.selectedFarmlandAreaInHa)
                self.areaText = areaText
            else
                local areaText = self.areaText
                areaText:setText(self.mapOverlayGenerator.selectedFarmlandAreaInHa)
            end
        else
            if self.areaText then
                self:removeElement(self.areaText)
            end
            if self.areaLabel then
                self:removeElement(self.areaLabel)
            end
        end
    end
end
InGameMenuMapFrame.onFarmlandOverlayFinished = Utils.prependedFunction(InGameMenuMapFrame.onFarmlandOverlayFinished, AdditionalFieldInfo.onFarmlandOverlayFinished)

function AdditionalFieldInfo:setFruitType(fruitTypeIndex, fruitGrowthState)
    if fruitTypeIndex > 0 then
        self.fruitType = self.fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
        -- print("Seed usage: "..tostring(self.fruitType.seedUsagePerSqm * 10000))
        if fruitGrowthState >= self.fruitType.minHarvestingGrowthState + 1 and fruitGrowthState <= self.fruitType.maxHarvestingGrowthState + 1 then
            -- local pixelToSqm = g_currentMission:getFruitPixelsToSqm()
            local literPerSqm = self.fruitType.literPerSqm
            -- print("literPerSqm "..tostring(literPerSqm))
            -- print("pixelToSqm "..tostring(pixelToSqm))
            local threshingScale = 1    -- seems not used from gdn lua doc
            self.potentialHarvestQty = literPerSqm * threshingScale
        else
            self.potentialHarvestQty = nil
        end
    end
end
FieldInfoDisplay.setFruitType = Utils.prependedFunction(FieldInfoDisplay.setFruitType, AdditionalFieldInfo.setFruitType)

function AdditionalFieldInfo:clearCustomText(fieldInfo, customRows)
    for i = 1, FieldInfoDisplay.MAX_ROW_COUNT do
        local row = fieldInfo.rows[i]

        if row.infoType == FieldInfoDisplay.INFO_TYPE.CUSTOM and customRows ~= nil then
            for j = 1, #customRows do
                if customRows[j] == i then
                    fieldInfo:clearInfoRow(row)
                    break
                end
            end
        end
    end
end

function AdditionalFieldInfo:onFieldDataUpdateFinished(data)
    if data == nil then return; end

    -- if self.displayDebug == nil  then self.displayDebug = true end
    -- if self.displayDebug then
    --     DebugUtil.printTableRecursively(g_i18n, " ", 1, 2);
    --     self.displayDebug = false
    -- end
    if self.currentField == nil then self.currentField = 4 end

    AdditionalFieldInfo:clearCustomText(self, self.customRows)
    self.customRows = {}

    for _, farmLand in pairs(g_fieldManager.farmlandIdFieldMapping) do
        local bFound = false
        local farmLandArea = 0.
        local fieldAreaSum = 0.
        local farmLandPrice = 0.
        local isOwned = false
        for fieldIndex, field in pairs(farmLand) do
            if field.farmland.id == data.farmlandId then
                if self.currentField > (4 * #farmLand + 2) then self.currentField = 4 end
                if fieldIndex == math.floor(self.currentField / 4) then
                    bFound = true
                    local fieldArea =  g_i18n:formatArea(field.fieldArea, 2)
                    fieldAreaSum = fieldAreaSum + field.fieldArea
                    farmLandArea =  g_i18n:formatArea(field.farmland.areaInHa, 2)
                    farmLandPrice = field.farmland.price
                    isOwned = field.farmland.isOwned
                    local Field_xx_Area = string.format(g_i18n:getText("additionalFieldInfo_FIELD_AREA"), field.fieldId)
                    if not g_modIsLoaded[AdditionalFieldInfo.PrecisionFarming] then
                        -- Display Area of each field in the current land
                        table.insert(self.customRows, self:addCustomText(Field_xx_Area, fieldArea))
                    end
                    if self.potentialHarvestQty ~= nil and self.fruitType ~= nil then
                        local multiplier = g_currentMission:getHarvestScaleMultiplier(self.fruitType, data.fertilizerFactor, 1 - data.needsPlowFactor, 1 - data.needsLimeFactor, 1 - data.weedFactor)
                        -- print("multiplier "..tostring(multiplier))
                        local fillType = self.fruitTypeManager:getFillTypeByFruitTypeIndex(self.fruitType.index)
                        local massPerLiter = fillType.massPerLiter

                        -- Display Potential harvest quantity
                        local Potential_Harvest = g_i18n:getText("additionalFieldInfo_POTENTIAL_HARVEST")
                        local potentialHarvestQty = self.potentialHarvestQty * field.fieldArea * multiplier * 10000 -- ha to sqm
                        table.insert(self.customRows, self:addCustomText(Potential_Harvest, g_i18n:formatVolume(potentialHarvestQty, 0)))

                        -- Display Potential yield
                        local Potential_Yield = g_i18n:getText("additionalFieldInfo_POTENTIAL_YIELD")
                        local potentialYield = (potentialHarvestQty * massPerLiter) / g_i18n:getArea(field.fieldArea)
                        table.insert(self.customRows, self:addCustomText(Potential_Yield, string.format("%1.2f T/"..tostring(g_i18n:getAreaUnit()), potentialYield)))
                    end
                end
            end
        end
        if bFound then
            self.currentField = self.currentField + 1
            local Farm_Land_Area = g_i18n:getText("additionalFieldInfo_FARMLAND_AREA")
            if not g_modIsLoaded[AdditionalFieldInfo.PrecisionFarming] then
                -- Display Current land area
                table.insert(self.customRows, self:addCustomText(Farm_Land_Area, farmLandArea))
            end
            if fieldAreaSum > 0. and not isOwned then
                local areaUnit = tostring(g_i18n:getAreaUnit())
                local pricePerArea = farmLandPrice / g_i18n:getArea(fieldAreaSum)
                local Price_On_Area = string.format(g_i18n:getText("additionalFieldInfo_PRICE_ON_AREA"), g_i18n:getAreaUnit())
                -- Display Price per ha (per ac) of the cultivated area on land you don't own
                table.insert(self.customRows, self:addCustomText(Price_On_Area, g_i18n:formatMoney(pricePerArea, 0)..'/'..areaUnit))
            end
            break
        end
    end
    -- self:addCustomText("farmlandId", tostring(data.farmlandId))
end
FieldInfoDisplay.onFieldDataUpdateFinished = Utils.appendedFunction(FieldInfoDisplay.onFieldDataUpdateFinished, AdditionalFieldInfo.onFieldDataUpdateFinished)

