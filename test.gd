
extends Control

var server
var client

var client_on = false

func _ready():
	server = load("res://server.gd").new()
	client = load("res://client.gd").new()
	
	server.connect("connect", self, "new_connection")
	server.connect("message", self, "new_message_server")
	
	client.connect("message", self, "new_message_client")
	
	randomize()

func start_server():
	server.start(8760)
	add_server_result("Turned ON!")

func start_client():
	if not client_on:
		client.connect_to("127.0.0.1", 8760)
		add_client_result("Turned ON!")
		client_on = true
	else:
		add_client_result("Already ON!")
	
func send_client():
	if client_on:
		var possible_messages = [
			{"get": "inventory"},
			{"action": "attack", "target": "rat-42"},
			{"action": "skill", "skill": "FireBall", "target": "snow_troll-3"},
			{"chat": "Hello Server!"}
		]
		var msg = possible_messages[rand_range(0, possible_messages.size())]
		client.send(msg)
		add_client_result(str("Sent message: ", msg.to_json()))
	else:
		add_client_result("Turn on first, please!")

func new_connection(id):
	add_server_result(str(id, " Connected!"))

func new_message_client(msg):
	add_client_result(str("Received: ", msg.to_json()))

func new_message_server(id, msg):
	add_server_result(str("Received: ", msg.to_json()))
	if msg.has("get") and msg.get == "inventory":
		server.send_to(id, {"items": ["Old boots", "Raw fish", "Lenses", "Hat", "Rusty dagger"]})
	if msg.has("action") and msg.action == "skill":
		server.send_to(id, {"error": "Not enough mana!"})
	if msg.has("action") and msg.action == "attack":
		server.send_to(id, {"ok": true})
	if msg.has("chat"):
		add_server_result(str("<", id, "> : ", msg.chat))


func add_server_result(r):
	get_node("Server/Result").set_text(str(get_node("Server/Result").get_text(), "\n", r))
func add_client_result(r):
	get_node("Client/Result").set_text(str(get_node("Client/Result").get_text(), "\n", r))
