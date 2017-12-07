#!/usr/bin/python
# coding=utf-8
# from meituan(美团）
# see git@github.com:GavinCT/AndroidMultiChannelBuildTool.git
import zipfile
import shutil
import os
import sys
import getopt
import time

# def main(argv):

argv = sys.argv[1:]

inputfile = ''
outputfile = ''
channelfile = ''

try:
  opts, args = getopt.getopt(argv,"hi:o:c:",["ifile=","ofile=", "cfile"])
except getopt.GetoptError:
  print '-i <inputfile> -o <outputfile> -c <channelfile>'
  sys.exit(2)

for opt, arg in opts:
  if opt == '-h':
    print '-i <inputfile> -o <outputfile> -c <channelfile>'
    sys.exit()
  elif opt in ("-i", "--ifile"):
    inputfile = arg
  elif opt in ("-o", "--ofile"):
    outputfile = arg
  elif opt in ("-c", "--cfile"):
    channelfile = arg

print '输入的文件为：', inputfile
print '输出的文件为：', outputfile
print '渠道文件为  ：', channelfile

ts = time.time()

# 空文件 便于写入此空文件到apk包中作为channel文件
src_empty_file = outputfile + "/czt.txt"
# print 'czt 文件为  ：', src_empty_file
# 创建一个空文件（不存在则创建）
f = open(src_empty_file, 'w') 
f.close()

# 获取当前目录中所有的apk源包
src_apks = []
# python3 : os.listdir()即可，这里使用兼容Python2的os.listdir('.')
for file in os.listdir(inputfile):
  file = inputfile + "/" + file
  # print 'apk file path  ：', file
  if os.path.isfile(file):
    extension = os.path.splitext(file)[1][1:]
    if extension in 'apk':
      src_apks.append(file)

# print 'apk list  ：', src_apks

# 获取渠道列表
channel_file = channelfile
f = open(channel_file)
lines = f.readlines()
f.close()

# print 'channel list  ：', lines

for src_apk in src_apks:
  # print 'src_apk path  ：', src_apk
  # file name (with extension)
  src_apk_file_name = os.path.basename(src_apk)
  # print 'src_apk_file_name：', src_apk_file_name
  # 分割文件名与后缀
  temp_list = os.path.splitext(src_apk_file_name)
  # print 'temp_list：', temp_list
  # name without extension
  src_apk_name = temp_list[0]
  # print 'src_apk_name：', src_apk_name
  # 后缀名，包含.   例如: ".apk "
  src_apk_extension = temp_list[1]
  # print 'src_apk_extension：', src_apk_extension
  
  # 创建生成目录,与文件名相关
  output_dir = outputfile + '/Android_' + src_apk_name + '/'
  # print 'output_dir：', output_dir
  # shutil.rmtree(output_dir)
  # 目录不存在则创建
  if os.path.exists(output_dir):
    shutil.rmtree(output_dir)

  os.mkdir(output_dir)
  # print 'create output_dir success'

  # 遍历渠道号并创建对应渠道号的apk文件
  for line in lines:
    # 获取当前渠道号和名称信息，因为从渠道文件中获得带有\n,所有strip一下
    target = line.strip()
    # 获取当前渠道号和名称
    target_channel, target_name = target.split(',', 1)
    # 拼接对应渠道号的apk
    target_apk = output_dir + src_apk_name + "_" + target_name + src_apk_extension  
    # 拷贝建立新apk
    shutil.copy(src_apk,  target_apk)
    # zip获取新建立的apk文件
    zipped = zipfile.ZipFile(target_apk, 'a', zipfile.ZIP_DEFLATED)
    # 初始化渠道信息
    empty_channel_file = "META-INF/costoonchannel_{channel}".format(channel = target_channel)
    # 写入渠道信息
    zipped.write(src_empty_file, empty_channel_file)
    # 关闭zip流
    zipped.close()

print 'write channel info success, total time(s): ', time.time() - ts

# if __name__ == "__main__":
#    main(sys.argv[1:])
