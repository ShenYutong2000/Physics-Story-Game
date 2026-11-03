extends RefCounted
## One source for the journal objective and optional, progressively clearer hints.
## The current step is derived from saved story evidence; no parallel quest state is saved.

const FOCUS_SCENES := {
	"Library Hall": "res://scenes/library_hall.tscn",
	"Machine Room": "res://scenes/machine_room.tscn",
	"Upper Stacks": "res://scenes/upper_stacks.tscn",
	"Kath's Room": "res://scenes/kath_room.tscn",
	"Service Road": "res://scenes/service_road.tscn",
	"Control Walkway": "res://scenes/castle_control_walkway.tscn",
	"Inverted Room": "res://scenes/chapter1_inverted_room.tscn",
	"Maintenance Shaft": "res://scenes/chapter1_maintenance_shaft.tscn",
	"Engine Room": "res://scenes/chapter1_engine_room.tscn",
	"Observatory": "res://scenes/chapter1_observatory.tscn",
}


static func current(state: Node) -> Dictionary:
	var f: Dictionary = state.flags
	if not state.hall_checks_complete():
		return _step("hall", "Complete the evening rounds", "Library Hall", "Library Hall", "Look for the three items named in Kath's rounds.", "The archive door, old clock and maintenance sheet are all in the hall.", "Stand beside each item and press E to inspect it.", [&"archive-door", &"clock-housing", &"maintenance-sheet"], 1040.0, 510.0)
	if not f.get("machine_baseline_recorded", false):
		return _step("baseline", "Record the machine reading", "Machine Room", "Machine Room", "The instrument has a mark from the last reading.", "Enter through the hall's archive door and find the large gauge.", "Press E at the gauge, compare its pointer with the old mark, then press Enter to record it.", [&"archive-door"], 1136.0, 420.0)
	if not f.get("stacks_bucket_moved", false):
		return _step("leak", "Contain the roof leak", "Upper Stacks", "Upper Stacks", "Listen for the drops above the hall.", "Go to the upper stacks and inspect the split roof seam.", "After examining the leak, stand beneath it and press F to move the bucket.", [&"machine-reading"], 1410.0, 420.0)
	if not f.get("stacks_page_collected", false):
		return _step("page", "Reach the unregistered case", "Upper Stacks", "Upper Stacks", "Wick noticed something above the shelves.", "Move the rolling ladder beneath the wooden case and lock its wheels.", "Press F to push and lock the ladder; climb with Up, then press F by the case and Enter to keep the page.", [&"leak-observation"], 1012.0, 365.0)
	if not f.get("room_lamp_on", false):
		return _step("lamp", "Light Kath's desk", "Kath's Room", "Kath's Room", "The torn page may belong with Kath's old notes.", "Enter Kath's room from the upper stacks and find the desk lamp.", "Press F at the desk lamp before comparing the page.", [&"newton-note"], 1281.0, 460.0)
	if not f.get("room_notebook_compared", false):
		return _step("compare_page", "Compare the torn page", "Kath's Room", "Kath's Room", "Look for a missing leaf in the everyday notebook.", "The old notebook is on the desk beside the lamp.", "Press F at the notebook, compare the torn edges, then press Enter to confirm.", [&"newton-note"], 1028.0, 475.0)
	if not f.get("room_rested", false):
		return _step("rest", "Rest until morning", "Kath's Room", "Kath's Room", "Kath has found the page's place in her notebook.", "The bed is the next stop before travelling at dawn.", "Press F at the bed to rest.", [&"notebook-match"], 560.0, 540.0)
	if not f.get("room_bag_packed", false):
		return _step("pack", "Pack the notebook", "Kath's Room", "Kath's Room", "Kath wants to take her observations to the castle.", "The travel satchel is within reach in her room.", "Press F at the satchel, then leave through the upper stacks.", [&"notebook-match"], 646.0, 570.0)
	if not f.get("machine_incident_active", false):
		return _step("return_hall", "Return to the hall", "Upper Stacks", "Library Hall", "Kath is ready to leave for the castle.", "Return through the upper stacks to the library hall.", "Use F at the room door, then F at the hall stairway.", [&"notebook-match"], 500.0, 530.0)
	if not f.get("incident_valve_two_open", false) or not f.get("incident_valve_four_open", false):
		return _step("valves", "Follow the emergency plate", "Machine Room", "Machine Room", "The needle has crossed the red line.", "Read the emergency controls beside the gauge in the machine room.", "Use F at the console; select levers 2 and 4 with Left/Right and operate each with F.", [&"machine-reading"], 1060.0, 430.0)
	if not f.get("incident_drive_stopped", false):
		return _step("stop", "Stop the local drive", "Machine Room", "Machine Room", "The pointer rose again after both levers moved.", "Find the red emergency stop on the machine-room control wall.", "Press F at the emergency stop; the castle's own controls are separate.", [&"machine-reading"], 1338.0, 470.0)
	if not f.get("incident_tilt_observed", false):
		return _step("tilt", "Watch the castle wing", "Machine Room", "Machine Room", "The local drive is stopped, but the remote signal is still abnormal.", "Look through the machine-room view toward the castle.", "Let the remote observation finish before leaving the room.", [&"machine-reading"], 1320.0, 470.0)
	if not f.get("service_gate_open", false):
		return _step("road_gate", "Open the castle service gate", "Service Road", "Service Road", "The castle wing is tilted, not yet upside down.", "Follow the machine-room service passage to the road gate.", "Inspect the road sign and hanging cable if you wish, then press F at the gate.", [&"castle-alarm"], 1322.0, 550.0)
	if not f.get("service_road_end_reached", false):
		return _step("road_end", "Reach the castle", "Service Road", "Control Walkway", "The open gate leads toward a fixed tower beside the turning wing.", "Walk to the far right end of the service road.", "At the Chapter I card, press Enter to enter the castle walkway.", [&"castle-alarm"], 1510.0, 560.0)
	if not f.get("control_dial_checked", false) or not f.get("control_erin_briefed", false):
		return _step("control_checks", "Compare the dial with Erin's report", "Control Walkway", "Control Walkway", "The wing is tilted while the central tower remains upright.", "Inspect the position dial and speak with Erin on the fixed walkway.", "Press E at the dial and at Erin; both observations are needed before testing the return.", [&"castle-alarm", &"castle-position-baseline", &"castle-basket-sketch"], 438.0, 465.0)
	if not f.get("control_inversion_complete", false):
		return _step("return_test", "Test the return control", "Control Walkway", "Control Walkway", "The dial and visible wing should agree before the test.", "Find the return console beside the support ring.", "Press F at the return console and observe where the moving wing stops.", [&"castle-position-baseline", &"castle-basket-sketch"], 568.0, 480.0)
	if not f.get("room_water_observed", false) or not f.get("room_plumb_observed", false):
		return _step("find_down", "Find the real downward direction", "Inverted Room", "Inverted Room", "The room turned, but loose things still fall. You may mark a chalk guess first.", "Inspect both the falling water and the hanging weight in the inverted room.", "Use F at the chalk mark for an optional prediction, then E on the water and weight to test it.", [&"castle-on-site-inversion", &"castle-water-path", &"castle-plumb-weight"], 900.0, 460.0)
	if not f.get("castle_down_confirmed", false):
		return _step("compare_down", "Compare the two observations", "Inverted Room", "Inverted Room", "Do the drops and chain point toward the same surface?", "Use the old ceiling and old floor as reference points.", "Press Enter through Kath's comparison to record the safe lower ledge.", [&"castle-water-path", &"castle-plumb-weight"], 870.0, 510.0)
	if not f.get("room_ladder_checked", false):
		return _step("ladder_check", "Inspect the maintenance ladder", "Inverted Room", "Inverted Room", "The safe ledge continues toward a ladder.", "Check the ladder's anchors at the far end of the turned room.", "Press E at the ladder to inspect it, then F to climb.", [&"castle-down-confirmed"], 1460.0, 480.0)
	if not f.get("shaft_erin_contacted", false):
		return _step("contact_erin", "Contact Erin", "Maintenance Shaft", "Maintenance Shaft", "A voice can carry across the fixed shaft.", "Find the speaking tube on the safe lower platform.", "Press E at the tube to ask Erin what blocks her landing.", [&"castle-shaft-access"], 770.0, 420.0)
	if not f.get("shaft_rig_inspected", false):
		return _step("inspect_rig", "Examine the basket route", "Maintenance Shaft", "Maintenance Shaft", "The basket hangs between your platform and Erin's ledge.", "Inspect the rope path and hand winch before loading anything.", "Use E on the rope and winch to identify the first rope arrangement.", [&"shaft-erin-rail"], 610.0, 480.0)
	if not f.get("shaft_tools_loaded", false):
		return _step("load_tools", "Load the tools safely", "Maintenance Shaft", "Maintenance Shaft", "Kath cannot step beyond the platform edge.", "Find the tool chest and loading tray on the lower platform.", "Press F at the tool chest to place tools into the basket.", [&"shaft-erin-rail", &"shaft-direct-rope"], 570.0, 620.0)
	if not f.get("shaft_tool_trip_complete", false):
		return _step("send_tools", "Lift the tools to Erin", "Maintenance Shaft", "Maintenance Shaft", "The hand winch controls the empty basket's height.", "Operate the winch from the lower platform, then stop the basket at Erin's ledge.", "F at winch; Up to top; release and F to pass tools; Down to return; close and F at winch to confirm.", [&"shaft-direct-rope"], 450.0, 620.0)
	if not f.get("shaft_passenger_rig_inspected", false):
		return _step("spare_wheel", "Inspect the passenger rope path", "Maintenance Shaft", "Maintenance Shaft", "The first rope route has not carried a person.", "Look at the covered spare wheel on the basket and the pilot line.", "Press E at the basket rig to inspect the spare wheel.", [&"shaft-tool-trip"], 610.0, 520.0)
	if not f.get("shaft_top_anchor_inspected", false):
		return _step("top_anchor", "Check the top anchor", "Maintenance Shaft", "Maintenance Shaft", "A second support needs a secure point above the basket.", "Look toward the top anchor and its maintenance pull line.", "Press E at the top anchor; Erin can confirm the latch from her ledge.", [&"shaft-spare-pulley"], 540.0, 430.0)
	if not f.get("shaft_lower_dock_locked", false) and not f.get("shaft_passenger_rethread_complete", false):
		return _step("lock_empty", "Secure the empty basket", "Maintenance Shaft", "Maintenance Shaft", "The old rope should be unloaded before rethreading.", "Use the lower dock catch beside the platform.", "Press F at the lower dock to lock the empty basket.", [&"shaft-tool-trip"], 700.0, 620.0)
	if not f.get("shaft_long_rope_taken", false):
		return _step("take_rope", "Take the longer rope", "Maintenance Shaft", "Maintenance Shaft", "The spare basket wheel needs a longer working line.", "Open the accessible rope cabinet on the lower platform.", "Press F at the long-rope cabinet to take the rope.", [&"shaft-spare-pulley", &"shaft-top-anchor"], 310.0, 600.0)
	if not f.get("shaft_passenger_rethread_complete", false):
		return _step("rethread", "Reconnect the rope for a passenger", "Maintenance Shaft", "Maintenance Shaft", "The basket is locked and the longer rope is available.", "The pilot line can carry the new rope through the spare wheel.", "Press F at the rig inspection point and follow the rope path to the top anchor.", [&"shaft-spare-pulley", &"shaft-top-anchor", &"shaft-long-rope"], 610.0, 520.0)
	if not f.get("shaft_empty_test_complete", false):
		return _step("empty_test", "Test the new rope with an empty basket", "Maintenance Shaft", "Maintenance Shaft", "A short empty lift can reveal whether the new rope stays seated.", "Release the lower dock, then operate the winch and observe the rope marks.", "Lift until the test mark, release Up to prove the brake holds, then lower the basket to its berth.", [&"shaft-passenger-rope"], 450.0, 620.0)
	if not f.get("shaft_upper_dock_locked", false) and not f.get("shaft_erin_aboard", false):
		return _step("raise_empty", "Bring the empty basket to Erin", "Maintenance Shaft", "Maintenance Shaft", "The tested basket is ready for a full empty lift.", "Release the lower dock and wind to Erin's upper ledge.", "Hold Up at the winch until level, release to stop, then press F at the speaking tube to dock.", [&"shaft-empty-passenger-test"], 450.0, 620.0)
	if not f.get("shaft_erin_aboard", false):
		return _step("board_erin", "Help Erin board", "Maintenance Shaft", "Maintenance Shaft", "The upper catch must support the basket while Erin enters.", "Speak through the tube once the basket is docked.", "Press F at the speaking tube to invite Erin aboard.", [&"shaft-empty-passenger-test"], 805.0, 420.0)
	if not f.get("shaft_load_tensioned", false):
		return _step("tension", "Take up the occupied load", "Maintenance Shaft", "Maintenance Shaft", "Erin boarding changes the pull shown by the rope indicator.", "The upper catch still protects the basket; use the winch to take up slack.", "Hold Up at the winch until the indicator settles, then release to check the brake. This dial does not measure mass directly.", [&"shaft-empty-passenger-test"], 450.0, 620.0)
	if not f.get("shaft_load_verified", false):
		return _step("check_load", "Check the occupied basket", "Maintenance Shaft", "Maintenance Shaft", "A still basket still needs support.", "Inspect the rope runs, top anchor, load indicator and brake.", "Press F at the winch; use Left/Right and F for four checks, then Enter to confirm.", [&"shaft-empty-passenger-test"], 450.0, 620.0)
	if not f.get("shaft_lower_arrived", false):
		return _step("lower_erin", "Lower Erin with room to brake", "Maintenance Shaft", "Maintenance Shaft", "The basket gains speed when rope is paid out.", "Release the upper catch through the speaking tube, then control the winch.", "Hold Down to descend; release early to slow and use Space for stronger braking.", [&"shaft-occupied-load"], 450.0, 620.0)
	if not f.get("shaft_lower_dock_locked", false):
		return _step("lower_dock", "Secure the basket at the lower berth", "Maintenance Shaft", "Maintenance Shaft", "Erin has reached the lower level but is still inside the basket.", "The lower dock catch is beside Kath's platform.", "Press F at the lower dock to lock the basket before Erin crosses.", [&"shaft-occupied-load"], 700.0, 620.0)
	if not f.get("shaft_rescue_complete", false):
		return _step("help_erin", "Bring Erin onto the platform", "Maintenance Shaft", "Maintenance Shaft", "A loading bridge joins the docked basket to Kath's platform.", "Check that the lower catch is engaged.", "Press F at the lower dock to help Erin across.", [&"shaft-occupied-load"], 700.0, 620.0)
	if not f.get("engine_fault_traced", false):
		return _step("trace_fault", "Trace the missed home stop", "Engine Room", "Engine Room", "A moving part may have failed to signal the home position.", "Inspect the wall chart, track, linkage, brake and signal, then return to the chart.", "After all five observations, press F at the chart. Compare the causal order, then choose the safe repair order: isolate, clear, dry-run test, return.", [&"shaft-rescue", &"engine-orientation-chart", &"engine-jammed-track"], 805.0, 470.0)
	if not f.get("engine_drive_isolated", false):
		return _step("isolate_drive", "Isolate the automatic drive", "Engine Room", "Engine Room", "The mechanism should be still before the obstruction is removed.", "Find the drive isolator beside the home linkage.", "Press F at the isolator and confirm the drive is separated.", [&"engine-fault-chain"], 585.0, 500.0)
	if not f.get("engine_jam_cleared", false):
		return _step("clear_track", "Clear the blocked linkage", "Engine Room", "Engine Room", "The wet grit and fragment prevent the rod from travelling.", "Return to the jammed track after isolating the drive.", "Press F at the jam to remove the obstruction with Erin's help.", [&"engine-fault-chain"], 805.0, 515.0)
	if not f.get("engine_checks_verified", false):
		return _step("dry_run", "Test the home stop path", "Engine Room", "Engine Room", "A clear rod does not yet prove that the whole stop path works.", "Use the linkage for an isolated dry run of signal, brake and lock.", "Press F at the linkage; select each check with Left/Right, press F, then Enter.", [&"engine-track-cleared"], 945.0, 480.0)
	if state.castle_pose != &"restored":
		return _step("restore_wing", "Return the wing slowly", "Engine Room", "Engine Room", "The stop path passed its dry run while the wing was still inverted.", "Use the local maintenance drive and watch the return progress.", "Press F at the maintenance drive, hold Left to return, and release to brake.", [&"engine-home-stop-test"], 1275.0, 470.0)
	if not f.get("observatory_archive_complete", false):
		return _step("archive", "Read the observatory records", "Observatory", "Observatory", "The restored wing has opened the observatory route.", "Open the shaken drawer and read all three surviving papers.", "Press F to open the archive drawer, use Left/Right to change pages, and Enter to keep each observation.", [&"engine-wing-restored", &"observatory-work-record", &"observatory-floating-slip", &"observatory-withdrawn"], 460.0, 500.0)
	if not f.get("observatory_page_stitched", false):
		return _step("stitch_page", "Return the loose page to the notebook", "Observatory", "Observatory", "The page and Kath's notebook can now be compared with the castle record.", "Find the worktable in the observatory.", "Press F at the notebook, then Enter to stitch the page in place.", [&"observatory-work-record", &"observatory-floating-slip", &"observatory-withdrawn"], 1320.0, 500.0)
	if not f.get("chapter1_complete", false):
		return _step("talk_erin", "Share the archive finding with Erin", "Engine Room", "Engine Room", "The castle record names both Kath and Erin.", "Return to Erin in the engine room.", "Press E to talk with Erin and finish this chapter.", [&"observatory-grand-archive-link", &"observatory-page-stitched"], 495.0, 520.0)
	return _step("complete", "Continue the investigation", "Castle", "Castle", "The castle is restored, but its records leave new questions.", "Review the observations in Kath's notebook.", "The next trail points toward the Floating Isles.", [&"chapter1-departure"])


static func discovered_clues(state: Node, objective: Dictionary) -> PackedStringArray:
	var results := PackedStringArray()
	for clue_id in objective.get("clue_ids", []):
		for note in state.notes:
			if note["id"] == clue_id:
				results.append(String(note["title"]))
				break
	return results


static func _step(id: String, title: String, area: String, next_area: String, first: String, second: String, third: String, clue_ids: Array = [], focus_x: float = -1.0, focus_y: float = -1.0) -> Dictionary:
	return {"id": id, "title": title, "area": area, "next_area": next_area, "hints": [first, second, third], "clue_ids": clue_ids, "focus_scene": FOCUS_SCENES.get(area, ""), "focus_position": Vector2(focus_x, focus_y)}
