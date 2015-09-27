
extends Reference

var handlers = {}

func on(event_name, listner):
	if not handlers.has(event_name):
		handlers[event_name] = []
	handlers[event_name].push_back(listner)

func dispatch(event_name, param):
	if handlers.has(event_name):
		for handler in handlers[event_name]:
			handler.call_func(param)