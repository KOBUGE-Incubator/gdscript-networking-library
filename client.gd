
extends Reference

const ReadWriteLock = preload("ReadWriteLock.gd")


var tcp_stream = StreamPeerTCP.new()
var packet_peer = PacketPeerStream.new()
var client_running
var message_queue = []
var M_tcp_stream = Mutex.new()

var loop_thread = Thread.new()

func _init():
	add_user_signal("start")
	add_user_signal("message", [{"message": TYPE_DICTIONARY}])
	
func connect_to(host, port):
	M_tcp_stream.lock()
	
	if not client_running:
		tcp_stream.connect(host, port)
		packet_peer.set_stream_peer(tcp_stream)
		client_running = true
		loop_thread.start(self, "loop")
	
	M_tcp_stream.unlock()

func loop(data):
	while true:
		M_tcp_stream.lock()
		if not client_running:
			tcp_stream.disconnect()
			break;
		
		while packet_peer.get_available_packet_count():
			emit_signal("message", packet_peer.get_var())
		
		for message in message_queue:
			packet_peer.put_var(message)
		message_queue.clear()
		
		M_tcp_stream.unlock()
		OS.delay_msec(100)

func send(message):
	M_tcp_stream.lock()
	
	message_queue.push_back(message)
	
	M_tcp_stream.unlock()

func stop(port):
	M_tcp_stream.lock()
	
	client_running = false
	
	M_tcp_stream.unlock()


