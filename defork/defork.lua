local richtext = require "richtext.richtext"

-- saved data, used mainly for brainless showing next dialogs using, after setOption()
local dialog_data = nil
local curr_node = nil

local M = {}

M.debug = true	-- Flag for debugging, true by default. If set to true, all info and warnings will be shown, otherwise only errors.

-------------------------------------------  [ TWINE DECODING FUNCTIONS ] -----------------------------------------------

function M.load(resource)
	local data = sys.load_resource(resource)
	dialog_data = json.decode(data)
	if dialog_data then
		if M.debug then print("Defork:","Info: Succesfully loaded data") end
	else
		print("Defork:","Error: Could not load data")
	end
	return dialog_data
end

function M.getName(conversation)
	return (conversation and conversation.name)
	or (dialog_data and dialog_data.name) or nil
end

function M.getStartNodeID(conversation)
	return (conversation and conversation.startnode)
	or (dialog_data and dialog_data.startnode) or nil
end

function M.getCurrentNodeID()
	return curr_node or nil
end

local function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	local i = 1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

function M.setCurrentNode(nodeID)
	if nodeID then 
		curr_node = nodeID
	else 
		return nil
	end
end

function M.getText(nodeID, conversation)
	if nodeID or curr_node then
		local id = nodeID or curr_node

		-- Twine concatenate the options to the text, so Defork is excluding a text only
		local whole_text = (conversation and conversation.passages[tonumber(id)]) 
		or (dialog_data and dialog_data.passages[tonumber(id)].text) or nil
		local delimiter = "[["
		local text = split(whole_text, delimiter)

		-- When there is more delimeters then expected, display a warning
		local links = (conversation and conversation.passages[tonumber(id)].links)
		or (dialog_data and dialog_data.passages[tonumber(id)].links) or nil

		if links then
			if #links ~= (#text - 1) then
				if M.debug then print("Defork:","Warning: There is an additional string '[[' in a conversation text. This string is reserved by Twine") end
				return nil
			end
		end

		return text[1] or nil
	end
	print("Defork:","Error: NodeID not specified and no current node ID saved") 
	return nil
end

function M.getTags(nodeID, conversation)
	local id = nodeID or curr_node
	if id then
		return (conversation and conversation.passages[tonumber(id)].tags)
		or (dialog_data and dialog_data.passages[tonumber(id)].tags) or nil
	end
	print("Defork:","Error: NodeID not specified and no current node ID saved") 
	return nil
end

function M.getOptions(nodeID, conversation)
	if nodeID or curr_node then
		local id = nodeID or curr_node
		return (conversation and conversation.passagess[tonumber(id)].links) 
		or (dialog_data and dialog_data.passages[tonumber(id)].links) or nil
	end
	print("Defork:","Error: NodeID not specified and no current node ID saved") 
	return nil
end

function M.getOptionLink(no, nodeID, conversation)
	if no and (nodeID or curr_node) then
		local id = nodeID or curr_node
		return (conversation and conversation.passagess[tonumber(id)].links[no].pid) 
		or (dialog_data and dialog_data.passages[tonumber(id)].links[no].pid) or nil
	end
	print("Defork:","Error: None of the option selected, NodeID not specified and no current node ID saved") 
	return nil
end

function M.getOptionText(no, nodeID, conversation)
	if no and (nodeID or curr_node) then
		local id = nodeID or curr_node
		return (conversation and conversation.passagess[tonumber(id)].links[no].name) 
		or (dialog_data and dialog_data.passages[tonumber(id)].links[no].name) or nil
	end
	print("Defork:","Error: None of the option selected, NodeID not specified and no current node ID saved") 
	return nil
end


-------------------------------------------  [ RICHTEXT FUNCTIONS ] -----------------------------------------------


local default_settings = {		-- some default settings for richtext (have no parent gui node!)
fonts = {
	system = {
		regular = hash("system_font"),
	},
	Roboto = {
		regular = hash("Roboto-Regular"),
		italic = hash("Roboto-Italic"),
		bold = hash("Roboto-Bold"),
		bold_italic = hash("Roboto-BoldItalic"),
	},
},
layers = {
	fonts = {
		[hash("Roboto-Regular")] = hash("roboto-regular"),
		[hash("Roboto-Italic")] = hash("roboto-italic"),
		[hash("Roboto-Bold")] = hash("roboto-bold"),
		[hash("Roboto-BoldItalic")] = hash("roboto-bold_italic"),
		[hash("Nanum-Regular")] = hash("nanum-regular"),
	},
	images = {
		[hash("images")] = hash("images-smileys"),
	}
},
width = 400,
position = vmath.vector3(20, -20, 0),
color = vmath.vector4(1),
align = richtext.ALIGN_LEFT,
line_spacing = 1.5
}

local function check_tags(string)	-- default tags checking (could be replaced by default functions)

local authors = richtext.tagged(string, "author")		-- tag <author>  (enlarged)
for _,author in pairs(authors) do
	local scale = gui.get_scale(author.node)
	scale.x = scale.x * 1.3
	scale.y = scale.y * 1.3
	gui.set_scale(author.node, scale)
end

local shined = richtext.tagged(string, "shine")			-- tag <shine>  (changing color)
for _,shine in pairs(shined) do 
	local chars = richtext.characters(shine)
	gui.delete_node(shine.node)
	for i,char in ipairs(chars) do
		gui.animate(char.node, "color.x", 0.9, gui.EASING_INOUTSINE, 1, i * 0.12, nil, gui.PLAYBACK_LOOP_PINGPONG)
		gui.animate(char.node, "color.y", 0.5, gui.EASING_INOUTSINE, 1, i * 0.12, nil, gui.PLAYBACK_LOOP_PINGPONG)
		gui.animate(char.node, "color.z", 0.5, gui.EASING_INOUTSINE, 1, i * 0.12, nil, gui.PLAYBACK_LOOP_PINGPONG)
	end
end

local shouted = richtext.tagged(string, "shout")		-- tag <shout>  (shrinking and expanding constantly)
for _,shout in pairs(shouted) do 
	local chars = richtext.characters(shout)
	gui.delete_node(shout.node)
	for i,char in ipairs(chars) do
		local pos = gui.get_position(char.node)
		pos.y = pos.y + 5
		pos.x = (pos.x - 5) + 2*i
		local frequency = tonumber(shout.tags.shout) or 2
		gui.animate(char.node, "scale", 1.4, gui.EASING_INOUTSINE, frequency, 0.12, nil, gui.PLAYBACK_LOOP_PINGPONG)
		gui.animate(char.node, "position.y", pos.y, gui.EASING_INOUTSINE, frequency, 0.12, nil, gui.PLAYBACK_LOOP_PINGPONG)
		gui.animate(char.node, "position.x", pos.x, gui.EASING_INOUTSINE, frequency, 0.12, nil, gui.PLAYBACK_LOOP_PINGPONG)
	end
end

end

function M.setRichtextSettings(new_settings) 
	if new_settings.parent then 	default_settings.parent		= new_settings.parent end
	if new_settings.fonts then 		default_settings.fonts		= new_settings.font end
	if new_settings.layers then		default_settings.layers		= new_settings.layers end
	if new_settings.width then		default_settings.width		= new_settings.width end
	if new_settings.position then	default_settings.position 	= new_settings.position end
	if new_settings.color then		default_settings.color		= new_settings.color end
	if new_settings.align then		default_settings.layers 	= new_settings.align end
	if new_settings.line_spacing then	default_settings.layers 	= new_settings.line_spacing end
	if new_settings.image_pixel_grid_snap then default_settings.image_pixel_grid_snap = new_settings.image_pixel_grid_snap end
end

function M.setRichtextParent(guiNodeID)
	if guiNodeID then
		default_settings.parent = guiNodeID
	end
	if M.debug then print("Defork:","Warning: No parent overwritten!") end
	return false
end

local saved_font = nil

function M.setRichtextFont(font)
	if font then
		saved_font = font
	end
	if M.debug then print("Defork:","Warning: No font overwritten!") end
	return false
end

function M.createOnePanelText(text, options, speaker, speaker_color, speaker_image)
	local text = text or ""
	local speaker = speaker or nil
	local image = speaker_image or nil
	local color = speaker_color or "yellow"	-- yellow by default, to differ speaker name and speech
	local options = options or nil

	if speaker then
		text = "<author><color="..color..">"..speaker..":</color></author><br/>"..text		-- add speaker's name
	end

	if image then 		-- add speaker's image
		text =  image.."  "..text
	end

	if options then
		for i,v in ipairs(options) do
			text = text.."\n\n<color=lightblue>\t <a=option_"..i..">"..v.name.."</a></color>"
		end
	end

	return text
end

function M.showRichtext(text, guiNodeID, font, custom_check_tags_function)
	M.setRichtextParent(guiNodeID)			-- overwrite parent node setting
	if not default_settings.parent then		-- if there is still no parent set - abort
		print("Defork:","Error: Failed to show a Richtext - No parent attached!")
		return nil
	end
	M.setRichtextFont(font)
	if not saved_font then
		print("Defork:","Error: Failed to show a Richtext - No gui font selected!")
		return nil
	end

	local words, metrics = richtext.create(text, saved_font, default_settings)
	if custom_check_tags_function then 
		if M.debug then print("Defork:","Info: Using custom function for checking Richtext tags") end
		custom_check_tags_function(words) 
	else
		if M.debug then print("Defork:","Info: Using default function for checking Richtext tags") end
		check_tags(words)
	end

	-- adjust background to cover text
	gui.set_size(default_settings.parent, vmath.vector3(default_settings.width+30, metrics.height+50, 0))
	return words
end

function M.refreshGUI(gui_node_id_to_refresh)
	local next_node = gui.clone(gui_node_id_to_refresh)
	gui.delete_node(gui_node_id_to_refresh)
	default_settings.parent = next_node
	return next_node
end

function M.on_input(richtextWords, action)		-- used to acquire inputs on RichText hyperlinks tagged <a>
	if action.pressed then
		local what = richtext.on_click(richtextWords, action)		-- then send message to parent
	end
end

return M