extends Control

const TABS := ["Студия", "Команда", "Консоли", "Игры"]
const GENRES := {
	"Экшен": [30, 40, 30], "РПГ": [45, 20, 35], "Симулятор": [30, 50, 20],
	"Стратегия": [45, 40, 15], "Приключения": [40, 15, 45], "Гонки": [15, 45, 40],
	"Хоррор": [35, 25, 40], "Головоломки": [55, 35, 10]}
const PLATS := [
	{"n": "PC", "y": 1990, "c": 0, "mk": 1.0},
	{"n": "Mega Box", "y": 1990, "c": 8000, "mk": 1.3},
	{"n": "Pocket Boy", "y": 1992, "c": 6000, "mk": 1.1},
	{"n": "Play Cube", "y": 1996, "c": 20000, "mk": 2.0},
	{"n": "Next Box", "y": 2002, "c": 40000, "mk": 3.0},
	{"n": "Hyper Station", "y": 2008, "c": 70000, "mk": 4.5},
	{"n": "Hybrid Pad", "y": 2017, "c": 100000, "mk": 6.0}]
const MK := [0, 5000, 20000]
const NAMES := ["Алекс", "Мария", "Игорь", "Соня", "Влад", "Кира", "Тимур", "Лена", "Даня", "Ева"]

var money := 60000
var week := 0
var fame := 0
var emps: Array = []
var lic: Array = ["PC"]
var proj = null
var sales: Array = []
var hist: Array = []
var awards: Array = []
var cand: Array = []
var sel := {"g": 0, "p": "PC", "f": [34.0, 33.0, 33.0], "m": 0, "name": ""}
var tab := 0
var running := false
var tick_t := 0.0
var log_lines: Array = []
var status: Label
var box: VBoxContainer
var logl: Label
var prog: Label

func year() -> int:
	return 1990 + week / 52

func plat(n):
	for p in PLATS:
		if p.n == n:
			return p
	return PLATS[0]

func say(t: String) -> void:
	log_lines.append(t)
	if log_lines.size() > 5:
		log_lines.pop_front()
	if logl:
		logl.text = "\n".join(log_lines)

func lbl(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_child(l)
	return l

func btn(t: String, f: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.pressed.connect(f)
	box.add_child(b)
	return b

func _ready() -> void:
	randomize()
	var th := Theme.new()
	th.default_font_size = 32
	theme = th
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	status = Label.new()
	root.add_child(status)
	var tb := HBoxContainer.new()
	root.add_child(tb)
	for i in TABS.size():
		var b := Button.new()
		b.text = TABS[i]
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.pressed.connect(set_tab.bind(i))
		tb.add_child(b)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(sc)
	box = VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	sc.add_child(box)
	logl = Label.new()
	logl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	logl.custom_minimum_size.y = 190
	root.add_child(logl)
	var pb := Button.new()
	pb.text = "▶ Старт / ⏸ Пауза"
	pb.pressed.connect(func(): running = not running)
	root.add_child(pb)
	load_game()
	render()

func _process(delta: float) -> void:
	if running:
		tick_t += delta
		if tick_t >= 0.8:
			tick_t = 0.0
			tick()

func set_tab(i: int) -> void:
	tab = i
	render()

func render() -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	prog = null
	match tab:
		0: ui_studio()
		1: ui_team()
		2: ui_plats()
		3: ui_games()
	upd()

func upd() -> void:
	status.text = "%d г., нед. %d | $%d | Слава %d" % [year(), week % 52 + 1, money, fame]
	if prog != null and proj != null:
		prog.text = "Прогресс: %d%%   Баги: %d" % [int(100.0 * proj.pr / proj.need), int(proj.bugs)]

func ui_studio() -> void:
	if proj != null:
		lbl("Разработка: «%s» (%s, %s)" % [proj.n, proj.g, proj.p])
		prog = lbl("")
		return
	lbl("Новая игра")
	var le := LineEdit.new()
	le.placeholder_text = "Название игры"
	le.text = sel.name
	le.text_changed.connect(func(t): sel.name = t)
	box.add_child(le)
	var go := OptionButton.new()
	for g in GENRES:
		go.add_item(g)
	go.select(sel.g)
	go.item_selected.connect(func(i):
		sel.g = i
		render())
	box.add_child(go)
	lbl("Идеальный баланс Дизайн/Тех/Графика: %s" % str(GENRES[GENRES.keys()[sel.g]]))
	var po := OptionButton.new()
	var av := []
	for p in PLATS:
		if p.y <= year():
			av.append(p)
			po.add_item(p.n + ("" if lic.has(p.n) else " (лиц. $%d)" % p.c))
			if p.n == sel.p:
				po.select(av.size() - 1)
	po.item_selected.connect(func(i): sel.p = av[i].n)
	box.add_child(po)
	var fn := ["Дизайн", "Технологии", "Графика"]
	for k in 3:
		lbl(fn[k])
		var s := HSlider.new()
		s.max_value = 100
		s.value = sel.f[k]
		s.custom_minimum_size.y = 44
		s.value_changed.connect(func(v): sel.f[k] = v)
		box.add_child(s)
	var mo := OptionButton.new()
	for m in MK:
		mo.add_item("Маркетинг $%d" % m)
	mo.select(MK.find(sel.m))
	mo.item_selected.connect(func(i): sel.m = MK[i])
	box.add_child(mo)
	btn("Начать разработку", start_proj)

func start_proj() -> void:
	var nm: String = sel.name.strip_edges()
	if nm == "":
		say("Введи название игры.")
		return
	var p = plat(sel.p)
	var cost: int = 0 if lic.has(p.n) else int(p.c)
	if money < cost + sel.m:
		say("Не хватает денег.")
		return
	money -= cost + sel.m
	if not lic.has(p.n):
		lic.append(p.n)
	var f: Array = sel.f
	var s := maxf(1.0, f[0] + f[1] + f[2])
	proj = {"n": nm, "g": GENRES.keys()[sel.g], "p": p.n,
		"f": [f[0] / s * 100.0, f[1] / s * 100.0, f[2] / s * 100.0],
		"pr": 0.0, "need": 200.0 + (year() - 1990) * 20.0,
		"bugs": 0.0, "m": sel.m, "q": 0.0, "w": 0}
	sel.name = ""
	running = true
	say("Старт разработки «%s»." % nm)
	render()

func ui_team() -> void:
	lbl("Сотрудники (%d/8). Д=дизайн Т=тех Г=графика" % emps.size())
	for i in emps.size():
		var e = emps[i]
		btn("Уволить %s Д%d Т%d Г%d $%d/мес" % [e.n, int(e.d), int(e.t), int(e.a), int(e.s)], fire.bind(i))
	lbl("Кандидаты (обновляются раз в месяц). Найм = 1 оклад.")
	for i in cand.size():
		var e = cand[i]
		btn("Нанять %s Д%d Т%d Г%d $%d/мес" % [e.n, int(e.d), int(e.t), int(e.a), int(e.s)], hire.bind(i))

func hire(i: int) -> void:
	var e = cand[i]
	if emps.size() >= 8:
		say("Офис полный (8).")
		return
	if money < e.s:
		say("Не хватает денег на найм.")
		return
	money -= int(e.s)
	emps.append(e)
	cand.remove_at(i)
	say("Нанят %s." % e.n)
	render()

func fire(i: int) -> void:
	say("Уволен %s." % emps[i].n)
	emps.remove_at(i)
	render()

func ui_plats() -> void:
	for p in PLATS:
		var st := ""
		if p.y > year():
			st = "выйдет в %d г." % p.y
		elif lic.has(p.n):
			st = "лицензия есть"
		else:
			st = "доступна"
		lbl("%s | рынок x%.1f | %s" % [p.n, p.mk, st])
		if p.y <= year() and not lic.has(p.n):
			btn("Купить лицензию $%d" % p.c, buy_lic.bind(p.n))

func buy_lic(n: String) -> void:
	var p = plat(n)
	if money < p.c:
		say("Не хватает денег.")
		return
	money -= int(p.c)
	lic.append(n)
	say("Лицензия на %s куплена." % n)
	render()

func ui_games() -> void:
	lbl("Награды:")
	if awards.is_empty():
		lbl("пока нет (нужна оценка 8+ за год)")
	for a in awards:
		lbl("🏆 " + a)
	lbl("Выпущенные игры:")
	for i in range(hist.size() - 1, maxi(-1, hist.size() - 13), -1):
		var h = hist[i]
		lbl("«%s» %s/%s, %d г. Оценка %.1f, выручка $%d" % [h.n, h.g, h.p, int(h.y), h.sc, int(h.rev)])
	btn("Новая игра (сброс)", new_game)

func new_game() -> void:
	money = 60000
	week = 0
	fame = 0
	emps = []
	lic = ["PC"]
	proj = null
	sales = []
	hist = []
	awards = []
	running = false
	new_cands()
	DirAccess.remove_absolute("user://save.json")
	say("Новая игра начата.")
	render()

func new_cands() -> void:
	cand = []
	var b := (year() - 1990) / 4
	for i in 3:
		var d := randi_range(1, 6) + b
		var t := randi_range(1, 6) + b
		var a := randi_range(1, 6) + b
		cand.append({"n": NAMES.pick_random(), "d": d, "t": t, "a": a, "s": (d + t + a) * 90})

func tick() -> void:
	week += 1
	if proj != null:
		work()
	sales_step()
	if week % 4 == 0:
		for e in emps:
			money -= int(e.s)
		money -= 800
		new_cands()
		save_game()
		if tab == 1:
			render()
	if week % 52 == 0:
		year_end()
	if money < -20000:
		running = false
		say("Банкротство! Открой «Игры» → «Новая игра».")
	upd()

func work() -> void:
	var f: Array = proj.f
	var pts := 6.0
	var tech := 0.0
	for e in emps:
		pts += (e.d * f[0] + e.t * f[1] + e.a * f[2]) / 100.0
		tech += e.t
	proj.pr += pts
	proj.q += pts
	proj.w += 1
	proj.bugs += maxf(0.0, randf_range(0.0, 3.0) - tech * 0.05)
	if proj.pr >= proj.need:
		release()

func release() -> void:
	var ideal: Array = GENRES[proj.g]
	var diff := 0.0
	for k in 3:
		diff += absf(proj.f[k] - ideal[k])
	var fit := 0.6 + 0.4 * (1.0 - diff / 200.0)
	var avg: float = proj.q / proj.w
	var sc := 10.0 * (1.0 - exp(-avg / 15.0)) * fit - minf(3.0, proj.bugs / 40.0) + randf_range(-0.7, 0.7)
	sc = snappedf(clampf(sc, 1.0, 10.0), 0.1)
	var p = plat(proj.p)
	var mk: float = p.mk * (2000.0 + fame * 8.0) * pow(sc / 5.0, 2.0) * (1.0 + proj.m / 10000.0)
	hist.append({"n": proj.n, "g": proj.g, "p": proj.p, "sc": sc, "rev": 0, "y": year()})
	sales.append({"hi": hist.size() - 1, "mk": mk, "k": 0})
	fame = maxi(0, fame + int((sc - 5.0) * 10.0))
	say("Релиз «%s»: оценка %.1f" % [proj.n, sc])
	proj = null
	render()

func sales_step() -> void:
	var keep := []
	for s in sales:
		var u: float = s.mk * 0.25 * pow(0.7, s.k)
		var r := u * 15.0 * (1.0 + (year() - 1990) * 0.02)
		money += int(r)
		hist[int(s.hi)].rev += int(r)
		s.k += 1
		if u > 5.0:
			keep.append(s)
	sales = keep

func year_end() -> void:
	var y := year() - 1
	var best = null
	for h in hist:
		if int(h.y) == y and (best == null or h.sc > best.sc):
			best = h
	if best != null and best.sc >= 8.0:
		awards.append("%d: «%s» — Игра года" % [y, best.n])
		money += 25000
		fame += 50
		say("🏆 «Игра года»: %s (+$25000)" % best.n)
	for p in PLATS:
		if p.y == year() and p.y > 1990:
			say("Вышла новая консоль: %s!" % p.n)
	if tab == 0 or tab == 2 or tab == 3:
		render()

func save_game() -> void:
	var d := {"money": money, "week": week, "fame": fame, "emps": emps, "lic": lic,
		"proj": proj, "sales": sales, "hist": hist, "awards": awards, "cand": cand}
	var f := FileAccess.open("user://save.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

func load_game() -> void:
	if FileAccess.file_exists("user://save.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("user://save.json"))
		if d is Dictionary:
			money = int(d.money)
			week = int(d.week)
			fame = int(d.fame)
			emps = d.emps
			lic = d.lic
			proj = d.proj
			sales = d.sales
			hist = d.hist
			awards = d.awards
			cand = d.cand
			say("Сохранение загружено. Нажми ▶.")
			return
	new_cands()
	say("Добро пожаловать! Назови игру, выбери жанр и консоль, нажми ▶.")
