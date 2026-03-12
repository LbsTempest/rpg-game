extends RefCounted

@export var definitions: Dictionary = {
	"story_intro_merchant": {
		"type": "segment",
		"title": "初识商人",
		"steps": [
			{"speaker": "旁白", "text": "你第一次来到村庄广场。", "type": "normal"},
			{
				"speaker": "商人",
				"text": "旅人，你愿意帮助村庄清理森林里的史莱姆吗？",
				"type": "branch",
				"options": [
					{
						"text": "我愿意帮忙",
						"next": -1,
						"action": "choose_story_branch",
						"action_payload": {"branch_id": "help_village"}
					},
					{
						"text": "我想先观望",
						"next": -1,
						"action": "choose_story_branch",
						"action_payload": {"branch_id": "stay_neutral"}
					}
				]
			}
		],
		"branches": {
			"help_village": {
				"set_flags": {
					"story.chapter_01.accepted_help": true
				},
				"actions": [
					{
						"id": "accept_quest",
						"payload": {"quest_id": "quest_first"}
					}
				]
			},
			"stay_neutral": {
				"set_flags": {
					"story.chapter_01.accepted_help": false,
					"story.branch.stay_neutral": true
				}
			}
		}
	},
	"ending_guardian": {
		"type": "ending_rule",
		"priority": 100,
		"ending_id": "ending_guardian",
		"required_flags": ["story.chapter_01.accepted_help"]
	},
	"ending_wanderer": {
		"type": "ending_rule",
		"priority": 10,
		"ending_id": "ending_wanderer",
		"required_flags": ["story.branch.stay_neutral"]
	}
}
