extends Node
# 分支对话示例 - 神秘商人
# 格式说明：
# - type: "normal" (普通对话) 或 "branch" (分支选项)
# - text: 显示的文本
# - options: 分支选项数组（仅 branch 类型需要）
#   - text: 选项按钮文字
#   - next: 选择后跳转到的行索引

@export var dialogue_data: Array = [
	{
		"text": "你好，冒险者！我这里有稀有的商品。",
		"type": "normal"
	},
	{
		"text": "你对什么感兴趣？",
		"type": "branch",
		"options": [
			{"text": "查看武器", "next": 2},
			{"text": "查看药水", "next": 3},
			{"text": "询问任务", "next": 4},
			{"text": "离开", "next": 7}
		]
	},
	{
		"text": "[查看武器] 我有一把锋利的铁剑（100金币）和一把魔法匕首（200金币）。",
		"type": "branch",
		"options": [
			{"text": "购买铁剑", "next": 5},
			{"text": "购买魔法匕首", "next": 6},
			{"text": "再看看别的", "next": 1}
		]
	},
	{
		"text": "[查看药水] 我有生命药水（50金币）和魔法药水（50金币）。",
		"type": "normal"
	},
	{
		"text": "[询问任务] 在北方的森林里有一个被史莱姆占据的洞穴，如果你能清理它们，我会给你丰厚的奖励！",
		"type": "normal"
	},
	{
		"text": "[购买铁剑] 谢谢惠顾！这把剑会保护你的。",
		"type": "normal"
	},
	{
		"text": "[购买魔法匕首] 明智的选择！这把匕首附有冰霜魔法。",
		"type": "normal"
	},
	{
		"text": "[离开] 慢走，有需要再来找我！",
		"type": "normal"
	}
]
