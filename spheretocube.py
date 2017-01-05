# coding=utf-8
#import Image
import os, math, time, multiprocessing
from PIL import Image

class Vector3f:
    def __init__(self):
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        return

    def set(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z
        return

    def add(self, o):
        r = Vector3f()
        r.x = self.x + o.x
        r.y = self.y + o.y
        r.z = self.z + o.z
        return r

    def sub(self, o):
        r = Vector3f()
        r.x = self.x - o.x
        r.y = self.y - o.y
        r.z = self.z - o.z
        return r

    def mul(self, v):
        r = Vector3f()
        r.x = self.x * v
        r.y = self.y * v
        r.z = self.z * v
        return r

    def div(self, v):
        r = Vector3f()
        r.x = self.x / v
        r.y = self.y / v
        r.z = self.z / v
        return r

    def dot(self, o):
        return self.x * o.x + self.y * o.y + self.z * o.z

    def length(self):
        return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)

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
        self.TexturePath = ''
        self.PixelBuffer = None
        self.ImageW = 0
        self.ImageH = 0
        self.pi2 = 2 * math.pi
        self.pihalf = 0.5 * math.pi
        self.R = 0
        self.Hr = 0
        if texPath is not None:
            self.LoadTexture(texPath)
        return

    def LoadTexture(self, texPath):
        if not os.path.exists(texPath):
            raise

        print("loading %s" %(texPath))
        currentTime = time.time()
        self.TexturePath = texPath
        texImg = Image.open(texPath)

        # Memory will be used in large numbers, when use this code.
        # d = texImg.getdata()
        # self.PixelBuffer = list(d)
        
        self.PixelBuffer = texImg.load()
        self.ImageW = texImg.size[0]
        self.ImageH = texImg.size[1]
        # 半径
        self.R = self.ImageW / self.pi2
        # 高的半径，默认为二比一的话，那么就是半径的一半
        self.Hr = self.ImageH / math.pi

        print('Use time ' + str(time.time() - currentTime) + 'sec')

        return

    def GetColor(self, hRad, vRad):
        if self.PixelBuffer is None: return 0, 0, 0

        x = hRad * self.R
        y = (vRad + self.pihalf) * self.Hr
        y = self.ImageH - y

        px = int(math.floor(x))
        py = int(math.floor(y))

        return self.PixelBuffer[px, py]

        # idx = py * self.ImageW + px
        # return self.PixelBuffer[idx]

    pass

def XYZToHVRad(x, y, z):
    t = math.sqrt(x*x + y*y)

    hRad = 0.0
    if t > 0.000001: # t == 0.0
        cosh = x / t
        hRad = math.acos(cosh)
        if y < 0.0:
            hRad = 2.0 * math.pi - hRad

    d = math.sqrt(t*t + z*z)
    sint = z / d
    vRad = math.asin(sint)

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

    print('RayCastCubeFace')
    currentTime = time.time()

    colors = []
    for py in range(pxHeight):
        dy = hDir.mul(py * hPixel)
        basePos = origin.add(dy)
        for px in range(pxWidth):
            dx = wDir.mul(px * wPixel)
            pos = basePos.add(dx)
            #c = RayCastPixel(pos, wPixel, hPixel, sampleRate)

            c = [0, 0, 0]
            for j in range(sampleRate):
                dySubPixel = hDir.mul((j + 0.5) * hSubPixel)
                baseSubPos = pos.add(dySubPixel)
                for i in range(sampleRate):
                    dxSubPixel = wDir.mul((i + 0.5) * wSubPixel)
                    subPos = baseSubPos.add(dxSubPixel)

                    hRad, vRad = XYZToHVRad(subPos.x, subPos.y, subPos.z)
                    r, g, b = sphere.GetColor(hRad, vRad)
                    c[0] += r
                    c[1] += g
                    c[2] += b
                    pass
            # end iterating subpixel

            r = round(c[0] / samples)
            g = round(c[1] / samples)
            b = round(c[2] / samples)
            colors.append((int(r), int(g), int(b)))
            pass
        pass
    # end iterating all pixels
    print('RayCastCubeFace time ' + str(time.time() - currentTime) + 'sec')
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

def GetCubeFrontRect():
    desc = RectDesc()
    desc.origin.set(-1.0, 1.0, 1.0)
    desc.hside.set(0.0, -2.0, 0.0)
    desc.vside.set(0.0, 0.0, -2.0)
    return desc

def GetCubeRightRect():
    desc = RectDesc()
    desc.origin.set(-1.0, -1.0, 1.0)
    desc.hside.set(2.0, 0.0, 0.0)
    desc.vside.set(0.0, 0.0, -2.0)
    return desc

def GetCubeLeftRect():
    desc = RectDesc()
    desc.origin.set(1.0, 1.0, 1.0)
    desc.hside.set(-2.0, 0.0, 0.0)
    desc.vside.set(0.0, 0.0, -2.0)
    return desc

def GetCubeBackRect():
    desc = RectDesc()
    desc.origin.set(1.0, -1.0, 1.0)
    desc.hside.set(0.0, 2.0, 0.0)
    desc.vside.set(0.0, 0.0, -2.0)
    return desc

def GetCubeTopRect():
    desc = RectDesc()
    desc.origin.set(1.0, 1.0, 1.0)
    desc.hside.set(0.0, -2.0, 0.0)
    desc.vside.set(-2.0, 0.0, 0.0)
    return desc

def GetCubeBottomRect():
    desc = RectDesc()
    desc.origin.set(-1.0, 1.0, -1.0)
    desc.hside.set(0.0, -2.0, 0.0)
    desc.vside.set(2.0, 0.0, 0.0)
    return desc

# 多线程
def createCubeFront(origin, file, width, height, sample):
    global sphere
    print('generating front face')
    face = GetCubeFrontRect()
    colors = RayCastCubeFace(sphere, face.origin, face.hside, face.vside, width, height, sample)
    # print('save front face')
    SaveCubeFace(file, width, height, colors)
    print('end front face')
    return

def createCubeLeft(origin, file, width, height, sample):
    global sphere
    print('generating right face')
    face = GetCubeLeftRect()
    colors = RayCastCubeFace(sphere, face.origin, face.hside, face.vside, width, height, sample)
    # print('save left face')
    SaveCubeFace(file, width, height, colors)
    print('end left face')
    return

def createCubeRight(origin, file, width, height, sample):
    global sphere
    print('generating left face')
    face = GetCubeRightRect()
    colors = RayCastCubeFace(sphere, face.origin, face.hside, face.vside, width, height, sample)
    # print('save right face')
    SaveCubeFace(file, width, height, colors)
    print('end right face')
    return

def createCubeBack(origin, file, width, height, sample):
    global sphere
    print('generating back face')
    face = GetCubeBackRect()
    colors = RayCastCubeFace(sphere, face.origin, face.hside, face.vside, width, height, sample)
    # print('save back face')
    SaveCubeFace(file, width, height, colors)
    print('end back face')
    return

def createCubeTop(origin, file, width, height, sample):
    global sphere
    print('generating top face')
    face = GetCubeTopRect()
    colors = RayCastCubeFace(sphere, face.origin, face.hside, face.vside, width, height, sample)
    # print('save top face')
    SaveCubeFace(file, width, height, colors)
    print('end top face')
    return

def createCubeBottom(origin, file, width, height, sample):
    global sphere
    print('generating bottom face')
    face = GetCubeBottomRect()
    colors = RayCastCubeFace(sphere, face.origin, face.hside, face.vside, width, height, sample)
    # print('save bottom face')
    SaveCubeFace(file, width, height, colors)
    print('end bottom face')
    return

# 多进程处理全景
def run_process(file, w, h, s, num):
    # input unit cube and sphere
    # work on each cube face

    # 启动多进程
    pool = multiprocessing.Pool(num)
    pool.apply_async(createCubeFront, (file, 'f.jpg', w, h, s))
    pool.apply_async(createCubeLeft, (file, 'l.jpg', w, h, s))
    pool.apply_async(createCubeRight, (file, 'r.jpg', w, h, s))
    pool.apply_async(createCubeBack, (file, 'b.jpg', w, h, s))
    pool.apply_async(createCubeTop, (file, 'u.jpg', w, h, s))
    pool.apply_async(createCubeBottom, (file, 'd.jpg', w, h, s))
    pool.close()
    pool.join()
    return 

# if __name__ == '__main__':
#     sphere = UnitSphere()
#     sphere.LoadTexture('pano1.jpg')
#     createCubeFront('pano1.jpg', 'f.jpg', 1500, 1500, 1)

sphere = UnitSphere()
sphere.LoadTexture('pano1.jpg')

if __name__ == '__main__':
    print('go main')
    multiprocessing.freeze_support()
    print('main')
    # 主进程不处理数据
    currentTime = time.time()
    cpu_count = multiprocessing.cpu_count()
    print("The number of CPU is: " + str(cpu_count))
    process_num = cpu_count - 1 if cpu_count > 1 else 1
    print("The number of process is: " + str(process_num))
    run_process('pano1.jpg', 1592, 1592, 1, process_num)
    print('Use time ' + str(time.time() - currentTime) + 'sec')
# else:
#     sphere.LoadTexture('pano1.jpg')