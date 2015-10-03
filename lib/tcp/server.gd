
extends Reference

const ReadWriteLock = preload("../ReadWriteLock.gd")

var tcp_server
var server_running
var global_message_queue = []
var M_tcp_server = Mutex.new()

var connections = []
var RW_connections = ReadWriteLock.new()

var loop_thread = Thread.new()

func _init():
	tcp_server = TCP_Server.new()
	
	add_user_signal("start")
	add_user_signal("connect", [{"id": TYPE_INT}])
	add_user_signal("message", [{"id": TYPE_INT}, {"message": TYPE_DICTIONARY}])
	
func start(port):
	M_tcp_server.lock()
	if not server_running:
		tcp_server.listen(port)
		server_running = true
		loop_thread.start(self, "loop")
	
	M_tcp_server.unlock()

func loop(data):
	while true:
		M_tcp_server.lock()
		if not server_running:
			tcp_server.stop()
			break;
		
		while tcp_server.is_connection_available():
			var connection = tcp_server.take_connection()
			var packet_peer = PacketPeerStream.new()
			
			packet_peer.set_stream_peer(connection)
			connections.push_back({
				id = connections.size(),
				connection = connection,
				packet_peer = packet_peer,
				message_queue = []
			})
			emit_signal("connect", connections.size() - 1)
		
		for connection in connections:
			while(connection.packet_peer.get_available_packet_count()):
				emit_signal("message", connection.id, connection.packet_peer.get_var())
			
			for message in connection.message_queue:
				connection.packet_peer.put_var(message)
			
			for message in global_message_queue:
				connection.packet_peer.put_var(message)
				
			connection.message_queue.clear()
		
		global_message_queue.clear()
		
		M_tcp_server.unlock()
		OS.delay_msec(100)

func stop(port):
	M_tcp_server.lock()
	
	server_running = false
	
	M_tcp_server.unlock()

func send_to(id, message):
	M_tcp_server.lock()
	
	connections[id].message_queue.push_back(message)
	
	M_tcp_server.unlock()

func send_to_all(message):
	M_tcp_server.lock()
	
	global_message_queue.push_back(message)
	
	M_tcp_server.unlock()


