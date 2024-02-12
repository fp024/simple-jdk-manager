#!/bin/sh

JDK_VERSION=$1

if [ "$JDK_VERSION" != "8" ] && [ "$JDK_VERSION" != "11" ] && [ "$JDK_VERSION" != "17" ] && [ "$JDK_VERSION" != "21" ]; then
  echo "버전을 입력해주세요. 가능한 버전은 8, 11, 17, 21 입니다."
  exit 1
fi

export $(grep -v '^#' version.properties | xargs)

JDK_ROOT=$(pwd)

if [ -d "$JDK_VERSION" ]; then
  rm "$JDK_VERSION"
else
  echo "[알림] $JDK_VERSION 심볼릭 링크가 존재하지 않습니다."
fi


rm -rf ${JDK_ROOT}/archive/${JDK_VERSION}
mkdir -p ${JDK_ROOT}/archive/${JDK_VERSION}
cd archive/${JDK_VERSION}
CURRENT_JDK_URL_NAME="JDK_URL_${JDK_VERSION}"
eval CURRENT_JDK_URL=\$$CURRENT_JDK_URL_NAME
wget "${CURRENT_JDK_URL}" || { echo "파일 다운로드에 실패했습니다."; exit 1; }
tar -xvzf *.tar.gz
JDK_DIR=$(find ../$JDK_VERSION/ -mindepth 1 -maxdepth 1 -type d | head -n 1)
mv ${JDK_DIR} latest
cd ${JDK_ROOT}
ln -s archive/${JDK_VERSION}/latest ${JDK_VERSION}

