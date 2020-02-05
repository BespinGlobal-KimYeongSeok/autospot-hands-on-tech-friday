#!/bin/zsh
REGION_CODE=(`eval "aws configure get region"`)
vared -p $'\n리전코드를 입력해 주세요.\n그냥 Enter 시 AWS Config에 설정된 값으로 진행합니다: ' -c REGION_CODE


echo $REGION_CODE

ALB_NAME="TestALB"
vared -p "ALB 이름을 입력해 주세요.: " -c ALB_NAME
echo $ALB_NAME

SUBNET_LIST="subnet-f830dcf6 subnet-33ba8b1d"
vared -p "공백으로 구분된 서브넷 아이디 리스트를 입력해 주세요. ex) subnet-f830dcf6 subnet-33ba8b1d: " -c SUBNET_LIST
echo $SUBNET_LIST

SG="sg-0c2e83738a5a18b1b"
vared -p "보안그룹 아이디를 입력해주세요 : " -c SG
echo $SG

SCRIPT="aws elbv2 create-load-balancer --name $ALB_NAME --subnets $SUBNET_LIST --security-groups $SG --region $REGION_CODE | jq -r '.LoadBalancers[].LoadBalancerArn'"

clb_response=$(eval $SCRIPT)
echo "response>>$clb_response"
alb_arn=$clb_response 
echo $alb_arn

result=$?
echo $result
if [ $result -eq 0 ]; then
    echo "ALB 생성에 성공하였습니다."
    local VPC_ID="vpc-3c450346"
    vared -p "대상그룹을 생성할 VPC ID를 입력해 주세요 :" -c VPC_ID
    echo $VPC_ID
    vared -p "대상그룹 이름을 입력해 주세요.:" -c TARGET_GROUP
    echo $TARGET_GROUP
    SCRIPT="aws elbv2 create-target-group --name $TARGET_GROUP --protocol HTTP --port 80 --vpc-id $VPC_ID | jq -r '.TargetGroups[].TargetGroupArn'"
    echo "Script: $SCRIPT"
    target_group_arn=$(eval $SCRIPT)    
    local result=$?
    if [ $result -eq 0 ]; then
        echo "대상그룹 생성에 성공하였습니다."

        echo "생성된 어플리케이션 로드 발란서의 HTTP:80 Request 를 생성한 대상그룹으로 포워딩할 리스너를 생성합니다."
        SCRIPT="aws elbv2 create-listener --load-balancer-arn $alb_arn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$target_group_arn --region $REGION_CODE"
        eval $SCRIPT
        local result=$?
        if [ $result -eq 0 ]; then
            echo "리스너 등록에 성공하였습니다."
            exit 0        
    else 
        echo "대상그룹 생성에 실패하였습니다."
        exit 1
    fi
else 
    echo "ALB 생성에 실패하였습니다."
    exit 1    
fi
# --vpc-id vpc-12345678
