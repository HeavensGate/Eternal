/client/proc/panicbunker()
	set category = "Server"
	set name = "Toggle Panic Bunker"
	if (!config.sql_enabled)
		usr << "<span class='adminnotice'>The Database is not enabled!</span>"
		return

	config.panic_bunker = (!config.panic_bunker)

	log_admin("[key_name(usr)] has toggled the Panic Bunker, it is now [(config.panic_bunker?"on":"off")]")
	message_admins("[key_name_admin(usr)] has toggled the Panic Bunker, it is now [(config.panic_bunker?"enabled":"disabled")].")
	if (config.panic_bunker)
		config.ic_allowed = 0
		config.ooc_allowed = 0
		config.looc_allowed = 0
		config.dsay_allowed = 0
		air_processing_killed = 1
		message_admins("In character chat, OOC, LOOC, DSAY and Air Processing have been disabled. They must be enabled again manually.")
	if (config.panic_bunker && (!dbcon || !dbcon.IsConnected()))
		message_admins("The Database is not connected! Panic bunker will not work until the connection is reestablished.")
	feedback_add_details("admin_verb","PANIC") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

