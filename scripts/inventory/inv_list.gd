extends Reference
# Simple id -> count inventory with a capacity limit.

var items = {}
var capacity = 60

func count(id):
	return int(items.get(id, 0))

func has(id, n=1):
	return count(id) >= n

func total():
	var t = 0
	for k in items.keys():
		t += int(items[k])
	return t

func add(id, n=1):
	var room = capacity - total()
	if room <= 0:
		Events.emit_signal("notify", "Inventory Full", "Free up space or build a warehouse.")
		return false
	if n > room:
		n = room
	items[id] = count(id) + n
	return true

func remove(id, n=1):
	if not has(id, n):
		return false
	var left = count(id) - n
	if left <= 0:
		items.erase(id)
	else:
		items[id] = left
	return true

func keys():
	return items.keys()

func save_dict():
	return items.duplicate()

func load_dict(d):
	items = {}
	for k in d.keys():
		items[k] = int(d[k])
