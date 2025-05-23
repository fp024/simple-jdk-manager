#!/bin/sh

JDK_VERSION=$1

if [ "$JDK_VERSION" != "8" ] && [ "$JDK_VERSION" != "11" ] && [ "$JDK_VERSION" != "17" ] && [ "$JDK_VERSION" != "21" ]; then
  echo "[알림] 버전을 입력해주세요. 가능한 버전은 8, 11, 17, 21 입니다."
  exit 1
fi


JDK_ROOT=$(pwd)

wget -O version.properties "https://raw.githubusercontent.com/fp024/simple-jdk-manager/master/version.properties" || { echo "[오류] version.properties 파일 다운로드에 실패했습니다."; eixt 1; }

export $(grep -v '^#' version.properties | xargs)


if [ -d "${JDK_VERSION}" ]; then
  rm "${JDK_VERSION}"
else
  echo "[알림] ${JDK_VERSION} 심볼릭 링크가 존재하지 않습니다."
fi

TEMP_JDK_DIR=${JDK_ROOT}/temp/${JDK_VERSION}
# 압축 파일을 해제할 임시경로
TEMP_JDK_DIR_EXTRACT=${TEMP_JDK_DIR}/extract
TARGET_JDK_DIR=${JDK_ROOT}/archive/${JDK_VERSION}

rm -rf ${TEMP_JDK_DIR_EXTRACT}
mkdir -p ${TEMP_JDK_DIR_EXTRACT}

CURRENT_JDK_URL_NAME="JDK_URL_${JDK_VERSION}"
eval CURRENT_JDK_URL=\$$CURRENT_JDK_URL_NAME
JDK_FILE_NAME=$(basename "$CURRENT_JDK_URL")

if [ -f "${TEMP_JDK_DIR}/${JDK_FILE_NAME}" ]; then 
  echo "[알림] "${TEMP_JDK_DIR}/${JDK_FILE_NAME}" 경로에 동일한 버전의 JDK${JDK_VERSION}의 압축파일이 다운로드 되어있습니다."
  echo "[알림] "${JDK_FILE_NAME}" 파일을 사용합니다."
else 
  wget -P ${TEMP_JDK_DIR} "${CURRENT_JDK_URL}" || { echo "[오류] 파일 다운로드에 실패했습니다."; exit 1; }
fi

tar -xzf ${TEMP_JDK_DIR}/${JDK_FILE_NAME} -C ${TEMP_JDK_DIR_EXTRACT}
TEMP_JDK_DIR_NAME=$(find ${TEMP_JDK_DIR_EXTRACT}/ -mindepth 1 -maxdepth 1 -type d | head -n 1 | xargs basename)

if [ -d "${TARGET_JDK_DIR}/${TEMP_JDK_DIR_NAME}" ]; then
  echo "[알림] ${TARGET_JDK_DIR}/${TEMP_JDK_DIR_NAME} 경로에 동일한 버전의 JDK${JDK_VERSION}(이/가) 설치되어있습니다."
  echo "[알림] ${TEMP_JDK_DIR_NAME}를 제거 후 다시 설치합니다."
  rm -rf ${TARGET_JDK_DIR}/${TEMP_JDK_DIR_NAME}  
fi

mkdir -p ${TARGET_JDK_DIR}/${TEMP_JDK_DIR_NAME}
mv ${TEMP_JDK_DIR_EXTRACT}/${TEMP_JDK_DIR_NAME} ${TARGET_JDK_DIR}
cd ${JDK_ROOT}
ln -s archive/${JDK_VERSION}/${TEMP_JDK_DIR_NAME} ${JDK_VERSION}
