
extends Control

var client = preload("res://lib/tcp/client.gd").new()

func _ready():
	get_node("Buttons/Send").connect("pressed", self, "send")
	get_node("Buttons/Toggle").connect("toggled", self, "toggle")
	
	get_parent().prepare_results_console(get_node("Result"))
	
	client.connect("connect", self, "client_connected")
	client.connect("message", self, "new_message")
	client.connect("disconnect", self, "client_disconnected")

func toggle(state):
	if state:
		get_node("Buttons/Toggle").set_text("Stop client")
		client.connect_to("127.0.0.1", 8760)
		add_result("Client is running!")
	else:
		get_node("Buttons/Toggle").set_text("Start client")
		add_result("Client stopped!")
		client.stop()
		
func new_message(msg):
	add_result(str("Received:     ", msg.to_json()))
	
	if msg.has("chat"):
		add_result(str("<", msg.from, "> : ", msg.chat))

func send():
	var possible_messages = [
		{"get": "inventory"},
		{"action": "attack", "target": "rat-42"},
		{"action": "skill", "skill": "FireBall", "target": "snow_troll-3"},
		{"chat": "Hello Server!"}
	]
	var msg = possible_messages[rand_range(0, possible_messages.size())]
	client.send(msg)
	add_result(str("Sent message: ", msg.to_json()))

func client_connected():
	add_result("Connected!")
	
func client_disconnected():
	add_result("Disconnected!")

func add_result(result):
	get_node("Result").set_text(str(get_node("Result").get_text(), "\n", result))
