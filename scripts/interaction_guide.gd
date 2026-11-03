extends RefCounted
## One keyboard vocabulary for every playable room. Preview scenes keep their own controls.

const ACTION_VERBS := [
	"ENTER", "RETURN", "EXIT", "OPEN", "MOVE", "PUSH", "CLIMB", "LOCK",
	"UNLOCK", "RELEASE", "TAKE", "LOAD", "RETHREAD", "OPERATE", "START",
	"STOP", "ISOLATE", "CLEAR", "TEST", "DOCK", "BOARD", "STITCH",
	"TURN ON", "COMPARE", "REST", "PACK", "HELP", "GRAB", "MARK",
]

const EXAMINATIONS := {
	&"archive-door": "The archive door leads to the machine room. The evening rounds come first.",
	&"upper-stacks-entry": "The upper shelves sit above the hall. The machine reading belongs in the log before I climb.",
	&"return-hall": "This passage leads back to the library hall.",
	&"service-road-exit": "The service passage continues toward the castle.",
	&"emergency-stop": "The red stop isolates this room's local drive. The castle has its own controls.",
	&"service-road-return-machine": "The machine room is still accessible behind me.",
	&"service-gate": "The gate latch is within reach from the safe side of the road.",
	&"castle-control-return": "The road leads back toward the library's machine room.",
	&"castle-return-console": "This control tests whether the rotating wing can return to level.",
	&"castle-lower-service-hatch": "The lower hatch joins the fixed tower to the rotating wing.",
	&"room-return-hatch": "The hatch leads back to the fixed control walkway.",
	&"room-shaft-ladder": "The maintenance ladder reaches a hatch into the fixed service structure.",
	&"room-chalk-patch": "The dry stone has room for a chalk guess. Water and the hanging weight can test it.",
	&"shaft-return-aperture": "The passage reconnects to the rotated room below.",
	&"shaft-engine-access": "The engine room is beyond the shaft's fixed platform.",
	&"shaft-speaking-tube": "The tube carries a voice between this platform and Erin's ledge.",
	&"stacks-ladder": "The ladder rolls on a track. Its wheels must be locked before climbing.",
	&"shaft-winch": "The hand winch moves the basket; its brake holds the basket when I let go.",
	&"shaft-tool-chest": "The tool chest can reach the basket through the loading tray from this safe platform.",
	&"shaft-lower-dock": "The lower catch keeps the basket still while its rope or load is changed.",
	&"shaft-long-rope": "A longer rope and a thin pilot line lead toward the spare basket pulley.",
	&"shaft-top-anchor": "The upper anchor is above Kath's reach. A maintenance pull line closes its catch.",
	&"shaft-rope-path": "The rope runs between the winch and basket. Its path can be checked from here.",
	&"engine-isolator": "This switch separates the automatic drive before anyone touches the linkage.",
	&"engine-wall-chart": "The chart separates the fixed tower, moving wing, home stop and inverted backup catch. I can compare my observations here.",
	&"engine-obstruction": "Wet grit and a metal fragment jam the normal-position rod.",
	&"engine-linkage": "The rod should trigger the stop, brake and home lock when the wing reaches level.",
	&"engine-drive": "The maintenance drive can return the wing only after the stop path has been checked.",
	&"engine-shaft-return": "The shaft lies beyond this fixed platform.",
	&"engine-observatory-exit": "The wing door leads to the observatory after the castle is level.",
	&"observatory-engine-return": "The engine room remains beyond this door.",
	&"observatory-records": "A drawer shifted during the rotation. Papers are visible inside.",
	&"observatory-worktable": "Kath's notebook is open at the page torn from the upper shelves.",
}

const NAMED_EXAMINATIONS := {
	"Stairway to Upper Stacks": "The stairs lead back into the upper stacks.",
	"Desk lamp": "The desk lamp would make the pencil marks easier to read.",
	"Old notebook": "One page is missing. The torn edge may match the leaf from the wooden case.",
	"Bed": "It is nearly morning. The castle can wait until I have checked the notebook.",
	"Travel satchel": "There is room for the notebook, pencil and torn page.",
	"Roof seam": "Water follows the roof crack to one spot on the floor. The bucket is close by.",
	"Rolling ladder": "Its wheels run along the shelves. A lock holds it in place for climbing.",
	"Wooden case": "The unregistered case sits high enough that I need the ladder.",
	"Kath's Room": "My room is through the left doorway of the stacks.",
	"Stairway to Hall": "The stairway returns to the library hall.",
	"Control Walkway": "The fixed control walkway is beyond the service road.",
	"Shaft Hatch": "The hatch connects this ladder to the fixed maintenance shaft.",
}


static func is_action_label(label: String) -> bool:
	var upper := label.to_upper()
	if upper.ends_with(" FIRST") or upper.begins_with("WAIT"):
		return false
	for verb in ACTION_VERBS:
		if upper == verb or upper.begins_with(verb + " "):
			return true
	return false


static func examination(hotspot: Node) -> String:
	if hotspot == null:
		return ""
	var item_id: StringName = hotspot.get("interaction_id")
	if EXAMINATIONS.has(item_id):
		return EXAMINATIONS[item_id]
	var name: String = hotspot.get("display_name")
	return examination_named(name)


static func examination_named(name: String) -> String:
	return NAMED_EXAMINATIONS.get(name, "%s is within reach." % name)
