#!/bin/bash
#see readme.md

# ################### #
# 移动 inputfile 所有文件到 outputfile 目录中
# 忽略层级关系
# ################### #
mvfile(){
 echo "准备移动 ${1} 到 ${2} ${3}"
 if [ -d "${1}" ];then
  ls_result=`ls "${1}"`
  IFS=$'\n'; files=($ls_result); unset IFS;

  for file in ${files[@]}
  do
   ifile="${1}/$file"
   mvfile "$ifile" "${2}" ${3}
  done
 elif [ -f "${1}" ];then
  if [ 2 -eq $# ];then
   echo "正在移动1 ${1} 至 ${2}"
   mv "${1}" "${2}"
  elif [ "${1##*.}" = $3 ];then
   echo "正在移动2 ${1} 至 ${2}"
   mv "${1}" "${2}"
  fi
 fi
}

# ################### #
# 将指定目录内的所有文件地址转换为二维码图片并保存
# ################### #
loadqr(){
# echo "目录：$1"
# echo "文件：$2"
# echo "URL ：$3"

 local tagetpath="${1}/${2}"

 if [ -d "$tagetpath" ];then
  ls_result=`ls "$tagetpath"`
  IFS=$'\n'; files=($ls_result); unset IFS;

  for file in ${files[@]}
  do
   loadqr "${1}" "${2}/$file" ${3}
  done
 elif [ -f "$tagetpath" ];then
  java -jar "$_root/QRGen.jar" "${3}/${2}" "$tagetpath.png"
 fi
}


time=`date +%s`

# shell 执行目录
_root=$(cd `dirname $0`; pwd)

# 获取本机 ip 地址
localhost=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

echo "根目录：$_root"
echo "本机地址：$localhost"

# ################## #
# 测试数据           #
# gradle_proxy_host="127.0.0.1"
# gradle_proxy_port="1087"
# _os="android"
# _360_username=""
# _360_password=""
# project_sign_file=""
# project_sign_psd=""
# project_sign_alias=""
# project_sign_alias_psd=""
# project_name=""
# project_version=""
# project_main=""
# project_flavor=""
# apk_source_svn=""
# apk_channel_file_path=""
# ################## #

gradle_proxy_host="127.0.0.1"
gradle_proxy_port=1087

# 平台
_os="android"

# 360 账号用户名
_360_username=""
# 360 账号密码
_360_password=""

# 签名文件路径
project_sign_file=""
# 签名密码
project_sign_psd=""
# 签名作者
project_sign_alias=""
# 签名作者密码
project_sign_alias_psd=""

# 项目名
project_name=""
# 项目版本名称
project_version=""
# 项目主工程目录
project_main=""
project_flavor=""
min_sdk_version=14

# 项目 SVN 地址
apk_source_svn=""

# 多渠道配置文件路径
apk_channel_file_path=""

apks_input_dir=""

# #################### #
# 初始化               #
# #################### #

echo "初始化..."

while getopts "hi:j:k:l:m:n:o:p:q:r:s:t:u:v:" arg
do
 case $arg in
 h)
  echo "-i: project name（项目名称）"
  echo "-j: project version name（项目版本号）"
  echo "-k: project main moudle name（项目主模块名称，即 application moudle）"
  echo "-l: project flavor task list, if empty, build all flavor, use "/" separated（项目 gradle 执行任务名称列表，如果为空，编译所有任务，填写时，使用 / 分隔）"
  echo "-m: project source svn http url（项目线上 svn 源码地址）"
  echo "-n: project channel file path for local, if empty, can't build channel pacakge（项目渠道文件地址，如果为空，则不打渠道包）"
  echo "-o: project sign file path for local（项目打包签名文件地址）"
  echo "-p: project sign file password（项目打包签名文件的密码）"
  echo "-q: project sign alias name（项目打包签名作者名称）"
  echo "-r: project sign alias password（项目打包签名作者的密码）"
  echo "-s: if use 360's jiagu, please write 360 login username（如果要使用360加固，请填写360登陆用户名）"
  echo "-t: if use 360's jiagu, please write 360 login password（如果要使用360加固，请填写360登陆密码）"
  echo "-u: gradle proxy ip（Gradle 代理 IP 地址）"
  echo "-v: gradle proxy port（Gradle 代理 port 商品号）"
  exit 0
 ;;
 i)
  project_name=$OPTARG
 ;;
 j)
  project_version=$OPTARG
 ;;
 k)
  project_main=$OPTARG
 ;;
 l)
  project_flavor=$OPTARG
 ;;
 m)
  apk_source_svn=$OPTARG
 ;;
 n)
  apk_channel_file_path=$OPTARG
 ;;
 o)
  project_sign_file=$OPTARG
 ;;
 p)
  project_sign_psd=$OPTARG
 ;;
 q)
  project_sign_alias=$OPTARG
 ;;
 r)
  project_sign_alias_psd=$OPTARG
 ;;
 s)
  _360_username=$OPTARG
 ;;
 t)
  _360_password=$OPTARG
 ;;
 u)
  gradle_proxy_host=$OPTARG
 ;;
 v)
  gradle_proxy_port=$OPTARG
 ;;
esac
done

echo "build and package start"

# 编译目录
build_root="$_root/build"

# 编译源码目录
source_root="$build_root/$project_name/$project_version/$_os/source"
# 输出目录，未签名
output_root="$build_root/$project_name/$project_version/$_os/output"
# 输出目录，已签名
signed_root="$build_root/$project_name/$project_version/$_os/signed"
# 输出目录，已加固
jiaguu_root="$build_root/$project_name/$project_version/$_os/jiaguu"
# 输出目录，多渠道
channel_root="$build_root/$project_name/$project_version/$_os/channel"

# 线上目录
online_root="$_root/files/apks/$project_name/$project_version/$_os"
online_qr_root="$_root/files/apks/$project_name/$project_version/$_os/qr"

if [ "" != "$source_root" ];then

echo "删除 $source_root"
rm -rf $source_root
echo "删除 $output_root"
rm -rf $output_root
echo "删除 $signed_root"
rm -rf $signed_root
echo "删除 $jiaguu_root"
rm -rf $jiaguu_root
echo "删除 $channel_root"
rm -rf $channel_root
echo "删除 $online_root"
rm -rf $online_root
echo "删除 $online_qr_root"
rm -rf $online_qr_root

fi


# #################### #
# 拉源码               #
# #################### #
if [ "" != "$apk_source_svn" ]
then

 echo "pull source from $apk_source_svn"

 svn checkout $apk_source_svn $source_root

fi
# #################### #
# gradle编译           #
# something to see https://developer.android.com/studio/intro/update.html#download-with-gradle
# and http://chaosleong.github.io/2017/02/10/Configuring-Gradle-Proxy/
# #################### #
if [ "" != "$apk_source_svn" ]
then


 cd $source_root

 if [ "" != "$gradle_proxy_host" ]
 then
  rm -f gradle.properties
  echo "代理IP: $gradle_proxy_host"
  echo "代理Port: $gradle_proxy_port"
  gradle -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=1087 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=1087 -DsocksProxyHost=127.0.0.1 -DsocksProxyPort=1087
 fi

 echo "查看 Gradle 所有任务"
 sh gradlew tasks

 echo "编译 Gradle 任务"

 if [ "" == "$project_flavor" ]
 then
  task="assembleRelease"
  sh gradlew $task
 else
  ss="Release"
  # 拆分字符串并循环打印
  IFS=/ flavors=($project_flavor) 
  for flavor in ${flavors[@]}
  do
   flavor="$(tr '[:lower:]' '[:upper:]' <<< ${flavor:0:1})${flavor:1}"
   task="assemble$flavor$ss"
   sh gradlew $task
  done
 fi

 echo "创建 $output_root"
 mkdir -p "$output_root"

 gradle_output_root="$source_root/$project_main/build/outputs/apk"
 echo "准备移动目录 $gradle_output_root 到 $output_root"

 mvfile "$gradle_output_root" "$output_root" apk

#  ls_result=`ls "$gradle_output_root"`
# 
# # 以空格分隔字符串
# # files=`echo "$ls_result" | tr -s ' ' | cut -d ' ' -f2`
# # 以换行符分隔字符串
#  IFS=$'\n'; files=($ls_result); unset IFS;
# 
#  for file in ${files[@]}
#  do
#   echo "准备移动 $file"
#   file="$gradle_output_root/$file"
#   echo "移动 $file 至 $output_root"
#   mv $file $output_root
#  done

 apks_input_dir="$output_root"

fi
# #################### #
# APK签名              #
# #################### #
if [ "" != "$project_sign_file" ]
then

 mkdir -p "$signed_root"

 for file in `ls $apks_input_dir`
 do
  unsigned_apk="$file"
  aligned_unsigned_apk="aligned_$file"
  signed_apk=${unsigned_apk/unsigned/signed}

  # v1-signing-enabled 默认签名方式
  # v2-signing-enabled 签名后，安装验证包大小

  zipalign -v -p 4 "$apks_input_dir/$unsigned_apk" "$apks_input_dir/$aligned_unsigned_apk"
  apksigner sign --v1-signing-enabled true --v2-signing-enabled false --ks "$project_sign_file" --ks-pass pass:"$project_sign_psd" --ks-key-alias "$project_sign_alias" --key-pass pass:"$project_sign_alias_psd" --out "$signed_root/$signed_apk" "$apks_input_dir/$aligned_unsigned_apk"
  apksigner verify --min-sdk-version $min_sdk_version "$signed_root/$signed_apk"
  echo "签名完成，保存地址为$signed_root/$signed_apk"
 done

 apks_input_dir="$signed_root"

fi
# #################### #
# 360加固              #
# #################### #
if [ "" != "$_360_username" ]
then
 
 _360_android_jiagu_sdk="$_root/360_android_jiagu_sdk"
 cd "$_360_android_jiagu_sdk"
 
 mkdir -p "$jiaguu_root"
 
#  _360_bin_path="$_360_android_jiagu_sdk/java/bin"
#  for file in `ls $_360_bin_path`
#  do
#   chmod 775 "$_360_bin_path/$file"
#  done
 
 java -jar jiagu.jar -login $_360_username $_360_password
 java -jar jiagu.jar -importsign "$project_sign_file" "$project_sign_psd" "$project_sign_alias" "$project_sign_alias_psd"
 java -jar jiagu.jar -config -x86
 # 360 加固助手命令行不支持增强选项配置
 # 360_android_jiagu_path.jar 作为补丁实现此服务
 # chmod 775 360_android_jiagu_patch.jar
 java -jar 360_android_jiagu_patch.jar "jiagu.db" 32
 
 # 循环加固             #
 
 for apk_file in `ls $apks_input_dir`
 do
  apk_file_abspath="$apks_input_dir/$apk_file"
  apk_file_outpath="$jiaguu_root"
  echo "start jiagu $apk_file_abspath"
  java -jar jiagu.jar -jiagu $apk_file_abspath $apk_file_outpath -autosign
  echo "$apk_file jiagu finished, out to $apk_file_outpath"
 done
 
 apks_input_dir="$jiaguu_root"
 
fi
# #################### #
# 多渠道               #
# #################### #
if [ "" != "$apk_channel_file_path" ]
then
 
 cd $_root
 
 mkdir -p "$channel_root"
 
 ./MultiChannelBuildToolS.py -i $apks_input_dir -o $channel_root -c $apk_channel_file_path

 rm -f "$channel_root/czt.txt"
 
 apks_input_dir=$channel_root
 
fi

# #################### #
# 同步                 #
# #################### #
if [ "" != "$localhost" ]
then
 
 mkdir -p "$online_root"
 cd "$online_root"
 
 for file in `ls $apks_input_dir`
 do
  cp -rf $apks_input_dir/$file $online_root

  online_url="http://$localhost:12345/files/apks/$project_name/$project_version/$_os"

  loadqr "$online_root" "$file" "$online_url"

  # 输出线上地址
  echo "线上地址：$online_url"
 done

 apks_input_dir=$online_root

fi
# #################### #
# 收尾                 #
# #################### #

stime=`date +%s`
time=`expr $stime - $time`
echo "build and package finished，total time：$time"
echo "apks: $apks_input_dir"


