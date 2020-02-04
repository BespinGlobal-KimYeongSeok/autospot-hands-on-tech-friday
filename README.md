# AutoSpot Hands-On Guideline on Tech Friday

> ## AutoSpot 서비스 사용을 위한 AWS Account 계정연결   
<h3><details><summary>Step1. Cost Management > AutoSpot 메뉴 클릭</summary>
 
 ![cm_autospot_menu](https://user-images.githubusercontent.com/60588746/73699880-5ba49c80-4728-11ea-95e0-dee85714d591.png) 

</details> 

<details>
 <summary>Step2. 계정 추가 버튼 클릭</summary>

![btn_add_account](https://user-images.githubusercontent.com/60588746/73699957-8989e100-4728-11ea-9847-9039da73f508.png)


</details> 
<details>
 <summary>Step3. CloudFormation 사용 탭으로 연결계정 추가</summary>

    1. 템플릿 열기 
    2. 연결할 AWS Account 계정에 해당되는 IAM User 로 로그인
    3. 스택생성 동의 후 스택생성 클릭  
     
![Approve](https://user-images.githubusercontent.com/60588746/73698971-edf77100-4725-11ea-8686-31077386feb5.png)

    4. 출력 탭에서 값 복사

![autospot_role_arn](https://user-images.githubusercontent.com/60588746/73699396-087e1a00-4727-11ea-8f9e-1f0d39649cdf.png)


    5. 역할 ARN 복사 후 붙여 넣기 후 추가 버튼 클릭 후 계정등록 계속 진행

![paste_role_arn](https://user-images.githubusercontent.com/60588746/73699692-d15c3880-4727-11ea-9f3a-badf5cc37dcd.png)

</details> 

<details>
 <summary>Step4. 연결 계정목록 확인</summary>

![account_list](https://user-images.githubusercontent.com/60588746/73700081-eb4a4b00-4728-11ea-86ff-12d450002697.png)

</details> 

<details>
 <summary>Step5. 연결계정별 AutoSpot 관리콘솔 진입</summary>

    1. 관리할 연결 계정을 목록에서 클릭
    2. 관리콘솔 화면 이동 후 초기화면 확인

![autospot_entry](https://user-images.githubusercontent.com/60588746/73700080-eb4a4b00-4728-11ea-9d93-b58651a79b68.png)

</details> 
</h3>


> ## Spot Analyzer 를 통한 Stateless Elastigroup 생성
>   - ### Appication Load Balancer 
>   - ### Auto Scaling Group 
>   - ### ASG Clone 을 통한 Elastigroup 






