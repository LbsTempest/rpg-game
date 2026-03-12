extends Node
# 神秘商人对话数据
# 现在简化为触发商店系统

# 当NPC开始对话时，通过信号通知NPC脚本打开商店

# 可以通过以下方式触发商店：
# 在NPC脚本中调用 ShopService.open_shop("merchant_shop")

# 这里保留对话数据用于欢迎语
@export var dialogue_data: Array = [
	{
		"text": "你好，冒险者！欢迎来到我的商店。",
		"type": "normal"
	},
	{
		"text": "我这里有武器、护甲和各种药水，随便看看！",
		"type": "branch",
		"options": [
			{"text": "打开商店", "next": -1, "action": "open_shop"},
			{"text": "离开", "next": 2}
		]
	},
	{
		"text": "慢走，有需要再来找我！",
		"type": "normal"
	}
]

# 商店ID
const SHOP_ID = "merchant_shop"
