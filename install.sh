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

# 기존 스크립트 및 version.properties 파일 제거
rm -f $JDK_SH_ROOT/update.sh $JDK_SH_ROOT/clean.sh $JDK_SH_ROOT/version.properties

# update.sh 복사 또는 다운로드
if [ -f "./update.sh" ]; then
  echo "[알림] 현재 디렉토리의 update.sh를 복사하여 설치합니다."
  cp ./update.sh $JDK_SH_ROOT/update.sh
else
  echo "[알림] update.sh를 다운로드하여 설치합니다."
  wget https://raw.githubusercontent.com/fp024/simple-jdk-manager/master/update.sh -O $JDK_SH_ROOT/update.sh || { echo "[오류] update.sh 파일 다운로드에 실패했습니다."; exit 1; }
fi

# clean.sh 복사 또는 다운로드
if [ -f "./clean.sh" ]; then
  echo "[알림] 현재 디렉토리의 clean.sh를 복사하여 설치합니다."
  cp ./clean.sh $JDK_SH_ROOT/clean.sh
else
  echo "[알림] clean.sh를 다운로드하여 설치합니다."
  wget https://raw.githubusercontent.com/fp024/simple-jdk-manager/master/clean.sh -O $JDK_SH_ROOT/clean.sh || { echo "[오류] clean.sh 파일 다운로드에 실패했습니다."; exit 1; }
fi

# version.properties 복사 또는 다운로드
if [ -f "./version.properties" ]; then
  echo "[알림] 현재 디렉토리의 version.properties를 복사하여 설치합니다."
  cp ./version.properties $JDK_SH_ROOT/version.properties
else
  echo "[알림] version.properties를 다운로드하여 설치합니다."
  wget https://raw.githubusercontent.com/fp024/simple-jdk-manager/master/version.properties -O $JDK_SH_ROOT/version.properties || { echo "[오류] version.properties 파일 다운로드에 실패했습니다."; exit 1; }
fi

chmod u+x $JDK_SH_ROOT/update.sh $JDK_SH_ROOT/clean.sh

echo "[알림] 설치가 완료되었습니다. 설치 경로: $JDK_SH_ROOT"
