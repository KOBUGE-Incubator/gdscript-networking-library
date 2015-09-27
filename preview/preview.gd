
extends Control

var server = preload("res://lib/tcp/server.gd").new()
var client = preload("res://lib/tcp/client.gd").new()

var client_on = false

export var symbol_color = Color(255,255,255)
export var outgoing_color = Color(255,0,255)
export var incoming_color = Color(0,255,255)


func _ready():
	for screen in get_children():
		var console = screen.get_node("Result")
		if console and console extends TextEdit:
			console.set_text(str("----", screen.get_name(), " log----"))
			console.set_readonly(true)
			console.set_wrap(true)
			console.set_max_chars(20)
			console.set_syntax_coloring(true)
			console.set_symbol_color(symbol_color)
			console.add_keyword_color("Sent", outgoing_color)
			console.add_keyword_color("message", outgoing_color)
			console.add_keyword_color("response", outgoing_color)
			console.add_keyword_color("Received", incoming_color)

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
	add_client_result(str("Received:     ", msg.to_json(), "\n"))

func new_message_server(id, msg):
	add_server_result(str("Received:     ", msg.to_json()))

	var response = false

	if msg.has("get") and msg.get == "inventory":
		response = {"items": ["Old boots", "Raw fish", "Lenses", "Hat", "Rusty dagger"]}
	if msg.has("action") and msg.action == "skill":
		response = {"error": "Not enough mana!"}
	if msg.has("action") and msg.action == "attack":
		response = {"ok": true}
	if msg.has("chat"):
		add_server_result(str("<", id, "> : ", msg.chat, "\n"))

	if response != false:
		add_server_result(str("Sent response: ", response.to_json(), "\n"))
		server.send_to(id, response)


func add_server_result(r):
	get_node("Server/Result").set_text(str(get_node("Server/Result").get_text(), "\n", r))
func add_client_result(r):
	get_node("Client/Result").set_text(str(get_node("Client/Result").get_text(), "\n", r))
