## auto build and package app shell

1. 初始化      -验证参数，填充参数
2. 拉源码      -重置项目目录，下载源码
3. gradle编译  -进入项目目录，获取任务列表，并执行任务（gradle task）
4. APK签名     -拷贝apks到待签名目录，循环签名并对齐apk到签名目录
5. 360加固     -登录360服务器，循环加固apk到加固目录
6. 多渠道      -循环修改 apk 的 meta-inf 文件夹，创建渠道文件，并输出到渠道文件夹
 - 获取参数，原始 apks 目录，输出目录，channel.txt 路径
 - 执行命令 `python MultiChannelBuildTool.py -i apks_source_dir -o apks_target_dir -c channel_file_path`
7. 同步        -拷贝最终 apks 到线上目录（5 6 两步可以不执行），生成二维码输出，并上传到版本管理服务器
