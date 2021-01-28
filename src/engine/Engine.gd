extends Node

# Provide functionality for interactions with a Chess Engine
# Also, find the installed exe files rather than needing UI entry by user

var iopiper # Path of UDP to CLI app bridge in the bin directory
var engine # Path of installed Chess Engine in the engine directory
var server_pid = 0

signal done

func _ready():
	# Get the base path of the application files
	var cmd = "pwd"
	var ext = ""
	if OS.get_name() == "Windows":
		cmd = "cd"
		ext = ".exe"
	var output = []
	var _exit_code = OS.execute(cmd, [], true, output)
	var path = output[0].strip_edges() # Seem to get a null termination char
	# Allow for running in dev mode, so back peddle from src folder
	var src_pos = path.find("src")
	if src_pos > -1:
		path = path.substr(0, src_pos - 1)
	
	# Form paths to the executables
	# Use forward slash for all platforms
	iopiper = path + "/bin/iopiper" + ext
	engine = path + "/engine/"

	# Get the first file found in the engine folder for the Chess Engine to use
	var dir = Directory.new()
	if dir.open(engine) == OK:
		dir.list_dir_begin(true)
		engine += dir.get_next()


func start_udp_server():
	var err = ""
	# Check for existence of the exe files
	var file = File.new()
	if !file.file_exists(iopiper):
		err = "Missing iopiper at: " + iopiper
	elif !file.file_exists(engine):
		err = "Missing engine at: " + engine
	else:
		server_pid = OS.execute(iopiper, [engine], false)
		if server_pid < 400:
			err = "Unable to start UDP server with error code: " + server_pid
		else:
			$UDPClient.set_server()
	return { "started": err == "", "error": err }


func stop_udp_server():
	# Return 0 or an error code
	if server_pid < 400:
		return 0
	return OS.kill(server_pid)


func send_packet(pkt: String):
	$UDPClient.send_packet(pkt)
	$Timer.start()


func _on_Timer_timeout():
	stop_udp_server()
	emit_signal("done", false, "")


func _on_UDPClient_got_packet(pkt):
	$Timer.stop()
	emit_signal("done", true, pkt)


func _on_Engine_tree_exited():
	stop_udp_server()
