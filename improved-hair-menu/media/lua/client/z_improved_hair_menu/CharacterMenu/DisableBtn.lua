--[[
	disableBtn modified to use modded UI elements.
	- We break down the method into smaller functions in case anyone needs to inject anything for compatibility.
	- Completely overwrites the original method as the original doesn't work due to removing elements from the screen.

	Earlier versions of this mod simply appended functionality to this method but this means we have to keep all
	the vanilla elements around and functional which is hard to maintain when the game updates.
]]

function CharacterCreationMain:disableBtn()
	-- CharacterCreationHeader calls this during creation
	if not self.chestHairLbl then return end -- If the menu hasn't been created yet
	
	local desc = MainScreen.instance.desc
	local visible = not desc:isFemale()
	self.chestHairLbl:setVisible(visible)
	self.chestHairTickBox:setVisible(visible)
	self.beardRect:setVisible(visible)
	self.beardLbl:setVisible(visible)
	self.beardMenu:setVisible(visible)
	if self.beardMenuButton then self.beardMenuButton:setVisible(visible) end
	-- NOTE: We don't set the stubble box because it's a child of beardMenu

	if self.female ~= desc:isFemale() or CharacterCreationMain.forceUpdateCombo then
		CharacterCreationMain.forceUpdateCombo = false
		self.female = desc:isFemale()

		local infoHair = self:generateHairList()
		if self.hairMenu then self.hairMenu:setInfoTable(infoHair) end

		local infoBeard = self:generateBeardList()
		if self.beardMenu then self.beardMenu:setInfoTable(infoBeard) end

		--########
		--Clothing
		--########
		
		if self.outfitCombo then
			self.outfitCombo.options = {}
			self.outfitCombo:addOptionWithData(getText("UI_characreation_clothing_none"), nil)
			local outfits = getAllOutfits(desc:isFemale())
			for i=1,outfits:size() do
				self.outfitCombo:addOptionWithData(outfits:get(i-1), outfits:get(i-1))
			end
		end
		
		local fillCombo = function(bodyLocation)
			local combo = self.clothingCombo[bodyLocation]
			combo.options = {}
			combo:addOptionWithData(getText("UI_characreation_clothing_none"), nil)
			local items = getAllItemsForBodyLocation(bodyLocation)
			table.sort(items, function(a,b)
				local itemA = ScriptManager.instance:FindItem(a)
				local itemB = ScriptManager.instance:FindItem(b)
				return not string.sort(itemA:getDisplayName(), itemB:getDisplayName())
			end)
			for _,fullType in ipairs(items) do
				local item = ScriptManager.instance:FindItem(fullType)
				local displayName = item:getDisplayName()
				combo:addOptionWithData(displayName, fullType)
			end
		end
		
		if CharacterCreationMain.debug then
			for bodyLocation,combo in pairs(self.clothingCombo) do
				fillCombo(bodyLocation)
			end
		end
	end

	self:syncUIWithTorso()

	if self.skinColors and self.skinColor then
		local color = self.skinColors[self.skinColor]
		self.skinColorButton.backgroundColor.r = color.r
		self.skinColorButton.backgroundColor.g = color.g
		self.skinColorButton.backgroundColor.b = color.b
		self.skinColorButton.attachedPanel:setSelectedInfoIndex(self.skinColor)
	end
		
	local color = desc:getHumanVisual():getHairColor()
	self.hairColorButton.backgroundColor.r = color:getRedFloat()
	self.hairColorButton.backgroundColor.g = color:getGreenFloat()
	self.hairColorButton.backgroundColor.b = color:getBlueFloat()
		
	if MainScreen.instance.avatar then
		local hairModel = desc:getHumanVisual():getHairModel()
		for i=1,#self.hairMenu.info do
			local name = self.hairMenu.info[i].id
			if name:lower() == hairModel:lower() then
				-- NOTE: hairMenu's onSelect triggers disableBtn so we need to set the selection silently to avoid an infinite loop
				self.hairMenu:setSelectedInfoIndex(i)
				break
			end
		end
		
		if not desc:isFemale() then
			local beardModel = desc:getHumanVisual():getBeardModel()
			for i=1,#self.beardMenu.info do
				local name = self.beardMenu.info[i].id
				if name:lower() == beardModel:lower() then
					self.beardMenu:setSelectedInfoIndex(i)
					break
				end
			end
		end
		
		if CharacterCreationMain.debug then
			for bodyLocation,combo in pairs(self.clothingCombo) do
				local selected = combo.selected
				combo.selected = 1 -- None
				local item = desc:getWornItem(bodyLocation)
				local clothingItem = nil
				if item and item:getVisual() then
					combo.selected = combo:find(function(text, data, fullType)
						return data == fullType
					end, item:getFullType())
					clothingItem = item:getVisual():getClothingItem()
				end
				local textureChoices = clothingItem and (clothingItem:hasModel() and clothingItem:getTextureChoices() or clothingItem:getBaseTextures())
				if textureChoices and (textureChoices:size() > 1) then
					local textureChoice = clothingItem:hasModel() and item:getVisual():getTextureChoice() or item:getVisual():getBaseTexture()
					local combo = self.clothingTextureCombo[bodyLocation];
					combo:setVisible(true);
					combo.options = {}
					for i=0,textureChoices:size() - 1 do
						combo:addOptionWithData("Type " .. (i + 1), textureChoices:get(i))
						if i == textureChoice then
							combo:select("Type " .. (i + 1));
						end
					end
				else
					self.clothingTextureCombo[bodyLocation].options = {};
					self.clothingTextureCombo[bodyLocation]:setVisible(false);
				end
				if clothingItem and clothingItem:getAllowRandomTint() then
					local color = item:getVisual():getTint(clothingItem)
					self.clothingColorBtn[bodyLocation].backgroundColor = { r=color:getRedFloat(), g=color:getGreenFloat(), b=color:getBlueFloat(), a = 1 }
					self.clothingColorBtn[bodyLocation]:setVisible(true)
				else
					self.clothingColorBtn[bodyLocation].backgroundColor = { r=1, g=1, b=1, a = 1 }
					self.clothingColorBtn[bodyLocation]:setVisible(false)
				end
				if clothingItem and clothingItem:getDecalGroup() then
					-- Fill the decal combo if a different clothing item is now selected.
					if self.decalItem ~= item then
						self.decalItem = item
						local decalCombo = self.clothingDecalCombo[bodyLocation]
						decalCombo.options = {}
						local items = getAllDecalNamesForItem(item)
						for i=1,items:size() do
							decalCombo:addOptionWithData(items:get(i-1), items:get(i-1))
						end
					end
					local decalName = item:getVisual():getDecal(clothingItem)
					self.clothingDecalCombo[bodyLocation]:select(decalName)
					self.clothingDecalCombo[bodyLocation]:setVisible(true)
				else
					self.clothingDecalCombo[bodyLocation]:setVisible(false)
				end
			end
		end
	end
end

function CharacterCreationMain:generateHairList()
	local desc = MainScreen.instance.desc
	local infoHair = {}
	local hairStyles = getAllHairStyles(desc:isFemale())
	for i=1,hairStyles:size() do
		local styleId = hairStyles:get(i-1)
		local hairStyle = self.female and getHairStylesInstance():FindFemaleStyle(styleId) or getHairStylesInstance():FindMaleStyle(styleId)
		local label = styleId
		if label == "" then
			label = getText("IGUI_Hair_Bald")
		else
			label = getText("IGUI_Hair_" .. label);
		end
		if not hairStyle:isNoChoose() then
			table.insert(infoHair, {
				id = hairStyles:get(i-1),
				display = label,
				selected = false,
				getterName = "getHairModel",
				setterName = "setHairModel",
			})
		end
	end

	return infoHair
end

function CharacterCreationMain:generateBeardList()
	local desc = MainScreen.instance.desc
	local infoBeard = {}
	if desc:isFemale() then
		-- no bearded ladies
	else
		local beardStyles = getAllBeardStyles()
		for i=1,beardStyles:size() do
			local label = beardStyles:get(i-1)
			if label == "" then
				label = getText("IGUI_Beard_None")
			else
				label = getText("IGUI_Beard_" .. label);
			end
			table.insert(infoBeard, {
				id = beardStyles:get(i-1),
				display = label,
				selected = false,
				getterName = "getBeardModel",
				setterName = "setBeardModel",
			})
		end
	end
	return infoBeard
end