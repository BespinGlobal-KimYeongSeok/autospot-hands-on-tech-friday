# AutoSpot Hands-On Guideline on Tech Friday

> ## AutoSpot 서비스 사용을 위한 AWS Account 계정연결   
<h3><details><summary>Step 1. Cost Management > AutoSpot 메뉴 클릭</summary>
 
 ![cm_autospot_menu](https://user-images.githubusercontent.com/60588746/73699880-5ba49c80-4728-11ea-95e0-dee85714d591.png) 
* * *
</details>
</h3> 

<h3>
<details>
 <summary>Step 2. 계정 추가 버튼 클릭</summary>

![btn_add_account](https://user-images.githubusercontent.com/60588746/73699957-8989e100-4728-11ea-9847-9039da73f508.png)
* * *

</details> 
</h3>

<h3>
<details>
 <summary>Step 3. CloudFormation 사용 탭으로 연결계정 추가</summary>

    1. 템플릿 열기 
    2. 연결할 AWS Account 계정에 해당되는 IAM User 로 로그인
    3. 스택생성 동의 후 스택생성 클릭  
     
![Approve](https://user-images.githubusercontent.com/60588746/73698971-edf77100-4725-11ea-8686-31077386feb5.png)

* * *
    4. 출력 탭에서 값 복사

![autospot_role_arn](https://user-images.githubusercontent.com/60588746/73699396-087e1a00-4727-11ea-8f9e-1f0d39649cdf.png)

* * *
    5. 역할 ARN 복사 후 붙여 넣기 후 추가 버튼 클릭 후 계정등록 계속 진행
* * *
![paste_role_arn](https://user-images.githubusercontent.com/60588746/73699692-d15c3880-4727-11ea-9f3a-badf5cc37dcd.png)
</details> 
</h3>

<h3>
<details>
 <summary>Step 4. 연결 계정목록 확인</summary>

![account_list](https://user-images.githubusercontent.com/60588746/73700081-eb4a4b00-4728-11ea-86ff-12d450002697.png)
* * *
</details> 
</h3>

<h3>
<details>
 <summary>Step 5. 연결계정별 AutoSpot 관리콘솔 진입</summary>

    1. 관리할 연결 계정을 목록에서 클릭
    2. 관리콘솔 화면 이동 후 초기화면 확인
* * *
![autospot_entry](https://user-images.githubusercontent.com/60588746/73700080-eb4a4b00-4728-11ea-9d93-b58651a79b68.png)
* * *
</details> 
</h3>
</h3>

# 
# 


> ## Spot Analyzer 를 통한 Stateless Elastigroup 생성
<h3>
 <details>
 <summary>Step 1. 사전 환경 구성</summary>  

* <details>
    <summary>AWS 관리 콘솔 이용하기</summary> 


   * [AWS Console Link](https://aws.amazon.com/console/) 로그인 후 진행
     * Application Load Balancer 생성
       * [공식가이드참조](https://docs.aws.amazon.com/ko_kr/elasticloadbalancing/latest/application/create-application-load-balancer.html)
         * 로드 밸런서 메뉴  
          ![alb_menu](https://user-images.githubusercontent.com/60588746/74622365-ea330800-5183-11ea-8127-c3de71094853.png)
          * * *
         * 로드 밸런스 생성 버튼
           ![alb_create_button](https://user-images.githubusercontent.com/60588746/74622396-f8812400-5183-11ea-97c0-1788c7481668.png)
           * * *
         * 로드 밸런서 종류 선택
           ![alb_type_selection](https://user-images.githubusercontent.com/60588746/74622408-08006d00-5184-11ea-822d-60d8ee907a2f.png)
           * * *
         * 로드밸런서 세부 구성
           ![alb_name_listener_az](https://user-images.githubusercontent.com/60588746/74622416-151d5c00-5184-11ea-9882-4f299ca66363.png)
           * * *
         * 보안구성 생략
           ![alb_creation_ssl](https://user-images.githubusercontent.com/60588746/74622455-31b99400-5184-11ea-9c9f-a1565523f7db.png)
           * * *
         * 기본 보안 그룹 설정
           ![alb_creation_security_group_default](https://user-images.githubusercontent.com/60588746/74622464-3aaa6580-5184-11ea-86a5-425780dd23ff.png)
           * * *
         * 로드밸런서 라우팅 설정
           ![alb_creation_routing](https://user-images.githubusercontent.com/60588746/74622476-439b3700-5184-11ea-85ea-565dafb16927.png)
           * * *
         * 대상그룹설정은 비워놓기
           ![alb_creation_targetgroup_empty](https://user-images.githubusercontent.com/60588746/74622480-4ac24500-5184-11ea-8ea7-5b3215e8638a.png)
           * * *
         * 검토
           ![alb_creation_review](https://user-images.githubusercontent.com/60588746/74622489-57df3400-5184-11ea-9d5a-114e9207d6cf.png)
          * * *
     * Auto Scaling Group 시작구성 생성
       * [공식가이드참조](https://docs.aws.amazon.com/ko_kr/autoscaling/ec2/userguide/create-asg-ec2-wizard.html)
         * 시작구성 생성 메뉴
           ![asg_config_create_menu](https://user-images.githubusercontent.com/60588746/74622514-79402000-5184-11ea-8684-6a063aaa7600.png)
           * * *
         * 시작구성 인트턴스 AMI 는 Amazon Linux 2 선택
           ![asg_config_ami_amazonlinux2](https://user-images.githubusercontent.com/60588746/74622548-9e349300-5184-11ea-9c61-65dd1da096a7.png)
           * * *
         * 시작구성 인트턴스 타입 선택
           ![asg_config_instancetype](https://user-images.githubusercontent.com/60588746/74622668-04b9b100-5185-11ea-96f7-9ed7228de953.png)
           * * *
         * 세부정보 구성
           * 이름입력
           ![asg_config_name](https://user-images.githubusercontent.com/60588746/74622697-29158d80-5185-11ea-8fc1-a2158a04df3c.png)
          * 사용자 데이터 복사 붙여넣기 [링크](https://github.com/bespinglobal-opsnow/autospot-hands-on-tech-friday/blob/master/asg-alb-listener-targetgroup/instance-setup.sh)
          <img width="1506" alt="user_data" src="https://user-images.githubusercontent.com/60588746/74796450-f2b64a80-530b-11ea-8a90-a14dd583729a.png">


           * * *
         * 시작구성 스토리지 구성
           ![asg_config_storage](https://user-images.githubusercontent.com/60588746/74622712-39c60380-5185-11ea-9f86-9e998bc11c46.png)
           * * *
         * 시작구성 보안그룹 구성
           ![asg_config_default_security_group](https://user-images.githubusercontent.com/60588746/74622747-56623b80-5185-11ea-8c5b-15f7e3509659.png)
           * * *
         * 시작구성 검토
           ![asg_config_review](https://user-images.githubusercontent.com/60588746/74622760-5feba380-5185-11ea-8632-e48ed3ebd80c.png)
          * * *

      * Auto Scaling Group 생성
        * 상세구성
          ![asg_details](https://user-images.githubusercontent.com/60588746/74622835-9d503100-5185-11ea-8317-f31b2e12cb24.png)
          * * *
        * 시작구성 오토스케일링 그대로 유지
          ![asg_scaling_policy](https://user-images.githubusercontent.com/60588746/74622841-a04b2180-5185-11ea-8a5a-c5e5fbea0f21.png)
          * * *
        * 오토스케일링 생성 검토
          ![asg_creation_review](https://user-images.githubusercontent.com/60588746/74622844-a3461200-5185-11ea-8e12-8505f30217c9.png)
          * * *
        * 생성 성공 확인
          ![asg_creation_success](https://user-images.githubusercontent.com/60588746/74622852-a5a86c00-5185-11ea-8520-f93a637ac7b7.png)
          * * *


     * Auto Scaling Group을 Load Balancer 에 연결
       * [공식가이드참조](https://docs.aws.amazon.com/ko_kr/autoscaling/ec2/userguide/attach-load-balancer-asg.html) 
          * AutoScalingGroup 편집  
            <img width="1027" alt="asg_edit_button" src="https://user-images.githubusercontent.com/60588746/74623209-0f754580-5187-11ea-89d6-9570cc594f02.png">
          * * *
          * 대상그룹 추가  
            <img width="625" alt="asg_edit_targetgroup" src="https://user-images.githubusercontent.com/60588746/74623212-113f0900-5187-11ea-8c9a-6268a58bcbf1.png">
          * * *
    </details>

* <details>
    <summary>AWS CLI 이용하기</summary> 

    * Git 설치 
      *  Mac  
           * Step 1 – Homebrew 설치
             * Terminal 윈도우에서 다음 명령어 실행  
               `$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`       
               `$ brew doctor`      
           * Step 2 – Git 설치
               * Terminal 윈도우에서 다음 명령어 실행  
               `$ brew install git"`
      *  Windows
          * Step 1 – [Chocolatey 설치](https://chocolatey.org/docs/installation)
            * 관리자 권한으로 cmd.exe 또는 powershell.exe 실행
              * 다음 명령줄 복사 후 붙여넣고 실행
                * cmd.exe 사용시  
                  * `@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command " [System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"`       
                  
                * powershell.exe 사용시  
                
                  * `Get-ExecutionPolicy` 실행 결과 값이 `Restricted` 인경우 
                    `Set-ExecutionPolicy AllSigned` 또는 `Set-ExecutionPolicy Bypass -Scope Process` 실행.

                  * `Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`
              
              
          * Step 2 – Git 설치
              * Terminal 윈도우에서 다음 명령어 실행  
               `choco install git` 
              



    * AWS CLI 설치 
      * AWS 공식 가이드 참조 
          * [MAC](https://docs.aws.amazon.com/cli/latest/userguide/install-macos.html)  
          * [Windows](https://docs.aws.amazon.com/cli/latest/userguide/install-windows.html)

    * AWS Configure 구성 
      * AWS IAM ACCESSKEY 생성하기  
        * AWS IAM 관리 콘솔에서 사용자 클릭
        <img width="1667" alt="iam_user_click" src="https://user-images.githubusercontent.com/60588746/74792645-61da7180-5301-11ea-851e-ddf928c7c6d1.png">
        * * *
        * 보안자격증명 탭에서 액세스키 만들기 클릭
        <img width="1675" alt="button_create_accesskey" src="https://user-images.githubusercontent.com/60588746/74792798-d0b7ca80-5301-11ea-8423-c864859b5245.png">
        * * *
        * 생성된 액세스키, 액세스 시크릿키 복사해놓기
        <img width="1675" alt="create_accesskey_success" src="https://user-images.githubusercontent.com/60588746/74792843-e927e500-5301-11ea-81a3-8c697afa735d.png">
        * * *


      * Terminal Window 에서 다음 명령어 실행 후 ACCESS_KEY, SECRET_ACCESS_KEY, Default Region 입력. 
        * `$ aws configure`
        * ![aws_configure](https://user-images.githubusercontent.com/60588746/74112543-f1d13a80-4be0-11ea-9872-316d936b4abd.png)
        * * *
      
    
    * 제공된 스크립트로 Application Load Balancer, Target Group, Listener, AutoScalingGroup 생성하기  
      * `$ git clone https://github.com/BespinGlobal-KimYeongSeok/autospot-hands-on-tech-friday`  
      * `$ cd autospot-hands-on-tech-friday/asg-alb-listener-targetgroup`  
      * `$ source create_alb_targetgroup_asg.sh`  
      
    </details>

</details> 
</h3>


<h3>
 <details>
 <summary>Step 2. Spot Analyzer 로 Discover & Clone </summary>

  
  * Additional Service > Spot Analyzer 들어가기
    ![spot_analyzer_menu](https://user-images.githubusercontent.com/60588746/74618357-b56b8480-5174-11ea-81b2-4e43dd83742c.png)
* * *
  * Rediscover Resources 로 생성한 자원 발견하기
    ![rediscover](https://user-images.githubusercontent.com/60588746/74618691-2c554d00-5176-11ea-890d-b988cd02bfb2.png)
* * *
  * 발견된 AutoScalingGroup 클론하기
    ![clone_asg](https://user-images.githubusercontent.com/60588746/74618453-33c82680-5175-11ea-97aa-36f772624eca.png)
* * *
  * 리전과 이름 확인 후 Next 버튼 클릭
    ![next_clone_asg](https://user-images.githubusercontent.com/60588746/74618569-c9fc4c80-5175-11ea-94ae-30cea67aab7b.png)
* * *
  * Elastigroup 요약정보 확인
    ![summary](https://user-images.githubusercontent.com/60588746/74618572-cc5ea680-5175-11ea-87fd-624e648c1e10.png)
* * *
  * Elastigroup 생성 성공 확인
    ![create_success](https://user-images.githubusercontent.com/60588746/74618575-cec10080-5175-11ea-81fc-5690d56e04b3.png)
* * *
</details> 
</h3>

<h3>
 <details>
 <summary>Step 3. Elastigroup 확인  </summary>

  * Elastigroup 상세정보확인
    ![elastigroup_created](https://user-images.githubusercontent.com/60588746/74618630-fca64500-5175-11ea-998a-672047c9b4d8.png)
  * * *
</details> 
</h3>

<h3>
 <details>
 <summary>Step 4. 자원 삭제  </summary>

  * Elastigroup 삭제
    <img width="1669" alt="choose_delete_esg" src="https://user-images.githubusercontent.com/60588746/74795043-3a3ad780-5308-11ea-839f-ac2aa9928a40.png">
    * * *
  * AWS 자원 삭제
    * AWS 관리콘솔에서 직접 삭제 
      * 삭제대상
        * 로드밸런서
        * 대상그룹
        * AutoScaling그룹
        * 시작구성
        * KeyPair
    
    * 제공된 스크립트 실행으로 삭제
    `$ ./cleanse_alb_targetgroup_asg.sh`  
    * * *
</details> 
</h3>




___ 