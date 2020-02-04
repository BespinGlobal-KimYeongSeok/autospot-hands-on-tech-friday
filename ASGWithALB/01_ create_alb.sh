#!/bin/zsh

vared -p "리전코드를 입력해 주세요.:" -c REGION_CODE
echo $REGION_CODE

vared -p "ALB 이름을 입력해 주세요.:" -c ALB_NAME
echo $ALB_NAME

vared -p "공백으로 구분된 서브넷 아이디 리스트를 입력해 주세요. ex) subnet-12345 subnet-54321:" -c SUBNET_LIST
echo $SUBNET_LIST

vared -p "보안그룹 아이디를 입력해주세요.:" -c SG
echo $SG

SCRIPT="aws elbv2 create-load-balancer --name $ALB_NAME --subnets $SUBNET_LIST --security-groups $SG --region $REGION_CODE"
echo "Executing the command: \n$SCRIPT"
eval $SCRIPT

# aws elbv2 create-target-group --name my-targets --protocol HTTP --port 80 \
# --vpc-id vpc-12345678
