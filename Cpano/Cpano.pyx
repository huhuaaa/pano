# coding=utf-8
cdef extern from "math.h":  
    float asinf(float theta)  
    float acosf(float theta)
    float sqrt(float value)
    float floor(float value)

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
    # if t > 0.000001: # t == 0.0
    if t > 0.0:
        cosh = x / t
        hRad = acosf(cosh)
        if y < 0.0:
            # hRad = 2.0 * math.pi - hRad
            hRad = 6.28318530717958 - hRad

    d = sqrt(t*t + z*z)
    sint = z / d
    vRad = asinf(sint)

    return hRad, vRad

def getPoints(width, height):
    # wFace = length(wVec)
    # hFace = length(hVec)
    # wPixel = wFace / float(width)
    # hPixel = hFace / float(height)
    # samples = float(sampleRate * sampleRate)
    # wSubPixel = wPixel / sampleRate
    # hSubPixel = hPixel / sampleRate
    
    wPixel = 2.0 / float(width)
    hPixel = 2.0 / float(height)
    wSubPixel = wPixel
    hSubPixel = hPixel

    # wDir = norm(wVec)
    # hDir = norm(hVec)
    # dySubPixel = mul(hDir, 0.5 * hSubPixel)
    # dxSubPixel = mul(wDir, 0.5 * wSubPixel)
    frontOrigin = [-1.0, 1.0, 1.0]
    frontWVec = [0.0, -2.0, 0.0]
    frontHVec = [0.0, 0.0, -2.0]
    frontWDir = norm(frontWVec)
    frontHDir = norm(frontHVec)
    frontDySubPixel = mul(frontHDir, 0.5 * hSubPixel)
    frontDxSubPixel = mul(frontWDir, 0.5 * wSubPixel)
    frontPoints = []

    # leftOrigin = [1.0, 1.0, 1.0]
    # leftWVec = [-2.0, 0.0, 0.0]
    # leftHVec = [0.0, 0.0, -2.0]
    # leftWDir = norm(leftWVec)
    # leftHDir = norm(leftHVec)
    # leftDySubPixel = mul(leftHDir, 0.5 * hSubPixel)
    # leftDxSubPixel = mul(leftWDir, 0.5 * wSubPixel)
    # leftPoints = []

    for py in range(height):
        frontBasePos = add(frontOrigin, mul(frontHDir, py * hPixel))

        # leftBasePos = add(leftOrigin, mul(leftHDir, py * hPixel))
        for px in range(width):
            frontDx = mul(frontWDir, px * wPixel)
            frontPos = add(frontBasePos, frontDx)
            frontBaseSubPos = add(frontPos, frontDySubPixel)
            frontSubPos = add(frontBaseSubPos, frontDxSubPixel)
            hRad, vRad = XYZToHVRad(frontSubPos[0], frontSubPos[1], frontSubPos[2])
            frontPoints.append([hRad, vRad])

            # leftDx = mul(leftWDir, px * wPixel)
            # leftPos = add(leftBasePos, leftDx)
            # leftBaseSubPos = add(leftPos, leftDySubPixel)
            # leftSubPos = add(leftBaseSubPos, leftDxSubPixel)
            # hRad, vRad = XYZToHVRad(leftSubPos[0], leftSubPos[1], leftSubPos[2])
            # leftPoints.append([hRad, vRad])

    return frontPoints

# def frontPoints(width, height):
#     origin = [-1.0, 1.0, 1.0]
#     wVec = [0.0, -2.0, 0.0]
#     hVec = [0.0, 0.0, -2.0]
#     return getPoints(origin, wVec, hVec, width, height)

class sphereToCube:

    def __init__(self, imgPath):
        self.image = Image.open(imgPath)
        self.width = self.image.size[0]
        self.height = self.image.size[1]
        # self.widthRadius = self.width / 2.8 * math.pi
        self.widthRadius = self.width / 6.28318530717958
        self.heightRadius = self.height / 3.14159265358979
        self.heightHalf = self.height * 0.5
        self.cubeWidth = int(self.width / 3.14159265358979)
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
        points = getPoints(self.cubeWidth, self.cubeHeight)
        colors = []
        for point in points:
            colors.append(self.getColor(point[0], point[1]))
        pass
        img = Image.new('RGB', (self.cubeWidth, self.cubeHeight))
        img.putdata(colors)
        img.save(front, quality=85)
    pass
