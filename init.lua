-- Custom Skins mod (based on https://github.com/MrRar/edit_skin)

local S = minetest.get_translator("customskins")

customskins = {
	item_names = {"base", "face", "legs", "bodyA", "bodyB", "hair", "shoes", "misc"}, -- Rendering order
	tab_names = {"template", "base", "face", "hair", "bodyA", "bodyB", "legs", "shoes", "misc"},
	tab_descriptions = {
		template = S("Template"),
		base = S("Skin"),
		shoes = S("Shoes"),
		face = S("Face"),
		legs = S("Legs"),
		bodyA = S("Body 1"),
		bodyB = S("Body 2"),
		hair = S("Hair"),
		misc = S("Miscellaneous")
	},
	sam = {}, -- Stores skin values for sam skin
	base = {}, -- List of skin textures
	shoes = {},
	face = {},
	legs = {},
	bodyA = {},
	bodyB = {},
	hair = {},
	misc = {},
	preview_rotations = {},
	players = {}
}

function customskins.register_item(item)
	assert(customskins[item.type], "Skin item type " .. item.type .. " does not exist.")
	local texture = item.texture or "blank.png"
	if item.sam then
		customskins.sam[item.type] = texture
	end

	table.insert(customskins[item.type], texture)
	if item.preview_rotation then
		customskins.preview_rotations[texture] = item.preview_rotation
	end
end

function customskins.save(player)
	if not player:is_player() then return end
	local skin = customskins.players[player]
	if not skin then return end
	player:get_meta():set_string("customskins:skin", minetest.serialize(skin))
end

--[[
minetest.register_chatcommand("skin", {
	description = S("Open skin configuration screen."),
	privs = {},
	func = function(name) customskins.show_formspec(minetest.get_player_by_name(name)) end
})
]]--

function customskins.compile_skin(skin)
	local output = ""
	for _, item in pairs(customskins.item_names) do
		local texture = skin[item]
		if texture and texture ~= "blank.png" then
			if #output > 0 then output = output .. "^" end
			output = output .. texture
		end
	end
	return output
end

function customskins.update_player_skin(player)
	local output = customskins.compile_skin(customskins.players[player])

	player_api.set_texture(player, 1, output)

	-- Set player first person hand node
	local base = customskins.players[player].base
	local node_id = base:gsub(".png$", "")
	player:get_inventory():set_stack("hand", 1, "customskins:" .. node_id)

	local name = player:get_player_name()

	if armor.textures and armor.textures[name] then
		armor.textures[name].skin = output
		armor.update_player_visuals(armor, player)
	end
end

-- Load player skin on join
minetest.register_on_joinplayer(function(player)
	local skin = player:get_meta():get_string("customskins:skin")
	if skin then
		skin = minetest.deserialize(skin)
	end
	if skin then
		customskins.players[player] = skin
	else
		skin = table.copy(customskins.sam)
		customskins.players[player] = skin
		customskins.save(player)
	end

	player:get_inventory():set_size("hand", 1)
	customskins.update_player_skin(player)
end)

minetest.register_on_leaveplayer(function(player)
	player:get_inventory():set_size("hand", 0)
	customskins.players[player] = nil
end)

function customskins.show_formspec(player, active_tab, page_num)
	active_tab = active_tab or "template"
	page_num = page_num or 1

	local page_count
	if page_num < 1 then page_num = 1 end
	if customskins[active_tab] then
		page_count = math.ceil(#customskins[active_tab] / 16)
		if page_num > page_count then
			page_num = page_count
		end
	else
		page_num = 1
		page_count = 1
	end

	local skin = customskins.players[player]
	local formspec = "formspec_version[3]size[13.2,11]"

	for i, tab in pairs(customskins.tab_names) do
		if tab == active_tab then
			formspec = formspec ..
				"style[" .. tab .. ";bgcolor=green]"
		end

		local y = 0.3 + (i - 1) * 0.8
		formspec = formspec ..
			"button[0.3," .. y .. ";3,0.8;" .. tab .. ";" .. customskins.tab_descriptions[tab] .. "]"
	end

	local mesh = player:get_properties().mesh
	if mesh then
		local textures = player_api.get_textures(player)
		textures[2] = "blank.png" -- Clear out the armor
		formspec = formspec ..
			"model[10,0.3;3,7;player_mesh;" .. mesh .. ";" ..
			table.concat(textures, ",") ..
			";0,180;false;true;0,0]"
	end

	if active_tab == "template" and mesh then
		formspec = formspec ..
			"model[4,2;2,3;player_mesh;" .. mesh .. ";" ..
			customskins.compile_skin(customskins.sam) ..
			",blank.png,blank.png;0,180;false;true;0,0]" ..

			"button[4,5.2;2,0.8;sam;" .. S("Select") .. "]"

	elseif customskins[active_tab] then
		formspec = formspec ..
			"style_type[button,image_button;border=false;bgcolor=#00000000]"
		local textures = customskins[active_tab]
		local page_start = (page_num - 1) * 16 + 1
		local page_end = math.min(page_start + 16 - 1, #textures)

		for j = page_start, page_end do
			local i = j - page_start + 1
			local texture = textures[j]
			local preview = "customskins_mask.png" .. "^[colorize:gray^" .. skin.base
			preview = preview .. "^" .. texture

			local objmesh = "customskins_head.obj"
			if active_tab == "bodyA" or active_tab == "bodyB" then
				objmesh = "customskins_top.obj"
			elseif active_tab == "legs" or active_tab == "shoes" then
				objmesh = "customskins_bottom.obj"
			end

			local rot_x = -10
			local rot_y = 20
			if customskins.preview_rotations[texture] then
				rot_x = customskins.preview_rotations[texture].x
				rot_y = customskins.preview_rotations[texture].y
			end

			i = i - 1
			local x = 3.5 + i % 4 * 1.6
			local y = 0.3 + math.floor(i / 4) * 1.6
			formspec = formspec ..
				"model[" .. x .. "," .. y ..
				";1.5,1.5;" .. objmesh .. ";" .. objmesh .. ";" ..
				preview ..
				";" .. rot_x .. "," .. rot_y .. ";false;false;0,0]"

			if skin[active_tab] == texture then
				formspec = formspec ..
					"image_button[" .. x .. "," .. y ..
					";1.5,1.5;customskins_select_overlay.png;" .. texture .. ";]"
			else
				formspec = formspec .. "button[" .. x .. "," .. y .. ";1.5,1.5;" .. texture .. ";]"
			end
		end
	end

	if page_num > 1 then
		formspec = formspec ..
			"image_button[3.5,6.7;1,1;customskins_arrow.png^[transformFX;previous_page;]"
	end

	if page_num < page_count then
		formspec = formspec ..
			"image_button[8.8,6.7;1,1;customskins_arrow.png;next_page;]"
	end

	if page_count > 1 then
		formspec = formspec ..
			"label[6.3,7.2;" .. page_num .. " / " .. page_count .. "]"
	end

	minetest.show_formspec(player:get_player_name(), "customskins:" .. active_tab .. "_" .. page_num, formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not formname:find("^customskins:") then return false end
	local _, _, active_tab, page_num = formname:find("^customskins:(%a+)_(%d+)")
	if not page_num or not active_tab then return true end

	local active_tab_found = false
	for _, tab in pairs(customskins.tab_names) do
		if tab == active_tab then active_tab_found = true end
	end
	active_tab = active_tab_found and active_tab or "template"

	page_num = math.floor(tonumber(page_num) or 1)

	-- Cancel formspec resend after scrollbar move
	if customskins.players[player].form_send_job then
		customskins.players[player].form_send_job:cancel()
	end

	if fields.quit then
		customskins.save(player)
		return true
	end

	if fields.sam then
		customskins.players[player] = table.copy(customskins.sam)
		customskins.update_player_skin(player)
		customskins.show_formspec(player, active_tab, page_num)
		return true
	end

	for _, tab in pairs(customskins.tab_names) do
		if fields[tab] then
			customskins.show_formspec(player, tab, page_num)
			return true
		end
	end

	local skin = customskins.players[player]
	if not skin then return true end

	if fields.next_page then
		page_num = page_num + 1
		customskins.show_formspec(player, active_tab, page_num)
		return true
	elseif fields.previous_page then
		page_num = page_num - 1
		customskins.show_formspec(player, active_tab, page_num)
		return true
	end

	local field
	for f, value in pairs(fields) do
		if value == "" then
			field = f
			break
		end
	end

	-- See if field is a texture
	if field and customskins[active_tab] then
		for _, texture in pairs(customskins[active_tab]) do
			if texture == field then
				skin[active_tab] = texture
				customskins.update_player_skin(player)
				customskins.show_formspec(player, active_tab, page_num)
				return true
			end
		end
	end

	return true
end)

local function init()
	customskins.modpath = minetest.get_modpath("customskins")

	local f = io.open(customskins.modpath .. "/list.json")
	assert(f, "Can't open the file list.json")
	local data = f:read("*all")
	assert(data, "Can't read data from list.json")
	local json, error = minetest.parse_json(data)
	assert(json, error)
	f:close()

	for _, item in pairs(json) do
		customskins.register_item(item)
	end

	if armor.get_player_skin then
		armor.get_player_skin = function(armor, name)
			return customskins.compile_skin(customskins.players[minetest.get_player_by_name(name)])
		end
	end

	for _, base in pairs(customskins.base) do
		local id = base:gsub(".png$", "")
		minetest.register_node("customskins:" .. id, {
			drawtype = "mesh",
			groups = {not_in_creative_inventory = 1},
			tiles = {base},
			use_texture_alpha = "clip",
			mesh = "customskins_hand.b3d",
			visual_scale = 1,
			wield_scale = {x = 1,y = 1,z = 1},
			paramtype = "light",
		})
	end

	if minetest.global_exists("unified_inventory") then
		unified_inventory.register_button("customskins", {
			type = "image",
			image = "customskins_skin_button.png",
			tooltip = ("Custom Skin"),
			action = function(player)
				customskins.show_formspec(player)
			end,
		})
	end
end

init()
