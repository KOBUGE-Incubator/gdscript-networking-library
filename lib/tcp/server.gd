
extends "../shared/server.gd"

class Connection:
	var id = -1
	var stream
	var packet_peer
	var connected = false
	static func create(id, stream):
		var new_self = new()
		new_self.id = id
		new_self.stream = stream
		
		new_self.packet_peer = PacketPeerStream.new()
		new_self.packet_peer.set_stream_peer(stream)
		
		return new_self

func _init():
	server = TCP_Server.new()
	
func _start_server(port):
	server.listen(port)

func _stop_server():
	server.stop()

func _update_connections():
	while server.is_connection_available():
		var stream = server.take_connection()
		var connection = Connection.create(next_id, stream)
		
		connections[next_id] = connection
		next_id += 1
	
	for id in connections:
		var connection = connections[id]
		var status = connection.stream.get_status()
		
		if status == StreamPeerTCP.STATUS_CONNECTED and not connection.connected:
			connection.connected = true
			emit_signal("connect", connection.id)
		if status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE and connection.connected:
			connection.connected = false
			emit_signal("disconnect", connection.id)
			connections.erase(connection.id)
			
		
		while connection.packet_peer.get_available_packet_count():
			emit_signal("message", connection.id, connection.packet_peer.get_var())

func _send_messages(messages):
	for message in messages:
		if message.target != null:
			if connections.has(message.target):
				connections[message.target].packet_peer.put_var(message.data)
		else:
			for id in connections:
				connections[id].packet_peer.put_var(message.data)
