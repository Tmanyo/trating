rating = {
	value = {},
	description = {},
	time = {}
}

local f = io.open(minetest.get_worldpath() .. "/server_rating.db", "r")
if f == nil then
	local f = io.open(minetest.get_worldpath() .. "/server_rating.db", "w")
	f:write(minetest.serialize(rating))
	f:close()
end

function save_rating()
	local f = io.open(minetest.get_worldpath() .. "/server_rating.db", "w")
	f:write(minetest.serialize(rating))
	f:close()
end

function read_rating()
	local f = io.open(minetest.get_worldpath() .. "/server_rating.db", "r")
	local rating = minetest.deserialize(f:read("*a"))
	f:close()
	return rating
end

rating = read_rating()

minetest.register_chatcommand("rate", {
	param = "<value> <description>",
	description = "Rate current server.",
	func = function(name, param)
		if not param then
			minetest.chat_send_player(name, "[T-Rate] Invalid usage, /rate <value> <description>")
		elseif not param:match("%d") then
			print("cow")
			minetest.chat_send_player(name, "[T-Rate] You must enter a number value between 0 and 5.")
		elseif not param:match("%w+") then
			minetest.chat_send_player(name, "[T-Rate] Please enter a description.")
		elseif tonumber(param:match("%d")) > 5 then
			minetest.chat_send_player(name, "[T-Rate] You must enter a number value between 0 and 5.")
		elseif not tonumber(param:match("%d")) then
			minetest.chat_send_player(name, "[T-Rate] Please format the number value as, ex: 5 or 4.5")
		else
			if param:match("%d%.+") then
				rating.value[name] = tonumber(param:match("%d.%d"))
			else
				rating.value[name] = tonumber(param:match("%d"))
			end
			local desc_done = {}
			local desc = param:sub(param:find(" ") + 1, param:len())
			if desc:match(",") then
				desc = desc:gsub(",", " ")
			end
			if desc:len() > 71 then
				local find_if_space = desc:sub(70, 72)
				if find_if_space:find(" ") == 2 then
					desc_done = desc:sub(1, 70) .. "," .. desc:sub(71, desc:len())
				else
					desc_done = desc:sub(1, 70) .. "-," .. desc:sub(71, desc:len())
				end
			else
				desc_done = desc
			end
			rating.description[name] = desc_done
			rating.time[name] = os.time()
			save_rating()
			minetest.chat_send_player(name, "[T-Rate] Thank you for your feedback!")
		end
	end
})

function overall_rating()
	local ratings = 0
	local total = 0
	local overall = {}
	for k,v in pairs(rating.value) do
		ratings = ratings + v
		total = total + 1
	end
	overall = ratings / total
	if total == 1 then
		return ratings
	else
		return tonumber(string.match(tostring(overall), "%d.%d%d"))
	end
end

function get_bar()
	return tonumber(overall_rating()) * 0.6
end

function color()
	local color = {}
	if overall_rating() <= 1.6 then
		color = "red"
	elseif overall_rating() <= 3.1 then
		color = "yellow"
	else
		color = "green"
	end
	return color
end

function get_reviews()
	local reviews = {}
	for k,v in pairs(rating.value) do
		reviews[k] = "Player: " .. k .. " - Rating: " .. v
	end
	for k,v in pairs(rating.time) do
		reviews[k] = reviews[k] .. " - " .. os.date("%x at %X", rating.time[k]) .. ",-- "
	end
	for k,v in pairs(rating.description) do
		reviews[k] = reviews[k] .. v .. ",,"
	end
	local refined_reviews = minetest.serialize(reviews):gsub("return", ""):gsub("{", ""):gsub("}", ""):
	gsub("%[", ""):gsub("%]", ""):gsub("\"", ""):gsub("=", ""):match("Player:.+"):gsub("\\", ""):
	gsub(", %w+ ", ",")
	return refined_reviews
end

minetest.register_chatcommand("rating", {
	description = "Open server rating form.",
	func = function(name, param)
		if overall_rating() == nil then
			minetest.chat_send_player(name, "[T-Rate] There are no reviews yet!")
		else
			minetest.show_formspec(name, "trating:server_rating",
				"size[6,7]" ..
				"label[2.3,0;Overall Rating:\n   ---------------]" ..
				"label[2.7,1;" .. overall_rating() .. "]" ..
				"label[1.5,1.5;|]" ..
				"label[4.5,1.5;|]" ..
				"box[1.5,1.5;" .. get_bar() .. ",.5;" .. color() .. "]" ..
				"label[2.3,2.5;Player Reviews:]" ..
				"textlist[.5,3;5.5,3.5;reviews;" .. get_reviews() .. ";;true]")
		end
	end
})

