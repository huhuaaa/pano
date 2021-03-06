# -*- coding: utf-8 -*-
from distutils.core import setup
import py2exe

includes = ["encodings", "encodings.*"]

options = {"py2exe":  
            {"compressed": 1, #压缩  
             "optimize": 2,  
             "ascii": 1,  
             "includes":includes,  
             "bundle_files": 1 #所有文件打包成一个exe文件
            }}
setup(
    options=options,  
    zipfile=None,
    console=[{"script": "spheretocube.py"}]
)