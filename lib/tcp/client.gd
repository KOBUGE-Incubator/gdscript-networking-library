
extends Reference

const ReadWriteLock = preload("../ReadWriteLock.gd")


var tcp_stream = StreamPeerTCP.new()
var packet_peer = PacketPeerStream.new()
var M_tcp_stream = Mutex.new()

var message_queue = []
var M_message_queue = Mutex.new()

var client_running
var M_client_running = Mutex.new()

var loop_thread = Thread.new()

func _init():
	add_user_signal("message", [{"message": TYPE_DICTIONARY}])
	
func connect_to(host, port):
	M_tcp_stream.lock()
	
	if not client_running:
		tcp_stream.connect(host, port)
		packet_peer.set_stream_peer(tcp_stream)
		client_running = true
		loop_thread.start(self, "loop")
	
	M_tcp_stream.unlock()

func send(message):
	M_message_queue.lock()
	
	message_queue.push_back(message)
	
	M_message_queue.unlock()

func stop():
	M_client_running.lock()
	
	client_running = false
	
	M_client_running.unlock()

func loop(data):
	while true:
		M_tcp_stream.lock()
		M_client_running.lock()
		if not client_running:
			M_client_running.unlock()
			
			tcp_stream.disconnect()
			M_tcp_stream.unlock()
			break;
		else:
			M_client_running.unlock()
		
		while packet_peer.get_available_packet_count():
			emit_signal("message", packet_peer.get_var())
		
		M_message_queue.lock()
		
		for message in message_queue:
			packet_peer.put_var(message)
		message_queue.clear()
		
		M_message_queue.unlock()
		
		M_tcp_stream.unlock()
		OS.delay_msec(100)


