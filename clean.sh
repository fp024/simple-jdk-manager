#!/bin/sh

JDK_ROOT=$(pwd)
ARCHIVE_DIR="${JDK_ROOT}/archive"
TEMP_DIR="${JDK_ROOT}/temp"

# version.properties 파일이 없을 때만 다운로드
if [ ! -f "version.properties" ]; then
  wget -O version.properties "https://raw.githubusercontent.com/fp024/simple-jdk-manager/master/version.properties" || { echo "[오류] version.properties 파일 다운로드에 실패했습니다."; exit 1; }
fi

# version.properties에서 지원 버전 목록 가져오기
if [ -f "${JDK_ROOT}/version.properties" ]; then
  #set -a
  . ./version.properties
  #set +a
  # 💡환경 변수들이 현재 셀 영역 내에서만 사용되서 환경변수 export가 필요없을 것 같다.
  VERSIONS="${SUPPORTED_VERSIONS}"
else
  echo "[오류] version.properties 파일이 존재하지 않습니다: ${JDK_ROOT}/version.properties"
  exit 1
fi

case "$1" in
  "") # 기능 1: 심볼릭 링크에 연결되지 않은 디렉토리 삭제
    echo "[알림] 심볼릭 링크에 연결되지 않은 디렉토리를 삭제합니다..."
    # 삭제하지 않을 경로 목록 생성
    EXCLUDE_DIRS=""

    for VERSION in $VERSIONS; do
      if [ -L "${JDK_ROOT}/${VERSION}" ]; then
        TARGET=$(readlink "${JDK_ROOT}/${VERSION}")
        EXCLUDE_DIRS="${EXCLUDE_DIRS} ${JDK_ROOT}/${TARGET}"                # 심볼릭 링크 타깃 추가
        EXCLUDE_DIRS="${EXCLUDE_DIRS} ${JDK_ROOT}/$(dirname "${TARGET}")"   # 타깃의 상위 디렉토리 추가
        echo "[알림] 심볼릭 링크 ${VERSION} -> ${TARGET} 유지"
      else
        echo "[알림] 심볼릭 링크 ${VERSION}가 존재하지 않습니다."
      fi
    done

    # archive 디렉토리에서 삭제 제외 목록에 없는 디렉토리 삭제
    for DIR in "${ARCHIVE_DIR}"/*/*; do
      # DIR이 삭제 제외 목록에 있는지 확인      
      if ! echo "$EXCLUDE_DIRS" | grep -q -w "$DIR"; then
        echo "[알림] 삭제: $DIR"
        rm -rf "$DIR"
      else
        echo "[알림] 유지: $DIR"
      fi
    done
    ;;

"temp") # 기능 2: temp 삭제 (version.properties에 정의된 압축파일이 포함된 디렉토리는 유지)
    echo "[알림] temp($TEMP_DIR) 디렉토리를 정리합니다..."

    # version.properties 파일에서 압축 파일 이름 추출
    if [ -f "${JDK_ROOT}/version.properties" ]; then
      # URL에서 마지막 '/' 이후의 파일명을 추출
      EXCLUDE_FILES=$(awk -F'/' '{print $NF}' "${JDK_ROOT}/version.properties")
    else
      echo "[오류] version.properties 파일이 존재하지 않습니다: ${JDK_ROOT}/version.properties"
      exit 1
    fi

    # 유지해야 할 디렉토리 및 파일 목록 생성
    EXCLUDE_DIRS=""
    EXCLUDE_FILES_PATH=""
    for FILE in $EXCLUDE_FILES; do
      FILE_PATH=$(find "$TEMP_DIR" -type f -name "$FILE")
      if [ -n "$FILE_PATH" ]; then
        EXCLUDE_FILES_PATH="${EXCLUDE_FILES_PATH} $FILE_PATH"
        EXCLUDE_DIRS="${EXCLUDE_DIRS} $(dirname "$FILE_PATH")"
      fi
    done

    # temp 디렉토리 내 파일 및 디렉토리 삭제
    find "$TEMP_DIR" -mindepth 1 | while read -r ITEM; do
      # 유지해야 할 파일인지 확인
      if echo "$EXCLUDE_FILES_PATH" | grep -q -w "$ITEM"; then
        echo "[알림] 유지: $ITEM"
        continue
      fi

      # 유지해야 할 디렉토리인지 확인
      IS_EXCLUDED=false
      for EXCLUDE_DIR in $EXCLUDE_DIRS; do
        if [ "$ITEM" = "$EXCLUDE_DIR" ]; then
          IS_EXCLUDED=true
          break
        fi
      done

      if [ "$IS_EXCLUDED" = true ]; then
        echo "[알림] 유지: $ITEM"
      else
        echo "[알림] 삭제: $ITEM"
        rm -rf "$ITEM"
      fi
    done

    echo "[완료] temp 디렉토리가 정리되었습니다."
    ;;

  "all") # 기능 3: 모든 심볼릭 링크 및 archive, temp 디렉토리 삭제
    echo "[알림] 모든 심볼릭 링크와 archive, temp 디렉토리를 삭제합니다..."
    for VERSION in $VERSIONS; do
      if [ -L "${JDK_ROOT}/${VERSION}" ]; then
        echo "[알림] 심볼릭 링크 삭제: ${VERSION}"
        rm "${JDK_ROOT}/${VERSION}"
      fi
    done
    echo "[알림] temp($ARCHIVE_DIR) 디렉토리를 삭제합니다..."
    rm -rf "${ARCHIVE_DIR}"

    echo "[알림] temp($TEMP_DIR) 디렉토리를 삭제합니다..."
    mkdir -p "$TEMP_DIR"
    rm -rf "$TEMP_DIR"

    if [ -f "${JDK_ROOT}/version.properties" ]; then
      echo "[알림] version.properties 파일을 삭제합니다..."
      rm "${JDK_ROOT}/version.properties"
    fi

    echo "[완료] archive 디렉토리와 모든 심볼릭 링크가 삭제되었습니다."
    ;;

    *) # 기능 4: 특정 버전의 모든 관련 파일 삭제 (심볼릭 링크, archive, temp)
    VERSION_TO_CLEAN="$1"
    
    # 지원되는 버전인지 확인
    if echo "$VERSIONS" | grep -q -w "$VERSION_TO_CLEAN"; then
      echo "[알림] ${VERSION_TO_CLEAN} 버전의 관련 파일들을 삭제합니다..."
      
      # 1. 심볼릭 링크 삭제
      if [ -L "${JDK_ROOT}/${VERSION_TO_CLEAN}" ]; then
        TARGET=$(readlink "${JDK_ROOT}/${VERSION_TO_CLEAN}")
        echo "[알림] 심볼릭 링크 삭제: ${VERSION_TO_CLEAN} -> ${TARGET}"
        rm "${JDK_ROOT}/${VERSION_TO_CLEAN}"
        
        # 2. archive 디렉토리에서 해당 버전의 디렉토리 삭제
        TARGET_DIR="${JDK_ROOT}/${TARGET}"
        if [ -d "$TARGET_DIR" ]; then
          echo "[알림] archive 디렉토리 삭제: $TARGET_DIR"
          rm -rf "$TARGET_DIR"
        fi
        
        # 3. archive의 상위 디렉토리가 비어있으면 삭제
        TARGET_PARENT="${JDK_ROOT}/$(dirname "${TARGET}")"
        if [ -d "$TARGET_PARENT" ] && [ -z "$(ls -A "$TARGET_PARENT")" ]; then
          echo "[알림] 빈 디렉토리 삭제: $TARGET_PARENT"
          rm -rf "$TARGET_PARENT"
        fi
      else
        echo "[알림] 심볼릭 링크 ${VERSION_TO_CLEAN}가 존재하지 않습니다."
      fi
      
      # 4. temp/버전 디렉토리 삭제
      TEMP_VERSION_DIR="${TEMP_DIR}/${VERSION_TO_CLEAN}"
      if [ -d "$TEMP_VERSION_DIR" ]; then
        echo "[알림] temp/${VERSION_TO_CLEAN} 디렉토리 삭제: $TEMP_VERSION_DIR"
        rm -rf "$TEMP_VERSION_DIR"
      fi
      
      echo "[완료] ${VERSION_TO_CLEAN} 버전의 관련 파일들이 삭제되었습니다."
    else
      echo "[오류] 잘못된 명령입니다. 사용법: clean.sh [temp 버전|all|버전]"
      echo "지원되는 버전: $VERSIONS"
      exit 1
    fi
    ;;
esac