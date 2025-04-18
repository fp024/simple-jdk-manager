#!/bin/sh

JDK_ROOT=$(pwd)
ARCHIVE_DIR="${JDK_ROOT}/archive"
TEMP_DIR="${ARCHIVE_DIR}/temp"

# 상수로 버전 목록 정의
VERSIONS="8 11 17 21"

case "$1" in
  "") # 기능 1: 심볼릭 링크에 연결되지 않은 디렉토리 삭제
    echo "[알림] 심볼릭 링크에 연결되지 않은 디렉토리를 삭제합니다..."
    for VERSION in $VERSIONS; do
      if [ -L "${JDK_ROOT}/${VERSION}" ]; then
        TARGET=$(readlink "${JDK_ROOT}/${VERSION}")
        echo "[알림] 심볼릭 링크 ${VERSION} -> ${TARGET} 유지"
      else
        echo "[알림] 심볼릭 링크 ${VERSION}가 존재하지 않습니다."
      fi
    done

    # archive 디렉토리에서 심볼릭 링크가 가리키지 않는 디렉토리 삭제
    for DIR in "${ARCHIVE_DIR}"/*; do
      # temp 디렉토리는 삭제 대상에서 제외
      if [ "$DIR" = "$TEMP_DIR" ]; then
        echo "[알림] temp 디렉토리는 삭제하지 않습니다."
        continue
      fi

      if [ -d "$DIR" ] && [ ! -L "$DIR" ]; then
        LINKED=false
        for VERSION in $VERSIONS; do
          if [ -L "${JDK_ROOT}/${VERSION}" ] && [ "$(readlink "${JDK_ROOT}/${VERSION}")" = "$DIR" ]; then
            LINKED=true
            break
          fi
        done
        if [ "$LINKED" = false ]; then
          echo "[알림] 삭제: $DIR"
          rm -rf "$DIR"
        fi
      fi
    done
    ;;

  "temp") # 기능 2: archive/temp 삭제
    echo "[알림] archive/temp 디렉토리를 삭제합니다..."
    rm -rf "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"
    echo "[완료] archive/temp 디렉토리가 초기화되었습니다."
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