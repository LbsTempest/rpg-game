extends Node

@export var dialogue_data: Array = [
	{"text": "欢迎来到我们的村庄！", "type": "normal"},
	{
		"text": "你来这里做什么？",
		"type": "branch",
		"options": [
			{"text": "寻找任务", "next": 2},
			{"text": "想买东西", "next": 3},
			{"text": "只是路过", "next": 4}
		]
	},
	{"text": "最近森林里的史莱姆很活跃，请小心！", "type": "normal"},
	{"text": "商店在东边的房子里，那里有补给品。", "type": "normal"},
	{"text": "保重！", "type": "normal"}
]
