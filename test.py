# coding=utf-8
import Cpano, time

# def t(a):
#     a[0] += 1
#     return a

# a = [1]
# b = t(a)
# print(a[0])
currentTime = time.time()
Cpano.sphereToCube('pano1.jpg').toCube('pano_%s.jpg')
print('Use time ' + str(time.time() - currentTime) + 'sec')