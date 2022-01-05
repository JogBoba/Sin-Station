/client
	var/datum/player_playtime/playtime_menu

/client/proc/cmd_player_playtimes()
	set category = "Admin"
	set name = "Player Playtimes"

	if(!check_rights(R_ADMIN))
		return

	if(!CONFIG_GET(flag/use_exp_tracking))
		to_chat(usr, "<span class='warning'>Tracking is disabled in the server configuration file.</span>")
		return

	if(!playtime_menu)
		playtime_menu = new()
	playtime_menu.ui_interact(usr)

/datum/player_playtime/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PlayerPlaytimes", "Player Playtimes")
		ui.open()

/datum/player_playtime/ui_state(mob/user)
	return GLOB.admin_state

/datum/player_playtime/ui_data(mob/user)
	var/list/data = list()

	var/list/clients = list()
	for(var/client/C in GLOB.clients)
		var/list/client = list()

		client["ckey"] = C.ckey
		client["playtime"] = C.get_exp_living(TRUE)
		client["playtime_hours"] = C.get_exp_living()

		var/name = C.ckey
		var/mob/M = C.mob
		if (istype(M))
			if (isobserver(M))
				client["observer"] = TRUE

			if(M.real_name)
				name += (" (" + M.real_name + ")")
		client["name"] = name

		clients += list(client)

	clients = sortList(clients, /proc/cmp_playtime)
	data["clients"] = clients
	return data

/datum/player_playtime/ui_act(action, params)
	if(..())
		return

	switch(action)
		if ("observe")
			if(!isobserver(usr) && !check_rights(R_ADMIN))
				return

			var/atom/movable/target = get_mob_by_key(params["ckey"])
			if(!target)
				to_chat(usr, "<span class='notice'>This player cannot be observed.</span>")
				return

			var/client/C = usr.client
			if(!isobserver(usr) && !C.admin_ghost())
				return
			var/mob/dead/observer/A = C.mob
			A.ManualFollow(target)
