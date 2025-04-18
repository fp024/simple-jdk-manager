#!/bin/sh

JDK_ROOT=$(pwd)
ARCHIVE_DIR="${JDK_ROOT}/archive"
TEMP_DIR="${JDK_ROOT}/temp"

# 상수로 버전 목록 정의
VERSIONS="8 11 17 21"

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

  "temp") # 기능 2: temp 삭제
    echo "[알림] temp($TEMP_DIR) 디렉토리를 삭제합니다..."
    mkdir -p "$TEMP_DIR"
    # rm -rf "$TEMP_DIR"
    echo "[완료] temp 디렉토리가 초기화되었습니다."
    ;;

  "all") # 기능 3: 모든 심볼릭 링크 및 archive 디렉토리 삭제
    echo "[알림] 모든 심볼릭 링크와 archive 디렉토리를 삭제합니다..."
    for VERSION in $VERSIONS; do
      if [ -L "${JDK_ROOT}/${VERSION}" ]; then
        echo "[알림] 심볼릭 링크 삭제: ${VERSION}"
        rm "${JDK_ROOT}/${VERSION}"
      fi
    done
    rm -rf "${ARCHIVE_DIR}"
    echo "[완료] archive 디렉토리와 모든 심볼릭 링크가 삭제되었습니다."
    ;;

  *) # 잘못된 명령어 처리
    echo "[오류] 잘못된 명령입니다. 사용법: clean.sh [temp|all]"
    exit 1
    ;;
esac