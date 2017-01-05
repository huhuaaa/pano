from distutils.core import setup
from Cython.Build import cythonize
setup(name = 'Cpano',
      ext_modules = cythonize("Cpano.pyx"))