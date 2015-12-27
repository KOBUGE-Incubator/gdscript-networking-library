
extends "../shared/client.gd"

const ReadWriteLock = preload("../ReadWriteLock.gd")

class Connection:
	var packet_peer
	
	var last_ack_sent = null
	var last_ack_received = null
	
	static func create(packet_peer):
		var new_self = new()
		
		new_self.packet_peer = packet_peer
		
		return new_self

func _start_connection(host, port):
	var packet_peer = PacketPeerUDP.new()
	packet_peer.set_send_address(host, port)
	#_send_internal()
	
	connection = Connection.create(packet_peer)

func _stop_connection():
	emit_signal("disconnect")
	connection.packet_peer.close()
	connection = null

func _update_connection():
	var timestamp = OS.get_ticks_msec()
#	var status = connection.stream.get_status()
#	
#	if status == StreamPeerTCP.STATUS_CONNECTED and not connection.connected:
#		connection.connected = true
#		emit_signal("connect")
#	if status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE and connection.connected:
#		connection.connected = false
#		emit_signal("disconnect")
	
	while connection.packet_peer.get_available_packet_count():
		var message = connection.packet_peer.get_var()
		if message.has(constants.UDP_COMMAND):
			var command = message[constants.UDP_COMMAND]
			if command == "ACK":
				if connection.last_ack_received == null:
					emit_signal("connect")
				connection.last_ack_received = timestamp
		else:
			emit_signal("message", message)
	
	if connection.last_ack_sent == null or timestamp - connection.last_ack_sent > constants.UDP_SEND_ACK:
		var ack = {}
		ack[constants.UDP_COMMAND] = "ACK"
		_send_internal(ack)
		
		connection.last_ack_sent = timestamp
	
	if connection.last_ack_recetived != null and timestamp - connection.last_ack_recetived > constants.UDP_TIMEOUT:
		emit_signal("disconnect")

func _send_messages(messages):
	for message in messages:
		connection.packet_peer.put_var(message)

