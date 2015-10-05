
extends Reference

const ReadWriteLock = preload("../ReadWriteLock.gd")

class RawMessage:
	var target = null
	var data = {}

var tcp_server
var server_running
var M_server_running = Mutex.new()
var M_tcp_server = Mutex.new()

var connections = []
var RW_connections = ReadWriteLock.new()

var message_queue = []
var M_message_queue = Mutex.new()

var loop_thread = Thread.new()

func _init():
	tcp_server = TCP_Server.new()
	
	add_user_signal("connect", [{"id": TYPE_INT}])
	add_user_signal("message", [{"id": TYPE_INT}, {"message": TYPE_DICTIONARY}])
	
func start(port):
	M_tcp_server.lock()
	if not server_running:
		tcp_server.listen(port)
		server_running = true
		loop_thread.start(self, "loop")
	
	M_tcp_server.unlock()

func stop():
	M_server_running.lock()
	
	server_running = false
	
	M_server_running.unlock()

func send_to(id, data):
	var message = RawMessage.new()
	message.target = id
	message.data = data
	
	M_message_queue.lock()
	
	message_queue.push_back(message)
	
	M_message_queue.unlock()

func send_to_all(data):
	var message = RawMessage.new()
	message.data = data
	
	M_message_queue.lock()
	
	message_queue.push_back(message)
	
	M_message_queue.unlock()

func loop(data):
	while true:
		M_tcp_server.lock()
		
		M_server_running.lock()
		if not server_running:
			M_server_running.unlock()
			
			tcp_server.stop()
			M_tcp_server.unlock()
			break;
		else:
			M_server_running.unlock()
		
		while tcp_server.is_connection_available():
			var connection = tcp_server.take_connection()
			var packet_peer = PacketPeerStream.new()
			
			RW_connections.lock_write()
			
			packet_peer.set_stream_peer(connection)
			connections.push_back({
				id = connections.size(),
				connection = connection,
				packet_peer = packet_peer
			})
			emit_signal("connect", connections.size() - 1)
			
			RW_connections.unlock_write()
		
		RW_connections.lock_read()
		
		for connection in connections:
			while(connection.packet_peer.get_available_packet_count()):
				emit_signal("message", connection.id, connection.packet_peer.get_var())
			
		M_message_queue.lock()
		
		for message in message_queue:
			if message.target != null:
				connections[message.target].packet_peer.put_var(message.data)
			else:
				for connection in connections:
					connection.packet_peer.put_var(message.data)
		
		message_queue.clear()
		
		M_message_queue.unlock()
		
		RW_connections.unlock_read()
		
		M_tcp_server.unlock()
		OS.delay_msec(100)


