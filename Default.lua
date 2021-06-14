HT_trackers = {
	trackers = {
	["none"] = {
	type = "Progress Tracker",
	name = "none",
	text = "none",
	textAlignment = 1,
	decimals = 1,
	font = "BOLD_FONT",
	fontSize = 30,
	fontWeight = "thick-outline",
	IDs = {},
	target = "Yourself",
	outlineThickness = 4,
	current = 0,
	max = 0,
	icon = "",
	targetNumber = 1,
	barColor = {1,1,1,1},
	timeColor = {1,1,1,1},
	textColor = {1,1,1,1},
	stacksColor = {1,1,1,1},
	backgroundColor = {0,0,0,0.4},
	outlineColor = {0,0,0,1},
	cooldownColor = {0,0,0,0.7},
	sizeX = 0,
	sizeY = 0,
	anchorToGroupMember = true,
	drawLevel = 0,
	parent = "none",
	children = {},
	xOffset = 0,
	yOffset = 0,
	timer1 = true,
	timer2 = true,
	inverse = false,
	hideIcon = false,
	conditions = {
		[1] = {
			arg1 = "Remaining Time",
			arg2 = 0,
			operator = "<",
			result = "Hide Tracker",
			resultArguments = {1,1,1,1},
		}
	},
	duration = {},
	expiresAt = {},
	stacks = {},
	events = {
		[1] = {
		type = "Get Effect Duration",
		arguments = {
			cooldown = 8,
			onlyYourCast = false,
			overwriteShorterDuration = false,
			luaCodeToExecute = "",
		},
		},
	},
	load = {
		never = false,
		inCombat = false,
		role = 2,
		class = "Dragonknight",
		skills = {},
		itemSets = {},
		zones = {},
		bosses = {},
	},
	},
	},

}