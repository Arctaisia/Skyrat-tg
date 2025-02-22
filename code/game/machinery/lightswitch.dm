/// The light switch. Can have multiple per area.
/obj/machinery/light_switch
	name = "light switch"
	icon = 'icons/obj/power.dmi' //ICON OVERRIDEN IN SKYRAT AESTHETICS - SEE MODULE
	icon_state = "light1"
	base_icon_state = "light"
	desc = "Make dark."
	power_channel = AREA_USAGE_LIGHT
	use_power = NO_POWER_USE
	/// Set this to a string, path, or area instance to control that area
	/// instead of the switch's location.
	var/area/area = null

/obj/machinery/light_switch/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/usb_port, list(
		/obj/item/circuit_component/light_switch,
	))

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light_switch, 26)

/obj/machinery/light_switch/Initialize(mapload)
	. = ..()
	if(istext(area))
		area = text2path(area)
	if(ispath(area))
		area = GLOB.areas_by_type[area]
	if(!area)
		area = get_area(src)

	if(!name)
		name = "light switch ([area.name])"

	update_appearance()

/obj/machinery/light_switch/update_appearance(updates=ALL)
	. = ..()
	luminosity = (machine_stat & NOPOWER) ? 0 : 1

/obj/machinery/light_switch/update_icon_state()
	if(machine_stat & NOPOWER)
		icon_state = "[base_icon_state]-p"
		return ..()
	icon_state = "[base_icon_state][area.lightswitch ? 1 : 0]"
	return ..()

/obj/machinery/light_switch/update_overlays()
	. = ..()
	if(!(machine_stat & NOPOWER))
		. += emissive_appearance(icon, "[base_icon_state]-glow", alpha = src.alpha)

/obj/machinery/light_switch/examine(mob/user)
	. = ..()
	. += "It is [area.lightswitch ? "on" : "off"]."

/obj/machinery/light_switch/interact(mob/user)
	. = ..()
	set_lights(!area.lightswitch)

/obj/machinery/light_switch/proc/set_lights(status)
	if(area.lightswitch == status)
		return
	area.lightswitch = status
	area.update_appearance()

	for(var/obj/machinery/light_switch/light_switch in area)
		light_switch.update_appearance()
		SEND_SIGNAL(light_switch, COMSIG_LIGHT_SWITCH_SET, status)

	area.power_change()

/obj/machinery/light_switch/power_change()
	SHOULD_CALL_PARENT(FALSE)
	if(area == get_area(src))
		return ..()

/obj/machinery/light_switch/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(!(machine_stat & (BROKEN|NOPOWER)))
		power_change()

/obj/item/circuit_component/light_switch
	display_name = "Light Switch"
	desc = "Allows to control the lights of an area."
	circuit_flags = CIRCUIT_FLAG_INPUT_SIGNAL

	///If the lights should be turned on or off when the trigger is triggered.
	var/datum/port/input/on_setting
	///Whether the lights are turned on
	var/datum/port/output/is_on

	var/obj/machinery/light_switch/attached_switch

/obj/item/circuit_component/light_switch/populate_ports()
	on_setting = add_input_port("On", PORT_TYPE_NUMBER)
	is_on = add_output_port("Is On", PORT_TYPE_NUMBER)

/obj/item/circuit_component/light_switch/register_usb_parent(atom/movable/parent)
	. = ..()
	if(istype(parent, /obj/machinery/light_switch))
		attached_switch = parent
		RegisterSignal(parent, COMSIG_LIGHT_SWITCH_SET, .proc/on_light_switch_set)

/obj/item/circuit_component/light_switch/unregister_usb_parent(atom/movable/parent)
	attached_switch = null
	UnregisterSignal(parent, COMSIG_LIGHT_SWITCH_SET)
	return ..()

/obj/item/circuit_component/light_switch/proc/on_light_switch_set(datum/source, status)
	SIGNAL_HANDLER
	is_on.set_output(status)

/obj/item/circuit_component/light_switch/input_received(datum/port/input/port)
	attached_switch?.set_lights(on_setting.value ? TRUE : FALSE)
