# iPhone에 앱 설치 및 테스트 가이드

이 문서는 현재 개발 중인 '소리-빛 번역 AI' 앱을 실제 iPhone에 설치하여 테스트하는 방법을 안내합니다.

---

### 사전 준비물

1.  **Mac**: Xcode가 설치된 Mac 컴퓨터가 필요합니다.
2.  **Apple ID**: Apple Developer Program에 등록된 계정이 필요합니다. (무료 계정으로도 개인 기기 테스트는 충분히 가능합니다.)
3.  **iPhone**: 테스트에 사용할 iPhone.
4.  **USB 케이블**: Mac과 iPhone을 연결할 케이블.

---

### 설치 단계

#### 1단계: Xcode 프로젝트 열기

1.  Finder에서 프로젝트 폴더로 이동합니다.
2.  `RecordingSample.xcodeproj` 파일을 찾아 더블클릭하여 Xcode에서 엽니다.

#### 2단계: iPhone 연결 및 신뢰 설정

1.  USB 케이블을 사용하여 iPhone을 Mac에 연결합니다.
2.  iPhone 화면에 "이 컴퓨터를 신뢰하겠습니까?" 라는 팝업이 나타나면 **'신뢰'**를 탭하고, 필요시 암호를 입력합니다.

#### 3단계: 빌드 대상 기기 선택

1.  Xcode 상단 툴바에서, '▶︎' (Run) 버튼 옆에 있는 기기 목록을 클릭합니다. (예: `iPhone 14 Pro`, `Any iOS Device` 등으로 표시되어 있을 수 있습니다.)
2.  나타나는 목록의 **맨 위**에 있는, 현재 연결된 본인의 iPhone을 선택합니다.

![Xcode Target Selection](https://i.imgur.com/9E4G2G6.png)
*(참고 이미지: Xcode 툴바에서 기기를 선택하는 예시)*

#### 4단계: 서명(Signing) 및 팀 설정 (가장 중요)

앱을 실제 기기에 설치하려면, 누가 이 앱을 만들었는지 Apple에 알려주는 '서명' 과정이 필요합니다.

1.  Xcode 왼쪽의 파일 탐색기(Project Navigator)에서 최상단에 있는 프로젝트 아이콘(`RecordingSample`)을 클릭합니다.
2.  중앙 에디터 영역에서 **TARGETS** 목록의 `RecordingSample`을 선택합니다.
3.  상단 탭에서 **"Signing & Capabilities"**를 선택합니다.
4.  **"Team"** 드롭다운 메뉴를 클릭하고, 본인의 Apple ID를 선택합니다.
    *   만약 목록에 본인의 Apple ID가 없다면, `Add an Account...`를 클릭하여 Xcode에 로그인해야 합니다.
    *   선택하면 Xcode가 대부분의 경우 자동으로 프로비저닝 프로파일(Provisioning Profile)을 생성하고 관리해줍니다. "Automatically manage signing"이 체크되어 있는지 확인하세요.

![Xcode Signing](https://i.imgur.com/sB6v2sB.png)
*(참고 이미지: Signing & Capabilities 설정 화면)*

#### 5단계: iPhone에서 '개발자 신뢰' 설정

처음으로 본인의 계정으로 빌드한 앱을 설치하는 경우, iPhone에서 해당 개발자를 신뢰하는 과정이 필요합니다.

1.  앱 설치 시도 후, iPhone에서 **`설정` > `일반` > `VPN 및 기기 관리`**로 이동합니다.
2.  '개발자 앱' 항목 아래에 있는 본인의 Apple ID 이메일 주소를 탭합니다.
3.  **"[본인 Apple ID]을(를) 신뢰함"**을 탭하고, 다시 한번 '신뢰'를 선택합니다.

이 과정은 최초 한 번만 수행하면 됩니다.

#### 6단계: 빌드 및 실행

1.  모든 설정이 완료되었으면, Xcode의 '▶︎' (Run) 버튼을 클릭합니다.
2.  Xcode가 앱을 빌드하여 연결된 iPhone에 자동으로 설치하고 실행합니다.
3.  이제 iPhone에서 앱이 정상적으로 작동하는지 테스트할 수 있습니다.

---

### 문제 해결 (Troubleshooting)

*   **"Could not launch “RecordingSample”" 오류가 발생하는 경우:**
    *   대부분 5단계('개발자 신뢰' 설정)가 완료되지 않았기 때문입니다. iPhone의 `설정`에서 개발자를 신뢰했는지 다시 확인해주세요.
*   **서명(Signing) 관련 오류가 발생하는 경우:**
    *   "Team"이 올바르게 선택되었는지, "Automatically manage signing"이 체크되어 있는지 확인하세요.
    *   Xcode를 완전히 종료했다가 다시 실행하거나, iPhone 연결을 해제했다가 다시 연결해보세요.
