# coding=utf-8
cdef extern from "math.h":  
    float asinf(float theta)  
    float acosf(float theta)
    float sqrt(float value)
    float floor(float value)

import os, math
from PIL import Image

class Vector3f:
    def __init__(self, v = None):
        if v is not None:
            self.x = v.x
            self.y = v.y
            self.z = v.z
        else:
            self.x = 0.0
            self.y = 0.0
            self.z = 0.0
        return

    def copy(self, v):
        self.x = v.x
        self.y = v.y
        self.z = v.z
        return self

    def set(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z
        return self

    def add(self, o):
        # r = Vector3f()
        # r.x = self.x + o.x
        # r.y = self.y + o.y
        # r.z = self.z + o.z
        # return r
        self.x += o.x
        self.y += o.y
        self.z += o.z
        return self

    def sub(self, o):
        # r = Vector3f()
        # r.x = self.x - o.x
        # r.y = self.y - o.y
        # r.z = self.z - o.z
        # return r
        self.x -= o.x
        self.y -= o.y
        self.z -= o.z
        return self

    def mul(self, v):
        # r = Vector3f()
        # r.x = self.x * v
        # r.y = self.y * v
        # r.z = self.z * v
        # return r
        self.x *= v
        self.y *= v
        self.z *= v
        return self

    def div(self, v):
        # r = Vector3f()
        # r.x = self.x / v
        # r.y = self.y / v
        # r.z = self.z / v
        # return r
        self.x *= v
        self.y *= v
        self.z *= v
        return self

    def dot(self, o):
        return self.x * o.x + self.y * o.y + self.z * o.z

    def length(self):
        return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)

    def norm(self):
        d = self.length()
        r = Vector3f()
        r.x = self.x / d
        r.y = self.y / d
        r.z = self.z / d
        return r

    pass

class UnitSphere:

    def __init__(self, texPath = None):
        self.PixelBuffer = None
        self.ImageW = 0
        self.ImageH = 0
        self.ImageH_Half = 0
        self.R = 0
        self.RH = 0
        if texPath is not None:
            self.LoadTexture(texPath)
        return

    def LoadTexture(self, string):

        # print('LoadTexture ')
        # currentTime = time.time()
        texImg = Image.open(string)
        
        self.PixelBuffer = texImg.load()
        self.ImageW = texImg.size[0]
        self.ImageH = texImg.size[1]
        self.R = self.ImageW / (math.pi * 2.0)
        self.RH = self.ImageH / math.pi
        self.ImageH_Half = self.ImageH * 0.5
        # print('LoadTexture used time ' + str(time.time() - currentTime) + 'sec')

        return

    def GetColor(self, hRad, vRad):
        if self.PixelBuffer is None: return 0, 0, 0

        x = hRad * self.R

        # y = (vRad + math.pi * 0.5) * self.ImageH / math.pi
        # y = self.ImageH - y

        y = self.ImageH_Half - vRad * self.RH

        px = int(floor(x))
        py = int(floor(y))

        return self.PixelBuffer[px, py]

        # idx = py * self.ImageW + px
        # return self.PixelBuffer[idx]

    pass

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

# sampleRate采样范围，为了颜色值过度更加平滑
def RayCastCubeFace(sphere, origin, wVec, hVec, pxWidth, pxHeight, sampleRate):
    # input face rect, sampling rate
    # for each pixel, cast ray, and merge samples
    # save the face
    samples = float(sampleRate * sampleRate)

    wFace = wVec.length()
    hFace = hVec.length()

    wPixel = wFace / float(pxWidth)
    hPixel = hFace / float(pxHeight)
    wSubPixel = wPixel / sampleRate
    hSubPixel = hPixel / sampleRate

    wDir = wVec.norm()
    hDir = hVec.norm()

    colors = []
    pyRange = range(pxHeight)
    pxRange = range(pxWidth)

    # add
    dy = Vector3f()
    dx = Vector3f()
    basePos = Vector3f()
    subPos = Vector3f()
    dySubPixel = Vector3f(hDir).mul(0.5 * hSubPixel)
    dxSubPixel = Vector3f(wDir).mul(0.5 * wSubPixel)

    for py in pyRange:
        # dy = hDir.mul(py * hPixel)
        # basePos = origin.add(dy)
        dy.copy(hDir).mul(py * hPixel)
        basePos.copy(origin).add(dy)
        for px in pxRange:
            # dx = wDir.mul(px * wPixel)
            # pos = basePos.add(dx)
            dx.copy(wDir).mul(px * wPixel)
            subPos.copy(basePos).add(dx).add(dySubPixel).add(dxSubPixel)
            hRad, vRad = XYZToHVRad(subPos.x, subPos.y, subPos.z)

            #c = RayCastPixel(pos, wPixel, hPixel, sampleRate)

            c = [0, 0, 0]
            # for j in range(sampleRate):
            #     dySubPixel = hDir.mul((j + 0.5) * hSubPixel)
            #     baseSubPos = pos.add(dySubPixel)
            #     for i in sampleRateRange:
            #         dxSubPixel = wDir.mul((i + 0.5) * wSubPixel)
            #         subPos = baseSubPos.add(dxSubPixel)

            #         hRad, vRad = XYZToHVRad(subPos.x, subPos.y, subPos.z)
            #         r, g, b = sphere.GetColor(hRad, vRad)
            #         c[0] += r
            #         c[1] += g
            #         c[2] += b
            #         pass
            # # end iterating subpixel

            # r = round(c[0] / samples)
            # g = round(c[1] / samples)
            # b = round(c[2] / samples)

            # hRad, vRad = XYZToHVRad(subPos.x, subPos.y, subPos.z)
            r, g, b = sphere.GetColor(hRad, vRad)
            c[0] = r
            c[1] = g
            c[2] = b
            # end iterating subpixel

            r = round(c[0] / samples)
            g = round(c[1] / samples)
            b = round(c[2] / samples)
            colors.append((int(r), int(g), int(b)))
            pass
        pass
    # end iterating all pixels

    return colors

def SaveCubeFace(path, w, h, colors):
    img = Image.new('RGB', (w, h))
    img.putdata(colors)
    img.save(path, quality=85)
    return

class RectDesc:

    def __init__(self):
        self.origin = Vector3f()
        self.hside = Vector3f()
        self.vside = Vector3f()
        return

    pass