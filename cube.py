# coding=utf-8
from PIL import Image
import math
# 读取图片文件
source = Image.open('./pano.jpg')
# 转换像素数据
sourceLoad = source.load()
# 读取图片的宽高
(width, height) = source.size
# 算出球体半径
r = width / 2 / math.pi
# 算出立方体边长
rectWidth = int(2 * r)

# 计算正前方的正方形图
front = Image.new("RGB", (rectWidth, rectWidth))
frontLoad = front.load()
rge = range(0, rectWidth)
for x in rge:
	for y in rge:
		thetax = math.atan((x - rectWidth / 2) / r) + math.pi
		thetay = math.atan((y - rectWidth / 2) / r) + math.pi / 2
		# x1, y1为标准柱形图上的坐标位置
		x1 = thetax * r
		y1 = thetay * r
		# 需要将标准左边转换为全景图上的坐标
		# frontLoad[x, y] = sourceLoad[x1, y1]

front.save('./f.jpg')