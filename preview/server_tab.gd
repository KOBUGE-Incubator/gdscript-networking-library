
extends Control

var server = preload("res://lib/udp/server.gd").new()

func _ready():
	get_node("Buttons/Send/Submit").connect("pressed", self, "send")
	get_node("Buttons/Toggle").connect("toggled", self, "toggle")
	
	get_node("Buttons/Send/Target").add_item("All connected clients", 0)
	
	get_parent().prepare_results_console(get_node("Result"))
	
	server.connect("connect", self, "client_connected")
	server.connect("message", self, "new_message")
	server.connect("disconnect", self, "client_disconnected")

func toggle(state):
	if state:
		get_node("Buttons/Toggle").set_text("Stop server")
		server.start(8760)
		add_result("Server is running!")
	else:
		get_node("Buttons/Toggle").set_text("Start server")
		add_result("Server stopped!")
		server.stop()
		
func new_message(id, msg):
	add_result(str("Received:     ", msg.to_json()))

	var response = false

	if msg.has("get") and msg.get == "inventory":
		response = {"items": ["Old boots", "Raw fish", "Lenses", "Hat", "Rusty dagger"]}
	if msg.has("action") and msg.action == "skill":
		response = {"error": "Not enough mana!"}
	if msg.has("action") and msg.action == "attack":
		response = {"ok": true}
	if msg.has("chat"):
		add_result(str("<", id, "> : ", msg.chat))
		var message = {"chat": msg.chat, "from": id}
		server.send_to_all(message)
		add_result(str("Sent message: ", message.to_json(), "\n"))

	if response != false:
		add_result(str("Sent response: ", response.to_json(), "\n"))
		server.send_to(id, response)

func send():
	var possible_messages = [
		{"dead": str("rat-", floor(rand_range(0, 42)))},
		{"move": str("rat-", floor(rand_range(0, 42))), "amount": [0, 1]},
		{"move": str("rat-", floor(rand_range(0, 42))), "amount": [0, -1]},
		{"move": str("rat-", floor(rand_range(0, 42))), "amount": [1, 0]},
		{"move": str("rat-", floor(rand_range(0, 42))), "amount": [-1, 0]},
		{"notification": str("A new level was added to the collection!"), "from": "!level_bot"}
	]
	var msg = possible_messages[rand_range(0, possible_messages.size())]
	
	var target = get_node("Buttons/Send/Target").get_selected_ID()
	if target == 0:
		server.send_to_all(msg)
	else:
		server.send_to(target-1, msg)
	
	add_result(str("Sent message: ", msg.to_json()))

func client_connected(id):
	get_node("Buttons/Send/Target").add_item(str("<",id,">"), id+1)
	add_result(str("<", id, "> Connected!"))
	
func client_disconnected(id):
	add_result(str("<", id, "> Disconnected!"))

func add_result(result):
	get_node("Result").set_text(str(get_node("Result").get_text(), "\n", result))
