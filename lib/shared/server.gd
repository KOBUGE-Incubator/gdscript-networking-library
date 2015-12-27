
extends Reference

const ReadWriteLock = preload("../ReadWriteLock.gd")
const constants = preload("constants.gd")

class RawMessage:
	var target = null
	var data = {}

signal connect(id)
signal disconnect(id)
signal message(id, message)

var server
var M_server = Mutex.new()

var running = false
var M_running = Mutex.new()

var connections = {}
var next_id = 0
var RW_connections = ReadWriteLock.new()

var message_queue = []
var _internal_message_queue = []
var M_message_queue = Mutex.new()

var loop_thread = Thread.new()

func _start_server(port):
	pass # Virtual

func _stop_server():
	pass # Virtual

func _update_connections():
	pass # Virtual

func _send_messages(messages):
	pass # Virtual

func start(port):
	M_running.lock()
	if not running:
		M_server.lock()
		
		running = true
		_start_server(port)
		loop_thread.start(self, "loop")
		
		M_server.unlock()
	
	M_running.unlock()

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

func _send_internal(id, data):
	var message = RawMessage.new()
	message.target = id
	message.data = data
	
	_internal_message_queue.push_back(message)

func stop():
	M_running.lock()
	
	running = false
	
	M_running.unlock()
	
	loop_thread.wait_to_finish()

func loop(data):
	while true:
		M_server.lock()
		
		M_running.lock()
		if not running:
			M_running.unlock()
			
			_stop_server()
			
			M_server.unlock()
			break;
		else:
			M_running.unlock()
		
		RW_connections.lock_write()
		
		_update_connections()
		
		RW_connections.unlock_write()
		
		RW_connections.lock_read()
		M_message_queue.lock()
		
		var _messages = message_queue
		message_queue = []
		
		M_message_queue.unlock()
		
		_send_messages(_messages)
		
		_messages = _internal_message_queue
		_internal_message_queue = []
		_send_messages(_messages)
		
		RW_connections.unlock_read()
		
		M_server.unlock()
		OS.delay_msec(constants.TICK_TIME)
