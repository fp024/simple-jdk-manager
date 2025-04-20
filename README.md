# 단순 JDK 관리자

> sdkman을 사용하긴 하지만, JDK같은 경우는 메이저 버전 별로 몇가지를 유지할 필요가 있는데, 그런 환경에서는 sdkman이 불편할 때가 있어서...
>
> 이번에 그동안 수동으로 했던일을 스크립트로 만들었다. 
>
> 물론 전자동은 아니고, 그동안 버전 업그레이드 마다 짜증나던 수작업의 일부를 어느정도 바꿔봤다...😅





## 사용 방법

### 스크립트 설치

`./install.sh {JDK들을 관리할 루트 경로}`

```sh
./install.sh /usr/local/JDK/
```



### JDK 설치

먼저의 예시대로 스크립트를 설치했다면 `/usr/local/JDK` 경로에 `update.sh`가 복사됨

```sh
cd /usr/local/JDK
./update.sh 17
```

`./update.sh {JDK 버전번호}` 와 같은 형식으로 명령을 실행해주면 다음과 같은 형식으로 설치해줌.

아래는 8, 11, 17, 21 버전을 각각 설치한 경우 다음과 같은 디렉토리 구조를 가지게됨.

```
  /usr/local/JDK
    ├── 11 -> archive/11/jdk-11.0.27+6/
    ├── 17 -> archive/17/jdk-17.0.15+6/
    ├── 21 -> archive/21/jdk-21.0.7+6/
    ├── 8 -> archive/8/jdk8u452-b09/
    ├── archive/
    │   ├── 11/
    │   │   └── jdk-11.0.27+6/
    │   ├── 17/
    │   │   └── jdk-17.0.15+6/
    │   ├── 21/
    │   │   └── jdk-21.0.7+6/
    │   └── 8/
    │       └── jdk8u452-b09/
    ├── clean.sh*
    ├── temp/
    │   ├── 11/
    │   │   ├── OpenJDK11U-jdk_x64_linux_hotspot_11.0.27_6.tar.gz
    │   │   └── extract/
    │   ├── 17/
    │   │   ├── OpenJDK17U-jdk_x64_linux_hotspot_17.0.15_6.tar.gz
    │   │   └── extract/
    │   ├── 21/
    │   │   ├── OpenJDK21U-jdk_x64_linux_hotspot_21.0.7_6.tar.gz
    │   │   └── extract/
    │   └── 8/
    │       ├── OpenJDK8U-jdk_x64_linux_hotspot_8u452b09.tar.gz
    │       └── extract/
    ├── update.sh*
    └── version.properties
```
* `temp/${버전번호}` 경로
  * 압축 파일이 다운로드 되는 경로
* `temp/${버전번호}/extrat`
  * 압축 파일을 푸는 경로
  * 실행할 때마다 갱신함



### 버전 유지관리 파일

* https://github.com/fp024/simple-jdk-manager/blob/master/version.properties

  ```properties
  JDK_URL_8=https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u452-b09/OpenJDK8U-jdk_x64_linux_hotspot_8u452b09.tar.gz
  JDK_URL_11=https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.27%2B6/OpenJDK11U-jdk_x64_linux_hotspot_11.0.27_6.tar.gz
  JDK_URL_17=https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.15%2B6/OpenJDK17U-jdk_x64_linux_hotspot_17.0.15_6.tar.gz
  JDK_URL_21=https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%2B6/OpenJDK21U-jdk_x64_linux_hotspot_21.0.7_6.tar.gz
  ```

JDK 벤더는 temurin만 사용하고 있는데, 시간이 지나서 버전업이 되면 이 파일을 버전업하고 github에 반영해주고...

각 머신에서 `update.sh {버전명}`으로 업데이트 해주면 된다.

> **😅 해깔릴 수 있는 부분**
>
> `install.sh`를 실행할 때, JDK 설치경로로 복사되는게 아니고, `version.properties`는 `update.sh` 실행시 항상 github에서 최신버전을 받아온다.  



### 임시파일 정리

1. JDK 설치 경로의 심볼릭 링크와 연결이 되어있지 않은 archive 이하의 하위 디렉토리 및 파일을 제거한다.

   ```sh
   ./clean.sh
   ```

   > 💡 `version.properties`의 내용이 업데이트 되었을 때, 심볼릭 링크를 재작성하는데, 이 명령을 실행해서 archive 이하의 이전 버전의 JDK를 정리 할 수 있다.

2. temp 디렉토리의 다운로드한 압축 파일 정리

   ```sh
   ./clean.sh temp
   ```

   > temp의 모든 내용을 지우진 않고, `version.properties`에 명시된 URL의 파일만 남기고 나머지는 정리한다.

3. 전체 정리

   ```sh
   ./clean all
   ```

   > 모든 심볼릭 링크와 archive, temp 디렉토리를 삭제한다.
   >
   > 이 명령을 실행하면 JDK 설치 경로에 `clean.sh`, `update.sh`, `version.properties`만 남게 된다.





## SDKMAN!과 연동

**SDKMAN!**과 연동해서 사용하면 현재 터미널의 JAVA_HOME을 쉽게 바꿀 수 있는 장점이 있는데... 다음과 같이 하면된다.

```sh
sdkman install java 17-tem-local /usr/local/JDK/17
```

* java 바로 우측의 버전이름은 기본의 이름과 겹치지 않게 `-local`이란 접미어를 붙여줌
  * `17-tem-local`
* 그 다음에는 로컬의 JDK의 경로를 넣어줌.
  * `/usr/local/JDK/17`





---

## 의견

로컬환경에서는 항상 해당 메이저 버전의 최신으로만 쓰기로해서, 스크립트도 그것에 맞춰서 단순하게 만들어졌는데..

개선은 필요할 때마다 천천히 해보자! 😊

* clean.sh에 대한 개선을 VSCode WSL + Copilot과 같이 진행했다. 👍
