List = {l = nil}
List.__index = List

function List:new()
	o = {}
	setmetatable(o, self)
	o.__index = o
	o.l = nil
	return o
end

function List:push(e)
	self.l = {t=e, n=self.l}
end

function List:find(finder)
	it = self.l
	while it ~= nil and not finder(it.t) do
		it = it.n
	end
	return it and ti.t
end

function List:removeF(finder)
	if (not self.l) or finder(self.l.t) then
		self.l = self.l and self.l.n
		return
	end
	it = self.l
	while it.n ~= nil and finder(it.n.t) do
		it = it.n
	end
	it.n = it.n and it.n.n
end

function List:remove(e)
	if (not self.l) or self.l.t == e then
		self.l = self.l and self.l.n
		return
	end
	it = self.l
	while it.n ~= nil and it.n.t == e do
		it = it.n
	end
	it.n = it.n and it.n.n
end

function List:__len()
	n = 0
	it = self.l
	while it ~= nil do
		it = it.n
		n = n + 1
	end
	return n
end

Activable = {_actifList={list=nil}}
Activable.__index = Activable

function Activable:activate()
  print("activate")
	self._actifList.list = {t=self, next=self._actifList.list}
end

function Activable:disactivate()
	if self._actifList.list.t == self then
		self._actifList.list = self._actifList.next
	else
		it = self._actifList.list
		while it.next ~= nil and it.next.t ~= self do
			it = it.next
		end
		if it.next ~= nil then
			it.next = it.next.next
		else
			error("Actif not found")
		end
	end
end

function Activable:updateActifs()
	it = self._actifList.list
	while it ~= nil do
		it.t:update()
		it = it.next
	end
end

function Activable:subclass(newClass)
  setmetatable(newClass, self)
  newClass.__index = newClass
  newClass._actifList={list=nil}
  return newClass
end


Folk=Activable:subclass({id=0, house=nil, state=0, dest={}})
local FolkVisionLength = 15

function Folk:spawn(x,y)
   Folk:new(ModBase.SpawnItem("Client", x, y),100):activate()
end


function Folk:new(id, state, house)
	o = {}
	setmetatable(o, self)
	o.__index = o
	o.id = id
	o.state = state or 0;
	o.house = house or nil;
	o.dest = {}
	return o
end

function Folk:moveIn(house)
	--ModDebug.Log("MoveIn")
	self.house = house
	house.folk = self
	ModObject.DestroyObject(house.id)
	house.id = ModBase.SpawnItem("Occupied Hut", house.x, house.y, true , true)
	ModObject.SetObjectRotation(house.id, 0, 0, 0)
	-- TODO register registerHouse = {ID=objectTarget, next=occupiedHouses}
	self:popIn()
end

function Folk:popIn()
	ModObject.DestroyObject(self.id)
	-- TODO Save client stats
	self.state = -1 -- state inside
	self:disactivate()
	self.house:activate()
end

function Folk:popOut(state, x, y)
	self.id = ModBase.SpawnItem("Client", x, y)
	-- TODO Load client stats
	self.state = state
	self.house:disactivate()
	self:activate()
end

function Folk:waitBuldingFree(x, y)
	
end

function Folk:update()
	-- state -1 == inside
	if self.state%10 == 1 then -- moving state
		-- maybe a timeout handle in case of error while moving
		--Info = ModObject.GetObjectProperties(self.id)
		coords = ModObject.GetObjectTileCoord(self.id)
		-- TODO non holdable client or check if info == nill
		--ModDebug.Log("Moving to ", self.dest.dx," ", self.dest.dy)
		if coords[1] == self.dest.dx and coords[2] == self.dest.dy then
			--ModDebug.Log("Arrived at", coords[1]," ", coords[2])
			self.state = self.state - 1 -- state pass to base state
		end
	elseif self.state == 100 then -- searching house state
		scoord = ModObject.GetObjectTileCoord(self.id)
		hutList = ModBuilding.GetAllBuildingsUIDsOfType("Free Hut", scoord[1]-FolkVisionLength,scoord[2]-FolkVisionLength, scoord[1]+FolkVisionLength,scoord[2]+FolkVisionLength)
		--TODO: closest?
		targetHut = hutList[1]
		if targetHut ~= nil and targetHut ~= -1 then
			--ModDebug.Log("Found: I'm in ", scoord[1], " ", scoord[2])
			coord = ModObject.GetObjectTileCoord(targetHut)
			if scoord[1] == coord[1] and scoord[2] == coord[2]+1 then -- already there
				-- claim house
				self:moveIn(House:new(targetHut, coord[1], coord[2]))
			else
				self:moveTo(coord[1], coord[2]+1)
			end
		end
	elseif self.state == 200 then -- searching food state
		scoord = ModObject.GetObjectTileCoord(self.id)
		tableList = ModBuilding.GetAllBuildingsUIDsOfType("Free Table", scoord[1]-FolkVisionLength,scoord[2]-FolkVisionLength, scoord[1]+FolkVisionLength,scoord[2]+FolkVisionLength)
		--TODO: closest?
		targetTable = tableList[1]
		if targetTable ~= nil and targetTable ~= -1 then
			--ModDebug.Log("Found: I'm in ", scoord[1], " ", scoord[2])
			coord = ModObject.GetObjectTileCoord(targetTable)
			if scoord[1] == coord[1] and scoord[2] == coord[2]+1 then -- already there
				-- claim house
				self:moveIn(House:new(targetTable, coord[1], coord[2]))
			else
				self:moveTo(coord[1], coord[2]+1)
			end
		end
	end
end

function Folk:moveTo(dx, dy)
	--ModDebug.Log("MoveTo", dx, " ", dy)
	self.state = (self.state - (self.state%10) + 1) -- state moving
	self.dest.dx = dx
	self.dest.dy = dy
	ModGoTo.moveTo(self.id, dx, dy)
end


-- TODO hut dispariton and move check

House=Activable:subclass({id=0, x=0, y=0, foodLevel=0, folk=nil})

function House:new(id, x, y, folk, present, foodLevel)
   o = {}
   setmetatable(o, self)
   o.__index = self
   o.id=id
   o.x=x
   o.y=y
   o.folkId = folk or nil
   o.present = present or false
   o.foodLevel = foodLevel or 0
   return o
end

function House:update()
	if self.foodLevel>0 then self.foodLevel = self.foodLevel - 1 end
	if self.folk==nil or self.folk.state ~= -1 then
	--idle state
		error("House inconsistent state.")
	else
		if self.foodLevel == 0 then
			self.folk:popOut(200, self.x, self.y+1) -- State seek food
		end
	end
end


-- Berries Mod
-- Creates a berry converter, adds recipe for creation of berries

-- Exposed variables to game
local Amazing = 10
local MaxSpeed = false

local clientID = 0
local clientState = 100
local clientTarget = 0
local objectTarget = 0
local HutID = 0
local FolkID = 0
local MustDrop = nil

local occupiedHouses = nil

local currentTime = 0

function Expose()

	-- Exposed variables
	ModBase.ExposeVariable("Amazing Variable", Amazing, ExposedCallback, 0, 20)
	ModBase.ExposeVariable("Speed", MaxSpeed, SpeedCallback)
	ModBase.ExposeVariable("Fun factor", 30, GenericCallback, 20, 40)
	ModBase.ExposeVariable("Instant Win", true, GenericCallback)	
	
end

function ExposedCallback( param )

	Amazing = param
	
end

function SpeedCallback( param )

	ModDebug.Log("Param: ", param)
	
end

function GenericCallback( param )

end

function SteamDetails()

	-- Setting of Steam details
	ModBase.SetSteamWorkshopDetails("BerryGoodMod V3", "Mega Berry Maker. Adds converter for berries along with recipe.", {"berries", "berry converter"}, "BerryLogo.png")
	
end

function BeforeLoad()

	-- Before Load Function - The majority of calls go here
	
	ModDebug.Log("MOD - Create Berry Recipe - All Converters - 1 stick = 10 berries produced") 
	ModVariable.SetIngredientsForRecipe("Berries", {"Stick"}, {1}, 10)	
	
	ModDebug.Log("MOD - Set Storage for Sticks to 200")
	ModVariable.SetVariableForStorageAmount("Stick", 200)
	
	ModDebug.Log("MOD - Set Storage for Berries to 200")
	ModVariable.SetVariableForStorageAmount("Berries", 200)
	ModTool.SetToolCategoryBase("MToll", "Scythe")
	
	
	ModVariable.SetVariableFarmerAction("Mining", "TreePine", "MToll", 32);
	ModVariable.SetVariableFarmerAction("Mining", "TreeApple", "MToll", 32);
	ModVariable.SetVariableFarmerAction("Mining", "TreeCoconut", "MToll", 32);
	ModVariable.SetVariableFarmerAction("Mining", "TreeMulberry", "MToll", 32);
	ModVariable.SetVariableFarmerAction("Mining", "Building3", "MToll", 32);
	ModVariable.SetVariableFarmerAction("Mining", "Client", "MToll", 32);
	ModVariable.SetVariableForObjectAsInt("MToll", "MaxUsage", 5);
	ModVariable.SetVariableForObjectAsInt("MToll", "Unlocked", 1);
	
	
	--ModVariable.SetVariableFarmerAction("Dig", "Turf", "Shovel", 1);
	ModVariable.SetVariableForObjectAsInt("Client", "MaxUsage", 999999999)
	ModVariable.SetVariableForObjectAsInt("Free Hut", "MaxUsage", 999999999)
	
	
	ModVariable.SetVariableForObjectAsInt("Berry", "MaxUsage", 1);
	ModVariable.SetVariableFarmerAction("ModAction", "Table needing berry", "Berry", 1);
	
end

function AfterLoad()

	-- After Load Function
	
	ModDebug.Log("MOD - Spawn Berries")
	ModBase.SpawnItem("Berries", 50, 50)
	
	--currentTime = ModSaveData.LoadValue("currentTime") or 0
	--ModDebug.Log(ModSaveData.LoadValue("currentTime"))
	--ModDebug.Log(currentTime)
end

function AfterLoad_CreatedWorld()
end

function AfterLoad_LoadedWorld()
	--ModBase.SpawnItem("Berries", 110, 67)
	--ModBase.SpawnItem("Berries", 110, 69)
	------clientID = ModTiles.GetObjectUIDsOnTile(110,67)[1]
	--clientID = 
	Folk:spawn(110,67)
	clientTarget = ModBase.SpawnItem("Free Hut", 105, 65, true , true)
	clientTarget = ModBase.SpawnItem("Free Table", 109, 65, true , true)
	-----ModObject.SetObjectDurability(clientID, 999999997)
	-----ModObject.SetObjectDurability(clientTarget, 999999997)
	--ModGoTo.moveTo(clientID, 110, 69)
	--ModBase.SpawnItem("MToll", 110, 70)
	ModBase.SpawnItem("TreeCoconut", 110, 71)
	
	
	--HutID = ModBase.SpawnItem("Hut", 110, 65, true , true)
	--FolkID = ModBase.SpawnItem("Folk", 115, 65, true , true)
	
	--ModBase.SpawnItem("ReceptionDesk", 105, 65, true , true)
	
	--ModObject.AddObjectToColonistHouse(HutID, FolkID) 
	
	
	--ModBase.SpawnItem("Pot", 110, 73)
	--ModBase.SpawnItem("Plate", 110, 72)
	
	ModBase.SpawnItem("Berry", 105, 67, true , true)
end

function WandCallback(UserUID, TileX, TileY, TargetUID, TargetType)
	ModDebug.Log(TargetType)
end

function NonPickupable(TargetType, TileX, TileY, TargetUID, UserUID)
	MustDrop = {target=UserUID; next=MustDrop}
end

local tableWberry = 0
function fillTableWithFood(UserUID, TileX, TileY, TargetUID, TargetType)
	ModObject.DestroyObject(TargetUID)
	tableWberry = ModBase.SpawnItem("Table with berry", TileX, TileY, true , true)
	-- TODO TargetUID
	objectTarget = tableWberry
	--
	ModObject.SetObjectRotation(tableWberry, 0, 0, 0)
end

function Creation()
	math.randomseed(os.time())
	-- Creation of any new converters or buildings etc. go here
	
	ModDebug.Log("MOD - Create a new Berry Converter")
	ModConverter.CreateConverter("TheBerryMaker", {"Berries"}, {"Plank", "Pole"}, {4, 3}, "ObjCrates/wooden boxes pack", {-1,-1}, {1,0}, {0,1}, {1,1})
	
	ModGoTo.CreateGoTo 	("Client", null, null, "Models/animals/animalalpaca", false)
	
	ModHoldable.CreateHoldable("ReceptionDesk", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", false)
	--ModHoldable.CreateHoldable("Pot", {"Stick"}, {1}, "Pot/pot", true)
	ModHoldable.CreateHoldable("Plate", {"Stick"}, {1}, "Plate/tart", true)
	ModHoldable.UpdateModelScale("Plate", 30) 
	
	--ModBuilding.CreateBuilding("Building3", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", {-1,-1}, {1,0}, {0,-2}, false)
	--ModBuilding.CreateBuilding("Building3", {"Stick"}, {1}, "Testable/table2", {-1,-1}, {1,0}, {0,-2}, true)
	--ModBuilding.CreateBuilding("Building3", {"Stick"}, {1}, "Testable/table2", {-1,-1}, {1,0}, {}, true)
	--ModDecorative.CreateDecorative("Building3")
	--ModBuilding.ShowBuildingAccessPoint("Building3", true) 
	--ModBuilding.SetBuildingWalkable("Building3", true) 
	
	ModTool.CreateTool("MToll", {"Stick"}, {1}, {"Client", "TreeCoconut", "Hut"}, {}, {}, {}, 5.0, "Models/Tools/ToolChiselCrude", false, WandCallback, false) 
	--ModHoldable.CreateHoldable("MToll", {"Stick"}, {1}, "Models/Food/AppleJam", false)
	
	
	
	-- Hous based object
	ModBuilding.CreateBuilding("Free Hut", {"Stick"}, {1}, "Models/Buildings/Hut", {0,0}, {0,0}, {0,1}, false)
	ModBuilding.ShowBuildingAccessPoint("Free Hut", true) 
	ModBuilding.CreateBuilding("Occupied Hut", {"Stick"}, {1}, "Models/Buildings/Hut", {0,0}, {0,0}, {0,1}, false)
	--ModBuilding.ShowBuildingAccessPoint("Occupied Hut", true) 
	
	-- Food base object
	ModBuilding.CreateBuilding("Free Table", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", {0,0}, {0,0}, {0,-2}, false)
	ModBuilding.SetBuildingWalkable("Free Table", true)
	ModHoldable.CreateHoldable("Table needing berry", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", false)
	ModHoldable.CreateHoldable("Table with berry", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", false)
	
	ModTool.CreateTool("Berry", {"Stick"}, {1}, {"Table needing berry"}, {}, {}, {}, 2.0, "Models/Food/Berries", false, fillTableWithFood, true)
	
	ModHoldable.RegisterForCustomCallback("Free Table", "HoldablePickedUp", NonPickupable)
	ModHoldable.RegisterForCustomCallback("Table needing berry", "HoldablePickedUp", NonPickupable)
	ModHoldable.RegisterForCustomCallback("Table with berry", "HoldablePickedUp", NonPickupable)
	--ModHoldable.RegisterForCustomCallback("Raw Meat", "HoldablePickedUp", CallbackFunction)
	--ModHoldable.RegisterForCustomCallback("Raw Meat", "HoldableDroppedOnGround", CallbackFunction)

end

function ClientGoToObject(ClientID, TargetType, IsBuilding)
	
	error("TODO ClientGoToObject with non building")
end

local ss = ""
local time_sum = 0

function OnUpdate(DeltaTime)
	ModDebug.Log(TU)
	time_sum = time_sum + DeltaTime
	if time_sum < 1 then
		return
	end
	time_sum = time_sum - 1
	ModDebug.Log("T")
	--ModDebug.Log(os.time())
	--if currentTime == 0 then
	--	currentTime = os.time()
	--	return
	--else
	--	newTime = os.time()
	--	DeltaTime = newTime - currentTime
	--end
	-- Drop all non holdable object
	--currentTime = currentTime + DeltaTime
	--ModSaveData.SaveValue("currentTime", currentTime)
	--ModDebug.Log(currentTime)
	
		--ModDebug.Log("dur")
	--	ModDebug.Log(ModObject.GetObjectDurability(clientTarget))
	sn = ModBase.GetGameState()
	if ss ~= sn then
		ss = sn
		ModDebug.Log(ss)
	end
	Folk:updateActifs()
	House:updateActifs()
end	
function noto()
	while MustDrop ~= nil do
		if ModObject.GetObjectProperties(MustDrop.target)[1] ~= "FarmerPlayer" then
			ModBot.DropAllHeldObjects(MustDrop.target)
		else
			ModPlayer.DropAllHeldObjects()
		end
		MustDrop = MustDrop.next
	end
	
	nextOccupiedHouses = nil
	while occupiedHouses ~= nil do
		
		occupiedHouses = occupiedHouses.next
	end
	occupiedHouses = nextOccupiedHouses

	--ModDebug.Log(os.time())
	-- Seek for Home
	if clientID ~= 0 then
		ModDebug.Log("dur")
		ModDebug.Log(ModObject.GetObjectDurability(clientID))
		if clientState == 100 then --Seekinghome
			coord = ModObject.GetObjectTileCoord(clientID)
			hutList = ModBuilding.GetAllBuildingsUIDsOfType("Free Hut", coord[1]-15,coord[2]-15, coord[1]+15,coord[2]+15)
			--TODO: closest?
			targetHut = hutList[1]
			--ModDebug.Log(targetHut)
			if targetHut ~= nil and targetHut ~= -1 then
				coord = ModObject.GetObjectTileCoord(targetHut) 
				ModGoTo.moveTo(clientID, coord[1]-1, coord[2])
				clientState = 101
				clientTarget = {coord[1]-1, coord[2]}
				objectTarget = targetHut
				ModDebug.Log("Client: J'y go hut")
			end
		elseif clientState == 101 then --goingAtHome
			-- [1]=Type, [2]=TileX, [3]=TileY, [4]=Rotation, [5]=Name, 
			Info = ModObject.GetObjectProperties(clientID)
			if Info[2] == clientTarget[1] and Info[3] == clientTarget[2] then
				ModDebug.Log("Client: J'y suis hut")
				Info = ModObject.GetObjectProperties(objectTarget)
				--ModObject.SetObjectActive(objectTarget, false)
				ModObject.DestroyObject(objectTarget)
				objectTarget = ModBase.SpawnItem("Occupied Hut", Info[2], Info[3], true , true)
				ModObject.SetObjectRotation(objectTarget, 0, 0, 0)
				-- TODO Save client stats
				occupiedHouses = {ID=objectTarget, next=occupiedHouses}
				ModObject.DestroyObject(clientID)
				---- To remove
				clientID = 0
				--clientState = 102
			end
		-- Seek for food
		elseif clientState == 0 then
			coord = ModObject.GetObjectTileCoord(clientID)
			--ModBuilding.GetAllBuildingsUIDsOfType("Free Table", coord[1]-15,coord[2]-15, coord[1]+15,coord[2]+15)
			tableList = ModBuilding.GetAllBuildingsUIDsOfType("Free Table", coord[1]-15,coord[2]-15, coord[1]+15,coord[2]+15)
			targetTable = tableList[1]
			if targetTable ~= nil and targetTable ~= -1 then
				coord = ModObject.GetObjectTileCoord(targetTable) 
				ModGoTo.moveTo(clientID, coord[1]-1, coord[2])
				clientState = 1
				clientTarget = {coord[1]-1, coord[2]}
				objectTarget = targetTable
				ModDebug.Log("Client: J'y go")
				--DestroyObject()
				--SetObjectActive
			end
		elseif clientState == 1 then
			-- [1]=Type, [2]=TileX, [3]=TileY, [4]=Rotation, [5]=Name, 
			Info = ModObject.GetObjectProperties(clientID)
			if Info[2] == clientTarget[1] and Info[3] == clientTarget[2] then
				ModDebug.Log("Client: J'y suis")
				Info = ModObject.GetObjectProperties(objectTarget)
				ModObject.SetObjectActive(objectTarget, false)
				objectTarget = ModBase.SpawnItem("Table needing berry", Info[2], Info[3], true , true)
				ModObject.SetObjectRotation(objectTarget, 0, 0, 0)
				clientState = 2
			end
		elseif clientState == 2 then
			-- [1]=Type, [2]=TileX, [3]=TileY, [4]=Rotation, [5]=Name, 
			Info = ModObject.GetObjectProperties(objectTarget)
			--ModDebug.Log(Info[1])
			--ModDebug.Log(Info[5])
			if Info[1] == "Table with berry" then
				ModDebug.Log("Client: Je mange")
				-- TODO Annimation
				clientState = 3
			end
		elseif clientState == 3 then
			rnd = math.random()
			--ModDebug.Log(rnd)
			if rnd*10000 < 1 then
				ModDebug.Log("Client: J'ai mangé")
				Info = ModObject.GetObjectProperties(objectTarget)
				ModObject.DestroyObject(objectTarget)
				ModObject.SetObjectActive(ModBuilding.GetBuildingCoveringTile(Info[2],Info[3]), true)
				--objectTarget = ModBase.SpawnItem("Free Table", Info[2], Info[3], true , true)
				--ModObject.SetObjectRotation(objectTarget, 0, 0, 0)
				ModGoTo.moveTo(clientID, 105, 66)
				clientState = 4
			end
		end
	end
end












































