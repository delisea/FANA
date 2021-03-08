-- Small Lua (open) lib for json handling
-- Source: https://gist.github.com/tylerneylon/59f4bcf316be525b30ab
local json = {}

-- Internal functions.

local function kind_of(obj)
  if type(obj) ~= 'table' then return type(obj) end
  local i = 1
  for _ in pairs(obj) do
    if obj[i] ~= nil then i = i + 1 else return 'table' end
  end
  if i == 1 then return 'table' else return 'array' end
end

local function escape_str(s)
  local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
  local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
  for i, c in ipairs(in_char) do
    s = s:gsub(c, '\\' .. out_char[i])
  end
  return s
end

-- Returns pos, did_find; there are two cases:
-- 1. Delimiter found: pos = pos after leading space + delim; did_find = true.
-- 2. Delimiter not found: pos = pos after leading space;     did_find = false.
-- This throws an error if err_if_missing is true and the delim is not found.
local function skip_delim(str, pos, delim, err_if_missing)
  pos = pos + #str:match('^%s*', pos)
  if str:sub(pos, pos) ~= delim then
    if err_if_missing then
      error('Expected ' .. delim .. ' near position ' .. pos)
    end
    return pos, false
  end
  return pos + 1, true
end

-- Expects the given pos to be the first character after the opening quote.
-- Returns val, pos; the returned pos is after the closing quote character.
local function parse_str_val(str, pos, val)
  val = val or ''
  local early_end_error = 'End of input found while parsing string.'
  if pos > #str then error(early_end_error) end
  local c = str:sub(pos, pos)
  if c == '"'  then return val, pos + 1 end
  if c ~= '\\' then return parse_str_val(str, pos + 1, val .. c) end
  -- We must have a \ character.
  local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
  local nextc = str:sub(pos + 1, pos + 1)
  if not nextc then error(early_end_error) end
  return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

-- Returns val, pos; the returned pos is after the number's final character.
local function parse_num_val(str, pos)
  local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
  local val = tonumber(num_str)
  if not val then error('Error parsing number at position ' .. pos .. '.') end
  return val, pos + #num_str
end


-- Public values and functions.

function json.stringify(obj, as_key)
  local s = {}  -- We'll build the string as an array of strings to be concatenated.
  local kind = kind_of(obj)  -- This is 'array' if it's an array or type(obj) otherwise.
  if kind == 'array' then
    if as_key then error('Can\'t encode array as key.') end
    s[#s + 1] = '['
    for i, val in ipairs(obj) do
      if i > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = json.stringify(val)
    end
    s[#s + 1] = ']'
  elseif kind == 'table' then
    if as_key then error('Can\'t encode table as key.') end
    s[#s + 1] = '{'
    for k, v in pairs(obj) do
      if #s > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = json.stringify(k, true)
      s[#s + 1] = ':'
      s[#s + 1] = json.stringify(v)
    end
    s[#s + 1] = '}'
  elseif kind == 'string' then
    return '"' .. escape_str(obj) .. '"'
  elseif kind == 'number' then
    if as_key then return '"' .. tostring(obj) .. '"' end
    return tostring(obj)
  elseif kind == 'boolean' then
    return tostring(obj)
  elseif kind == 'nil' then
    return 'null'
  else
    error('Unjsonifiable type: ' .. kind .. '.')
  end
  return table.concat(s)
end

json.null = {}  -- This is a one-off table to represent the null value.

function json.parse(str, pos, end_delim)
  pos = pos or 1
  if pos > #str then error('Reached unexpected end of input.') end
  local pos = pos + #str:match('^%s*', pos)  -- Skip whitespace.
  local first = str:sub(pos, pos)
  if first == '{' then  -- Parse an object.
    local obj, key, delim_found = {}, true, true
    pos = pos + 1
    while true do
      key, pos = json.parse(str, pos, '}')
      if key == nil then return obj, pos end
      if not delim_found then error('Comma missing between object items.') end
      pos = skip_delim(str, pos, ':', true)  -- true -> error if missing.
      obj[key], pos = json.parse(str, pos)
      pos, delim_found = skip_delim(str, pos, ',')
    end
  elseif first == '[' then  -- Parse an array.
    local arr, val, delim_found = {}, true, true
    pos = pos + 1
    while true do
      val, pos = json.parse(str, pos, ']')
      if val == nil then return arr, pos end
      if not delim_found then error('Comma missing between array items.') end
      arr[#arr + 1] = val
      pos, delim_found = skip_delim(str, pos, ',')
    end
  elseif first == '"' then  -- Parse a string.
    return parse_str_val(str, pos + 1)
  elseif first == '-' or first:match('%d') then  -- Parse a number.
    return parse_num_val(str, pos)
  elseif first == end_delim then  -- End of an object or array.
    return nil, pos + 1
  else  -- Parse true, false, or null.
    local literals = {['true'] = true, ['false'] = false, ['null'] = json.null}
    for lit_str, lit_val in pairs(literals) do
      local lit_end = pos + #lit_str - 1
      if str:sub(pos, lit_end) == lit_str then return lit_val, lit_end + 1 end
    end
    local pos_info_str = 'position ' .. pos .. ': ' .. str:sub(pos, pos + 10)
    error('Invalid json syntax starting at ' .. pos_info_str)
  end
end












--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-----------------                     List Classs                                             ----------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

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
	local it = self.l
	while it ~= nil and not finder(it.t) do
		it = it.n
	end
	return it and it.t or nil
end

function List:removeF(finder)
	if (not self.l) or finder(self.l.t) then
		self.l = self.l and self.l.n
		return
	end
	local it = self.l
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
	local it = self.l
	while it.n ~= nil and it.n.t ~= e do
		it = it.n
	end
	it.n = it.n and it.n.n
end

function List:__len()
	local n = 0
	local it = self.l
	while it ~= nil do
		it = it.n
		n = n + 1
	end
	return n
end

function List:getData()
	local data = {l = nil}
	local it = self.l
	while it ~= nil do
		List.push(data,it.t:getData())
		it = it.n
	end
	return data
end

function List:fromDataBuilder(data, builder)
	local it = data.l
	while it ~= nil do
		builder:fromData(it.t)
		it = it.n
	end
end












--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-----------------                     Default values                                          ----------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- base delay = 15
-- num *= 1f / (float)(heartTier * 2 + 1);
-- HeartDelay: time before heart spawn
HeartDelay = {15,45,75,105,135,165,195}

FoodCategory = {
	"Primary", -- champi, poisson
	"Secondary", -- blé, carotte, citrouille
	"Desert" -- baie, pomme
}

FoodCatalog = {}
FoodList = { -- Name, Category, Tier
	-- TIER I
	{"BerriesSpice","Desert", 1, "PotCrude"},
	{"AppleSpice","Desert", 1, "PotCrude"},
	{"MushroomHerb","Primary", 1, "PotCrude"},
	{"FishHerb","Primary", 1, "PotCrude"},
	{"PumpkinHerb","Secondary", 1, "PotCrude"},
	{"Porridge","Secondary", 1, "PotCrude"},
	{"CarrotSalad","Secondary", 1, "PotCrude"},
	-- TIER II
	{"BerriesStew","Desert", 2, "CookingPotCrude"},
	{"AppleStew","Desert", 2, "CookingPotCrude"},
	{"MushroomSoup","Primary", 2, "CookingPotCrude"},
	{"FishSoup","Primary", 2, "CookingPotCrude"},
	{"PumpkinSoup","Secondary", 2, "CookingPotCrude"},
	{"BreadCrude","Secondary", 2, "OvenCrude"},
	{"CarrotStirFry","Secondary", 2, "CookingPotCrude"}
}

ClothList = { -- Name, from, Tier
	{"TopPoncho", 1},
	{"TopTunic", 1},
	{"TopToga", 1}
}


HouseTier = { -- model, Tier
	"",
	"Hut",
	"LogCabin",
}

SignLinks = {}

TimeoutDuration = 7


-- Helpers functions:

function shuffle(array)
    local counter = #array
    while counter > 1 do
        local index = math.random(counter)
		array[index], array[counter] = array[counter], array[index]
        counter = counter - 1
    end
end


function emptyCallback()
end












--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-----------------     Quest Class: Used to trigger achievement                                ----------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------


QuestManager = {_metrics={}}
QuestManager.__index = QuestManager

function QuestManager:updateQuests()
	-- TODO: dyn quest, + conf in file
	if (self._metrics['MoveIn'] or 0) > 9 and (self._metrics['Wuv2'] or 0) > 99 then
		--self._actifList.list = {t=self, n=self._actifList.list}
		--ModUI.ShowPopup("Nice job!","Quest done.")
		ModQuest.SetQuestComplete('AcademyColonisation2', true)
	end
end

function QuestManager:up(metric)
	self._metrics[metric] = 1 + (self._metrics[metric] or 0)
	self:updateQuests()
end

function QuestManager:down(metric)
	self._metrics[metric] = -1 + (self._metrics[metric] or 0)
	self:updateQuests()
end

function QuestManager:fromData(data)
	self._metrics = data
end

function QuestManager:getData()
	return self._metrics
end













-------------------------------------------------------------
--- Activable Class: Object that can be updated each tick ---
-------------------------------------------------------------


Activable = {_actifList={list=nil}}
Activable.__index = Activable

function Activable:activate()
	--print("activate")
	self._actifList.list = {t=self, n=self._actifList.list}
end

function Activable:disactivate()
	if self._actifList.list == nil then
		return
	end
	if self._actifList.list.t == self then
		self._actifList.list = self._actifList.list.n
	else
		local it = self._actifList.list
		while it.n ~= nil and it.n.t ~= self do
			it = it.n
		end
		if it.n ~= nil then
			it.n = it.n.n
		--else
			--error("Actif not found")
		end
	end
end

function Activable:updateActifs()
	local it = self._actifList.list
	while it ~= nil do
		it.t:update()
		it = it.n
	end
end

function Activable:isActivated()
	if self._actifList.list == nil then
		return false
	end
	if self._actifList.list.t == self then
		return true
	else
		local it = self._actifList.list
		while it.n ~= nil and it.n.t ~= self do
			it = it.n
		end
		if it.n ~= nil then
			return true
		else
			return false
		end
	end
end

function Activable:subclass(newClass)
  setmetatable(newClass, self)
  newClass.__index = newClass
  newClass._actifList={list=nil}
  return newClass
end






















--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-----------------     Folk Class: Handle behaviour of colonists                               ----------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
Folk=Activable:subclass({id=0, house=nil, state=0, dest={}, top=nil, choice=nil, satisfaction=0, though=nil, folkList=List:new(), askingstation=nil, lastSeen={}, lock=nil})
local FolkVisionLength = 15

function Folk:spawn(x,y)
   Folk:new(ModBase.SpawnItem("Client", x, y),100):activate()
end

function Folk:register(id)
	Folk:new(id,100):activate()
end


function Folk:new(id, state, house, top, dest, choice, satisfaction, though, lastSeen, askingstation, lock, activated)
	o = {}
	setmetatable(o, self)
	o.__index = o
	o.id = id
	o.state = state or 0
	o.house = house or nil
	o.top = top or nil
	o.dest = dest or {}
	o.choice = choice or nil
	o.satisfaction = satisfaction or 0
	o.though = though or nil
	o.lastSeen = lastSeen or {x=0, y=0}
	o.askingstation = askingstation or nil
	o.lock = lock or nil
	if activated then o:activate() end
	Folk.folkList:push(o)
	return o
end

function Folk:fromData(data)
	data.house = data.house and House:fromData(data.house) or nil
	data.though = data.though and Though:fromData(data.though) or nil
	data.askingstation = data.askingstation and AskingStation:fromData(data.askingstation) or nil
	newFolk = self:new(data.id, data.state, data.house, data.top, data.dest, data.choice, data.satisfaction, data.though, data.lastSeen, data.askingstation, data.lock, data.activated)
	if data.house then
		data.house.folk = newFolk
		House.freeHouse:remove(data.house)
	end
	if data.askingstation then data.askingstation.folk = newFolk end
	return newFolk
end

function Folk:getData()
	return {id=self.id, house=self.house and self.house:getData() or nil, state=self.state, dest=self.dest, top=self.top, choice=self.choice, satisfaction=self.satisfaction, lastSeen=self.lastSeen, askingstation=self.askingstation and self.askingstation:getData(), though=self.though and self.though:getData() or nil, lock=self.lock, activated=self:isActivated()}
end

function Folk:moveIn(house,preventPopIn)
	self.house = house
	House.freeHouse:remove(self.house)
	self.house.folk = self
	self.state = 330 -- state turn back to home
	local houseCoord = self.house:coordinates()
	local r = ModBuilding.GetRotation(self.house.id)
	houseEdited_enable = false
	ModObject.DestroyObject(self.house.id)
	self.house.id = ModBase.SpawnItem("Occupied "..HouseTier[self.house.tier], houseCoord[1], houseCoord[2], true , true)
	ModBuilding.SetRotation(self.house.id, r)
	ModBuilding.RegisterForBuildingEditedCallback(self.house.id, houseEdited)
	houseEdited_enable = true
	if not preventPopIn then self:popIn() end
end

function Folk:moveOut()
	if self.state == -1 and self.though != nil then
		self.though:stopThinking()
	end
	local dc = self.house:door()
	self:popOut(100, dc[1], dc[2])
	House.freeHouse:push(self.house)
	local houseCoord = self.house:coordinates()
	local r = self.house:rotation()
	houseEdited_enable = false
	ModObject.DestroyObject(self.house.id) -- only skipped when not existing
	self.house.id = ModBase.SpawnItem("Free "..HouseTier[self.house.tier], houseCoord[1], houseCoord[2], true , true)
	ModBuilding.SetRotation(self.house.id, r)
	houseEdited_enable = true
	self.house.folk = nil
	self.house = nil
	ModDebug.Log("moveOut: Done")
end

function Folk:popIn()
	ModObject.DestroyObject(self.id)
	-- TODO Save client stats
	self.state = -1 -- state inside
	self:disactivate()
	self.house:activate()
	QuestManager:up('MoveIn')
end

function Folk:popOut(state, x, y)
	self.id = ModBase.SpawnItem("Client" .. (self.top and (" with ".. self.top) or ""), x, y)
	ModDebug.Log("pop out", self.id)
	-- TODO Load client stats
	self.state = state
	self.house:disactivate()
	self:activate()
end

function Folk:updateSkin()
	coords = ModObject.GetObjectTileCoord(self.id)
	ModObject.DestroyObject(self.id)
	self.id = ModBase.SpawnItem("Client" .. (self.top and (" with ".. self.top) or ""), coords[1], coords[2])
end

function Folk:waitBuldingFree(x, y)
	
end


function findFreeAdjacent(coord, from)
	local adj = {{coord[1],coord[2]+1},{coord[1],coord[2]-1},{coord[1]+1,coord[2]},{coord[1]-1,coord[2]}}
	--shuffle(adj)
	for i=4,1,-1 do
		local flg = from[1] == adj[i][1] and from[2] == adj[i][2]
		local typeOnTile = ModTiles.GetObjectTypeOnTile(adj[i][1],adj[i][2])
		--if #ModTiles.GetSelectableObjectUIDs(adj[i][1],adj[i][2]) > 0 then--or Folk.folkList:find(function(e) return e.dest.x == v[1] and e.dest.y == v[2]; end) then
			for j=#typeOnTile,1,-1 do
			--for _,r in pairs(ModTiles.GetSelectableObjectUIDs(adj[i][1],adj[i][2])) do
				if string.sub(typeOnTile[j], 1, 8) ~= "Flooring" then
					if flg and typeOnTile[j] == "Client" then
						flg = false
					else
						table.remove(adj, i)
					break
					end
				end
			end
		--end
	end
	while #adj > 1 do
		if squareDist(from, adj[1]) > squareDist(from, adj[2]) then
			adj[1] = adj[2]
		end
		table.remove(adj, 2)
	end
	return adj[1]
end

function squareDist(p1,p2)
	return (p1[1]-p2[1])*(p1[1]-p2[1]) + (p1[2]-p2[2])*(p1[2]-p2[2])
end

function Folk:findCloseObject(objectType, searchFunction, freeAdjacent, onTopOf)
	local tbs = {self.id}
	local seen = {}
	seen[tostring(self.id)] = true
	local tbsSize = 1
	
	local i = 1
	while i<=tbsSize do
		local scoord = ModObject.GetObjectTileCoord(tbs[i])
		local uids = searchFunction(objectType, scoord[1]-FolkVisionLength,scoord[2]-FolkVisionLength, scoord[1]+FolkVisionLength,scoord[2]+FolkVisionLength)
		local uid = nil
		local coord
		local coord2
		for j=#uids,1,-1 do
			if not Folk.folkList:find(function(e) return e.dest.id == uids[j]; end) then
				coord2 = ModObject.GetObjectTileCoord(uids[j])
				if not uid or squareDist(scoord, coord) > squareDist(scoord, coord2) then
					local otoUids = onTopOf and ModTiles.GetObjectTypeOnTile(coord2[1],coord2[2])
					if onTopOf then
						for k=#otoUids,1,-1 do
							if string.sub(otoUids[k], 1, 8) == "Flooring" then
								table.remove(otoUids, k)
							end
						end
					end
					if not onTopOf or (#otoUids == 2 and (otoUids[1] == objectType and otoUids[2] == onTopOf or otoUids[2] == objectType and otoUids[1] == onTopOf)) then	
						if freeAdjacent then
							coord2 = findFreeAdjacent(coord2, scoord)
						end
						if coord2 then
							coord = coord2
							uid = uids[j]
						end
					end
				end
			end
		end
		if uid then
			return {coord[1],coord[2],uid}
		end
		for _,signType in pairs({"Sign","Sign2","Sign3"}) do
			for _,v in pairs(ModTiles.GetObjectsOfTypeInAreaUIDs(signType, scoord[1]-FolkVisionLength,scoord[2]-FolkVisionLength, scoord[1]+FolkVisionLength,scoord[2]+FolkVisionLength)) do
				if SignLinks[tostring(v)] and not seen[tostring(v)] then
					seen[tostring(v)] = true;
					seen[SignLinks[tostring(v)]] = true;
					table.insert(tbs, SignLinks[tostring(v)])
					tbsSize = tbsSize + 1
				end
			end
		end
		i = i + 1
	end
	return nil
end

function Folk:update()
	if ModObject.GetObjectTileCoord(self.id)[1] <= 0 then
		return
	end
	-- state -1 == inside
	ModDebug.Log("St:", self.state)
	if self.state%10 == 1 then -- moving state
		-- maybe a timeout handle in case of error while moving
		--Info = ModObject.GetObjectProperties(self.id)
		coords = ModObject.GetObjectTileCoord(self.id)
		if coords[1] == self.dest.dx and coords[2] == self.dest.dy or coords[1] == self.lastSeen.x and coords[2] == self.lastSeen.y then
			self.dest.id = nil
			self.state = self.state - 1 -- state pass to base state
		end
		self.lastSeen.x = coords[1]
		self.lastSeen.y = coords[2]
	elseif self.state == 100 then -- searching house state
		local scoord = ModObject.GetObjectTileCoord(self.id) --TODO  free accepting any building
		local targetHut = self.dest.id or self:findCloseObject("Free Hut", ModBuilding.GetAllBuildingsUIDsOfType)
		if targetHut then
			if self.though then
				self.though:stopThinking()
				self.though = nil
			end
			if not self:moveToBuilding(targetHut[3], scoord) then -- if already there
				-- claim house
				house = House.freeHouse:find(function(e) return e.id == targetHut[3]; end)
				if not house then
					error("House claimed not found, sanity.")
				end
				self:moveIn(house)
			end
		else
			if not self.though then
				scoord = ModObject.GetObjectTileCoord(self.id)
				self.though = Though:thinkOf("ThoughOfHut",scoord[1], scoord[2])
			end
		end
	elseif self.state == 200 then -- searching food 
				ModDebug.Log("Seek ClaimTable")
		local scoord = ModObject.GetObjectTileCoord(self.id)
		-- tableList = ModBuilding.GetAllBuildingsUIDsOfType("Free Table", scoord[1]-FolkVisionLength,scoord[2]-FolkVisionLength, scoord[1]+FolkVisionLength,scoord[2]+FolkVisionLength)
		local targetTable = self.dest.id or self:findCloseObject("Free Table", ModBuilding.GetAllBuildingsUIDsOfType)
		--TODO: closest?
		-- targetTable = tableList[1]
		if targetTable then -- ~= nil and targetTable ~= -1
			ModDebug.Log("found ClaimTable")
			if self.though then
				self.though:stopThinking()
				self.though = nil
			end
			--ModDebug.Log("Found: I'm in ", scoord[1], " ", scoord[2])
			--local coord = ModObject.GetObjectTileCoord(targetTable)
			if not self:moveToBuilding(targetTable[3], scoord) then -- if already there
				-- claim house
				self.state = 202 -- wait state
				ModDebug.Log("ClaimTable")
				AskingStation:claim(self, targetTable[3], self:chooseFood())
			end
		else
			if not self.though then
				scoord = ModObject.GetObjectTileCoord(self.id)
				self.though = Though:thinkOf("ThoughOfFoodDesk",scoord[1], scoord[2])
			end
		end
	elseif self.state == 210 then -- come back food state
		local houseCoord = self.house:door()
		scoord = ModObject.GetObjectTileCoord(self.id)
		if scoord[1] == houseCoord[1] and scoord[2] == houseCoord[2] then -- already there
			self:popIn()
			self.house.foodLevel = (self.house.tier == 3 and 60 or 50) * self.satisfaction
		else
			self:moveTo(houseCoord[1], houseCoord[2])
		end
	elseif self.state == 300 then -- searching cloth desk state
		local scoord = ModObject.GetObjectTileCoord(self.id)
		local targetPedestal = self.dest.id or self:findCloseObject("Pedestal", ModTiles.GetObjectsOfTypeInAreaUIDs, true)
		if targetPedestal then
			if self.though then
				self.though:stopThinking()
				self.though = nil
			end
			if not self:moveToObjectCoord(targetPedestal, scoord) then -- if already there
				self.state = 310 -- choosing cloth state
				self.choice = nil
			end
		elseif not self.though then
			self.though = Though:thinkOf("ThoughOfClothDesk",scoord[1], scoord[2])
			self.dest.timer = 5
		elseif self.dest.timer == 1 then
			if self.though then
				self.though:stopThinking()
				self.though = nil
			end
			self.state = 320 -- turning home
			self.satisfaction = 0
		else
			self.dest.timer = self.dest.timer - 1
		end
	elseif self.state == 310 then -- choosing cloth state
		local scoord = ModObject.GetObjectTileCoord(self.id)
		if not self.choice then
			local choice = self:chooseCloth()
			self.choice = choice--.." on hanger"
			self.though = Though:thinkOf("ThoughOf"..choice[1],scoord[1], scoord[2])
			self.dest.timer = 5
		end
		local targetCloth = self:findCloseObject(self.choice[1], ModTiles.GetObjectsOfTypeInAreaUIDs, true, "Pedestal")
		if targetCloth then -- and targetTable ~= -1
			if self.though then
				self.though:stopThinking()
				self.though = nil
			end
			if not self:moveToObjectCoord(targetCloth, scoord) then -- already there
				-- claim house
				self.state = 320 -- get cloth
				self.top = self.choice[1] --string.gsub(self.choice, " on hanger", "")
				self.satisfaction = #self.choice
				self:updateSkin()
				ModObject.DestroyObject(targetCloth[3])
				self.choice = nil
			end
		else
			self.dest.timer = self.dest.timer-1
			if self.dest.timer == 0 then
				if self.though then
					self.though:stopThinking()
					self.though = nil
				end
				if #self.choice == 1 then
					self.though = nil
					self.choice = nil
					self.satisfaction = 0
					self.state = 320
				else
					table.remove(self.choice, 1)
					self.though = Though:thinkOf("ThoughOf"..self.choice[1],scoord[1], scoord[2])
					self.dest.timer = 5
				end
			end
		end
	elseif self.state == 320 then -- come back cloth state
		local houseCoord = self.house:door()
		scoord = ModObject.GetObjectTileCoord(self.id)
		if scoord[1] == houseCoord[1] and scoord[2] == houseCoord[2] then -- already there
			self:popIn()
			self.house.clothLevel = self.satisfaction --* 10
		else
			self:moveTo(houseCoord[1], houseCoord[2])
		end
	elseif self.state == 330 then -- come back only
		local houseCoord = self.house:door()
		scoord = ModObject.GetObjectTileCoord(self.id)
		if scoord[1] == houseCoord[1] and scoord[2] == houseCoord[2] then -- already there
			self:popIn()
		else
			self:moveTo(houseCoord[1], houseCoord[2])
		end
	end
end

function Folk:chooseFood()
	-- Could be optimised
	cf = {}
	for i=1, #FoodCategory do
		cf[i] = FoodCategory[i]..tostring(self.house.tier-1)
	end
	shuffle(cf)
	return cf
end

function Folk:chooseCloth()
	-- Could be optimised
	cf = {}
	for i=1, #ClothList do
		cf[i] = ClothList[i][1]
	end
	shuffle(cf)
	return cf
end
-- function Folk:chooseCloth()
	-- return ClothList[1 + math.floor(math.random() * (#ClothList))][1]
-- end

function Folk:moveTo(dx, dy)
	--ModDebug.Log("MoveTo", dx, " ", dy)
	self.state = (self.state - (self.state%10) + 1) -- state moving
	self.dest.dx = dx
	self.dest.dy = dy
	ModGoTo.moveTo(self.id, dx, dy)
end

function Folk:moveToBuilding(id, from)
	dc = House.door({modelId=id})
	if from ~= nil and dc[1] == from[1] and dc[2] == from[2] then
		self.dest.id = nil
		return false
	end
	self.dest.id = id
	self:moveTo(dc[1], dc[2])
	return true
end

function Folk:moveToObject(id, from)
	dc = House.coordinates({id=id})
	if from ~= nil and dc[1] == from[1] and dc[2] == from[2] then
		self.dest.id = nil
		return false
	end
	self.dest.id = id
	self:moveTo(dc[1], dc[2])
	return true
end

function Folk:moveToObjectCoord(object, from)
	if from ~= nil and object[1] == from[1] and object[2] == from[2] then
		self.dest.id = nil
		return false
	end
	self.dest.id = object[3]
	self:moveTo(object[1], object[2])
	return true
end

























--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-----------------     House Class: Handle behaviour of folk house                             ----------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- TODO hut dispariton and move check

House=Activable:subclass({tier=0, id=0, modelId=0, broken_id=nil, foodLevel=0, clothLevel=0, folk=nil, satisfactionLevel=0, durability=0, freeHouse=List:new()})

function House:new(tier, id, modelId, folk, present, foodLevel, clothLevel, satisfactionLevel, durability, broken_id, activated)
   o = {}
   setmetatable(o, self)
   o.__index = self
   o.tier = tier
   o.id=id
   o.modelId=modelId
   o.folk = folk or nil
   o.present = present or false
   o.foodLevel = foodLevel or 0
   o.clothLevel = clothLevel or 0
   if o.clothLevel > 3 then -- TODO remove on next patch, temporary fix for 1.1.3
		o.clothLevel = 1
	end
   o.satisfactionLevel = satisfactionLevel or 0
   o.durability = durability or 10
   o.broken_id = broken_id or nil
   if activated then o:activate() end
	House.freeHouse:push(o)
   return o
end

function House:fromData(data)
	--TODO: this a game bug, sometime bulding order change on save
	local recreate = false
	local coord = ModObject.GetObjectTileCoord(data.modelId)
	local UIDs = ModTiles.GetSelectableObjectUIDs(coord[1], coord[2])
	local upLayer = data.broken_id or data.id
	for i=1,#UIDs do
		if UIDs[i] == upLayer then
			recreate = true -- if model is after it must be recreated
			break
		elseif UIDs[i] == data.modelId then
			break
		end
		--ModDebug.Log("(",data.modelId, ",", data.id,")",UIDs[i])
	end
	if data.broken_id then
		if recreate then
			local r = ModBuilding.GetRotation(data.modelId)
			local type = ModObject.GetObjectType(data.modelId)
			--ModDebug.Log("(",data.modelId,")",type,":",data.broken_id)
			ModObject.DestroyObject(data.modelId)
			ModObject.DestroyObject(data.broken_id)
			-- --TODO verifie ModBase.SpawnItem("Broken"..string.gsub(ModObject.GetObjectProperties(data.id)[1], "Occupied", ""), coord[1]+2, coord[2], true, true)
			brokenHouseRepaired_enable = false
			houseEdited_enable = false
			newHouseSpawned_enable = false
			data.modelId = ModBase.SpawnItem(type, coord[1], coord[2])
			ModBuilding.SetRotation(data.modelId, r)
			ModObject.SetObjectActive(data.modelId, false)
			data.broken_id = ModBase.SpawnItem("Broken "..type, coord[1], coord[2], false, false, true)
			ModBuilding.SetRotation(data.broken_id, r)
			brokenHouseRepaired_enable = true
			houseEdited_enable = true
			newHouseSpawned_enable = true
		end
		ModBuilding.RegisterForBuildingEditedCallback(data.broken_id, brokenHouseEdited)
	else
		if recreate then
			local r = ModBuilding.GetRotation(data.modelId)
			local modelType = ModObject.GetObjectType(data.modelId)
			local type = ModObject.GetObjectType(data.id)
			ModDebug.Log("(",data.modelId,")",type,":",data.id,"[", coord[1],",", coord[2],"]")
			ModObject.DestroyObject(data.modelId)
			ModObject.DestroyObject(data.id)
			houseEdited_enable = false
			newHouseSpawned_enable = false
			data.modelId = ModBase.SpawnItem(modelType, coord[1], coord[2])
			ModBuilding.SetRotation(data.modelId, r)
			data.id = ModBase.SpawnItem(type, coord[1], coord[2], false, true)
			ModBuilding.SetRotation(data.id, r)
			houseEdited_enable = true
			newHouseSpawned_enable = true
		end
		ModBuilding.RegisterForBuildingEditedCallback(data.id, houseEdited)
	end
	return House:new(data.tier, data.id, data.modelId, nil, data.present, data.foodLevel, data.clothLevel, data.satisfactionLevel, data.durability, data.broken_id, data.activated)
end

function House:getData()
	return {tier=self.tier, id=self.id, modelId=self.modelId, broken_id=self.broken_id, foodLevel=self.foodLevel, clothLevel=self.clothLevel, satisfactionLevel=self.satisfactionLevel, durability=self.durability, activated=self:isActivated()}
end

function House:resetDurability()
	self.durability = 10
end

function House:coordinates()
	return ModObject.GetObjectTileCoord(self.modelId)
end

function House:rotation()
	return ModBuilding.GetRotation(self.modelId)
end

function House:door()
	ModDebug.Log("Door")
	ModDebug.Log(self.id)
	coord = ModObject.GetObjectTileCoord(self.modelId)
	ModDebug.Log("Door end")
	r = House.rotation(self) -- allow non object call
	--ModDebug.Log("rotation : ",r)
	if r == 0 then
		coord[2] = coord[2] + 1
	elseif r == 1 then
		coord[1] = coord[1] - 1
	elseif r == 2 then
		coord[2] = coord[2] - 1
	else
		coord[1] = coord[1] + 1
	end
	return coord
end
--UnregisterForBuildingEditedCallback---------------------------------------------------
--RegisterForBuildingTypeSpawnedCallback-------------------------------
brokenhouseEdited_enable = true
function brokenHouseEdited(BuildingUID, EditType, NewValue)
	ModDebug.Log("brokenHouseEdited: ",BuildingUID, " ", EditType, " ", NewValue)
	if not brokenhouseEdited_enable then
		return
	end

	ModDebug.Log("Seek", BuildingUID)
	house = List.find({l = House._actifList.list}, function(e) return e.broken_id == BuildingUID; end)
	if not house then
		error("brokenHouseEdited: House couldn't be found, this error could corrupt your modData, it is recommended to save on different name and report the bug.")
	end
	
	if EditType == "Move" then -- or EditType == "Rotate" then -- On move + rotate work is done twice, should not be a big deal
		local x, y = NewValue:match("([^:]+):([^:]+)")
		local r = ModBuilding.GetRotation(BuildingUID)
		local modelType = ModObject.GetObjectProperties(house.modelId)[1]
		local brokenType = "Broken "..modelType
		-- TODO: ask if auto release of register
		ModBuilding.UnregisterForBuildingEditedCallback(BuildingUID)
		ModObject.DestroyObject(BuildingUID)
		ModObject.DestroyObject(house.modelId)
		
		newHouseSpawned_enable = false
		house.modelId = ModBase.SpawnItem(modelType, tonumber(x), tonumber(y), false, true)
		ModBuilding.SetRotation(house.modelId, r)
		ModObject.SetObjectActive(house.modelId, false)
		newHouseSpawned_enable = true

		brokenHouseRepaired_enable = false
		house.broken_id = ModBase.SpawnItem(brokenType, tonumber(x), tonumber(y), false, false, true)
		ModBuilding.SetRotation(house.broken_id, r)
		ModBuilding.RegisterForBuildingEditedCallback(house.broken_id, brokenHouseEdited)
		brokenHouseRepaired_enable = true
	elseif EditType == "Destroy" then
		local coord = house:coordinates()
		local r = house:rotation()
		local modelType = ModObject.GetObjectProperties(house.modelId)[1]
		local brokenType = "Broken "..modelType
		brokenHouseRepaired_enable = false
		house.broken_id = ModBase.SpawnItem(brokenType, coord[1], coord[2], false, false, true)
		ModBuilding.SetRotation(house.broken_id, r)
		ModBuilding.RegisterForBuildingEditedCallback(house.broken_id, brokenHouseEdited)
		brokenHouseRepaired_enable = true
	end
	-- elseif EditType == "Rotate" then
	-- else
	-- 	ModDebug.Log("Edited : ", EditType)
	-- end
	ModDebug.Log("[DONE] brokenHouseEdited: ",BuildingUID, " ", EditType, " ", NewValue)
end

function House:update()
	if self.durability == 0 then -- If broken skip update, not disactivated to stay catalogued
		if self.folk.though then
			self.folk.though:stopThinking() -- TODO remove sanity for version 1.3.1.1
			self.folk.though = nil
		end
		return
	end
	local dc = nil
	--ModDebug.Log(self.foodLevel)
	if self.foodLevel>0 and (self.tier<=2 or self.clothLevel>0) and self.durability>0 then
		local coord = self:coordinates()
		if self.folk.though and not ModObject.IsValidObjectUID(self.folk.though.id) then
			self.folk.though:stopThinking()
			self.folk.though = nil
		end
		if not self.folk.though then
			self.folk.though = Though:thinkOf("heart",coord[1], coord[2])
			-- ModObject.SetNodeMaterial(self.folk.though.id, 'tranche'..testnb..'$', "Heart/colors/red_light")
		end
		if self.folk.though.typeName ~= "heart"..tostring(math.floor((20*self.satisfactionLevel)/HeartDelay[self.tier])) then
			for i=0,math.floor((20*self.satisfactionLevel)/HeartDelay[self.tier])-1 do
				ModObject.SetNodeMaterial(self.folk.though.id, 'tranche'..i..'$', "Heart/colors/red_light")
			end
			for i=math.floor((20*self.satisfactionLevel)/HeartDelay[self.tier])-1,17 do
				ModObject.SetNodeMaterial(self.folk.though.id, 'tranche'..i..'$', "Heart/colors/red_dark")
			end
		end
		-- if not self.folk.though then
		-- 	self.folk.though = Though:thinkOf("heart"..tostring(math.floor((19*self.satisfactionLevel)/HeartDelay[self.tier])),coord[1], coord[2])
		-- elseif self.folk.though.typeName ~= "heart"..tostring(math.floor((19*self.satisfactionLevel)/HeartDelay[self.tier])) then
		-- 	local r = self.folk.though.rotation
		-- 	self.folk.though:stopThinking()
		-- 	self.folk.though = Though:thinkOf("heart"..tostring(math.floor((19*self.satisfactionLevel)/HeartDelay[self.tier])),coord[1], coord[2],r)
		-- end
		
		-- ModObject.SetNodeMaterial(testcoeur, 'tranche'..testnb..'$', "Heart/colors/red_light")
		-- testnb = testnb + 1
		
		self.satisfactionLevel = self.satisfactionLevel + 1
		self.foodLevel = self.foodLevel - 1
		if self.satisfactionLevel == HeartDelay[self.tier] then 
		ModDebug.Log("dur , ", self.durability)
			self.satisfactionLevel = 0
			dc = self:door()
			ModBase.SpawnItem("FolkHeart"..tostring(self.tier), dc[1], dc[2])
			QuestManager:up('Wuv'..tostring(self.tier))
			if self.tier>2 then
				self.clothLevel = self.clothLevel - 1
				if self.clothLevel==0 then self.folk.top = nil end
			end
			ModDebug.Log("dur , ", self.durability)
			self.durability = self.durability - 1
			ModDebug.Log("dur , ", self.durability)
			if self.durability==0 then 
				local r = self:rotation()
				local type = string.gsub(ModObject.GetObjectProperties(self.id)[1], "Occupied", "")
				brokenhouseEdited_enable = false
				houseEdited_enable = false
				brokenHouseRepaired_enable = false
				ModObject.DestroyObject(self.id)
				ModObject.SetObjectActive(self.modelId, false)
				self.broken_id = ModBase.SpawnItem("Broken"..type, coord[1], coord[2], false, false, true)
				ModBuilding.SetRotation(self.broken_id, r)
				ModBuilding.RegisterForBuildingEditedCallback(self.broken_id, brokenHouseEdited)
				brokenHouseRepaired_enable = true
				houseEdited_enable = true
				brokenhouseEdited_enable = true
				if self.folk.though then
					self.folk.though:stopThinking()
					self.folk.though = nil
				end
			end
		end
		return -- If happy nothing happen else
	end
	if self.folk.though then
		self.folk.though:stopThinking()
		self.folk.though = nil
	end
	--if self.foodLevel>0 then self.foodLevel = self.foodLevel - 1 end
	--if self.clothLevel>0 then self.clothLevel = self.clothLevel - 1; if self.clothLevel==0 then self.folk.top = nil end end
	--ModDebug.Log(self.foodLevel)
	if self.folk==nil or self.folk.state ~= -1 then
	--idle state
		error("House inconsistent state.")
	else
		-- UnHappy folk seek for better house
		local tgt = House.freeHouse:find(function(e) return e.tier > self.tier; end)
		if dc == nil then dc = self:door() end
		if tgt then
			local t = self.folk
			t:moveOut()
			t:moveIn(tgt, true)
		elseif self.tier>2 and self.clothLevel == 0 then
			self.folk.choice = nil
			self.folk:popOut(300, dc[1], dc[2]) -- State seek cloth
		elseif self.foodLevel == 0 then
			self.folk:popOut(200, dc[1], dc[2]) -- State seek food
		end
	end
end















AskingStation=Activable:subclass({id=0, x=0, y=0, state=0, folk=nil, askedList=nil, stationList=List:new()})

function AskingStation:claim(folk,idClaimed,objectsAsked)
	-- TODO check if already claimed w= must be done for multi-client
	-- ie if as already existe on it
	coord = ModObject.GetObjectTileCoord(idClaimed)
	ModDebug.Log("AskingStation:claim:",ModObject.GetObjectType(idClaimed), idClaimed)
	ModObject.DestroyObject(idClaimed)
	tc = AskingStation:new(ModBase.SpawnItem("Table needing "..objectsAsked[1], coord[1], coord[2], true , true), coord[1], coord[2], 100,folk)
	ModObject.SetObjectRotation(tc.id, 0, 0, 0)
	tc.askedList = objectsAsked
	tc.state = 100 + TimeoutDuration
	folk:disactivate()
	tc:activate()
	scoord = ModObject.GetObjectTileCoord(folk.id)-- TODO  as:fromdata and as:getdata, and folk etc
	tc.folk.though = Though:thinkOf("ThoughOf"..objectsAsked[1],scoord[1], scoord[2])
end

function AskingStation:fromData(data)
	scoord = ModObject.GetObjectTileCoord(data.id)
	x = scoord[1]
	y = scoord[2]
	ModObject.SetObjectActive(ModBuilding.GetBuildingCoveringTile(x,y), false)
	ModObject.SetObjectRotation(data.id, 0, 0, 0)
	return AskingStation:new(data.id, data.x, data.y, data.state, nil, data.askedList, data.activated)
end

function AskingStation:getData()
	return {id=self.id, x=self.x, y=self.y, state=self.state, askedList=self.askedList, activated=self:isActivated()}
end

function AskingStation:free()
	if self.folk.though then
		self.folk.though:stopThinking()
		self.folk.though = nil
	end
	local coord = ModObject.GetObjectTileCoord(self.id)
	self:disactivate()
	ModObject.DestroyObject(self.id)
	ModBase.SpawnItem("Free Table", coord[1], coord[2])
	self.folk.state = self.folk.state - (self.folk.state%10) + 10
	self.folk.satisfaction = #self.askedList
	self.folk:activate()
	AskingStation.stationList:remove(self)
	self.folk.askingstation = nil
	self.folk:update()
end

function AskingStation:timeout()
	table.remove(self.askedList, 1)
	if #self.askedList == 0 then
		self:free()
		return
	end
	-- TODO getObject property to avoid using Table needing
	local scoord = ModObject.GetObjectTileCoord(self.id)
	x = scoord[1]
	y = scoord[2]
	ModObject.DestroyObject(self.id)
	self.id = ModBase.SpawnItem("Table needing "..self.askedList[1], x, y, true , true)
	ModObject.SetObjectRotation(self.id, 0, 0, 0)
	self.state = self.state - (self.state%100) + TimeoutDuration
	scoord = ModObject.GetObjectTileCoord(self.folk.though.id)
	self.folk.though:stopThinking()
	self.folk.though = Though:thinkOf("ThoughOf"..self.askedList[1],scoord[1], scoord[2])
end

function AskingStation:new(id, x, y, state, folk, askedList, activated)
   o = {}
   setmetatable(o, self)
   o.__index = self
   o.id=id
   o.x=x
   o.y=y
   o.state= state or 0
   o.folk = folk or nil
   if folk then folk.askingstation = o end
   o.askedList = askedList or nil
   if activated then o:activate() end
	AskingStation.stationList:push(o)
   return o
end

function AskingStation:update()
	--if self.folk==nil or self.folk.state ~= -1 then
	--idle state
	--	error("AskingStation inconsistent state.")
	--else
		if self.state - (self.state)%100 == 200 then -- Using delivered
			if self.state%100 > 0 then -- Using delivered object
				self.state = self.state - 1
			else -- done using delivered object
				self:free()
			end
		elseif self.state - (self.state)%100 == 100 then -- Wait delivering (0: timeout)
			if self.state%100 > 0 then -- Waiting
				self.state = self.state - 1
			else -- Timeout
				self:timeout()
			end
		end
	--end
end




function fillTableWithFood(UserUID, TileX, TileY, TargetUID, TargetType,a,b,c)
	-- if ModObject.GetObjectProperties(UserUID)[1] ~= "FarmerPlayer" then
		-- ModBot.DropAllHeldObjects(MustDrop.target)
	-- else
		-- ModPlayer.DropAllHeldObjects()
	-- end
	-- TODO find item in hand instead of reading name, for food
	as = AskingStation.stationList:find(function(e) return e.id == TargetUID; end)
	ModObject.DestroyObject(TargetUID)
	-- TODO spawn as
	ModDebug.Log("Table with "..(string.gsub(TargetType, "Table needing ", "")))
	ModDebug.Log("Table with ",as.id)
	as.id = ModBase.SpawnItem("Table with "..(string.gsub(TargetType, "Table needing ", "")), TileX, TileY, true , true)
	as.folk.though:stopThinking()
	as.folk.though = nil
	ModObject.SetObjectRotation(as.id, 0, 0, 0)
	as.state = 205
	-- TODO add though method to folk to prevent lose of stability
	local scoord = ModObject.GetObjectTileCoord(as.folk.id)
	as.folk.though = Though:thinkOf("satisfactionHeart"..tostring(#as.askedList),scoord[1], scoord[2])
end
















function clothOnClient(UserUID, TileX, TileY, TargetUID, TargetType)
	as = AskingStation.stationList:find(function(e) return e.id == TargetUID; end)
	as.folk.top = string.gsub(TargetType, "Desk asking ", "")
	--ModDebug.Log(as.folk.top)
	as.folk:updateSkin()
	as:free()
	--ModObject.DestroyObject(TargetUID)
	-- TODO spawn as
	--ModDebug.Log("Table with "..(string.gsub(TargetType, "Table needing ", "")))
	--as.id = ModBase.SpawnItem("Table with "..(string.gsub(TargetType, "Table needing ", "")), TileX, TileY, true , true)
	--ModObject.SetObjectRotation(as.id, 0, 0, 0)
	--as.state = 205
	--as:activate()
end




-- lastDelta = global value, time spent until last update
Though=Activable:subclass({id=0, rotation=0, typeName=nil, lastDelta = 0})

function Though:new(id, typeName, rotation, activated)
	o = {}
	setmetatable(o, self)
	o.__index = self
	o.id=id
	o.typeName=typeName
	o.rotation = rotation or 0
	ModObject.SetObjectRotation(self.id, 0, self.rotation, 0)
   if activated then o:activate() end
   return o
end

function Though:fromData(data)
	return self:new(data.id, data.typeName, data.rotation, data.activated)
end

function Though:getData()
	return {id=self.id, rotation=self.rotation, typeName=self.typeName, activated = self:isActivated()}
end

function Though:thinkOf(typeName,x,y,rotation)
	t = Though:new(ModBase.SpawnItem(typeName, x, y), typeName, rotation)
	t:activate()
	return t
end

function Though:stopThinking()
	self:disactivate()
	ModObject.DestroyObject(self.id)
end

function Though:update()
	self.rotation = self.rotation + 180.0 * self.lastDelta * (string.sub(self.typeName,1,string.len("heart"))=="heart" and 0.3 or 1)
	ModObject.SetObjectRotation(self.id, 0, self.rotation, 0)
end

function Though:updateActifs(lastDelta)
	Though.lastDelta = lastDelta
	Activable.updateActifs(Though)
end

-- ExposingStation = {}

-- ExposingStation:exposed(id, type_name, x, y)
	-- -- No safety check
	-- ModObject.DestroyObject(id)
	-- ModBase.SpawnItem("Empty " .. type_name, x, y)
-- end







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
local MustDelete = nil
-- local MustMove = nil

local occupiedHouses = nil

local currentTime = 0
local checkVersion = true
local patchnote_seen = false

local patchDescription = {
	{"0.1.5.2", [[- Adjustement, folk though change a bit slower.
	Fix: Auto recreate hut on loading when needed. Sometime game mess with building order when saving.
]]},
	{"0.1.5.1", [[- Hotfix, broken hut did not always spawn correctly when world loaded.
]]},
	{"0.1.5", [[- Broken houses are back, you now have to repair them again
	Occupied house can now be deleted when folk is in
	Due to game limitation, deleting 'Free House' or 'Occupied House' will destroy definitively the building and not bring him back to your inventory
	Occupied house with folk out only trigger a warning message and cancel the deletion
	Display heart have been reworked, they will no more trigger a visual effect when filling
]]},
	{"0.1.4", [[- Add quest system, now "Colonisation Level2" can correctly be achieved. Unfortunately progress is not show, you only know when completed. A special UI could come later.
	FIX: remove a quick fix causing issue with occupied house moved.
	FIX: fix duplication of colonist when reloading the save.
]]},
	{"0.1.3.1", [[- Quick fix, remerge script file and disable broken house, house doesn't have to be repaired for now (to avoid an issue needing to be fixed quickly)
]]},
	{"0.1.3", [[- Important fix: Now cloth have correctly enought durability to produce 1,2 or 3 heart (and no more 10,20,30), saves will be automatically fixed
- Folk will now go to a free tile adjacent pedestal (instead of walking on them)
- Folk will use a pedestal only if there is not more item than the pedestal and the looking item on the tile
]]},
	{"0.1.2", [[- Remove stick stockage amount and berry stockage amount change
]]},
	{"0.1.1", [[- Fix a bug when stealing object on pedestal from folks could cause error
- Now folks goes to the right table side
- Folk now lock target object as robot does, they don't rush on same target anymore
- Add patchnote system
- A popup with updates since save show up after load
- A popup with ALL updates since begining show up after creating a new map (it's bad I know, I'm seeking for an alternative)
- Patchnote popup can be disactivated on mod configuration panel
]]}
}
local version = patchDescription[1][1]

function getPatchDescription(lastVersion)
	local acc = ""
	for k,v in pairs(patchDescription) do
		if v[1] == lastVersion then
			return acc
		end
		acc = acc .. [[
==========   ]] .. v[1] .. [[   ==========
]] .. v[2]
	end
	return acc
end

function Expose()
	-- Exposed variables
	-- ModBase.ExposeVariable("Amazing Variable", Amazing, ExposedCallback, 0, 20)
	-- ModBase.ExposeVariable("Speed", MaxSpeed, SpeedCallback)
	-- ModBase.ExposeVariable("Fun factor", 30, GenericCallback, 20, 40)
	-- ModBase.ExposeVariable("Instant Win", true, GenericCallback)
	ModBase.ExposeVariable("Never show patchnote", false, emptyCallback)
end

-- function ExposedCallback( param )

	-- Amazing = param
	
-- end

-- function SpeedCallback( param )

	-- ModDebug.Log("Param: ", param)
	
-- end

-- function GenericCallback( param )

-- end

function SteamDetails()

	-- Setting of Steam details
	ModBase.SetSteamWorkshopDetails("Folks are not animals", [[Folks Are Not Animals is a mod replacing the vanilla system of folk waiting at home for robot feeding them by folk walking to divers stations (as a table for food or a pedestal for clothes).

FANA only start really when you reach hut research and advanced cooking.
Craddle allow you to grow vanilla folk into grown one (named Client in the mod), all reference to folks in this description make refer actually to "Client" (i can't reuse the name folk in game)

Folks are now able to speak, represented by thoughts bubbles, bubbles can be watched by bots (but they can't pick them up).

You can't feed folks directly anymore, they now use table instead.
Folks now have wishes, which means if you give them their firsts wishes they will be more pleased and items will last longer.
For convenience, aliments are now categorized into 3 types:
Primary dish: Fish and Mushroom based dishes
Secondary dish: Pumpkin, Wheat, and Carrot based dishes
Dessert: Berry and Apple-based dishes
Only one category is enough for a colonist to be satiated, and all dishes of the same category have the same effect.

When a higher tier house (currently ony logcabin and hut available) is available folk will move in automatically.
Tier2 folks will seek for clothes dropped only on pedestal, clothes on the ground doesn't work. Currently only the 3 basic top are available.

Folks can see object in an area of 20 tiles centred on them, you can extend search zone by using linked sign.
When you drop a sign on an other one they are link (not visible), if a folk has a linked sign in his search area he will check in 20 tiles around the other one.

If you notice a bug or you have a comment, feel free to contact me on discord Skrommer
#1189, you can find me on Autonaut's discord too.

Future work will concern mod stability, more tier addition, and folk's behavior alongside overall enhancement.

Patchnotes:
]]..getPatchDescription("0"), {"FANA", "Folks are not animals", "Colonist", "halloweencompo"}, "small.png")
	
end

function replaceOverridedFood(arr)
	for k,v in pairs(arr) do
		if FoodCatalog[v] then
			arr[k] = "Served "..v
		end
	end
	return arr
end

function BeforeLoad()

	--ModDebug.Log(ModVariable.GetVariableForObjectAsInt("TopTunic", "Usage"))

	-- Before Load Function - The majority of calls go here
	
	ModDebug.Log("MOD - Create Berry Recipe - All Converters - 1 stick = 10 berries produced") 
	--ModVariable.SetIngredientsForRecipeSpecific("Berries", {"Stick"}, {1}, 10)
	
	--ModVariable.SetIngredientsForRecipe("Client", {"Folk"}, {1}, 1)

	ModVariable.SetIngredientsForRecipeSpecific("Cradle", "Client", {"Folk"}, {1}, 1) 
	ModVariable.SetVariableForObjectAsInt("Cradle", "ConversionDelay", 10)
	
	ModDebug.Log("MOD - Set Storage for Sticks to 200")
	-- ModVariable.SetVariableForStorageAmount("Stick", 200)
	
	ModDebug.Log("MOD - Set Storage for Berries to 200")
	-- ModVariable.SetVariableForStorageAmount("Berries", 200)
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
	
	
	-- ModVariable.SetVariableForObjectAsInt("Berry", "MaxUsage", 1);
	ModVariable.SetVariableFarmerAction("ModAction", "Table needing berry", "Berry", 1);
	
	
	-- Set single usage object, their durability
	for k,v in pairs(FoodList) do
		FoodCatalog[v[1]]={energy=ModVariable.GetVariableForObjectAsInt(v[1], "Energy")*(v[3]*2+1),tier=v[3]}
	end
	for k,v in pairs(FoodList) do
		ModVariable.SetVariableForObjectAsInt("Served "..v[1], "MaxUsage", 1);
		ModVariable.SetVariableForObjectAsInt("Served "..v[1], "Weight", ModVariable.GetVariableForObjectAsInt(v[1], "Weight"));
		ModVariable.SetIngredientsForRecipe("Served "..v[1], replaceOverridedFood(ModVariable.GetIngredientsForRecipe(v[1])), ModVariable.GetIngredientsAmountForRecipe(v[1]), 1)
		ModVariable.AddRecipeToConverter(v[4], "Served "..v[1], 1)
		ModVariable.RemoveRecipeFromConverter(v[4], v[1])
	end
	-- for k,v in pairs(ClothList) do
		-- ModVariable.SetVariableForObjectAsInt(v[1].." on hanger", "MaxUsage", 1);
		-----ModVariable.SetIngredientsForRecipe(v[1].." on hanger", ModVariable.GetIngredientsForRecipe(v[1]), ModVariable.GetIngredientsAmountForRecipe(v[1]), 1)
	--	ModVariable.AddRecipeToConverter("PotCrude", "Served "..v[1], 1)
	--	ModVariable.RemoveRecipeFromConverter("PotCrude", v[1])
	-- end
	ModVariable.AddRecipeToConverter("Workbench", "Pedestal", 1)
	
	--ModVariable.SetVariableForObjectAsFloat("Folk", "HeadScale", 5.0)
	--ModVariable.SetVariableForObjectAsInt("BerriesSpice", "Unlocked", 0);
	
	ModVariable.SetVariableForObjectAsInt("Broken Hut", "Unlocked", 0);
	ModVariable.SetVariableForObjectAsInt("Free Hut", "Unlocked", 0);
	ModVariable.SetVariableForObjectAsInt("Occupied Hut", "Unlocked", 0);
	ModVariable.SetVariableForObjectAsInt("Broken LogCabin", "Unlocked", 0);
	ModVariable.SetVariableForObjectAsInt("Free LogCabin", "Unlocked", 0);
	ModVariable.SetVariableForObjectAsInt("Occupied LogCabin", "Unlocked", 0);
	-- ModVariable.SetVariableForObjectAsInt("Free LogCabin", "Hidden", 1);
	-- ModVariable.SetVariableForObjectAsInt("Free Hut", "Hidden", 1);
		----TEST upgrade
	--ClayStationCrude UpgradeTo Value:143
	--ClayStation UpgradeFrom Value:142
	--ModVariable.SetVariableForObjectAsInt("Free Hut", "UpgradeTo", 676)
	--ModVariable.SetVariableForObjectAsInt("Broken Hut", "UpgradeFrom", 142)-- Free Hut
	
	-- ModVariable.SetVariableForObjectAsInt("Broken Hut", "MaxUsage", 100);
	-- ModVariable.SetVariableForObjectAsInt("Broken Hut", "RepairObject", 215);
	-- ModVariable.SetVariableForObjectAsInt("Broken Hut", "RepairAmount", 2);


------------Hut Tier Value:1    TODO: 543387156
end

function AfterLoad()

	-- After Load Function
	
	--currentTime = ModSaveData.LoadValue("currentTime") or 0
	--ModDebug.Log(ModSaveData.LoadValue("currentTime"))
	--ModDebug.Log(currentTime)
end

function ccbf(BuildingUID, EditType, NewValue)
	if NewValue and EditType then
		ModDebug.Log("Edited : ", EditType, " = ", NewValue)
	elseif EditType then
		ModDebug.Log("Edited : ", EditType)
	elseif NewValue then
		ModDebug.Log("Edited = ", NewValue)
	else
		ModDebug.Log("Edited.")
	end
end

houseEdited_enable = true
function houseEdited(BuildingUID, EditType, NewValue)
	if not houseEdited_enable then
		return
	end
	local folk
	local house = House.freeHouse:find(function(e) return e.id == BuildingUID; end)
	if not house then
		folk = Folk.folkList:find(function(e) return e.house and e.house.id == BuildingUID; end)
		house = folk.house
	end
	if not house then
		ModDebug.Log("folkList", json.stringify(Folk.folkList:getData()))
		ModDebug.Log("Callbackparams: ", BuildingUID, " ", EditType, " ", NewValue)
		error('House edited cannot be found: Sanity error.')
		return
	end
	if EditType == "Move" then -- or EditType == "Rotate" -- On move + rotate work is done twice, should not be a big deal
		local ty = ModObject.GetObjectProperties(house.id)[1]
		local x, y = NewValue:match("([^:]+):([^:]+)")
		local r = ModBuilding.GetRotation(BuildingUID)
		houseEdited_enable = false
		newHouseSpawned_enable = false
		ModObject.DestroyObject(house.modelId)
		-- MustDelete = {target=BuildingUID; UnregisterForBuildingEditedCallback=true; next=MustDelete}
		ModObject.DestroyObject(BuildingUID) -- == house.id
		-- MustMove = {target=rete, type="Hut", x=tonumber(x), y=tonumber(y); next=MustMove}
		-- MustMove = {target=BuildingUID, type="Test1", x=tonumber(x), y=tonumber(y); next=MustMove}
		house.modelId = ModBase.SpawnItem(string.gsub(string.gsub(ty, "Free", ""), "Occupied", ""), tonumber(x), tonumber(y), true, true)
		ModBuilding.SetRotation(house.modelId, r)
		house.id = ModBase.SpawnItem(ty, tonumber(x), tonumber(y), true, true)
		ModBuilding.SetRotation(house.id, r)
		ModBuilding.RegisterForBuildingEditedCallback(house.id, houseEdited)
		houseEdited_enable = true
		newHouseSpawned_enable = true
	elseif EditType == "Destroy" then
		if folk and folk.state == -1 then
			folk:moveOut() -- Deletion when folk is in house
			-- house is now free, must be deleted
			houseEdited_enable = false
			ModObject.DestroyObject(house.id)
			houseEdited_enable = true
			ModObject.DestroyObject(house.modelId)
			House.freeHouse:remove(house)
		elseif folk then -- Deletion when folk is out, not supported yet
			local modelType = ModObject.GetObjectProperties(house.modelId)[1]
			local coords = house:coordinates()
			local r = house:rotation()
			houseEdited_enable = false
			newHouseSpawned_enable = false
			house.id = ModBase.SpawnItem("Occupied "..modelType, coords[1], coords[2], true, true)
			ModBuilding.SetRotation(house.id, r)
			ModBuilding.RegisterForBuildingEditedCallback(house.id, houseEdited)
			houseEdited_enable = true
			newHouseSpawned_enable = true
			ModUI.ShowPopup("Wait!","Deleting an occupied house when folk is out is not supported yet, the deletion has be canceled.")
		else
			ModObject.DestroyObject(house.modelId)
			House.freeHouse:remove(house)
		end
	end
end

function AfterLoad_CreatedWorld()
end

-- testcoeur = nil
function AfterLoad_LoadedWorld()
	--ModDebug.Log(ModSaveData.SaveValue("folkList", json.stringify(Folk.folkList:getData())))
	House._actifList.list = nil
	Folk._actifList.list = nil
	AskingStation._actifList.list = nil
	Though._actifList.list = nil
	
	House._actifList.list = nil
	Folk.folkList = List:new() -- TODO deep free
	sv = ModSaveData.LoadValue("folkList", "{}")
	if sv == "" then sv = "{}" end
	--ModDebug.Log(sv)
	List:fromDataBuilder(json.parse(sv), Folk)
	House.freeHouse = List:new() -- TODO deep free
	sv = ModSaveData.LoadValue("freeHouseList", "{}")
	if sv == "" then sv = "{}" end
	--ModDebug.Log(sv)
	List:fromDataBuilder(json.parse(sv), House)
	SignLinks = json.parse(ModSaveData.LoadValue("signLinks", "{}"))
	QuestManager:fromData(json.parse(ModSaveData.LoadValue("questData", "{}")))
	-- c = ModPlayer.GetLocation ()
	-- rete = ModBase.SpawnItem("Hut", c[1]+1, c[2], true , true)
	-- ModBuilding.RegisterForBuildingEditedCallback(ModBase.SpawnItem("Test1", c[1]+1, c[2], true , true), brokenHouseEdited22)
	-- testcoeur = ModBase.SpawnItem("heart", ModPlayer.GetLocation()[1], ModPlayer.GetLocation()[2], true , true)
end

function WandCallback(UserUID, TileX, TileY, TargetUID, TargetType)
	ModDebug.Log(TargetType)
end

function LinkSign(UserUID, TileX, TileY, TargetUID, TargetType)
	-- uids = ModTiles.GetObjectUIDsOnTile(TileX, TileY)
	UIDs = ModTiles.GetObjectUIDsOfType("Sign", TileX, TileY, TileX, TileY)
	-- ModDebug.Log(json.stringify(UIDs))
	for k,v in pairs(UIDs) do
		if v ~= TargetUID then
			SignLinks[tostring(TargetUID)] = v
			SignLinks[tostring(v)] = TargetUID
			return
		end
	end
	UIDs = ModTiles.GetObjectUIDsOfType("Sign2", TileX, TileY, TileX, TileY)
	-- ModDebug.Log(json.stringify(UIDs))
	for k,v in pairs(UIDs) do
		if v ~= TargetUID then
			SignLinks[tostring(TargetUID)] = v
			SignLinks[tostring(v)] = TargetUID
			return
		end
	end
	UIDs = ModTiles.GetObjectUIDsOfType("Sign3", TileX, TileY, TileX, TileY)
	-- ModDebug.Log(json.stringify(UIDs))
	for k,v in pairs(UIDs) do
		if v ~= TargetUID then
			SignLinks[tostring(TargetUID)] = v
			SignLinks[tostring(v)] = TargetUID
			return
		end
	end
end

function NonPickupable(TargetType, TileX, TileY, TargetUID, UserUID)
	-- TODO: safer verification, replace at previous position
	MustDrop = {target=UserUID; next=MustDrop}
end

function registerFolk(TargetType, TileX, TileY, TargetUID, UserUID)
	-- TODO: safer verification, replace at previous position
	Folk:register(TargetUID)
end

-- function testo(TargetType, TileX, TileY, TargetUID, UserUID)
	-- ModUI.ShowPopup("Start save!","Drop.")
-- end

dodelete = false
toBedeleted = nil

--local tableWberry = 0
-- function fillTableWithFood(UserUID, TileX, TileY, TargetUID, TargetType)
	-- ModObject.DestroyObject(TargetUID)
	-- tableWberry = ModBase.SpawnItem("Table with berry", TileX, TileY, true , true)
	-- -- TODO TargetUID
	-- objectTarget = tableWberry
	-- --
	-- ModObject.SetObjectRotation(tableWberry, 0, 0, 0)
-- end
brokenHouseRepaired_enable = true
function brokenHouseRepaired(BuildingUID, EditType, Blueprint, BuildingInDragModels)
	if not brokenHouseRepaired_enable then
		return
	end
	
	local coords = ModObject.GetObjectTileCoord(BuildingUID)
	local house = List.find({l = House._actifList.list}, function(e) c2 = e:coordinates(); return c2[1] == coords[1] and c2[2] == coords[2] ; end)
	if not house then
		ModDebug.Log("brokenHouseRepaired[Additional DATA]:",coords," ",coords[1], " ",coords[2], " ", BuildingUID)
		error("brokenHouseRepaired: House couldn't be found, this error could corrupt your modData, it is recommended to save on different name and report the bug, please save the FANA_DebuLog.txt of your mod folder.")
	end
	--ModObject.SetObjectActive(house.id, true)
	house:resetDurability()
	local r = house:rotation()
	ModObject.DestroyObject(BuildingUID)
	ModObject.SetObjectActive(house.modelId, true)
	houseEdited_enable = false
	newHouseSpawned_enable = false
	house.id = ModBase.SpawnItem("Occupied "..HouseTier[house.tier], coords[1], coords[2], true , true)
	house.broken_id = nil
	ModBuilding.SetRotation(house.id, r)
	ModBuilding.RegisterForBuildingEditedCallback(house.id, houseEdited)
	houseEdited_enable = true
	newHouseSpawned_enable = true
end

newHouseSpawned_enable = true

function newHouseSpawned(BuildingUID, EditType, Blueprint, BuildingInDragModels)
	ModDebug.Log("newHouseSpawned(",newHouseSpawned_enable,"): ",BuildingUID, EditType, Blueprint, BuildingInDragModels)
	-- Add new house to free ones:
	if newHouseSpawned_enable then
		local coord = ModObject.GetObjectTileCoord(BuildingUID)
		local house = House:new(EditType == "Hut" and 2 or EditType == "LogCabin" and 3, ModBase.SpawnItem("Free "..EditType, coord[1], coord[2], true , true),BuildingUID)
		ModBuilding.SetRotation(house.id, ModBuilding.GetRotation(BuildingUID))
		ModBuilding.RegisterForBuildingEditedCallback(house.id, houseEdited)
	end
-- if not rete then
	-- c = ModObject.GetObjectTileCoord(BuildingUID)
	-- rete = BuildingUID--ModBase.SpawnItem("Hut", c[1]+1, c[2], true , true)
	-- ModDebug.Log("XXXXXX",c[1]," ",c[2])
	-- ModBuilding.RegisterForBuildingEditedCallback(ModBase.SpawnItem("Test1", c[1], c[2], true , true), brokenHouseEdited22)
-- end
	-- if houseMoving then
		-- return
	-- end
	-- coord = ModObject.GetObjectTileCoord(BuildingUID)
	-- ModDebug.Log(coord[1],coord[2])
	-- r = ModBuilding.GetRotation(BuildingUID)
	-- ModObject.DestroyObject(BuildingUID)
	-- nid = ModBase.SpawnItem("Free "..EditType, coord[1], coord[2], true , true)
	-- ModBuilding.SetRotation(nid, r)
end

already_inited = false
function Creation()
	if not already_inited then
		ModObject.AddMaterialsToCache("Heart/colors")
	--	return
	end
	already_inited = true
	-- Load Heart texture
	--for level=0,19 do
	--	ModObject.AddMaterialsToCache("Heart/heart"..level..".mtl")
	--end

	-- ModHoldable.RegisterForCustomCallback("Sign", "HoldablePickedUp", function(a,b,c,d,e,f,g) ModDebug.Log(a);ModDebug.Log(b);ModDebug.Log(c);ModDebug.Log(d);ModDebug.Log(e);ModDebug.Log(f);ModDebug.Log(g);ModDebug.Log(ModBot.GetScriptSavegameFormat(ModBot.GetAllBotUIDs()[1]));ModBot.SetScriptSavegameFormat(ModBot.GetAllBotUIDs()[1],"[{\"Type\":\"InstructionMove\",\"Line\":-1,\"OT\":\"Plot\",\"UID\":0,\"X\":109,\"Y\":77,\"V1\":\"\",\"V2\":\"\",\"A\":\"MoveTo\",\"R\":\"\",\"AT\":0,\"AOT\":\"Total\"}]"); end)
	--ModBot.SetScriptSavegameFormat(ModBot.GetAllBotUIDs()[1],"[{\"Type\":\"InstructionFindNearestObject\",\"ArgName\":\"215 72 121 78 Full\",\"Line\":-1,\"OT\":\"FolkHeart\",\"UID\":13936,\"X\":118,\"Y\":75,\"V1\":\"Total\",\"V2\":\"\",\"A\":\"Pickup\",\"R\":\"\",\"AT\":0,\"AOT\":\"Total\"}]");
	ModHoldable.RegisterForCustomCallback("Sign", "HoldableDroppedOnGround", LinkSign)
	ModHoldable.RegisterForCustomCallback("Sign2", "HoldableDroppedOnGround", LinkSign)
	ModHoldable.RegisterForCustomCallback("Sign3", "HoldableDroppedOnGround", LinkSign)
	ModDebug.Log(TU)
	math.randomseed(os.time())
	-- Creation of any new converters or buildings etc. go here

	-- House based object
	ModBuilding.CreateBuilding("Free Hut", {}, {}, "Hut/Hut", {0,0}, {0,0}, {0,1}, true) --673 --ModBuilding.UpdateModelScale("Free Hut", 60) Do not update free hut
	ModBuilding.ShowBuildingAccessPoint("Free Hut", true) 
	ModBuilding.CreateBuilding("Occupied Hut", {}, {}, "Hut/Hut", {0,0}, {0,0}, {0,1}, true) --ModBuilding.UpdateModelScale("Occupied Hut", 60) 
	ModBuilding.CreateBuilding("Broken Hut", {"Log"}, {2}, "Models/Buildings/Hut", {0,0}, {0,0}, {0,1}, false)  --675 --ModBuilding.UpdateModelScale("Broken Hut", 60) Do not update free hut
	ModBuilding.ShowBuildingAccessPoint("Occupied Hut", true)

	ModBuilding.CreateBuilding("Free LogCabin", {}, {}, "LogCabin/LogCabin", {0,0}, {1,0}, {0,1}, true)  --676
	ModBuilding.ShowBuildingAccessPoint("Free LogCabin", true)
	ModBuilding.CreateBuilding("Occupied LogCabin", {}, {}, "LogCabin/LogCabin", {0,0}, {1,0}, {0,1}, true)  --676
	ModBuilding.ShowBuildingAccessPoint("Occupied LogCabin", true)
	ModBuilding.CreateBuilding("Broken LogCabin", {}, {}, "Models/Buildings/LogCabin", {0,0}, {1,0}, {0,1}, false)
	
	
	ModBuilding.RegisterForBuildingTypeSpawnedCallback("Hut", newHouseSpawned)
	ModBuilding.RegisterForBuildingTypeSpawnedCallback("LogCabin", newHouseSpawned)
	ModBuilding.RegisterForBuildingTypeSpawnedCallback("Broken Hut", brokenHouseRepaired)
	ModBuilding.RegisterForBuildingTypeSpawnedCallback("Broken LogCabin", brokenHouseRepaired)

	
	ModDebug.Log("MOD - Create a new Berry Converter")
	--ModConverter.CreateConverter("TheBerryMaker", {"Berries"}, {"Plank", "Pole"}, {4, 3}, "ObjCrates/wooden boxes pack", {-1,-1}, {1,0}, {0,1}, {1,1})
	
	ModGoTo.CreateGoTo("Client", null, null, "Folk/Folk", true) --"Models/animals/animalalpaca", false
	ModGoTo.UpdateModelRotation("Client", 0, -180,0) 
	
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
	
	-- ModBuilding.CreateBuilding("Test1", {"Stick"}, {1}, "Empty/Empty", {0,0}, {0,0}, {0,1}, true)
	-- ModBuilding.ShowBuildingAccessPoint("Test1", true) 
	
	
	-- Food base object
	
	-- -- ModHoldable.CreateHoldable("Table needing berry", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", false)
	-- -- ModHoldable.CreateHoldable("Table with berry", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", false)
	
	-- -- ModTool.CreateTool("Berry", {"Stick"}, {1}, {"Table needing berry"}, {}, {}, {}, 2.0, "Models/Food/Berries", false, fillTableWithFood, false)
	-- -- -- ModBuilding.CreateBuilding("Free Table", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", {0,0}, {0,0}, {0,-2}, false)

	-- -- ModHoldable.RegisterForCustomCallback("Table needing berry", "HoldablePickedUp", NonPickupable)
	-- -- ModHoldable.RegisterForCustomCallback("Table with berry", "HoldablePickedUp", NonPickupable)
	--ModHoldable.RegisterForCustomCallback("Raw Meat", "HoldablePickedUp", CallbackFunction)
	--ModHoldable.RegisterForCustomCallback("Raw Meat", "HoldableDroppedOnGround", CallbackFunction)
	
	ModHoldable.CreateHoldable("Pedestal", {"Plank"}, {4}, "Box/Box", true)
	ModHoldable.UpdateModelScale("Pedestal", 60.0)
	
	ModConverter.CreateConverter("Cradle", {"Client"}, {"Plank", "Pole"}, {4, 8}, "Cradle/cradle", {0,0}, {1,0}, {0,1}, {1,1})
	ModConverter.UpdateModelScale("Cradle", 3.0)
	ModConverter.UpdateModelRotation("Cradle", 0, 90, 0)
	ModConverter.UpdateModelTranslation("Cradle", 1.5,0,0) 
	ModConverter.RegisterForCustomCallback("Cradle", "ConverterCreateItem", registerFolk)
	----ModHoldable.RegisterForCustomCallback("Stick", "AddedToConverter", startCradle)
	----ModConverter.RegisterForCustomCallback("Cradle", "ConverterComplete", endCradle)
	
	ModBuilding.CreateBuilding("Free Desk", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", {0,0}, {0,0}, {0,-2}, false)
	ModBuilding.SetBuildingWalkable("Free Desk", true)
	ModHoldable.RegisterForCustomCallback("Free Desk", "HoldablePickedUp", NonPickupable)
	
		
	ModHoldable.CreateHoldable("ThoughOfFoodDesk", {}, {}, "Thoughs/FoodDesk/though", true)
	ModHoldable.UpdateModelRotation("ThoughOfFoodDesk", 0, 0, 90)
	ModHoldable.UpdateModelTranslation("ThoughOfFoodDesk", 0,2.15,0) 
	ModHoldable.RegisterForCustomCallback("ThoughOfFoodDesk", "HoldablePickedUp", NonPickupable)
		
	ModHoldable.CreateHoldable("ThoughOfClothDesk", {}, {}, "Thoughs/ClothDesk/though", true)
	ModHoldable.UpdateModelRotation("ThoughOfClothDesk", 0, 0, 90)
	ModHoldable.UpdateModelTranslation("ThoughOfClothDesk", 0,2.15,0) 
	ModHoldable.RegisterForCustomCallback("ThoughOfClothDesk", "HoldablePickedUp", NonPickupable)
		
	ModHoldable.CreateHoldable("ThoughOfHut", {}, {}, "Hut/though", true)
	ModHoldable.UpdateModelRotation("ThoughOfHut", 0, 0, 90)
	ModHoldable.UpdateModelTranslation("ThoughOfHut", 0,2.15,0) 
	ModHoldable.RegisterForCustomCallback("ThoughOfHut", "HoldablePickedUp", NonPickupable)
		
	-- Create Tables
	ModBuilding.CreateBuilding("Free Table", {"Pole","Plank"}, {4,2}, "Table/Table", {0,0}, {0,0}, {0,1}, true)
	ModBuilding.UpdateModelScale("Free Table", 2)
	-- ModBuilding.SetBuildingWalkable("Free Table", true) not needed anymore
	ModHoldable.RegisterForCustomCallback("Free Table", "HoldablePickedUp", NonPickupable)
	ModBuilding.ShowBuildingAccessPoint("Free Table", true)
	for tier=1,2 do
		for k,v in pairs(FoodCategory) do
			--ModDebug.Log("Table needing "..v)
			-- Create object
			ModHoldable.CreateHoldable("Table needing "..v..tostring(tier), {}, {}, "Table/Table", true)
			ModHoldable.UpdateModelScale("Table needing "..v..tostring(tier), 2)
			ModHoldable.CreateHoldable("Table with "..v..tostring(tier), {}, {}, "Table/Table", true)
			ModHoldable.UpdateModelScale("Table with "..v..tostring(tier), 2)
			-- Set non pickupable
			ModHoldable.RegisterForCustomCallback("Table needing "..v..tostring(tier), "HoldablePickedUp", NonPickupable)
			ModHoldable.RegisterForCustomCallback("Table with "..v..tostring(tier), "HoldablePickedUp", NonPickupable)
			
			ModHoldable.CreateHoldable("ThoughOf"..v..tostring(tier), {}, {}, "Thoughs/"..v..tostring(tier).."/though", true)
			ModHoldable.UpdateModelRotation("ThoughOf"..v..tostring(tier), 0, 0, 90)
			ModHoldable.UpdateModelTranslation("ThoughOf"..v..tostring(tier), 0,2.15,0) 
			ModHoldable.RegisterForCustomCallback("ThoughOf"..v..tostring(tier), "HoldablePickedUp", NonPickupable)
			
			
			-- ModHoldable.RegisterForCustomCallback("Folk", "HoldableDroppedOnGround", testo)
		end
	end
	-- Create AskingStation:food
	for k,v in pairs(FoodList) do
		--ModDebug.Log("Served "..v[1] .. "   :   " .. "Table needing "..v[2])
		-- Create ServedFood
		--ModTool.CreateTool("Served "..v[1], {"LargeBowlClay", v[1]}, {1,1}, {"Table needing "..v[2]..v[3]}, {}, {}, {}, 0.0, "Models/Food/"..v[1], false, fillTableWithFood, false)
		ModTool.CreateTool("Served "..v[1], {}, {}, {"Table needing "..v[2]..v[3]}, {}, {}, {}, 0.0, "Models/Food/"..v[1], false, fillTableWithFood, false)
		-- old duration: 2.0
	end
	
	--ModBuilding.CreateBuilding("Cloth desk", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", {0,0}, {0,0}, {0,-2}, false)
	-- -- ModBuilding.CreateBuilding("Cloth desk", {"Stick"}, {1}, "Models/Buildings/storage/StorageGeneric", {-1,-1}, {1,0}, {0,-2}, false)
	-- -- ClothNameList = {}
	for k,v in pairs(ClothList) do
		-- Create object
		--ModHoldable.CreateHoldable("Desk asking "..v[1], {}, {}, "Models/Buildings/storage/StorageGeneric", false)
		--ModHoldable.CreateHoldable("Table with "..v[1], {}, {}, "Models/Buildings/storage/StorageGeneric", false)
		-- Set non pickupable
		--ModHoldable.RegisterForCustomCallback("Desk asking "..v[1], "HoldablePickedUp", NonPickupable)
		
		-- Create ServedFood
		-- -- ModHoldable.CreateHoldable(v[1].." on hanger", {v[1], "Stick"}, {1, 1}, "Models/Clothes/Tops/"..v[1], false)
		-- -- ClothNameList[#ClothNameList + 1] = v[1].." on hanger"
		
		ModGoTo.CreateGoTo("Client with "..v[1], null, null, "Clothes/"..v[1].."/Folk"..v[1], true)
		--ModGoTo.CreateGoTo("Client with "..v[1], null, null, "TopPoncho/FolkTopPoncho", true)
		ModGoTo.UpdateModelScale("Client with "..v[1], 90.0)
		ModGoTo.UpdateModelRotation("Client with "..v[1], 0, -180,0)
		ModGoTo.UpdateModelTranslation("Client with "..v[1], 0,1.15,0)
		
		ModHoldable.CreateHoldable("ThoughOf"..v[1], {}, {}, "Thoughs/"..v[1].."/though", true)
		ModHoldable.UpdateModelRotation("ThoughOf"..v[1], 0, 0, 90)
		ModHoldable.UpdateModelTranslation("ThoughOf"..v[1], 0,2.15,0) 
		ModHoldable.RegisterForCustomCallback("ThoughOf"..v[1], "HoldablePickedUp", NonPickupable)
	end
	
	ModHoldable.CreateHoldable("heart", {}, {}, "Heart/heart", true)
	ModHoldable.UpdateModelTranslation("heart", 0,4,0)
	ModHoldable.RegisterForCustomCallback("heart", "HoldablePickedUp", NonPickupable)
	
	for n=1,3 do
		ModHoldable.CreateHoldable("satisfactionHeart"..tostring(n), {}, {}, "Heart/heart"..tostring(n).."d3", true)
		ModHoldable.UpdateModelTranslation("satisfactionHeart"..tostring(n), 0,3,0)
		ModHoldable.UpdateModelScale("satisfactionHeart"..tostring(n), 0.5)
		ModHoldable.RegisterForCustomCallback("satisfactionHeart"..tostring(n), "HoldablePickedUp", NonPickupable)
	end
	
	-- -- ModConverter.CreateConverter("Cloth preparing station", ClothNameList, {"Plank", "Pole"}, {4, 3}, "ObjCrates/wooden boxes pack", {-1,-1}, {1,0}, {0,1}, {1,1})
	
	ModHoldable.UpdateModelScale("Folk", 30)
	ModHoldable.UpdateModelRotation("Folk", -90,0,0) 
	ModDebug.Log("Init Done")
end

function ClientGoToObject(ClientID, TargetType, IsBuilding)
	
	error("TODO ClientGoToObject with non building")
end

function AfterSave()
	ModDebug.Log("Start save")
	--ModDebug.Log(json.stringify(Folk.folkList:getData()))
	ModDebug.Log(ModSaveData.SaveValue("folkList", json.stringify(Folk.folkList:getData())))
	ModDebug.Log(ModSaveData.SaveValue("freeHouseList", json.stringify(House.freeHouse:getData())))
	ModDebug.Log(ModSaveData.SaveValue("signLinks", json.stringify(SignLinks)))
	ModDebug.Log(ModSaveData.SaveValue("questData", json.stringify(QuestManager:getData())))
	ModSaveData.SaveValue("lastVersion", version)
end

local StateRunning = { Normal=true, SelectWorker=true, TeachWorker=true, Edit=true, Drag=true, ObjectSelect=true, Planning=true, BuildingSelect=true, Inventory=true, DragInventorySlot=true, RenameSign=true, SelectObject=true, EditArea=true, FreeCam=true, Terraform=true}

local GameState = "Normal"
local ss = ""
local time_sum = 0

-- TempAnim = nil
-- RTempAnim = 0.0
function OnUpdate(DeltaTime)
	-- RTempAnim = RTempAnim + DeltaTime*180.0
	-- ModObject.SetObjectRotation(TempAnim, 0, RTempAnim, 0)
-- if dodelete then
-- 	ModObject.DestroyObject(toBedeleted)
-- end

-- CheatTools CreativeTools
-- "Paused", "PlatformPaused", "Save", "Load", "Confirm", "Settings", "About"
-- "PlayCameraSequence"
-- "BackupRestore"
-- "Loading"
-- "CreateWorld"
-- "Ceremony"
-- "NewGame"
-- "Error"
-- "OK"
-- "Badges"
-- "Industry"
-- "Evolution"
-- "Academy"
-- "Research"
-- "Autopedia"
-- "Stats"
-- "AnyKey"
-- "Arcade"
-- "MissionEditor"
-- "MissionList"
-- "SetTargetTile"
-- "SetSpacePort"
-- "Start"
-- "MainMenuCreate"
-- "MainMenu"
-- "LanguageSelect"
-- "ModsPanel"
-- "ModsUploadConfirm"
-- "ModsError"
-- "ModsOptions"
-- "ModsAnyKey"
-- "ModsPopup"
-- "ModsPopupConfirm"
-- "ModsPanelLocalOnly"
-- "PlaybackLoading"
-- "Playback"
-- "SceneChange"

	sn = ModBase.GetGameState()
	
	if StateRunning[sn] then
		GameState = "Running"
	elseif sn == ss or sn == "ModsPopup" then
		return -- If State paused but no change, skip update
		-- ModPopUp is also considered as pause
	elseif sn == "Paused" then
		GameState = "Paused"
	elseif sn == "Save" then
		GameState = "Save"
	elseif GameState == "Save" and sn == "OK" then
		-- -- ModDebug.Log("Start save")
		-- -- ModDebug.Log(json.stringify(Folk.folkList:getData()))
		-- -- ModDebug.Log("s3 save")
		-- -- ModDebug.Log(ModSaveData.SaveValue("folkList", json.stringify(Folk.folkList:getData())))
		-- -- ModDebug.Log("s4 save")
		---------------ModDebug.Log(ModSaveData.SaveValue("folkList", json.stringify(Folk.folkList:getData()))) TODO pareil avec les AS
		
		--ModUI.ShowPopup("Start save!","Saving.")
		
		-- data = json.parse(stringData)
	-- self:fromData(data)
	end
	
	if ss ~= sn then
		ss = sn
		ModDebug.Log(ss)
	end
	
	if GameState ~= "Running" then
		return
	end
	-- ModObject.DestroyObject(ModBase.SpawnItem("Cradle", 134, 73, false , false))

	while MustDrop ~= nil do
		if ModObject.GetObjectProperties(MustDrop.target)[1] ~= "FarmerPlayer" then
			ModBot.DropAllHeldObjects(MustDrop.target)
		else
			ModPlayer.DropAllHeldObjects()
		end
		MustDrop = MustDrop.next
	end
	

	while MustDelete ~= nil do
		-- if MustDelete.UnregisterForBuildingEditedCallback then
			-- ModBuilding.UnregisterForBuildingEditedCallback(MustDelete.target)
		-- end
		ModObject.DestroyObject(MustDelete.target)
		MustDelete = MustDelete.next
	end
	

	-- while MustMove ~= nil do
		-- ModObject.DestroyObject(MustMove.target)
		-- ModBase.SpawnItem(MustMove.type, MustMove.x, MustMove.y, true , true)
		-- MustMove = MustMove.next
	-- end

	Though:updateActifs(DeltaTime)

	time_sum = time_sum + DeltaTime
	if time_sum < 1 then
		return
	end
	time_sum = time_sum - 1

	
	if checkVersion and not ModBase.GetExposedVariable("Do not show futur patchnote") and ModSaveData.LoadValue("lastVersion", "0") ~= version then
		ModUI.ShowPopup("FANA: Patch note",getPatchDescription(ModSaveData.LoadValue("lastVersion", "0")))
		checkVersion = false
	end
	
	-- if test ~= 0 then
		-- if test2 then
			-- ModObject.SetObjectRotation(test, 0, 0, 15)
		-- else
			-- ModObject.SetObjectRotation(test, 0, 0, -15) 
		-- end
		-- test2 = not test2
	-- end
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
	AskingStation:updateActifs()
end












-- TODO check var hidden, perhaps to hide in datatech
-- TODO move hut seem bugged for iccupied one, failed to fix, to do later
-- TODO move to pedestal should lock a cell

-- TODO repair broken feature broken house
-- TODO check path finding on moveto update
-- TODO translation
-- TODO use node update to set folks happiness

-- TODO unpickable though, should use ref to replace them
-- TODO thought not well placed, especially for new one on craddle
-- TODO folk must have a timeout




-- TODO modapi allow custom quest
-- TODO modapi allow add itemto quest
-- TODO modapi allow validate quest
-- TODO modapi allow dyn add recipe
-- TODO modapi handle sign





