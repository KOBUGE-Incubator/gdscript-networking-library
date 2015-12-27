
extends Reference

const ReadWriteLock = preload("../ReadWriteLock.gd")
const constants = preload("constants.gd")

signal connect()
signal disconnect()
signal message(message)

var connection
var M_connection = Mutex.new()

var message_queue = []
var _internal_message_queue = []
var M_message_queue = Mutex.new()

var running
var M_running = Mutex.new()

var loop_thread = Thread.new()

func _start_connection(host, port):
	pass # Virtual

func _stop_connection():
	pass # Virtual

func _update_connection():
	pass # Virtual

func _send_messages(messages):
	pass # Virtual

func connect_to(host, port):
	M_running.lock()
	if not running:
		M_connection.lock()
		
		running = true
		_start_connection(host, port)
		loop_thread.start(self, "loop")
		
		M_connection.unlock()
	
	M_running.unlock()

func send(message):
	M_message_queue.lock()
	
	message_queue.push_back(message)
	
	M_message_queue.unlock()

func _send_internal(message):
	_internal_message_queue.push_back(message)

func stop():
	M_running.lock()
	
	running = false
	
	M_running.unlock()
	
	loop_thread.wait_to_finish()

func loop(data):
	while true:
		M_connection.lock()
		
		M_running.lock()
		if not running:
			M_running.unlock()
			
			_stop_connection()
			
			M_connection.unlock()
			break;
		else:
			M_running.unlock()
		
		_update_connection()
		
		M_message_queue.lock()
		
		var _messages = message_queue
		message_queue = []
		
		M_message_queue.unlock()
		
		_send_messages(_messages)
		
		_messages = _internal_message_queue
		_internal_message_queue = []
		_send_messages(_messages)
		
		M_connection.unlock()
		OS.delay_msec(constants.TICK_TIME)
