# AutoSpot Hands-On Guideline on Tech Friday

> ## AutoSpot 서비스 사용을 위한 AWS Account 계정연결   
<details>
 <summary>Step1. Cost Management > AutoSpot 메뉴 클릭</summary>
</details> 
<details>
 <summary>Step2. 계정 추가 버튼 클릭</summary>
</details> 
<details>
 <summary>Step3. CloudFormation 사용 탭</summary>

    1. 템플릿 열기 
    2. 연결할 AWS Account 계정에 해당되는 IAM User 로 로그인
    3. 스택생성 동의 후 스택생성 클릭  
     
![Approve](https://user-images.githubusercontent.com/60588746/73698971-edf77100-4725-11ea-8686-31077386feb5.png)

    4. 출력 탭에서 값 복사

![autospot_role_arn](https://user-images.githubusercontent.com/60588746/73699396-087e1a00-4727-11ea-8f9e-1f0d39649cdf.png)


    5. 역할 ARN 복사 후 붙여 넣기 후 추가 

![paste_role_arn](https://user-images.githubusercontent.com/60588746/73699503-598e0e00-4727-11ea-9b73-ed3005f16e07.png)

</details> 







> ## Spot Analyzer 를 통한 Stateless Elastigroup 생성
>   - ### Appication Load Balancer 
>   - ### Auto Scaling Group 
>   - ### ASG Clone 을 통한 Elastigroup 






