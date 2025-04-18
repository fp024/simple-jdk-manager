#!/bin/sh

JDK_SH_ROOT=$1

if [ -z "$JDK_SH_ROOT" ]; then
  echo "[알림] 단순 JDK 관리자 스크립트가 설치될 경로를 입력해주세요. 예) /usr/local/JDK"
  exit 1
fi

sudo mkdir -p $JDK_SH_ROOT

if [ ! -d "$JDK_SH_ROOT" ]; then
  echo "[알림] 설치될 경로가 만들어지지 않았습니다.: $JDK_SH_ROOT"
fi

CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -g -n)

sudo chown $CURRENT_USER.$CURRENT_GROUP $JDK_SH_ROOT

rm -f $JDK_SH_ROOT/update.sh $JDK_SH_ROOT/clean.sh
wget https://raw.githubusercontent.com/fp024/simple-jdk-manager/master/update.sh -O $JDK_SH_ROOT/update.sh || { echo "[오류] update.sh 파일 다운로드에 실패했습니다."; exit 1; }
wget https://raw.githubusercontent.com/fp024/simple-jdk-manager/master/clean.sh -O $JDK_SH_ROOT/clean.sh || { echo "[오류] clean.sh 파일 다운로드에 실패했습니다."; exit 1; }

chmod u+x $JDK_SH_ROOT/update.sh $JDK_SH_ROOT/clean.sh

echo "[알림] 설치가 완료되었습니다. 설치 경로: $JDK_SH_ROOT"
