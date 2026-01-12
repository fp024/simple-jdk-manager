# update-versions 동작 요약

이 문서는 `update-versions.ps1`과 `update-versions.sh`의 역할과 로직 흐름을 정리합니다.

## 목적
- `version.properties`에 정의된 `SUPPORTED_VERSIONS` 목록을 읽고
- 각 버전의 최신 Temurin JDK(linux x64, hotspot) 다운로드 URL을 Adoptium API로 조회한 뒤
- 파일의 `JDK_URL_<버전>` 항목을 최신 링크로 교체 또는 추가합니다.

## 사용 방법

### PowerShell 버전 (Windows)
```powershell
# PowerShell에서 직접 실행
pwsh ./update-versions.ps1               # 기본: version.properties
pwsh ./update-versions.ps1 -FilePath ./version.properties

# Windows 배치 파일로 실행
./update-versions.bat
```

### Bash 버전 (Linux/WSL)
```bash
# 실행 권한 설정 (처음 한 번만)
chmod +x update-versions.sh

# 실행
./update-versions.sh                     # 기본: version.properties
./update-versions.sh version.properties
```

## 로직 흐름

### PowerShell 버전 (update-versions.ps1)
1. **입력 확인**: `-FilePath`로 지정한 `version.properties` 존재 여부를 검사합니다.
2. **버전 목록 파싱**: 파일에서 `SUPPORTED_VERSIONS="..."`를 정규식으로 추출하여 공백 단위로 버전 리스트를 만듭니다.
3. **API 조회 및 링크 검증** (버전별 반복):
   - 호출 URL: `https://api.adoptium.net/v3/assets/latest/<ver>/hotspot?architecture=x64&os=linux&image_type=jdk`
   - `Invoke-RestMethod`로 JSON을 받아 첫 번째 항목의 `binary.package.link`를 추출합니다.
   - `Invoke-WebRequest -Method Head`로 해당 링크가 HTTP 200인지 확인하고, 실패 시 즉시 오류 종료합니다.
4. **파일 갱신**:
   - 기존 라인을 순회하며 `JDK_URL_<ver>=...` 패턴을 만나면 새 링크로 교체하고, 처리된 버전은 딕셔너리에서 제거합니다.
   - 아직 파일에 없던 버전이 남아 있다면 `JDK_URL_<ver>=...` 라인을 파일 끝에 추가합니다.
5. **저장**: 수정된 내용을 원본 경로에 덮어쓰고 "Updated <파일명>" 메시지를 출력합니다.

### Bash 버전 (update-versions.sh)
1. **입력 확인**: 명령행 인자 또는 기본값 `version.properties` 존재 여부를 검사합니다.
2. **버전 목록 파싱**: `grep`과 `sed`로 파일에서 `SUPPORTED_VERSIONS="..."`를 추출합니다.
3. **API 조회 및 링크 검증** (버전별 반복, `fetch_and_validate_url()` 함수):
   - 호출 URL: `https://api.adoptium.net/v3/assets/latest/<ver>/hotspot?architecture=x64&os=linux&image_type=jdk`
   - `curl`로 JSON을 받아 `jq` 또는 `grep -oE`로 `.tar.gz`로 끝나는 다운로드 링크를 추출합니다.
   - `curl -I`로 해당 링크의 HTTP 상태 코드가 200인지 확인하고, 실패 시 오류 메시지를 출력 후 종료합니다.
4. **파일 갱신**:
   - 파일 라인을 순회하며 `JDK_URL_<ver>=...` 패턴을 정규식으로 매칭하고, 연관 배열에서 URL이 있으면 교체합니다.
   - 처리된 버전은 배열에서 제거(unset)하여 중복 추가를 방지합니다.
   - 아직 파일에 없던 버전이 남아 있다면 새 라인으로 추가합니다.
5. **저장**: 임시 파일을 원본 경로로 이동(mv)하고 "Updated <파일명>" 메시지를 출력합니다.

## 전제 및 주의사항

### 공통
- 네트워크로 Adoptium API와 GitHub 릴리스에 접근 가능해야 합니다.
- 링크 유효성 검증을 하므로 프록시/방화벽이 HTTP 헤드(또는 다운로드) 요청을 막는 환경에서는 실패할 수 있습니다.

### PowerShell 버전
- `.ps1` 파일 실행 정책이 허용되어야 합니다. 배치 래퍼(`update-versions.bat`)는 `-ExecutionPolicy Bypass`로 우회합니다.
- 재시도 로직은 기본 포함되어 있지 않습니다. 간헐적 504/타임아웃이 잦다면 재시도(백오프) 추가를 고려하세요.

### Bash 버전
- `curl` 필수, `jq` 선택 (없으면 `grep -oE`로 대체)
- `python3` 불필요 (이전 버전과 달리 grep/sed만 사용)
- WSL, Linux, git-bash에서 동작 가능

## 관련 파일
- PowerShell: [update-versions.ps1](../update-versions.ps1)
- 배치 래퍼: [update-versions.bat](../update-versions.bat)
- Bash: [update-versions.sh](../update-versions.sh)
- 설정 예시: [version.properties](../version.properties)
