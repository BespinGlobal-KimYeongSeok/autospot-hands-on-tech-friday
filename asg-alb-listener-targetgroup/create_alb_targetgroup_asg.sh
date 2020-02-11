#!/bin/bash

init_variables(){

     default_vpc_id=""

}


get_default_vpc_from_region () {
    echo "getting default vpc information from the default region"
    local result=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true  | jq -r '.Vpcs[].VpcId')     
    local return_code=$?
    if [ $return_code -eq 0 ]; then
        echo "Your Default VPC ID: $result"
        default_vpc_id=$result
    else 
        echo "Can't fetch your default VPC"
        exit 1
    fi
}

multi_select_from_array(){
    subnet_choices=()
    echo "options: $subnets_arr"
    menu() {
        echo "Avaliable options:"
        for i in ${!subnets_arr[@]}; do
            printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${subnets_arr[i]}"
        done
        [[ "$msg" ]] && echo "$msg"; :
    }
    
    prompt="Check an option (again to uncheck, ENTER when done): "
    while menu && read -rp "$prompt" num && [[ "$num" ]]; do
        [[ "$num" != *[![:digit:]]* ]] &&
        (( num > 0 && num <= ${#subnets_arr[@]} )) ||
        { msg="Invalid option: $num"; continue; }
        ((num--)); msg="${subnets_arr[num]} was ${choices[num]:+un}checked"
        subnet_choices[num]=${subnets_arr[num]}
        [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
    done
    
    printf "You selected"; msg=" nothing"
    for i in ${!subnets_arr[@]}; do
        [[ "${choices[i]}" ]] && { printf " %s" "${subnets_arr[i]}"; msg=""; }
    done
    echo "$msg"
    echo $subnet_choices
}


select_subnets_or_input(){
    subnets_arr=( $(aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-3c450346 | jq -r '.Subnets[].SubnetId') )
    # vared -p "공백으로 구분된 서브넷 아이디 리스트를 입력해 주세요. ex) subnet-f830dcf6 subnet-33ba8b1d: " -c SUBNET_LIST
    
    multi_select_from_array 
    for subnet in ${subnet_choices[@]};
    do 
        echo $subnet 
    done
    
}

get_default_region_or_input(){
    REGION_CODE=(`eval "aws configure get region"`)
    vared -p $'\n리전코드를 입력해 주세요.\n그냥 Enter 시 AWS Configure에 설정된 값으로 진행합니다: ' -c REGION_CODE
    echo $REGION_CODE
}

get_default_albname_or_input(){

    ALB_NAME="TestALB"
    vared -p "ALB 이름을 입력해 주세요.: " -c ALB_NAME
    echo $ALB_NAME
}




select_security_groups_or_input(){

    SG="sg-0c2e83738a5a18b1b"
    vared -p "보안그룹 아이디를 입력해주세요 : " -c SG
    echo $SG
}





create_application_load_balancer(){

    SCRIPT="aws elbv2 create-load-balancer --name $ALB_NAME --subnets $SUBNET_LIST --security-groups $SG --region $REGION_CODE | jq -r '.LoadBalancers[].LoadBalancerArn'"

    clb_response=$(eval $SCRIPT)
    echo "response>>$clb_response"
    alb_arn=$clb_response 
    echo $alb_arn

    result=$?
    echo $result
}


create_target_group(){

    local VPC_ID="vpc-3c450346"
    vared -p "대상그룹을 생성할 VPC ID를 입력해 주세요 :" -c VPC_ID
    echo $VPC_ID
    vared -p "대상그룹 이름을 입력해 주세요.:" -c TARGET_GROUP
    echo $TARGET_GROUP
    SCRIPT="aws elbv2 create-target-group --name $TARGET_GROUP --protocol HTTP --port 80 --vpc-id $VPC_ID | jq -r '.TargetGroups[].TargetGroupArn'"
    echo "Script: $SCRIPT"
    target_group_arn=$(eval $SCRIPT)    
    local result=$?
}

create_listener_with_alb_targetgroup(){
    echo "생성된 어플리케이션 로드 발란서의 HTTP:80 Request 를 생성한 대상그룹으로 포워딩할 리스너를 생성합니다."
    SCRIPT="aws elbv2 create-listener --load-balancer-arn $alb_arn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$target_group_arn --region $REGION_CODE"
    eval $SCRIPT
    local result=$?
    if [ $result -eq 0 ]; 
    then
        echo "리스너 등록에 성공하였습니다."
        exit 0        
    else
        exit 1
    fi
}


######
#Main#
######

#Variable Init
init_variables

#Get Default VPC 
get_default_vpc_from_region

#get subnets from default vpc
select_subnets_or_input
