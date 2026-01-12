# update-versions.ps1 동작 요약

이 문서는 `update-versions.ps1`의 역할과 로직 흐름을 정리합니다.

## 목적
- `version.properties`에 정의된 `SUPPORTED_VERSIONS` 목록을 읽고
- 각 버전의 최신 Temurin JDK(linux x64, hotspot) 다운로드 URL을 Adoptium API로 조회한 뒤
- 파일의 `JDK_URL_<버전>` 항목을 최신 링크로 교체 또는 추가합니다.

## 사용 방법
```powershell
# PowerShell에서 실행
pwsh ./update-versions.ps1               # 기본: version.properties
pwsh ./update-versions.ps1 -FilePath ./version.properties

# Windows에서 배치 파일로 실행
./update-versions.bat
```

## 로직 흐름
1. **입력 확인**: `-FilePath`로 지정한 `version.properties` 존재 여부를 검사합니다.
2. **버전 목록 파싱**: 파일에서 `SUPPORTED_VERSIONS="..."`를 정규식으로 추출하여 공백 단위로 버전 리스트를 만듭니다.
3. **API 조회 및 링크 검증** (버전별 반복):
   - 호출 URL: `https://api.adoptium.net/v3/assets/latest/<ver>/hotspot?architecture=x64&os=linux&image_type=jdk`
   - `Invoke-RestMethod`로 JSON을 받아 첫 번째 항목의 `binary.package.link`를 추출합니다.
   - `Invoke-WebRequest -Method Head`로 해당 링크가 HTTP 200인지 확인하고, 실패 시 즉시 오류 종료합니다.
4. **파일 갱신**:
   - 기존 라인을 순회하며 `JDK_URL_<ver>=...` 패턴을 만나면 새 링크로 교체하고, 처리된 버전은 목록에서 제거합니다.
   - 아직 파일에 없던 버전이 남아 있다면 `JDK_URL_<ver>=...` 라인을 파일 끝에 추가합니다.
5. **저장**: 수정된 내용을 원본 경로에 덮어쓰고 "Updated <파일명>" 메시지를 출력합니다.

## 전제 및 주의사항
- 네트워크로 Adoptium API와 GitHub 릴리스에 접근 가능해야 합니다.
- 링크 HEAD 검증을 하므로 프록시/방화벽이 HTTP HEAD를 막는 환경에서는 실패할 수 있습니다.
- 재시도 로직은 기본 포함되어 있지 않습니다. 간헐적 504/타임아웃이 잦다면 재시도(백오프) 추가를 고려하세요.

## 관련 파일
- 스크립트: [update-versions.ps1](../update-versions.ps1)
- 배치 래퍼: [update-versions.bat](../update-versions.bat)
- 설정 예시: [version.properties](../version.properties)
