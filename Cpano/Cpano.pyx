# coding=utf-8
cdef extern from "math.h":  
    float asinf(float theta)  
    float acosf(float theta)
    float sqrt(float value)
    float floor(float value)

import os, math
from PIL import Image

# 向量相加
def add(a, b):
    return [a[0] + b[0], a[1] + b[1], a[2] + b[2]]

# 向量相减
def sub(a, b):
    return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]

# 向量乘以数字
def mul(a, b):
    return [a[0] * b, a[1] * b, a[2] * b]

# 向量除数字
def div(a, b):
    return [a[0] / b, a[1] / b, a[2] / b]

# 获取向量长度
def length(a):
    return sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])

# 单位向量，长度为1
def norm(a):
    return div(a, length(a))

# 向量坐标转极坐标
def XYZToHVRad(x, y, z):
    t = sqrt(x*x + y*y)

    hRad = 0.0
    if t > 0.000001: # t == 0.0
        cosh = x / t
        hRad = acosf(cosh)
        if y < 0.0:
            hRad = 2.0 * math.pi - hRad

    d = sqrt(t*t + z*z)
    sint = z / d
    vRad = asinf(sint)

    return hRad, vRad

def getPoints(origin, wVec, hVec, width, height, sampleRate):
    wFace = length(wVec)
    hFace = length(hVec)
    wPixel = wFace / float(width)
    hPixel = hFace / float(height)
    samples = float(sampleRate * sampleRate)
    wSubPixel = wPixel / sampleRate
    hSubPixel = hPixel / sampleRate

    wDir = norm(wVec)
    hDir = norm(hVec)

    pyRange = range(height)
    pxRange = range(width)

    # dy = [0.0, 0.0, 0.0]
    # dx = [0.0, 0.0, 0.0]
    # basePos = [0.0, 0.0, 0.0]
    # subPos = [0.0, 0.0, 0.0]
    dySubPixel = mul(hDir, 0.5 * hSubPixel)
    dxSubPixel = mul(wDir, 0.5 * wSubPixel)
    points = []
    for py in pyRange:
        dy = mul(hDir, py * hPixel)
        basePos = add(origin, dy)
        for px in pxRange:
            dx = mul(wDir, px * wPixel)
            pos = add(basePos, dx)
            baseSubPos = add(pos, dySubPixel)
            subPos = add(baseSubPos, dxSubPixel)
            hRad, vRad = XYZToHVRad(subPos[0], subPos[1], subPos[2])
            points.append([hRad, vRad])

    return points

def frontPoints(width, height, sampleRate):
    origin = [-1.0, 1.0, 1.0]
    wVec = [0.0, -2.0, 0.0]
    hVec = [0.0, 0.0, -2.0]
    return getPoints(origin, wVec, hVec, width, height, sampleRate)

class sphereToCube:

    def __init__(self, imgPath):
        self.image = Image.open(imgPath)
        self.width = self.image.size[0]
        self.height = self.image.size[1]
        self.twoPi = 2.0 * math.pi
        self.widthRadius = self.width / self.twoPi
        self.heightRadius = self.height / math.pi
        self.heightHalf = self.height * 0.5
        self.cubeWidth = (int(self.width / math.pi) >> 1) << 1
        self.cubeHeight = self.cubeWidth
        self.pixelBuffer = self.image.load()
        print('cubeWidth: %d' % self.cubeWidth)
        return
    pass

    def getColor(self, hRad, vRad):
        if self.pixelBuffer is None: return 0, 0, 0

        x = hRad * self.widthRadius

        y = self.heightHalf - vRad * self.heightRadius

        px = int(floor(x))
        py = int(floor(y))
        # print(px, py)
        return self.pixelBuffer[px, py]
    pass


    def toCube(self, savePath):
        front = savePath.replace('%s', 'f')
        points = frontPoints(self.cubeWidth, self.cubeHeight, 1)
        colors = []
        for point in points:
            colors.append(self.getColor(point[0], point[1]))
        pass
        img = Image.new('RGB', (self.cubeWidth, self.cubeHeight))
        img.putdata(colors)
        img.save(front, quality=85)
    pass
