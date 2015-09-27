
extends Reference

var write_lock = Mutex.new()
var read_lock = Mutex.new()
var read_count = 0

func lock_write():
	write_lock.lock()

func unlock_write():
	write_lock.unlock()

func lock_read():
	read_lock.lock()
	read_count += 1
	if read_count == 1:
		write_lock.lock()
	read_lock.unlock()

func unlock_read():
	read_lock.lock()
	read_count -= 1
	if read_count == 0:
		write_lock.unlock()
	read_lock.unlock()


