
extends Control

var tab_count = 0
const characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

export var symbol_color = Color(255,255,255)
export var outgoing_color = Color(255,0,255)
export var incoming_color = Color(0,255,255)


func _ready():
	var add_menu = get_node("../Add").get_popup()
	add_menu.add_item("Add server", 0)
	add_menu.add_item("Add client", 1)
	add_menu.connect("item_pressed", self, "add_tab")
	
	add_tab(0)
	add_tab(1)
	
	randomize()
func add_tab(type):
	var new_tab
	if type == 0:
		new_tab = preload("./server_tab.xscn")
	elif type == 1:
		new_tab = preload("./client_tab.xscn")
	new_tab = new_tab.instance()
	new_tab.set_name(str(new_tab.get_name(), " ", characters[tab_count]))
	tab_count += 1
	add_child(new_tab)

func prepare_results_console(console):
	console.set_text(str("----", console.get_parent().get_name(), " log----"))
	console.set_readonly(true)
	console.set_wrap(true)
	console.set_max_chars(20)
	console.set_syntax_coloring(true)
	console.set_symbol_color(symbol_color)
	console.add_keyword_color("Sent", outgoing_color)
	console.add_keyword_color("message", outgoing_color)
	console.add_keyword_color("response", outgoing_color)
	console.add_keyword_color("Received", incoming_color)