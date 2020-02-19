#!/usr/local/bin/bash
echo "생성한 자원을 삭제합니다."
#1 로드 발란서 삭제
aws elbv2 delete-load-balancer --region $region_code --load-balancer-arn $alb_arn
sleep 7

#2 타켓그룹 삭제
aws elbv2 delete-target-group --region $region_code --target-group-arn $target_group_arn
sleep 7

#3 오토스케일링 그룹 삭제
aws autoscaling delete-auto-scaling-group --region $region_code --auto-scaling-group-name $auto_scaling_group_name
sleep 7

#4 오토스케일링 그룹 설정 삭제
aws autoscaling delete-launch-configuration --region $region_code --launch-configuration-name $launch_configuration_name
sleep 7

#5 키페어삭제
aws ec2 delete-key-pair --region $region_code --key-name $created_key_name
sleep 7
echo "기존 생성 자원을 삭제완료하였습니다."