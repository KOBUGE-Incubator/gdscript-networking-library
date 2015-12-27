
extends "../shared/server.gd"

var address_id_map = {}

class Connection:
	var id = -1
	var host
	var port
	
	var last_ack_received = null
	var last_ack_sent = null
	
	func _init(_id, _host, _port):
		id = _id
		host = _host
		port = _port

func _init():
	server = PacketPeerUDP.new()
	
func _start_server(port):
	server.listen(port)

func _stop_server():
	server.close()
	address_id_map = {}

func _update_connections():
	var timestamp = OS.get_ticks_msec()
	while server.get_available_packet_count():
		var host = server.get_packet_ip()
		var port = server.get_packet_port()
		var address = str(host, ":", port)
		
		if not address_id_map.has(address) or not connections.has(address_id_map[address]):
			print(address)
			var connection = Connection.new(next_id, host, port)
			
			address_id_map[address] = next_id
			connections[next_id] = connection
			
			next_id += 1
		
		var connection = connections[address_id_map[address]]
		
		var message = server.get_var()
		
		if message.has(constants.UDP_COMMAND):
			var command = message[constants.UDP_COMMAND]
			if command == "ACK":
				if connection.last_ack_received == null:
					emit_signal("connect", connection.id)
				connection.last_ack_received = timestamp
		else:
			emit_signal("message", connection.id, message)
	
	for id in connections:
		var connection = connections[id]
		if connection.last_ack_sent == null or timestamp - connection.last_ack_sent > constants.UDP_SEND_ACK:
			var ack = {}
			ack[constants.UDP_COMMAND] = "ACK"
			_send_internal(id, ack)
			
			connection.last_ack_sent = timestamp
		
		if connection.last_ack_received != null and timestamp - connection.last_ack_received > constants.UDP_TIMEOUT:
			var ack = {}
			ack[constants.UDP_COMMAND] = "ACK"
			_send_internal(id, ack)
			emit_signal("disconnect", id)
			connections.erase(id)
			

func _send_messages(messages):
	for message in messages:
		if message.target != null:
			if connections.has(message.target):
				var connection = connections[message.target]
				server.set_send_address(connection.host, connection.port)
				server.put_var(message.data)
		else:
			for id in connections:
				var connection = connections[id]
				server.set_send_address(connection.host, connection.port)
				server.put_var(message.data)
