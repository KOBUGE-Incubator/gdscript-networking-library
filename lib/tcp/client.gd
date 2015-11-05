
extends "../shared/client.gd"

const ReadWriteLock = preload("../ReadWriteLock.gd")

class Connection:
	var stream
	var packet_peer
	var connected = false
	static func create(stream):
		var new_self = new()
		new_self.stream = stream
		
		new_self.packet_peer = PacketPeerStream.new()
		new_self.packet_peer.set_stream_peer(stream)
		
		return new_self

func _start_connection(host, port):
	var stream = StreamPeerTCP.new()
	stream.connect(host, port)
	
	connection = Connection.create(stream)

func _stop_connection():
	emit_signal("disconnect")
	connection.stream.disconnect()
	connection = null

func _update_connection():
	var status = connection.stream.get_status()
	
	if status == StreamPeerTCP.STATUS_CONNECTED and not connection.connected:
		connection.connected = true
		emit_signal("connect")
	if status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE and connection.connected:
		connection.connected = false
		emit_signal("disconnect")
	
	while connection.packet_peer.get_available_packet_count():
		emit_signal("message", connection.packet_peer.get_var())

func _send_messages(messages):
	for message in messages:
		connection.packet_peer.put_var(message)

